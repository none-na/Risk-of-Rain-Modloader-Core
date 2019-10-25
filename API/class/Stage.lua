
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
local stage_map_interactable_rarity = {}
local stage_list_enemy = {}
local stage_list_rooms = {}

local id_to_stage = {}

-- Stage.progression but includes extended lists
local raw_progression = {}
local raw_progression_limit = AnyTypeRet(GML.variable_instance_get(GML_init_instance_id, "last_level")) + 1

RoRStage = {
	toGML = function(stage)
		return ids[stage]
	end,
	fromGML = function(stage)
		return id_to_stage[stage]
	end
}

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
		GML.ds_map_replace(ids[t], AnyTypeArg("locked"), AnyTypeArg(v and 1 or 0))
	end
}

lookup.music = {
	get = function(t)
		return Sound.fromID(AnyTypeRet(GML.ds_map_find_value(ids[t], AnyTypeArg("music"))))
	end,
	set = function(t, v)
		if typeOf(v) ~= "Sound" then fieldTypeError("Stage.music", "Sound", v) end
		GML.ds_map_replace(ids[t], AnyTypeArg("music"), AnyTypeArg(v.ID))
	end
}

lookup.enemies = {
	get = function(t)
		return stage_list_enemy[t]
	end
}

lookup.interactables = {
	get = function(t)
		return stage_list_interactable[t]
	end
}

lookup.interactableRarity = {
	get = function(t)
		return stage_map_interactable_rarity[t]
	end
}

------------------------------------------
-- GLOBAL FUNCTIONS ----------------------
------------------------------------------
Stage = {}
mods.modenv.Stage = Stage

Stage.progression = {}
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

function Stage.progressionLimit(value)
	if value ~= nil and type(value) ~= "number" then typeCheckError("Stage.progressionLimit", 1, "value", "number", value) end

	if value ~= nil then
		-- Setting
		raw_progression_limit = value
		GML.variable_instane_set(GML_init_instance_id, "last_level", AnyTypeArg(raw_progression_limit - 1))
		-- Add missing stage lists
		while #raw_progression < raw_progression_limit do
			local id = GML.ds_list_create()
			raw_progression[#raw_progression + 1] = dsWrapper.list(id, "Stage", RoRStage)
			GML.array_global_write_1("levellist", id)
		end
	end

	return raw_progression_limit
end

function Stage.getProgression(index)
	if type(index) ~= "number" then typeCheckError("Stage.getProgression", 1, "index", "number", index) end
	return raw_progression[index]
end

------------------------------------------
-- WRAP VANILLA STAGES -------------------
------------------------------------------

do

	local stage_id_list = {AnyTypeRet(GML.variable_global_get("stage_boar_beach"))}
	GML.array_open("levellist")
	for i = 1, 6 do
		local l = AnyTypeRet(GML.array_read_1(i))

		Stage.progression[i] = dsWrapper.list(l, "Stage", RoRStage)
		raw_progression[i] = Stage.progression[i]

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
		stage_list_interactable[new] = dsWrapper.list(AnyTypeRet(GML.ds_map_find_value(v, AnyTypeArg("chests"))), "Interactable", RoRInteractable)
		stage_map_interactable_rarity[new] = dsWrapper.map(AnyTypeRet(GML.ds_map_find_value(v, AnyTypeArg("rarity"))), "Interactable", RoRInteractable, nil, "number", nil, nil)
		stage_list_enemy[new] = dsWrapper.list(AnyTypeRet(GML.ds_map_find_value(v, AnyTypeArg("enemies"))), "Enemy", RoREnemy)
		stage_list_rooms[new] = dsWrapper.list(AnyTypeRet(GML.ds_map_find_value(v, AnyTypeArg("rooms"))), "Room", GMRoom)
		stage_origin[new] = "Vanilla"
		id_to_stage[v] = new
		all_stages.vanilla[stage_name[new]:lower()] = new
	end
end
