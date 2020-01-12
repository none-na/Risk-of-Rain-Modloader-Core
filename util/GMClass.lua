
local AnyTypeRet = AnyTypeRet
local AnyTypeArg = AnyTypeArg
local GML = GML

local floor = math.floor

local typeConv = {
	GMObject = GMObject,
	Sprite = SpriteUtil,
	Sound = {toID = function(v) return SoundUtil.ids[v] end, fromID = function(v) return SoundUtil.ids_map[v] end},
	boolean = {toID = function(v) return v and 1 or 0 end, fromID = function(v) return v > 0.5 end},
	Color = {toID = GetColorValue, fromID = ConstructColorObject},
}
local fastCheckTypes = {
	number = true,
	boolean = true,
	string = true
}

local sharedMT = {__call = function(self, ...) return self.new(...) end}

local gmClassIDs = setmetatable({}, {__mode = "k"})
local gmClassArrays = setmetatable({}, {__mode = "k"})

local function typeCheck(classChildren, name, func, args)
	local st = "local t = typeOf return function(f,c)return function("
	if classChildren ~= nil then st = st .. "s" end
	for i = 1, #args do
		if i > 1 or classChildren ~= nil then st = st .. "," end
		st = st .. "a" .. tostring(i)
	end
	st = st .. ")"
	if classChildren ~= nil then
		st = st .. "if c[s]==nil then methodCallError('" .. name .. "',s)end "
	end
	for k, v in ipairs(args) do
		local needed = v
		local argname = nil
		if type(v) ~= "string" then argname = v[1] needed = v[2] end
		st = st .. "if t(a" .. tostring(k) .. ")~='" .. needed .. "'then typeCheckError('" .. name .. "',"..tostring(k)..",'" .. (argname or "argument " .. tostring(k)) .. "','" .. needed .. "',a" .. tostring(k) .. ")end "
	end
	st = st .. "return f("
	if classChildren ~= nil then st = st .. "s" end
	for i = 1, #args do
		if i > 1 or classChildren ~= nil then st = st .. "," end
		st = st .. "a" .. tostring(i)
	end	
	st = st .. ") end end"
	return loadstring(st)()(func, classChildren)
end

local func = function(args)
	
	------------------------------------------
	------------------------------------------
	-- Basic class properties

	-- Class type
	local className = args[1]
	if type(className) ~= "string" then error("bad class name") end

	-- Class type
	local kind = args[2]
	if type(kind) ~= "string" then error("bad gm class type") end

	-- Origin / name fields
	local originIndex, nameIndex = args.originIndex, args.nameIndex
	if type(originIndex) ~= type(nameIndex) or (originIndex ~= nil and type(originIndex) ~= "number") then error("bad origin or name index") end

	-- Class ctor
	local allocator = args.allocator
	local allocatorTypes
	if type(allocator) == "table" then
		allocatorTypes = allocator[2]
		if allocatorTypes ~= nil and type(allocatorTypes) ~= "table" then error("bad allocator types") end
		allocator = allocator[1]
	end
	if allocator ~= nil and type(allocator) ~= "function" then error("bad allocator") end

	-- ID Field / fromID
	local idField = args.idField ~= false

	-- Net type id
	local netRegisterIndex = args.netRegisterIndex
	if netRegisterIndex ~= nil and type(netRegisterIndex) ~= "number" then error("bad net register index") end

	local arrayName
	if kind == "ArrayClass" then
		-- Global 2D array like buff and item info
		arrayName = args.arrayName
		if type(arrayName) ~= "string" then error("bad array name") end
	else
		error("invalid gm class type")
	end

	------------------------------------------
	------------------------------------------
	-- Constuct class base

	local static, lookup, meta, ids, special, children = NewClass(className, true)

	-- Use namespace tostring if the class stores origin and name info
	if originIndex ~= nil then
		meta.__tostring = __tostring_default_namespace
	end

	-- Automatically add IDs to table
	function meta:__init(id)
		gmClassIDs[self] = id
		gmClassArrays[self] = arrayName
	end

	------------------------------------------
	------------------------------------------
	-- Populate fields

	local fields = {
		f = {}, -- Array field
		g = {}, -- GML method
		l = {}, -- Lua method
		a = {}, -- Aliases 
		gf = {}, -- GML getter / setter fields
		lf = {}, -- Lua getter / setter fields
	}

	-- Collect all fields by type
	for k, v in pairs(args) do
		if type(v) == "table" and k ~= "allocator" then
			local fieldKind = v[1]
			if not fields[fieldKind] then error("unknown field kind for " .. tostring(k)) end
			v.k = k
			table.insert(fields[fieldKind], v)
		end
	end

	-- Array fields
	for _, v in ipairs(fields.f) do
		local id, ttype, mode = v[2], v[3], v[4]
		if type(id) ~= "number" then error("bad field id") end
		if type(ttype) ~= "string" then error("bad field type") end
		if mode ~= nil and type(mode) ~= "string" then error("bad field mode") end

		local f = {}

		local typeCheck = fastCheckTypes[ttype] and type or typeOf
		local fieldName = v.k
		local conv = typeConv[ttype]

		local not_nillable = mode == nil or (not (mode:find("n") and true or false))
		if conv ~= nil then 
			-- Getter
			if mode == nil or mode:find("r") then
				function f.get(self)
					return conv.fromID(AnyTypeRet(GML.array_global_read_2(arrayName, ids[self], id)))
				end
			end
			-- Setter
			if mode == nil or mode:find("w") then
				function f.set(self, value)
					if typeCheck(value) ~= ttype and (not_nillable or value ~= nil) then fieldTypeError(className .. '.' .. fieldName, ttype, value) end
					GML.array_global_write_2(arrayName, AnyTypeArg(value == nil and -4 or conv.toID(value)), ids[self], id)
				end
			end
		else
			if not not_nillable then error("nillable field not supported for convless gml fields (" .. fieldName .. ")") end
			-- Getter
			if mode == nil or mode:find("r") then
				function f.get(self)
					return AnyTypeRet(GML.array_global_read_2(arrayName, ids[self], id))
				end
			end
			-- Setter
			if mode == nil or mode:find("w") then
				function f.set(self, value)
					if typeCheck(value) ~= ttype then fieldTypeError(className .. '.' .. fieldName, ttype, value) end
					GML.array_global_write_2(arrayName, AnyTypeArg(value), ids[self], id)
				end
			end
		end
		lookup[fieldName] = f
	end

	-- GML getter fields
	for _, v in ipairs(fields.gf) do
		local ttype, getter, setter, mode = v[2], v[3], v[4], v[5]
		if type(ttype) ~= "string" then error("bad field type") end
		if type(getter) ~= "cdata" then error("bad field getter") end
		if type(setter) ~= "cdata" then error("bad field setter") end
		if mode ~= nil and type(mode) ~= "string" then error("bad field mode") end

		local f = {}

		local typeCheck = fastCheckTypes[ttype] and type or typeOf
		local fieldName = v.k
		local conv = typeConv[ttype]

		local not_nillable = mode == nil or (not (mode:find("n") and true or false))
		if conv ~= nil then 
			-- Getter
			if mode == nil or mode:find("r") then
				function f.get(self)
					return conv.fromID(getter(ids[self]))
				end
			end
			-- Setter
			if mode == nil or mode:find("w") then
				function f.set(self, value)
					if typeCheck(value) ~= ttype and (not_nillable or value ~= nil) then fieldTypeError(className .. '.' .. fieldName, ttype, value) end
					setter(ids[self], conv.toID(value))
				end
			end
		else
			-- Getter
			if mode == nil or mode:find("r") then
				function f.get(self)
					return getter(ids[self])
				end
			end
			-- Setter
			if mode == nil or mode:find("w") then
				function f.set(self, value)
					if typeCheck(value) ~= ttype and (not_nillable or value ~= nil) then fieldTypeError(className .. '.' .. fieldName, ttype, value) end
					setter(ids[self], value)
				end
			end
		end

		lookup[fieldName] = f
	end

	-- Lua getter fields
	for _, v in ipairs(fields.lf) do
		local getter, setter = v[2], v[3]
		if getter ~= nil and type(getter) ~= "function" then error("bad field getter") end
		if setter ~= nil and type(setter) ~= "function" then error("bad field setter") end

		local f = {}

		local fieldName = v.k

		f.get = getter
		f.set = setter

		lookup[fieldName] = f
	end

	-- Lua methods
	for _, v in ipairs(fields.l) do
		local methodName = v.k
		local method = v[2]
		lookup[methodName] = typeCheck(children, methodName, method, v[3] or {})
	end

	-- Aliases
	for _, v in ipairs(fields.a) do
		lookup[v.k] = lookup[v[2]]
	end

	-- Common methods
	if originIndex ~= nil then
		function lookup:getOrigin()
			if not children[self] then methodCallError(className .. ":getOrigin", self) end
			return AnyTypeRet(GML.array_global_read_2(arrayName, ids[self], originIndex))
		end
	end
	if nameIndex ~= nil then
		function lookup:getName()
			if not children[self] then methodCallError(className .. ":getName", self) end
			return AnyTypeRet(GML.array_global_read_2(arrayName, ids[self], nameIndex))
		end
	end
	-- Out table
	--[[if type(args.out) == "table" then
		local out = args.out
		out.ids = ids or children
		out.lookup = lookup
		out.meta = meta
	end]]
	local new, find, findAll, fromID

	local classNew = static.new
	local idMin, idMax = 0, 0
	local allIds, idToObj
	local new
	
	if idField then
		function fromID(id)
			if type(id) ~= "number" then typeCheckError(className .. ".fromID", 1, "id", "number", id) end
			return new(id)
		end

		lookup.id = {get = function(self) return ids[self] end}
		lookup.ID = lookup.id
	end

	if originIndex ~= nil then
		allIds, idToObj = {vanilla = {}}, setmetatable({}, {__mode = "v"})
		
		function new(id, ...)
			id = floor(id)
			if id > idMax or id < idMin then return nil end
			if not idToObj[id] then
				idToObj[id] = classNew(id, ...)
			end
			return idToObj[id]
		end

		function find(name, namespace)
			if type(name) ~= "string" then typeCheckError(className .. ":find", 1, "name", "string", name) end
			if type(namespace) ~= "string" and namespace ~= nil then typeCheckError(className .. ":find", 2, "namespace", "string or nil", namespace) end
	
			name = name:lower()
			local outID = nil
			if namespace == nil then
				-- No namespace specified, search all namespaces.
				if allIds.vanilla[name] then
					outID = allIds.vanilla[name]
				else
					for _, v in pairs(allIds) do
						if v[name] then
							outID = v[name]
							break
						end
					end
				end
			else
				namespace = namespace:lower()
				if allIds[namespace] then
					outID = allIds[namespace][name]
				end
			end

			if outID == nil then
				return nil
			else
				return new(outID)
			end
		end

		function findAll(namespace)
			if type(namespace) ~= "string" and namespace ~= nil then typeCheckError(className .. ":find", 1, "namespace", "string or nil", namespace) end
	
			local out = {}
			if namespace == nil then
				-- No namespace specified, get everything ever
				for _, v in pairs(allIds) do
					for _, id in pairs(v) do
						out[#out + 1] = new(id)
					end
				end
			else
				namespace = namespace:lower()
				if allIds[namespace] then
					for _, id in pairs(allIds[namespace]) do
						out[#out + 1] = new(id)
					end
				end
			end

			return out
		end

		if arrayName ~= nil and nameIndex ~= nil then
			GML.array_open(arrayName)
			-- Vanilla is ASSUMED for all built ins
			local t = allIds.vanilla
			idMax = GML.array_length() - 1
			for i = 0, idMax do
				local name = AnyTypeRet(GML.array_read_2(i, nameIndex))
				t[name:lower()] = i
			end
			GML.array_close()
		end
	else
		new = static.new
	end

	local ctor

	if nameIndex ~= nil and allocator ~= nil then
		if allocatorTypes ~= nil then
			table.insert(allocatorTypes, 1, {"name", "string"})
			ctor = typeCheck(nil, className .. ".new", function(name, ...)
				local context = GetModContext()
				contextVerify(allIds, name, context, className, 1)
				local id = allocator(context, name, ...)
				if id > idMax then idMax = id end
				contextInsert(allIds, name, context, id)
				return new(id)
			end, allocatorTypes)
		else
			function ctor(name, ...)
				if type(name) ~= "string" then typeCheckError(className .. ".new", 1, "name", "string", name) end
				local context = GetModContext()
				contextVerify(allIds, name, context, className)
				local id = allocator(context, name, ...)
				if id > idMax then idMax = id end
				contextInsert(allIds, name, context, id)
				return new(id)
			end
		end
	end

	return setmetatable({new = ctor, find = find, findAll = findAll, fromID = fromID}, sharedMT), new, ids
end

local function get(obj, index)
	return AnyTypeRet(GML.array_global_read_2(gmClassArrays[obj], gmClassIDs[obj], index))
end

local function set(obj, index, value)
	return AnyTypeRet(GML.array_global_write_2(gmClassArrays[obj], AnyTypeArg(value), gmClassIDs[obj], index))
end

return setmetatable({class = func, ids = gmClassIDs, get = get, set = set}, {__call = function(self, ...) return self.class(...) end})