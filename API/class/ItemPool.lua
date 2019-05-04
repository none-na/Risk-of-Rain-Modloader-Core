local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("ItemPool", true)

local all_pools
local pool_name = {}
local pool_origin = {}
local pool_from_id = {}
local pool_crate = {}

local item_toObjID = RoRItem.toObjID
local item_fromObjID = RoRItem.fromObjID

local crate_parent = GML.asset_get_index("pArtifact8Box")
do
	local function wrapPool(id, name, crate)
		local new = static.new(id)
		pool_name[new] = name
		pool_origin[new] = "vanilla"
		pool_from_id[id] = new
		if crate then
			pool_crate[new] = Object.find(crate, "vanilla")
		end
		return new
	end

	all_pools = {
		vanilla = {
			common = wrapPool(AnyTypeRet(GML.variable_global_get("_pool_white")), "common", "Artifact8Box1"),
			uncommon = wrapPool(AnyTypeRet(GML.variable_global_get("_pool_green")), "uncommon", "Artifact8Box2"),
			rare = wrapPool(AnyTypeRet(GML.variable_global_get("_pool_red")), "rare", "Artifact8Box3"),
			use = wrapPool(AnyTypeRet(GML.variable_global_get("_pool_use")), "use", "Artifact8BoxUse"),
			enigma = wrapPool(AnyTypeRet(GML.variable_global_get("_pool_enigma")), "enigma"),
			medcab = wrapPool(AnyTypeRet(GML.variable_global_get("_pool_medcab")), "medcab"),
			gunchest = wrapPool(AnyTypeRet(GML.variable_global_get("_pool_weapons")), "gunchest")
		}
	}
end


-- Static methods

ItemPool = {}

-- Create new item pool
local function new_pool(fname, name)
	if name ~= nil and type(name) ~= "string" then typeCheckError(fname, 1, "name", "string or nil", name) end
	local context = GetModContext()
	if name == nil then
		name = "[ItemPool" .. tostring(contextCount(all_pools, context)) .. "]"
	end
	contextVerify(all_pools, name, context, "ItemPool")
	local nid = GML.ds_list_create()
	local new = static.new(nid)
	contextInsert(all_pools, name, context, new)
	pool_name[new] = name
	pool_origin[new] = context
	pool_from_id[nid] = new
	return new
end

function ItemPool.new(name)
	return new_pool("ItemPool.new", name)
end
setmetatable(ItemPool, {__call = function(t, name)
	return new_pool("ItemPool", name)
end})

-- Find existing item pool
ItemPool.find = contextSearch(all_pools, "ItemPool.find")
ItemPool.findAll = contextFindAll(all_pools, "ItemPool.findAll")

mods.modenv.ItemPool = ItemPool

-- ItemPool methods

-- Add an item
function lookup:add(item)
	if not children[self] then methodCallError("ItemPool:add", self) end
	if typeOf(item) ~= "Item" then typeCheckError("ItemPool:add", 1, "item", "Item", item) end
	GML.item_pool_add(ids[self], item_toObjID(item))
end

-- Remove an item
function lookup:remove(item)
	if not children[self] then methodCallError("ItemPool:remove", self) end
	if typeOf(item) ~= "Item" then typeCheckError("ItemPool:remove", 1, "item", "Item", item) end
	GML.item_pool_remove(ids[self], item_toObjID(item))
end

-- Check for an item
function lookup:contains(item)
	if not children[self] then methodCallError("ItemPool:contains", self) end
	if typeOf(item) ~= "Item" then typeCheckError("ItemPool:contains", 1, "item", "Item", item) end
	return (GML.item_pool_has(ids[self], item_toObjID(item)) > 0)
end

-- Roll a random item
function lookup:roll()
	if not children[self] then methodCallError("ItemPool:roll", self) end
	return item_fromObjID(GML.item_roll(ids[self]))
end

-- Get command crate
local crate_pool_map = AnyTypeRet(GML.variable_global_get("_crate_inventory"))
function lookup:getCrate()
	if not children[self] then methodCallError("ItemPool:getCrate", self) end
	if pool_crate[self] then
		return pool_crate[self]
	else
		-- Generate new crate when none existing

		-- Create new GMObject
		overrideModContext = "modLoaderCore"
		local newObj = Object.new(pool_origin[self].."_pool_"..pool_name[self])
		overrideModContext = nil
		local noid = GMObject.toID(newObj)
		GML.object_set_parent(noid, crate_parent)
		GML.object_set_depth(noid, -1400)
		GML.ds_map_add(crate_pool_map, AnyTypeArg(noid), AnyTypeArg(ids[self]))

		-- Store it
		pool_crate[self] = newObj

		-- Return it
		return newObj
	end
end

function lookup:toList()
	if not children[self] then methodCallError("ItemPool:toList", self) end
	GML.item_pool_list(ids[self])
	local res = PopNumbers()
	for k, v in ipairs(res) do
		res[k] = item_fromObjID(v)
	end
	return res
end

function lookup:getName()
	if not children[self] then methodCallError("ItemPool:getName", self) end
	return pool_name[self]
end

function lookup:getOrigin()
	if not children[self] then methodCallError("ItemPool:getOrigin", self) end
	return pool_origin[self]
end

-- Ignores item locks
lookup.ignoreLocks = {
	get = function(t)
		return (GML.item_pool_get_ignore_droppable(ids[t]) > 0)
	end,
	set = function(t, v)
		if typeOf(v) ~= "boolean" then fieldTypeError("ItemPool.ignoreLocks", "boolean", v) end
		GML.item_pool_set_ignore_droppable(ids[t], v and 1 or 0)
	end
}

-- Ignores enigma
lookup.ignoreEnigma = {
	get = function(t)
		return (GML.item_pool_get_ignore_enigma(ids[t]) > 0)
	end,
	set = function(t, v)
		if typeOf(v) ~= "boolean" then fieldTypeError("ItemPool.ignoreEnigma", "boolean", v) end
		GML.item_pool_set_ignore_enigma(ids[t], v and 1 or 0)
	end
}

-- Is weighted
lookup.weighted = {
	get = function(t)
		return (GML.item_pool_get_weighted(ids[t]) > 0)
	end,
	set = function(t, v)
		if typeOf(v) ~= "boolean" then fieldTypeError("ItemPool.weighted", "boolean", v) end
		GML.item_pool_set_weighted(ids[t], v and 1 or 0)
	end
}

function lookup:setWeight(item, weight)
	if not children[self] then methodCallError("ItemPool:setWeight", self) end
	if typeOf(item) ~= "Item" then typeCheckError("ItemPool:setWeight", 1, "item", "Item", item) end
	if type(weight) ~= "number" then typeCheckError("ItemPool:setWeight", 2, "weight", "number", weight) end
	GML.item_pool_set_weight(ids[self], item_toObjID(item), weight)
end

function lookup:getWeight(item)
	if not children[self] then methodCallError("ItemPool:getWeight", self) end
	if typeOf(item) ~= "Item" then typeCheckError("ItemPool:getWeight", 1, "item", "Item", item) end
	return GML.item_pool_get_weight(ids[self], item_toObjID(item))
end


function RoRItem.poolFromID(id)
	return pool_from_id[id]
end
