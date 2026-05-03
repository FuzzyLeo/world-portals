
CreateClientConVar("worldportals_debug", "0", true, false, "World Portals - Show portal render-decision debug overlay", 0, 1)

local NEAR_EPS = 1

local function getPortalCorners(portal)
    local pos = portal:GetPos()
    local fwd = portal:GetForward()
    local right = portal:GetRight()
    local up = portal:GetUp()
    local hw = portal:GetWidth() * 0.5
    local hh = portal:GetHeight() * 0.5
    -- visible face sits at pos - fwd*5 (matches DrawQuadEasy in entity cl_init.lua)
    local center = pos - fwd * 5
    return
        center + right * hw + up * hh,
        center - right * hw + up * hh,
        center - right * hw - up * hh,
        center + right * hw - up * hh
end

-- Sutherland-Hodgman clip of a quad against the half-space in front of the
-- camera (signed distance along camFwd > NEAR_EPS). Returns 0..5 world-space
-- points.
local function clipQuadToCamera(c1, c2, c3, c4, camPos, camFwd)
    local pts = {}

    local function clipEdge(a, b)
        local da = (a - camPos):Dot(camFwd) - NEAR_EPS
        local db = (b - camPos):Dot(camFwd) - NEAR_EPS
        if da > 0 then
            pts[#pts + 1] = a
            if db <= 0 then
                pts[#pts + 1] = a + (b - a) * (da / (da - db))
            end
        elseif db > 0 then
            pts[#pts + 1] = a + (b - a) * (da / (da - db))
        end
    end

    clipEdge(c1, c2)
    clipEdge(c2, c3)
    clipEdge(c3, c4)
    clipEdge(c4, c1)
    return pts
end

local COLOR_RENDERED = Color(0, 255, 0, 220)
local COLOR_CULLED = Color(255, 60, 60, 220)

local function drawClippedQuad(portal, camPos, camFwd)
    local c1, c2, c3, c4 = getPortalCorners(portal)
    local pts = clipQuadToCamera(c1, c2, c3, c4, camPos, camFwd)
    if #pts < 2 then return end

    local first, prev
    for _, v in ipairs(pts) do
        local s = v:ToScreen()
        if prev then
            surface.DrawLine(prev.x, prev.y, s.x, s.y)
        else
            first = s
        end
        prev = s
    end
    if first and prev and prev ~= first then
        surface.DrawLine(prev.x, prev.y, first.x, first.y)
    end
end

hook.Add("HUDPaint", "WorldPortals_Debug", function()
    if not GetConVar("worldportals_debug"):GetBool() then return end

    local camPos = EyePos()
    local camFwd = EyeAngles():Forward()

    for _, portal in ipairs(ents.FindByClass("linked_portal_door")) do
        if IsValid(portal) then
            local rendered = wp.shouldrender(portal)
            surface.SetDrawColor(rendered and COLOR_RENDERED or COLOR_CULLED)
            drawClippedQuad(portal, camPos, camFwd)
        end
    end
end)
