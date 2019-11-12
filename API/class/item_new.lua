
local GMClass = require 'util/GMClass'

local ITEM_ARRAY = "item_info"

local ids = GMClass.ids

-- Chunky methods
local method_setTier
do
	local common = AnyTypeRet(GML.variable_global_get("_pool_white"))
	local uncommon = AnyTypeRet(GML.variable_global_get("_pool_green"))
	local rare = AnyTypeRet(GML.variable_global_get("_pool_red"))
	local use = AnyTypeRet(GML.variable_global_get("_pool_use"))
	local pools = {common, uncommon, rare, use}
	local pool = {common = common, uncommon = uncommon, rare = rare, use = use}
	local col = {common = "w", uncommon = "g", rare = "r", use = "or"}
	function method_setTier(self, tier)
		tier = string.lower(tier)
		if not pool[tier] then error("'" .. tier .. "' is not a valid item tier (common, uncommon, rare, or use)", 3) end
		-- Get the object ID of the item
		local objid = GML.array_global_read_2(ITEM_ARRAY, ids[self], 15)
		-- Remove the item from all pool
		for _, v in ipairs(pools) do GML.item_pool_remove(v, objid) end
		-- Add the item to the correct pool
		GML.item_pool_add(pool[tier], objid)
		-- Set the item's colour
		GML.array_global_write_2(ITEM_ARRAY, AnyTypeArg(col[tier]), ids[self], 17)
	end		
end

local method_setLog
do
	local log_list = AnyTypeRet(GML.variable_global_get("item_info_list"))
	local log_fields = {
		group = -1,
		description = 1,
		priority = 2,
		destination = 5,
		date = 7,
		story = 8
	}
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
	function method_setLog(self, args)
		if typeOf(args) ~= "table" then typeCheckError("Item:setLog", 1, "args", "named arguments", args) end

		-- Do this early on to avoid beginning to write fields when invalid group is passed
		local raw_group = rawget(args, "group")
		if type(raw_group) == "string" and not log_categories[raw_group] then error("'"..raw_group.."' is not a known item log group", 3) end

		GML.array_open(ITEM_ARRAY)
		local iid = ids[self]
		for k, _ in pairs(args) do
			if log_fields[k] then
				local v = rawget(args, k)
				if type(v) ~= "string" then GML.array_close() typeCheckError("Item:setLog", 1, "args."..tostring(k), "string", v, 1) end
				if log_fields[k] ~= -1 then GML.array_write_2(iid, log_fields[k], AnyTypeArg(v)) end
			end
		end
		local old_index = GML.ds_list_find_index(log_list, AnyTypeArg(iid))
		if old_index < 0 then GML.array_write_2(iid, 13, AnyTypeArg(1)) end
		-- Change group
		if raw_group then
			-- Remove existing log
			if old_index >= 0 then
				GML.ds_list_delete(log_list, old_index)
				for k, v in pairs(log_categories) do
					if v >= old_index then
						log_categories[k] = v - 1
					end
				end
			end
			local group = math.min(log_categories[raw_group], GML.ds_list_size(log_list) - 1)
			for k, v in pairs(log_categories) do
				if v >= group then
					log_categories[k] = v + 1
				end
			end
			GML.ds_list_insert(log_list, group, AnyTypeArg(iid))
			if not args.priority then
				GML.array_write_2(iid, 2, AnyTypeArg(log_default_priority[raw_group] or ""))
			end
		end
		GML.array_close()
	end
end

local function getter_color(self)
	local val = AnyTypeRet(GML.array_global_write_2(ITEM_ARRAY, ids[self], 17))
	if val:match("%d+") == val then
		return ConstructColorObject(val)
	else
		return val
	end
end
local function setter_color(self, value)
	local typ = typeOf(value)
	if typ ~= "string" and typ ~= "Color" then fieldTypeError("Item.color", "Color or string", value) end
	GML.array_global_write_2(ITEM_ARRAY, AnyTypeArg(typ == "string" and value or tostring(GetColorValue(gml))), ids[self], 17)
end

local function getter_use_cooldown(self)
	return GML.item_get_cooldown(AnyTypeRet(GML.array_global_read_2(ITEM_ARRAY, ids[self], 15)))
end
local function setter_use_cooldown(self, value)
	if type(value) ~= "number" then fieldTypeError("Item.useCooldown", "number", value) end
	GML.item_set_cooldown(AnyTypeRet(GML.array_global_read_2(ITEM_ARRAY, ids[self], 15)), value)
end

-- Item log class which overlaps with normal item class
local logClass = GMClass{
	-- Class properties ------------
	"ItemLog", "ArrayClass",
	arrayName = ITEM_ARRAY,

	-- Fields ----------------------
	--               Kind     Id  Type
	description = {  "f",     1 , "string"  },
	priority    = {  "f",     2 , "string"  },
	destination = {  "f",     5 , "string"  },
	date        = {  "f",     7 , "string"  },
	story       = {  "f",     8 , "string"  },
	-- Copy of item fields 
	displayName = {  "f",     0 , "string"  },
	sprite      = {  "f",     4 , "Sprite"  },
}

-- Main item class
return GMClass{
	-- Class properties ------------
	"Item", "ArrayClass",
	arrayName = ITEM_ARRAY,
	nameIndex = 10,
	originIndex = 9,

	-- Fields ----------------------
	--               Kind     Id  Type
	displayName = {  "f",     0 , "string"  },
	pickupText  = {  "f",     11, "string"  },
	isUseItem   = {  "f",     14, "boolean" },
	sprite      = {  "f",     4 , "Sprite"  },
	object      = {  "f",     15, "GMObject",  "r"},

	useCooldown = {  "lf", getter_use_cooldown, setter_use_cooldown },
	color       = {  "lf", getter_color, setter_color },
	colour      = {  "a", "color"},

	-- Methods ---------------------
	getLog      = { "l", function(self) return logClass(ids[self]) end},
	create      = { "l", function(self) return self.object:create(x, y) end, {{"x", "number"}, {"y", "number"}}},
	setTier     = { "l", method_setTier, {{"tier", "string"}} },
	setLog      = { "l", method_setLog, {{"args", "table"}} },

	-- Deprecated ------------------
	getObject = { "l", function(self) return self.object end },
}
