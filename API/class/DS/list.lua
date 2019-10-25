local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("List<T>", true)

-- The value type a list uses
local list_type = setmetatable({}, {__mode = "k"})
-- Functions for converting the value to / from its lua version
local list_to_gml = setmetatable({}, {__mode = "k"})
local list_from_gml = setmetatable({}, {__mode = "k"})

local list_on_remove = setmetatable({}, {__mode = "k"})
local list_on_add = setmetatable({}, {__mode = "k"})

function meta:__typeof()
	return "List<" .. list_type[self] .. ">"
end

-- [] lookup
do
	function meta:__index(k)
		if type(k) == "number" then
			local id = ids[self]
			local len = GML.ds_list_size(id)
			k = math.floor(k)
			if k < 1 or k > len then
				return nil
			else
				local conv = list_from_gml[self]
				return conv(AnyTypeRet(GML.ds_list_find_value(id, k - 1)))
			end
		else
			local val = lookup[k]
			if val then
				return val
			else
				error("List<" .. list_type[self] .. "> does not contain a field '" .. tostring(k) .. "'", 2)
			end
		end
	end
	
	function meta:__newindex(k, v)
		error("unable to assign to List<" .. list_type[self] .. "> directly, use the 'add' and 'remove' methods instead", 2)
	end
end

-- Get length
-- cant use # becausse __len metamethod is not in 5.1, sad!
function lookup:len()
	if not children[self] then methodCallError("List<T>:len", self) end
	return GML.ds_list_size(ids[self])
end

-- Check for an object
function lookup:contains(value)
	if not children[self] then methodCallError("List<T>:contains", self) end
	if typeOf(value) ~= list_type[self] then typeCheckError("List<" .. list_type[self] .. ">:contains", 1, "value", list_type[self], value) end
	return GML.ds_list_find_index(ids[self], AnyTypeArg(list_to_gml[self](value))) >= 0
end

-- Add an object
function lookup:add(value)
	if not children[self] then methodCallError("List<T>:add", self) end
	if typeOf(value) ~= list_type[self] then typeCheckError("List<" .. list_type[self] .. ">:add", 1, "value", list_type[self], value) end
	local id = ids[self]
	local gmValue = list_to_gml[self](value)
	if GML.ds_list_find_index(id, AnyTypeArg(gmValue)) < 0 then
		if list_on_add[self] ~= nil then
			list_on_add[self](self, value)
		end
		GML.ds_list_add(id, AnyTypeArg(gmValue))
		return true
	else
		return false
	end
end

-- Remove an object
function lookup:remove(value)
	if not children[self] then methodCallError("List<T>:remove", self) end
	if typeOf(value) ~= list_type[self] then typeCheckError("List<" .. list_type[self] .. ">:remove", 1, "value", list_type[self], value) end
	local id = ids[self]
	local gmValue = list_to_gml[self](value)
	local index = GML.ds_list_find_index(id, AnyTypeArg(gmValue))
	if index >= 0 then
		if list_on_remove[self] ~= nil then
			list_on_remove[self](self, value)
		end
		GML.ds_list_delete(id, index)
		return true
	else
		return false
	end
end

-- Tostring
meta.__tostring = function(t)
	local str = "List<" .. list_type[t] .. ">{"

	local id = ids[t]
	local conv = list_from_gml[t]
	local len = GML.ds_list_size(id)
	
	if len > 0 then
		str = str .. "\n"
		for i = 0, len - 1 do
			str = str .. "  " .. tostring(conv(AnyTypeRet(GML.ds_list_find_value(id, i))))
			if i ~= len - 1 then
				str = str .. ","
			end
			str = str .. "\n"
		end
	end

	str = str .. "}"
	return str
end

-- Convert to table
function lookup:toTable()
	if not children[self] then methodCallError("List<T>:toTable", self) end

	local ret = {}

	local id = ids[self]
	local conv = list_from_gml[self]
	local len = GML.ds_list_size(id)
	
	for i = 0, len - 1 do
		ret[#ret + 1] = conv(AnyTypeRet(GML.ds_list_find_value(id, i)))
	end

	return ret
end


-- Constructor
function dsWrapper.list(id, type, to, from, onAdd, onRemove)
	local n = static.new(id)
	if to and not from then
		from = to.fromID
		to = to.toID
	end
	list_type[n] = type
	list_to_gml[n] = to or dsWrapper.dummy
	list_from_gml[n] = from or dsWrapper.dummy
	list_on_add[n] = onAdd
	list_on_remove[n] = onRemove
	return n
end
