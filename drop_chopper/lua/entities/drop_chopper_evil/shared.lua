ENT.Type = "anim"
ENT.Base = "drop_chopper"
 
ENT.PrintName		= "Hostile Huey"
ENT.Author			= "MrNiceGuy518"
ENT.Contact			= "mng518workshop@gmail.com"
ENT.Purpose			= "Drops Soldiers"
ENT.Instructions	= ""

ENT.Category = "Air Cavalry"
ENT.Spawnable = false
ENT.AdminSpawnable = false


list.Set( "NPC", "hostile_huey", {
	Name = "Huey (Hostile)", 
	Class = "drop_chopper_evil", 
	Category = "Air Cavalry"
} )