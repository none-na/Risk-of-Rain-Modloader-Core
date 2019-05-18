local GML = GML
local type = type
local typeOf = typeOf
-- Initialize table
net = {}

net.ALL = 1
net.EXCLUDE = 2
net.DIRECT = 3

net_online = false
net_host = false
function RefreshNetAPI(tables)
	local coop = AnyTypeRet(GML.variable_instance_get(GML_init_instance_id, "coop")) == 2
	net_online = coop

	local host = true
	net_host = host
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
	if net_online then
		player = GMInstance.iwrap(AnyTypeRet(GML.variable_global_get("my_player")))
	end
	for _, v in ipairs(tables) do
		rawset(v, "localPlayer", player)
	end
end


require("api/class/net/Packet")

-- Add to mod environment
mods.modenv.net = net
