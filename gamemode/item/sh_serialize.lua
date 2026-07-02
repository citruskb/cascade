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

	return BackpackItemsSIDToID[sid], backpackidx, rotidx
end