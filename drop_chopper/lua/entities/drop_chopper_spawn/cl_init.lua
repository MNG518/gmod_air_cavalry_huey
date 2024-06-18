include('shared.lua')

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


function ENT:Draw()
     self:DrawModel()
     render.SetMaterial(Material("helipad"))
     render.DrawQuadEasy(self:GetPos()+Vector(0,0,10), Angle():Up(), 512,512, Color(255,255,255), self:GetAngles().y)

end

