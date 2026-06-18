if not BackpackItem then
	GM.BackpackItems = {}
	BackpackItem = Class:Create(nil, "BackpackItem")
end

function BackpackItem:__Create(data)
	self.name = data.name
	self.description = data.description
	self.model = data.model
	self.triggerDelay = data.triggerDelay
	self.retriggerable = data.retriggerable
	self.hitboxPoints = data.hitboxPoints
	self.gridPoints = data.gridPoints
	self.DoActivate = data.DoActivate
end

function GM:RegisterBackpackItem(data) BackpackItem:Create(data) end