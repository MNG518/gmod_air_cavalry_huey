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


local function findSuitablePlacement(center, radius, i, failures)
	if !failures then failures = 0 end
	local ranpos = center + Vector(math.random(-radius, radius), math.random(-radius, radius), 10)
	local tr = {
		start = ranpos,
		endpos = ranpos,
		mins = Vector( -25, -25, 0 ),
		maxs = Vector( 25, 25, 71 )
	}
	local HasFloor = util.TraceLine({
		start = ranpos, 
		endpos = ranpos+Vector(0,0,-40),
	})
	local hullTrace = util.TraceHull(tr)
	if !hullTrace.Hit && HasFloor.Hit then 
		if i < 2 then
			return {ranpos}
		else
			i = i-1
			return table.Add(findSuitablePlacement(center, radius, i), {ranpos})
		end
	else
		failures = failures+1
		if failures > 99 then
			return "FAILED"
		end
		return findSuitablePlacement(center, radius, i, failures)
	end
end





--==============================================================================================================
-- CREW CONTROL
--==============================================================================================================

-- They can talk now.
hook.Add("AcceptInput", "DropChopperSoldiersTalk", function(ent, input, activator, caller, value)
    if IsValid(ent) && ent.IsDropChopperSoldier && ent:GetClass() == "npc_citizen" && input == "Use"  then

        if !ent.NextTalk then
            ent.NextTalk = CurTime()
        else
           if ent.NextTalk > CurTime() then return end 
        end

        ent.NextTalk = CurTime() + 3
        if ent:GetNPCState() != 3 then 
            if math.random(1,3) == 2 then
                local num = math.random(1,9)
                if num == 8 then num = 9 end
                ent:PlayScene("scenes/npc/male01/question0"..num..".vcd")
            else
                local num = math.random(10,31)
                if num == 15 then num = 16 end
                ent:PlayScene("scenes/npc/male01/question"..num..".vcd")
            end
        end
    end
end)






hook.Add("EntityTakeDamage","DropChopper_FixCSRagdolls", function(ent, dmginfo)
    if !GetConVar("ai_serverragdolls"):GetBool() && ent.inHelicopter then


        if dmginfo:GetDamage() >= ent:Health() then
            dmginfo:SetDamage(0)
            ent:EmitSound("vo/npc/male01/pain0"..math.random(1,9)..".wav")
            ent:Fire("becomeragdoll")
        end


    end
end)

function ENT:KillCrew_CS(ent)

    local bdy = ents.Create(ent:GetClass())
        bdy:SetPos(ent:GetPos())
        bdy:SetAngles(ent:GetAngles())
    bdy:Spawn()
    bdy:SetModel(ent:GetModel())
    bdy:Fire("becomeragdoll")

    ent:Remove()
    timer.Simple(1, function()
        if IsValid(bdy) then bdy:Remove() end
    end)
end


function ENT:FloorSpot()
	local startpoint = self:GetPos()+Vector(0,0,10)
	local endpoint = self:GetPos() - Vector(0,0,99999)
	local los = util.TraceLine({
		start = startpoint, 
		endpos = endpoint,
		filter = function(hitent) if hitent == Entity(0) || hitent:GetClass() == "prop_physics" then return true end end
	})

	return los.HitPos

end




function ENT:CrewTakeDamage(damage,attacker)

    if !attacker then attacker = self end
    local function dmg(ent)
        if !IsValid(ent) then return end
        local dmginfo = DamageInfo()
        dmginfo:SetAttacker(attacker)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamage(math.random(1,damage))


        -- if keep corpses is off then we need to kill them manually
        if !GetConVar("ai_serverragdolls"):GetBool() && dmginfo:GetDamage() >= ent:Health() then
            self:KillCrew_CS(ent)
            return
        else

            ent:TakeDamageInfo(dmginfo)
        end
    end

    for k,v in pairs(self.crew) do
        dmg(v)
    end
    dmg(self.gunner_l)
    dmg(self.gunner_r)
    dmg(self.pilot1)
    dmg(self.pilot2)


end


function ENT:EvacCrew()
    if self.WillEvac then return end
    self.WillEvac = true
    -- dmsg("Evacing...")


    self:KillEngine()
    timer.Simple(6, function()
        if !IsValid(self) then return end
        if !self:IsProbablyCrashed() then 
            self.WillEvac = false
        end

        self.IsCertainlyDead = true
        timer.Simple(60, function()
            if !IsValid(self) then return end
            self:Remove()
        
        end)

        self:DeployCrew()


        local to_evac = {}

        local function evac2(ent)
            if IsValid(ent) then
                table.insert(to_evac, ent)
            end
        end


        evac2(self.gunner_l)
        evac2(self.gunner_r)
        evac2(self.pilot1)
        evac2(self.pilot2)



        local mdl_translate = {
            ["models/kali/characters/bo/choppercrew/choppercrew_01.mdl"] = "models/namsoldiers/male_01.mdl",
            ["models/kali/characters/bo/choppercrew/choppercrew_02.mdl"] = "models/namsoldiers/male_02.mdl",
            ["models/kali/characters/bo/choppercrew/choppercrew_03.mdl"] = "models/namsoldiers/male_03.mdl",
            ["models/kali/characters/bo/choppercrew/choppercrew_04.mdl"] = "models/namsoldiers/male_04.mdl",
            ["models/kali/characters/bo/choppercrew/choppercrew_05.mdl"] = "models/namsoldiers/male_05.mdl",
            ["models/kali/characters/bo/choppercrew/choppercrew_06.mdl"] = "models/namsoldiers/male_06.mdl",
            ["models/kali/characters/bo/choppercrew/choppercrew_07.mdl"] = "models/namsoldiers/male_07.mdl",
            ["models/kali/characters/bo/choppercrew/choppercrew_08.mdl"] = "models/namsoldiers/male_08.mdl",
            ["models/kali/characters/bo/choppercrew/choppercrew_09.mdl"] = "models/namsoldiers/male_09.mdl",
        }

        for k,v in pairs(to_evac) do
            local placement_data = findSuitablePlacement(self:FloorSpot(),256,1)
    
            if IsValid(v) && istable(placement_data) then
                local soldier
                if self.IsEvil then
                    soldier = ents.Create("npc_combine_s")
                else
                    soldier = ents.Create("npc_citizen")
                end
    
                soldier:Spawn()
    

                if !mdl_translate[v:GetModel()] then return end

                soldier:SetModel(mdl_translate[v:GetModel()])


                soldier:SetSkin(2)
                soldier:SetPos(placement_data[1])
                soldier:SetHealth(20)


                if v.isGunner then
                    soldier:Give("weapon_npc_ac_m60")
                else
                    soldier:Give("weapon_pistol")
                end

                soldier:SetAngles(Angle(0,self:GetAngles().y,0))
    
                soldier.NPCTable = {}
                if v.isGunner then
                    soldier.NPCTable.Name = "Helicopter Gunner"
                else
                    soldier.NPCTable.Name = "Helicopter Pilot"
                end

                soldier:SetBodygroup(1,2)
                soldier:SetBodygroup(2,3)
                soldier:SetBodygroup(3,3)
                soldier:SetBodygroup(4,2)
                soldier:SetBodygroup(5,1)
                soldier:SetBodygroup(6,1)
                soldier:SetBodygroup(7,2)
                soldier:SetBodygroup(8,5)
                soldier:SetBodygroup(14,1)
                
                v:Remove()
            end
    
            
        end









    end)

end



function ENT:PilotsAlive()

	return (IsValid(self.pilot1) && self.pilot1:Health() > 0) || (IsValid(self.pilot2) && self.pilot2:Health() > 0)
end

function ENT:HasCrew()
    local crewDead = true


    for k,v in pairs(self.crew) do
        if IsValid(v) && v:Health() > 0 then
            crewDead = false
        end
    end

    return !crewDead

end


function ENT:ReloadCrew()

    if self.CrewReloading then return false end

    self.damage = 0

    self.CrewReloading = true
    timer.Simple(5, function()
        if !IsValid(self) then return end

        if !IsValid(self.gunner_l) then
            self.gunner_l = self:SpawnGunner()
        end

        if !IsValid(self.gunner_r) then
            self.gunner_r = self:SpawnGunner(true)
        end

        if !IsValid(self.pilot1) then
            self.pilot1 = self:SpawnPilot()
        end

        if !IsValid(self.pilot2) then
            self.pilot2 = self:SpawnPilot(true)
        end

    	self.crew = {
            seat1 = self:LoadGuy("seat1"),
            seat2 = self:LoadGuy("seat2"),
            seat3 = self:LoadGuy("seat3"),
            seat4 = self:LoadGuy("seat4"),
            seat5 = self:LoadGuy("seat5"),
        }
        self.CrewReloading = false
    end)

end


function ENT:DeployCrew()

    
    for k,v in pairs(self.crew) do
        local placement_data = findSuitablePlacement(self:FloorSpot(),256,1)

        if IsValid(v) && istable(placement_data) then

            local soldier
            if self.IsEvil then
                soldier = ents.Create("npc_combine_s")
            else
                soldier = ents.Create("npc_citizen")
            end

            soldier:Spawn()

            soldier:SetModel(v:GetModel())
            soldier:SetSkin(v:GetSkin())
            soldier:SetPos(placement_data[1])
            soldier:Give(v.wep_to_have)

            soldier:SetAngles(Angle(0,self:GetAngles().y,0))

            soldier.NPCTable = {}
            soldier.NPCTable.Name = "Helicopter Soldier"

            soldier.IsDropChopperSoldier = true

            for i=0,v:GetNumBodyGroups()-1 do
                soldier:SetBodygroup(i,v:GetBodygroup(i))
            end
            v:Remove()
        end

        if !self:IsProbablyCrashed() && self:GetAltitude() < 200 then
            self:GetPhysicsObject():ApplyForceCenter(self:GetAngles():Up()*155000)
        end
    end
end



local crew_classes = {
    --Recon
    {
        bg_setup = function(guy)
            guy:SetBodygroup(1,1)
            guy:SetBodygroup(2,2)
            guy:SetBodygroup(4,2)
            guy:SetBodygroup(7,1)
            guy:SetBodygroup(8,5)
        end,
        wep = "weapon_npc_ac_m14"
    },
    --CQB
    {
        bg_setup = function(guy)
            guy:SetBodygroup(2,1)
            guy:SetBodygroup(6,1)
            guy:SetBodygroup(8,2)
            guy:SetBodygroup(12,1)
            guy:SetBodygroup(13,1)
        end,
        wep = "weapon_npc_ac_m16"
    },
    --Squad Leader
    {
        bg_setup = function(guy)
            guy:SetBodygroup(3,2)
            guy:SetBodygroup(7,2)
            guy:SetBodygroup(8,1)
            guy:SetBodygroup(9,1)                     
        end,
        wep = "weapon_npc_ac_m16"
    },
    --Demolitions
    {
        bg_setup = function(guy)
            guy:SetBodygroup(2,1)
            guy:SetBodygroup(3,1)
            guy:SetBodygroup(6,1)
            guy:SetBodygroup(8,4)
            guy:SetBodygroup(11,1)
            guy:SetBodygroup(13,1)
            
        end,
        wep = "weapon_npc_ac_law"
    },

    --Heavy Weapons
    {
        bg_setup = function(guy)
            guy:SetBodygroup(1,1)
            guy:SetBodygroup(3,1)
            guy:SetBodygroup(4,1)
            guy:SetBodygroup(5,1)
            guy:SetBodygroup(6,1)
            guy:SetBodygroup(8,4)
            guy:SetBodygroup(10,1)
            
        end,
        wep = "weapon_npc_ac_m60"
    },

}

local crew_config = {
	seat1 = {
		relative_vector = Vector(-55, -30, 20),
		relative_angle = Angle(),
		sequence = "sitchair1",
		bone_setup = function(guy)
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_Spine4"), Angle(0,-20.07,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Calf"), Angle(0,-41.95,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Foot"), Angle(0,11.37,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Toe0"), Angle(0,9.62,-15.25))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Calf"), Angle(0,-50.45,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Foot"), Angle(0,18.39,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Toe0"), Angle(0,31.86,9.96))
		end
	},
	seat2 = {
		relative_vector = Vector(-55, 30, 20),
		relative_angle = Angle(),
		sequence = "sitchair1",
		bone_setup = function(guy)
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_Spine4"), Angle(0,-20.07,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Calf"), Angle(0,-41.95,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Foot"), Angle(0,11.37,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Toe0"), Angle(0,9.62,-15.25))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Calf"), Angle(0,-50.45,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Foot"), Angle(0,18.39,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Toe0"), Angle(0,31.86,9.96))
		end
	},
	seat3 = {
		relative_vector = Vector(35, 30, 25),
		relative_angle = Angle(0,0,180),
		sequence = "sitchair1",
		bone_setup = function(guy)
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_Spine4"), Angle(0,-20.07,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Foot"), Angle(0,-28.8,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Toe0"), Angle(0,9.62,-15.25))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Foot"), Angle(0,-36.67,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Toe0"), Angle(0,36.19,9.96))
		end
	},
	seat4 = {
		relative_vector = Vector(35, -30, 25),
		relative_angle = Angle(0,0,180),
		sequence = "sitchair1",
		bone_setup = function(guy)
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_Spine4"), Angle(0,-20.07,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Foot"), Angle(0,-28.8,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Toe0"), Angle(0,9.62,-15.25))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Foot"), Angle(0,-36.67,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Toe0"), Angle(0,36.19,9.96))
		end
	},
	seat5 = {
		relative_vector = Vector(-18, 0, 33),
		relative_angle = Angle(0,0,0),
		sequence = "crouchidlehide",
		bone_setup = function(guy)
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_Spine1"), Angle(0,-3.89,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_UpperArm"), Angle(14.14,0,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Forearm"), Angle(-60.5,78.09,-5405.97))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Hand"), Angle(0,-6.96,-79.72))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_UpperArm"), Angle(-57.18,-112.69,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Forearm"), Angle(9.42,37.14,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Hand"), Angle(-43.17,-13.92,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Calf"), Angle(0,-33.65,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Foot"), Angle(0,5.13,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Toe0"), Angle(0,29.18,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Calf"), Angle(0,-46.05,0))
			guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Foot"), Angle(0,44.47,0))
		end
	},
}



function ENT:FreakOutCrew()
    for _,v in pairs(self.crew) do
        if IsValid(v) then
            v:FreakOut()
        end
    end
end

function ENT:LoadGuy(seat)


    local guy
    if self.IsEvil then
        guy = ents.Create("npc_combine_s")
    else
        guy = ents.Create("npc_citizen")
    end
    if not IsValid(guy) then return end

    guy:SetAngles(self:GetAngles())
    guy:Spawn()
    guy.NPCTable = {}
    guy.NPCTable.Name = "Helicopter Soldier"
    guy.inHelicopter = true
    

    guy.FreakOut = function(this)
        if this.AlreadyFreakedOut then return false end
        local oh_shits = {
            "scenes/npc/male01/incoming02.vcd",
            "scenes/npc/male01/strider_run.vcd",
            "scenes/npc/male01/watchout.vcd",
        }
        this:PlayScene( oh_shits[math.random(1,#oh_shits)] )
        this.AlreadyFreakedOut = true
    end

	guy.PhysgunDisabled = true
	timer.Simple(0, function() -- Load him in first before putting him in the helicopter

		guy:SetPos(vecMod(self:GetPos(), self:GetAngles(), crew_config[seat].relative_vector))
		guy:SetAngles(angMod(guy:GetAngles(), crew_config[seat].relative_angle))
	end)
    guy:SetModel("models/namsoldiers/male_0"..math.random(1,9)..".mdl")
    guy:SetParent(self)
    guy:SetSkin(math.random(0,3))

    -- That one skin is broken. Not my fault, I know, but people might think it's my fault.
    if guy:GetModel() == "models/namsoldiers/male_07.mdl" && guy:GetSkin() == 0 then
        guy:SetSkin(1)
    end

    local class

    if seat == "seat1" then
        class = crew_classes[1]
    elseif seat == "seat2" then
        class = crew_classes[2]
    elseif seat == "seat3" then
        class = crew_classes[3]
    elseif seat == "seat4" then
        class = crew_classes[4]
    elseif seat == "seat5" then
        class = crew_classes[5]
    end

    guy.wep_to_have = class.wep
    class.bg_setup(guy)


    guy:SetMoveType(MOVETYPE_NONE)  -- Disable physics
    guy:SetCollisionGroup(COLLISION_GROUP_WORLD)  -- Prevent odd physics behavior with the helicopter



	crew_config[seat].bone_setup(guy)




	guy.sequence = crew_config[seat].sequence
	local tName = "animator"..guy:EntIndex()
	timer.Create(tName, 0, 0, function()
		if !IsValid(guy) then timer.Remove(tName) return end
		guy:SetSequence(guy.sequence)

        if seat == "seat3" || seat == "seat4" then
            guy:SetAngles(angMod(self:GetAngles(), Angle(0,0,180)))
        else

            guy:SetAngles(self:GetAngles())
        end
	end)



    return guy
end




function ENT:SpawnGunner(right)


    local guy
    if self.IsEvil then
        guy = ents.Create("npc_combine_s")
    else
        guy = ents.Create("npc_citizen")
    end

    if not IsValid(guy) then return end

    guy:SetAngles(self:GetAngles())
    guy:Spawn()
    guy.isGunner = true
    guy.inHelicopter = true

    guy.NPCTable = {}
    guy.NPCTable.Name = "Helicopter Gunner"





	guy.PhysgunDisabled = true
	timer.Simple(0, function() -- Load him in first before putting him in the helicopter

        if right then

		    guy:SetPos(vecMod(self:GetPos(), self:GetAngles(), Vector(-14,33,26)))
		    guy:SetAngles(angMod(guy:GetAngles(), Angle(0,0,90)))
        else


		    guy:SetPos(vecMod(self:GetPos(), self:GetAngles(), Vector(-14,-33,26)))
		    guy:SetAngles(angMod(guy:GetAngles(), Angle(0,0,90)))
        end
	end)
    guy:SetModel("models/kali/characters/bo/choppercrew/choppercrew_0"..math.random(1,9)..".mdl")
    guy:SetParent(self)

    guy:SetBodygroup(3,6)



    net.Start("DChopper_HookM60Render")



        net.WriteInt(guy:EntIndex(), 16)
        net.WriteInt(self:EntIndex(), 16)
    net.Broadcast()

    guy:SetMoveType(MOVETYPE_NONE)  -- Disable physics
    guy:SetCollisionGroup(COLLISION_GROUP_WORLD)  -- Prevent odd physics behavior with the helicopter







    guy.NextFire = CurTime()


    guy.AcquireTarget = function(this)

        --Throttle the target acquisition rate.
        --Iterating through ents.GetAll() is expensive.

        if !this.NextAcquire then
            this.NextAcquire = CurTime()
        end

        if this.NextAcquire > CurTime() then return end

        this.NextAcquire = CurTime()+3 -- 3 seconds between each attempt

        

        --Find the closest hostile target
    
        local minD = math.huge
        local found
    
        local all = ents.FindInSphere(self:GetPos(), 2048)  -- This was ents.GetAll(), but that's a lot of stuff to iterate through
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
            -- dmsg(">> GUNNER TARGET ACQUIRED: "..tostring(found))
            this.target = found
        end
    
    end

    
    guy.FireWeapon = function(this)
        --550RPM
        if CurTime() < guy.NextFire then return end

        local rpm = 550
        local bullet_delay = 1/(rpm/60)

        guy.NextFire = CurTime()+bullet_delay

        -- dmsg(CurTime())



        this:EmitSound("weapons/m60_shot.wav",100,90,1,CHAN_WEAPON)


        local bPos, bAng = this:GetBonePosition(this:LookupBone("ValveBiped.Bip01_R_Hand"))
        local tp = LocalToWorld(this.target:OBBCenter(), Angle(), this.target:GetPos(), Angle() )
        

        local muzzpos = vecMod(bPos, bAng, Vector(35,0,-10))

        local effectdata = EffectData()
        effectdata:SetOrigin(muzzpos)
        effectdata:SetAngles(angMod(bAng, Angle(0,-12,0)))
        effectdata:SetScale(2)
        util.Effect("MuzzleEffect", effectdata)	
        


        local effectdata2 = EffectData()
        effectdata:SetOrigin(vecMod(bPos, bAng, Vector(4,0,-1)))
        effectdata:SetAngles(angMod(bAng, Angle(0,0,90)))
        effectdata2:SetScale(0.5)
        util.Effect("RifleShellEject", effectdata2)	

        
        local bullet = {}
        bullet.Num		 = 1
        bullet.Src		 = muzzpos
        bullet.Dir		 = (tp-muzzpos):Angle():Forward()
        bullet.Spread	 = Vector(0.02, 0.02, 0 )
        bullet.Tracer	= 4
        bullet.TracerName = "Tracer"
        bullet.Force	= 2
        bullet.Damage	= 24
        bullet.Callback = function(atk,tr,dmginfo)
            if tr.Entity:GetClass() == this:GetClass() then
                dmginfo:SetDamage(0)
            end
        end

        this:FireBullets( bullet )



        this:AddGestureSequence( this:LookupSequence("flinch_01") )
    end


	guy.sequence = "cidle_ar2"
	local tName = "thinker"..guy:EntIndex()

	timer.Create(tName, 0, 0, function()
        
		if !IsValid(guy) then timer.Remove(tName) return end
		guy:SetSequence(guy.sequence)
        
        if right then
            guy:SetAngles(angMod(self:GetAngles(), Angle(0,0,-90)))
        
        else
            guy:SetAngles(angMod(self:GetAngles(), Angle(0,0,90)))
        end
        
        
        if !IsValid(guy.target) then
            guy:AcquireTarget()
        else
            
            local gp = guy:GetPos()
            local tp = LocalToWorld(guy.target:OBBCenter(), Angle(), guy.target:GetPos(), Angle() )
            

            local bName = guy:LookupBone("ValveBiped.Bip01_R_Hand")
            if !bName then return end
            local bPos, bAng = guy:GetBonePosition(bName)
            local shootpos = vecMod(bPos, bAng, Vector(35,0,-10))

            local muzzpos = shootpos--+Vector(0,0,30)


            local targetpos = tp
            
            --Translate the target's position (angled at 0,0,0) to a coordinate plane originating at the AI's postion, 
            --with angle 0,0,0 at the AI's Current Angles. Essentially how our target's position is different from ours.
            local TargetOffset = WorldToLocal(targetpos, Angle(), muzzpos, guy:GetAngles()) --(Our pos must be plus 60, because the bot thinks his chest-height is at his origin, which is at his feet.)
            local Distance = targetpos:Distance(muzzpos) --The distance from the target's position to me. 
            
            local newYaw=-math.deg(math.atan(TargetOffset.Y/TargetOffset.X )) --Determine what angle Tangent of X and Y combined will yield, in degrees form.
            local newPitch=math.deg(math.asin(TargetOffset.Z/Distance))	 --Much more simple with a single dimension.

            --When the target is behind us, aim pos is going to behave as if is has eyes on the back of it's head:
            if TargetOffset.X/Distance < 0 then
                newYaw=newYaw+180
            end
            
            local Pitch=math.NormalizeAngle(newPitch)
            local Yaw=math.NormalizeAngle(newYaw)


            Yaw = -Yaw
            Pitch = -Pitch

            guy:SetPoseParameter("aim_yaw", Yaw)
            guy:SetPoseParameter("aim_pitch", Pitch)






            local los = util.TraceLine({
                start = shootpos, 
                endpos = tp,
            })

            -- Don't let them shoot at unrealistic angles
            if los.Entity == guy.target && Yaw > -60 && Yaw < 70 then
                guy:FireWeapon()
            end



        end

	end)


    return guy

end







function ENT:SpawnPilot(isCopilot)


    local guy
    if self.IsEvil then
        guy = ents.Create("npc_combine_s")

        --None of this could get them to stop jittering. If you know how to fix this, please let me know.
        -- guy:RunEngineTask(0,0)

        -- guy:SetSchedule(SCHED_NPC_FREEZE)

        -- guy:SetCondition(COND.TASK_FAILED)
        -- guy:SetCondition(COND.NO_HEAR_DANGER)
        -- guy:SetCondition(COND.NO_WEAPON)
        -- guy:SetCondition(COND.NPC_FREEZE)

    
        -- guy:SetSchedule(SCHED_IDLE_STAND)
    
        -- guy:SetSaveValue("m_bInAScriptedScene", true)
        -- guy:SetSaveValue("m_bDontThink", true)

    else
        guy = ents.Create("npc_citizen")
    end

    if not IsValid(guy) then return end

    guy:SetAngles(self:GetAngles())
    guy:Spawn()
    guy.inHelicopter = true
    guy.NPCTable = {}
    guy.NPCTable.Name = "Helicopter Pilot"

	guy.PhysgunDisabled = true
	timer.Simple(0, function() -- Load him in first before putting him in the helicopter
        if isCopilot then
            guy:SetPos(vecMod(self:GetPos(), self:GetAngles(), Vector(67,20,41)))
        else
            guy:SetPos(vecMod(self:GetPos(), self:GetAngles(), Vector(67,-20,41)))
        end

		guy:SetAngles(self:GetAngles())
	end)

	guy:SetModel("models/kali/characters/bo/choppercrew/choppercrew_0"..math.random(1,9)..".mdl")
	guy:SetSkin(math.random(0,3))

    guy:SetParent(self)

    guy:SetMoveType(MOVETYPE_NONE)  -- Disable physics
    guy:SetCollisionGroup(COLLISION_GROUP_WORLD)  -- Prevent odd physics behavior with the helicopter


	guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_Spine1"), Angle(-1.53,2.84,0))
	guy:ManipulateBonePosition(guy:LookupBone("ValveBiped.Bip01_Spine2"), Vector(0,0,2.1))
	guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_Spine2"), Angle(-1.46,-28.49,-34.4))
	guy:ManipulateBonePosition(guy:LookupBone("ValveBiped.Bip01_Spine4"), Vector(0,0,-1.1))
	guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_Spine4"), Angle(0,-21.45,-11.38))
	guy:ManipulateBonePosition(guy:LookupBone("ValveBiped.Bip01_Neck1"), Vector(0.89,-0.28,-0.34))
	guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_Neck1"), Angle(-7.97,4.07,-4.87))
	guy:ManipulateBonePosition(guy:LookupBone("ValveBiped.Bip01_Head1"), Vector(0,0.22,0))
	guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_Head1"), Angle(0,4.7,4.74))
	guy:ManipulateBonePosition(guy:LookupBone("ValveBiped.Bip01_R_UpperArm"), Vector(0,-0.4,0))
	guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_UpperArm"), Angle(-0.2,0.81,0))
	guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_R_Forearm"), Angle(-33.04,-5.35,0))
	guy:ManipulateBonePosition(guy:LookupBone("ValveBiped.Bip01_R_Hand"), Vector(0.69,0,0))
	guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_UpperArm"), Angle(0,-15.19,0))
	guy:ManipulateBoneAngles(guy:LookupBone("ValveBiped.Bip01_L_Forearm"), Angle(36.32,15.22,0))
	guy:ManipulateBonePosition(guy:LookupBone("ValveBiped.Bip01_L_Hand"), Vector(0.6,0,0))



	guy.sequence = "sit_duel"
	local tName = "animator"..guy:EntIndex()
	timer.Create(tName, 0, 0, function()
		if !IsValid(guy) then timer.Remove(tName) return end
		guy:SetSequence(guy.sequence)
        guy:SetAngles(self:GetAngles())
	end)

    return guy


end


