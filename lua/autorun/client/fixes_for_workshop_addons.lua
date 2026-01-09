
/*---------------------------------------------------------------------------
Fixing some workshop addons for NeedDepthPass.
---------------------------------------------------------------------------*/

local libname = "shaderlib_fixes"

local entMeta = FindMetaTable("Entity")

local SetNoDraw = entMeta.SetNoDraw
local IsValid = IsValid
local LocalPlayer = LocalPlayer
local GetChildren = entMeta.GetChildren
local SetRenderOrigin = entMeta.SetRenderOrigin
local SetRenderAngles = entMeta.SetRenderAngles
local Angle = Angle
local GetAngles = entMeta.GetAngles
local render = render

hook.Add("LocalPlayer_Validated", libname, function() // First-Person Body
    timer.Simple(0, function()
        local ply = LocalPlayer()
        local ply_Body = ply.Body
        if IsValid(ply_Body) then 
            old_Body_Render = old_Body_Render or ply.Body.RenderOverride

            ply.Body.RenderOverride = function(self, flag)
                old_Body_Render(self,STUDIO_RENDER)
            end
        end
    end)
end)

hook.Add("InitPostEntity", libname, function() 
    /*if g_Legs then // GMOD Legs 3
        old_LegsDoFinalRender = old_LegsDoFinalRender or g_Legs.DoFinalRender

        local rt_blacklist = {
            ["_rt_waterreflection"] = true,
            ["_rt_waterrefraction"] = true,
            ["_rt_camera"] = true,
        }

        local function HideLegs(ent)
            SetNoDraw(ent, true)
            SetRenderOrigin(ent)
            SetRenderAngles(ent)
        end

        function g_Legs:DoFinalRender()
            local rt = render.GetRenderTarget()

            if rt and rt:GetName() then
                if rt_blacklist[rt:GetName()] then 
                    return
                end
            end
            
            --local dist = LocalPlayer():EyePos():DistToSqr(EyePos())

            --[[if dist > 0 then // fix third person render
                HideLegs(self.LegEnt)
                return
            end]]

            SetNoDraw(self.LegEnt, false) // fix depth buffer
            old_LegsDoFinalRender(self)
            SetRenderOrigin(self.LegEnt, self.RenderPos)
            SetRenderAngles(self.LegEnt, self.RenderAngle)
        end
    end*/

    if ArcCW then
        local function FixACRCWBase(class)
            class = class or "arccw_base"
            local ENT = weapons.GetStored(class)

            old_DrawHolosight = old_DrawHolosight or ENT.DrawHolosight
            old_FormCheapScope = old_FormCheapScope or ENT.FormCheapScope

            local function depthBufferCheck()
                local rt = render.GetRenderTarget()
                return rt and rt:GetName() == "_rt_resolvedfullframedepth"
            end

            function ENT:DrawHolosight(...)
                if depthBufferCheck() then return end
                old_DrawHolosight(self, ...)
            end

            function ENT:FormCheapScope(...)
                if depthBufferCheck() then return end
                old_FormCheapScope(self, ...)
            end

            weapons.Register(ENT, class)
        end

        for k,v in pairs(weapons.GetList()) do
            if v.Base == "arccw_base" then
                FixACRCWBase(v.ClassName)
            end
        end

        FixACRCWBase()
    end

    if EnhancedCameraTwo then // Enhanced Camera 2
        old_enca2_render = old_enca2_render or EnhancedCameraTwo.Render
        old_enca2_setmodel = old_enca2_setmodel or EnhancedCameraTwo.SetModel

         function EnhancedCameraTwo:GetRenderPosAngle() 
            local ply = LocalPlayer()
            local renderPos = ply:EyePos() // fix for CSM and other addons with shadowmap/snowmap
            local renderAngle
            
            if ply:InVehicle() then
                renderAngle = GetAngles( ply:GetVehicle() )
                renderAngle:RotateAroundAxis(renderAngle:Up(), EnhancedCameraTwo.vehicleAngle)
            else
                renderAngle = Angle(0, ply:EyeAngles().y, 0)
            end

            local offset = EnhancedCameraTwo.viewOffset - EnhancedCameraTwo.neckOffset
            offset:Rotate(renderAngle)

            renderPos = renderPos + offset
            return renderPos, renderAngle
        end
        
        function EnhancedCameraTwo:Render()
            local renderPos, renderAngle = self:GetRenderPosAngle()
            old_enca2_render(self)
            if IsValid(self.entity) then // was lua error sometimes
                SetRenderOrigin(self.entity, renderPos)
                SetRenderAngles(self.entity, renderAngle)
            end
        end

        function EnhancedCameraTwo:SetModel(model)
            old_enca2_setmodel(self, model)
            if IsValid(self.entity) then
                SetNoDraw(self.entity, false)
            end
        end
    end
end)

hook.Add("Initialize", libname,function()
    --RunConsoleCommand("mat_viewportscale", 1) -- some users have 0.8 value. so it broke depth buffer
    hook.Remove("NeedsDepthPass", "FAS2_NeedsDepthPass") // FAS2 fix: Fas2 broke ResolvedDepthBuffer
    
    if TFA then
        -- fix TFA flashlight glitches

        hook.Add("PreDrawTranslucentRenderables", "TFA_fix_flashligth", function(isDrawingDepth, isDrawSkybox, isDraw3DSkybox)
            if isDrawingDepth or isDrawSkybox or isDraw3DSkybox then return end

            if render.GetViewSetup(true).viewid != 0 then return end

            local wep = LocalPlayer():GetActiveWeapon()
            if !IsValid(wep) then return end
            if not wep.IsTFAWeapon then return end

            wep:DrawFlashlight(wep)
        end)

        local function FixTFABase(class)
            local ENT = weapons.GetStored(class)

            function ENT:UpdateProjectedTextures(view)
                self:DrawLaser(view)
                -- self:DrawFlashlight(view)
            end

            weapons.Register(ENT, class)
        end

        for k,v in pairs(weapons.GetList()) do
            if v.Base == "tfa_gun_base" or v.IsTFAWeapon then
                FixTFABase(v.ClassName)
            end
        end
    end

    if CLegs then
        local ENT = scripted_ents.Get("firstperson_legs")
        ENT.RenderGroup = RENDERGROUP_OPAQUE

        hook.Remove("PostDrawTranslucentRenderables", "CLegs.DoRender") // Fixing double leg rendering

        function ENT:Draw()
            self:DoRender(LocalPlayer())
            SetRenderOrigin(self, self.RenderPos)
            SetRenderAngles(self, self.RenderAngle)
        end

        scripted_ents.Register( ENT, "firstperson_legs" )
    end
end)

/*---------------------------------------------------------------------------
FIXED:
First Person Legs:          https://steamcommunity.com/sharedfiles/filedetails/?id=3348203779&searchtext=legs
GMOD Legs 3                 https://steamcommunity.com/sharedfiles/filedetails/?id=112806637&searchtext=gmod+legs (Mirror bug)
clegs                       https://steamcommunity.com/sharedfiles/filedetails/?id=3386878739&searchtext=clegs+
Enhanced Camera 2           https://steamcommunity.com/sharedfiles/filedetails/?id=2203217139
ACRCW write FrameBuffer info DepthBuffer 

UNFIXED:
Enhanced Camera             https://steamcommunity.com/sharedfiles/filedetails/?id=678037029&searchtext=Enhanced+Camera

CFShadow: эта хуйня походу ломает буфер глубины к хуям
https://steamcommunity.com/sharedfiles/filedetails/?id=3386876474

Тело от Первого лица: https://steamcommunity.com/sharedfiles/filedetails/?id=3104967124

Исправлено:
1. В TFA (3D SCOPES) не появляются фонтанчики от выстрелом при включенном MRT
2. Фонарики ТФА запаздыают из-за буфера глубины (фикс - выбран рекомендованный хук для обновления projtexture)
3. Антискример не давал вызвать локализированные функции DrawScreenQuad https://steamcommunity.com/sharedfiles/filedetails/?id=3404179264


---------------------------------------------------------------------------*/









