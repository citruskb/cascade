--[[
TODO

This should act as a parent element to all backpack item behaviors.
This just needs an associated physbox. Leave the physobj2d library to handle everything about that.

General items:
- Must be placed on a container.
- Cannot be placed ontop of other items.

Containers (child of general items):
- Must be placed directly into the grid inventory.
- Cannot be placed ontop of other containers.

Augments (child of general items):
- Must be placed into containers or into a socket.

And would implement custom behavior, particularly on the grid inventory.

]] 