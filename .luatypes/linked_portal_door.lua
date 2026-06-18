---@meta

-- Type contract for the linked_portal_door entity, so portal-typed vars (wp.portals,
-- the render sort buffer) resolve the runtime fields cl_render.lua stashes on the
-- entity table - the WP* per-frame pose/chain cache - instead of flagging them as
-- undefined once the var is strictly typed. glua_ls resolves NetworkVar accessors
-- (GetExit, GetOpen, ...) on its own but NOT AccessorFunc ones, so SetTexture/
-- GetTexture (and GetExit's portal-typed return) are declared here too. Adding a new
-- WP* field or AccessorFunc read on a portal-typed var -> declare it here, or the
-- strict type trips undefined-field.

---@class LinkedPortalDoor : Entity
---@field WPPosX number
---@field WPPosY number
---@field WPPosZ number
---@field WPFwdX number
---@field WPFwdY number
---@field WPFwdZ number
---@field WPRtX number
---@field WPRtY number
---@field WPRtZ number
---@field WPUpX number
---@field WPUpY number
---@field WPUpZ number
---@field WPAngP number
---@field WPAngY number
---@field WPAngR number
---@field WPEPOffX number
---@field WPEPOffY number
---@field WPEPOffZ number
---@field WPEAOffP number
---@field WPEAOffY number
---@field WPEAOffR number
---@field WPCacheFrame number
---@field WPSortKey number
---@field WPDepth1ChainKey string
---@field WPLastChainKey string
---@field WPLastChainKeyDepth number
---@field WPLastChainKeyQX number
---@field WPLastChainKeyQY number
---@field WPLastChainKeyQZ number
---@field WPDecKey string
---@field WPDecKeyDepth number
---@field WPDecKeyQX number
---@field WPDecKeyQY number
---@field WPDecKeyQZ number
---@field WPLastRenderedChainKey string
---@field WPLastRenderedDepth number
---@field WPLastRenderedTexture ITexture
---@field WPLastDrawChainKey string
---@field WPLastDrawChainDepth number
---@field WPLastDrawChainCam Vector
---@field WPTexture1 ITexture
---@field WPTexture1Width number
---@field WPTexture1Height number
local LinkedPortalDoor = {}

---@return LinkedPortalDoor
function LinkedPortalDoor:GetExit() end

---@param texture ITexture
function LinkedPortalDoor:SetTexture(texture) end

---@return ITexture
function LinkedPortalDoor:GetTexture() end
