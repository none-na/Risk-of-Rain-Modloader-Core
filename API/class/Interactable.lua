local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Interactable", true)
meta.__tostring = __tostring_default_namespace

local all_interactables = {vanilla = {}}
local interactable_origin = {}
local interactable_from_object = {}
local interactable_from_id = {}

Interactable = {}

local interactable_id_max = 19



lookup.spawnCost = {
	get = function(t)
		return AnyTypeRet(GML.array_global_read_2("chest_card", ids[t], 2))
	end,
	set = function(t, v)
		if typeOf(v) ~= "number" then fieldTypeError("Interactable.spawnCost", "number", v) end
		GML.array_global_write_2("chest_card", AnyTypeArg(v), ids[t], 2)
	end
}

function lookup:getObject()
	if not children[self] then methodCallError("Interactable:getObject", self) end
	return GMObject.fromID(AnyTypeRet(GML.array_global_read_2("chest_card", ids[self], 3)))
end




function lookup:getName()
	if not children[self] then methodCallError("Interactable:getName", self) end
	return AnyTypeRet(GML.array_global_read_2("chest_card", ids[self], 0))
end

function lookup:getOrigin()
	if not children[self] then methodCallError("Interactable:getOrigin", self) end
	return interactable_origin[self]
end


Interactable.find = contextSearch(all_interactables, "Interactable.find")
Interactable.findAll = contextFindAll(all_interactables, "Interactable.findAll")

function Interactable.fromObject(object)
	if typeOf(object) ~= "GMObject" then typeCheckError("Interactable.fromObject", 1, "object", "GMObject", object) end
	return interactable_from_object[object]
end

-- Create new
do
	local function new_interactable(fname, obj, name)
		if typeOf(obj) ~= "GMObject" then typeCheckError(fname, 1, "obj", "GMObject", obj) end
		if name ~= nil and type(name) ~= "string" then typeCheckError(fname, 2, "name", "string or nil", name) end
		if name == nil then name = "Interactable" .. obj:getName() end
		local context = GetModContext()

		contextVerify(all_interactables, name, context, "Interactable", 1)

		interactable_id_max = interactable_id_max + 1
		local n = static.new(interactable_id_max)

		interactable_origin[n] = context

		interactable_from_object[obj] = n
		interactable_from_id[interactable_id_max] = n

		GML.array_global_write_2("chest_card", AnyTypeArg(name), interactable_id_max, 0)
		GML.array_global_write_2("chest_card", AnyTypeArg(75), interactable_id_max, 2)
		GML.array_global_write_2("chest_card", AnyTypeArg(GMObject.toID(obj)), interactable_id_max, 3)

		contextInsert(all_interactables, name, context, n)

		return n
	end

	function Interactable.new(obj, name)
		return new_interactable("Interactable.new", obj, name)
	end
	setmetatable(Interactable, {__call = function(t, obj, name)
		return new_interactable("Interactable", obj, name)
	end})
end

-- Wrap existing
for i = 1, interactable_id_max do
	local n = static.new(i)

	interactable_from_object[n:getObject()] = n
	all_interactables.vanilla[n:getName():lower()] = n
	interactable_origin[n] = "Vanilla"
	interactable_from_id[i] = n

end

RoRInteractable = {
	ids = ids,
	toID = function(v)
		return ids[v]
	end,
	fromID = function(v)
		return interactable_from_id[v]
	end
}

-- env
mods.modenv.Interactable = Interactable
