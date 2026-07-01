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