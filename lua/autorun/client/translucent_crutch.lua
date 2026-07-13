local hookName = "TranslucentHack"

local classes = {
	["prop_door_rotating"] 			= true;
	["prop_physics"]		 		= true;
	["prop_dynamic"] 				= true;
	["prop_ragdoll"] 				= true;
	["prop_physics_multiplayer"] 	= true;
}

local function HackEnt(ent)
	if !IsValid(ent) then return end
	if !classes[ent:GetClass()] then return end
	ent:SetKeyValue("fademindist", -1)
	ent:SetKeyValue("fademaxdist", 0)
	ent:SetRenderMode(RENDERMODE_NORMAL)
end

local function HackFade()
	for _, ent in ents.Iterator() do
		HackEnt(ent)
	end
end

hook.Add("EnableTranslucentCrutch", hookName, function()
	HackFade()

	hook.Add("PostCleanupMap", hookName, function()
		timer.Simple(2, function()
			HackFade()
		end)
	end)

	hook.Add("OnEntityCreated", hookName, function(ent)
		timer.Simple(0, function()
			HackEnt(ent)
		end)
	end)
end)



