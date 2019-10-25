local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Map<T,T>", true)

-- The key type
local map_key_type = setmetatable({}, {__mode = "k"})
local map_key_to_gml = setmetatable({}, {__mode = "k"})
local map_key_from_gml = setmetatable({}, {__mode = "k"})
-- The value type
local map_value_type = setmetatable({}, {__mode = "k"})
local map_value_to_gml = setmetatable({}, {__mode = "k"})
local map_value_from_gml = setmetatable({}, {__mode = "k"})

function meta:__typeof()
	return "Map<" .. map_key_type[self] .. "," .. map_value_type[self] .. ">"
end
local strMap = meta.__typeof

local function getKeys(self)
	GML.ds_map_get_keys(ids[self])
	local valuesStr, valuesNum = PopStrings(), PopNumbers()

	if #valuesStr ~= 0 then
		return valuesStr
	else
		return valuesNum
	end
end


-- [] lookup
do
	function meta:__index(k)
		if lookup[k] then
			return lookup[k]
		else
			if typeOf(k) ~= map_key_type[self] then error("incorrect key type for " .. strMap(self) .. " (got " .. typeOf(k) .. ")", 2) end
			local val = AnyTypeRet(GML.ds_map_find_value(ids[self], AnyTypeArg(map_key_to_gml[self](k))))
			if val ~= nil then
				return map_value_from_gml[self](val)
			else
				return nil
			end
		end
	end
	
	function meta:__newindex(k, v)
		if lookup[k] then
			print("trying to override " .. strMap(self) .. " class method", 2)
		else
			if typeOf(k) ~= map_key_type[self] then error("incorrect key type for " .. strMap(self) .. " (got " .. typeOf(k) .. ")", 1) end
			if v ~= nil and typeOf(v) ~= map_value_type[self] then error("incorrect value type for " .. strMap(self) .. " (got " .. typeOf(v) .. ")", 2) end
			
			k = AnyTypeArg(map_key_to_gml[self](k))
			if v ~= nil then
				GML.ds_map_replace(ids[self], k, AnyTypeArg(map_value_to_gml[self](v)))
			else
				GML.ds_map_delete(ids[self], k)
			end
		end
	end
end

-- Tostring
meta.__tostring = function(t)
	local str = strMap(t) .. "{"

	local id = ids[t]
	local convKey = map_key_from_gml[t]
	local convValue = map_value_from_gml[t]

	local keys = getKeys(t)

	if #keys ~= 0 then
		str = str .. "\n"
	end
	for k, v in ipairs(keys) do
		local key = convKey(v)
		local value = convValue(AnyTypeRet(GML.ds_map_find_value(id, AnyTypeArg(v))))
		str = str .. "  " .. tostring(key) .. " = " .. tostring(value)
		if k < #keys then
			str = str .. ","
		end
		str = str .. "\n"
	end

	str = str .. "}"
	return str
end

-- Convert to table
function lookup:toTable()
	if not children[self] then methodCallError("Map<T,T>:toTable", self) end

	local ret = {}

	local id = ids[self]
	local convKey = map_key_from_gml[self]
	local convValue = map_value_from_gml[self]

	local keys = getKeys(self)

	for k, v in ipairs(keys) do
		local key = convKey(v)
		local value = convValue(AnyTypeRet(GML.ds_map_find_value(id, AnyTypeArg(v))))
		ret[key] = value
	end

	return ret
end


-- Constructor
function dsWrapper.map(id, typeKey, toKey, fromKey, typeValue, toValue, fromValue)
	local n = static.new(id)
	
	if toKey and not fromKey then
		fromKey = toKey.fromID
		toKey = toKey.toID
	end
	map_key_type[n] = typeKey
	map_key_to_gml[n] = toKey or dsWrapper.dummy
	map_key_from_gml[n] = fromKey or dsWrapper.dummy

	if toValue and not fromValue then
		fromValue = toValue.fromID
		toValue = toValue.toID
	end
	map_value_type[n] = typeValue
	map_value_to_gml[n] = toValue or dsWrapper.dummy
	map_value_from_gml[n] = fromValue or dsWrapper.dummy

	return n
end
