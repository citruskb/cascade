-- Used to determine physics collision.
-- These hitbox panels may be irregularly shapped (Circular? Polynomial?)

-- Pulls heavily from: https://gist.github.com/meepen/4b591bf1e26ec9ad97df244a6f265d29
-- Why reinvent the wheel?

--local debugMat = surface.GetTextureID("vgui/white")

PANEL = {}

--[[
function PANEL:Init()
    self.ObjectCount = 4 -- Assume we are a square.
    self:InvalidateLayout(true)
end

function PANEL:PerformLayout(w, h)
    w = math.Min(w, h)
    local r = w * 0.5
    local obj = {}
    for i = 1, w * 2 do
        -- clockwise
        local d = math.Rad(-i / w * 180)
        obj[i] = {
            x = math.Sin(d) * r + r,
            y = math.Cos(d) * r + r,
        }
    end
    self.Poly = obj

    local lines = {}

    for i = 1, self.ObjectCount do

        local pos = Angle(0,360 / self.ObjectCount * i, 0):Forward():GetNormalized() * r
        lines[i] = {
            x = pos.x + r,
            y = pos.y + r
        }

    end

    self.Lines = lines
end
]]

vgui.Register("DHitbox", PANEL, "DPanel")