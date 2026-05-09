local hookName = "TranslucentCrutch"

local classes = {
	["prop_door_rotating"] 			= true;
	["prop_physics"]		 		= true;
	["prop_dynamic"] 				= true;
	["prop_ragdoll"] 				= true;
	["prop_physics_multiplayer"] 	= true;
}

hook.Add("EnableTranslucentCrutch", hookName, function()
	for _, ent in ents.Iterator() do
		if !classes[ent:GetClass()] then continue end
		ent:SetKeyValue("fademindist", -1)
		ent:SetKeyValue("fademaxdist", 0)
		ent:SetRenderMode(RENDERMODE_NORMAL)
	end
end)
