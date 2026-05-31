-- Options

hook.Add("PopulateToolMenu", "WorldPortals_PopulateToolMenu", function()
    ---@diagnostic disable-next-line: deprecated
    spawnmenu.AddToolMenuOption("Options", "World Portals", "WorldPortals_Options", "Settings", "", "", function(panel)
        panel:ClearControls()

        local title = vgui.Create("DLabel")
        title:SetText("World Portals")
        panel:AddItem(title)

        local enabled = vgui.Create("DCheckBoxLabel")
        enabled:SetText("Enable portals")
        enabled:SetConVar("worldportals_enabled")
        enabled:SetTooltip("When off, portals don't render and entity Draw bails. Saves the per-frame engine RenderView allocations the recursion produces.")
        panel:AddItem(enabled)

        local recursion = vgui.Create("DNumSlider")
        recursion:SetText("Recursion depth")
        recursion:SetMinMax(1, 9)
        recursion:SetDecimals(0)
        recursion:SetConVar("worldportals_recurse_depth")
        recursion:SetTooltip("Default: 2. Higher = portals seen through portals seen through portals... up to 9 levels.")
        panel:AddItem(recursion)

        local clones = vgui.Create("DCheckBoxLabel")
        clones:SetText("Continuous entity clones")
        clones:SetConVar("worldportals_clones")
        clones:SetTooltip("Render props mid-teleport as two clipped halves so they look continuous across the portal instead of being cut off.")
        panel:AddItem(clones)

        local debugMode = vgui.Create("DComboBox")
        debugMode:SetSortItems(false)
        debugMode:AddChoice("Off", 0)
        debugMode:AddChoice("Clipped to visible", 1)
        debugMode:AddChoice("Rendered only", 2)
        debugMode:AddChoice("All including culled", 3)
        debugMode:SetValue(({[0]="Off",[1]="Clipped to visible",[2]="Rendered only",[3]="All including culled"})
            [GetConVar("worldportals_debug"):GetInt()] or "Off")
        debugMode.OnSelect = function(_, _, _, value)
            RunConsoleCommand("worldportals_debug", tostring(value))
        end
        local debugLabel = vgui.Create("DLabel")
        debugLabel:SetText("Debug overlay")
        panel:AddItem(debugLabel)
        panel:AddItem(debugMode)
    end)
end)
