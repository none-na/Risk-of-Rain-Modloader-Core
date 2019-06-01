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

local typeIDs = {"number", "string", "GMObject", "Sprite", "Sound", "Item", "NetInstance", "true", "false", "nil"}
for k, v in ipairs(typeIDs) do
	typeIDs[v] = k
end

-- 3 is buffer_u16
local encoders = {
	number = function(val) GML.writedouble(val) end,
	string = function(val) GML.writestring(val) end,
	GMObject = function(val) GML.writeobject(3, GMObject.ids[val]) end,
	Sprite = function(val) GML.writesprite(3, SpriteUtil.toID(val)) end,
	Sound = function(val) GML.writesound(3, SoundUtil.ids[val]) end,
	Item = function(val) GML.writeobject(3, RoRItem.toObjID(val)) end,
	NetInstance = function(val) GML.writeobject(3, GMObject.ids[val.object]) GML.writedouble(val.id) end,
}

local writeRaw = {
	["boolean"] = true,
	["nil"] = true
}

local decoders = {
	number = function() return GML.readdouble() end,
	string = function() return ffi.string(GML.readstring()) end,
	GMObject = function() return GMObject.ids_map[GML.readobject(3)] end,
	Sprite = function() return SpriteUtil.fromID(GML.readsprite(3)) end,
	Sound = function() return SoundUtil.ids_map[GML.readsound(3)] end,
	Item = function() return RoRItem.fromObjID(GML.readobject(3)) end,
	NetInstance = function() 
		local obj = GMObject.ids_map[GML.readobject(3)]
		local id = GML.readdouble()
		return GMInstance.getNetIdentity(id, obj)
	end,
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
		if encoders[t] == nil and not writeRaw[t] then
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
	-- ADD CODE TO CHECK FOR END OF PACKET
	local count = GML.readint()
	for i = 1, count do
		local t = typeIDs[GML.readbyte()]
		hargs[i] = decoders[t]()
	end
	CallModdedFunction(packet_handler[all_packets[modname:lower()][packetname:lower()]], hargs)
end

function lookup:sendAsClient(...)
	if not children[self] then methodCallError("Packet:sendAsClient", self) end
	if net_online and not net_host then
		local old_buff = GML.net_packet_begin()
		encodePacketData(self, {...})
		GML.net_packet_end(old_buff, 0, -4)
	end
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
	if net_online and net_host then
		local old_buff = GML.net_packet_begin()
		encodePacketData(self, {...})
		if target == "all" then
			player = -4
		else
			player = GMInstance.IDs[player]
		end
		GML.net_packet_end(old_buff, sendTypes[target], player)
	end
end

net.Packet = setmetatable({new = function(name, handler)
	return newPacket("net.Packet.new", name, handler)
end}, {__call = function(t, name, handler)
	return newPacket("net.Packet", name, handler)
end})
