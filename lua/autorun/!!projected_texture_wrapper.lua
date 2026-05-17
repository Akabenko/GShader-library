
-- https://github.com/Facepunch/garrysmod/pull/2462
function string.ToColor( str )

    local r, g, b, a = string.match( str, "(%d+) (%d+) (%d+) (%d+)" )
    if ( !a ) then r, g, b = string.match( str, "(%d+) (%d+) (%d+)" ) end
    return Color( tonumber( r ) or 255, tonumber( g ) or 255, tonumber( b ) or 255, tonumber( a ) or 255 )

end

if SERVER then return end

ENV_PROJTEXS = ENV_PROJTEXS or {}
ENV_PROJTEXS_I = ENV_PROJTEXS_I or {}

C_ProjectedTexture = C_ProjectedTexture or ProjectedTexture

ptCache = ptCache or setmetatable({}, {__mode = "k"})
nextID = nextID or 0

function GetProjectedTextureByID(id)
    for light, lid in pairs(ptCache) do
        if lid == id then return light end
    end
    return nil
end

function ProjectedTexture()
    local light = C_ProjectedTexture()

    nextID = nextID + 1
    local index = nextID
    

    local i = #ENV_PROJTEXS + 1
    ENV_PROJTEXS[i] = light
	ENV_PROJTEXS_I[index] = i

    ptCache[light] = index

    --print("создано", i, index)
    
    local meta = debug.getmetatable(light) or {}
    local oldIndex = meta.__index
    
    meta.__index = function(t, k)
        if k == "GetID" or k == "id" then
            return ptCache[t]
        end
        
        if type(oldIndex) == "function" then
            return oldIndex(t, k)
        elseif type(oldIndex) == "table" then
            return oldIndex[k]
        end
        
        return nil
    end
    
    debug.setmetatable(light, meta)
    
    return light
end

local metaTex = FindMetaTable("ProjectedTexture")

old_remove = old_remove or metaTex.Remove

function metaTex:Remove()
	local index = ptCache[self]

	local i = ENV_PROJTEXS_I[index]
    if !i then old_remove(self) return end -- Double removing fix
	table.remove(ENV_PROJTEXS, i)
	ENV_PROJTEXS_I[index] = nil

    --print("убрано", i, index)

	old_remove(self)
end

