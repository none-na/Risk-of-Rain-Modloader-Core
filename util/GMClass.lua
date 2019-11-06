
local AnyTypeRet = AnyTypeRet
local AnyTypeArg = AnyTypeArg
local GML = GML

local typeConv = {
	GMObject = GMObject,
	Sprite = SpriteUtil,
	boolean = {toID = function(v) return v and 1 or 0 end, fromID = function(v) return v > 0.5 end},
}
local fastCheckTypes = {
	number = true,
	boolean = true,
	string = true
}

return function(args)
	
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
		if type(v) == "table" then
			local fieldKind = v[1]
			if not fields[fieldKind] then error("unknown field kind for " .. tostring(k)) end
			v.k = k
			table.insert(fields[fieldKind], v)
		end
	end

	-- Array fields
	for _, v in ipairs(fields.f) do
		local id, ttype, default, mode = v[2], v[3], v[4], v[5]
		if type(id) ~= "number" then error("bad field id") end
		if type(ttype) ~= "string" then error("bad field type") end
		if default ~= nil and typeOf(default) ~= ttype then error("bad field default") end
		if mode ~= nil and type(mode) ~= "string" then error("bad field mode") end

		local f = {}

		local typeCheck = fastCheckTypes[ttype] and type or typeOf
		local fieldName = v.k
		local conv = typeConv[ttype]

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
					if typeCheck(value) ~= ttype then fieldTypeError(className .. '.' .. fieldName, ttype, value) end
					GML.array_global_write_2(arrayName, AnyTypeArg(conv.toID(value)), ids[self], id)
				end
			end
		else
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
					if typeCheck(value) ~= ttype then fieldTypeError(className .. '.' .. fieldName, ttype, value) end
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
					if typeCheck(value) ~= ttype then fieldTypeError(className .. '.' .. fieldName, ttype, value) end
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

		f.getter = getter
		f.setter = setter

		lookup[fieldName] = f
	end

	-- Lua methods
	for _, v in ipairs(fields.l) do
		local methodName = v.k
		local method = v[2]
		lookup[methodName] = function(self, ...)
			if not children[self] then methodCallError(className .. ":" .. methodName, self) end
			return method(self, ...)
		end
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

	lookup.id = {get = function(self) return ids[self] end}
	lookup.ID = lookup.id

	-- Out table
	--[[if type(args.out) == "table" then
		local out = args.out
		out.ids = ids or children
		out.lookup = lookup
		out.meta = meta
	end]]
	local new, find, findAll
	
	local classNew = static.new
	local allIds, idToObj
	if originIndex ~= nil then
		allIds, idToObj = {vanilla = {}}, setmetatable({}, {__mode = "v"})
		function find(name, namespace)
			if type(name) ~= "string" then typeCheckError(className .. ":find", 1, "name", "string", name) end
			if type(namespace) ~= "string" and namespace ~= nil then typeCheckError(className .. ":find", 1, "namespace", "string or nil", namespace) end
	
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
				local obj = classNew(id)
				idToObj[outID] = obj
				return obj
			end
		end
	end

	new = static.new
	return setmetatable({new = new, find = find, findAll = findAll}, new and {__call = function(self, ...) return self.new(...) end} or nil)
end

