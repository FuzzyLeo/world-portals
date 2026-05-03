
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
local COLOR_CHILD = Color(255, 220, 0, 220)
local COLOR_CHILD_VISIBLE = Color(255, 140, 0, 220)

-- Project a portal's clipped quad to player screen pixels using the
-- player's camera (via :ToScreen()).
local function projectQuadScreen(portal, camPos, camFwd)
    local c1, c2, c3, c4 = getPortalCorners(portal)
    local pts = clipQuadToCamera(c1, c2, c3, c4, camPos, camFwd)
    local out = {}
    for _, v in ipairs(pts) do
        local s = v:ToScreen()
        out[#out + 1] = { x = s.x, y = s.y }
    end
    return out
end

-- Project a portal's clipped quad to player screen pixels through a custom
-- (inner) camera. The inner camera renders to a screen-aligned RT, so a
-- feature at inner-NDC (u, v) lands at player-screen NDC (u, v).
local function projectQuadScreenNDC(portal, camPos, camFwd, camRight, camUp, tanHalfH, tanHalfV)
    local c1, c2, c3, c4 = getPortalCorners(portal)
    local pts = clipQuadToCamera(c1, c2, c3, c4, camPos, camFwd)
    local out = {}
    local sw, sh = ScrW(), ScrH()
    for _, v in ipairs(pts) do
        local rel = v - camPos
        local d = rel:Dot(camFwd)
        local ndcX = rel:Dot(camRight) / (d * tanHalfH)
        local ndcY = rel:Dot(camUp)    / (d * tanHalfV)
        out[#out + 1] = {
            x = (ndcX + 1) * 0.5 * sw,
            y = (1 - ndcY) * 0.5 * sh,
        }
    end
    return out
end

local function projectPolyOntoAxis(pts, ax, ay)
    local mn, mx = math.huge, -math.huge
    for _, p in ipairs(pts) do
        local d = p.x * ax + p.y * ay
        if d < mn then mn = d end
        if d > mx then mx = d end
    end
    return mn, mx
end

-- Test each edge of polygon `axes` as a candidate separating axis: project
-- both polygons onto the edge's normal and report disjoint ranges.
local function hasSeparatingEdge(axes, other)
    local function testEdge(p1, p2)
        local ax = -(p2.y - p1.y)
        local ay = p2.x - p1.x
        local aMin, aMax = projectPolyOntoAxis(axes, ax, ay)
        local bMin, bMax = projectPolyOntoAxis(other, ax, ay)
        return aMax < bMin or bMax < aMin
    end

    local first, prev
    for _, p in ipairs(axes) do
        if prev then
            if testEdge(prev, p) then return true end
        else
            first = p
        end
        prev = p
    end
    if first and prev and prev ~= first then
        if testEdge(prev, first) then return true end
    end
    return false
end

-- Convex-polygon intersection via Separating Axis Theorem. Both inputs are
-- assumed convex (which our near-plane-clipped quads always are).
local function polygonsIntersect(a, b)
    if #a < 3 or #b < 3 then return false end
    if hasSeparatingEdge(a, b) then return false end
    if hasSeparatingEdge(b, a) then return false end
    return true
end

local function drawScreenPolygon(pts)
    if #pts < 2 then return end
    local first, prev
    for _, p in ipairs(pts) do
        if prev then
            surface.DrawLine(prev.x, prev.y, p.x, p.y)
        else
            first = p
        end
        prev = p
    end
    if first and prev and prev ~= first then
        surface.DrawLine(prev.x, prev.y, first.x, first.y)
    end
end

local function drawChildOverlays(parent, plyOrigin, plyAngles, plyFov, aspect, portals, parentPts)
    local exit = parent:GetExit()
    if not IsValid(exit) then return end

    local innerOrigin = wp.TransformPortalPos(plyOrigin, parent, exit)
    local innerAngles = wp.TransformPortalAngle(plyAngles, parent, exit)
    local innerFwd = innerAngles:Forward()
    local innerRight = innerAngles:Right()
    local innerUp = innerAngles:Up()
    -- Source uses Hor+ scaling: GetFOV() is the horizontal FOV at 4:3
    -- reference; the actual rendering keeps the derived vertical FOV
    -- constant and widens hfov for wider aspects.
    local tanHalfV = math.tan(plyFov * math.pi / 360) * 0.75
    local tanHalfH = tanHalfV * aspect

    for _, child in pairs(portals) do
        if IsValid(child)
           and wp.shouldrender(child, innerOrigin, innerAngles, plyFov) then
            local pts = projectQuadScreenNDC(child, innerOrigin, innerFwd, innerRight, innerUp, tanHalfH, tanHalfV)
            local color = polygonsIntersect(parentPts, pts) and COLOR_CHILD_VISIBLE or COLOR_CHILD
            surface.SetDrawColor(color)
            drawScreenPolygon(pts)
        end
    end
end

hook.Add("HUDPaint", "WorldPortals_Debug", function()
    if not GetConVar("worldportals_debug"):GetBool() then return end

    local camPos = EyePos()
    local camAng = EyeAngles()
    local camFwd = camAng:Forward()
    local camFov = LocalPlayer():GetFOV()
    local aspect = ScrW() / ScrH()
    local portals = ents.FindByClass("linked_portal_door")

    for _, portal in ipairs(portals) do
        if IsValid(portal) then
            local rendered = wp.shouldrender(portal)
            local pts = projectQuadScreen(portal, camPos, camFwd)
            surface.SetDrawColor(rendered and COLOR_RENDERED or COLOR_CULLED)
            drawScreenPolygon(pts)

            if rendered then
                drawChildOverlays(portal, camPos, camAng, camFov, aspect, portals, pts)
            end
        end
    end
end)
