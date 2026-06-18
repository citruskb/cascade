local data = {
	name = "Wooden Crate",
	description = "It's just a crate.",
	model = "models/props_junk/wood_crate001a.mdl",
	triggerDelay = 4,
	retriggerable = true,
	hitboxPoints = {
		[1] = {	Vector2(0, 0),
				Vector2(30, 0),
				Vector2(30, 30),
				Vector2(0, 30)},
	},
	gridPoints = {	-- 0, 0 is the upper left corner.
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(0, 1),
		Vector2(1, 1),
	},
	DoActivate = function(me, opponent) end
}

gamemode.Call("RegisterBackpackItem", data)