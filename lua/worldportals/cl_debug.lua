
CreateClientConVar("worldportals_debug", "0", true, false, "World Portals - Show portal render-decision debug overlay", 0, 1)

local COLOR_RENDERED = Color(0, 255, 0, 220)
local COLOR_CULLED = Color(255, 60, 60, 220)
local COLOR_CHILD = Color(255, 220, 0, 220)
local COLOR_CHILD_VISIBLE = Color(255, 140, 0, 220)

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

    for _, child in pairs(portals) do
        if IsValid(child)
           and wp.shouldrender(child, innerOrigin, innerAngles, plyFov) then
            local pts = wp.GetPortalScreenPolygon(child, innerOrigin, innerAngles, plyFov, aspect)
            local color = wp.PolygonsIntersectSAT(parentPts, pts) and COLOR_CHILD_VISIBLE or COLOR_CHILD
            surface.SetDrawColor(color)
            drawScreenPolygon(pts)
        end
    end
end

hook.Add("HUDPaint", "WorldPortals_Debug", function()
    if not GetConVar("worldportals_debug"):GetBool() then return end

    local camPos = EyePos()
    local camAng = EyeAngles()
    local camFov = LocalPlayer():GetFOV()
    local aspect = ScrW() / ScrH()
    local portals = ents.FindByClass("linked_portal_door")

    for _, portal in ipairs(portals) do
        if IsValid(portal) then
            local rendered = wp.shouldrender(portal)
            local pts = wp.GetPortalScreenPolygon(portal, camPos, camAng, camFov, aspect)
            surface.SetDrawColor(rendered and COLOR_RENDERED or COLOR_CULLED)
            drawScreenPolygon(pts)

            if rendered then
                drawChildOverlays(portal, camPos, camAng, camFov, aspect, portals, pts)
            end
        end
    end

    local SHADOW = Color(0, 0, 0, 220)
    local x = 16
    local lineH = 22
    local total = wp.GetFramePortalRenderCount()
    local byDepth = wp.GetFramePortalRenderByDepth()
    local maxDepth = wp.GetRecurseDepth()

    -- Center the block vertically around screen midline.
    local visibleDepths = 0
    for d = 1, maxDepth do
        if (byDepth[d] or 0) > 0 then visibleDepths = visibleDepths + 1 end
    end
    local totalLines = 1 + visibleDepths
    local y = math.floor(ScrH() * 0.5 - ((totalLines - 1) * lineH) * 0.5)

    draw.SimpleTextOutlined("Portal renders: " .. total, "Trebuchet18", x, y,
        color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, SHADOW)
    y = y + lineH
    for d = 1, maxDepth do
        local c = byDepth[d] or 0
        if c > 0 then
            draw.SimpleTextOutlined(("  D%d: %d"):format(d, c), "Trebuchet18", x, y,
                color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, SHADOW)
            y = y + lineH
        end
    end
end)
