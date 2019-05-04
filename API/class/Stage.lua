
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
