
local shaderName = "VelocityBuffer"

local function InitVelocityBuffer()
	local old_ViewProj = Matrix()
	local cur_ViewProj = Matrix()

	shaderlib.mat_velocity = Material("pp/velocity_buffer")

	shaderlib.rt_Velocity = GetRenderTargetEx("_rt_Velocity", ScrW(), ScrH(), 
	    RT_SIZE_FULL_FRAME_BUFFER,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(4,8,16,256,512),
	    0,
	    IMAGE_FORMAT_IA88 // encoded using CryTeck CryEngine 3 paper (Advances in Real-Time Rendering cource), LVutner's implementation.
	)

	function shaderlib.DrawVelocityBuffer(viewSetup)
		cur_ViewProj = shaderlib.GetViewProjMatrix(viewSetup)

	    shaderlib.mat_velocity:SetMatrix("$VIEWPROJMAT", old_ViewProj)

	    render.PushRenderTarget(shaderlib.rt_Velocity)
	        render.Clear(0,0,0,0)
	        render.SetMaterial(shaderlib.mat_velocity)
	        render.DrawScreenQuad()
	    render.PopRenderTarget()
	end

	hook.Add("PostRender", shaderName, function()
		old_ViewProj = cur_ViewProj
	end)
end 

hook.Add("InitReconstruction", shaderName, InitVelocityBuffer)
