
-- Pretty empty for now, needs stuff for things
-- especially the level editor but that thing is gonna take forever

local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Stage", true)
meta.__tostring = __tostring_default_namespace

local all_stages = {vanilla = {}}

local stage_name = {}
local stage_origin = {}
local stage_displayname = {}
local stage_subname = {}
local stage_list_interactable = {}
local stage_list_interactable_rarity = {}
local stage_list_enemy = {}

local id_to_stage = {}

------------------------------------------
-- COMMON	 ------------------------------
------------------------------------------

function lookup:getName()
	if not children[self] then methodCallError("Stage:getName", self) end

	return stage_name[self]
end

function lookup:getOrigin()
	if not children[self] then methodCallError("Stage:getOrigin", self) end

	return stage_origin[self]
end

lookup.displayName = {
	get = function(t)
		return stage_displayname[t] or stage_name[t]
	end,
	set = function(t, v)
		if type(v) ~= "string" then fieldTypeError("Stage.displayName", "string", v) end

		stage_displayname[t] = v
		GML.ds_map_replace(ids[t], AnyTypeArg("name"), AnyTypeArg(v))
	end
}

------------------------------------------
-- STAGE PROPERTIES ----------------------
------------------------------------------

lookup.subname = {
	get = function(t)
		return stage_subname[t]
	end,
	set = function(t, v)
		if type(v) ~= "string" then fieldTypeError("Stage.subname", "string", v) end
		stage_subname[t] = v
		GML.ds_map_replace(ids[t], AnyTypeArg("subname"), AnyTypeArg(v))
	end
}

lookup.disabled = {
	get = function(t)
		return AnyTypeRet(GML.ds_map_find_value(ids[t], AnyTypeArg("locked"))) == 1
	end,
	set = function(t, v)
		if type(v) ~= "boolean" then fieldTypeError("Stage.disabled", "boolean", v) end
		stage_subname[t] = v
		GML.ds_map_replace(ids[t], AnyTypeArg("locked"), AnyTypeArg(v and 1 or 0))
	end
}

------------------------------------------
-- INTERACTABLES -------------------------
------------------------------------------

function lookup:addInteractable(interactable)
	if not children[self] then methodCallError("Stage:addInteractable", self) end
	if typeOf(interactable) ~= "Interactable" then typeCheckError("Stage:addInteractable", 1, "interactable", "Interactable", interactable) end
	local list = stage_list_interactable[self]
	local iid = RoRInteractable.ids[interactable]
	if GML.ds_list_find_index(list, AnyTypeArg(iid)) < 0 then
		GML.ds_list_add(list, AnyTypeArg(iid))
		GML.ds_list_add(stage_list_interactable_rarity[self], AnyTypeArg(1))
	end
end

function lookup:removeInteractable(interactable)
	if not children[self] then methodCallError("Stage:removeInteractable", self) end
	if typeOf(interactable) ~= "Interactable" then typeCheckError("Stage:removeInteractable", 1, "interactable", "Interactable", interactable) end
	local list = stage_list_interactable[self]
	local iid = RoRInteractable.ids[interactable]
	local index = GML.ds_list_find_index(list, AnyTypeArg(iid))
	if index >= 0 then
		GML.ds_list_delete(list, index)
		GML.ds_list_delete(stage_list_interactable_rarity[self], index)
	end
end

function lookup:listInteractables()
	if not children[self] then methodCallError("Stage:listInteractables", self) end
	local r = {}
	local list = stage_list_interactable[self]
	for i = 0, GML.ds_list_size(list) - 1 do
		r[i + 1] = RoRInteractable.fromID[AnyTypeRet(GML.ds_list_find_value(list, i))]
	end
	return r
end

function lookup:getInteractableRarity(interactable)
	if not children[self] then methodCallError("Stage:getInteractableRarity", self) end
	if typeOf(interactable) ~= "Interactable" then typeCheckError("Stage:getInteractableRarity", 1, "interactable", "Interactable", interactable) end
	local list = stage_list_interactable[self]
	local iid = RoRInteractable.ids[interactable]
	local index = GML.ds_list_find_index(list, AnyTypeArg(iid))
	if index >= 0 then
		return AnyTypeRet(GML.ds_list_find_value(stage_list_interactable_rarity[self], index))
	else
		return 1
	end
end

function lookup:setInteractableRarity(interactable, rarity)
	if not children[self] then methodCallError("Stage:setInteractableRarity", self) end
	if typeOf(interactable) ~= "Interactable" then typeCheckError("Stage:setInteractableRarity", 1, "interactable", "Interactable", interactable) end
	if type(rarity) ~= "number" then typeCheckError("Stage:setInteractableRarity", 2, "rarity", "number", rarity) end
	local list = stage_list_interactable[self]
	local iid = RoRInteractable.ids[interactable]
	local index = GML.ds_list_find_index(list, AnyTypeArg(iid))
	if index >= 0 then
		GML.ds_list_replace(stage_list_interactable_rarity[self], index, AnyTypeArg(rarity))
	end
end

------------------------------------------
-- WRAP VANILLA STAGES -------------------
------------------------------------------

do
	local stage_id_list = {AnyTypeRet(GML.variable_global_get("stage_boar_beach"))}
	GML.array_open("levellist")
	for i = 1, 6 do
		local l = AnyTypeRet(GML.array_read_1(i))
		local size = GML.ds_list_size(l) - 1
		for j = 0, size do
			table.insert(stage_id_list, AnyTypeRet(GML.ds_list_find_value(l, j)))
		end
	end
	GML.array_close()

	for _, v in ipairs(stage_id_list) do
		local new = static.new(v)
		stage_name[new] = AnyTypeRet(GML.ds_map_find_value(v, AnyTypeArg("name")))
		stage_subname[new] = AnyTypeRet(GML.ds_map_find_value(v, AnyTypeArg("subname")))
		stage_list_interactable[new] = AnyTypeRet(GML.ds_map_find_value(v, AnyTypeArg("chests")))
		stage_list_interactable_rarity[new] = AnyTypeRet(GML.ds_map_find_value(v, AnyTypeArg("rarity")))
		stage_list_enemy[new] = AnyTypeRet(GML.ds_map_find_value(v, AnyTypeArg("enemies")))
		stage_origin[new] = "Vanilla"
		id_to_stage[v] = new
		all_stages.vanilla[stage_name[new]:lower()] = new
	end
end

------------------------------------------
-- GLOBAL FUNCTIONS ----------------------
------------------------------------------
Stage = {}
mods.modenv.Stage = Stage

Stage.find = contextSearch(all_stages, "Stage.find")
Stage.findAll = contextFindAll(all_stages, "Stage.findAll")

function Stage.getCurrentStage()
	if DisableInstanceInteraction then return end
	return id_to_stage[AnyTypeRet(GML.variable_global_get("stage_index"))]
end

function Stage.getDimensions()
	if DisableInstanceInteraction then return end
	return AnyTypeRet(GML.variable_global_get("room_width")), AnyTypeRet(GML.variable_global_get("room_height"))
end

function Stage.collidesPoint(x, y)
	if type(x) ~= "number" then typeCheckError("Stage.collidesPoint", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("Stage.collidesPoint", 2, "y", "number", y) end
	if DisableInstanceInteraction then return end
	return GML.map_point_collision(x, y) > 0
end

function Stage.collidesRectangle(x1, y1, x2, y2)
	if type(x1) ~= "number" then typeCheckError("Stage.collidesPoint", 1, "x1", "number", x1) end
	if type(y1) ~= "number" then typeCheckError("Stage.collidesPoint", 2, "y1", "number", y1) end
	if type(x2) ~= "number" then typeCheckError("Stage.collidesPoint", 3, "x2", "number", x2) end
	if type(y2) ~= "number" then typeCheckError("Stage.collidesPoint", 4, "y2", "number", y2) end
	if DisableInstanceInteraction then return end
	return GML.map_rect_collision(x1, y1, x2, y2) > 0
end
