AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.
 
include('shared.lua')



function ENT:Initialize()
	self:SetModel("models/hunter/plates/plate.mdl")
	self:PhysicsInit( SOLID_NONE )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE ) 

	self:SetMaterial("models/wireframe")
	
	self:EmitSound("ambient/fire/fire_big_loop1.wav")
end

function ENT:Think()
	if self:WaterLevel() > 0 then
		self:Remove()
	end
end


function ENT:OnRemove()

	self:StopSound("ambient/fire/fire_big_loop1.wav")
end




