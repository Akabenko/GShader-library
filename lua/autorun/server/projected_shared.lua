local shaderName = "ProjectedShared"

-- Get a new projcted textures params
hook.Add( "AcceptInput", shaderName, function( ent, name, activator, caller, data )
    if ( ent:GetClass() != "env_projectedtexture" ) then return end
    
    if name == "SpotlightTexture"   then    ent:SetNWString("SpotlightTexture", data)   end
    if name == "TurnOn"             then    ent:SetNWBool("enabled", true)              end     -- Not shadows, but state
    if name == "TurnOff"            then    ent:SetNWBool("enabled", false)             end
    if name == "FOV"                then    ent:SetNWFloat("FOV", data)                 end
end )

local meta = FindMetaTable("Entity")
meta.old_key_value = meta.old_key_value or meta.SetKeyValue

-- Detour
function meta:SetKeyValue(k,v)
    self.old_key_value(self,k,v)
    
    if ( self:GetClass() != "env_projectedtexture" ) then return end

    if k == "lightcolor" then
        local lightcolor = string.ToColor(v)
        self:SetNWVector("COLOR", Vector(lightcolor.r,lightcolor.g,lightcolor.b) )
    end

    if k == "nearz"             then self:SetNWFloat("NEARZ", tonumber(v))      end
    if k == "farz"              then self:SetNWFloat("FARZ", tonumber(v))       end
    if k == "lightfov"          then self:SetNWFloat("FOV", tonumber(v))        end
    if k == "enableshadows"     then self:SetNWBool("enableshadows",  tonumber(v) > 0  ) end
end

-- Map start
hook.Add( "EntityKeyValue", shaderName, function( ent, k, v )
    if ent:GetClass() != "env_projectedtexture" then return end

    if k == "enableshadows"     then ent:SetNWBool("enableshadows",  tonumber(v) > 0  )  end
    if k == "texturename"       then ent:SetNWString("SpotlightTexture", v )      end
    if k == "nearz"             then ent:SetNWFloat("NEARZ", tonumber(v))       end
    if k == "farz"              then ent:SetNWFloat("FARZ", tonumber(v))        end
    if k == "lightfov"          then ent:SetNWFloat("FOV", tonumber(v))         end

    if k == "lightcolor" then
        local lightcolor = string.ToColor(v)
        ent:SetNWVector("COLOR", Vector(lightcolor.r,lightcolor.g,lightcolor.b) )
    end
end )

