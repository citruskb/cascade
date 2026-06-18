local gridSquare = {Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)}

local data = {
	name = "Wooden Crate",
	description = "It's just a crate.",

	model = "models/props_junk/wood_crate001a.mdl",
	fov = 60,
	camPos = Vector(1, 0, 0),

	triggerDelay = 4,
	retriggerable = true,
	hitboxPoints = {
		[1] = {	Vector2(0, 0),
				Vector2(30, 0),
				Vector2(30, 30),
				Vector2(0, 30)},
	},

	gridPoints = gridSquare,

	DoActivate = function(me, other) end
}

gamemode.Call("RegisterBackpackItem", data)