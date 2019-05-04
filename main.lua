
-- Table of functions which are executed and then cleared when everything is loaded
CallWhenLoaded = {}

local code_dir = "resources/modloadercore/"
package.path = "./?.lua;"

require(code_dir .. "internal/ffiinit")
require(code_dir .. "internal/internals")

table.unpack = unpack or table.unpack
function table.pack(...) return {n = select("#", ...), ...} end
overrideModContext = nil
currentModContext = "ModLoaderCore"
modFunctionSources = setmetatable({}, {__type = "k"})
function GetModContext()
	return overrideModContext or currentModContext
end

function ResolveModPath()
	return "mods/" .. mods.getModData().path .. "/"
end

SpecialCallbacks = {}

local unpack = table.unpack or unpack
function CallbackHandlers.FireSpecialCallback(args)
	local name = args[1]
	table.remove(args, 1)
	SpecialCallbacks[name](unpack(args))
end

GML_init_instance_id = GML.instance_find(GML.asset_get_index("oInit"), 0)

math.randomseed(GML.random_get_seed())

mods = require(code_dir .. "modhandler")
require "loadmods"

require "util/apitools"
require "util/class"

-- print / log functions
do
	local rtype = type
	_G.type = typeOf
	local inspect = require("inspect")
	_G.type = rtype
	local function printInternal(...)
		args = table.pack(...)
		str = ""
		for i = 1, args.n do
			local t
			if type(args[i]) == "string" then
				t = args[i]
			else
				t = inspect(args[i])
			end
			if i > 1 then
				str = str .. "    " .. t
			else
				str = t
			end
		end
		if str == "" then
			str = " " -- Fixes a crash idk
		end
		return str
	end

	function print(...)
		GML.console_add_message(printInternal(...), 15923448, 0)
	end

	function log(...)
		GML.console_add_message("[LOGGED] " .. printInternal(...), 15923448, 0)
		GML.log_text(str)
	end
end

require "internal/callbackHandler"

require "api/standardExpanded"

require "api/module/modloader"

require "api/newtype"

require "api/module/graphics"

require "api/class/object/GMObjectBase"

require "api/class/Sound"

require "api/class/ParticleType"

require "api/module/input"

require "api/class/Item"

require "api/class/Artifact"

require "api/class/Survivor"

require "api/class/Stage"

require "api/class/Buff"

require "api/class/Achievement"

require "api/module/misc"

require "api/defaultCallbacks"

require "api/modConstants"

mods.modenv.print = print
mods.modenv.log = log

local function initializeRun()
	ResetGraphics()
	mods.clearPlayerList()
	mods.updateDirectorInstance()
end

local function updatePlayerList()
	mods.updatePlayerList()
end

function CallbackHandlers.initializeRun()
	local success, err = pcall(initializeRun)
	if err then log(err) end
end

function CallbackHandlers.updatePlayerList()
	local success, err = pcall(updatePlayerList)
	if err then log(err) end
end

function CallbackHandlers.encodeModSave() end

-- Call queued post-load functions
for _, v in ipairs(CallWhenLoaded) do
	v()
end
CallWhenLoaded = nil
