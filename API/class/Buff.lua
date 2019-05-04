local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Buff", true)
meta.__tostring = __tostring_default_namespace
-- Create global table
Buff = {}
mods.modenv.Buff = Buff

local all_buffs = {vanilla = {}}

-- Field tables
local buff_name = {}
local buff_origin = {}
local buff_icon_sprite = {}
local buff_icon_index = {}
local buff_icon_speed = {}
local buff_callbacks = {}
local id_to_buff = {}

local default_sprite = SpriteUtil.fromID(GML.asset_get_index("sBuffs"))
local maxbuff = 31

------------------------------------------
-- COMMON -------------------------------
------------------------------------------

function lookup:getName()
	if not children[self] then methodCallError("Buff:getName", self) end

	return buff_name[self]
end

function lookup:getOrigin()
	if not children[self] then methodCallError("Buff:getOrigin", self) end

	return buff_origin[self]
end



------------------------------------------
-- FIELDS --------------------------------
------------------------------------------

local syncBuffField
do
	local fieldID = {
		sprite = 0,
		frameIndex = 1,
		frameSpeed = 2
	}
	function syncBuffField(buff, field, value)
		GML.array_open("buff_info")
		GML.array_write_2(ids[buff], fieldID[field], AnyTypeArg(value))
		GML.array_close()
	end
end

lookup.sprite = {
	get = function(t)
		return buff_icon_sprite[t]
	end,
	set = function(t, v)
		if typeOf(v) ~= "Sprite" then fieldTypeError("Buff.sprite", "Sprite", v) end
		buff_icon_sprite[t] = v
		syncBuffField(t, "sprite", SpriteUtil.toID(v))
	end
}

lookup.subimage = {
	get = function(t)
		return buff_icon_index[t]
	end,
	set = function(t, v)
		if type(v) ~= "number" then fieldTypeError("Buff.subimage", "number", v) end
		buff_icon_index[t] = v
		syncBuffField(t, "frameIndex", v - 1)
	end
}

lookup.frameSpeed = {
	get = function(t)
		return buff_icon_speed[t]
	end,
	set = function(t, v)
		if type(v) ~= "number" then fieldTypeError("Buff.frameSpeed", "number", v) end
		buff_icon_speed[t] = v
		syncBuffField(t, "frameSpeed", v)
	end
}



------------------------------------------
-- CALLBACKS -----------------------------
------------------------------------------

do
	local events = {
		["start"] = 3,
		["step"] = 4,
		["end"] = 5
	}
	function lookup:addCallback(callback, bind)
		if not children[self] then methodCallError("Buff:addCallback", self) end
		if type(callback) ~= "string" then typeCheckError("Buff:addCallback", 1, "callback", "string", callback) end
		if type(bind) ~= "function" then typeCheckError("Buff:addCallback", 2, "bind", "function", bind) end
		if not events[callback] then error(string.format("'%s' is not a valid buff callback", callback), 2) end
		verifyCallback(bind)
		
		modFunctionSources[bind] = GetModContext()

		local current = buff_callbacks[self][callback]
		if current == nil then
			current = {}
			buff_callbacks[self][callback] = current

			GML.array_open("buff_info")
			GML.array_write_2(ids[self], events[callback], AnyTypeArg(1))
			GML.array_close()
		end
		table.insert(current, bind)
	end
end

function SpecialCallbacks.buff(callback, buffid, actor, time)
	local buff = id_to_buff[buffid]
	local call = buff_callbacks[buff][callback]
	if not call then
		return
	else
		local args = {GMInstance.iwrap(actor), time}
		for _, v in ipairs(call) do
			CallModdedFunction(v, args)
		end
	end
end



------------------------------------------
-- WRAP VANILLA --------------------------
------------------------------------------

do
	vanilla_buff_names = {
		[0] = "wormEye", [1] = "slow", [5] = "burstSpeed",
		[6] = "burstHealth", [7] = "slow2", [8] = "shield",
		[9] = "thallium", [10] = "warbanner", [11] = "dice1",
		[12] = "dice2", [13] = "dice3", [14] = "dice4",
		[15] = "dice5", [16] = "dice6", [17] = "snare",
		[18] = "dash", [19] = "poisonTrail", [20] = "sunder1",
		[21] = "sunder2", [22] = "sunder3", [23] = "sunder4",
		[24] = "sunder5", [25] = "blood1", [26] = "blood2",
		[27] = "blood3", [28] = "burstAttackSpeed",
		[29] = "superShield", [30] = "burstSpeed2", [31] = "oil"
	}

	for i = 0, 31 do
		if vanilla_buff_names[i] then
			local new = static.new(i)
			id_to_buff[i] = new

			all_buffs.vanilla[string.lower(vanilla_buff_names[i])] = new

			buff_name[new] = vanilla_buff_names[i]
			buff_origin[new] = "Vanilla"

			buff_icon_sprite[new] = default_sprite
			buff_icon_index[new] = i + 1
			buff_icon_speed[new] = 0
			buff_callbacks[new] = {}
		end
	end
end

------------------------------------------
-- GLOBAL FUNCTIONS ----------------------
------------------------------------------

Buff.find = contextSearch(all_buffs, "Buff.find")
Buff.findAll = contextFindAll(all_buffs, "Buff.findAll")

local function buff_new(name)
	local context = GetModContext()
	if name == nil then
		name = "[Buff" .. tostring(contextCount(all_buffs, context)) .. "]"
	end
	contextVerify(all_buffs, name, context, "Buff", 1)

	maxbuff = maxbuff + 1
	local nid = maxbuff
	local new = static.new(nid)
	id_to_buff[nid] = new

	contextInsert(all_buffs, name, context, new)

	buff_origin[new] = context
	buff_name[new] = name
	buff_icon_sprite[new] = default_sprite
	buff_icon_index[new] = 1
	buff_icon_speed[new] = 0
	buff_callbacks[new] = {}

	GML.array_open("buff_info")
	GML.array_write_2(nid, 0, AnyTypeArg(SpriteUtil.toID(default_sprite)))
	for i = 1, 5 do
		GML.array_write_2(nid, i, AnyTypeArg(0))
	end
	GML.array_close()

	return new
end

function Buff.new(name)
	if name ~= nil and type(name) ~= "string" then typeCheckError("Buff.new", 1, "name", "string or nil", name) end
	return buff_new(name)
end

setmetatable(Buff, {__call = function(t, name)
	if name ~= nil and type(name) ~= "string" then typeCheckError("Buff", 1, "name", "string or nil", name) end
	return buff_new(name)
end})

-- Stuff needed by ActorInstance.lua
RoRBuff = {}
function RoRBuff.toID(buff)
	return ids[buff]
end
function RoRBuff.fromID(id)
	return id_to_buff[id]
end
