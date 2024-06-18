include('shared.lua')




function ENT:Initialize()
   PrecacheParticleSystem("fire_jet_01")
   CreateParticleSystem(self, "fire_jet_01", 4, 0)
end

function ENT:Draw()

end