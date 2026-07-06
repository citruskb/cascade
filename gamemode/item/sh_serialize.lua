--[[
	These should never, ever be changed or removed. Unless you want to break every existing saved build. 
	Done this way to make serializing inventories take up far less space long-term.
	Instead of having to save the item's id ie. "wooden_crate" we can now simply save it's item type (container->1) and id (->1) to represent the same data.
	
	Adding more is not a problem.
	Changing existing shapes will also break builds.
]]

ITEM_C_WOODEN_CRATE = 1
ITEM_C_HARDDRIVE = 2
ITEM_C_LOCKER = 3
ITEM_C_NIGHTSTAND = 4
ITEM_C_POCKET_DIMENSION = 5
ITEM_BANANA = 6
ITEM_BLAST_DOOR = 7
ITEM_PLANK = 8
ITEM_BRIEFCASE = 9
ITEM_HULA_DOLL = 10

ITEM_SERL_SEPARATOR = "-"
ITEM_SERL_LINE_SEPARATOR = ";"

-- Takes the item.
-- Returns the serialization.
function GM:SerializeBackpackItem(item, backpackidx, rotidx)
	local str = ""
	str = str .. ToString(item.itemData.sid) .. ITEM_SERL_SEPARATOR
	str = str .. ToString(backpackidx) .. ITEM_SERL_SEPARATOR
	str = str .. ToString(rotidx)

	return str
end

-- Takes an item serialization.
-- Returns deserialized item data
function GM:DeserializeBackpackItem(serl)
	local str = string.Explode(ITEM_SERL_SEPARATOR, serl)
	local sid = ToNumber(str[1])
	local backpackidx = ToString(str[2])
	local rotidx = ToNumber(str[3])

	return GAMEMODE.BackpackItemsSIDToID[sid], backpackidx, rotidx
end


--local serializations = {
	--[1] = [[{"c":"2-3x6-2;1-5x5-1;2-5x4-2;4-3x3-2;5-6x3-2;1-3x4-1;3-2x3-1","i":"6-4x6-1;9-3x4-1;10-2x3-1;7-5x3-2"}]],
	--[2] = [[{"c":"1-5x5-1;1-8x6-2;5-6x7-1;2-4x7-2;2-7x2-3;1-8x4-3;2-3x2-1;4-7x1-2;3-7x4-1;1-8x2-4;1-3x5-2;3-6x1-1;4-5x1-3;5-5x4-4;2-3x1-4;4-4x2-3","i":"9-7x6-4;6-7x4-2;9-4x4-1;6-6x1-2;10-4x5-3;7-4x6-3;8-3x5-1;7-8x5-2;10-6x5-2;10-8x2-1;6-5x2-4;10-5x5-1"}]],
	--[3] = [[{"c":"1-6x6-1;1-6x4-1;3-1x7-2;2-4x4-3;2-2x2-3;5-2x1-1;2-4x2-1;4-1x5-2;1-8x4-3;1-6x2-3;1-8x2-2;3-1x6-2;4-1x4-2;5-1x3-3;2-1x1-1;4-3x1-3","i":"9-3x4-1;6-2x3-2;9-3x5-1;10-6x2-1;10-7x3-1;6-4x7-4;8-2x6-2;6-1x7-1;7-6x5-4;10-6x3-1;7-8x3-2;10-7x2-1"}]],
--}

--[[
local serlCounter = 1
timer.Create("TestSerialization", 6, 0, function()
	if not GAMEMODE.backpack then return end

	local idx = (serlCounter % #serializations) + 1
	GAMEMODE.backpack:LoadFromSerialized(serializations[idx])
	serlCounter = serlCounter + 1
end)
]]