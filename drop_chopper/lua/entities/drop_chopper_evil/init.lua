AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include('shared.lua')


function ENT:SetMorality() 
	self.IsEvil = true
end


function ENT:IsEnemy(ent)

	if ent:IsNPC() then 

		local enemy_classes = {
			[CLASS_PLAYER] = true,
			[CLASS_PLAYER_ALLY] = true,
			[CLASS_PLAYER_ALLY_VITAL] = true,
			[CLASS_VORTIGAUNT] = true,
			[CLASS_ANTLION] = true,
			[CLASS_HEADCRAB] = true,
			[CLASS_ZOMBIE] = true,
			[CLASS_HUMAN_MILITARY] = true,
			[CLASS_ALIEN_MILITARY] = true,
			[CLASS_ALIEN_MONSTER] = true,
			[CLASS_ALIEN_PREY] = true,
			[CLASS_ALIEN_PREDATOR] = true,
		}

		return enemy_classes[ent:Classify()]
	elseif ent:IsPlayer() && !GetConVar("ai_ignoreplayers"):GetBool() then
		return true
	end
end