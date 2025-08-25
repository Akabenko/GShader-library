
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
    if MW_ATTS then // MW base
        local function FixMWBase(class)
            class = class or "mg_base"
            local ENT = weapons.GetStored(class)

            function ENT:PostDrawViewModel( ViewModel )
                local children = GetChildren(self)
                local ent = children[#children] --mg_viewmodel
                if !IsValid(ent) then return end
                SetNoDraw(ent, false)
            end

            weapons.Register(ENT, class)
        end

        for k,v in pairs(weapons.GetList()) do
            if string.find(v.ClassName, "mg_") then
                FixMWBase(v.ClassName)
            end
        end

        FixMWBase()
    end

    if g_Legs then // GMOD Legs 3
        old_LegsDoFinalRender = old_LegsDoFinalRender or g_Legs.DoFinalRender

        function g_Legs:DoFinalRender()
            SetNoDraw(self.LegEnt, false)
            old_LegsDoFinalRender(self)
            SetRenderOrigin(self.LegEnt, self.RenderPos)
            SetRenderAngles(self.LegEnt, self.RenderAngle)
        end
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
            SetRenderOrigin(self.entity, renderPos)
            SetRenderAngles(self.entity, renderAngle)
        end

        function EnhancedCameraTwo:SetModel(model)
            old_enca2_setmodel(self, model)
            SetNoDraw(self.entity, false)
        end
    end
end)

hook.Add("Initialize", libname,function() // clegs
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

    if VManip then
        hook.Add("PostDrawViewModel", libname, function()// 不明原因
            if IsValid(VManip.VMGesture) and hook.Run("NeedsDepthPass") == true then
                VManip.VMGesture:SetupBones()
                VManip.VMGesture:DrawModel()
            end
        end)
    end
end)


/*---------------------------------------------------------------------------
FIXED:
First Person Legs:          https://steamcommunity.com/sharedfiles/filedetails/?id=3348203779&searchtext=legs
Modern Bentleyfare Base:    https://steamcommunity.com/workshop/filedetails/?id=2459720887
GMOD Legs 3                 https://steamcommunity.com/sharedfiles/filedetails/?id=112806637&searchtext=gmod+legs
clegs                       https://steamcommunity.com/sharedfiles/filedetails/?id=3386878739&searchtext=clegs+
Enhanced Camera 2           https://steamcommunity.com/sharedfiles/filedetails/?id=2203217139
VManip (Base)               https://steamcommunity.com/sharedfiles/filedetails/?id=2155366756

UNFIXED:
Enhanced Camera             https://steamcommunity.com/sharedfiles/filedetails/?id=678037029&searchtext=Enhanced+Camera
---------------------------------------------------------------------------*/








