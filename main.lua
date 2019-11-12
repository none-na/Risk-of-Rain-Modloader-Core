
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

do
	local g = _G
	local function getModEnv()
		local level = 3
		repeat
			local success, res = pcall(getfenv, level)
			if not success then
				return g
			elseif res ~= g then
				return res
			end
			level = level + 1
		until false
	end
	function GetModContext()
		return overrideModContext or mods.envToName[(getModEnv() or 1)] or currentModContext
	end
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

LOAD_IN_PROGRESS = true
INGAME = false

--local require = function(...) log(...) require(...) end

local API = {}

require "api/class/DS/dsWrapper"

require "internal/callbackHandler"

require "api/standardExpanded"

require "api/module/modloader"

require "api/newtype"

require "api/module/graphics"

require "api/class/object/GMObjectBase"

require "api/class/Sound"

require "api/class/Camera"

-- require "api/io"

require "api/class/ParticleType"

API.MonsterCard = require "api/class/MonsterCard"
API.MonsterLog = require "api/class/MonsterLog"
API.EliteType = require "api/class/EliteType"

require "api/module/input"

require "api/module/net"

require "api/module/save"

require "api/class/Item"

require "api/class/Artifact"

require "api/class/Interactable"

require "api/class/Difficulty"

require "api/class/Survivor"

require "api/class/Buff"

require "api/class/Achievement"

require "api/class/Room"

require "api/class/Stage"

require "api/module/misc"

require "api/defaultCallbacks"

require "api/modConstants"

for k, v in pairs(API) do
	mods.modenv[k] = v
	_G[k] = v
end

mods.modenv.print = print
mods.modenv.log = log

local function initializeRun()
	ResetGraphics()
	mods.clearPlayerList()
	mods.updateDirectorInstance()
	INGAME = true
	RefreshNetAPI(mods.netAPIList)
end

local function updatePlayerList()
	mods.clearPlayerList()
	mods.updatePlayerList()
	RefreshNetAPILate(mods.netAPIList)
end

function CallbackHandlers.initializeRun()
	local success, err = pcall(initializeRun)
	if err then log("initializeRun:", err) end
end

-- Called before onGameEnd
function CallbackHandlers.cleanRun()
	INGAME = false
end

function CallbackHandlers.updatePlayerList()
	local success, err = pcall(updatePlayerList)
	if err then log("updatePlayerList:", err) end
end

-- Call queued post-load functions
for _, v in ipairs(CallWhenLoaded) do
	v()
end
CallWhenLoaded = nil
