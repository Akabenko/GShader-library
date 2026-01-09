local addons = engine.GetAddons()
local nak_installed = false

for i = 1, #addons do
    nak_installed = addons[i]["wsid"] == "2861839844"
    if nak_installed then break end
end

nak_installed = (nak_installed or NikNaks)

if nak_installed then
	require("niknaks")
end
