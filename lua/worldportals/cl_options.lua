-- Options

hook.Add("PopulateToolMenu", "WorldPortals_PopulateToolMenu", function()
    ---@diagnostic disable-next-line: deprecated
    spawnmenu.AddToolMenuOption("Options", "World Portals", "WorldPortals_Options", "Settings", "", "", function(panel)
        panel:ClearControls()

        local title = vgui.Create("DLabel")
        title:SetText("World Portals")
        panel:AddItem(title)

        local resolution = vgui.Create("DNumSlider")
        resolution:SetText("Render resolution percentage")
        resolution:SetMinMax(1, 100)
        resolution:SetDecimals(0)
        resolution:SetConVar("worldportals_resolution_percentage")
        resolution:SetTooltip("Default: 100")
        panel:AddItem(resolution)

        local recursion = vgui.Create("DNumSlider")
        recursion:SetText("Recursion depth")
        recursion:SetMinMax(1, 9)
        recursion:SetDecimals(0)
        recursion:SetConVar("worldportals_recurse_depth")
        recursion:SetTooltip("Default: 1")
        panel:AddItem(recursion)
    end)
end)
