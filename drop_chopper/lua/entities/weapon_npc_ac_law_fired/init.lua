AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.
 
include('shared.lua')

local CollideHardSound = Sound( "Cardboard.ImpactHard" )
local CollideSoftSound = Sound( "Cardboard.ImpactSoft" )
function ENT:Initialize()

	self:SetModel("models/weapons/w_missile.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS ) 


    local phys = self:GetPhysicsObject()
	
	phys:Wake()

	phys:SetMass(25)
	
	
	
	self:SetMaterial("phoenix_storms/heli")
	

	self:GetPhysicsObject():EnableGravity(false)

end



function ENT:Use( activator, caller )
    return
end



function ENT:PhysicsUpdate(phys)
	phys:ApplyForceCenter(self:GetAngles():Forward()*10000)
end



function ENT:Explode()
	if self.Exploding then return false end
	self.Exploding = true



	
	local effectdata = EffectData()
	effectdata:SetOrigin(self:GetPos())
	effectdata:SetAngles(self:GetAngles())
	effectdata:SetScale(1)
	util.Effect("Explosion", effectdata)

	for _,v in pairs(ents.FindInSphere(self:GetPos(),256)) do



		local d = DamageInfo()
		d:SetDamage(1000)
		d:SetDamageType(DMG_BLAST)
		d:SetInflictor(self)
		d:SetDamageForce((self:GetPos()-v:GetPos()):Angle():Forward()*-30000)
		if v:GetClass() == "npc_strider" then
			v:Fire("sethealth", "0")
		end


		if IsValid(self.Launcher) then
			d:SetAttacker(self.Launcher)

			if v:GetClass() != self.Launcher:GetClass() then
				v:TakeDamageInfo(d)
			end
		else
			v:TakeDamageInfo(d)
		end
	end
	
	self:Remove()


end


function ENT:OnTakeDamage()
	
	self:Explode()
end



function ENT:PhysicsCollide( data, physobj )
	if ( data.Speed > 100 && data.DeltaTime > 0.1 ) then
		self:Explode()
	else
		self:EmitSound("weapons/rpg/shotdown.wav")
	end	
end



