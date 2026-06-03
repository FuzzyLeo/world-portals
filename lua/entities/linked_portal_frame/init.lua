AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

-- Per-tick portal move above which we SNAP the hull instead of sweeping it (a
-- demat/remat warp can't be swept). Mirrors ComputeShadowControl's teleportdistance.
local SHADOW_TELEPORT_DIST = 128

-- Eight corners of an axis-aligned box in this entity's local space.
local function boxVerts(x0, x1, y0, y1, z0, z1)
    return {
        Vector(x0, y0, z0), Vector(x1, y0, z0), Vector(x0, y1, z0), Vector(x1, y1, z0),
        Vector(x0, y0, z1), Vector(x1, y0, z1), Vector(x0, y1, z1), Vector(x1, y1, z1),
    }
end

function ENT:Initialize()
    self:SetMoveType(MOVETYPE_NONE)
    self:DrawShadow(false)
    self:SetNoDraw(true)
end

-- (Re)build the perimeter-frame collision hull from the portal opening
-- dimensions. Verts are in this entity's local space; parented at the portal
-- with no offset, that equals the portal's local space: +x forward/transit,
-- y the width axis, z the height axis (matching shared.lua SetupBounds, where
-- the opening box is x in [-(5+thickness), -5], y in +-width/2, z in +-height/2).
-- Calling again replaces the previous physics object.
function ENT:BuildFrame(width, height, thickness)
    local slabs = self:FrameSlabs(width, height, thickness)
    if not slabs then
        self:PhysicsDestroy()
        return false
    end

    local meshes = {}
    for _, s in ipairs(slabs) do
        meshes[#meshes + 1] = boxVerts(s[1], s[2], s[3], s[4], s[5], s[6])
    end

    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInitMultiConvex(meshes)
    -- No EnableCustomCollisions: physics-vs-physics is all we need (a prop resting
    -- on a slab); ECC is expensive and would block bullet/use traces too.
    -- COLLISION_GROUP_WEAPON hits world+props but not players, so the frame funnels
    -- props without changing player movement.
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    if not IsValid(self:GetPhysicsObject()) then return false end
    -- Drive the hull as an immovable physics SHADOW (both flags false): external
    -- forces never displace it, yet UpdateShadow can sweep it each tick, and a SWEPT
    -- shadow PUSHES props instead of teleporting past them. A static SetPos'd hull
    -- flung props instead (verified A/B).
    self:MakePhysicsObjectAShadow(false, false)
    local phys = self:GetPhysicsObject()
    if not IsValid(phys) then return false end
    phys:SetMass(50000)
    self:SetMoveType(MOVETYPE_NONE)

    -- The new physobj defaults to colliding -- constraint.NoCollide fires its
    -- disable once and never reapplies -- so re-add the frame<->wall no-collide
    -- or the immovable shadow shoves the shell.
    if self.WallNoCollides then
        for _, c in pairs(self.WallNoCollides) do
            if IsValid(c) then c:Remove() end
        end
        self.WallNoCollides = nil
    end
    wp.NoCollideFrame(self, self.Portal)
    return true
end

-- Follow the portal WITHOUT being parented, driving both the entity transform and
-- the physics hull from here each tick. Not parented because the prop<->shell
-- no-collide would disable the prop against the shell's whole parented subtree, so
-- a parented frame would be phased the instant a prop armed (sv_collision.lua).
function ENT:Think()
    local portal = self.Portal
    if not IsValid(portal) then
        -- Portal gone independently of our OnRemove path; nothing to bound.
        self:Remove()
        return
    end
    local pos, ang = portal:GetPos(), portal:GetAngles()
    if self:GetPos() ~= pos or self:GetAngles() ~= ang then
        self:SetPos(pos)
        self:SetAngles(ang)
    end
    -- Sweep the shadow hull toward the portal so a moving portal pushes props
    -- along with it; snap instead for a single-tick warp (SHADOW_TELEPORT_DIST).
    -- The drift check sweeps while it catches up, leaves it free once converged.
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        local last = self.LastShadowTarget
        if (not last) or pos:Distance(last) > SHADOW_TELEPORT_DIST then
            phys:SetPos(pos)
            phys:SetAngles(ang)
        elseif not phys:GetPos():IsEqualTol(pos, 0.05) or phys:GetAngles() ~= ang then
            phys:Wake()
            phys:UpdateShadow(pos, ang, FrameTime())
        end
        self.LastShadowTarget = pos
    end
    -- Keep the (unparented) hull no-collided with the wall it sits in, so it doesn't
    -- interpenetrate the TARDIS shell and launch it. Low-frequency re-check picks up
    -- the shell once the portal is parented to it and any parts added later.
    local now = CurTime()
    if not self.NextWallCheck or now >= self.NextWallCheck then
        self.NextWallCheck = now + 1
        wp.NoCollideFrame(self, portal)
    end
    self:NextThink(CurTime())
    return true
end
