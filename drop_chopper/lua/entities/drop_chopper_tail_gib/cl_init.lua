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
   local ClipDepth = 0
   local pos = self:GetPos()+self:GetAngles():Right()*-110
   local normal = self:GetAngles():Right()*1 --1 Clips down from the top, -1 Clips up from the bottom
   local distance = normal:Dot(pos)
   
   render.EnableClipping(true)
   
   render.PushCustomClipPlane(normal, distance)
      render.Model({
         model = "models/jessev92/rambo/vehicles/uh1n_hull.mdl",
         pos = vecMod(self:GetPos(), self:GetAngles(), Vector(-6,-250,-35)),
         angle = angMod(self:GetAngles(), Angle(5,0,90))
      })

   render.PopCustomClipPlane()	

   render.EnableClipping(false)
end