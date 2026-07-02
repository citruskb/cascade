local meta = FindMetaTable("GridInventory")

-- Utility function for turning a table of contained items or containers into a single serialized string.
local function SerializeLine(line)
	local ret = ""
	for i = 1, #line do
		local item = line[i]
		local itemOrigin = item.gridPointEvaluator.bindPointsOriginIDX
		local itemRot = item.gridPointEvaluator.rotidx
		ret = ret .. gamemode.Call("SerializeBackpackItem", line[i], itemOrigin, itemRot) .. (i == #line and "" or ITEM_SERL_LINE_SEPARATOR)
	end
end

-- Output our contents in serialized format. Used for saving our contents to file or database.
function meta:Serialize()
	local tab = {}
	tab.c = SerializeLine(self:GetHeldContainers())
	tab.i = SerializeLine(self:GetHeldItems())

	return util.TableToJSON(tab)
end

--[[ TODO: Need to implement direct item insertion first.
function meta:LoadFromSerializedLine(line)
	for i = 1, #line do
		local id, backpackidx, rotidx = gamemode.Call("DeserializeBackpackItem", line[i])

		-- get a "good enough" position.
		local originCell = self.cellsScreenIDX[backpackidx]
		local bestBindPoint = originCell:GetAssocScreenBindPoint()

		-- get our rotation.
		local rot = ITEM_ORIENTATION_TO_ANGLE[rotidx]

		-- Spawn the item.
		local item = ItemObj:Create(id, bestBindPoint, rot)

		-- We want to line up the item so that the origin bindpoint lines up with the origin backpack point.
		item:StepBindPoints()
		item.position = item.position + item:GetStepGridDelta()

		-- Now we need to properly bind it.
		item:StepBindPoints()
		item.gridPointEvaluator:BindItem(item)
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
]]