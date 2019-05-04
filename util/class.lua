local classData = setmetatable({}, {__mode = "k"})
local instanceOf = setmetatable({}, {__mode = "k"})
local childrenOf = setmetatable({}, {__mode = "k"})
local nameToClass = setmetatable({}, {__mode = "v"})

function NewClass(name, useIDs, inherit)
	local static, meta, lookup, ids, special
	local myChildren = setmetatable({}, {__mode = "k"})
	
	static = {}
	special = {}
	
	if useIDs then
		ids = {}
	end
	
	-- Create table for field lookup 
	if inherit then
		lookup = setmetatable({}, {__index = classData[inherit].lookup})
	else
		lookup = {}
	end
	
	meta = {
		__index = function(t, k)
			local val = lookup[k]
			if val then
				if type(val) == "function" then
					return val
				elseif val.get then
					return val.get(t)
				end
			end
			error(string.format("%s does not contain a field '%s'", name, tostring(k)), 2)
		end,
		
		__newindex = function(t, k, v)
			local val = lookup[k]
			if type(val) == "table" and val.set then
				 val.set(t, v)
			else
				error(string.format("%s does not contain a field '%s'", name, tostring(k)), 2)
			end
		end,
		
		__tostring = function(t)
			return name
		end
	}
	
	local initFunction, inheritedData
	if inherit then
		inheritedData = classData[inherit]
		initFunction = function(t, id, ...)
			inheritedData.initFunction(t, id, ...)
			myChildren[t] = true
			if useIDs then
				ids[t] = id
			end
			if meta.__init then
				meta.__init(t, id, ...)
			end
		end
	else
		initFunction = function(t, id, ...)
			myChildren[t] = true
			if useIDs then
				ids[t] = id
			end
			if meta.__init then
				meta.__init(t, id, ...)
			end 
		end
	end
	
	classData[static] = {meta = meta, lookup = lookup, special = special, name = name, initFunction = initFunction, children = myChildren, static = static, ids = ids}
	nameToClass[name] = classData[static]
	childrenOf[name] = myChildren
	
	function static.new(id, ...)
		if useIDs and id then
			id = math.floor(id)
		end
		local new = setmetatable({}, meta)
		
		initFunction(new, id, ...)
		
		instanceOf[new] = static
		
		return new
	end
	
	
	return static, lookup, meta, ids, special, myChildren
end

function getClass(name)
	return nameToClass[name]
end

function typeOf(v)
	if instanceOf[v] then
		return classData[instanceOf[v]].name
	else
		return type(v)
	end
end

__tostring_default_namespace = function(obj)
	return "<" .. typeOf(obj) .. ":".. obj:getOrigin() .. ":" .. obj:getName() .. ">"
end

function isA(inst, obj)
	return (childrenOf[obj][inst] ~= nil)
end

local function simpleTypeError(name, n, ex, val)
	error(string.format("bad argument #%d to '%s' (%s expected, got %s)", n, name, ex, typeOf(val)), 3)
end

mods.modenv.type = typeOf

mods.modenv.rawget = function(t, k)
	if typeOf(t) ~= "table" then simpleTypeError("rawget", 1, "table", t) end
	return rawget(t, k)
end

mods.modenv.rawset = function(t, k, v)
	if typeOf(t) ~= "table" then simpleTypeError("rawset", 1, "table", t) end
	if k == nil then error("table index is nil", 2) end
	return rawset(t, k, v)
end

mods.modenv.getmetatable = function(t)
	if typeOf(t) ~= "table" then simpleTypeError("getmetatable", 1, "table", t) end
	return getmetatable(t)
end

mods.modenv.setmetatable = function(t, mt)
	if typeOf(t) ~= "table" then simpleTypeError("setmetatable", 1, "table", t) end
	if typeOf(mt) ~= "table" then simpleTypeError("setmetatable", 2, "table", mt) end
	return setmetatable(t, mt)
end

function mods.modenv.isa(obj, t)
	if type(t) ~= "string" then simpleTypeError("isa", 2, "string", t) end
	local typ = typeOf(obj)
	if childrenOf[t] ~= nil then
		if obj == nil then
			return false
		else
			return childrenOf[t][obj] ~= nil
		end
	else
		return typ == t
	end
end
