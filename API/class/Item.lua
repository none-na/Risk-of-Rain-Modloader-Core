local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Item", true)
meta.__tostring = __tostring_default_namespace

local all_items = {vanilla = {}}

local common_parent = GML.asset_get_index("pItem")
local base_sprite = GML.asset_get_index("sRandom")

-- Definition tables
local item_name = {}
local item_displayname = {}
local item_sprite = {}
local item_text = {}
local item_object = {}
local item_is_use = {}
local item_is_modded = {}
local item_callbacks = {}
local item_origin = {}
local item_log_index = {}
local item_number = 115
local item_log_number = 109
local item_col = {}

local object_to_item = {}
local objids = {}
local id_to_item = {}
local iwrap = GMInstance.iwrap

local syncItemField
do
	local fieldID = {
		name = 0,
		text = 11,
		use = 14,
		sprite = 4,
		col = 17
	}
	function syncItemField(item, field, value)
		GML.array_open("item_info")
		GML.array_write_2(ids[item], fieldID[field], AnyTypeArg(value))
		GML.array_close()
	end
end

local log_list = AnyTypeRet(GML.variable_global_get("item_info_list"))
local log_categories = {
	start = 0,
	common = 16,
	common_locked = 25,
	uncommon = 41,
	uncommon_locked = 52,
	rare = 65,
	rare_locked = 78,
	use = 93,
	use_locked = 104,
	boss = 110,
	boss_locked = 111,
	["end"] = 112
}
local log_default_priority = {
	common = "Standard",
	uncommon = "&g&Priority&!&",
	rare = "&r&High Priority&!&",
	use = "&y&Volatile&!&",
	boss = "&b&Field-Found&!&"
}
for k, v in pairs(log_default_priority) do
	log_default_priority[k .. "_locked"] = v
end

local obj_fromID = GMObject.fromID
local obj_toID = GMObject.toID

-----------------------------------------
-----------------------------------------
---Item-methods-and-fields---------------
-----------------------------------------
-----------------------------------------
do
	-- Get object from item
	function lookup:getObject()
		if not children[self] then methodCallError("Item:getObject", self) end
		return item_object[self]
	end

	-- Get origin from item
	function lookup:getOrigin()
		if not children[self] then methodCallError("Item:getOrigin", self) end
		return item_origin[self]
	end

	-- Get real name
	function lookup:getName()
		if not children[self] then methodCallError("Item:getName", self) end
		return item_name[self]
	end

	-- Bind a function to an item callback
	local events = {
		pickup = 0,
		use = 1,
		drop = 2
	}
	function lookup:addCallback(callback, bind)
		if not children[self] then methodCallError("Item:addCallback", self) end
		if type(callback) ~= "string" then typeCheckError("Item:addCallback", 1, "callback", "string", callback) end
		if type(bind) ~= "function" then typeCheckError("Item:addCallback", 2, "bind", "function", bind) end
		if not events[callback] then error(string.format("'%s' is not a valid item callback", callback), 2) end
		verifyCallback(bind)
		
		modFunctionSources[bind] = GetModContext()
		local current = item_callbacks[self][callback]
		if current == nil then
			current = {}
			item_callbacks[self][callback] = current
			GML.item_enable_callback(ids[self], events[callback])
		end
		table.insert(current, bind)
	end

	-- Set item log
	local log_fields = {
		group = -1,
		description = 1,
		priority = 2,
		destination = 5,
		date = 7,
		story = 8
	}
	function lookup:setLog(args)
		if not children[self] then methodCallError("Item:setLog", self) end
		if typeOf(args) ~= "table" then typeCheckError("Item:setLog", 1, "args", "named arguments", args) end

		local rgroup = rawget(args, "group")
		if type(rgroup) == "string" then
			-- Do this early on to avoid writing when we shouldn't
			if not log_categories[rgroup] then
				error("'"..rgroup.."' is not a known item log group", 3)
			end
		end

		GML.array_open("item_info")

		local iid = ids[self]

		for k, _ in pairs(args) do
			if log_fields[k] then
				local v = rawget(args, k)
				if type(v) ~= "string" then GML.array_close() typeCheckError("Item:setLog", 1, "args."..tostring(k), "string", v) end
				if log_fields[k] ~= -1 then
					GML.array_write_2(iid, log_fields[k], AnyTypeArg(v))
				end
			end
		end

		if item_log_index[self] == nil then
			GML.array_write_2(iid, 13, AnyTypeArg(1))
		end

		if rgroup then
			-- Remove existing log
			if item_log_index[self] then
				curr = item_log_index[self]
				GML.ds_list_delete(log_list, curr)
				for k, v in pairs(log_categories) do
					if v >= curr then
						log_categories[k] = v - 1
					end
				end
			else
				item_log_number = item_log_number + 1
			end

			local group = math.min(log_categories[rgroup], item_log_number)

			for k, v in pairs(log_categories) do
				if v >= group then
					log_categories[k] = v + 1
				end
			end

			GML.ds_list_insert(log_list, group, AnyTypeArg(ids[self]))

			if not args.priority then
				GML.array_write_2(iid, 2, AnyTypeArg(log_default_priority[rgroup] or ""))
			end
		end

		GML.array_close()
	end
	
	do
		local common = AnyTypeRet(GML.variable_global_get("_pool_white"))
		local uncommon = AnyTypeRet(GML.variable_global_get("_pool_green"))
		local rare = AnyTypeRet(GML.variable_global_get("_pool_red"))
		local use = AnyTypeRet(GML.variable_global_get("_pool_use"))
		local pools = {common, uncommon, rare, use}
		local pool = {common = common, uncommon = uncommon, rare = rare, use = use}
		local col = {common = "w", uncommon = "g", rare = "r", use = "or"}
		
		function lookup:setTier(tier)
			if not children[self] then methodCallError("Item:setTier", self) end
			if type(tier) ~= "string" then typeCheckError("Item:setTier", 1, "tier", "string", tier) end
			tier = string.lower(tier)
			if not pool[tier] then error("'" .. tier .. "' is not a valid item tier (common, uncommon, rare, or use)", 2) end
			
			-- Get the object ID of the item
			local objid = obj_toID(item_object[self])
			
			-- Remove the item from all pool
			for _, v in ipairs(pools) do
				GML.item_pool_remove(v, objid)
			end
			
			-- Add the item to the correct pool
			GML.item_pool_add(pool[tier], objid)
			
			-- Set the item's colour
			item_col[self] = col[tier]
			syncItemField(self, "col", col[tier])
		end		
	end
	
	-- Pickup text
	lookup.pickupText = {
		get = function(t)
			return item_text[t]
		end,
		set = function(t, v)
			if type(v) ~= "string" then fieldTypeError("Item.pickupText", "string", v) end
			item_text[t] = v
			syncItemField(t, "text", v)
		end
	}

	-- Sprite
	lookup.sprite = {
		get = function(t)
			return item_sprite[t]
		end,
		set = function(t, v)
			if typeOf(v) ~= "Sprite" then fieldTypeError("Item.sprite", "Sprite", v) end
			item_sprite[t] = v
			local spid = SpriteUtil.toID(v)
			GML.object_set_sprite(objids[t], spid)
			syncItemField(t, "sprite", spid)
		end
	}

	-- Use item?
	lookup.isUseItem = {
		get = function(t)
			return item_is_use[t]
		end,
		set = function(t, v)
			if typeOf(v) ~= "boolean" then fieldTypeError("Item.isUseItem", "boolean", v) end
			item_is_use[t] = v
			syncItemField(t, "use", v and 1 or 0)
		end
	}

	-- Use item cooldown
	lookup.useCooldown = {
		get = function(t)
			return GML.item_get_cooldown(objids[t])
		end,
		set = function(t, v)
			if typeOf(v) ~= "number" then fieldTypeError("Item.useCooldown", "number", v) end
			GML.item_set_cooldown(objids[t], v)
		end
	}

	-- Displayed name
	lookup.displayName = {
		get = function(t)
			return item_displayname[t]
		end,
		set = function(t, v)
			if type(v) ~= "string" then fieldTypeError("Item.displayName", "string", v) end
			item_displayname[t] = v
			syncItemField(t, "name", v)
		end
	}

	-- Item colour
	lookup.color = {
		get = function(t)
			return item_col[t]
		end,
		set = function(t, v)
			local typ = typeOf(v) 
			if typ ~= "string" and typ ~= "Color" then fieldTypeError("Item.color", "Color or string", v) end
			item_col[t] = v
			syncItemField(t, "col", typ == "string" and v or tostring(GetColorValue(v)))
		end
	}
	lookup.colour = lookup.color

	-- Shortcut to item:getObject():create()
	function lookup:create(x, y)
		if not children[self] then methodCallError("Item:create", self) end
		if type(x) ~= "number" then typeCheckError("Item:create", 1, "x", "number", x) end
		if type(y) ~= "number" then typeCheckError("Item:create", 2, "y", "number", y) end
		return iwrap(GML.instance_create(x, y, obj_toID(item_object[self])))
	end
end

-----------------------------------------
-----------------------------------------
---Static-methods------------------------
-----------------------------------------
-----------------------------------------

Item = {}

do
	local function item_new(name)
		local context = GetModContext()
		contextVerify(all_items, name, context, "Item", 1)

		item_number = item_number + 1
		local nid = item_number
		GML.variable_global_set("item_number", AnyTypeArg(nid))

		-- Create new GMObject
		overrideModContext = "modLoaderCore"
		local newObj = Object.new(context.."_item_"..name)
		GMObject.setObjectType(newObj, "item")
		overrideModContext = nil
		local noid = obj_toID(newObj)
		GML.object_set_parent(noid, common_parent)
		GML.object_set_depth(noid, -99)

		-- Create new item
		local new = static.new(nid)
		-- Add to mod item table
		contextInsert(all_items, name, context, new)

		objids[new] = obj_toID(newObj)

		-- Set default item properties
		item_name[new] = name
		item_displayname[new] = name
		item_text[new] = ""
		item_sprite[new] = SpriteUtil.fromID(base_sprite)
		item_object[new] = newObj
		item_is_use[new] = false
		item_origin[new] = context
		item_col[new] = "w"
		item_callbacks[new] = {}

		-- GML side function which automatically initializes all item info and loads from the save
		GML.init_item(nid, name, noid, context)

		object_to_item[newObj] = new
		id_to_item[nid] = new

		return new
	end
	-- New item
	function Item.new(name)
		if type(name) ~= "string" then typeCheckError("Item.new", 1, "name", "string", name) end
		return item_new(name)
	end
	Item.find = contextSearch(all_items, "Item.find")
	Item.findAll = contextFindAll(all_items, "Item.findAll")
	setmetatable(Item, {__call = function(t, name)
		if type(name) ~= "string" then typeCheckError("Item", 1, "name", "string", name) end
		return item_new(name)
	end})
end

-- Find an item from its object
function Item.fromObject(object)
	if typeOf(object) ~= "GMObject" then typeCheckError("Item.fromObject", 1, "object", "GMObject", object) end
	return object_to_item[object]
end


-----------------------------------------
-----------------------------------------
---Misc----------------------------------
-----------------------------------------
-----------------------------------------

-- Wrap vanilla items
GML.array_open("item_info")
for i = 0, item_number do
	local n = static.new(i)
	item_name[n] = AnyTypeRet(GML.array_read_2(i, 0))
	item_displayname[n] = item_name[n]
	item_text[n] = AnyTypeRet(GML.array_read_2(i, 11))
	item_sprite[n] = SpriteUtil.fromID(AnyTypeRet(GML.array_read_2(i, 4)))
	objids[n] = AnyTypeRet(GML.array_read_2(i, 15))
	item_object[n] = obj_fromID(objids[n])
	item_is_use[n] = (AnyTypeRet(GML.array_read_2(i, 14)) == 1)
	item_col[n] = AnyTypeRet(GML.array_read_2(i, 17))
	item_origin[n] = "Vanilla"
	if i <= item_number - 11 then
		item_log_index[n] = i
	end
	item_callbacks[n] = {}
	all_items.vanilla[string.lower(item_name[n])] = n
	object_to_item[item_object[n]] = n
	id_to_item[i] = n
end
GML.array_close()

-- Handle callback
function SpecialCallbacks.item(callback, item, player, spec)
	item = object_to_item[obj_fromID(item)]
	local call = item_callbacks[item][callback]
	if not call then
		return
	else
		local args = {iwrap(player)}

		-- Use callback embryo status
		if callback == "use" then
			args[2] = spec == 1
		end

		for _, v in ipairs(call) do
			CallModdedFunction(v, args)
		end
	end
end

-- API internals table
RoRItem = {}
function RoRItem.toID(item)
	return ids[item]
end
function RoRItem.fromID(item)
	return id_to_item[item]
end
function RoRItem.toObjID(item)
	return obj_toID(item_object[item])
end
function RoRItem.fromObjID(item)
	return object_to_item[obj_fromID(item)]
end
function RoRItem.fromObj(item)
	return object_to_item[item]
end

-- Load ItemPool API
require("api/class/ItemPool")

-- env
mods.modenv.Item = Item
