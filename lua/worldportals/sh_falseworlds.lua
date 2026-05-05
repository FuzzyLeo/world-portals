wp.falseworlds = wp.falseworlds or {}

local VECTOR_ORIGIN = Vector()
local VECTOR_UP = Vector( 0, 0, 1 )
local ANGLE_ZERO = Angle()
local ANGLE_YAW_180 = Angle( 0, 180, 0 )

function wp.addfalseworld( T )
    if not T.id then
        error( "wp.addfalseworld: missing T.id" )
    end
    wp.falseworlds[T.id] = table.Copy( T )
end

if SERVER then return end

local function TransformFalseWorldAngle( angle, portal, falseWorldAng )
    local l_angle = portal:WorldToLocalAngles( angle )
    l_angle:RotateAroundAxis( VECTOR_UP, 180 )
    local _, w_angle = LocalToWorld( VECTOR_ORIGIN, l_angle, VECTOR_ORIGIN, falseWorldAng )

    return w_angle
end

local function TransformFalseWorldPos( pos, portal, falseWorldPos, falseWorldAng )
    local l_pos = portal:WorldToLocal( pos )
    l_pos:Rotate( ANGLE_YAW_180 )
    local w_pos = LocalToWorld( l_pos, ANGLE_ZERO, falseWorldPos, falseWorldAng )

    return w_pos
end

local function GetFalseWorldExitPose( portal, falseWorldPos, falseWorldAng )
    local exitPos = falseWorldPos
    local exitAng = falseWorldAng

    local posOffset = portal:GetExitPosOffset()
    if posOffset.x ~= 0 or posOffset.y ~= 0 or posOffset.z ~= 0 then
        local rotatedOffset = Vector( posOffset.x, posOffset.y, posOffset.z )
        rotatedOffset:Rotate( falseWorldAng )
        exitPos = falseWorldPos + rotatedOffset
    end

    local angOffset = portal:GetExitAngOffset()
    if angOffset.p ~= 0 or angOffset.y ~= 0 or angOffset.r ~= 0 then
        exitAng = falseWorldAng + angOffset
    end

    return exitPos, exitAng
end

function wp.createfalseworld( portal, plyOrigin, plyAngle, width, height, fov )
    local fwname = portal:GetFalseWorld()
    local falseworld = wp.falseworlds[fwname]

    if not falseworld then
        ErrorNoHalt( "wp.createfalseworld: no registered false world '" .. tostring( fwname ) .. "'\n" )
        return
    end

    local falseWorldPos = falseworld.pos or VECTOR_ORIGIN
    local falseWorldAng = falseworld.ang or ANGLE_ZERO
    local baselight = falseworld.baselight or Vector()
    local exitPos, exitAng = GetFalseWorldExitPose( portal, falseWorldPos, falseWorldAng )
    local camOrigin = TransformFalseWorldPos( plyOrigin, portal, exitPos, exitAng )
    local camAngle = TransformFalseWorldAngle( plyAngle, portal, exitAng )

    cam.Start3D( camOrigin, camAngle, fov, 0, 0, width, height )
        local exit_forward = exitAng:Forward()

        local oldEC = render.EnableClipping( true )

        local function DrawPart( rawpart )
            local skybox = rawpart.skybox
            local model = rawpart.model
            local scale = rawpart.scale
            local color = rawpart.color or Vector( 1, 1, 1 )
            local pos = rawpart.pos or Vector()
            local ang = rawpart.ang or ANGLE_ZERO
            local rendergroup = rawpart.rendergroup
            local part = ClientsideModel( model, rendergroup )
            if not IsValid( part ) then return end
            part:SetNoDraw( true )
            if skybox then
                part:SetPos( camOrigin )
            else
                part:SetPos( pos )
            end
            part:SetAngles( ang )
            render.SetColorModulation( color.x, color.y, color.z )
            if not skybox then
                render.ResetModelLighting( baselight.x, baselight.y, baselight.z )
                render.SetLocalModelLights( falseworld.lights )
            end
            if scale then
                local mat = Matrix()
                mat:Scale( scale )
                part:EnableMatrix( "RenderMultiply", mat )
            end
            if skybox then
                render.OverrideDepthEnable( true, false )
                part:DrawModel()
                render.OverrideDepthEnable( false, false )
            else
                part:DrawModel()
            end
            -- clientside entity MUST be removed after drawing or they stack up every frame
            part:Remove()
        end

        if falseworld.skybox then
            local skybox = falseworld.skybox
            skybox.skybox = true
            DrawPart( skybox )
        end

        render.PushCustomClipPlane( exit_forward, exit_forward:Dot( exitPos - exit_forward * 0.5 ) )
            for _, v in pairs( falseworld.models ) do
                DrawPart( v )
            end
        render.PopCustomClipPlane()

        render.EnableClipping( oldEC )
    cam.End3D()
end

function wp.renderfalseworld( texture, portal, plyOrigin, plyAngle, width, height, fov, depth )
    hook.Call( "wp-prerender", GAMEMODE, portal, nil, plyOrigin, depth )
    render.PushRenderTarget( texture )
        local oldW, oldH = ScrW(), ScrH()
        render.Clear( 0, 0, 0, 0, true, true )
        render.SetViewPort( 0, 0, ScrW(), ScrH() )

        local oldFog = render.GetFogMode()
        render.SuppressEngineLighting( true )
        render.FogMode( MATERIAL_FOG_NONE )

        wp.createfalseworld( portal, plyOrigin, plyAngle, width, height, fov )

        render.OverrideDepthEnable( false, false )
        render.FogMode( oldFog )
        render.SuppressEngineLighting( false )

        render.SetViewPort( 0, 0, oldW, oldH )
    render.PopRenderTarget()
    hook.Call( "wp-postrender", GAMEMODE, portal, nil, plyOrigin, depth )
end
