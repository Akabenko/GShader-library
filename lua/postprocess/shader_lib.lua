
local libName = "shaderlib"

local r_shaderlib = CreateClientConVar( "r_shaderlib", "1", true, false, "Reconstruct WorldPos, Normals, Tangents.", 0, 1 )
local r_shaderlib_wp_format = CreateClientConVar( "r_shaderlib_wp_format", "1", true, false, "WorldPos IMAGE FORMAT.", 0, 1 )
local r_shaderlib_wn_format = CreateClientConVar( "r_shaderlib_wn_format", "1", true, false, "WorldNormals IMAGE FORMAT.", 0, 1 )
local r_shaderlib_depthbuffer = CreateClientConVar( "r_shaderlib_depthbuffer", "1", true, false, "Enable/disable depth buffer.", 0, 1 )
local r_shaderlib_wn_reconsruction = CreateClientConVar( "r_shaderlib_wn_reconsruction", "4", true, false, "Type of WorldNormals reconstruction.", 0, 4 )
local r_shaderlib_wn_smooth = CreateClientConVar( "r_shaderlib_wn_smooth", "0", true, false, "Smooth normals.", 0, 1 ) // beta
local r_shaderlib_debug = CreateClientConVar( "r_shaderlib_debug", "0", true, false, "Show rendertargets on HUD.", 0, 1 )
local r_shaderlib_debug_decode = CreateClientConVar( "r_shaderlib_debug_decode", "0", false, false, "Show decoded rendertargets on HUD.", 0, 1 ) 
local r_shaderlib_dbg_scale = CreateClientConVar( "r_shaderlib_dbg_scale", "0.5", true, false, "Scale factor debug rt.", 0.4, 1 )
local r_shaderlib_3tap_offset = CreateClientConVar( "r_shaderlib_3tap_offset", "1", true, false, "Scale factor debug rt.", 0.6, 1.49 )
local r_shaderlib_mrt = CreateClientConVar( "r_shaderlib_mrt", "1", true, false, "MRT may not work for some reason on some systems. The reason is not yet understood. If Debug mode displays a black image, try disabling MRT.", 0, 1 )
local r_shaderlib_hook = CreateClientConVar( "r_shaderlib_hook", "0", true, false, "The hook where the reconstruction will take place. The best choice is PreDrawTranslucentRenderables. But if you have a black screen, you can try to choose another one, but in this case ghosting is possible.", 0, 3 )
local r_shaderlib_velocity = CreateClientConVar( "r_shaderlib_velocity", "1", true, false, "Enable Velocity buffer.", 0, 1 )
local r_shaderlib_velx = CreateClientConVar( "r_shaderlib_velx", "0.5", true, false, "X multiplier of Velocity buffer.", 0.5, 10 )
local r_shaderlib_vely = CreateClientConVar( "r_shaderlib_vely", "0.5", true, false, "Y multiplier of Velocity buffer.", 0.5, 10 )


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
					[ r_shaderlib_wp_format:GetName() ] 		= r_shaderlib_wp_format:GetDefault(),
					[ r_shaderlib_wn_format:GetName() ] 		= r_shaderlib_wn_format:GetDefault(),
					[ r_shaderlib_depthbuffer:GetName() ] 		= r_shaderlib_depthbuffer:GetDefault(),
					[ r_shaderlib_wn_reconsruction:GetName() ] 	= r_shaderlib_wn_reconsruction:GetDefault(),
					[ r_shaderlib_dbg_scale:GetName() ] 		= r_shaderlib_dbg_scale:GetDefault(),
					[ r_shaderlib_wn_smooth:GetName() ] 		= r_shaderlib_wn_smooth:GetDefault(),
					[ r_shaderlib_debug_decode:GetName() ]		= r_shaderlib_debug_decode:GetDefault(),
					[ r_shaderlib_debug:GetName() ] 			= r_shaderlib_debug_decode:GetDefault(),
					[ r_shaderlib_3tap_offset:GetName() ] 		= r_shaderlib_3tap_offset:GetDefault(),
					[ r_shaderlib_mrt:GetName() ] 				= r_shaderlib_mrt:GetDefault(),
					[ r_shaderlib_hook:GetName() ] 				= r_shaderlib_hook:GetDefault(),
					[ r_shaderlib_velocity:GetName() ]			= r_shaderlib_velocity:GetDefault(),
					[ r_shaderlib_velx:GetName() ] 				= r_shaderlib_velx:GetDefault(),
					[ r_shaderlib_vely:GetName() ]				= r_shaderlib_vely:GetDefault(),
				},

				[ "#r_shaderlib.medium" ] = {
					[ r_shaderlib:GetName() ] 					= r_shaderlib:GetDefault(),
					[ r_shaderlib_wp_format:GetName() ] 		= r_shaderlib_wp_format:GetDefault(),
					[ r_shaderlib_wn_format:GetName() ] 		= "0",
					[ r_shaderlib_depthbuffer:GetName() ] 		= r_shaderlib_depthbuffer:GetDefault(),
					[ r_shaderlib_wn_reconsruction:GetName() ] 	= "3",
					[ r_shaderlib_dbg_scale:GetName() ] 		= r_shaderlib_dbg_scale:GetDefault(),
					[ r_shaderlib_wn_smooth:GetName() ]			= r_shaderlib_wn_smooth:GetDefault(),
					[ r_shaderlib_debug_decode:GetName() ] 		= r_shaderlib_debug_decode:GetDefault(),
					[ r_shaderlib_debug:GetName() ] 			= r_shaderlib_debug:GetDefault(),
					[ r_shaderlib_3tap_offset:GetName() ] 		= r_shaderlib_3tap_offset:GetDefault(),
					[ r_shaderlib_mrt:GetName() ] 				= r_shaderlib_mrt:GetDefault(),
					[ r_shaderlib_hook:GetName() ] 				= r_shaderlib_hook:GetDefault(),
					[ r_shaderlib_velocity:GetName() ]			= r_shaderlib_velocity:GetDefault(),
					[ r_shaderlib_velx:GetName() ] 				= r_shaderlib_velx:GetDefault(),
					[ r_shaderlib_vely:GetName() ]				= r_shaderlib_vely:GetDefault(),
				},

				[ "#r_shaderlib.mininal" ] = {
					[ r_shaderlib:GetName() ] 					= r_shaderlib:GetDefault(),
					[ r_shaderlib_wp_format:GetName() ] 		= "0",
					[ r_shaderlib_wn_format:GetName() ] 		= "0",
					[ r_shaderlib_depthbuffer:GetName() ] 		= r_shaderlib_depthbuffer:GetDefault(),
					[ r_shaderlib_wn_reconsruction:GetName() ] 	= "3",
					[ r_shaderlib_dbg_scale:GetName() ] 		= r_shaderlib_dbg_scale:GetDefault(),
					[ r_shaderlib_wn_smooth:GetName() ]			= "0",
					[ r_shaderlib_debug_decode:GetName() ] 		= r_shaderlib_debug_decode:GetDefault(),
					[ r_shaderlib_debug:GetName() ] 			= r_shaderlib_debug:GetDefault(),
					[ r_shaderlib_3tap_offset:GetName() ] 		= r_shaderlib_3tap_offset:GetDefault(),
					[ r_shaderlib_mrt:GetName() ] 				= r_shaderlib_mrt:GetDefault(),
					[ r_shaderlib_hook:GetName() ] 				= r_shaderlib_hook:GetDefault(),
					[ r_shaderlib_velocity:GetName() ]			= "0",
					[ r_shaderlib_velx:GetName() ] 				= r_shaderlib_velx:GetDefault(),
					[ r_shaderlib_vely:GetName() ]				= r_shaderlib_vely:GetDefault(),
				},
			},
			["CVars"] = {
				r_shaderlib:GetName(),
				r_shaderlib_wp_format:GetName(),
				r_shaderlib_wn_format:GetName(),
				r_shaderlib_depthbuffer:GetName(),
				r_shaderlib_wn_reconsruction:GetName(),
				r_shaderlib_dbg_scale:GetName(),
				r_shaderlib_wn_smooth:GetName(),
				r_shaderlib_debug_decode:GetName(),
				r_shaderlib_debug:GetName(),
				r_shaderlib_3tap_offset:GetName(),
				r_shaderlib_mrt:GetName(),
				r_shaderlib_hook:GetName(),
				r_shaderlib_velocity:GetName(),
				r_shaderlib_velx:GetName(),
				r_shaderlib_vely:GetName(),
			}
		} )

		panel:AddControl( "CheckBox", {
			["Label"] = "#r_shaderlib.enable_reconsruction",
			["Command"] = r_shaderlib:GetName()
		} )

		panel:AddControl( "CheckBox", {
			["Label"] = "#r_shaderlib.depthbuffer",
			["Command"] = r_shaderlib_depthbuffer:GetName()
		} )

		panel:AddControl( "CheckBox", {
			["Label"] = "#r_shaderlib.velocitybuffer",
			["Command"] = r_shaderlib_velocity:GetName()
		} )

		panel:AddControl( "Slider", {
			["Label"] = "#r_shaderlib.velocity_x",
			["Command"] = r_shaderlib_vely:GetName(),
			["Min"] = tostring( r_shaderlib_vely:GetMin() ),
			["Max"] = tostring( r_shaderlib_vely:GetMax() ),
			["Type"] = "Float",
			["Help"] = false
		} )

		panel:AddControl( "Slider", {
			["Label"] = "#r_shaderlib.velocity_y",
			["Command"] = r_shaderlib_velx:GetName(),
			["Min"] = tostring( r_shaderlib_velx:GetMin() ),
			["Max"] = tostring( r_shaderlib_velx:GetMax() ),
			["Type"] = "Float",
			["Help"] = false
		} )

		panel:Help( "#r_shaderlib.formats" )
		
		panel:AddControl( "combobox", {
			["Label"] = "#r_shaderlib.wp_format",
			["Command"] = r_shaderlib_wp_format:GetName(),
			["Options"] = {
				[ "#r_shaderlib.16161616f" ] = {
					[ r_shaderlib_wp_format:GetName() ] = "0",
				},

				[ "#r_shaderlib.32323232f" ] = {
					[ r_shaderlib_wp_format:GetName() ] = "1",
				},
			},
			["CVars"] = {
				r_shaderlib_wp_format:GetName(),
			},
			["Help"] = false,
		} )


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
			},
			["CVars"] = {
				r_shaderlib_wn_format:GetName(),
			},
			["Help"] = false,
		} )

		panel:Help( "#r_shaderlib.reconsruction" )

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

		panel:AddControl( "CheckBox", {
			["Label"] = "#r_shaderlib.wn_smooth",
			["Command"] = r_shaderlib_wn_smooth:GetName()
		} )

		panel:Help( "#r_shaderlib.encode" )

		panel:Help( "#r_shaderlib.debug" )

		panel:AddControl( "CheckBox", {
			["Label"] = "#r_shaderlib.debug_enable",
			["Command"] = r_shaderlib_debug:GetName()
		} )

		panel:Help( "#r_shaderlib.decode_info" )

		panel:AddControl( "CheckBox", {
			["Label"] = "#r_shaderlib.debug_decode",
			["Command"] = r_shaderlib_debug_decode:GetName()
		} )

		panel:AddControl( "Slider", {
			["Label"] = "#r_shaderlib.dbg_scale",
			["Command"] = r_shaderlib_dbg_scale:GetName(),
			["Min"] = tostring( r_shaderlib_dbg_scale:GetMin() ),
			["Max"] = tostring( r_shaderlib_dbg_scale:GetMax() ),
			["Type"] = "Float",
			["Help"] = false
		} )

		panel:Help( "#r_shaderlib.mrtinfo" )

		panel:AddControl( "CheckBox", {
			["Label"] = "#r_shaderlib.mrt",
			["Command"] = r_shaderlib_mrt:GetName()
		} )

		panel:Help( "#r_shaderlib.hookinfo" )

		panel:AddControl( "combobox", {
			["Label"] = "#r_shaderlib.hook",
			["Sort"] = true,
			["Command"] = r_shaderlib_hook:GetName(),
			["Options"] = {
				[ "#r_shaderlib.predrawrt" ] = {
					[ r_shaderlib_hook:GetName() ] = "0",
				},

				[ "#r_shaderlib.postdrawop" ] = {
					[ r_shaderlib_hook:GetName() ] = "1",
				},

				[ "#r_shaderlib.predrawef" ] = {
					[ r_shaderlib_hook:GetName() ] = "2",
				},

				[ "#r_shaderlib.renderscreen" ] = {
					[ r_shaderlib_hook:GetName() ] = "3",
				},
			},
			["CVars"] = {
				r_shaderlib_hook:GetName(),
			},
			["Help"] = false,
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
local rt_Decode_Velocity
--local rt_Binormals

local debug_decode = r_shaderlib_debug_decode:GetBool()

local function InitTestRT()
	if !debug_decode then return end
	rt_Decode_Tangents = GetRenderTargetEx("_rt_Decode_Tangents", ScrW(), ScrH(),
	    RT_SIZE_FULL_FRAME_BUFFER,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(4, 8, 256, 512, 32768, 8388608),
	    0,
	    shaderlib.GetWorldNormalsImageFormat()
	)

	rt_Decode_Normals = GetRenderTargetEx("_rt_Decode_Normals", ScrW(), ScrH(),
	    RT_SIZE_FULL_FRAME_BUFFER,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(4, 8, 256, 512, 32768, 8388608),
	    0,
	    shaderlib.GetWorldNormalsImageFormat()
	)

	rt_Decode_Velocity = GetRenderTargetEx("_rt_Decode_Velocity", ScrW(), ScrH(),
	    RT_SIZE_FULL_FRAME_BUFFER,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(4, 8, 16, 256, 512),
	    0,
	    IMAGE_FORMAT_RGBA16161616F
	)

	/*rt_Binormals = GetRenderTargetEx("_rt_Binormals", ScrW(), ScrH(),
	    RT_SIZE_FULL_FRAME_BUFFER,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(4, 8, 256, 512, 32768, 8388608),
	    0,
	    shaderlib.GetWorldNormalsImageFormat()
	)*/
end

local function InitParams()
	shaderlib.normals_smooth = r_shaderlib_wn_smooth:GetBool()
	// The rendertarget format is applied once and does not change. It seems that it is impossible to get the image format using the function. That is why I output it like this.
	NM_IMG_FORMAT = NM_IMG_FORMAT or (
		shaderlib.GetWorldNormalsImageFormat() == IMAGE_FORMAT_RGBA32323232F and "IMAGE_FORMAT_RGBA32323232F" or "IMAGE_FORMAT_RGBA16161616F")

	WP_IMG_FORMAT = WP_IMG_FORMAT or (
		shaderlib.GetWorldPosImageFormat() == IMAGE_FORMAT_RGBA32323232F and "IMAGE_FORMAT_RGBA32323232F" or "IMAGE_FORMAT_RGBA16161616F")

	local vales_hook = {
		[0] = "PreDrawTranslucentRenderables",
		[1] = "PostDrawOpaqueRenderables",
		[2] = "PreDrawEffects",
		[3] = "RenderScreenspaceEffects",
	}

	local function EnableReconstruction()
		local hook_name = vales_hook[math.Round(math.Clamp(r_shaderlib_hook:GetInt(),0,#vales_hook))] or "PreDrawTranslucentRenderables"
		hook.Add(hook_name, libName, function(isDrawingDepth, isDrawSkybox, isDraw3DSkybox)
			shaderlib.DrawReconstruction(isDrawingDepth, isDrawSkybox, isDraw3DSkybox)
		end)
	end

	cvars.AddChangeCallback( r_shaderlib_hook:GetName(), function( convar_name, _, identifier )
		if r_shaderlib:GetBool() then EnableReconstruction() end
	end, libName )

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
		shaderlib.mat_wpndepth = nm_mats[i]
		shaderlib.mat_wpndepth:SetFloat("$c0_w", 1)
        shaderlib.mat_wpndepth:SetFloat("$c1_w", 4000) // spans 4000, znear of 1 (correct if wrong)
	end

	getCurrentMethodMat( r_shaderlib_wn_reconsruction:GetInt() )

	cvars.AddChangeCallback( r_shaderlib_wn_reconsruction:GetName(), function( convar_name, _, identifier )
		getCurrentMethodMat( tonumber(identifier) )
	end, libName )

	cvars.AddChangeCallback( r_shaderlib_debug_decode:GetName(), function( convar_name, _, identifier )
		debug_decode = tobool(identifier)

		InitTestRT()
	end, libName )

	cvars.AddChangeCallback( r_shaderlib_velx:GetName(), function( convar_name, _, identifier )
		shaderlib.mat_velocity:SetFloat("$c0_x", identifier)
	end, libName )

	cvars.AddChangeCallback( r_shaderlib_vely:GetName(), function( convar_name, _, identifier )
		shaderlib.mat_velocity:SetFloat("$c0_y", identifier)
	end, libName )

	local function EnableDebugMode()
		local s = r_shaderlib_dbg_scale:GetFloat()

		local decode_mat = Material("pp/decode_normals_tangents")
		local decode_velocity = Material("pp/decode_velocity_buffer")

		InitTestRT()

		local wp_name = shaderlib.rt_WPDepth:GetName() .." " .. shaderlib.rt_WPDepth:Width() .. "x" .. shaderlib.rt_WPDepth:Height() .. "\n"..WP_IMG_FORMAT .."\n.RGB — WorldPos\n.A  — Depth"
		local nm_name = shaderlib.rt_NormalsTangents:GetName() .." " .. shaderlib.rt_NormalsTangents:Width() .. "x" .. shaderlib.rt_NormalsTangents:Height() .. "\n"..NM_IMG_FORMAT.. " (Encode)\n.RG — Normals\n.B — Tangents\n.A — Sign"

		local vt_name = shaderlib.rt_Velocity:GetName() .." " .. shaderlib.rt_Velocity:Width() .. "x" .. shaderlib.rt_Velocity:Height() .. "\n".."IMAGE_FORMAT_IA88".. "\n.R — MontionVector.x\n.A — MontionVector.y"

		local depth_buffer = render.GetResolvedFullFrameDepth()
		local depth_name = depth_buffer:GetName() .." " .. depth_buffer:Width() .. "x" .. depth_buffer:Height() .. "\n"..(render.GetDXLevel() == 92 and "IMAGE_FORMAT_RGBA32323232F" or "IMAGE_FORMAT_R32F").. "\n.R — Depth"

	    hook.Add("HUDPaint", libName, function()
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

	        local enabled_velocity_buffer = r_shaderlib_velocity:GetBool()

	        if enabled_velocity_buffer then
	        	render.DrawTextureToScreenRect(shaderlib.rt_Velocity, x2, scrh, scrw, scrh)
	        	draw.DrawText(vt_name, "DebugOverlay", x2, scrh, color_white)
	        end

	        -- декодируем

	        if debug_decode then
	        	render.PushRenderTarget(rt_Decode_Normals) render.Clear(0,0,0,0) render.PopRenderTarget()
    			render.PushRenderTarget(rt_Decode_Tangents) render.Clear(0,0,0,0) render.PopRenderTarget()

    			if enabled_velocity_buffer then
	    			render.PushRenderTarget(rt_Decode_Velocity)
	    				render.Clear(0,0,0,0)
	    				render.SetMaterial(decode_velocity)
	    				render.DrawScreenQuad()
	    			render.PopRenderTarget()
	    		end

    			--render.PushRenderTarget(rt_Binormals) render.Clear(0,0,0,0) render.PopRenderTarget()

	        	render.SetRenderTargetEx(0, rt_Decode_Normals)
		        render.SetRenderTargetEx(1, rt_Decode_Tangents)

		        render.SetMaterial(decode_mat) --encode test
		        shaderlib.DrawScreenQuad()

		        render.SetRenderTargetEx(0)
		        render.SetRenderTargetEx(1)

		        local x3 = ScrW()-scrw*3

		        render.DrawTextureToScreenRect(rt_Decode_Tangents, x3, 0, scrw, scrh)
		        draw.DrawText(rt_Decode_Tangents:GetName().." (Decode debug) ".. rt_Decode_Tangents:Width().. "x".. rt_Decode_Tangents:Height() .. "\n"..NM_IMG_FORMAT, "DebugOverlay", x3, 0, color_white)

		        render.DrawTextureToScreenRect(rt_Decode_Normals, x3, scrh, scrw, scrh)
		        draw.DrawText(rt_Decode_Normals:GetName().." (Decode debug) ".. rt_Decode_Normals:Width().. "x".. rt_Decode_Normals:Height() .. "\n"..NM_IMG_FORMAT, "DebugOverlay", x3, scrh, color_white)

		        render.DrawTextureToScreenRect(rt_Decode_Velocity, x2, scrh*2, scrw, scrh)
		        draw.DrawText(rt_Decode_Velocity:GetName().." (Decode debug) ".. rt_Decode_Velocity:Width().. "x".. rt_Decode_Velocity:Height() .. "\n".."IMAGE_FORMAT_RGBA16161616F", "DebugOverlay", x2, scrh*2, color_white)
		    end
	    end)
	end

	cvars.AddChangeCallback( r_shaderlib:GetName(), function( convar_name, _, identifier )
		local enable = identifier == "1"

		if enable then
			EnableReconstruction()

			if r_shaderlib_debug:GetBool() then EnableDebugMode() end
		else 
			hook.Remove("HUDPaint", libName)

			for i = 0,#vales_hook do
				print(i)
				hook.Remove(vales_hook[i], libName)
			end
		end
	end, libName )

	shaderlib.mrt_enabled = r_shaderlib_mrt:GetBool()

	cvars.AddChangeCallback( r_shaderlib_mrt:GetName(), function( convar_name, _, identifier )
		local state = identifier == "1"
		shaderlib.mrt_enabled = state
	end, libName )

	velocity_postrender_func = velocity_postrender_func or hook.GetTable()["PostRender"]["VelocityBuffer"]

	local function EnableVelocityBuffer()
		hook.Add("PostDrawReconstruction", "VelocityBuffer", function(viewSetup)
			shaderlib.DrawVelocityBuffer(viewSetup)
		end)

		hook.Add("PostRender","VelocityBuffer",velocity_postrender_func)
	end

	if r_shaderlib_velocity:GetBool() then
		EnableVelocityBuffer()
	else
		hook.Remove("PostRender", "VelocityBuffer")
	end

	cvars.AddChangeCallback( r_shaderlib_velocity:GetName(), function( convar_name, _, identifier )
		local state = identifier == "1"

		if state then
			EnableVelocityBuffer()
		else
			hook.Remove("PostDrawReconstruction", "VelocityBuffer")
			hook.Remove("PostRender", "VelocityBuffer")
		end

	end, libName )

	if r_shaderlib_debug:GetBool() and r_shaderlib:GetBool() then EnableDebugMode() end

	cvars.AddChangeCallback( r_shaderlib_debug:GetName(), function( convar_name, _, identifier )
		local state = identifier == "1"

		debug_mode = state
		
		if state then
			EnableDebugMode()
		else
			hook.Remove("HUDPaint", libName)
		end
	end, libName )
end

hook.Add("InitPostReconstruction", libName, InitParams)
