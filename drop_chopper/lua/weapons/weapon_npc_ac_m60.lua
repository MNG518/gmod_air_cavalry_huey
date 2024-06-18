
SWEP.PrintName				= "M60 Machine Gun"			
SWEP.Author					= "MrNiceGuy518"

SWEP.Category				= "Better NPC Guns"

SWEP.Instructions			= "No. 1 rule of gun safety: Have fun!"

SWEP.Spawnable 				= false
SWEP.AdminOnly 				= false

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
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
			model = "models/namsoldiers/props/m60.mdl",
            pos = vecMod(bPos, bAng, Vector(4,0,0)),
            angle = angMod(bAng, Angle(180,12,0))
		})
	else
		render.Model({
			model = "models/namsoldiers/props/m60.mdl",
			pos = self:GetPos(),
			angle = angMod(self:GetAngles(), Angle(0,0,90))
		})
	end

	return false
end


function SWEP:Initialize()
	self:SetHoldType("smg")
	self:DrawShadow(false)
end

function SWEP:Equip(owner)
	if owner && owner:IsPlayer() then

		owner:GiveAmmo(60,"ar2")


		self:Remove()
	end
end


function SWEP:PrimaryAttack()

	self:SetHoldType("smg")

	if self:GetNextPrimaryFire() && self:GetNextPrimaryFire() > CurTime() then
		return false
	end


	local rpm = 550
	local bullet_delay = 1/(rpm/60)

	

			
	if !IsValid(self) || !IsValid(self.Owner) then return end


	
	self.Weapon:SendWeaponAnim( ACT_DEPLOY ) 

	
	local enemy = self.Owner:GetEnemy()
	if !IsValid(enemy) then return end
	local targetpos = LocalToWorld(enemy:OBBCenter(), Angle(), enemy:GetPos(), Angle() )
	
	local shots = math.random(6,18)
	self.Weapon:SetNextPrimaryFire(CurTime()+shots*bullet_delay)	
	for i=1,shots do 
		timer.Simple((i-1)*bullet_delay, function()
			if !IsValid(self) || !IsValid(self.Owner) then
				return false
			end 
			local bullet = {}
			bullet.Num		 = 1
			bullet.Src		 = self.Owner:GetShootPos()
			bullet.Dir		 = (targetpos-self.Owner:GetShootPos()):Angle():Forward()
			bullet.Spread	 = Vector(0.01, 0.01, 0 )
			bullet.Tracer	= 4
			bullet.TracerName = "Tracer"
			bullet.Force	= 2
			bullet.Damage	= 24

			bullet.Callback = function(atk,tr,dmginfo)
				if tr.Entity:GetClass() == self.Owner:GetClass() then
					dmginfo:SetDamage(0)
				end
			end

			self:EmitSound("weapons/m60_shot.wav",90,90,1,CHAN_WEAPON)
			self.Owner:FireBullets( bullet )

			local effectdata = EffectData()
			local atDat = self:GetAttachment(1)
			effectdata:SetOrigin(vecMod(atDat.Pos,atDat.Ang, Vector(30,0,0)))
			effectdata:SetAngles(atDat.Ang)
			effectdata:SetScale(1)
			util.Effect("MuzzleEffect", effectdata)	
	
			local effectdata2 = EffectData()
			local shelldat = self:GetAttachment(1)
			effectdata2:SetOrigin(vecMod(shelldat.Pos,shelldat.Ang, Vector(4,-3,0)))
			effectdata2:SetAngles(angMod(shelldat.Ang, Angle(0,0,90)))
			effectdata2:SetScale(0.5)
			util.Effect("RifleShellEject", effectdata2)	

		end)
	end
	
	if CLIENT then return true end
	
end







function SWEP:SecondaryAttack()
	if true then return end
end
 




