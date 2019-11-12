
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
	toID = function(stage)
		return ids[stage]
	end,
	fromID = function(stage)
		return id_to_stage[stage]
	end
}

-- Used for updating map of room -> stage for online coop
local room_map_id = AnyTypeRet(GML.variable_global_get("levelmap"))
local room_list_to_stage = {}
local function stageRoomAdded(list, room)
	local roomID = GMRoom.toID(room)
	local oldValue = AnyTypeRet(GML.ds_map_find_value(room_map_id, AnyTypeArg(roomID)))
	if oldValue ~= nil then
		error("room is already in use by another stage (" .. tostring(id_to_stage[oldValue]) .. ")", 3)
	else
		GML.ds_map_replace(room_map_id, AnyTypeArg(roomID), AnyTypeArg(ids[room_list_to_stage[list]]))
	end
end
local function stageRoomRemoved(list, room)
	GML.ds_map_delete(room_map_id, AnyTypeArg(GMRoom.toID(room)))
end

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

lookup.rooms = {
	get = function(t)
		return stage_list_rooms[t]
	end
}

lookup.teleporterIndex = {
	get = function(t)
		return AnyTypeRet(GML.ds_map_find_value(ids[t], AnyTypeArg("tp")))
	end,
	set = function(t, v)
		if type(v) ~= "number" then fieldTypeError("Stage.teleporterIndex", "number", v) end
		GML.ds_map_replace(ids[t], AnyTypeArg("tp"), AnyTypeArg(v))
	end,
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
	verifyIngame("Stage.getCurrentStage")
	return id_to_stage[AnyTypeRet(GML.variable_global_get("stage_index"))]
end

function Stage.getDimensions()
	return AnyTypeRet(GML.variable_global_get("room_width")), AnyTypeRet(GML.variable_global_get("room_height"))
end

function Stage.collidesPoint(x, y)
	if type(x) ~= "number" then typeCheckError("Stage.collidesPoint", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("Stage.collidesPoint", 2, "y", "number", y) end
	return GML.map_point_collision(x, y) > 0
end

function Stage.collidesRectangle(x1, y1, x2, y2)
	if type(x1) ~= "number" then typeCheckError("Stage.collidesPoint", 1, "x1", "number", x1) end
	if type(y1) ~= "number" then typeCheckError("Stage.collidesPoint", 2, "y1", "number", y1) end
	if type(x2) ~= "number" then typeCheckError("Stage.collidesPoint", 3, "x2", "number", x2) end
	if type(y2) ~= "number" then typeCheckError("Stage.collidesPoint", 4, "y2", "number", y2) end
	return GML.map_rect_collision(x1, y1, x2, y2) > 0
end

function Stage.progressionLimit(value)
	if value ~= nil and type(value) ~= "number" then typeCheckError("Stage.progressionLimit", 1, "value", "number", value) end

	if value ~= nil then
		-- Setting
		raw_progression_limit = value
		GML.variable_instance_set(GML_init_instance_id, "last_level", AnyTypeArg(raw_progression_limit - 1))
		-- Add missing stage lists
		while #raw_progression < raw_progression_limit do
			local id = GML.ds_list_create()
			raw_progression[#raw_progression + 1] = dsWrapper.list(id, "Stage", RoRStage)
			GML.array_global_write_1("levellist", AnyTypeArg(id), #raw_progression)
		end
	end

	return raw_progression_limit
end

function Stage.getProgression(index)
	if type(index) ~= "number" then typeCheckError("Stage.getProgression", 1, "index", "number", index) end
	return raw_progression[index]
end

function Stage.transport(stage)
	verifyIngame("Stage.transport")
	if typeOf(stage) ~= "Stage" then typeCheckError("Stage.transport", 1, "stage", "Stage", stage) end
	GML.stage_goto(ids[stage])
end

------------------------------------------
-- CONSTRUCTOR ---------------------------
------------------------------------------

do
	local function new_stage(fname, name)
		if type(name) ~= "string" then typeCheckError(fname, 1, "name", "string", name, 1) end
		local context = GetModContext()

		contextVerify(all_stages, name, context, "Stage", 1)

		local nid = GML.ds_map_create()
		local new = static.new(nid)
		contextInsert(all_stages, name, context, new)

		local enemy_list = GML.ds_list_create()
		local interactable_list = GML.ds_list_create()
		local rarity_map = GML.ds_map_create()
		local room_list = GML.ds_list_create()

		stage_name[new] = name
		stage_origin[new] = context
		stage_subname[new] = ""
		stage_list_interactable[new] = dsWrapper.list(interactable_list, "Interactable", RoRInteractable)
		stage_map_interactable_rarity[new] = dsWrapper.map(AnyTypeRetrarity_map, "Interactable", RoRInteractable, nil, "number", nil, nil)
		stage_list_enemy[new] = dsWrapper.list(enemy_list, "Enemy", RoREnemy)
		stage_list_rooms[new] = dsWrapper.list(room_list, "Room", GMRoom, nil, stageRoomAdded, stageRoomRemoved)

		room_list_to_stage[stage_list_rooms[new]] = new
		id_to_stage[nid] = new

		GML.ds_map_replace(nid, AnyTypeArg("name"), AnyTypeArg(name))
		GML.ds_map_replace(nid, AnyTypeArg("subname"), AnyTypeArg(""))
		GML.ds_map_replace(nid, AnyTypeArg("enemies"), AnyTypeArg(enemy_list))
		GML.ds_map_replace(nid, AnyTypeArg("rooms"), AnyTypeArg(room_list))
		GML.ds_map_replace(nid, AnyTypeArg("chests"), AnyTypeArg(interactable_list))
		GML.ds_map_replace(nid, AnyTypeArg("rarity"), AnyTypeArg(rarity_map))
		GML.ds_map_replace(nid, AnyTypeArg("tp"), AnyTypeArg(6))

		return new
	end

	function Stage.new(name)
		return new_stage("Stage.new", name)
	end
	setmetatable(Stage, {__call = function(t, name)
		return new_stage("Stage", name)
	end})
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
		stage_list_enemy[new] = dsWrapper.list(AnyTypeRet(GML.ds_map_find_value(v, AnyTypeArg("enemies"))), "MonsterCard", RoRMonsterCard)
		stage_list_rooms[new] = dsWrapper.list(AnyTypeRet(GML.ds_map_find_value(v, AnyTypeArg("rooms"))), "Room", GMRoom, nil, stageRoomAdded, stageRoomRemoved)
		stage_origin[new] = "Vanilla"
		room_list_to_stage[stage_list_rooms[new]] = new
		id_to_stage[v] = new
		all_stages.vanilla[stage_name[new]:lower()] = new
	end
end
