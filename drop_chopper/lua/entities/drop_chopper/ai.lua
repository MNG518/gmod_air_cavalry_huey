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
--	AI ROUTINES
--==============================================================================================================


function ENT:Get2DDistance(pos)
    if !isvector(pos) then return 0 end
    
    local selfPos = self:GetPos()
    local targetPos = pos

    local dx = selfPos.x - targetPos.x
    local dy = selfPos.y - targetPos.y

    return math.sqrt(dx * dx + dy * dy)
end


function ENT:IsEnemy(ent)
	if !ent:IsNPC() then return false end

	local enemy_classes = {
		[CLASS_ANTLION] = true,
		[CLASS_COMBINE] = true,
		[CLASS_HEADCRAB] = true,
		[CLASS_METROPOLICE] = true,
		[CLASS_MANHACK] = true,
		[CLASS_STALKER] = true,
		[CLASS_ZOMBIE] = true,
		[CLASS_COMBINE_HUNTER] = true,
		[CLASS_HUMAN_MILITARY] = true,
		[CLASS_ALIEN_MILITARY] = true,
		[CLASS_ALIEN_MONSTER] = true,
		[CLASS_ALIEN_PREY] = true,
		[CLASS_ALIEN_PREDATOR] = true,
	}

	return enemy_classes[ent:Classify()]
end




--======================================================================================================================
--	LZ Calc
--====================================================================================================================== 




-- These 2 functions are used for trace visualization and debug
-- Very laggy

-- local function trVis(pos1, pos2, mat, decay, big)
-- 	if true then return false end
-- 	if !mat then
-- 		mat = "cable/cable"
-- 	end

-- 	if !decay then
-- 		decay = 5
-- 	end

-- 	local size = 8

-- 	if big then
-- 		size = 100
-- 	end

-- 	local tr0vis=constraint.Rope(Entity(0), Entity(0), 0, 0, pos1, pos2, 5, 0, 5, size, mat, false)

-- 	-- 
-- 	timer.Simple(decay, function()
-- 		tr0vis:Remove()
-- 	end)

-- end

-- local function markPlace(pos, decay)
-- 	if true then return false end
-- 	if !decay then decay = 5 end

-- 	local tr0vis=constraint.Rope(Entity(0), Entity(0), 0, 0, pos+Vector(-30,0,0), pos+Vector(30,0,0), 5, 0, 5, 4, "cable/physbeam", false)
-- 	local tr1vis=constraint.Rope(Entity(0), Entity(0), 0, 0, pos+Vector(0,-30,0), pos+Vector(0,30,0), 5, 0, 5, 4, "cable/physbeam", false)
-- 	local tr2vis=constraint.Rope(Entity(0), Entity(0), 0, 0, pos, pos+Vector(0,0,30), 5, 0, 5, 4, "cable/physbeam", false)
	
-- 	timer.Simple(decay, function() 
	
-- 		if IsValid(tr0vis) then
-- 			tr0vis:Remove()
-- 		end
		
-- 		if IsValid(tr1vis) then
-- 			tr1vis:Remove() 
-- 		end
		
-- 		if IsValid(tr2vis) then
-- 			tr2vis:Remove() 
-- 		end

-- 	end)

-- end


function ENT:FindLZ(basePos)


	--This is a pretty heavy calculation, to avoid lag I'm limiting its rate, and building the AI around that.
	if !self.NextLZCalc then
		self.NextLZCalc = CurTime()
	end

	if self.NextLZCalc > CurTime() then return end


	--Throttle this based on the number of helicopters present.
	self.NextLZCalc = CurTime() + (0.25*#ents.FindByClass("drop_chopper"))

	-- This is kinda bogo, I hope it works...
	local LZRadius

	if self.LZFailures < 30 then
		LZRadius = 320
	elseif self.LZFailures < 50 then
		LZRadius = 670
	else
		LZRadius = 1024
	
	--If we have to go this far out then our guys won't be able to reach the target.
	--If they're too far away we'll just let the gunners deal with it

	-- elseif self.LZFailures < 100 then 
	-- 	LZRadius = 2048
	-- elseif self.LZFailures < 200 then
	-- 	LZRadius = 4092
	-- elseif self.LZFailures < 500 then
	-- 	LZRadius = 10000
	-- else
	-- 	LZRadius = 65536
	end

	-- dmsg("Attempt #"..(self.LZFailures+1)..", radius = "..LZRadius)
	if self.LZFailures > 100 then
		self.TargetPos = false
		self.LZFailures = 0
	end





	-- markPlace(basePos)


	--Get upper root / we should factor in the altitude for this
	local upperCenter = basePos+Vector(0,0,1200)

	-- trVis(basePos, upperCenter, "cable/physbeam")
	-- markPlace(upperCenter)


	local testArea = upperCenter + Vector(math.random(-LZRadius, LZRadius), math.random(-LZRadius, LZRadius), 0)

	-- markPlace(testArea)
	-- trVis(upperCenter, testArea, "cable/physbeam")


	--Now, is the ground level below the test area?

	local lA = testArea
	local lB = testArea + Vector(-20, -20, 0)

	-- trVis(testArea, lA, "cable/redlaser")
	-- trVis(testArea, lB, "cable/redlaser")


	local e_lA = lA + Vector(0,0,-65000)

	local los_lA = util.TraceLine({
		start = lA, 
		endpos = e_lA,
	})



	--See if it's far enough away from another chopper's LZ
	--No more clusterf*ck landings
	local proposedSpot = los_lA.HitPos

	local otherHelicopters = ents.FindByClass("drop_chopper")

	for i=1,#otherHelicopters do
		local oh = otherHelicopters[i]
		if isvector(oh.LandingZone) && oh.LandingZone:Distance(proposedSpot) < 400 then
			self.LZFailures = self.LZFailures + 1
			return false
		end
	end





	local e_lB = lB + Vector(0,0,-65000)

	local los_lB = util.TraceLine({
		start = lB, 
		endpos = e_lB,
	})


	local slopeTolerance = 5

	local distanceToGround = los_lA.HitPos:Distance(lA)

	local slope = math.abs(distanceToGround - los_lB.HitPos:Distance(lB))



	if slope < slopeTolerance then
		-- dmsg("Ground level enough!")

		-- trVis(lA, los_lA.HitPos)
		-- trVis(lB, los_lB.HitPos)

	else -- not level
		-- dmsg("Ground not level!")
		-- trVis(lA, los_lA.HitPos, "cable/redlaser")
		-- trVis(lB, los_lB.HitPos, "cable/redlaser")
		self.LZFailures = self.LZFailures + 1
		return false
		-- dmsg(lA)
		-- dmsg(los_lA.HitPos)
	end



	--Next, we need to hull trace and check if the above spot is accessible by air


   local mins = Vector(-400,-400,-0)
   local maxs = Vector(400, 400, 200)


	local airHull = util.TraceHull({
		start = self:GetPos(),
		endpos = testArea,
		maxs = maxs,
		mins = mins,
		filter = function(hitent) if hitent != self && hitent:GetClass() != self:GetClass() && !hitent:IsNPC() && hitent:GetParent() != self && !hitent:IsPlayer() then return true end end
	})

	if airHull.Hit then	--The path from the air is obstructed
		-- dmsg("I can't fly there...")
		-- dmsg("Hit "..tostring(airHull.Entity))
		-- trVis(airHull.HitPos, self:GetPos()+Vector(0,0,60), "cable/redlaser", 5, true)
		self.LZFailures = self.LZFailures + 1
		return false
	else
		-- dmsg("Reachable by air!")
		-- trVis(testArea, self:GetPos()+Vector(0,0,60), "cable/cable", 5, true)
	end

	--Okay, now that we've done all that, let's see if we can land there.

	--Looks like the landing hull trace is ignoring a lot of stuff that will make us crash.

	--Time to do a ton of traces. Ugh.

	local function PointsAroundCircle(pos, pointCount)
		local startPoint = 0
		local points = {}

		local angle = Angle()
		angle:RotateAroundAxis(angle:Up(), startPoint)


		local increment = 180/pointCount

		for i = startPoint+(increment),startPoint+360, increment do
			angle:RotateAroundAxis(angle:Up(), increment)
			table.insert(points, pos+angle:Forward()*340)
		end

		return points
	end
	

	local function circleTrace(pos, points, depth)

		local pos = pos+Vector(0,0,-depth)

		for i=1,#points do
			local point = points[i]+Vector(0,0,-depth)

			local pointLOS = util.TraceLine({
				start = pos, 
				endpos = point,
				filter = function(hitent) if hitent != self && hitent:GetClass() != self:GetClass() && !hitent:IsNPC() && hitent:GetParent() != self && !hitent:IsPlayer() then return true end end
			})

			if pointLOS.Hit then
				-- dmsg("Something in the way of this descent vector: "..tostring(pointLOS.Entity))
				-- trVis(pointLOS.HitPos, pos, "cable/redlaser")
				self.LZFailures = self.LZFailures + 1
				return false
			else
				-- trVis(point, pos)
			end

		end
		return true
	end


	local circlePoints = PointsAroundCircle(testArea, 24)


	--Let's first see if there's anything weird vertically
	for i = 1, #circlePoints do
		local cp = circlePoints[i]
		local verticalLOS = util.TraceLine({
			start = cp, 
			endpos = cp+Vector(0,0,-5000),
			filter = function(hitent) if hitent != self && hitent:GetClass() != self:GetClass() && !hitent:IsNPC() && hitent:GetParent() != self && !hitent:IsPlayer() then return true end end
		})

		local tolerance = 40

		local slope = math.abs(distanceToGround - verticalLOS.HitPos:Distance(cp))

		if slope > tolerance then

			-- dmsg("Weird vertical stuff detected: dif = "..slope)
			-- trVis(verticalLOS.HitPos, cp, "cable/redlaser")
			self.LZFailures = self.LZFailures + 1
			return false
		else
			-- trVis(cp, verticalLOS.HitPos)
		end
	end
	-- dmsg("Vertical approach confirmed!")


	
	--We'll use this to take horizontal slices all the way down
	-- circleTrace(testArea, circlePoints, 0)
	local resolution = 7 -- We wanna keep this as low as possible, because we'll be doing this*circlepoints traces...
	for i = 0, resolution-1 do
		local slice = distanceToGround/resolution

		if !circleTrace(testArea, circlePoints, slice*i) then
			self.LZFailures = self.LZFailures + 1
			return false
		end

	end
	
	-- dmsg("Descent vector LOCKED!")

	self.LZFailures = 0
	self.NextLZCalc = CurTime()+1.5



	local LZ = los_lA.HitPos
	-- markPlace(LZ)
	-- self:EmitSound("buttons/button3.wav")
	-- local tr2vis=constraint.Rope(Entity(0), Entity(0), 0, 0, self:GetPos(), LZ, 5, 0, 5, 40, "cable/physbeam", false)
	-- timer.Simple(10, function()
	-- 	tr2vis:Remove()
	-- end)

	self.LandingZone = LZ


	--Get the position of the target
	-- Identify a descent pattern
		-- for i in untill we find a good one
			-- start at tPos.z + altitude
			-- LOS trace to the chopper to ensure we can reach this
			-- see if the ground is level
				-- What if it's not?? Anywhere??
				-- Figure out later. try it anyway?
			-- Hull trace down to make sure the descent is clear.

	-- Keep in mind how hot the LZ is
	--	land further away if it's hot (more dudes)



end



--======================================================================================================================
--======================================================================================================================


function ENT:AcquireTarget()

	--Throttle the target acquisition rate.
	--Iterating through ents.GetAll() is expensive.

	if !self.NextAcquire then
		self.NextAcquire = CurTime()
	end

	if self.NextAcquire > CurTime() then return end

	self.NextAcquire = CurTime()+3 -- 3 seconds between each attempt

        
	--Find the closest hostile target

	local minD = math.huge
	local found

	local all = ents.GetAll()
	for i=1,#all do
		local ent = all[i]
		if self:IsEnemy(ent) then

			local dist = ent:GetPos():Distance(self:GetPos())

			if dist < minD then
				minD = dist
				found = ent
			end
		end

	end

	if found then 
		-- dmsg(">> TARGET ACQUIRED: "..tostring(found))
		self.TargetPos = found:GetPos()
	end

end

function ENT:FlightControl()

	-- dmsg(self:GetAltitude())
	-- self.TargetPos = Entity(1):GetPos()
	if self.destruction.fuel then 
		self:GoForward()
		return
	end

	-- if true then return end -- Stop for now.



	if self:HasCrew() then

		--We have soldiers on board ready for deployment
		if self.TargetPos then

			-- dmsg(self.TargetPos)

			-- self:ExposeGunner()
			-- self:GoForward()

			-- self:FaceTarget()
			if self.LandingZone then -- We should go and land
				self.TargetPos = self.LandingZone
				local d = self:Get2DDistance(self.LandingZone)

				if self:GetAltitude() < 30 && d < 256 then
					self:DeployCrew()
				elseif d > 64 then -- We're not over the Landing Zone
					-- dmsg("Too far to land!")
					self:FaceTarget()
					self:GoForward()
					self.AltitudeTarget = 1200
					if d < 256 then
						self:SlowUp(true)
					end

				else -- We're in position

					--Let the gunners work
					self:ExposeGunner()

					if self:GetVelocity():LengthSqr() > 1500 then -- we're fast
						self:SlowUp()
					end
					self.AltitudeTarget = 0
				end

			else --We're calculating an LZ
				self:FindLZ(self.TargetPos)
				self.AltitudeTarget = 1200
				local d = self:Get2DDistance(self.TargetPos)
				if d > 1024 then
					
					-- APPROACH TARGET
					self:FaceTarget()

					if self:GetAltitude() > 1000 then
						self:GoForward()
					end
					
				else
					-- Are we fast or slow?
					if self:GetVelocity():LengthSqr() > 1500 then -- we're fast
						self:SlowUp()

					end
					self:ExposeGunner()
				end
				-- Calculate the LZ

				-- We're in range
					-- Let the gunners pick at him
				--We're not in range
					-- get in range
				

			end


			
		else
			self.AltitudeTarget = 700
			self:AcquireTarget()
		end
	else
		self.TargetPos = false
		self.LandingZone = false
		-- dmsg("No crew!")
		--We should return to base and get more soldiers

		

		local d2 = self:Get2DDistance(self.BasePos)

		if d2 > 64 then
			
			self.AltitudeTarget = 1200

			-- APPROACH TARGET
			self:FaceTarget(true)
			if self:GetAltitude() > 1000 then
				self:GoForward()
				
			end
			if d2 < 256 then
				self:SlowUp(true)
				self.AltitudeTarget = 200
				
			end
		else
			-- Are we fast or slow?
			local velocity = self:GetVelocity():LengthSqr() 
			if velocity > 2000 then -- we're fast
				self:SlowUp()
				self:NegateSpin()
			else -- We've slowed down enough to land
				self.AltitudeTarget = 0
				
				if self:GetAltitude() < 15 then
					for k,v in pairs(ents.FindInSphere(self:GetPos(),256)) do
						if v:GetClass() == "prop_ragdoll" then
							v:Remove()
						end
					end
					self:ReloadCrew()
					self.TargetPos = false
				end
			end


			
		end

		

	end

end
