
local libName = "shaderlib"

local r_shaderlib = CreateClientConVar( "r_shaderlib", "1", true, false, "Reconstruct WorldPos, Normals, Tangents.", 0, 1 )
local r_shaderlib_wn_format = CreateClientConVar( "r_shaderlib_wn_format", "2", true, false, "WorldNormals IMAGE FORMAT.", 0, 2 )
local r_shaderlib_depthbuffer = CreateClientConVar( "r_shaderlib_depthbuffer", "1", true, false, "Enable/disable depth buffer.", 0, 1 )
local r_shaderlib_wn_reconsruction = CreateClientConVar( "r_shaderlib_wn_reconsruction", "4", true, false, "Type of WorldNormals reconstruction.", 0, 4 )
local r_shaderlib_wn_smooth = CreateClientConVar( "r_shaderlib_wn_smooth", "1", true, false, "Smooth normals.", 0, 1 )
local r_shaderlib_debug = CreateClientConVar( "r_shaderlib_debug", "0", true, false, "Show rendertargets on HUD.", 0, 1 )
local r_shaderlib_debug_decode = CreateClientConVar( "r_shaderlib_debug_decode", "0", false, false, "Show decoded rendertargets on HUD.", 0, 1 ) 
local r_shaderlib_dbg_scale = CreateClientConVar( "r_shaderlib_dbg_scale", "0.5", true, false, "Scale factor debug rt.", 0.4, 1 )
local r_shaderlib_3tap_offset = CreateClientConVar( "r_shaderlib_3tap_offset", "1", true, false, "Scale factor debug rt.", 0.6, 1.49 )
local r_shaderlib_3dskybox = CreateClientConVar( "r_shaderlib_3dskybox", "1", true, false, "3D Skybox support", 0, 1 )

list.Set( "PostProcess", "#r_shaderlib", {
	["icon"] = "gui/postprocess/shaderlib.jpg",
	["convar"] = r_shaderlib:GetName(),
	["category"] = "#shaders_pp",
	["cpanel"] = function( panel )

		panel:Help( "#r_shaderlib.info" )

		panel:AddControl( "ComboBox", {
			["MenuButton"] = 1,
			["Folder"] = libName,
			["Options"] = {
				[ "#preset.default" ] = {
					[ r_shaderlib:GetName() ] 					= r_shaderlib:GetDefault(),
					[ r_shaderlib_wn_format:GetName() ] 		= r_shaderlib_wn_format:GetDefault(),
					[ r_shaderlib_depthbuffer:GetName() ] 		= r_shaderlib_depthbuffer:GetDefault(),
					[ r_shaderlib_wn_reconsruction:GetName() ] 	= r_shaderlib_wn_reconsruction:GetDefault(),
					[ r_shaderlib_dbg_scale:GetName() ] 		= r_shaderlib_dbg_scale:GetDefault(),
					[ r_shaderlib_wn_smooth:GetName() ] 		= r_shaderlib_wn_smooth:GetDefault(),
					[ r_shaderlib_debug_decode:GetName() ]		= r_shaderlib_debug_decode:GetDefault(),
					[ r_shaderlib_debug:GetName() ] 			= r_shaderlib_debug:GetDefault(),
					[ r_shaderlib_3tap_offset:GetName() ] 		= r_shaderlib_3tap_offset:GetDefault(),
					[ r_shaderlib_3dskybox:GetName() ] 			= r_shaderlib_3dskybox:GetDefault(),
				},

				[ "#r_shaderlib.medium" ] = {
					[ r_shaderlib:GetName() ] 					= r_shaderlib:GetDefault(),
					[ r_shaderlib_wn_format:GetName() ] 		= "0",
					[ r_shaderlib_depthbuffer:GetName() ] 		= r_shaderlib_depthbuffer:GetDefault(),
					[ r_shaderlib_wn_reconsruction:GetName() ] 	= "3",
					[ r_shaderlib_dbg_scale:GetName() ] 		= r_shaderlib_dbg_scale:GetDefault(),
					[ r_shaderlib_wn_smooth:GetName() ]			= r_shaderlib_wn_smooth:GetDefault(),
					[ r_shaderlib_debug_decode:GetName() ] 		= r_shaderlib_debug_decode:GetDefault(),
					[ r_shaderlib_debug:GetName() ] 			= r_shaderlib_debug:GetDefault(),
					[ r_shaderlib_3tap_offset:GetName() ] 		= r_shaderlib_3tap_offset:GetDefault(),
					[ r_shaderlib_3dskybox:GetName() ] 		= r_shaderlib_3dskybox:GetDefault(),
				},
			},
			["CVars"] = {
				r_shaderlib:GetName(),
				r_shaderlib_wn_format:GetName(),
				r_shaderlib_depthbuffer:GetName(),
				r_shaderlib_wn_reconsruction:GetName(),
				r_shaderlib_dbg_scale:GetName(),
				r_shaderlib_wn_smooth:GetName(),
				r_shaderlib_debug_decode:GetName(),
				r_shaderlib_debug:GetName(),
				r_shaderlib_3tap_offset:GetName(),
				r_shaderlib_3dskybox:GetName(),
			}
		} )

		panel:AddControl( "CheckBox", { ["Label"] = "#r_shaderlib.enable_reconsruction", ["Command"] = r_shaderlib:GetName() } )
		panel:AddControl( "CheckBox", { ["Label"] = "#r_shaderlib.depthbuffer", ["Command"] = r_shaderlib_depthbuffer:GetName() } )
		panel:AddControl( "CheckBox", { ["Label"] = "#r_shaderlib.3dskybox", ["Command"] = r_shaderlib_3dskybox:GetName() } )

		panel:Help( "#r_shaderlib.reconsruction" )

		panel:AddControl( "combobox", {
			["Label"] = "#r_shaderlib.wn_format",
			["Command"] = r_shaderlib_wn_format:GetName(),
			["Options"] = {
				[ "#r_shaderlib.16161616f" ] = {
					[ r_shaderlib_wn_format:GetName() ] = "0",
				},
				[ "#r_shaderlib.32323232f" ] = {
					[ r_shaderlib_wn_format:GetName() ] = "1",
				},
				[ "#r_shaderlib.888" ] = {
					[ r_shaderlib_wn_format:GetName() ] = "2",
				},
			},
			["CVars"] = {
				r_shaderlib_wn_format:GetName(),
			},
			["Help"] = false,
		} )

		panel:Help( "#r_shaderlib.formats" )

		panel:AddControl( "combobox", {
			["Label"] = "#r_shaderlib.wn_reconsruction_type",
			["Command"] = r_shaderlib_wn_reconsruction:GetName(),
			["Options"] = {
				[ "#r_shaderlib.1default" ] = {
					[ r_shaderlib_wn_reconsruction:GetName() ] = "0",
				},
				[ "#r_shaderlib.3tap" ] = {
					[ r_shaderlib_wn_reconsruction:GetName() ] = "1",
				},
				[ "#r_shaderlib.4tap" ] = {
					[ r_shaderlib_wn_reconsruction:GetName() ] = "2",
				},
				[ "#r_shaderlib.3recommend" ] = {
					[ r_shaderlib_wn_reconsruction:GetName() ] = "3",
				},
				[ "#r_shaderlib.4accurate" ] = {
					[ r_shaderlib_wn_reconsruction:GetName() ] = "4",
				},
			},
			["CVars"] = {
				r_shaderlib_wn_reconsruction:GetName(),
			},
			["Help"] = false,
		} )

		panel:AddControl( "Slider", {
			["Label"] = "#r_shaderlib.3tap_offset",
			["Command"] = r_shaderlib_3tap_offset:GetName(),
			["Min"] = tostring( r_shaderlib_3tap_offset:GetMin() ),
			["Max"] = tostring( r_shaderlib_3tap_offset:GetMax() ),
			["Type"] = "Float",
			["Help"] = false
		} )

		panel:AddControl( "CheckBox", { ["Label"] = "#r_shaderlib.wn_smooth", ["Command"] = r_shaderlib_wn_smooth:GetName() } )
		panel:Help( "#r_shaderlib.encode" )
		panel:Help( "#r_shaderlib.debug" )
		panel:AddControl( "CheckBox", { ["Label"] = "#r_shaderlib.debug_enable", ["Command"] = r_shaderlib_debug:GetName() } )
		panel:Help( "#r_shaderlib.decode_info" )
		panel:AddControl( "CheckBox", { ["Label"] = "#r_shaderlib.debug_decode", ["Command"] = r_shaderlib_debug_decode:GetName() } )

		panel:AddControl( "Slider", {
			["Label"] = "#r_shaderlib.dbg_scale",
			["Command"] = r_shaderlib_dbg_scale:GetName(),
			["Min"] = tostring( r_shaderlib_dbg_scale:GetMin() ),
			["Max"] = tostring( r_shaderlib_dbg_scale:GetMax() ),
			["Type"] = "Float",
			["Help"] = false
		} )

	end
} )


STORE_DEPTH_HOOKS = STORE_DEPTH_HOOKS or table.Copy( hook.GetTable()["NeedsDepthPass"] )

local debug_mode = r_shaderlib_debug:GetBool()

local function DisableDepthBuffer(ply)
	STORE_DEPTH_HOOKS = table.Copy( hook.GetTable()["NeedsDepthPass"] )

	for hook_name, func in pairs(STORE_DEPTH_HOOKS) do
		hook.Remove("NeedsDepthPass", hook_name)
		if IsValid(ply) and debug_mode then
			ply:PrintMessage( HUD_PRINTTALK, "Removed NeedsDepthPass "..hook_name.." hook." )
		end
	end
end

cvars.AddChangeCallback( r_shaderlib_depthbuffer:GetName(), function( convar_name, _, identifier )
	local enable = identifier == "1"
	local ply = LocalPlayer()

	if enable then
		for hook_name, func in pairs(STORE_DEPTH_HOOKS) do // Return all removed depth buffer hooks
			hook.Add("NeedsDepthPass", hook_name, func)
			if debug_mode then
				ply:PrintMessage( HUD_PRINTTALK, "Added NeedsDepthPass "..hook_name.." hook." )
			end
		end
	else
		DisableDepthBuffer(ply)
	end

end, libName )

local rt_Decode_Tangents
local rt_Decode_Normals
--local rt_Binormals

local debug_decode = r_shaderlib_debug_decode:GetBool()

local wn_formats = {
    [24] = "IMAGE_FORMAT_RGBA16161616F";
    [29] = "IMAGE_FORMAT_RGBA32323232F";
    [2] = "IMAGE_FORMAT_RGB888"; -- IMAGE_FORMAT_RGBA8888 0 
}

local n_format_decode

local function InitTestRT()
	if !debug_decode then return end

	rt_Decode_Tangents = GetRenderTargetEx("_rt_Decode_Tangents", ScrW(), ScrH(),
	    RT_SIZE_FULL_FRAME_BUFFER,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(4, 8, 256, 512, 32768, 8388608),
	    0,
	    --IMAGE_FORMAT_RGBA16161616F
	    IMAGE_FORMAT_RGBA32323232F
	)

	rt_Decode_Normals = GetRenderTargetEx("_rt_Decode_Normals", ScrW(), ScrH(),
	    RT_SIZE_FULL_FRAME_BUFFER,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(4, 8, 256, 512, 32768, 8388608),
	    0,
	    --IMAGE_FORMAT_RGBA16161616F
	    IMAGE_FORMAT_RGBA32323232F
	)

	/*rt_Binormals = GetRenderTargetEx("_rt_Binormals", ScrW(), ScrH(),
	    RT_SIZE_FULL_FRAME_BUFFER,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(4, 8, 256, 512, 32768, 8388608),
	    0,
	    shaderlib.GetWorldNormalsImageFormat()
	)*/
end

-- смена хука рендера на PreDrawViewModels фиксит баг отсутствия рендера реконструкций под водой

local function InitParams()
	shaderlib.normals_smooth = r_shaderlib_wn_smooth:GetBool()
	// The rendertarget format is applied once and does not change. It seems that it is impossible to get the image format using the function. That is why I output it like this.
	NW_IMG = NW_IMG or shaderlib.GetWorldNormalsImageFormat()
	NM_IMG_FORMAT = wn_formats[NW_IMG]

	local function EnableReconstruction()
		local value = GetConVar("mat_viewportscale"):GetFloat()
		if value < 1 then
			LocalPlayer():ChatPrint( "Warning! Your mat_viewportscale is " .. value .. "! Set it to 1! Or shaders broke!" )
		end

		--local hook_name = vales_hook[math.Round(math.Clamp(r_shaderlib_hook:GetInt(),0,#vales_hook))] or "PreDrawTranslucentRenderables"
		local hook_name = "PreDrawTranslucentRenderables"
		--hook_name = "PreDrawEffects" -- ok

		--hook_name = "PreDrawViewModels"
		hook.Add(hook_name, libName, function(isDrawingDepth, isDrawSkybox, isDraw3DSkybox)
			shaderlib.DrawReconstruction(isDrawingDepth, isDrawSkybox, isDraw3DSkybox)
		end)
	end

	if r_shaderlib:GetBool() then EnableReconstruction() end

	if !r_shaderlib_depthbuffer:GetBool() then DisableDepthBuffer(LocalPlayer()) end

	cvars.AddChangeCallback( r_shaderlib_wn_smooth:GetName(), function( convar_name, _, identifier )
		shaderlib.normals_smooth = identifier == "1"
	end, libName )

	local nm_mats = {
		[0] = Material("pp/wpn_reconstruction_simple");
		[1] = Material("pp/wpn_reconstruction_3tap");
		[2] = Material("pp/wpn_reconstruction_4tap");
		[3] = Material("pp/wpn_reconstruction_improved");
		[4] = Material("pp/wpn_reconstruction_accurate");
	}

	nm_mats[1]:SetFloat("$c1_x", r_shaderlib_3tap_offset:GetFloat())

	cvars.AddChangeCallback( r_shaderlib_3tap_offset:GetName(), function( convar_name, _, identifier )
		nm_mats[1]:SetFloat("$c1_x", identifier)
	end, libName )


	local function getCurrentMethodMat(i)
		i = math.Clamp(math.Round(i), 0, r_shaderlib_wn_reconsruction:GetMax())
		shaderlib.mat_wpndepth 	= nm_mats[i]
	end

	timer.Simple(0, function()
		getCurrentMethodMat( r_shaderlib_wn_reconsruction:GetInt() )
	end)

	cvars.AddChangeCallback( r_shaderlib_wn_reconsruction:GetName(), function( convar_name, _, identifier )
		getCurrentMethodMat( tonumber(identifier) )
	end, libName )

	cvars.AddChangeCallback( r_shaderlib_debug_decode:GetName(), function( convar_name, _, identifier )
		debug_decode = tobool(identifier)

		InitTestRT()
	end, libName )

	local debug_hook = "HUDPaint"--"PreDrawHUD"

	function shaderlib.EnableDebugMode()
		local s = r_shaderlib_dbg_scale:GetFloat()

		local decode_mat = Material("pp/decode_normals_tangents")

		InitTestRT()

		local wp_name = shaderlib.rt_WPDepth:GetName() .." " .. shaderlib.rt_WPDepth:Width() .. "x" .. shaderlib.rt_WPDepth:Height() .. "\n".."IMAGE_FORMAT_RGBA32323232F" .."\n.RGB — WorldPos\n.A  — Depth"
		local nm_name = shaderlib.rt_NormalsTangents:GetName() .." " .. shaderlib.rt_NormalsTangents:Width() .. "x" .. shaderlib.rt_NormalsTangents:Height() .. "\n"..NM_IMG_FORMAT.. " (Encode)\n.RG — Normals\n.B — Tangents"
		if r_shaderlib_wn_format:GetInt() != 2 then
			nm_name = nm_name .. "\n.A — Sign"
		end

		local bm_name = shaderlib.rt_Bump:GetName() .." " .. shaderlib.rt_Bump:Width() .. "x" .. shaderlib.rt_Bump:Height() .. "\n".."IMAGE_FORMAT_RGBA8888".. "\n.RGB — Bumps\n.A — Fog"

		local depth_buffer = render.GetResolvedFullFrameDepth()
		local depth_name = depth_buffer:GetName() .." " .. depth_buffer:Width() .. "x" .. depth_buffer:Height() .. "\n"..(render.GetDXLevel() == 92 and "IMAGE_FORMAT_RGBA32323232F" or "IMAGE_FORMAT_R32F").. "\n.R — Depth"

		--local fog_name = shaderlib.rt_Fog:GetName() .." " .. shaderlib.rt_Fog:Width() .. "x" .. shaderlib.rt_Fog:Height() .. "\n".."IMAGE_FORMAT_I8".. "\n.R — Fog mask"

		local dc_name_format = wn_formats[n_format_decode]

	    hook.Add(debug_hook, libName, function()
	    	cam.Start2D()
	    	local scale = r_shaderlib_dbg_scale:GetFloat()/3
	        local scrw = ScrW() * scale
	        local scrh = ScrH() * scale

	        local x = ScrW()-scrw

	        render.DrawTextureToScreenRect(shaderlib.rt_WPDepth, x, 0, scrw, scrh)

	        draw.DrawText(wp_name, "DebugOverlay", x, 0, color_white)

	        render.DrawTextureToScreenRect(shaderlib.rt_NormalsTangents, x, scrh, scrw, scrh)
	        draw.DrawText(nm_name, "DebugOverlay", x, scrh, color_white)

	        local x2 = ScrW()-scrw*2

	        render.DrawTextureToScreenRect(depth_buffer, x2, 0, scrw, scrh)
	        draw.DrawText(depth_name, "DebugOverlay", x2, 0, color_white)

	        local x3 = ScrW()-scrw*3

        	render.DrawTextureToScreenRect(shaderlib.rt_Bump, x, scrh*2, scrw, scrh)
        	draw.DrawText(bm_name, "DebugOverlay", x, scrh*2, color_white)

	        if debug_decode then
	        	render.PushRenderTarget(rt_Decode_Normals) render.Clear(0,0,0,0) render.PopRenderTarget()
    			render.PushRenderTarget(rt_Decode_Tangents) render.Clear(0,0,0,0) render.PopRenderTarget()

    			--render.PushRenderTarget(rt_Binormals) render.Clear(0,0,0,0) render.PopRenderTarget()

	        	render.SetRenderTargetEx(0, rt_Decode_Normals)
		        render.SetRenderTargetEx(1, rt_Decode_Tangents)

		        render.SetMaterial(decode_mat) --encode test
		        shaderlib.DrawScreenQuad()

		        render.SetRenderTargetEx(0)
		        render.SetRenderTargetEx(1)

		        render.DrawTextureToScreenRect(rt_Decode_Tangents, x3, 0, scrw, scrh)
		        draw.DrawText(rt_Decode_Tangents:GetName().." (Decode debug) ".. rt_Decode_Tangents:Width().. "x".. rt_Decode_Tangents:Height() .. "\n".."IMAGE_FORMAT_RGBA32323232F", "DebugOverlay", x3, 0, color_white)

		        render.DrawTextureToScreenRect(rt_Decode_Normals, x3, scrh, scrw, scrh)
		        draw.DrawText(rt_Decode_Normals:GetName().." (Decode debug) ".. rt_Decode_Normals:Width().. "x".. rt_Decode_Normals:Height() .. "\n".."IMAGE_FORMAT_RGBA32323232F", "DebugOverlay", x3, scrh, color_white)
		    end
		    cam.End2D()
	    end)
	end

	cvars.AddChangeCallback( r_shaderlib:GetName(), function( convar_name, _, identifier )
		local enable = identifier == "1"

		if enable then
			EnableReconstruction()

			if r_shaderlib_debug:GetBool() then shaderlib.EnableDebugMode() end
		else 
			hook.Remove("HUDPaint", libName)
			hook.Remove("PreDrawTranslucentRenderables", libName)
		end
	end, libName )

	cvars.AddChangeCallback( r_shaderlib_debug:GetName(), function( convar_name, _, identifier )
		local state = identifier == "1"

		debug_mode = state
		
		if state then
			shaderlib.EnableDebugMode()
		else
			hook.Remove(debug_hook, libName)
		end
	end, libName )

	if r_shaderlib_debug:GetBool() and r_shaderlib:GetBool() then shaderlib.EnableDebugMode() end
end

hook.Add("InitPostReconstruction", libName, InitParams)


