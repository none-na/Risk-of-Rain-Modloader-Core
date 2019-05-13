local GML = GML
local type = type
local typeOf = typeOf
-- Initialize table
net = {}

net.ALL = 1
net.EXCLUDE = 2
net.DIRECT = 3

local online = false
function RefreshNetAPI(tables)
	local coop = AnyTypeRet(GML.variable_instance_get(GML_init_instance_id, "coop")) == 2
	online = coop

	local host = true
	if coop then
		host = AnyTypeRet(GML.variable_global_get("host")) > 0
	end

	for _, v in ipairs(tables) do
		rawset(v, "online", coop)
		rawset(v, "host", host)
		rawset(v, "localPlayer", nil)
	end
end
function RefreshNetAPILate(tables)
	local player = nil
	if online then
		player = GMInstance.iwrap(AnyTypeRet(GML.variable_global_get("my_player")))
	end
	for _, v in ipairs(tables) do
		rawset(v, "localPlayer", player)
	end
end


require("api/class/Packet")

-- Add to mod environment
mods.modenv.net = net
