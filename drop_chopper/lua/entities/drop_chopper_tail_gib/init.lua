AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include('shared.lua')

local CollideHardSound = Sound( "MetalVehicle.ImpactHard" )
local CollideSoftSound = Sound( "MetalVehicle.ImpactSoft" )

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube075x5x075.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS ) 

	self:SetMaterial("models/wireframe")
    local phys = self:GetPhysicsObject()
	
	phys:Wake()
	phys:SetMass(2000)

end




function ENT:PhysicsCollide( data, physobj )
	if ( data.Speed > 300 && data.DeltaTime > 0.1 ) then
		sound.Play( CollideHardSound, self:GetPos(), 50, math.random( 90, 120 ), math.Clamp( data.Speed / 150, 0, 1 ) )
	elseif ( data.Speed > 45 && data.DeltaTime > 0.1 ) then
		sound.Play( CollideSoftSound, self:GetPos(), 20, math.random( 90, 120 ), math.Clamp( data.Speed / 150, 0, 1 ) )
	end	
end




