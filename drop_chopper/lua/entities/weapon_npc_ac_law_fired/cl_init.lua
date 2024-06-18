include('shared.lua')
 

function ENT:Draw()
     self.BaseClass.Draw(self)
end

function ENT:Think()

	self:NextThink(CurTime())
	local effectdata = EffectData()
	local muzzledat = self:GetAttachment(1)
	effectdata:SetOrigin(muzzledat.Pos + muzzledat.Ang:Forward()*13)
	muzzledat.Ang:RotateAroundAxis(muzzledat.Ang:Up(),180)
	effectdata:SetAngles(muzzledat.Ang)
	effectdata:SetScale(0.5)
	util.Effect("MuzzleEffect", effectdata)	
	return true

end