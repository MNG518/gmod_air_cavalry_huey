AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include('shared.lua')

local CollideHardSound = Sound( "MetalVehicle.ImpactHard" )
local CollideSoftSound = Sound( "MetalVehicle.ImpactSoft" )

function ENT:Initialize()
	if !self.gibNum then
		self.gibNum = 2
	end

	self:DrawShadow(false)

	self:SetNWInt("gn", self.gibNum)

	if self.gibNum == 1 then
		self:SetModel("models/sentry/uh-1d_tr.mdl")
	else
		self:SetModel("models/hunter/plates/plate025x5.mdl")
		self:SetMaterial("models/wireframe")
	end

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS ) 


    local phys = self:GetPhysicsObject()
	phys:SetDragCoefficient(0)
	phys:Wake()

	if self.gibNum == 1 then
		phys:SetMass(1000)
	else
		phys:SetMass(500)
	end

	


end




function ENT:PhysicsCollide( data, physobj )
	if ( data.Speed > 300 && data.DeltaTime > 0.1 ) then
		sound.Play( CollideHardSound, self:GetPos(), 50, math.random( 90, 120 ), math.Clamp( data.Speed / 150, 0, 1 ) )
	elseif ( data.Speed > 45 && data.DeltaTime > 0.1 ) then
		sound.Play( CollideSoftSound, self:GetPos(), 20, math.random( 90, 120 ), math.Clamp( data.Speed / 150, 0, 1 ) )
	end	
end




