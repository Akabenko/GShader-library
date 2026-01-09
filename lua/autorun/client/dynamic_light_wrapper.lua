--[[----------------------------------
    DynamicLight Wrapper by Zaurzo
    https://gist.github.com/Zaurzo/c5c2811f77fc6a52e6fa71d34b7229be
-------------------------------------]]

local dlight_tables, dlight_to_index, index_to_dlight do
    local function weak_table(mode)
        return setmetatable({}, { __mode = mode })
    end

    dlight_tables = weak_table('k')
    dlight_to_index = weak_table('k')
    index_to_dlight = weak_table('v')
end

local _DynamicLight = DynamicLight
local Vector = Vector

function DynamicLight(index, elight, ...)
    local dlight = _DynamicLight(index, elight, ...)

    if dlight then
        local current = index_to_dlight[index]

        if current then
            local current_table = dlight_tables[current]
            current_table._elight = elight or false

            dlight_tables[dlight] = current_table
            dlight_tables[current] = nil
        else
            local tbl = {
                _elight = elight or false
            }

            -- Setup default fields
            tbl.dir = Vector(0, 0, 0)
            tbl.pos = Vector(0, 0, 0)
            tbl.noworld = false
            tbl.nomodel = false
            tbl.r = 0
            tbl.g = 0
            tbl.b = 0
            tbl.brightness = 0
            tbl.decay = 0
            tbl.size = 0
            tbl.dietime = 0
            tbl.innerangle = 0
            tbl.outerangle = 0
            tbl.minlight = 0
            tbl.style = 0
            tbl.key = 0 -- whatever this is

            dlight_tables[dlight] = tbl
        end

        dlight_to_index[dlight] = index
        index_to_dlight[index] = dlight
    end

    return dlight
end

local DLIGHT = FindMetaTable('dlight_t')

local function DLIGHT_GetTable(dlight)
    local index = dlight_to_index[dlight]
    if not index then return end

    dlight = index_to_dlight[index]
    if not dlight then return end

    return dlight_tables[dlight]
end

--[[----------------------------------
    dlight_t Extensions
-------------------------------------]]

AccessorFunc(DLIGHT, 'brightness', 'Brightness', FORCE_NUMBER)
AccessorFunc(DLIGHT, 'decay', 'Decay', FORCE_NUMBER)
AccessorFunc(DLIGHT, 'dietime', 'DieTime', FORCE_NUMBER)
AccessorFunc(DLIGHT, 'dir', 'Direction', FORCE_NUMBER)
AccessorFunc(DLIGHT, 'innerangle', 'InnerAngle', FORCE_NUMBER)
AccessorFunc(DLIGHT, 'OuterAngle', 'OuterAngle', FORCE_NUMBER)
AccessorFunc(DLIGHT, 'minlight', 'MinLight', FORCE_NUMBER)
AccessorFunc(DLIGHT, 'size', 'Size', FORCE_NUMBER)
AccessorFunc(DLIGHT, 'style', 'style', FORCE_NUMBER)
AccessorFunc(DLIGHT, 'pos', 'Pos', FORCE_VECTOR)

function DLIGHT:GetTable()
    return DLIGHT_GetTable(self)
end

function DLIGHT:GetIndex()
    return dlight_to_index[self]
end

function DLIGHT:CanLightModels()
    return not DLIGHT_GetTable(self).nomodel
end

function DLIGHT:CanLightWorld()
    return not DLIGHT_GetTable(self).noworld
end

function DLIGHT:IsELight()
    return DLIGHT_GetTable(self)._elight and true
end

-- Returns the entity with same index as the dlight
local ents_GetByIndex = ents.GetByIndex
function DLIGHT:GetEntity()
    local index = dlight_to_index[self]
    if not index then return NULL end

    return ents_GetByIndex(index)
end

local Color = Color
function DLIGHT:GetColor()
    local tbl = DLIGHT_GetTable(self)
    if not tbl then return end

    return Color(tbl.r, tbl.g, tbl.b, 255)
end

function DLIGHT:GetColorUnpacked()
    local tbl = DLIGHT_GetTable(self)
    if not tbl then return end

    return tbl.r, tbl.g, tbl.b
end

function DLIGHT:SetColor(color)
    self.r = color.r
    self.g = color.g
    self.b = color.b
end

function DLIGHT:SetColorUnpacked(r, g, b)
    self.r = r
    self.g = g
    self.b = b
end

function DLIGHT:SetLightModels(value)
    self.nomodel = not value
end

function DLIGHT:SetLightWorld(value)
    self.noworld = not value
end

--[[----------------------------------
    dlight_t Overrides
-------------------------------------]]

local original_newindex = DLIGHT.__newindex
local string_lower = string.lower
local base_fields = {
    dir = true,
    pos = true,
    noworld = true,
    nomodel = true,
    r = true,
    g = true,
    b = true,
    brightness = true,
    decay = true,
    size = true,
    dietime = true,
    innerangle = true,
    outerangle = true,
    minlight = true,
    style = true,
    key = true
}

DLIGHT.__newindex = function(self, k, v)
    local tbl = DLIGHT_GetTable(self)

    if tbl ~= nil then
        local k_lower = string_lower(k)

        if base_fields[k_lower] then
            tbl[k_lower] = v
        else
            tbl[k] = v
        end
    end

    return original_newindex(self, k, v)
end

local original_index = DLIGHT.__index

local is_index_table = istable(original_index)
local is_index_function = isfunction(original_index)

DLIGHT.__index = function(self, k)
    local tbl = DLIGHT_GetTable(self)

    if tbl ~= nil then
        local value = tbl[k]

        if value ~= nil then
            return value
        end
    end

    if is_index_table then
        return original_index[k]
    elseif is_index_function then -- just in case any addon changed it to a function too
        return original_index(self, k)
    end
end

--[[----------------------------------
    Global Functions
-------------------------------------]]

local getmetatable = getmetatable
local pairs = pairs

function isdlight(value)
    return getmetatable(value) == DLIGHT
end

function render.GetDynamicLights()
    local list = {}
    local n = 0

    for _, dlight in pairs(index_to_dlight) do
        n = n + 1
        list[n] = dlight
    end

    return list
end

function render.GetDynamicLightByIndex(index)
    return index_to_dlight[index]
end