local GML = GML
local type = type

local code_dir = "resources/modloadercore/"
local lib_dir = "resources/libs/"
package.path = string.format("?;?.lua;%s?.lua;%s?;%s?.lua;%s?;%s?/main.lua;%s?/?.lua", code_dir, code_dir, lib_dir, lib_dir, lib_dir, lib_dir)
package.cpath = string.format("%s?.dll", lib_dir)

require "util/utils"

local public = {}
local modenv = {
	["_VERSION"] = _VERSION,
	["assert"] = assert,
	["collectgarbage"] = collectgarbage,
	["coroutine"] = coroutine,
	["dump"] = dump,
	["error"] = error,
	["gcinfo"] = gcinfo,
	["ipairs"] = ipairs,
	["load"] = load,
	["math"] = math,
	["newproxy"] = newproxy,
	["next"] = next,
	["pairs"] = pairs,
	["pcall"] = pcall,
	["print"] = print,
	["rawequal"] = rawequal,
	["select"] = select,
	["string"] = string,
	["table"] = table,
	["tonumber"] = tonumber,
	["tostring"] = tostring,
	["type"] = type,
	["unpack"] = unpack,
	["xpcall"] = xpcall,
}
local aliases = {}

local ALLOW_C_MODULES = false

local mods = {}
local modlist = {}
local modexports = {}

local mod_signature_base = 32
local mod_signature_upper = 32
local mod_singature_end = 126
local signature_to_mod = {}

local playerLists = {}
local miscTables = {}
local netTables = {}

do
	local function formatErrorLine(v)
		while true do
			-- Find next mod reference
			local first, last = v:find('%[string ".-_.-"%]')
			if first ~= nil then
				local r = v:sub(first, last)
				-- Get the mod and file name from the string
				local mod = signature_to_mod[r:sub(10, 11)]
				local file = r:sub(14, -3)
				-- Replace it with the new string
				v = v:gsub('%[string ".-_.-"%]', mod.internalname .. ":" .. file, 1)
			else
				-- Exit loop when no more remaining
				break
			end
		end
		return v
	end

	local function handleModError(a)
		local stack = ""
		local cutLine = false

		for v in string.gmatch(debug.traceback():gsub("\t", ""), "([^\n]+)") do
			if not cutLine and string.find(v, ".+modhandler.lua:.-:.+") then
				cutLine = true
			elseif string.find(v, ".+'CallModdedFunction'") then
				break
			elseif v:sub(1, 10) ~= "resources/" and v:sub(1, 12) ~= ".\\resources/" and  v:sub(1, 3) ~= "[C]" then
				if v ~= "stack traceback:" then
					v = formatErrorLine(v:gsub(": in function '__modCallFunction'", "", 1))
				end
				stack = stack .. "\n    " .. v
			end
		end

		GML.error_error(formatErrorLine(a) .. stack, 0)
	end

	local modCallArgs
	local __modCallFunction

	local function CallModdedFunctionInternal()
		if modCallArgs then
			if #modCallArgs == 1 then
				return __modCallFunction(modCallArgs[1])
			elseif #modCallArgs == 2 then
				return __modCallFunction(modCallArgs[1], modCallArgs[2])
			elseif #modCallArgs == 3 then
				return __modCallFunction(modCallArgs[1], modCallArgs[2], modCallArgs[3])
			elseif #modCallArgs == 4 then
				return __modCallFunction(modCallArgs[1], modCallArgs[2], modCallArgs[3], modCallArgs[4])
			else
				return __modCallFunction(table.unpack(modCallArgs))
			end
		else
			return __modCallFunction()
		end
	end

	local resetGraphics
	table.insert(CallWhenLoaded, function() resetGraphics = CallbackResetGraphics end)

	function CallModdedFunction(func, args)
		currentModContext = modFunctionSources[func] or "ModLoaderCore"
		__modCallFunction = func
		-- Pass args as table, they need to be unpacked anyways
		modCallArgs = args
		local success, result = xpcall(CallModdedFunctionInternal, handleModError)
		resetGraphics()
		return result
	end
end

local function getBottomModData()
	local i = 1
	while true do
		local info = debug.getinfo(i, "S")
		if not info then break end
		local source = info.source

		local t = signature_to_mod[source:sub(1, 2)]
		if t then return t end

		i = i + 1
	end

	return nil
end

local function getTopModData()
	local i, mod = 1
	while true do
		local info = debug.getinfo(i, "S")
		if not info then break end
		local source = info.source

		local t = signature_to_mod[source:sub(1, 2)]
		if t then mod = t end

		i = i + 1
	end

	return mod
end

local function simpleTypeError(name, n, ex, val)
	error(string.format("bad argument #%d to '%s' (%s expected, got %s)", n, name, ex, typeOf(val)), 3)
end

modenv.require = function(s)
	if type(s) ~= "string" then simpleTypeError("require", 1, "string", s) end
	
	local info = debug.getinfo(2, "S")
	local source = info.source

	local t = signature_to_mod[source:sub(1, 2)]
	if not t then error("cross mod require unsupported", 2) end

	if t.loaded[s] then return table.unpack(t.loaded[s]) end

	local lua_path = package.searchpath(s, t.ppath)
	if lua_path then
		local f = io.open(lua_path, "r")
		local code = f:read("*all")
		f:close()

		local func, err = load(code, t.sig.."r_"..s, "bt", getfenv(2))
		if not func then
			local m = string.format("failed to load library '%s': ", s)
			m = m .. err:gsub("%[(.-)%]:", "", 1)
			error(m, 2)
		end
		
		local ret = {func()}

		t.loaded[s] = ret
		return table.unpack(ret)
	end

	if ALLOW_C_MODULES and t.cpath then
		local c_path = package.searchpath(s, t.cpath)
		if c_path then
			local func, err = package.loadlib(c_path, s)

			if not func then error(err) end

			local ret = {func()}

			t.loaded[s] = ret
			return table.unpack(ret)
		end
	end

	error(string.format("could not find library '%s'", s), 2)
end

modenv.load = function(code, name, mode, env)
	if type(code) ~= "string" then simpleTypeError("load", 1, "string", code) end
	if name ~= nil and type(name) ~= "string" then simpleTypeError("load", 2, "string or nil", name) end
	if mode ~= nil and type(mode) ~= "string" then simpleTypeError("load", 3, "string or nil", mode) end
	if env ~= nil and typeOf(env) ~= "table" then simpleTypeError("load", 4, "table", env) end
	if mode == "b" then error("loading of binary chunks is disabled", 2) end
	local t = getBottomModData()
	if not t then return end
	return load(code, name, "t", env or getfenv(2))
end

modenv.loadstring = modenv.load

modenv.pairs = function(t)
	if type(t) ~= "table" then simpleTypeError("pairs", 1, "table", t) end
	local mt = getmetatable(t)
	if mt then
		if type(mt.__pairs) == "function" then
			return mt.__pairs(t)
		elseif typeOf(t) ~= "table" then
			error("object does not support pairs function", 2)
		end
	end
	return pairs(t)
end

modenv.ipairs = function(t)
	if type(t) ~= "table" then simpleTypeError("ipairs", 1, "table", t) end
	local mt = getmetatable(t)
	if mt then
		if type(mt.__ipairs) == "function" then
			return mt.__ipairs(t)
		elseif typeOf(t) ~= "table" then
			error("object does not support ipairs function", 2)
		end
	end
	return ipairs(t)
end

local function traversePath(env, path)
	for i = 1, #path - 1 do
		local s = path[i]
		if env[s] == nil then
			env[s] = {}
		elseif typeOf(env[s]) ~= "table" then
			return nil
		end
		env = env[s]
	end
	return env
end

modenv.export = function(name, value)
	if type(name) ~= "string" then simpleTypeError("export", 1, "string", name) end
	local mod = getTopModData()

	local path = {}
	for str in string.gmatch(name, "([^.]+)") do
		path[#path + 1] = str
	end

	local env = traversePath(mod.env, path)
	name = path[#path]

	if env then 
		value = value or env[name] or {}
		env[name] = value
	end

	if mod.exportTargets then
		for _, v in ipairs(mod.exportTargets) do
			v = traversePath(v, path)
			if v then
				v[name] = value
			end
		end
	end
end

modenv.os = {
	clock=os.clock,
	date=os.date,
	difftime=os.difftime,
	time=os.time,
}

modenv.getfenv = function(t)
	local ttype = type(t)
	if t ~= nil and ttype ~= "function" and ttype ~= "number" then simpleTypeError("getfenv", 1, "function or number", t) end
	if t == nil then t = 2
	elseif ttype == "number" then t = t + 1 end
	local e = getfenv(t)
	if e == _G then return nil end
	return e
end

modenv.setfenv = function(t, env)
	-- Vanilla lua setfenv supports using a number as first argument
	-- but due to some bug, the cause of which I'm clueless about,
	-- we're not doing that here.
	if type(t) ~= "function" then simpleTypeError("setfenv", 1, "function", t) end
	if typeOf(env) ~= "table" then simpleTypeError("setfenv", 2, "table", env) end
	if getfenv(t) == _G then error("attempt to set environment of built-in function", 2) end
	return setfenv(t, env)
end

local function loadFromFile(s, dat, nocopy)
	if not nocopy then
		dat = dat and reccopy(dat) or {}
	end
	dat.filepath = s
	dat.name = dat.name or s

	local sinternal = string.lower(dat.internalname)
	if mods[sinternal] then
		return nil, string.format("failed to load '%s', %s", dat.name, "namespace '" .. sinternal .. "' is already in use")
	elseif sinternal == "vanilla" or sinternal == "modloadercore" then
		return nil, string.format("failed to load '%s', %s", dat.name, "namespace '" .. sinternal .. "' is reserved")
	end

	dat.loaded = dat.loaded or {}
	dat.ppath = string.format("mods/%s/?.lua;mods/%s/?;%s?.lua;%s?/main.lua;%s?/?.lua", dat.path, dat.path, lib_dir, lib_dir, lib_dir)
	dat.cpath = string.format("%s?.dll", lib_dir)

	local sig = string.char(mod_signature_base) .. string.char(mod_signature_upper)
	signature_to_mod[sig] = dat
	dat.sig = sig
	mod_signature_base = mod_signature_base + 1
	if mod_signature_base > mod_singature_end then
		-- Hopefully just under 9k mod slots is enough
		mod_signature_base = 32
		mod_signature_upper = mod_signature_upper + 1
	end

	mods[sinternal] = dat
	modlist[#modlist + 1] = dat.internalname

	io.input(s)
	local code = io.read("*all")
	io.input():close()

	local func, err = load(code, dat.sig .. "r_main")

	if err then
		return nil, string.format("failed to load '%s', %s", dat.name, err):gsub("%[string \""..dat.sig.."\"%]", dat.internalname .. ":main.lua", 1), err
	end

	local newenv = reccopy(modenv)
	for k, v in pairs(aliases) do
		newenv[k] = newenv[v]
	end
	newenv._G = newenv
	table.insert(miscTables, newenv.misc)
	table.insert(netTables, newenv.net)
	table.insert(playerLists, newenv.misc.players)
	
	dat.env = newenv
	setfenv(func, newenv)
	dat.func = func

	return dat.func, nil, dat
end

local function loadFromName(s, dat, nocopy)
	if not nocopy then
		dat = dat and reccopy(dat) or {}
	end

	dat.path = s
	dat.name = dat.name or dat.metadata.name or s
	dat.internalname = dat.metadata.internalname or dat.name

	local func, err = loadFromFile(string.format("mods/%s/main.lua", s), dat, true)
	if not func then
		return nil, err, err
	end

	return func, err, dat
end

local function loadMod(s, dat)
	local func, err, dat = loadFromName(s, dat, dat)
	
	local dn = dat.name or s

	if not func then
		GML.error_error(err, 0)
		return
	end

	modFunctionSources[func] = dat.internalname

	public.initFunctionQueue[#public.initFunctionQueue + 1] = func

	return dat
end

function public.preInitializeMods()
	for _, v in pairs(mods) do
		local d = v.metadata.dependencyList
		if d then
			for _, i in ipairs(d) do
				if mods[i] then
					local j = mods[i]
					if j then
						j.exportTargets = j.exportTargets or {}
						j.exportTargets[#j.exportTargets + 1] = v.env
					end
				end
			end
		end
	end
end

do
	function public.clearPlayerList()
		for _, v in ipairs(playerLists) do
			for k, _ in ipairs(v) do
				v[k] = nil
			end
		end
	end

	local playerObj = nil
	local oldHUD = nil
	function public.updatePlayerList()
		if playerObj == nil then
			playerObj = Object.find("p", "vanilla")
		end
		local playersFalse = playerObj:findAll()
		local players = {}
		local count = 0
		for _, v in ipairs(playersFalse) do
			if v:isValid() then
				count = count + 1
				players[count] = v
			end
		end

		for _, v in ipairs(playerLists) do
			for k, p in ipairs(players) do
				rawset(v, k, p)
			end
		end

		if oldHUD ~= GML_hud_instance_id then
			oldHUD = GML_hud_instance_id
			local hudInst = GMInstance.iwrap(GML_hud_instance_id)
			for _, v in ipairs(miscTables) do
				rawset(v, "hud", hudInst)
				rawset(v, "HUD", hudInst)
			end
		end
	end

	function public.updateDirectorInstance()
		local directorInst = GMInstance.iwrap(GML_director_instance_id)
		for _, v in ipairs(miscTables) do
			rawset(v, "director", directorInst)
		end
	end
end

public.loadFromFile = loadFromFile
public.loadFromName = loadFromName
public.loadMod = loadMod
public.getModData = getBottomModData
public.getTopModData = getTopModData
public.modenv = modenv
public.aliases = aliases
public.mods = mods
public.modlist = modlist
public.netAPIList = netTables

return public
