local GML = GML
local type = type
local typeOf = typeOf

save = {}

-- Save string:
-- modname,key,type,value,key,type,value...|modname,key,type,value,key,type,value...|etc

local saveDat = {}

local function toSafe(str)
	str = str:gsub("%%", "(%%1%%)")
	str = str:gsub(",", "(%%2%%)")
	str = str:gsub("|", "(%%3%%)")
	return str
end

local function toUnsafe(str)
	str = str:gsub("(%%3%%)", "|")
	str = str:gsub("(%%2%%)", ",")
	str = str:gsub("(%%1%%)", "%%")
	return str
end

local function split(str, sep)
	local res = {}
	for s in str:gmatch("([^" .. sep .. "]+)") do
		table.insert(res, s)
	end
	return res
end

local function trueWrite(mod, key, value)
	mod = mod:lower()
	if saveDat[mod] == nil then
		saveDat[mod] = {}
	end
	saveDat[mod][key] = value
end

local function trueRead(mod, key, value)
	mod = mod:lower()
	if saveDat[mod] == nil then
		return nil
	else
		return saveDat[mod][key]
	end
end

local supportedTypes = {
	"number", "string", "boolean", "nil"
}

for k, v in ipairs(supportedTypes) do
	supportedTypes[v] = k
end

local encoders = {
	number = function(v) return tostring(v) end,
	string = function(v) return v end,
	boolean = function(v) return v and "1" or "0" end,
	["nil"] = function() return " " end
}

local decoders = {
	number = function(v) return tonumber(v) end,
	string = function(v) return v end,
	boolean = function(v) return v == "1" and true or false end,
	["nil"] = function() return nil end
}

local function encode(t)
	local str = ""
	for mod, dat in pairs(t) do
		str = str .. toSafe(mod) .. ","
		for k, v in pairs(dat) do
			str = str .. tostring(supportedTypes[type(v)]) .. "," .. toSafe(encoders[type(k)](k)) .. "," .. toSafe(encoders[type(v)](v)) .. ","
		end
		str = str .. "|"
	end
	return str
end

local function decode(s)
	local t = {}
	for _, dat in ipairs(split(s, "|")) do
		local e = split(dat, ",")
		local modName = toUnsafe(e[1])
		t[modName] = t[modName] or {}
		for i = 2, #e, 3 do
			local q = e[i]
			local k = e[i + 1]
			local v = e[i + 2]
			if q == nil or k == nil or v == nil then
				break
			end

			q = tonumber(toUnsafe(q))
			k = toUnsafe(k)
			v = toUnsafe(v)

			if not supportedTypes[t] then
				t[modName][k] = decoders[supportedTypes[q]](v)
			end
		end
	end

	return t
end

function save.write(key, value)
	if type(key) ~= "string" then typeCheckError("save.write", 1, "key", "string", key) end
	if not supportedTypes[typeOf(value)] then typeCheckError("save.write", 2, "value", "number, string, boolean, or nil", value) end
	trueWrite(GetModContext(), key, value)
end

function save.read(key)
	if type(key) ~= "string" then typeCheckError("save.read", 1, "key", "string", key) end
	return trueRead(GetModContext(), key)
end

function save.writeMod(mod, key, value)
	if type(mod) ~= "string" then typeCheckError("save.writeMod", 1, "mod", "string", mod) end
	if type(key) ~= "string" then typeCheckError("save.writeMod", 2, "key", "string", key) end
	if not supportedTypes[typeOf(value)] then typeCheckError("save.writeMod", 3, "value", "number, string, boolean, or nil", value) end
	trueWrite(mod, key, value)
end

function save.readMod(mod, key)
	if type(mod) ~= "string" then typeCheckError("save.readMod", 1, "mod", "string", mod) end
	if type(key) ~= "string" then typeCheckError("save.readMod", 2, "key", "string", key) end
	return trueRead(mod, key)
end

function CallbackHandlers.encodeModSave()
	GML.ds_map_replace(
		AnyTypeRet(GML.variable_global_get("save_mods")),
		AnyTypeArg("BasicSaveSys"),
		AnyTypeArg(encode(saveDat))
	)
end

do
	local saveStr = AnyTypeRet(GML.ds_map_find_value(
		AnyTypeRet(GML.variable_global_get("mod_save_loaded")),
		AnyTypeArg("BasicSaveSys")
	))
	if type(saveStr) == "string" then
		saveDat = decode(saveStr)
	end
end

mods.modenv.save = save
