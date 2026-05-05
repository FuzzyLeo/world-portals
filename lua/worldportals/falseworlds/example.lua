-- Example world for testing and helping people learn how to make them.
local T = {
    id = "example",
    pos = Vector( -250, 0, 0 ), -- virtual exit/camera position, relative to 0,0,0
    ang = Angle( 0, 0, 0 ), -- virtual exit/camera angle
    baselight = Vector( 0.2, 0.2, 0.2 ), -- base light level
    skybox = { -- skybox models follow the camera, useful for space ceilings, though not required
        model = "models/hunter/misc/shell2x2.mdl",
        ang = Angle( 0, 0, 0 ),
    },
    models = { -- model pos/ang values are in false-world coordinates, relative to 0,0,0
        vending = {
            model = "models/props_interiors/VendingMachineSoda01a.mdl",
            pos = Vector( 180, -70, -3 ),
            ang = Angle( 0, 180, 0 ),
            color = Vector( 0, 1, 0 ),
        },
        tube = {
            model = "models/props_phx/construct/windows/window_curve360x2.mdl",
            pos = Vector( 180, 70, -50 ),
            ang = Angle( 0, 180, 0 ),
            scale = Vector( 0.5, 0.5, 1.7 ),
        },
        tower = {
            model = "models/props_phx/huge/tower.mdl",
            pos = Vector( 0, 0, -2015 ),
            ang = Angle( 0, 0, 0 ),
        },
    },
    lights = { -- LocalLight positions are in false-world coordinates, relative to 0,0,0
        { color = Vector( 1, 0, 0 ), pos = Vector( 0, 0, 20 ) },
        { color = Vector( 0, 0, 1 ), pos = Vector( 0, -200, 20 ) },
        { color = Vector( 0, 1, 0 ), pos = Vector( 0, 200, 20 ) },
    },
}

wp.addfalseworld( T )
