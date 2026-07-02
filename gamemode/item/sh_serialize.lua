--[[
	These should never, ever changed or removed. Unless you want to break every existing saved build. 
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

ITEM_BANANA = 1
ITEM_BLAST_DOOR = 2
ITEM_PLANK = 3
ITEM_BRIEFCASE = 4
ITEM_HULA_DOLL = 5

ITEM_SERL_SEPARATOR = "-"
ITEM_SERL_LINE_SEPARATOR = ","

-- Takes the item.
-- Returns the serialization.
function GM:SerializeBackpackItem(item, backpackidx, rotidx)
	local str = ""
	str = str .. ToString(item.itemData.type) .. ITEM_SERL_SEPARATOR
	str = str .. ToString(item.itemData.sid) .. ITEM_SERL_SEPARATOR
	str = str .. backpackidx .. ITEM_SERL_SEPARATOR
	str = str .. rotidx

	return str
end

-- Takes an item serialization.
-- Returns deserialized item data
function GM:DeserializeBackpackItem(serl)
	local str = string.Explode(ITEM_SERL_SEPARATOR, serl)
	local typ, sid = ToNumber(str[1]), ToNumber(str[2])
	local backpackidx = str[3]
	local rotidx = ToNumber(str[4])

	-- TODO: build a table to load this when registering items.
	local foundid
	for id, data in pairs(GAMEMODE.BackpackItems) do
		if data.type ~= typ then continue end
		if data.sid ~= sid then continue end
		foundid = id
	end

	return foundid, backpackidx, rotidx
end