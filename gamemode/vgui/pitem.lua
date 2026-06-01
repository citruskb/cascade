-- Representative of an underlying game object.
-- Need to pull said data from that registered object and display it here.


-- [[ Step 1 ]]
-- Need to define collection of "hitbox" panels for physics collision
-- dCollisionPanel?
-- These hitbox panels may be irregularly shapped (Circular? Polynomial?)
-- example: https://gist.github.com/meepen/4b591bf1e26ec9ad97df244a6f265d29


-- [[ Step 2 ]]
-- Physics can be on or off
    -- Collides & bounces against other objects while physics is on

-- Can be frozen or unfrozen
    -- Frozen (physics disabled): in shop, or set in grid inventory, or preview
    -- Unfrozen (physics enabled): in inventory


-- [[ Step 3 ]]
-- Snap into and out of inventory grid
-- Optionally can be placed tangental to the existing grid


-- [[ Step 4 ]]
-- Displays object through a 3d model projected on 2d surface
    -- Define details like item size, rotation, color, etc from registered object data?

-- Specific animation sequence that plays when item activates
-- Could spin, flash, grow and shrink in size, shake, wobble, etc

-- Add noises to pick up/dropping and to collision bounce


PANEL = {}
vgui.Register("PItem", PANEL, "DPanel")