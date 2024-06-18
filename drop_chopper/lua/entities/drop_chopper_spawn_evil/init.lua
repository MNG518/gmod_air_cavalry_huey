AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include('shared.lua')


local function dmsg(msg)
	Entity(1):PrintMessage(3, tostring(msg))
end

function ENT:Initialize()

	self:SetModel("models/hunter/tubes/circle4x4.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS ) 


	
	
    local phys = self:GetPhysicsObject()
	
	phys:Wake()
	
	
	
	self:SetMaterial("phoenix_storms/road")
	self:SetColor(Color(255,255,255,50))
	self:SetRenderMode( RENDERMODE_TRANSCOLOR )

	self.LandingPad = true


end


function ENT:Think()

	if IsValid(self.Chopper) && !self.Chopper.IsCertainlyDead then
		self.Chopper.BasePos = self:GetPos()
	else
		self:SpawnChopper()
	end
end

function ENT:OnRemove()
	if IsValid(self.Chopper) then 
		self.Chopper:Remove()
	end
end

function ENT:SpawnChopper()
	if self.Spawning then return end

	self.Spawning = true


	timer.Simple(5, function()
		if !IsValid(self) then return end

		self.Spawning = false

		local dc = ents.Create("drop_chopper_evil")
			dc:SetPos(self:GetPos() + Vector(0,0,10))
			dc:SetAngles(Angle(0,self:GetAngles().y,0))
		dc:Spawn()
		
		self.Chopper = dc
	end)

	
end





function ENT:Use( activator, caller )
    return
end







