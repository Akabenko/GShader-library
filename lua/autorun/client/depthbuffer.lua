local libname = "shaderlib"

local function UpgradeDepthBuffer()
    // This is an improvement of the depth buffer image format. The standard image format is: IMAGE_FORMAT_RGBA8888
    // Thanks to notunknowndude for the idea of a way to upgrade the depth buffer.

    GetRenderTargetEx( render.GetResolvedFullFrameDepth():GetName(), ScrW(), ScrH(),
         RT_SIZE_FULL_FRAME_BUFFER,
        --MATERIAL_RT_DEPTH_SEPARATE,
        MATERIAL_RT_DEPTH_NONE,
        bit.bor(4, 8, 256, 512, 32768, 65536),
        0,
        IMAGE_FORMAT_R32F
    )

    /*---------------------------------------------------------------------------
    Selecting the image format of the depth buffer:

    IMAGE_FORMAT_R32F not works on Linux (dx 92). (confirm)
    IMAGE_FORMAT_RGBA32323232F not works without d3d9ex (mat_disable_d3d9ex 0). (confirm)

    Best format for depth buffer is IMAGE_FORMAT_R32F. 

    But if it is not available to us, then we preserve the quality of the depth buffer,
    leaving 32 Bit, but use the IMAGE_FORMAT_RGBA32323232F format, which costs more video memory.
    We sacrifice it for the sake of the quality of the depth buffer.

    If d3d9ex is not available, then we use at least 16 bit, but the IMAGE_FORMAT_R16F bit format does
    not work (ShaderAPIDX8::CreateD3DTexture: Invalid color format!). So we use IMAGE_FORMAT_RGBA16161616F.
    But it's still twice as good as the standard image format.
    ---------------------------------------------------------------------------*/

    /*---------------------------------------------------------------------------
    About the depth buffer render.GetResolvedFullFrameDepth() (_rt_resolvedfullframedepth):

    Before increasing the bit depth of the depth buffer, it worked at a distance of 4000.
    In the shader, the depth at >=4000 units was equal to 1 in the shader.

    After upgrading the depth buffer from IMAGE_FORMAT_RGBA8888 to IMAGE_FORMAT with floating point format,
    it started writing numbers above >1. It began to record depth at a distance of >4000 units, namely the entire scene. 
    Now it turns out that the distance of 0 — 4000 units is from 0 to 1, 4000 — 8000 units from 1 to 2 and so on.

    In this case the sky is equal to exactly depth == 1:
    if (tex2D(DepthBuffer,uv).r) == 1 discard;
    Although on other engines, the check is done by  depth >= 1.
    ---------------------------------------------------------------------------*/

    hook.Add("NeedsDepthPass", libname, function() return true end)

    /*---------------------------------------------------------------------------
    When rendering a shadow map, artifacts may appear with the scene when NeedsDepthPass return true.
    That's why we output return false when rendering CSM or any other scene renders.
    
    FIX:
    bDrawCSM = true
    render.RenderView(viewSetup)
    bDrawCSM = false
    ---------------------------------------------------------------------------*/
end

hook.Add("InitPostShaderlib", libname, UpgradeDepthBuffer)



local function SkyBox3DUpradeDepth() -- 3D skybox support
    local render = render
    local file = file
    local util = util
    local Matrix = Matrix
    local string = string

    local linux = render.GetDXLevel() == 92 or system.IsLinux() or system.IsOSX() or system.IsProton()

    shaderlib.rt_depth_skybox = GetRenderTargetEx( "_rt_ResolvedFullFrameDepthSky", ScrW(), ScrH(),
        RT_SIZE_FULL_FRAME_BUFFER,
        MATERIAL_RT_DEPTH_NONE,
        bit.bor(4, 8, 256, 512, 32768, 65536),
        0,
        NikNaks and IMAGE_FORMAT_R32F or (linux and IMAGE_FORMAT_RGB888 or IMAGE_FORMAT_I8)
    )
    
    hook.Add("PreRender", libname, function()
        render.PushRenderTarget(shaderlib.rt_depth_skybox)
            render.Clear( 255, 0, 0, 0 )
        render.PopRenderTarget()
        hook.Remove("PreRender", libname)
    end)

    local depthwrite_mat = CreateMaterial("depthwritesky", "DepthWrite", {
        ["$COLOR_DEPTH"] = "1"
    })

    --[[local zNear = 1
    local zFar = 100000200
    hook.Add("PreDrawReconstruction", "SkyDrawBoxDepth", function()
        render.PushRenderTarget(shaderlib.rt_depth_skybox)
            render.Clear( 255, 0, 0, 0 )
            render.ClearDepth()
            cam.IgnoreZ(true)
            cam.Start3D(vector_origin, EyeAngles(), nil, nil, nil, nil, nil, zNear, zFar )
                render.SetMaterial(depthwrite_mat)
                local min,max = game.GetWorld():GetModelBounds()
                render.DrawBox( vector_origin, angle_zero, max, min, color_white )
            cam.End3D()
            cam.IgnoreZ(false)
        render.PopRenderTarget()
    end)]]

    if !NikNaks then return end

    local has_skybox        = NikNaks.CurrentMap:HasSkyBox()
    if !has_skybox then return end

    local function tableAdd(dest, source)
        for i = 1, #source do
            dest[#dest + 1] = source[i]
        end
        return dest
    end

    local skybox_scale      = NikNaks.CurrentMap:GetSkyBoxScale()
    local sky_camera_pos    = NikNaks.CurrentMap:GetSkyBoxPos()
    local skybox_leafs      = NikNaks.CurrentMap:GetSkyboxLeafs()
    local skybox_faces = {}
    local skybox_static_props = {}

    local blacklist_mat = {
        ["tools/toolsskybox"] = true,
        ["tools/toolsskybox2d"] = true,
    }

    local skybox_mins, skybox_maxs = NikNaks.CurrentMap:GetSkyboxSize()

    local function Collect3DSkyboxInfo()
        local indexes = {}

        for i = 1,#skybox_leafs do
            local leaf = skybox_leafs[i]

            local boxMins = leaf.mins
            local boxMaxs = leaf.maxs

            local faces = {}
            local leaf_faces = leaf:GetFaces(true)
            --for k, face in pairs(leaf_faces) do
            for k = 1,#leaf_faces do
                local face = leaf_faces[k]
                if !face then continue end
                --print(k, face, #leaf_faces)
                if face:HasTexInfoFlag(0x08) then continue end
                local tex = string.lower( face:GetTexData().nameStringTableID )
                if blacklist_mat[tex] then continue end
                if face:IsSkyBox() then continue end
                if face:IsSkyBox3D() then continue end
                if face:GetEntity().classname != "worldspawn" then continue end

                local patch = "materials/"..tex..".vmt"
                local mat_file = file.Read( patch, "GAME" )
                
                if mat_file then
                    local key_values = util.KeyValuesToTable( mat_file )
                    if (key_values["$translucent"] or 0) >= 1 then continue end
                end

                local index = face:GetIndex()
                if indexes[index] then continue end

                local skip_face = false
                
                local verts = face:GenerateVertexTriangleData()
                for i3 = 1,#verts do
                    local vert_pos = verts[i3].pos
                    if !verts[i3].pos:WithinAABox( skybox_mins, skybox_maxs ) then
                        skip_face = true
                        break
                    end
                end

                if skip_face then continue end

                indexes[index] = true
                faces[#faces+1] = face
            end 

            tableAdd( skybox_faces, faces )
        end

        skybox_static_props = NikNaks.CurrentMap:FindStaticInBox( skybox_mins, skybox_maxs )
    end

    local vertex_limit = math.floor(65535/3)

    local function CheckAlphatest(tex)
        local patch = "materials/"..tex..".vmt"
        local mat_file = file.Read( patch, "GAME" )

        local alphatest = false
        if mat_file then
            local key_values = util.KeyValuesToTable( mat_file )

            alphatest = (key_values["$alphatest"] or 0) >= 1 or
                        (key_values["$translucent"] or 0) >= 1 or
                        (key_values["$additive"] or 0) >= 1 or
                        (key_values["$vertexalpha"] or 0) >= 1
        end 

        return alphatest
    end

    local function SortVertexByMat(static_t)
        local mats_vertexes_alpha = {}
        local opaque_meshes = {}
        local temp_vertexes = {}

        for i = 1,#static_t do
            local static_prop = static_t[i]
            local model = static_prop.PropType
            local _skin = static_prop.Skin or 0
     
            local visualMeshes = util.GetModelMeshes( model, 0, 0, _skin )
            if ( !visualMeshes ) then continue end

            local pos   = static_prop.Origin
            local ang   = static_prop.Angles

            local mModel = Matrix()
            mModel:SetTranslation(pos)
            if ang != angle_zero then
                mModel:SetAngles(ang)
            end

            local last = i == #static_t

            for i2 = 1,#visualMeshes do
                --visualMeshes[i2].verticies = nil

                local tex = visualMeshes[i2].material
                --visualMeshes[i2].material = nil

                local alphatest = CheckAlphatest(tex)

                local triangles = visualMeshes[i2].triangles
                --visualMeshes[i2] = nil
                local unique_vertexes = {}

                if alphatest then
                    for i3 = 1,#triangles do
                        local v = triangles[i3]
                        table.insert(unique_vertexes, {
                            pos = mModel*v.pos,
                            u = v.u,
                            v = v.v
                        })
                    end

                    if !mats_vertexes_alpha[tex] then mats_vertexes_alpha[tex] = {} end
                    local index = #mats_vertexes_alpha[tex]
                    if !mats_vertexes_alpha[tex][index] then mats_vertexes_alpha[tex][index] = {} end
                    if #triangles + #mats_vertexes_alpha[tex][index] > vertex_limit then index = index + 1 end
                    if !mats_vertexes_alpha[tex][index] then mats_vertexes_alpha[tex][index] = {} end
                    tableAdd(mats_vertexes_alpha[tex][index], unique_vertexes)
                else
                    for i3 = 1,#triangles do
                        local v = triangles[i3]
                        table.insert(unique_vertexes, {
                            pos = mModel*v.pos
                        })
                    end
                    
                    if #triangles + #temp_vertexes > vertex_limit then
                        local _mesh = Mesh()
                        _mesh:BuildFromTriangles(temp_vertexes)
                        opaque_meshes[#opaque_meshes + 1] = _mesh
                        temp_vertexes = {}
                    end

                    tableAdd(temp_vertexes, unique_vertexes)
                end
            end

            if last then
                local _mesh = Mesh()
                _mesh:BuildFromTriangles(temp_vertexes)
                opaque_meshes[#opaque_meshes + 1] = _mesh
            end
        end

        return opaque_meshes, mats_vertexes_alpha
    end

    local function SortVertexByMatBrush(faces_t)
        local opaque_meshes = {}
        local temp_vertexes = {}
        local mats_vertexes_alpha = {}

        for i = 1, #faces_t do
            local face = faces_t[i]
            local triangles = face:GenerateVertexTriangleData()

            local tex = face:GetTexture()
            local alphatest = CheckAlphatest(tex)
            local last = i == #faces_t

            if alphatest then
                if !mats_vertexes_alpha[tex] then mats_vertexes_alpha[tex] = {} end

                local index = #mats_vertexes_alpha[tex]

                if !mats_vertexes_alpha[tex][index] then mats_vertexes_alpha[tex][index] = {} end

                if #triangles + #mats_vertexes_alpha[tex][index] > vertex_limit then
                    index = index + 1
                end

                if !mats_vertexes_alpha[tex][index] then mats_vertexes_alpha[tex][index] = {} end

                tableAdd(mats_vertexes_alpha[tex][index], triangles)
            else
                if #triangles + #temp_vertexes > vertex_limit then
                    local _mesh = Mesh()
                    _mesh:BuildFromTriangles(temp_vertexes)
                    opaque_meshes[#opaque_meshes + 1] = _mesh
                    temp_vertexes = {}
                end

                tableAdd(temp_vertexes, triangles)
            end

            if last then
               -- if alphatest then

                --else
                    local _mesh = Mesh()
                    _mesh:BuildFromTriangles(temp_vertexes)
                    opaque_meshes[#opaque_meshes + 1] = _mesh
                --end
            end
        end

        return opaque_meshes, mats_vertexes_alpha
    end

    local cachedMaterials = {}

    local function getMaterial(materialPath)
        cachedMaterials[materialPath] = cachedMaterials[materialPath] or Material(materialPath)
        return cachedMaterials[materialPath]
    end

    local function createMaterial(name,shader,keyvalues)
        cachedMaterials[name] = cachedMaterials[name] or CreateMaterial(name,shader,keyvalues)
        return cachedMaterials[name]
    end

    local function CreateDepthMaterial(tex, depthwrite_shader)
        local patch = "materials/"..tex..".vmt"
        local mat_file = file.Read( patch, "GAME" )
        if !mat_file then return nil end 
        local key_values = util.KeyValuesToTable( mat_file )

        local orig_mat = getMaterial( tex )

        local depth_write = createMaterial(orig_mat:GetName().."_depth_dw", "DepthWrite", {
            ["$COLOR_DEPTH"] = "1";
            ["$no_fullbright"] = "1";
            ["$ALPHATEST"] = "1";
            ["$translate"] = key_values["$translate"] or "[0 0]";
            ["$treesway"] = key_values["$treesway"] or "0";
            ["$alphatestreference"] = key_values["$alphatestreference"] or (key_values["$vertexalpha"] and "0.01" or "0.5");
            ["$vertexalpha"] = key_values["$vertexalpha"] or "0";
            ["$treeswayheight"] = key_values["$treeswayheight"] or "1000";
            ["$treeswaystartheight"] = key_values["$treeswaystartheight"] or "0.2";
            ["$treeswayradius"] = key_values["$treeswayradius"] or "300";
            ["$treeswaystartradius"] = key_values["$treeswaystartradius"] or "0.1";
            ["$treeswayspeed"] = key_values["$treeswayspeed"] or "1";
            ["$treeswaystrength"] = key_values["$treeswaystrength"] or "10";
            ["$treeswayscrumblespeed"] = key_values["$treeswayscrumblespeed"] or "0.1";
            ["$treeswayscrumblestrength"] = key_values["$treeswayscrumblestrength"] or "0.1";
            ["$treeswayscrumblefrequency"] = key_values["$treeswayscrumblefrequency "] or "0.1";
            ["$treeswayfalloffexp"] = key_values["$treeswayfalloffexp"] or "1.5";
            ["$treeswayscrumblefalloffexp"] = key_values["$treeswayscrumblefalloffexp"] or "1";
            ["$treeswayspeedhighwindmultipler"] = key_values["$treeswayspeedhighwindmultipler"] or "2";
            ["$treeswayspeedlerpstart"] = key_values["$treeswayspeedlerpstart"] or "3";
            ["$treeswayspeedlerpend"] = key_values["$treeswayspeedlerpend"] or "6";
            ["$treeswaystatic"] = key_values["$treeswaystatic"] or "0";
            ["$treeswaystaticvalues"] = key_values["$treeswaystaticvalues"] or "[0.5 0.5]";
            ["Proxies"] = key_values["proxies"] or {};
            ["$nocull"] = key_values["$nocull"] or "0";
        })

        depth_write:SetTexture("$basetexture", orig_mat:GetTexture("$basetexture") )

        return depth_write
    end

    local function CreateCombinedMesh(mats_vertexes)
        local combined_depth_mats = {}
        local meshes_tbl = {}

        for tex,v in pairs(mats_vertexes) do
            for index = 0,#v do
                local vertexes = v[index]

            --for index, vertexes in pairs(v) do
                --print(index,vertexes)
                local _mesh = Mesh()
                _mesh:BuildFromTriangles(vertexes)

                local i = #meshes_tbl + 1
                combined_depth_mats[i] = CreateDepthMaterial(tex)
                meshes_tbl[i] = _mesh
            end
        end

        mats_vertexes = nil

        return meshes_tbl, combined_depth_mats
    end

    Collect3DSkyboxInfo()
    local opaque_meshes, mats_vertexes_alpha = SortVertexByMatBrush(skybox_faces)
    local opaque_meshes_alpha, alpha_depth_mats = CreateCombinedMesh(mats_vertexes_alpha)
    local static_prop_combined, vertexes_tbl_alpha = SortVertexByMat(skybox_static_props)
    local static_prop_combined_alpha, combined_depth_mats = CreateCombinedMesh(vertexes_tbl_alpha)

    hook.Add("PreDrawReconstruction", libname, function()
        if !GetConVar("r_shaderlib_3dskybox"):GetBool() then return end
        if !GetConVar("r_3dsky"):GetBool() then return end
        if hook.Run("NeedsDepthPass") != true then return end
        
        local viewSetup = render.GetViewSetup()

        render.PushRenderTarget(shaderlib.rt_depth_skybox)
            render.Clear( 255, 0, 0, 0 )
            render.ClearDepth()
            render.CullMode(MATERIAL_CULLMODE_NONE or MATERIAL_CULLMODE_CW)

            viewSetup.origin = sky_camera_pos + (viewSetup.origin / skybox_scale);
            viewSetup.zfar = viewSetup.zfar*skybox_scale;

            -- первым можно рендерить коробку
            --[[cam.Start3D()
                render.SetMaterial(vector_origin, EyeAngles())
                local min,max = game.GetWorld():GetModelBounds()
                render.DrawBox( vector_origin, angle_zero, max, min, color_white )
            cam.End3D()]]

            cam.Start(viewSetup)
                for i = 1,#opaque_meshes do
                    local _mesh = opaque_meshes[i]
                    render.SetMaterial(depthwrite_mat)
                    _mesh:Draw(STUDIO_SSAODEPTHTEXTURE)
                end

                for i = 1,#static_prop_combined do
                    local _mesh = static_prop_combined[i]
                    render.SetMaterial(depthwrite_mat)
                    _mesh:Draw(STUDIO_SSAODEPTHTEXTURE)
                end

                for i = 1,#static_prop_combined_alpha do
                    local _mesh = static_prop_combined_alpha[i]
                    render.SetMaterial(combined_depth_mats[i] or depthwrite_mat)
                    _mesh:Draw(STUDIO_SSAODEPTHTEXTURE)
                end

                for i = 1,#opaque_meshes_alpha do
                    local _mesh = opaque_meshes_alpha[i]
                    render.SetMaterial(alpha_depth_mats[i] or depthwrite_mat)
                    _mesh:Draw(STUDIO_SSAODEPTHTEXTURE)
                end
            cam.End()

            render.CullMode(MATERIAL_CULLMODE_CCW)
        render.PopRenderTarget()
    end)

    cvars.AddChangeCallback("r_3dsky", function(convar_name, value_old, value_new)
        if tonumber(value_new) <= 0 then
            render.PushRenderTarget(shaderlib.rt_depth_skybox)
                render.Clear( 255, 0, 0, 0 )
            render.PopRenderTarget()
        end
    end)

    cvars.AddChangeCallback("r_shaderlib_3dskybox", function(convar_name, _, value_new)
        local state = value_new == "1"
        if !state then
            render.PushRenderTarget(shaderlib.rt_depth_skybox)
                render.Clear( 255, 0, 0, 0 )
            render.PopRenderTarget()
        end
    end)
end
--SkyBox3DUpradeDepth()
hook.Add("InitPostShaderlib", "SkyBoxDepth3D", function()
    timer.Simple(0, function()
        SkyBox3DUpradeDepth()
    end)
end)

hook.Add("PostDrawHUD", "test", function()
    render.DrawTextureToScreen("_rt_normalstangents")
end)


