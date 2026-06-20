function GM:RegisterBackpackItem(id, tab)
	self.BackpackItems[id] = tab
	if tab.hidden then return end

	if CLIENT then tab.clEnt = ClientsideModel(tab.model) end
	-- Do other things here.
end

function GM:RegisterBackpackItems()
	self.BackpackItems = {}

	local included = {}

	local itemfiles, itemdirectories = file.Find(self.FolderName .. "/gamemode/backpack_items/*", "LUA")
	table.sort(itemfiles)
	--table.sort(itemdirectories)

	for i, filename in ipairs(itemfiles) do
		if string.sub(filename, -4) ~= ".lua" then continue end

		ITEM = {}

		AddCSLuaFile("backpack_items/" .. filename)
		include("backpack_items/" .. filename)

		self:RegisterBackpackItem(ITEM.id, ITEM)

		included[filename] = ITEM
		ITEM = nil
	end

	for k, v in pairs(self.BackpackItems) do

		local base = v.base
		if not base then continue end

		base = base .. ".lua"
		if included[base] then
			local old_Hidden = v.hidden
			local old_ID = v.id
			local old_Description = v.description

			table.Inherit(v, included[base])

			-- Don't inherit these.
			v.hidden = old_Hidden
			v.id = old_ID
			v.description = old_Description
		else
			ErrorNoHalt("ITEM " .. tostring(v.name) .. " uses base class " .. base .. " but it doesn't exist!")
		end
	end
end

if GAMEMODE then GAMEMODE:RegisterBackpackItems() end
if GM then GM:RegisterBackpackItems() end