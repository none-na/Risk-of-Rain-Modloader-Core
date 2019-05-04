
-- Create class
local static, lookup, meta, ids, special, children = NewClass("ObjectGroup", true)
meta.__tostring = __tostring_default_namespace

local all_groups = {vanilla = {}}
local group_origin = {}
local group_name = {}
local group_contents = {}
local group_managed_id = {}


local iwrap = GMInstance.iwrap

------------------------------------------
-- COMMON --------------------------------
------------------------------------------

function lookup:getName()
	if not children[self] then methodCallError("ObjectGroup:getName", self) end

	return group_name[self]
end

function lookup:getOrigin()
	if not children[self] then methodCallError("ObjectGroup:getOrigin", self) end

	return group_origin[self]
end

------------------------------------------
-- GROUP MANIPULATION --------------------
------------------------------------------

function lookup:add(...)
	if not children[self] then methodCallError("ObjectGroup:add", self) end
	if group_managed_id[self] then error("attempt to call method add on a vanilla object group, built-in group modification is unsupported", 3) end

	local args = {...}
	local contents = group_contents[self]

	for _, v in ipairs(args) do
		if typeOf(v) ~= "GMObject" then
			typeCheckError("ObjectGroup:add", k, "...", "GMObject", v)
		else
			if not contents[v] then
				GML.GML_objectgroup_add(ids[self], GMObject.toID(v))
				contents[v] = true
			end
		end
	end

end

function lookup:remove(...)
	if not children[self] then methodCallError("ObjectGroup:remove", self) end
	if group_managed_id[self] then error("attempt to call method remove on a vanilla object group, built-in group modification is unsupported", 3) end

	local args = {...}
	local contents = group_contents[self]

	for _, v in ipairs(args) do
		if typeOf(v) ~= "GMObject" then
			typeCheckError("ObjectGroup:remove", k, "...", "GMObject", v)
		else
			if contents[v] then
				GML.objectgroup_remove(ids[self], GMObject.toID(v))
				contents[v] = nil
			end
		end
	end
end

function lookup:contains(object)
	if not children[self] then methodCallError("ObjectGroup:contains", self) end
	if typeOf(object) ~= "GMObject" then typeCheckError("ObjectGroup:contains", 1, "object", "GMObject", object) end

	if group_managed_id[self] then
		return GML.object_is_ancestor(GMObject.toID(object), group_managed_id[self]) > 0
	else
		return group_contents[self][object] and true or false
	end
end

------------------------------------------
-- INSTANCE SEARCHING --------------------
------------------------------------------

function lookup:findAll()
	if not children[self] then methodCallError("ObjectGroup:findAll", self) end

	if group_managed_id[self] then
		GML.instance_find_all(group_managed_id[self])
	else
		GML.objectgroup_find_all(ids[self])
	end
	
	local res = PopNumbers()
	for k, v in ipairs(res) do
		res[k] = iwrap(v)
	end

	return res
end

function lookup:findNearest(x, y)
	if not children[self] then methodCallError("ObjectGroup:findNearest", self) end
	if type(x) ~= "number" then typeCheckError("ObjectGroup:findNearest", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("ObjectGroup:findNearest", 2, "y", "number", y) end

	local ti
	if group_managed_id[self] then
		ti = GML.instance_nearest(x, y, group_managed_id[self])
	else
		ti = GML.objectgroup_nearest(ids[self], x, y)
	end

	return (ti and ti > 0) and iwrap(ti) or nil
end

function lookup:findFurthest(x, y)
	if not children[self] then methodCallError("ObjectGroup:findFurthest", self) end
	if type(x) ~= "number" then typeCheckError("ObjectGroup:findFurthest", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("ObjectGroup:findFurthest", 2, "y", "number", y) end

	local ti
	if group_managed_id[self] then
		ti = GML.instance_furthest(x, y, group_managed_id[self])
	else
		ti = GML.objectgroup_furthest(ids[self], x, y)
	end

	return (ti and ti > 0) and iwrap(ti) or nil
end

local id_to_object = GMObject.ids_map
function lookup:toList(x, y)
	if not children[self] then methodCallError("ObjectGroup:toList", self) end

	if group_managed_id[self] then
		GML.GML_object_get_ancestors(group_managed_id[self])
		
		local ret = PopNumbers()
		local out = {}
		local i = 1
		for k, v in ipairs(ret) do
			local obj = id_to_object[v]
			if obj ~= nil then
				out[i] = obj
				i = i + 1
			end
		end
		
		return out
	else
		local ret = {}
		local i = 1
		for k, _ in pairs(group_contents[self]) do
			ret[i] = k
			i = i + 1
		end
		return ret
	end
end

do
	-- copy-pasted code yay
	local legalTypes = {number = true, string = true, ["nil"] = true}
	local legalOperators = {["=="] = true, ["~="] = true, ["<"] = true, [">"] = true, ["<="] = true, [">="] = true, };
	function lookup:findMatching(...)
		if not children[self] then methodCallError("ObjectGroup:findMatching", self) end

		local targs = {...}
		for i = 1, #targs, 2 do
			if type(targs[i]) ~= "string" then typeCheckError("ObjectGroup:findMatching", i, "key", "string", targs[i]) end
			if not legalTypes[type(targs[i + 1])] then typeCheckError("ObjectGroup:findMatching", i + 1, "value", "number, string, or nil", targs[i + 1]) end
		end

		PushCBArgs(targs)
		if group_managed_id[self] then
			GML.instance_find_matching(group_managed_id[self])
		else
			GML.objectgroup_find_matching(ids[self])
		end

		local res = PopNumbers()
		for k, v in ipairs(res) do
			res[k] = iwrap(v)
		end

		return res
	end

	function lookup:findMatchingOp(...)
		if not children[self] then methodCallError("ObjectGroup:findMatchingOp", self) end

		local targs = {...}
		for i = 1, #targs, 3 do
			if type(targs[i]) ~= "string" then typeCheckError("ObjectGroup:findMatchingOp", i, "key", "string", targs[i]) end
			if type(targs[i + 1]) ~= "string" then typeCheckError("ObjectGroup:findMatchingOp", i + 1, "value", "string", targs[i + 1]) end
			if not legalOperators[targs[i + 1]] then error("'" .. targs[i + 1] .. "' is not a known operator", 3) end
			if not legalTypes[type(targs[i + 2])] then typeCheckError("ObjectGroup:findMatchingOp", i + 2, "value", "number, string, or nil", targs[i + 2]) end
		end

		PushCBArgs(targs)
		if group_managed_id[self] then
			GML.instance_find_matching_op(group_managed_id[self])
		else
		 	GML.objectgroup_find_matching_op(ids[self])
		end

		local res = PopNumbers()
		for k, v in ipairs(res) do
			res[k] = iwrap(v)
		end

		return res
	end
end

function lookup:find(n)
	if not children[self] then methodCallError("ObjectGroup:find", self) end
	if type(n) ~= "number" then typeCheckError("ObjectGroup:find", 1, "n", "number", n) end

	local inst
	if group_managed_id[self] then
		inst = GML.instance_find(group_managed_id[self], n - 1)
	else
		inst = GML.objectgroup_find(ids[self], n - 1)
	end
	
	if inst > 0 then
		return iwrap(inst)
	else
		return nil
	end
end

function lookup:count()
	if not children[self] then methodCallError("ObjectGroup:count", self) end
	
	if group_managed_id[self] then
		return GML.instance_number(group_managed_id[self])
	else
		return GML.objectgroup_count(ids[self])
	end
end

------------------------------------------
-- BUILTIN GROUPS ------------------------
------------------------------------------

do
	local builtinIndex = 0
	local function create(name, parentName)
		builtinIndex = builtinIndex - 1
		local new = static.new(builtinIndex)

		group_origin[new] = "vanilla"
		group_name[new] = name
		group_managed_id[new] = GML.asset_get_index(parentName)

		all_groups.vanilla[string.lower(name)] = new
	end

	-- Actors
	create("actors", "pNPC")

	create("enemies", "pEnemy")
	create("classicEnemies", "pEnemyClassic")
	create("flyingEnemies", "pFlying")
	create("bosses", "pBoss")

	create("allies", "pFriend")
	create("drones", "pDrone")

	-- MapObjects
	create("mapObjects", "pMapObjects")
	create("droneItems", "pDroneItem")
	create("chests", "pChest")

	-- Misc
	create("items", "pItem")
	create("artifacts", "pArtifact")
	create("commandCrates", "pArtifact8Box")
end

------------------------------------------
-- STATIC METHODS ------------------------
------------------------------------------

ObjectGroup = {}

local function new_group(fname, name, ...)
	local tn = typeOf(name)
	if name ~= nil and tn ~= "string" and tn ~= "GMObject" then typeCheckError("Object.newGroup", 1, "name", "string", name) end
	
	local context = GetModContext()
	local realname
	if tn ~= "string" then 
		realname = "[ObjectGroup" .. tostring(contextCount(all_groups, context)) .. "]"
	else
		realname = name
	end
	contextVerify(all_groups, realname, context, "ObjectGroup")

	local args
	
	if tn == "GMObject" then
		args = {name, ...}
	else
		args = {...}
	end
	
	local contents = {}

	for _, v in ipairs(args) do
		if typeOf(v) ~= "GMObject" then
			typeCheckError("Object.newGroup", k + 1, "...", "GMObject", v)
		end
	end

	local nid = GML.objectgroup_create()
	local new = static.new(nid)

	for _, v in ipairs(args) do
		GML.GML_objectgroup_add(nid, GMObject.toID(v))
		contents[v] = true
	end

	group_origin[new] = context
	group_name[new] = realname
	group_contents[new] = contents

	contextInsert(all_groups, realname, context, new)

	return new
end

function ObjectGroup.new(name, ...)
	return new_group("ObjectGroup.new", name, ...)
end
setmetatable(ObjectGroup, {__call = function(t, name, ...)
	return new_group("ObjectGroup", name, ...)
end})

ObjectGroup.find = contextSearch(all_groups, "ObjectGroup.find")
ObjectGroup.findAll = contextFindAll(all_groups, "ObjectGroup.findAll")

deprecate(ObjectGroup, "class", "ObjectGroup", "ParentObject")

mods.modenv.ObjectGroup = ObjectGroup
