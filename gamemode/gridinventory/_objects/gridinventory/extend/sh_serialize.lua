local meta = FindMetaTable("GridInventory")

-- Utility function for turning a table of contained items or containers into a single serialized string.
local function SerializeLine(line)
	local ret = ""
	for i = 1, #line do
		local item = line[i]
		local _, itemOrigin, itemRot = item:GetBackpackInputVars()
		ret = ret .. gamemode.Call("SerializeBackpackItem", item, itemOrigin, itemRot) .. (i == #line and "" or ITEM_SERL_LINE_SEPARATOR)
	end

	return ret
end

-- Output our contents in serialized format. Used for saving our contents to file or database.
function meta:Serialize()
	local tab = {}
	tab.c = SerializeLine(self:GetHeldContainers())
	tab.i = SerializeLine(self:GetHeldItems())

	return util.TableToJSON(tab)
end

function meta:LoadFromSerializedLine(line)
	for i = 1, #line do
		local id, backpackidx, rotidx = gamemode.Call("DeserializeBackpackItem", line[i])
		self:BindNewItemObj(id, backpackidx, rotidx)
		self:Validate()
	end
end

function meta:LoadFromSerialized(serl)
	-- From combat we load from an empty board anyways. But what if we're inspecting previous builds of our's?
	self:Clear()

	local tab = util.JSONToTable(serl)

	local serlContainers = string.Explode(ITEM_SERL_LINE_SEPARATOR, tab.c)
	self:LoadFromSerializedLine(serlContainers)

	local serlItems = string.Explode(ITEM_SERL_LINE_SEPARATOR, tab.i)
	self:LoadFromSerializedLine(serlItems)
end