--[[----------------------------------
    DynamicLight Wrapper by Zaurzo
    https://gist.github.com/Zaurzo/c5c2811f77fc6a52e6fa71d34b7229be
-------------------------------------]]

if SERVER then return end

local DLight = FindMetaTable('dlight_t')
local lightCache = setmetatable({}, { __mode = 'v' })

local pairs = pairs
local setmetatable = setmetatable
local math_floor = math.floor
local table_insert = table.insert
local debug_setmetatable = debug.setmetatable
local debug_getmetatable = debug.getmetatable

local function reset_member_values(tbl)
    tbl.brightness = 0
    tbl.decay = 0
    tbl.dietime = 0
    tbl.innerangle = 0
    tbl.outerangle = 0
    tbl.minlight = 0
    tbl.size = 0
    tbl.style = 0
    tbl.b = 0
    tbl.g = 0
    tbl.r = 0
    tbl.noworld = false
    tbl.nomodel = false
    tbl.pos = nil
    tbl.dir = nil
end

local lightTableMeta = { __index = DLight }
local function create_light_metatable(index, isELight)
    local lightTable = { key = index }

    lightTable._Table = lightTable
    lightTable._IsELight = isELight or false

    -- Table fallbacks to DLight metatable
    setmetatable(lightTable, lightTableMeta)

    local lightMeta = {}

    lightMeta.__index = lightTable
    lightMeta.__metatable = DLight
    lightMeta.__newindex = DLight.__newindex
    lightMeta.__tostring = DLight.__tostring

    return lightMeta
end

-- DynamicLight indexes can only be an integer
-- We separate ELights from DLights within the cache by adding .1 to their index
local function get_cache_index(index, isELight)
    return isELight and (index + (index < 0 and -0.1 or 0.1)) or index
end

local C_DynamicLight = DynamicLight
function DynamicLight(index, isELight)
    local light = C_DynamicLight(index, isELight)
    if not light then return end

    index = math_floor(index)

    local cacheIndex = get_cache_index(index, isELight)
    local meta = lightCache[cacheIndex] and debug_getmetatable(lightCache[cacheIndex])

    meta = meta or create_light_metatable(index, isELight)

    -- We have to reset the table's values every time to
    -- preserve 1:1 behavior
    reset_member_values(meta.__index)
    debug_setmetatable(light, meta)

    lightCache[cacheIndex] = light

    return light
end

--[[---------------------------------
    Meta Methods
-----------------------------------]]

function DLight:__tostring()
    return 'dlight_t [' .. self.key .. ']'
end

local C__newindex = DLight.__newindex
local string_lower = string.lower

local validMembers = {
    brightness = true,
    decay = true,
    dietime = true,
    dir = true,
    innerangle = true,
    outerangle = true,
    key = true,
    minlight = true,
    noworld = true,
    nomodel = true,
    pos = true,
    size = true,
    style = true,
    b = true,
    g = true,
    r = true,
}

function DLight:__newindex(key, value)
    if validMembers[key] then -- Fast path
        self._Table[key] = value
        return C__newindex(self, key, value)
    end

    key = string_lower(key) -- Member names are case-insensitive
    
    if validMembers[key] then
        self._Table[key] = value
    end

    return C__newindex(self, key, value)
end

--[[----------------------------------
    Methods
-------------------------------------]]

AccessorFunc(DLight, 'brightness', 'Brightness', FORCE_NUMBER)
AccessorFunc(DLight, 'decay', 'Decay', FORCE_NUMBER)
AccessorFunc(DLight, 'dietime', 'DieTime', FORCE_NUMBER)
AccessorFunc(DLight, 'innerangle', 'InnerAngle', FORCE_NUMBER)
AccessorFunc(DLight, 'OuterAngle', 'OuterAngle', FORCE_NUMBER)
AccessorFunc(DLight, 'minlight', 'MinLight', FORCE_NUMBER)
AccessorFunc(DLight, 'size', 'Size', FORCE_NUMBER)
AccessorFunc(DLight, 'style', 'style', FORCE_NUMBER)

local Vector = Vector
local function accessor_vector(fieldName, methodName)
    DLight['Get' .. methodName] = function(self)
        local tbl = self._Table
        local vec = tbl[fieldName]

        -- We create the fallback vector here instead of when the DynamicLight is created
        -- for better performance
        if not vec then
            vec = Vector(0, 0, 0)
            tbl[fieldName] = vec
        end

        return vec
    end

    DLight['Set' .. methodName] = function(self, vec)
        self[fieldName] = vec
    end
end

accessor_vector('pos', 'Pos')
accessor_vector('dir', 'Direction')

function DLight:GetIndex()
    return self.key
end

function DLight:IsELight()
    return self._IsELight
end

local Entity = Entity
local Color = Color

function DLight:GetLightModels()
    return not self.nomodel
end

function DLight:GetLightWorld()
    return not self.noworld and not self._IsELight
end

--
-- Returns the entity of the same index as this DLight
--
function DLight:GetEntity()
    return Entity(self.key)
end

function DLight:GetColor()
    local tbl = self._Table
    return Color(tbl.r, tbl.g, tbl.b, 255)
end

function DLight:GetColorUnpacked()
    local tbl = self._Table
    return tbl.r, tbl.g, tbl.b
end

function DLight:SetColor(color)
    self.r = color.r
    self.g = color.g
    self.b = color.b
end

function DLight:SetColorUnpacked(r, g, b)
    self.r = r
    self.g = g
    self.b = b
end

function DLight:SetLightModels(lightModels)
    self.nomodel = not lightModels
end

function DLight:SetLightWorld(lightWorld)
    self.noworld = not lightWorld
end

--[[---------------------------------
    Global Getters
-----------------------------------]]

local next = next

function render.GetDynamicLights(elight)
    local list = {}
    local n = 0

    for _, light in next, lightCache do
        local addToList = elight == nil or
        (elight == true and light:IsELight()) or
        (elight == false and not light:IsELight())
       
        if addToList then
            n = n + 1
            list[n] = light
        end
    end

    return list
end

function render.GetDynamicLight(index, isELight)
    return lightCache[get_cache_index(index, isELight)]
end

function render.DynamicLightPairs()
    return next, lightCache
end
