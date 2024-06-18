
SWEP.PrintName				= "M72 LAW"			
SWEP.Author					= "MrNiceGuy518"

SWEP.Category				= "Better NPC Guns"

SWEP.Instructions			= "No. 1 rule of gun safety: Have fun!"

SWEP.Spawnable 				= false
SWEP.AdminOnly 				= false

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.Weight					= 5
SWEP.AutoSwitchTo			= false
SWEP.AutoSwitchFrom			= false

SWEP.Slot					= 4
SWEP.SlotPos				= 2
SWEP.DrawAmmo				= true
SWEP.DrawCrosshair			= true

SWEP.PrimaryPunch				= 0
SWEP.SecondaryPunch				= 0

SWEP.HoldType = "rpg"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = true
SWEP.WorldModel = "models/kali/weapons/m16a1.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.UseHands		= true


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


function SWEP:DrawWorldModel()


	if IsValid(self.Owner) then

		local bName = self.Owner:LookupBone("ValveBiped.Bip01_R_Hand")


		local bPos, bAng = self.Owner:GetBonePosition(bName)


		render.Model({
			model = "models/namsoldiers/props/law_open.mdl",
            pos = vecMod(bPos, bAng, Vector(0,1,-3)),
            angle = angMod(bAng, Angle(180,6,-90))
		})
	else
		render.Model({
			model = "models/namsoldiers/props/law_open.mdl",
			pos = self:GetPos(),
			angle = self:GetAngles()
		})
	end

	return false
end


function SWEP:Initialize()
	self:SetHoldType("rpg")
	self:DrawShadow(false)
end

function SWEP:Equip(owner)
	if owner && owner:IsPlayer() then

		owner:GiveAmmo(1,"rpg_round")


		self:Remove()
	end
end


function SWEP:PrimaryAttack()

	
	
	if self:GetNextPrimaryFire() && self:GetNextPrimaryFire() > CurTime() then
		return false
	end


	
	
	
	self.Weapon:SetNextPrimaryFire( CurTime() + 2)	
	
	

	if !self.FirstFire then 
		self.FirstFire = true 
		return false
	end
	

				
	if !IsValid(self) || !IsValid(self.Owner) then return end

	
	local enemy = self.Owner:GetEnemy()
	if !IsValid(enemy) then return end
	local targetpos = LocalToWorld(enemy:OBBCenter(), Angle(), enemy:GetPos(), Angle() )
	

	local targetDistance =  targetpos:Distance(self.Owner:GetPos())



	self:EmitSound("weapons/m60_shot.wav",90,50,1,CHAN_WEAPON)
	self.Owner:EmitSound("weapons/underwater_explode"..math.random(3,4)..".wav",90,100,1,CHAN_STATIC)

	local effectdata = EffectData()
	local atDat = self:GetAttachment(1)
	effectdata:SetOrigin(vecMod(atDat.Pos,atDat.Ang, Vector(-18,2,-3)))
	effectdata:SetAngles(angMod(atDat.Ang, Angle(0,0,180)))
	effectdata:SetScale(1.5)
	util.Effect("MuzzleEffect", effectdata)	

	local rocket = ents.Create("weapon_npc_ac_law_fired")
	rocket:SetPos(vecMod(atDat.Pos,atDat.Ang, Vector(-20,0,0)))
	local ang = (targetpos-self.Owner:GetShootPos()):Angle()

	rocket:SetAngles(ang)
	rocket.Launcher = self.Owner
	rocket:Spawn()


	local discard = ents.Create("prop_physics")
		discard:SetPos(atDat.Pos)
		discard:SetAngles(angMod(atDat.Ang, Angle(180,0,90)))
		discard:SetModel("models/namsoldiers/props/law_open.mdl")
	discard:Spawn()

	timer.Simple(30, function()
		if IsValid(discard) then discard:Remove() end
	end)



	local own = self.Owner

	if own.IsDropChopperSoldier then
		own:Give("weapon_npc_ac_m16")
		timer.Simple(30, function()
			if !IsValid(own) then return end
			own:Give("weapon_npc_ac_law")
		end)

	else

		timer.Simple(6, function()
			if !IsValid(own) then return end
			own:Give("weapon_npc_ac_law")
		end)
	end


	self:Remove()

	
	if CLIENT then return true end
	
end





