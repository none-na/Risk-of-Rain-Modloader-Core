function typeCheckError(fname, argn, aname, expected, got, level)
	error(string.format("bad argument #%i ('%s') to '%s' (%s expected, got %s)", argn, aname, fname, expected, typeOf(got)), 3 + (level or 0))
end

function fieldTypeError(name, expected, got, level)
	error(string.format("incorrect type for '%s' (%s expected, got %s)", name, expected, typeOf(got)), 3 + (level or 0))
end

function methodCallError(name, got, level)
	error(string.format("attempt to call method '%s' on object of type %s (did you type a '.' in place of ':'?)", name, typeOf(got)), 3 + (level or 0))
end

function modOnlyError(name, level, level)
	error(string.format("unable to call method '%s' on a built-in object", name), 3 + (level or 0))
end

function verifyCallback(func, level)
	if getfenv(func) == _G and getfenv(3 + (level or 0)) ~= _G then
		error("trying to assign a built-in function to a callback", 3 + (level or 0))
	end
end

function verifyIngame(name, level)
	if not INGAME then
		error("attempting to call " .. tostring(name) .. " while not in-game ", 3 + (level or 0))
	end
end

function contextSearch(t, fname)
	return function(name, namespace)
		if type(name) ~= "string" then typeCheckError(fname, 1, "name", "string", name) end
		if type(namespace) ~= "string" and namespace ~= nil then typeCheckError(fname, 1, "namespace", "string or nil", namespace) end

		name = string.lower(name)
		if namespace == nil then
			-- No namespace specified, search all namespaces.
			for _, v in pairs(t) do
				if v[name] then
					return v[name]
				end
			end
		else
			namespace = string.lower(namespace)
			if t[namespace] then
				return t[namespace][name]
			else
				return nil
			end
		end
	end
end

function contextFindAll(t, fname)
	return function(namespace)
		if type(namespace) ~= "string" then typeCheckError(fname, 1, "namespace", "string", namespace) end

		namespace = string.lower(namespace)

		local new = {}

		if t[namespace] then
			local i = 0
			for _, v in pairs(t[namespace]) do
				i = i + 1
				new[i] = v
			end
		end

		return new
	end
end

function contextInsert(t, name, context, value)
	context = string.lower(context)
	if not t[context] then
		t[context] = {}
	end
	t[context][string.lower(name)] = value
end

function contextVerify(t, name, context, obj, level)
	context = string.lower(context)
	if not t[context] then
		return
	elseif t[context][string.lower(name)] then
		local f = string.lower(string.sub(obj, 1, 1))
		local a
		if f == "a" or f == "e" or f == "i" or f == "o" or f == "u" then
			a = "an"
		else
			a = "a"
		end
		error(string.format("%s %s of the name '%s' already exists in the namespace %s", a, obj, name, context), 3 + (level or 0))
	end
end

function contextCount(t, context)
	context = string.lower(context)
	if not t[context] then
		return 1
	else
		local count = 1
		for _, _ in pairs(t[context]) do
			count = count + 1
		end
		return count
	end
end

do
	local IDFormat = { -- GML enum
		object = 0,
		sprite = 1,
		map = 2,
		-- item = 3, -- These aren't used here
		-- monster = 4,
		-- class = 5,
		sound = 6
	}
	function registerNetID(type, id, origin, name)
		-- Adds the ID to the system for syncing in online coop
		GML.resource_register_id(IDFormat[type], id, origin, name)
	end
end

function getFilename(path)
	path = path:match( "([^/\\]+)$")
	local name = path:match("^(.+)%.")
	return name and name or path
end

do
	local modsWarned = {}
	local function deprecateWarning(kind, name, replacement)
		local context = GetModContext()
		local warns = modsWarned[context]
		if warns == nil then
			warns = {}
			modsWarned[context] = warns
		end
		if warns[name] == nil then
			GML.console_add_message("Warning: mod " .. context .. " using deprecated " .. kind .. " " .. name .. ". Switching to " .. replacement .. " may be required for compatibility with future versions.", 0x98EEE7, 0)
			warns[name] = true
		end
	end
	function deprecate(thing, kind, name, replacement)
		if type(thing) == "function" then
			return function(...) deprecateWarning(kind, name, replacement) return thing(...) end
		elseif type(thing) == "table" then
			for k, v in pairs(thing) do
				if type(v) == "function" then
					thing[k] = function(...) deprecateWarning(kind, name, replacement) return v(...) end
				end
			end
			return thing
		end
	end
end