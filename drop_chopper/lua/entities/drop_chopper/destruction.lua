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

local CollideHardSound = Sound( "MetalVehicle.ImpactHard" )
local CollideSoftSound = Sound( "EpicMetal_Heavy.ImpactSoft" )


--==============================================================================================================
-- DESTRUCTION PHYSICS
--==============================================================================================================




function ENT:IsProbablyCrashed()
	return (self.destruction.engine || self.destruction.rotor || self.destruction.tail || !self:PilotsAlive())  && self:GetAltitude() < 120
end


function ENT:SendDamageMessage(part)
	if !part then part = "" end

	net.Start("DChopper_Destruction")
		net.WriteEntity(self)
		net.WriteInt(self.rotor_damage, 8)
		net.WriteString(part)
	net.Broadcast()
end


function ENT:TakeRotorDamage(level)
	if !level then
		level = 1
	end

	if self.rotor_damage >= 20 then
		self:BreakRotor()
	else
		self.rotor_damage = self.rotor_damage+level
		self:SendDamageMessage()
	end
end


function ENT:RotorTrace()
	-- I should optimize this... This many traces is disgusting.

	if self.destruction.rotor then return end


   local rAngle2 = self:GetAngles()
   rAngle2:RotateAroundAxis(self:GetAngles():Up(), math.fmod(CurTime(), 360) * (360*self:GetRPS()))

   local startpoint = vecMod(self:GetPos(), self:GetAngles(), Vector(-23,0,165))

   local endpoint1 = startpoint+rAngle2:Right()*285
   local endpoint2 = startpoint+rAngle2:Right()*-285






	local los1 = util.TraceLine({
		start = startpoint, 
		endpos = endpoint1,
		filter = function(hitent) if hitent != self && hitent:GetClass() != self:GetClass() && !hitent.inHelicopter then return true end end--&& (IsValid(hitent:GetParent()) && hitent:GetParent():GetClass() != self:GetClass()) then return true end end
	})


	local los2 = util.TraceLine({
		start = startpoint, 
		endpos = endpoint2,
		filter = function(hitent) if hitent != self && hitent:GetClass() != self:GetClass() && !hitent.inHelicopter then return true end end--&& (IsValid(hitent:GetParent()) && hitent:GetParent():GetClass() != self:GetClass()) then return true end end
	})



	if los1.Hit && !los1.HitSky then
		self:SmackBlade(los1.HitPos, los1.MatType, los1.Entity)
	elseif los2.Hit && !los2.HitSky then
		self:SmackBlade(los2.HitPos, los2.MatType, los2.Entity)
	end

end

function ENT:SmackBlade(hitpos, mat, ent)
	if mat == MAT_DEFAULT then return false end

	if !self.NextBladeSmack then
		self.NextBladeSmack = 0
	end

	if CurTime() < self.NextBladeSmack then
		return false
	end

	local mat_sounds = {
		[MAT_ANTLION] = {
			snd = "physics/body/body_medium_impact_hard",
			fx = "HunterDamage",
			count = 6,
		},
		[MAT_CONCRETE] = {
			snd = "physics/concrete/concrete_impact_hard",
			fx = "ManhackSparks",
			count = 3,
		},
		[MAT_DIRT] = {
			snd = "physics/surfaces/sand_impact_bullet",
			count = 4,
		},
		[MAT_FLESH] = {
			snd = "physics/body/body_medium_impact_hard",
			fx = "BloodImpact",
			count = 6,
		},
		[MAT_ALIENFLESH] = {
			snd = "physics/body/body_medium_impact_hard",
			fx = "BloodImpact",
			count = 6,
		},
		[MAT_PLASTIC] = {
			snd = "play physics/plastic/plastic_barrel_impact_bullet",
			count = 3,
		},
		[MAT_METAL] = {
			snd = "physics/metal/metal_solid_impact_bullet",
			fx = "ManhackSparks",
			count = 4,
		},
		[MAT_SAND] = {
			snd = "physics/surfaces/sand_impact_bullet",
			count = 4,
		},
		[MAT_TILE] = {
			snd = "physics/surfaces/tile_impact_bullet",
			fx = "ManhackSparks",
			count = 4,
		},
		[MAT_GRASS] = {
			snd = "physics/surfaces/sand_impact_bullet",
			count = 4,
		},
		[MAT_WOOD] = {
			snd = "physics/wood/wood_plank_impact_hard",
			count = 5,
		},
		[MAT_GLASS] = {
			snd = "physics/glass/glass_impact_bullet",
			fx = "GlassImpact",
			count = 4,
		}
	}





	if mat_sounds[mat] then
		EmitSound(mat_sounds[mat].snd..math.random(1,mat_sounds[mat].count)..".wav", hitpos, 0, CHAN_STATIC, 1, 90, 0, math.random(80,100))

		local effectdata2 = EffectData()
		effectdata2:SetOrigin(hitpos)
		effectdata2:SetScale(1)

		local fx = "WheelDust"
		if mat_sounds[mat].fx then
			fx = mat_sounds[mat].fx
		end
		util.Effect(fx, effectdata2)	

	end

	self:EmitSound("physics/metal/metal_sheet_impact_hard"..math.random(6,8)..".wav", 90, math.random(80,100), 0.5, CHAN_STATIC)

	if self.destruction.engine then
		self:BreakRotor()
	elseif !self:PilotsAlive() || self.destruction.tail then
		self:TakeRotorDamage(5)
	else
		if self:GetPhysicsObject():GetMass() == 45678 then -- If we're being physgunned then the player is probably trying to kill us
			self:TakeRotorDamage(1)						   -- Just let 'em. Part of the fun.
		else
			-- self:TakeRotorDamage(0.1) -- Accidentally crashing is just a bad look any way you slice it.
		end
	end

	self.NextBladeSmack = CurTime() + (1/self:GetRPS())/2



	if !IsValid(ent) then return end
	local dmginfo = DamageInfo()
	dmginfo:SetAttacker(self)
	dmginfo:SetInflictor(self)
	dmginfo:SetDamage(500)
	dmginfo:SetDamageType(DMG_BLAST)
	dmginfo:SetDamageForce((self:GetPos()-ent:GetPos()):Angle():Forward()*-40000)
	ent:TakeDamageInfo(dmginfo)


end


function ENT:Explode()
	if self.destruction.exploded then return end

	self.destruction.exploded = true


	self:EmitSound("ambient/explosions/explode_3.wav", 140, 100, 1, CHAN_STATIC)
	self:BreakGlass()
	self:BreakRotor()
	self:BreakTail()
	self:RuptureFuel()
	self:KillEngine()





	self:SendDamageMessage("explode")

	local function cwispy(ent)
		if !IsValid(ent) then return end
		ent:SetModel("models/Humans/Charple0"..math.random(1,4)..".mdl")
	end



	for k,v in pairs(self.crew) do
		cwispy(v)
	end
	cwispy(self.gunner_l)
	cwispy(self.gunner_r)
	cwispy(self.pilot1)
	cwispy(self.pilot2)




	timer.Simple(0, function()
		for k,v in pairs(ents.FindInSphere(self:GetPos(), 256)) do
			if v:GetClass() == "prop_ragdoll" then
				v:Ignite(60)
			end
		end
	end)




	self:CrewTakeDamage(10000)

end


function ENT:RuptureFuel()
	if self.destruction.fuel then return end

	self:FreakOutCrew()
	self.destruction.fuel = true

	local fireSpots = {
		Vector(-80,20,80),
		Vector(-80,-20,80),
		Vector(-80,40,80),
		Vector(-80,-40,80),
		Vector(-80,40,60),
		Vector(-80,-40,60),
		Vector(-80,40,40),
		Vector(-80,-40,40),
		Vector(-80,40,30),
		Vector(-80,-40,30),
		Vector(-80,20,30),
		Vector(-80,-20,30),
	}


	for k,v in pairs(fireSpots) do
		local fire = ents.Create("drop_chopper_flame_plume")
			fire:SetPos(vecMod(self:GetPos(), self:GetAngles(), v))
			fire:SetAngles(angMod(self:GetAngles(), Angle(0,0,180)))
		fire:Spawn()
		fire:SetParent(self)
	end

	local fxPos = vecMod(self:GetPos(), self:GetAngles(), Vector(-120,6,47.5))

	local effectdata = EffectData()
	effectdata:SetOrigin(fxPos)
	effectdata:SetAngles(self:GetAngles())
	effectdata:SetScale(1)
	util.Effect("Explosion", effectdata)	


	local function ig(ent)
		if IsValid(ent) then ent:Ignite(60) end
	end


	ig(self.crew.seat1)
	ig(self.crew.seat2)



	local bTime = 10
	local bMax = 176

	local bStep = bTime/bMax

	for i = 1, bMax do
		timer.Simple(bStep*i, function()
			if !IsValid(self) then return end
			local cVal = 255-i
			self:SetColor(Color(cVal,cVal,cVal))
		end)
	end



	timer.Simple(math.random(5,10), function()
		if !IsValid(self) then return end
		self:KillEngine()
		self:SetColor(Color(79,79,79))
	end)

	timer.Simple(30, function()
		if !IsValid(self) then return end
		self:Explode()
	end)

end

function ENT:BreakGlass()
	if self.destruction.glass then return end

	self.destruction.glass = true
	self:SetSubMaterial(4, "chopper_glass_broken")
	self:EmitSound("physics/glass/glass_impact_bullet4.wav",90, 100,1,CHAN_STATIC)
end

function ENT:KillEngine()
	if self.destruction.engine then return end
	self:SendDamageMessage("engine")

	self:FreakOutCrew()


	self:GetPhysicsObject():SetDragCoefficient(200)

	local res = 50
	local time = 5

	self:GetPhysicsObject():SetDragCoefficient(0)

	for i = 1,res do

		timer.Simple((time/res)*i, function()
			if !IsValid(self) then return end
			local rps = (6/res)*(res-i)
			self:SetRPS(rps)
		end)
	end


	timer.Simple(2, function()
		if !IsValid(self) then return end
		self.sound2:ChangePitch(0,3)
	end)


	self.destruction.engine = true

end



function ENT:RotorGibs()

	local a = math.fmod(CurTime(), 360) * (360*self.rps)

	local rAngle = self:GetAngles()
	rAngle:RotateAroundAxis(self:GetAngles():Up(), a)

	local g0 = ents.Create("drop_chopper_rotor_gib")
		g0:SetPos(vecMod(self:GetPos(), self:GetAngles(), Vector(-22,0,149))) 
		g0:SetAngles(rAngle)
		g0.gibNum = 1
		g0:Spawn()
		g0:SetColor(self:GetColor())


	local g1 = ents.Create("drop_chopper_rotor_gib")
		g1:SetPos(vecMod(g0:GetPos(), g0:GetAngles(), Vector(0,140,10)))
		g1:SetAngles(angMod(g0:GetAngles(), Angle(0,0,0)))
		g1:Spawn()
		g1:SetColor(self:GetColor())


	local g2 = ents.Create("drop_chopper_rotor_gib")
		g2:SetPos(vecMod(g0:GetPos(), g0:GetAngles(), Vector(0,-140,10)))
		g2:SetAngles(angMod(g0:GetAngles(), Angle(0,0,-180)))
		g2:Spawn()
		g2:SetColor(self:GetColor())


	g0:GetPhysicsObject():ApplyForceCenter(g0:GetAngles():Up()*100000)
	g0:GetPhysicsObject():ApplyTorqueCenter(g0:GetAngles():Up()*2000000)

	g1:GetPhysicsObject():ApplyForceCenter(g1:GetAngles():Right()*1000000)
	g2:GetPhysicsObject():ApplyForceCenter(g2:GetAngles():Right()*1000000)

	self:CallOnRemove("RemoveRotorGibs", function()
		
		if IsValid(g0) then
			g0:Remove()
		end
		if IsValid(g1) then
			g1:Remove()
		end
		if IsValid(g2) then
			g2:Remove()
		end
	
	end)

	for i=1,5 do
		local effectdata2 = EffectData()
		effectdata2:SetOrigin(g0:GetPos())
		effectdata2:SetAngles(self:GetAngles())
		effectdata2:SetScale(1)
		util.Effect("ManhackSparks", effectdata2)	
	end

end


function ENT:BreakRotor()
	if self.destruction.rotor then return end
	self:SendDamageMessage("rotor")

	self:FreakOutCrew()

	self:RotorGibs()

	for i = 1,30 do

		self:EmitSound("vehicles/v8/vehicle_impact_medium2.wav",140, math.random(77,100), 1, CHAN_STATIC)
	end


	timer.Simple(2, function()
		if !IsValid(self) then return end
		self.sound2:ChangePitch(0,3)
	end)


	self.destruction.rotor = true
	self:GetPhysicsObject():SetDragCoefficient(0)
end


function ENT:BreakTail()

	if self.destruction.tail then
		return false
	end

	self:PitchSounds(true)
	self:FreakOutCrew()

	self.destruction.tail = true

	self:SendDamageMessage("tail")

	self:EmitSound("physics/metal/metal_box_break1.wav", 100, 75, 1, CHAN_STATIC)

	local fxPos = vecMod(self:GetPos(), self:GetAngles(), Vector(-140,6,47.5))

	local effectdata = EffectData()
	effectdata:SetOrigin(fxPos)
	effectdata:SetAngles(self:GetAngles())
	effectdata:SetScale(1)
	util.Effect("Explosion", effectdata)	

	for i=1,20 do
		local effectdata2 = EffectData()
		effectdata2:SetOrigin(fxPos)
		effectdata2:SetAngles(self:GetAngles())
		effectdata2:SetScale(1)
		util.Effect("ManhackSparks", effectdata2)	
	end



	local gib = ents.Create("drop_chopper_tail_gib")
		gib:SetPos(vecMod(self:GetPos(), self:GetAngles(), Vector(-240,6,47.5)))
		gib:SetAngles(angMod(self:GetAngles(), Angle(0,0,-90)))
	gib:Spawn()
	self.TailGib = gib
	gib:SetColor(self:GetColor())
	constraint.NoCollide(self, gib, 0, 0)


	self:GetPhysicsObject():SetMass(6500)

	gib:GetPhysicsObject():SetVelocityInstantaneous(self:GetPhysicsObject():GetVelocity())

	self:GetPhysicsObject():SetDragCoefficient(0)

	self:CallOnRemove("CleanupDCTail", function()
		if IsValid(self.TailGib) then
			self.TailGib:Remove()
		end
	end)


end

function ENT:PhysicsCollide( data, physobj )
	if data.HitEntity:GetClass() == "drop_chopper" then return end
	if data.HitEntity:GetClass() == "drop_chopper_evil" then return end
	if data.HitEntity:GetClass() == self:GetClass() then return end
	if data.HitObject:GetMass() == 45678 then return end	-- Physgunned items have this weight
	if data.HitEntity:GetClass() == "prop_ragdoll" then return end
	if data.HitEntity:GetClass() == "drop_chopper_rotor_gib" then return end


	local damFactor
	if data.HitEntity == Entity(0) then
		damFactor = data.Speed
	else
		local kineticEnergy = 0.5 * data.HitObject:GetMass() * (data.Speed/10 ^ 2)

		damFactor = kineticEnergy
	end



	if self.destruction.tail || self.destruction.rotor then
		if damFactor > 100 && data.DeltaTime > 0.1 then
			self:CrewTakeDamage(damFactor/25)

			if damFactor > 1000 then
				self:SetCollisionGroup(COLLISION_GROUP_WORLD)
				timer.Simple(0.1, function()
					self:SetCollisionGroup(COLLISION_GROUP_NONE)
				end) 
			end

		end
	end


	if damFactor > 500 && self.destruction.fuel then
		self:Explode()
	end

	if damFactor > 500 then
		self:BreakGlass()
	end

	if damFactor > 750 then
		self:BreakTail()
	end


	if damFactor > 3000 then
		self:RuptureFuel()
	end


	if ( damFactor > 300 && data.DeltaTime > 0.1 ) then
		sound.Play( CollideHardSound, self:GetPos(), 50, math.random( 90, 120 ), math.Clamp( damFactor / 150, 0, 1 ) )
	elseif ( damFactor > 10 && data.DeltaTime > 0.1 ) then
		sound.Play( CollideSoftSound, self:GetPos(), 20, math.random( 90, 120 ), math.Clamp( damFactor / 150, 0, 1 ) )
	end	
end

function ENT:BreakSomething()


	local disasters = {
		self.BreakGlass,
		self.BreakTail,
		self.RuptureFuel,
		self.KillEngine
	}

	local disaster = disasters[math.random(1,3)]

	disaster(self)

end


function ENT:OnTakeDamage(dmginfo)
	if dmginfo:GetDamageType() == DMG_BLAST then
		if math.random(1,2) == 2 then
			self:RuptureFuel()
		end
	elseif dmginfo:GetDamageType() == DMG_BURN then
		if math.random(1,10) == 5 then
			self:RuptureFuel()
		end
	end


	if dmginfo:GetDamage() < 5 then return end

	self.damage = self.damage + dmginfo:GetDamage()


	if math.random(1,30000) <= self.damage then
		self:BreakSomething()
	end


	return
end