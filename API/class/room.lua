local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Room", true)
meta.__tostring = __tostring_default_namespace

local all_rooms = {vanilla = {}}

local room_name = {}
local room_origin = {}
local id_to_room = {}

------------------------------------------
-- CLASS METHODS -------------------------
------------------------------------------

function lookup:getName()
	if not children[self] then methodCallError("Room:getName", self) end
	return room_name[self]
end

function lookup:getOrigin()
	if not children[self] then methodCallError("Room:getOrigin", self) end
	return room_origin[self]
end

function lookup:createInstance(object, x, y)
	if not children[self] then methodCallError("Room:createInstance", self) end
	if typeOf(object) ~= "GMObject" then typeCheckError("Room:createInstance", 1, "object", "GMObject", object) end
	if type(x) ~= "number" then typeCheckError("Room:createInstance", 2, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("Room:createInstance", 3, "y", "number", y) end
	local id  = GML.room_instance_create(ids[self], x, y, GMObject.ids[object])
	if id == -4 then id = nil end
	return id
end

function lookup:resize(width, height)
	if not children[self] then methodCallError("Room:setSize", self) end
	if type(width) ~= "number" then typeCheckError("Room:setSize", 1, "width", "number", width) end
	if type(height) ~= "number" then typeCheckError("Room:setSize", 2, "height", "number", height) end
	GML.room_set_width(ids[self], width)
	GML.room_set_height(ids[self], height)
end

------------------------------------------
-- GLOBAL FUNCTIONS ----------------------
------------------------------------------
Room = {}
mods.modenv.Room = Room

-- Create new
do
	local base_room = GML.asset_get_index("rCustomMap")

	local function new_room(fname, name)
		if type(name) ~= "string" then typeCheckError(fname, 1, "name", "string", name, 1) end
		local context = GetModContext()

		contextVerify(all_rooms, name, context, "Room", 1)

		local nid = GML.room_duplicate(base_room)
		local new = static.new(nid)

		room_name[new] = name
		room_origin[new] = context
		id_to_room[nid] = new

		return new
	end

	function Room.new(name)
		return new_room("Room.new", name)
	end
	setmetatable(Room, {__call = function(t, name)
		return new_room("Room", name)
	end})
end

-- Wrap
do
	local t = all_rooms.vanilla
	local i = 0
	while GML.room_exists(i) > 0 do
		local new = static.new(i)
		room_origin[new] = "Vanilla"
		local name = ffi.string(GML.room_get_name(i))
		name = name:sub(2, name:len())
		room_name[new] = name
		i = i + 1
	end
end

Room.find = contextSearch(all_rooms, "Room.find")
Room.findAll = contextFindAll(all_rooms, "Room.findAll")

function Room.getCurrentRoom()
	return id_to_room[AnyTypeRet(GML.variable_global_get("room"))]
end

GMRoom = {
	fromID = function(v)
		return id_to_room[v]
	end,
	toID = function(v)
		return ids[v]
	end
}
