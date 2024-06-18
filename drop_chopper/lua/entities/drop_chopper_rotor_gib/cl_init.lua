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
   

   if self:GetNWInt("gn") == 1 then
      
      local ClipDepth = 0
      local pos = self:GetPos()+self:GetAngles():Right()*-30
      local normal = self:GetAngles():Right()*1 --1 Clips down from the top, -1 Clips up from the bottom
      local distance = normal:Dot(pos)

      local pos2 = self:GetPos()+self:GetAngles():Right()*30
      local normal2 = self:GetAngles():Right()*-1 --1 Clips down from the top, -1 Clips up from the bottom
      local distance2 = normal2:Dot(pos2)
      
      render.EnableClipping(true)
      
      render.PushCustomClipPlane(normal, distance)
      render.PushCustomClipPlane(normal2, distance2)


         self:DrawModel()
      render.PopCustomClipPlane()	
      render.PopCustomClipPlane()	



   else

      local ClipDepth = 0
      local pos = self:GetPos()+self:GetAngles():Right()*-115
      local normal = self:GetAngles():Right()*1 --1 Clips down from the top, -1 Clips up from the bottom
      local distance = normal:Dot(pos)
      
      render.EnableClipping(true)
      
      render.PushCustomClipPlane(normal, distance)
         render.Model({
            model = "models/sentry/uh-1d_tr.mdl",
            pos = vecMod(self:GetPos(), self:GetAngles(), Vector(0,-145,-10)),
            angle = angMod(self:GetAngles(), Angle(0,0,0))
         })

      render.PopCustomClipPlane()	

      render.EnableClipping(false)
   end


end