local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Packet", false, nil)

-- fix error on client join
-- expose find_object

local all_packets = {}
local packet_origin = {}
local packet_name = {}
local packet_handler = {}

local function newPacket(fname, name, handler)
	if type(name) ~= "string" then typeCheckError(fname, 1, "name", "string", name, 1) end
	if type(handler) ~= "function" then typeCheckError(fname, 2, "handler", "function", handler, 1) end
	verifyCallback(bind, 1)
	local context = GetModContext()
	contextVerify(all_packets, name, context, "Packet", 1)
	local new = static.new(nid)
	contextInsert(all_packets, name, context, new)
	packet_origin[new] = context
	packet_name[new] = name
	packet_handler[new] = handler
	return new
end

local typeIDs = {"number", "string", "GMObject", "Sprite", "Sound", "Item", "true", "false", "nil"}
for k, v in ipairs(typeIDs) do
	typeIDs[v] = k
end

local encoders = {
	number = function(val) GML.writedouble(val) end,
	string = function(val) GML.writestring(val) end,
	GMObject = function(val) GML.writeobject(GMObject.ids[val]) end,
	Sprite = function(val) GML.writesprite(SpriteUtil.toID(val)) end,
	Sound = function(val) GML.writesound(SoundUtil.ids[val]) end,
	Item = function(val) GML.writeobject(RoRItem.toObjID(val)) end,
}

local decoders = {
	number = function() return GML.readdouble() end,
	string = function() return ffi.string(GML.readstring()) end,
	GMObject = function() return GMObject.ids_map[GML.readobject()] end,
	Sprite = function() return SpriteUtil.fromID(GML.readsprite()) end,
	Sound = function() return SoundUtil.ids_map[GML.readsound()] end,
	Item = function() return RoRItem.fromObjID(GML.readobject()) end,
	["true"] = function() return true end,
	["false"] = function() return false end,
	["nil"] = function() return nil end,
}

local function encodePacketData(packet, args)
	GML.writestring(packet_origin[packet])
	GML.writestring(packet_name[packet])
	-- THIS NEEDS TO CHANGE TO NOT DIE ON BROKEN TABLES
	GML.writeint(#args)
	for _, v in ipairs(args) do
		local t = typeOf(v)
		if encoders[t] == nil then
			error("unsupported value type " .. t, 3)
		else
			-- Special cases for single byte values
			if v == nil then
				GML.writebyte(typeIDs["nil"])
			elseif v == true then
				GML.writebyte(typeIDs["true"])
			elseif v == false then
				GML.writebyte(typeIDs["false"])
			else
				GML.writebyte(typeIDs[t])
				encoders[t](v)
			end
		end
	end
end

function CallbackHandlers.HandleUserPacket(args)
	local sender = GMInstance.iwrap(args[1])
	local modname = ffi.string(GML.readstring())
	local packetname = ffi.string(GML.readstring())
	local hargs = {sender}
	local argpos = 2
	-- ADD CODE TO CHECK FOR END OF PACKET
	local count = GML.readint()
	for i = 1, count do
		local t = typeIDs[GML.readbyte()]
		hargs[argpos] = decoders[t]()
		argpos = argpos + 1
	end

	CallModdedFunction(packet_handler[all_packets[modname][packetname]], hargs)
end

function lookup:sendAsClient(...)
	if not children[self] then methodCallError("Packet:sendAsClient", self) end
	local old_buff = GML.net_packet_begin()
	encodePacketData(self, {...})
	GML.net_packet_end(old_buff, 0, -4)
end

net.ALL = "all"
net.EXCLUDE = "exclude"
net.DIRECT = "direct"

local sendTypes = {
	all = 1,
	exclude = 2,
	direct = 3
}

function lookup:sendAsHost(target, player, ...)
	if not children[self] then methodCallError("Packet:sendAsHost", self) end
	if type(target) ~= "string" then typeCheckError("Packet:sendAsHost", 1, "target", "string", target, 1) end
	if target ~= "all" and typeOf(player) ~= "PlayerInstance" then typeCheckError("Packet:sendAsHost", 1, "player", "PlayerInstance", player, 1) end
	if sendTypes[target] == nil then error("unknown target '" .. target .. "'", 2) end
	local old_buff = GML.net_packet_begin()
	encodePacketData(self, {...})
	if target == "all" then
		player = -4
	else
		player = GMInstance.IDs[player]
	end
	
	GML.net_packet_end(old_buff, sendTypes[target], player)
end

net.Packet = setmetatable({new = function(name, handler)
	return newPacket("net.Packet.new", name, handler)
end}, {__call = function(t, name, handler)
	return newPacket("net.Packet", name, handler)
end})
