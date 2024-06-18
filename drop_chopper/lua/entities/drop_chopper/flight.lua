local function dmsg(msg)
	Entity(1):PrintMessage(3, tostring(msg))
end

local function vecMod(pos, ang, modVector)
	return pos + ang:Forward()*modVector.x + ang:Right()*modVector.y + ang:Up()*modVector.z
 end


local function angMod(ang, modAngle)
	local newAng = ang

	newAng:RotateAroundAxis(ang:Forward(), modAngle.x)
	newAng:RotateAroundAxis(ang:Right(), modAngle.y)
	newAng:RotateAroundAxis(ang:Up(), modAngle.z)

	return newAng
end


--==============================================================================================================
-- FLIGHT CONTROL
--==============================================================================================================


--Do this trace once per tick, and allow it to be the main source of truth
--For all functions that need the altitude. Eliminates redundant calls.
function ENT:UpdateAltitude()



	--Trace-based altitude reading...
	local startpoint = self:GetPos()+Vector(0,0,10)

	local angs = Angle(0,self:GetAngles().y,0)


	local endpoint = self:GetPos() + angs:Up()*-1200

	local los = util.TraceLine({
		start = startpoint, 
		endpos = endpoint,
		mask = MASK_WATER + MASK_SOLID,
		filter = function(hitent) if hitent == Entity(0) || hitent:GetClass() == "prop_physics" || hitent.LandingPad then return true end end
	})
	-- local tr0vis=constraint.Rope(Entity(0), Entity(0), 0, 0, startpoint, los.HitPos, 5, 0, 5, 1, "cable/cable", false)
	-- timer.Simple(0.1, function() tr0vis:Remove() end)
	
	local groundAltitude = self:GetPos():Distance(los.HitPos)
	-- dmsg(self.Altitude)	



	--Dustoff effect.
	if groundAltitude < 170 && !self.destruction.engine && !self.destruction.rotor then
		local effectdata2 = EffectData()
		effectdata2:SetOrigin(los.HitPos)
		effectdata2:SetAngles(self:GetAngles():Forward():Angle())
		effectdata2:SetScale(math.Clamp( (140 - self.Altitude)/10, 0, 30 ))
		util.Effect("WheelDust", effectdata2)	
	end


	--If we're that close to the ground, it's more important to pay a attention to the ground than the z difference
	if groundAltitude < 1000 then

		self.Altitude = groundAltitude
		return
	end











	--Z difference altitude reading
	if self.TargetPos then

		local selfZ = self:GetPos().z

		local targetZ = self.TargetPos.z


		self.Altitude = selfZ - targetZ
	else
		local selfZ = self:GetPos().z

		local targetZ = self.BasePos.z

		self.Altitude = selfZ - targetZ

	end







end

function ENT:GetAltitude()

	if !self.Altitude then
		self.Altitude = 0
	end



	return self.Altitude

end


function ENT:PitchSounds(fast)
	if fast == self.soundpitchfast then return end


	self.soundpitchfast = fast

	net.Start("DChopper_SoundPitch")
		net.WriteEntity(self)
		net.WriteBit(fast)

	net.Broadcast()
end

function ENT:CollisionAvoidance()


	local function bumper(ep, isForward)

		local startpoint = self:GetPos()
		local endpoint = self:GetPos() + ep
	
		local los = util.TraceLine({
			start = startpoint, 
			endpos = endpoint,
			filter = function(hitent) if hitent != self || hitent:GetClass() != "prop_ragdoll" then return true end end
		})
		
		if los.Hit then

			local sidevec = los.HitNormal:Angle():Right()
			if isForward && self.LastGoForward > CurTime() - 1 then
				self:GetPhysicsObject():ApplyTorqueCenter(sidevec*-120000)
			else
				self:GetPhysicsObject():ApplyTorqueCenter(sidevec*-80000)
			end
		end

		-- local tr0vis=constraint.Rope(Entity(0), Entity(0), 0, 0, startpoint, endpoint, 5, 0, 5, 1, "cable/cable", false)
		-- timer.Simple(0.1, function() tr0vis:Remove() end)

	end


	if self.AltitudeTarget > 0 && self:GetAltitude() > 100 then
		-- dmsg(self.AltitudeTarget)
		bumper(self:GetAngles():Forward()*800, true)
		bumper(self:GetAngles():Forward()*-800)
		bumper(self:GetAngles():Right()*600)
		bumper(self:GetAngles():Right()*-600)
	end


end




function ENT:AltitudeControl()
    local target = self.AltitudeTarget
    
    local alt = self:GetAltitude()
    local altChangeRate = (alt - (self.lastAltitude or alt)) / FrameTime()

	
    self.lastAltitude = alt
	
    local targetThrottle = 1.0
	


    if alt < target then
        targetThrottle = 1.3
    else
        targetThrottle = 0.95
    end

    -- Apply a smaller damping factor to smooth the throttle adjustments
    local dampingFactor = 0.0001
    local damping = -altChangeRate * dampingFactor

    self.throttle = targetThrottle + damping

end



function ENT:ExposeGunner()

	local tp
	local currentDir

	--See if the right gunner is alive and wants to shoot
	if IsValid(self.gunner_r) && IsValid(self.gunner_r.target) then

		-- dmsg("Right Gunner wants to shoot!")

		tp = self.gunner_r.target:GetPos()

		currentDir = self:GetRight()
	

	elseif IsValid(self.gunner_l) && IsValid(self.gunner_l.target) then
		-- dmsg("Left Gunner wants to shoot!")
		tp = self.gunner_l.target:GetPos()

		currentDir = self:GetRight()*-1
	
	else
		-- dmsg("Gunners are dead or don't want to shoot.")
		self:NegateSpin()
		return
	end

	local targetDir = (tp - self:GetPos()):GetNormalized()
	local angleDiff = currentDir:Angle() - targetDir:Angle()
	angleDiff:Normalize()

	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end

	-- Proportional control for yaw
	local yawCorrection = angleDiff.y * -10000

	-- Damping based on angular velocity
	local angVel = phys:GetAngleVelocity()
	local yawDamping = angVel.z * -20000

	-- Apply torque to rotate the helicopter towards the target
	phys:ApplyTorqueCenter(self:GetAngles():Up() * (yawCorrection + yawDamping))

end


function ENT:FaceTarget(isBase)

	local tp = self.TargetPos

	if isBase then 
		tp = self.BasePos
	end

    if !tp || (self:GetAltitude() < 200) then return end

    local targetDir = (tp - self:GetPos()):GetNormalized()
    local currentDir = self:GetForward()

    local angleDiff = currentDir:Angle() - targetDir:Angle()
    angleDiff:Normalize()

    local phys = self:GetPhysicsObject()
    if not IsValid(phys) then return end

    -- Proportional control for yaw
    local yawCorrection = angleDiff.y * -10000

    -- Damping based on angular velocity
    local angVel = phys:GetAngleVelocity()
    local yawDamping = angVel.z * -5000

    -- Apply torque to rotate the helicopter towards the target
    phys:ApplyTorqueCenter(self:GetAngles():Up() * (yawCorrection + yawDamping))


end






function ENT:GoForward()
	if self:GetAltitude() < 200 then return end
	self:PitchSounds(true)

	self.LastGoForward = CurTime()
	self:GetPhysicsObject():ApplyTorqueCenter(self:GetAngles():Right()*-115000)

end

function ENT:NegateSpin()
	-- dmsg("negating spin...")

	local phys = self:GetPhysicsObject()
	local angVel = phys:GetAngleVelocity()
	phys:SetAngleVelocity(Vector(0,angVel.y,0))
end


function ENT:SlowUp(less_so)
	self:PitchSounds(false)
	
	local phys = self:GetPhysicsObject()
	local velocity = phys:GetVelocity()

	if less_so then
		phys:ApplyForceCenter(-Vector(velocity.x, velocity.y,math.max(velocity.x,0))*200)
	else
		phys:ApplyForceCenter(-Vector(velocity.x, velocity.y,math.max(velocity.x,0))*500)
	end
end


