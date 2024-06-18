ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName		= "Friendly Huey"
ENT.Author			= "MrNiceGuy518"
ENT.Contact			= "mng518workshop@gmail.com"
ENT.Purpose			= "Drops Soldiers"
ENT.Instructions	= ""

ENT.Category = "Air Cavalry"
ENT.Spawnable = false
ENT.AdminSpawnable = false



list.Set( "NPC", "friendly_huey", {
	Name = "Huey (Friendly)", 
	Class = "drop_chopper", 
	Category = "Air Cavalry"
} )