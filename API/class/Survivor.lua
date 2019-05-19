local static, lookup, meta, ids, special, children = NewClass("Survivor", true)
meta.__tostring = __tostring_default_namespace
Survivor = {}
mods.modenv.Survivor = Survivor

local all_survivors = {vanilla = {}}
local survivor_name = {}
local survivor_origin = {}
local id_to_survivor = {}
local survivor_color = {}
local survivor_menu_sprite = {}
local survivor_callbacks = {}
local survivor_callbacks_map = {}
local survivor_active = {}
local survivor_display_name = {}

-- Wrap vanilla survivors
for i = 1, 12 do
	local new = static.new(i)
	id_to_survivor[i] = new

	GML.array_open("class_info")
	survivor_name[new] = AnyTypeRet(GML.array_read_2(i, 0))
	survivor_menu_sprite[new] = SpriteUtil.fromID(AnyTypeRet(GML.array_read_2(i, 1)))
	survivor_display_name[new] = AnyTypeRet(GML.array_read_2(i, 16))
	survivor_callbacks[new] = {}
	survivor_callbacks_map[new] = AnyTypeRet(GML.array_read_2(i, 17))
	GML.array_close()
	survivor_origin[new] = "Vanilla"

	GML.array_open_instance(GML_init_instance_id, "class_color")
	survivor_color[new] = ConstructColorObject(AnyTypeRet(GML.array_read_1(i)))
	GML.array_close()

	all_survivors.vanilla[string.lower(survivor_name[new])] = new
end

local function syncClassInfo(self, index, value)
	GML.array_open("class_info")
	GML.array_write_2(ids[self], index, AnyTypeArg(value))
	GML.array_close()
end

--------------------
--------------------
--Methods-----------
--------------------
--------------------

function lookup:getName()
	if not children[self] then methodCallError("Survivor:getName", self) end
	return survivor_name[self]
end

function lookup:getOrigin()
	if not children[self] then methodCallError("Survivor:getOrigin", self) end
	return survivor_origin[self]
end

lookup.disabled = {
	get = function(t)
		return not survivor_active[t] or true
	end,
	set = function(t, v)
		if type(v) ~= "boolean" then fieldTypeError("Survivor.enabled", "boolean", v) end
		GML.class_set_active(ids[t], not v)
		survivor_active[t] = not v
	end
}

lookup.displayName = {
	get = function(t)
		return survivor_display_name[t]
	end,
	set = function(t, v)
		if type(v) ~= "string" then fieldTypeError("Survivor.displayName", "string", v) end
		syncClassInfo(t, 16, v)
		survivor_display_name[t] = v
	end
}

-- Bind a function to a callback
do
	local events = {
		init = true,
		step = true,
		draw = true,
		useSkill = true,
		onSkill = true,
		levelUp = true,
		scepter = true
	}
	function lookup:addCallback(callback, bind)
		if not children[self] then methodCallError("Survivor:addCallback", self) end
		if type(callback) ~= "string" then typeCheckError("Survivor:addCallback", 1, "callback", "string", callback) end
		if type(bind) ~= "function" then typeCheckError("Survivor:addCallback", 2, "bind", "function", bind) end
		if not events[callback] then error(string.format("'%s' is not a valid survivor callback", callback), 2) end
		verifyCallback(bind)
		
		modFunctionSources[bind] = GetModContext()
		local current = survivor_callbacks[self][callback]
		if current == nil then
			current = {}
			survivor_callbacks[self][callback] = current
			GML.ds_map_add(survivor_callbacks_map[self], AnyTypeArg(callback), AnyTypeArg(1))
		end
		table.insert(current, bind)
	end
end

--------------------
--------------------
--Menu--------------
--------------------
--------------------

function lookup:setLoadoutInfo(description, skills)
	if not children[self] then methodCallError("Survivor:setLoadoutInfo", self) end
	if type(description) ~= "string" then typeCheckError("Survivor:setLoadoutInfo", 1, "description", "string", description) end
	if typeOf(skills) ~= "Sprite" then typeCheckError("Survivor:setLoadoutInfo", 2, "skills", "Sprite", skills) end

	local id = ids[self]
	GML.array_open("class_info")
	GML.array_write_2(id, 11, AnyTypeArg(description))
	GML.array_write_2(id, 2, AnyTypeArg(SpriteUtil.toID(skills)))
	GML.array_close()
end

function lookup:setLoadoutSkill(index, name, description)
	if not children[self] then methodCallError("Survivor:setLoadoutSkill", self) end
	if type(index) ~= "number" then typeCheckError("Survivor:setLoadoutSkill", 1, "index", "number", index) end
	if type(name) ~= "string" then typeCheckError("Survivor:setLoadoutSkill", 2, "name", "string", name) end
	if type(description) ~= "string" then typeCheckError("Survivor:setLoadoutSkill", 3, "description", "string", description) end
	if index < 1 or index > 4 then error("invalid skill index, expected 1 - 4", 3) end
	
	local id = ids[self]
	GML.array_open("class_info")
	GML.array_write_2(id, index * 2 + 1, AnyTypeArg(name))
	GML.array_write_2(id, index * 2 + 2, AnyTypeArg(description))
	GML.array_close()
end

lookup.loadoutSprite = {
	set = function(t, v)
		if typeOf(v) ~= "Sprite" then fieldTypeError("Survivor.loadoutSprite", "Sprite", v) end
		survivor_menu_sprite[t] = v
		syncClassInfo(t, 1, SpriteUtil.toID(v))
	end,
	get = function(t)
		return survivor_menu_sprite[t]
	end
}

lookup.loadoutColor = {
	get = function(t)
		return survivor_color[t]
	end,
	set = function(t, v)
		if typeOf(v) ~= "Color" then fieldTypeError("Survivor.loadoutColor", "Color", v) end
		survivor_color[t] = v
		GML.array_open_instance(GML_init_instance_id, "class_color")
		GML.array_write_1(ids[t], AnyTypeArg(GetColorValue(v)))
		GML.array_close()
	end
}
lookup.loadoutColour = lookup.loadoutColor

lookup.loadoutWide = {
	set = function(t, v)
		if typeOf(v) ~= "boolean" then fieldTypeError("Survivor.loadoutWide", "boolean", v) end
		syncClassInfo(t, 14, v and 1 or 0)
	end,
	get = function(t)
		GML.array_open("class_info")
		local r = AnyTypeRet(GML.array_read_2(ids[t], 14))
		GML.array_close()
		return r > 0
	end
}

lookup.titleSprite = {
	set = function(t, v)
		if typeOf(v) ~= "Sprite" then fieldTypeError("Survivor.titleSprite", "Sprite", v) end
		GML.array_global_write_1("class_sprite", AnyTypeArg(SpriteUtil.toID(v)), ids[t] - 1)
	end,
	get = function(t)
		return SpriteUtil.fromID(AnyTypeRet(GML.array_global_read_1("class_sprite", ids[t] - 1)))
	end
}

lookup.idleSprite = {
	set = function(t, v)
		if typeOf(v) ~= "Sprite" then fieldTypeError("Survivor.idleSprite", "Sprite", v) end
		GML.array_global_write_2("class_info", AnyTypeArg(SpriteUtil.toID(v)), ids[t], 19)
	end,
	get = function(t)
		return SpriteUtil.fromID(AnyTypeRet(GML.array_global_read_2("class_info", ids[t], 19)))
	end
}

lookup.endingQuote = {
	set = function(t, v)
		if typeOf(v) ~= "string" then fieldTypeError("Survivor.endingQuote", "string", v) end
		GML.array_open("class_info")
		GML.array_write_2(ids[t], 18, AnyTypeArg(v))
		GML.array_close()
	end,
	get = function(t)
		GML.array_open("class_info")
		local r = AnyTypeRet(GML.array_read_2(ids[t], 18))
		GML.array_close()
		return r
	end
}

--------------------
--------------------
--Global------------
--------------------
--------------------
do
	local defaultMenuSprite = SpriteUtil.fromID(GML.asset_get_index("sSelectAnon"))
	local function survivor_new(name)
		local context = GetModContext()
		contextVerify(all_survivors, name, context, "Survivor", 1)

		local nid = GML.class_add()
		local new = static.new(nid)
		id_to_survivor[nid] = new
		survivor_name[new] = name
		survivor_origin[new] = context

		survivor_color[new] = ConstructColorObject(16777215)
		survivor_menu_sprite[new] = defaultMenuSprite
		survivor_display_name[new] = name

		GML.array_open("class_info")
		GML.array_write_2(nid, 0, AnyTypeArg(name))
		GML.array_write_2(nid, 15, AnyTypeArg(context))
		GML.array_write_2(nid, 16, AnyTypeArg(name))
		survivor_callbacks_map[new] = AnyTypeRet(GML.array_read_2(nid, 17))
		survivor_callbacks[new] = {}
		GML.array_close()

		contextInsert(all_survivors, name, context, new)

		return new
	end

	function Survivor.new(name)
		if type(name) ~= "string" then typeCheckError("Survivor.new", 1, "name", "string", name) end
		return survivor_new(name)
	end
	
	setmetatable(Survivor, {__call = function(t, name)
		if type(name) ~= "string" then typeCheckError("Survivor", 1, "name", "string", name) end
		return survivor_new(name)
	end})
end

Survivor.find = contextSearch(all_survivors, "Survivor.find")
Survivor.findAll = contextFindAll(all_survivors, "Survivor.findAll")


-- Handle callback
local iwrap = GMInstance.iwrap
function SpecialCallbacks.survivor(player, callback, class, arg, arg2)
	local p = iwrap(player)
	local args = {p, arg, arg2}
	for _, v in ipairs(survivor_callbacks[id_to_survivor[class]][callback]) do
		CallModdedFunction(v, args)
	end
end

-- b

RoRSurvivor = {}

function RoRSurvivor.fromID(t)
	return id_to_survivor[t]
end

function RoRSurvivor.toID(t)
	return ids[t]
end

--]======]
