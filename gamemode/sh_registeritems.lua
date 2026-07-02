
ITEM_TYPE_CONTAINER = 1
ITEM_TYPE_NORMAL = 2
ITEM_TYPE_AUGMENT = 3

ITEM_RARITY_BASIC = 1
ITEM_RARITY_UNCOMMON = 2
ITEM_RARITY_RARE = 3
ITEM_RARITY_EPIC = 4
ITEM_RARITY_LEGENDARY = 5

ITEM_ORIENTATION_0 = 1
ITEM_ORIENTATION_90 = 2
ITEM_ORIENTATION_180 = 3
ITEM_ORIENTATION_270 = 4

ITEM_ANGLE_TO_ORIENTATION = {
	[0] = ITEM_ORIENTATION_0,
	[90] = ITEM_ORIENTATION_90,
	[180] = ITEM_ORIENTATION_180,
	[270] = ITEM_ORIENTATION_270,
}

ITEM_ORIENTATION_TO_ANGLE = {
	[ITEM_ORIENTATION_0] = 0,
	[ITEM_ORIENTATION_90] = 90,
	[ITEM_ORIENTATION_180] = 180,
	[ITEM_ORIENTATION_270] = 270,
}

if CLIENT then
	ItemRarityColors = {
		[ITEM_RARITY_BASIC] = Color(170, 170, 170, 255),
		[ITEM_RARITY_UNCOMMON] = Color(200, 240, 205, 255),
		[ITEM_RARITY_RARE] = Color(180, 200, 230, 255),
		[ITEM_RARITY_EPIC] = Color(200, 150, 220, 255),
		[ITEM_RARITY_LEGENDARY] = Color(255, 230, 150, 255),
	}

	ItemRarityTxtColors = {
		[ITEM_RARITY_BASIC] = Color(22, 22, 22, 255),
		[ITEM_RARITY_UNCOMMON] = Color(0, 100, 00, 255),
		[ITEM_RARITY_RARE] = Color(50, 85, 150, 255),
		[ITEM_RARITY_EPIC] = Color(110, 50, 160, 255),
		[ITEM_RARITY_LEGENDARY] = Color(200, 90, 15, 255),
	}
end

function GM:RegisterBackpackItem(id, tab)
	self.BackpackItems[id] = tab
	if tab.hidden then return end

	if CLIENT then
		local ent = ClientsideModel(tab.model, RENDERGROUP_OTHER)
		if not IsValid(ent) then return end

		ent:SetNoDraw(true)

		local scale = tab.modelScale
		if scale ~= Vector(1, 1, 1) then
			local matrix = Matrix()
			matrix:Scale(scale)
			ent:EnableMatrix("RenderMultiply", matrix)
		end

		tab.clEnt = ent
	end
	-- Do other things here.
end

function GM:RegisterBackpackItems()
	self.BackpackItems = {}

	local included = {}

	local function LoadFile(dir, fileName)
		if string.sub(fileName, -4) ~= ".lua" then return end
		ITEM = {}

		AddCSLuaFile(dir .. fileName)
		include(dir .. fileName)

		self:RegisterBackpackItem(ITEM.id, ITEM)

		included[fileName] = ITEM
		ITEM = nil
	end

	local function LoadDirectory(dir)
		local files, dirs = file.Find(self.FolderName .. "/gamemode/" .. dir .. "*", "LUA")

		table.Sort(files)
		table.Sort(dirs)

		for i, fileName in ipairs(files) do LoadFile(dir, fileName) end
		for i, recursiveDir in ipairs(dirs) do LoadDirectory(dir .. recursiveDir .. "/") end
	end

	local baseDir = "itemregistry/"
	LoadDirectory(baseDir)

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

if GAMEMODE then
	GAMEMODE:RegisterBackpackItems()
elseif GM then
	GM:RegisterBackpackItems()
end