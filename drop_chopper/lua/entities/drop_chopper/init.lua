AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.
 
include('shared.lua')


include('ai.lua')
include('crew.lua')
include('flight.lua')
include('destruction.lua')

util.AddNetworkString("DChopper_HookM60Render")

util.AddNetworkString("DChopper_Destruction")

util.AddNetworkString("DChopper_SoundPitch")




--======================================================
--	PRECACHING
--======================================================


--Models
util.PrecacheModel("models/jessev92/rambo/vehicles/uh1n_hull.mdl")
util.PrecacheModel("models/sentry/uh-1d_tr.mdl")
util.PrecacheModel("models/sentry/uh-1d_rr.mdl")

for i=1,9 do
	util.PrecacheModel("models/kali/characters/bo/choppercrew/choppercrew_0"..i..".mdl")
	util.PrecacheModel("models/namsoldiers/male_0"..i..".mdl")
end




--======================================================
--======================================================








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




function ENT:SetMorality()
	self.IsEvil = false
end


function ENT:Initialize()
	self:SetMorality()

	-- This helicopter is a Bell UH-1N Twin Huey

	self:SetModel("models/jessev92/rambo/vehicles/uh1n_hull.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS ) 


	self.NPCTable = {}
	self.NPCTable.Name = "Huey"

	self.BasePos = self:GetPos()

    local phys = self:GetPhysicsObject()
	
	phys:Wake()

	--So we don't fly in circles
	phys:SetDragCoefficient(25)


	self.damage = 0

	self:SetRPS(6)

	self.destruction = {}
	self.rotor_damage = 0

	self:SetBodygroup(1,1)	-- No rocket pods



	self.sound2 = CreateSound(self, "uh1d/engine.wav")
	self.sound2:SetSoundLevel(70)
	self.sound2:Play()
	self.sound2:ChangeVolume(0.4)

	self.inHelicopter = true

	self.throttle = 1

	self.pilot1 = self:SpawnPilot()
	self.pilot2 = self:SpawnPilot(true)
	self.gunner_l = self:SpawnGunner()
	self.gunner_r = self:SpawnGunner(true)

	self.crew = {

		seat1 = self:LoadGuy("seat1"),
		seat2 = self:LoadGuy("seat2"),
		seat3 = self:LoadGuy("seat3"),
		seat4 = self:LoadGuy("seat4"),
		seat5 = self:LoadGuy("seat5"),
	}

	self.AltitudeTarget = 256
	self.Altitude = 0


	self.LZFailures = 0

	self.LastGoForward = CurTime()

	

end




--==============================================================================================================
-- MAIN HOOKS
--==============================================================================================================






function ENT:PhysicsUpdate(phys)


	if self.destruction.rotor then
		return false
	end

	
	
	self:RotorTrace()
	
	
	
    if FrameTime() == 0 then
        return -- Skip the physics update when the game is paused
    end


	if !self.destruction.engine then
		local forceVector = self:GetAngles():Up() * 67600 * self.throttle
		phys:ApplyForceCenter(forceVector)

		if self.destruction.tail then
			phys:ApplyTorqueCenter(self:GetAngles():Up() * -100000)
		end


	end


	if !self:PilotsAlive() || self.destruction.tail then return end 





	if !self.destruction.tail then
		local ang = self:GetAngles()
		local angVel = phys:GetAngleVelocity()

		-- Proportional control with reduced gain
		local pitchCorrection = ang.x * 5000
		local rollCorrection = ang.z * -2500

		-- Damping based on angular velocity
		local pitchDamping = angVel.y * 500
		local rollDamping = angVel.x * -250

		-- Apply torque with damping
		phys:ApplyTorqueCenter(self:GetAngles():Right() * (pitchCorrection + pitchDamping))
		phys:ApplyTorqueCenter(self:GetAngles():Forward() * (rollCorrection + rollDamping))


	end
end







function ENT:Think()
	self:NextThink(CurTime())

	self:UpdateAltitude()

	if self:IsProbablyCrashed() then
		self:EvacCrew()
	end

	if self:PilotsAlive() && !self.destruction.rotor && !self.destruction.tail then
		self:FlightControl()


		self:AltitudeControl()
		self:CollisionAvoidance()
	end

	return true

end



function ENT:SetRPS(rps)
	self:SetNWInt("HueyRPS", rps)
	self.rps = rps
end


function ENT:GetRPS()
	return self.rps
end


function ENT:OnRemove()
	self.sound2:Stop()
end