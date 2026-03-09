wp.falseworlds = wp.falseworlds or {}

-- Example world for testing and helping people learn how to make them
wp.falseworlds.example = {
    origin = Vector(-230,0,0), -- origin point all positioning will be based on
    baselight = Vector(0.2,0.2,0.2), -- base light level
    skybox = { -- use a model as a skybox, useful for space ceilings, though not required
        model = "models/hunter/misc/shell2x2.mdl",
        pos = Vector(0,0,0),
        angle = Angle(0,0,0),
    },
    models = {
        vending = {
            model = "models/props_interiors/VendingMachineSoda01a.mdl",
            pos = Vector(-180,0,-3),
            angle = Angle(0,0,0)
            scale = Ve
        },
        tower = {
            model = "models/props_phx/huge/tower.mdl",
            pos = Vector(0,0,-2015),
            angle = Angle(0,0,0)
        },
    },
    lights = { -- These lights are fed in directly using the LocalLight structure
        {
            color = Vector(1,0,0),
            pos = Vector(0,0,20),
        },
        {
            color = Vector(0,0,1),
            pos = Vector(0,200,20),
        },
        {
            color = Vector(0,1,0),
            pos = Vector(0,-200,20),
        },
    }
}

if SERVER then return end

function wp.createfalseworld(portal, plyOrigin, plyAngle, width, height, fov)

    local fwname = portal:GetFalseWorld()

    local falseworld = wp.falseworlds[fwname]

    if not falseworld then
        print("Cant find false world!!")
        return
    end

    local origin = -falseworld.origin or Vector()

    local baselight = falseworld.baselight or Vector()

    cam.Start3D(plyOrigin+origin, plyAngle, fov, 0, 0, width, height)
        local exit_forward = -portal:GetForward()

        local oldEC = render.EnableClipping( true )

        local function DrawPart(rawpart)
            local skybox = rawpart.skybox
            local model = rawpart.model
            local pos = rawpart.pos or Vector()
            local angle = rawpart.angle or Angle()
            local rendergroup = rawpart.rendergroup or "RENDERGROUP_OPAQUE"
            local part = ClientsideModel(model, rendergroup)
            part:SetNoDraw(true)
            if skybox then
                part:SetPos(plyOrigin+origin)
            else
                part:SetPos(pos)
            end
            part:SetPoseParameter(1,pose or 0)
            local portalangle = portal:GetAngles()
            part:SetAngles(angle)
            if not skybox then
                render.ResetModelLighting(baselight.x,baselight.y,baselight.z)
                render.SetLocalModelLights(falseworld.lights)
            end
            if skybox then
                render.OverrideDepthEnable(true, false)
                part:DrawModel()
                render.OverrideDepthEnable(false)
            else
                part:DrawModel()
            end
            part:Remove()
        end

        if falseworld.skybox then
            skybox = falseworld.skybox
            skybox.skybox = true
            DrawPart(skybox)
        end

        render.PushCustomClipPlane( exit_forward, exit_forward:Dot( origin - exit_forward * 0.5 ) )
            for k,v in pairs(falseworld.models) do
                DrawPart(v)
            end
        render.PopCustomClipPlane()

        render.EnableClipping( oldEC )

    cam.End3D()

end