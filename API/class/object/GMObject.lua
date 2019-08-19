local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("GMObject", true, GMObject.baseClass)
meta.__tostring = __tostring_default_namespace


-- Table of all objects by context
local all_objects = {vanilla = {}}

local object_id_to_wrapper = {}
local object_type_to_wrapper

-- Object definition tables
local object_nospawn = {}
local object_nodestroy = {}
local object_origin = {} -- Source of object
local object_name = {}
local object_type = {}
local id_to_object = {}
local object_real_name = {}
local object_locked = {}

-- Global tables
GMObject.noSpawn = object_nospawn
GMObject.noDestroy = object_nodestroy
GMObject.ids = ids
GMObject.ids_map = id_to_object
GMObject.locked = object_locked

GMInstance = {}
local instance_object = setmetatable({}, {__mode = "k"})
-- Helper functions
local iwrap
local object_id_custom = {}
do
	local wrapped = setmetatable({}, {__mode = "v"})
	function iwrap(instance, unsafe)
		if not instance then return end
		if wrapped[instance] then
			return wrapped[instance]
		else
			local nid
			if not unsafe then
				nid = GML.get_object_index(instance)
			else
				-- Lua side implementation of the get_obejct_index script
				nid = AnyTypeRet(GML.variable_instance_get(instance, "object_index"))
				if object_id_custom[nid] then
					nid = AnyTypeRet(GML.variable_instance_get(instance, "_object_index"))
				end
			end
			if nid < 0 then
				-- Doesn't exist
				return
			end
			local wrapper = object_id_to_wrapper[nid]
			if wrapper == nil then
				error("Attempting to wrap instance of unwrappable object '" .. ffi.string(GML.object_get_name(nid)) .. "', please report this as this is as modloader flaw.")
			end
			local new = wrapper(instance)
			wrapped[instance] = new
			instance_object[new] = id_to_object[nid]
			return new
		end
	end
end
GMInstance.iwrap = iwrap
GMInstance.instance_object = instance_object

function GMObject.fromID(id)
	return id_to_object[id]
end
function GMObject.toID(this)
	return ids[this]
end
function GMObject.setObjectType(obj, typ)
	object_type[obj] = typ
	object_id_to_wrapper[ids[obj]] = object_type_to_wrapper[typ]
end

local function objectLockError(t)
	error("attempt to access locked object "..object_name[t], 3)
end

-- Fields
lookup.sprite = {
	get = function(t)
		if object_locked[t] then objectLockError(t) end
		return SpriteUtil.fromID(GML.object_get_sprite(ids[t]))
	end,
	set = function(t, v)
		if object_locked[t] then objectLockError(t) end
		if typeOf(v) ~= "Sprite" then fieldTypeError("GMObject.sprite", "Sprite", v) end
		GML.object_set_sprite(ids[t], SpriteUtil.toID(v))
	end
}

lookup.depth = {
	get = function(t)
		if object_locked[t] then objectLockError(t) end
		return GML.object_get_depth(ids[t])
	end,
	set = function(t, v)
		if object_locked[t] then objectLockError(t) end
		if typeOf(v) ~= "number" then fieldTypeError("GMObject.depth", "number", v) end
		GML.object_set_depth(ids[t], v)
	end
}

-- Method definitions
function lookup:create(x, y)
	if not children[self] then methodCallError("GMObject:create", self) end
	if type(x) ~= "number" then typeCheckError("GMObject:create", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("GMObject:create", 2, "y", "number", y) end
	if object_locked[self] then objectLockError(self) end
	if object_nospawn[self] then error("attempt to create spawn-disabled object "..object_name[self], 2) end
	return iwrap(GML.instance_create(x, y, ids[self]))
end

function lookup:getOrigin()
	if not children[self] then methodCallError("GMObject:getOrigin", self) end
	return object_origin[self]
end

function lookup:getName()
	if not children[self] then methodCallError("GMObject:getName", self) end
	return object_name[self]
end

lookup.id = {get = function(self)
	return ids[self]
end}
lookup.ID = lookup.id


-- Event binding
do
	local events = {
		create = 0,
		destroy = 1,
		step = 3,
		draw = 8
	}

	local objectEvents = {}

	function lookup:addCallback(callback, bind)
		if not children[self] then methodCallError("GMObject:addCallback", self) end
		if type(callback) ~= "string" then typeCheckError("GMObject:addCallback", 1, "callback", "string", callback) end
		if type(bind) ~= "function" then typeCheckError("GMObject:addCallback", 2, "bind", "function", bind) end
		if object_locked[self] then objectLockError(self) end
		local event = events[callback]
		if not event then
			error(string.format("'%s' is not a valid object callback", callback), 2)
		end
		if object_origin[self] == "Vanilla" and event > 1 then
			error(string.format("callback '%s' is not supported by vanilla objects", callback), 2)
		end
		verifyCallback(bind)

		local id = ids[self]
		if not objectEvents[id] then
			objectEvents[id] = {}
		end

		modFunctionSources[bind] = GetModContext()

		local t = objectEvents[id][event]
		if not t then
			t = {}
			objectEvents[id][event] = t
			GML.object_add_event_bind(id, event)
		end

		table.insert(t, bind)
	end

	function CallbackHandlers.FireObjectEventBind(args)
		local id = args[1]
		local ev = args[2]
		local obj = args[3]
		local special = args[4]
			
		-- Only call if an event actually exists
		if objectEvents[obj] then
			if objectEvents[obj][ev] then
				-- Wrap instances
				VerifiedInstances[id] = 2
				id = iwrap(id, ev == 1)
				if special then special = iwrap(special) end
				-- Call events
				local args = {id, special}
				for _, v in ipairs(objectEvents[obj][ev]) do
					CallModdedFunction(v, args)
				end
			end
		end
	end

end


-- Global table
Object = {}

-- Load instance class
require "api/class/object/Instance"

object_type_to_wrapper = {
	default = GMInstance.Instance.new,
	item = GMInstance.ItemInstance.new,
	mapObject = GMInstance.Instance.new,
	damager = GMInstance.DamagerInstance.new,
	actor = GMInstance.ActorInstance.new,
	player = GMInstance.PlayerInstance.new,
    enemy = GMInstance.ActorInstance.new
}

-- Wrap basegame objects
local object_id_hidden = {}
do
	-- Table for converting parent names to RoRML object types
	local object_parent_to_type = {
		pItem = "item",
		pUseItem = "item",

		pNPC = "actor",
		pEnemy = "actor",
		pEnemyClassic = "actor",
		pFlying = "actor",
		pBoss = "actor",
		pBossClassic = "actor",
		pFriend = "actor",
		pDrone = "actor",
		pEnemyController = "actor",

		pChest = "mapObject",
		pArtifact8Box = "mapObject",
		pActive = "mapObject",
		pBase = "mapObject",
		pMapObjects = "mapObject",
		pDroneItem = "mapObject",

		pPlayer = "player"
	}
	-- For special objects that don't use a parent
	local object_name_to_type = {
		oExplosion = "damager",
		oBullet = "damager"
	}

	-- List of spawn disabled objects
	-- These mostly just crash the game or do other weird stuff
	local object_nospawn_list = {
		"oP", "oBullet", "oExplosion", "oEfPlayerDead", "oBodyCollector", "oBody",
		"oWormBody", "oWormHead", "oWurmBody", "oWurmHead", "oWurmController",
		"oCommandFinal", "oJellyLegs",
	}
	-- Spawn disabled but destroy enabled objects
	local object_yesdestroy_list = {
		"oDrawDepth"
	}

	-- List of locked objects
	-- Objects that can be accessed by mods but you cant really do anything with them
	local object_lock_list = {
		"oDirectorControl",
		"oHUD"
	}

	
	-- List of hidden objects
	-- These are objects found outside of runs or technical objects
	local object_hide_list = {
		-- Menu stuff
		"oLogo", "oStartMenu","oStartObjects",
		"oHostClient", "oStorageMenu", "oBook",
		"oHighscore", "oSelect", "oSelectCoop",
		"oSelectMult", "oFairItemButton", "oCharPalette",
		"oCredits", "oEfGameBeat", "oMenu",
		"oAchievement", "oError",
		-- Control objects
		"objClient", "objServer", "oPrePlayer", "oInit", "oConsole",
		"rousrDissonance", "oTransformInto", "oCustomRoomControl", "oCustomRoomLayer",
		-- Parents
		"pArtifact8Box", "pBlock", "pNPC", "pRope", "pFlying",
		"pBoss", "pBlockMain", "pEnemyClassic", "pChest", "pPlayer", "pEnemy",
		"pMapObjects", "pDroneItem", "pDrone", "pItem", "pArtifact", "pFriend",
		"pBulletCollision", "pBossClassic", "pEnemyController",
		-- Cutscene stuff
		"oShipCargoHead", "oShipCargo", "oBlackIn", "oCutsceneControl", "oBlackbars",
		"oFadeToBlack", "oGiantPod", "oIntroControl", "oBoss1Fake",
		-- Unused stuff
		-- There's a lot but for the most part it all just crashes the game
		-- Maybe at some point they can be restored to be usable?
		"oCentControl", "oFoot", "oThigh", "oCent", "oCalf",
		"oBeast", "oBeastBody", "oBeastTail", "oBeastLeg", "oBeastHead",
		"oEye", "oMimic", "oBoss", "oWormSmall", "oWormHeadSmall",
		"oLizardT", "oLizardFOLD", "oBot", "oHuntressBolt2OLD", "oExplosion1",
		"oPyroHeat", "oEfBlaze", "oHuntressCape", "oChefBottle", "oChefOil",
		"oChefKnife2", "oPodBullet", "oEfHarpoonEnemy", "oHuntressMine1", "oEngiStunner",
		"object422", "oBossSkill2Old", "oBossLightning", "oBarrelT", "oChest1New",
		"oChestSlot", "oPartner", "oMapDraw", "oBElevator", "object416", "oBoss1Sword",
		"oFeralPregnate", "oFeralNugget", "oTotemMissile", "oTotemShockwave", 
		"oTotemControl", "oTotem", "oAssassinPoke", "oAssassinHands", "oAssassinHit",
		"oAssassin", "oMushB", "oPost", "oCube", "oBG", "oWormHole",
		"oJLMG", "oHeroHat", "oHeroGarb", "oHeroScarf", "oHeroShoe",
		"oHunter", "oImpGFake", "oFlash",
	}
	
	local objecct_custom_list = {
		-- Customobjects
		"oCustomObject", "oCustomObject_pBoss", "oCustomObject_pNPC", "oCustomObject_pEnemyClassic",
		"oCustomObject_pBossClassic", "oCustomObject_pFlying", "oCustomObject_pEnemy",
		"oCustomObject_pFriend", "oCustomObject_pItem",
		"oCustomObject_pDrone", "oCustomObject_pMapObjects", "oCustomObject_pChest",
		"oCustomObject_pBlockMain", "oCustomObject_pBlockAdvancedCollision", "oCustomObject_pArtifact",
		"oCustomObject_pArtifact8Box",
	}

	local no_rename = {
		["object415"] = true
	}
	
	local object_to_lock, object_to_nospawn, object_to_nodestroy, object_to_hide, object_to_custom = {}, {}, {}, {}, {}
	for _, v in ipairs(object_lock_list) do
		object_to_lock[v] = true
	end
	for _, v in ipairs(object_nospawn_list) do
		object_to_nospawn[v] = true
		object_to_nodestroy[v] = true
	end
	for _, v in ipairs(object_yesdestroy_list) do
		object_to_nospawn[v] = true
	end
	for _, v in ipairs(object_hide_list) do
		object_to_hide[v] = true
	end
	for _, v in ipairs(objecct_custom_list) do
		object_to_hide[v] = true
		object_to_custom[v] = true
	end

	local ttable = all_objects.vanilla
	local t = 0
	while GML.object_exists(t) == 1 do
		local realName = ffi.string(GML.object_get_name(t))
		if not object_to_hide[realName] then
			local new = static.new(t)
			local name
			if not no_rename[realName] then
				name = string.sub(realName, 2, -1)
			else
				name = realName
			end
			
			ttable[string.lower(name)] = new

			object_name[new] = name
			object_real_name[new] = realName
			object_origin[new] = "Vanilla"
			if object_name_to_type[realName] then
				object_type[new] = object_name_to_type[realName]
			else
				local tparent = GML.object_get_parent(t)
				if tparent >= 0 then
					object_type[new] = object_parent_to_type[ffi.string(GML.object_get_name(tparent))] or "default"
				else
					object_type[new] = "default"
				end
			end
			id_to_object[t] = new
			if object_to_lock[realName] then
				object_locked[new] = true
			end
			if object_to_nospawn[realName] then
				object_nospawn[new] = true
			end
			if object_to_nodestroy[realName] then
				object_nodestroy[new] = true
			end
			object_id_to_wrapper[t] = object_type_to_wrapper[object_type[new]]
		else
			object_id_hidden[t] = true
			if object_to_custom[realName] then
				object_id_custom[t] = true
			end
		end
		t = t + 1
	end
end

Object.find = contextSearch(all_objects, "Object.find")
Object.findAll = contextFindAll(all_objects, "Object.findAll")

local function object_new(name)
	local context = GetModContext()
	if name == nil then
		name = "[CustomObject" .. tostring(contextCount(all_objects, context)) .. "]"
	end
	contextVerify(all_objects, name, context, "GMObject", 1)

	local nid = GML.object_add()
	local new = static.new(nid)

	contextInsert(all_objects, name, context, new)

	registerNetID("object", nid, context, name)
	object_origin[new] = context
	object_name[new] = name
	object_type[new] = "default"
	id_to_object[nid] = new
	object_real_name[new] = new
	object_id_to_wrapper[nid] = object_type_to_wrapper[object_type[new]]

	return new
end

function Object.new(name)
	if name ~= nil and type(name) ~= "string" then typeCheckError("Object.new", 1, "name", "string or nil", name) end
	return object_new(name)
end

setmetatable(Object, {__call = function(t, name)
	if name ~= nil and type(name) ~= "string" then typeCheckError("Object", 1, "name", "string or nil", name) end
	return object_new(name)
end})

function Object.findInstance(id)
	if type(id) ~= "number" then typeCheckError("Object.findInstance", 1, "id", "number", id) end
	if id > 100000 and GML.instance_exists(id) == 1 then
		local obj = GML.get_object_index(id)
		if not object_id_hidden[obj] then
			return iwrap(id)
		end
	end
end

function Object.fromID(id)
	if type(id) ~= "number" then typeCheckError("Object.fromID", 1, "id", "number", id) end
	return id_to_object[id]
end

require("api/deprecated/ObjectGroup")

-- env
mods.modenv.Object = Object
