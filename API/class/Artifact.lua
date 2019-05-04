local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Artifact", true)
meta.__tostring = __tostring_default_namespace

Artifact = {}
mods.modenv.Artifact = Artifact

local all_artifacts = {vanilla = {}}

local artifact_name = {}
local artifact_displayname = {}
local artifact_fullname = {}
local artifact_description = {}
local artifact_sprite = {}
local artifact_menu_sprite = {}
local artifact_object = {}
local artifact_origin = {}
local artifact_enabled = {}

local object_to_artifact = {}

-----------------------------------------------------------------
-- STATIC -------------------------------------------------------
-----------------------------------------------------------------

Artifact.find = contextSearch(all_artifacts, "Artifact.find")
Artifact.findAll = contextFindAll(all_artifacts, "Artifact.findAll")

local default_sprite_pickup = SpriteUtil.fromID(GML.asset_get_index("sArtifact1"))
local default_sprite_loadout = SpriteUtil.fromID(GML.asset_get_index("sSelectArtifact1"))
local function artifact_new(name)
	local context = GetModContext()
	contextVerify(all_artifacts, name, context, "Artifact", 1)

	local new = static.new(GML.artifact_add(name, context))
	
	artifact_name[new] = name
	artifact_displayname[new] = name
	artifact_fullname[new] = "Artifact of " .. name
	artifact_description[new] = ""
	artifact_object[new] = nil
	artifact_sprite[new] = default_sprite_pickup
	artifact_menu_sprite[new] = default_sprite_loadout
	--GML.array_global_write_2("artifact_info", 99, ids[self], 4)
	artifact_origin[new] = context
	artifact_enabled[new] = true
	
	contextInsert(all_artifacts, name, context, new)
	
	return new
end

function Artifact.new(name)
	if type(name) ~= "string" then typeCheckError("Artifact.new", 1, "name", "string", name) end
	return artifact_new(name)
end

setmetatable(Artifact, {__call = function(t, name)
	if type(name) ~= "string" then typeCheckError("Artifact", 1, "name", "string", name) end
	return artifact_new(name)
end})

function Artifact.fromObject(object)
	if typeOf(object) ~= "GMObject" then typeCheckError("Artifact.fromObject", 1, "object", "GMObject", object) end
	return object_to_artifact[object]
end

-----------------------------------------------------------------
-- METHODS ------------------------------------------------------
-----------------------------------------------------------------

-- Standard stuff
function lookup:getName()
	if not children[self] then methodCallError("Artifact:getName", self) end
	return artifact_name[self]
end

function lookup:getOrigin()
	if not children[self] then methodCallError("Artifact:getOrigin", self) end
	return artifact_origin[self]
end

local pickup_parent = GML.asset_get_index("pArtifact")
local pickup_id_map = AnyTypeRet(GML.variable_global_get("artifact_object_to_id"))
function lookup:getObject()
	if not children[self] then methodCallError("Artifact:getObject", self) end
	if artifact_object[self] then
		return artifact_object[self]
	else
		-- Create new GMObject
		overrideModContext = "modLoaderCore"
		local newObj = Object.new(artifact_origin[self] .. "_artifact_" .. artifact_name[self])
		overrideModContext = nil
		local noid = GMObject.toID(newObj)
		GML.object_set_parent(noid, pickup_parent)
		GML.object_set_depth(noid, -99)
		GML.ds_map_add(pickup_id_map, AnyTypeArg(noid), AnyTypeArg(ids[self]))
		
		GML.array_global_write_2("artifact_info", AnyTypeArg(noid), ids[self], 3)
		--GML.object_set_sprite(noid, SpriteUtil.fromID(artifact_sprite[self]))
		newObj.sprite = artifact_sprite[self]
		
		artifact_object[self] = newObj
		object_to_artifact[newObj] = self

		return newObj
	end
end

-----------------------------------------------------------------
-- FIELDS -------------------------------------------------------
-----------------------------------------------------------------

-- Standard stuff
lookup.displayName = {
	get = function(self)
		return artifact_displayname[self]
	end,
	set = function(self, value)
		if type(value) ~= "string" then fieldTypeError("Artifact.displayName", "string", value) end
		GML.array_global_write_2("artifact_info", AnyTypeArg(value), ids[self], 0)
		artifact_displayname[self] = value
		lookup.pickupName.set(self, "Artifact of " .. value)
	end
}

-- Artifact stuff
lookup.pickupName = {
	get = function(self)
		return artifact_fullname[self]
	end,
	set = function(self, value)
		if type(value) ~= "string" then fieldTypeError("Artifact.pickupName", "string", value) end
		GML.array_global_write_2("artifact_info", AnyTypeArg(value), ids[self], 6)
		artifact_fullname[self] = value
	end
}

lookup.pickupSprite = {
	get = function(self)
		return artifact_sprite[self]
	end,
	set = function(self, value)
		if typeOf(value) ~= "Sprite" then fieldTypeError("Artifact.pickupSprite", "Sprite", value) end
		local spid = SpriteUtil.toID(value)
		GML.array_global_write_2("artifact_info", AnyTypeArg(spid), ids[self], 4)
		if artifact_object[self] then
			artifact_object[self].sprite = value
		end
		artifact_sprite[self] = value
	end
}

lookup.active = {
	get = function(self)
		return GML.artifact_get_active(ids[self]) == 1
	end,
	set = function(self, value)
		if typeOf(value) ~= "boolean" then fieldTypeError("Artifact.active", "boolean", value) end
		GML.artifact_set_active(ids[self], value and 1 or 0)
	end
}

lookup.unlocked = {
	get = function(self)
		return GML.artifact_get_unlocked(ids[self]) == 1
	end,
	set = function(self, value)
		if typeOf(value) ~= "boolean" then fieldTypeError("Artifact.unlocked", "boolean", value) end
		GML.artifact_set_unlocked(ids[self], value and 1 or 0)
	end
}

lookup.disabled = {
	get = function(self)
		return not artifact_enabled[self]
	end,
	set = function(self, value)
		if type(value) ~= "boolean" then fieldTypeError("Artifact.disabled", "boolean", value) end
		GML.array_global_write_2("artifact_info", AnyTypeArg(value and 0 or 1), ids[self], 8)
		artifact_enabled[self] = not value
	end
}

lookup.loadoutSprite = {
	get = function(self)
		return artifact_menu_sprite[self]
	end,
	set = function(self, value)
		if typeOf(value) ~= "Sprite" then fieldTypeError("Artifact.loadoutSprite", "Sprite", value) end
		local spid = SpriteUtil.toID(value)
		GML.array_global_write_2("artifact_info", AnyTypeArg(spid), ids[self], 7)
		artifact_menu_sprite[self] = value
	end
}

lookup.loadoutText = {
	get = function(self)
		return artifact_description[self]
	end,
	set = function(self, value)
		if type(value) ~= "string" then fieldTypeError("Artifact.loadoutText", "string", value) end
		GML.array_global_write_2("artifact_info", AnyTypeArg(value), ids[self], 1)
		artifact_description[self] = value
	end
}

-----------------------------------------------------------------
-----------------------------------------------------------------
-----------------------------------------------------------------

-- Wrap Vanilla
GML.array_open("artifact_info")
for i = 0, 9 do
	local new = static.new(i)
	artifact_name[new] = AnyTypeRet(GML.array_read_2(i, 5))
	artifact_displayname[new] = AnyTypeRet(GML.array_read_2(i, 0))
	artifact_fullname[new] = AnyTypeRet(GML.array_read_2(i, 6))
	artifact_description[new] = AnyTypeRet(GML.array_read_2(i, 1))
	artifact_object[new] = GMObject.fromID(AnyTypeRet(GML.array_read_2(i, 3)))
	object_to_artifact[artifact_object[new]] = new
	artifact_sprite[new] = SpriteUtil.fromID(AnyTypeRet(GML.array_read_2(i, 4)))
	artifact_menu_sprite[new] = SpriteUtil.fromID(AnyTypeRet(GML.array_read_2(i, 7)))
	artifact_origin[new] = "Vanilla"
	artifact_enabled[new] = true
	all_artifacts.vanilla[artifact_name[new]:lower()] = new
end
GML.array_close()
