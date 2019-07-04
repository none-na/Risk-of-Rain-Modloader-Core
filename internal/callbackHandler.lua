
callback = {}
mods.modenv.callback = callback

local callbacks = {}
local callbackslookup = {}
local callbackdata = {}

local defaultcallbackdata = {
	cancellable = false,
	noGML = true,
	types = {},
}

local function FireCallbackInternal(name, dat, args)
	local cancellable = dat.cancellable
	local returnType = dat.returnType

	for _, v in ipairs(callbacks[name]) do
		local v = CallModdedFunction(v.func, args)
		if returnType then
			if typeOf(v) == returnType then
				return dat.returnFunc and dat.returnFunc(v) or v
			else
				-- error handling here? ? ?? ?? ?? ??
			end
		elseif cancellable and v then
			return 1
		end
	end

	return nil
end

function FireCallback(args)
	local name = args[1]
	if not callbacks[name] then return end
	local dat = callbackdata[name] or defaultcallbackdata
	table.remove(args, 1)

	local types = dat.types
	if types then
		for i = 1, #args do
			if types[i] and args[i] then
				args[i] = types[i](args[i])
			end
		end
	end

	return FireCallbackInternal(name, dat, args)
end
CallbackHandlers.FireCallback = FireCallback

function callback.register(name, func, priority)
	verifyCallback(func)
	priority = priority or 10

	modFunctionSources[func] = GetModContext()

	if not callbacks[name] then
		callbacks[name] = {}
		callbackslookup[name] = {}
		if callbackdata[name] and not callbackdata[name].noGML then
			GML.hook_set_active(name, 1)
		end
	end

	if not callbackslookup[name][func] then
		local t = {}
		callbackslookup[name][func] = t

		t.func = func
		t.name = name
		t.priority = priority

		local list = callbacks[name]
		local inserted = false
		for i = 1, #list do
			local t2 = list[i]
			if t2.priority < t.priority then
				table.insert(list, i, t)
				inserted = true
				break
			end
		end

		if not inserted then
			table.insert(callbacks[name], t)
		end
	end
end
-- Shortcut
setmetatable(callback, {__call = function(_, ...) return callback.register(...) end})


function AddCallback(name, descriptor)
	if not descriptor then descriptor = {} end
	if not descriptor.types then descriptor.types = {} end
	callbackdata[name] = descriptor
end

local function FireModCallback(name, ...)
	local context = currentModContext
	for _, v in ipairs(callbacks[name]) do
		currentModContext = modFunctionSources[func] or "ModLoaderCore"
		v.func(...)
	end
	currentModContext = context
end

function callback.create(name)
	if type(name) ~= "string" then typeCheckError("callback.create", 1, "name", "string", name) end
	if callbackdata[name] then
		error("callback '" .. name .. "' already exists (duplicate callback in " .. GetModContext() .. ", original in " .. (callbackdata[name].origin or "ModLoaderCore") .. ")", 2)
	end
	AddCallback(name)
	callbacks[name] = {}
	callbackslookup[name] = {}
	callbackdata[name].origin = GetModContext()
	return function(...)
		FireModCallback(name, ...)
	end
end

-- Legacy compat
mods.modenv.registercallback = callback.register
mods.modenv.createcallback = callback.create