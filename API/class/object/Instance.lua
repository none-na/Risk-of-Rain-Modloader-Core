local GML = GML
local type = type
local typeOf = typeOf
local gmobj = GMObject
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Instance", true, nil)

__tostring_default_instance = function(obj)
	return "<instance " .. obj:getObject():getName() .. " " .. tostring(obj.id) .. ">"
end
meta.__tostring = __tostring_default_instance

-- Flag for when the game is still loading
DisableInstanceInteraction = true

-- Callback-local verified instances. Resets each callback call
VerifiedInstances = {}

-- Table of instance objects
local instance_object = GMInstance.instance_object

-- Checks whether a call to an instance reference is valid
local obj_locked = gmobj.locked
local function verifyInstCall(id)
	if not VerifiedInstances[id] then
		if GML.instance_exists(id) ~= 1 then
			error("attempt to access invalid instance reference, the instance no longer exists", 3)
		elseif DisableInstanceInteraction then
			error("attempt to access instance reference during game load, access is disabled", 3)
		elseif obj_locked[instance_object[self]] then
			error("attempt to access instance of a locked object", 3)
		end
		VerifiedInstances[id] = 1
	end
end

-- GML.variable_instance_get / set but with result caching
local AnyTypeArg = AnyTypeArg
local AnyTypeRet = AnyTypeRet
local function fastGet(id, key)
	return AnyTypeRet(GML.variable_instance_get(id, key))
end
local function fastSet(id, key, value)
	GML.variable_instance_set(id, key, AnyTypeArg(value))
end

-- Creates a new field from a GM field with a specific type
local function instanceVarField(fieldname, varname, valtype)
	return {
		get = function(t)
			verifyInstCall(ids[t])
			return fastGet(ids[t], varname)
		end,
		set = function(t, v)
			if type(v) ~= valtype then fieldTypeError(fieldname, valtype, v) end
			verifyInstCall(ids[t])
			fastSet(ids[t], varname, v)
		end
	}
end

-- Save static class for use in other APIs
GMInstance.Instance = static
GMInstance.verifyInstCall = verifyInstCall
GMInstance.fastGet = fastGet
GMInstance.fastSet = fastSet
GMInstance.IDs = ids

----------------
-- Management --
----------------

-- Checks if the instance reference is still valid
function lookup:isValid()
	if not children[self] then methodCallError("Instance:isValid", self) end
	return (GML.instance_exists(ids[self]) == 1)
end

local obj_nodestroy = gmobj.noDestroy
-- Destroys the instance
function lookup:destroy()
	if not children[self] then methodCallError("Instance:destroy", self) end
	if obj_nodestroy[instance_object[self]] then error("trying to destroy instance of a destroy-disabled object", 2) end
	local id = ids[self]
	verifyInstCall(id)
	if GML.instance_exists(id) == 0 then
		error("calling destroy method on already destroyed instance", 2)
	else
		VerifiedInstances[id] = nil
		GML.instance_destroy(ids[self], 1)
	end
end

-- Deletes the instance
function lookup:delete()
	if not children[self] then methodCallError("Instance:delete", self) end
	if obj_nodestroy[instance_object[self]] then error("trying to delete instance of a destroy-disabled object", 2) end
	local id = ids[self]
	verifyInstCall(id)
	if GML.instance_exists(id) == 0 then
		error("calling delete method on already destroyed instance", 2)
	else
		VerifiedInstances[id] = nil
		GML.instance_destroy(ids[self], 0)
	end
end

-----------------------
-- Getters / Setters --
-----------------------

-- Gets the object the instance came from
function lookup:getObject()
	if not children[self] then methodCallError("Instance:getObject", self) end
	verifyInstCall(ids[self])
	return instance_object[self]
end

-- Get a value from the instance
local unpack = table.unpack
function lookup:get(varName, varName2, ...)
	if not children[self] then methodCallError("Instance:get", self) end
	verifyInstCall(ids[self])
	if varName2 == nil then
		if type(varName) ~= "string" then typeCheckError("Instance:get", 1, "varName", "string", varName) end
		return fastGet(ids[self], varName)
	else
		local res = {}
		local id = ids[self]
		for k, v in ipairs({varName, varName2, ...}) do
			if type(v) ~= "string" then typeCheckError("Instance:get", k, "varName" .. tostring(k), "string", v) end
			res[k] = fastGet(id, v)
		end
		return unpack(res)
	end
end

-- Set a value in the instance
do
	local legalTypes = {number = true, string = true, ["nil"] = true}
	function lookup:set(varName, value)
		if not children[self] then methodCallError("Instance:set", self) end
		if type(varName) ~= "string" then typeCheckError("Instance:set", 1, "varName", "string", varName) end
		if not legalTypes[type(value)] then typeCheckError("Instance:set", 2, "value", "number, string, or nil", value) end
		verifyInstCall(ids[self])
		fastSet(ids[self], varName, value)
		return self
	end
end

-- Gets the InstanceAccessor for this instance
do
	local instance_accessors = setmetatable({}, {__mode = "kv"})
	function lookup:getAccessor()
		if not children[self] then methodCallError("Instance:getAccessor", self) end
		verifyInstCall(ids[self])
		if instance_accessors[self] then
			return instance_accessors[self]
		else
			local new = GMInstance.InstanceAccessor.new(ids[self])
			instance_accessors[self] = new
			return new
		end
	end
end

-- Get an alarm from the instance
function lookup:getAlarm(index)
	if not children[self] then methodCallError("Instance:getAlarm", self) end
	if type(index) ~= "number" then typeCheckError("Instance:getAlarm", 1, "index", "number", index) end
	verifyInstCall(ids[self])
	return GML.read_alarm(ids[self], index)
end

-- Sets an alarm in the instance
function lookup:setAlarm(index, value)
	if not children[self] then methodCallError("Instance:setAlarm", self) end
	if type(index) ~= "number" then typeCheckError("Instance:setAlarm", 1, "index", "number", index) end
	if type(value) ~= "number" then typeCheckError("Instance:setAlarm", 2, "value", "number", value) end
	verifyInstCall(ids[self])
	GML.write_alarm(ids[self], index, value)
	return self
end

------------------
-- Sprite Stuff --
------------------

local spr_id = SpriteUtil.fromID
local spr_2id = SpriteUtil.toID
lookup.sprite = {
	get = function(self)
		verifyInstCall(ids[self])
		return spr_id(fastGet(ids[self], "sprite_index"))
	end,
	set = function(self, v)
		if typeOf(v) ~= "Sprite" then fieldTypeError("Instance.sprite", "Sprite", v) end
		verifyInstCall(ids[self])
		fastSet(ids[self], "sprite_index", spr_2id(v))
	end
}
lookup.mask = {
	get = function(self)
		verifyInstCall(ids[self])
		return spr_id(fastGet(ids[self], "mask_index"))
	end,
	set = function(self, v)
		if v ~= nil and typeOf(v) ~= "Sprite" then fieldTypeError("Instance.mask", "Sprite or nil", v) end
		verifyInstCall(ids[self])
		if v == nil then
			fastSet(ids[self], "mask_index", -1)
		else
			fastSet(ids[self], "mask_index", spr_2id(v))
		end
	end
}
local col_obj = ConstructColorObject
local col_val = GetColorValue
lookup.blendColor = {
	get = function(self)
		verifyInstCall(ids[self])
		return col_obj(fastGet(ids[self], "image_blend"))
	end,
	set = function(self, v)
		if typeOf(v) ~= "Color" then fieldTypeError("Instance.blendColor", "Color", v) end
		verifyInstCall(ids[self])
		fastSet(ids[self], "image_blend", col_val(v))
	end
}
lookup.blendColour = lookup.blendColor
lookup.xscale = instanceVarField("Instance.xscale", "image_xscale", "number")
lookup.yscale = instanceVarField("Instance.yscale", "image_yscale", "number")
lookup.angle = instanceVarField("Instance.angle", "image_angle", "number")
lookup.alpha = instanceVarField("Instance.alpha", "image_alpha", "number")
lookup.spriteSpeed = instanceVarField("Instance.spriteSpeed", "image_speed", "number")
lookup.subimage = {
	get = function(self)
		verifyInstCall(ids[self])
		return fastGet(ids[self], "image_index") + 1
	end,
	set = function(self, v)
		if type(v) ~= "number" then fieldTypeError("Instance.subimage", "number", v) end
		verifyInstCall(ids[self])
		fastSet(ids[self], "image_index", v - 1)
	end
}
lookup.depth = instanceVarField("Instance.depth", "depth", "number")
lookup.visible = {
	get = function(self)
		verifyInstCall(ids[self])
		return fastGet(ids[self], "visible") >= 0.5
	end,
	set = function(self, v)
		if type(v) ~= "boolean" then fieldTypeError("Instance.visible", "boolean", v) end
		verifyInstCall(ids[self])
		fastSet(ids[self], "visible", v and 1 or 0)
	end
}

----------------
-- Misc Stuff --
----------------

local obj_id = gmobj.toID
-- Check for collisions against other objects or instances
function lookup:collidesWith(other, x, y)
	if not children[self] then methodCallError("Instance:collidesWith", self) end
	local otherType = typeOf(other)
	if not isA(other, "Instance") and otherType ~= "GMObject" then typeCheckError("Instance:collidesWith", 1, "other", "Instance or GMObject", other) end
	if type(x) ~= "number" then typeCheckError("Instance:collidesWith", 2, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("Instance:collidesWith", 3, "y", "number", y) end
	verifyInstCall(ids[self])
	local this = ids[self]
	if ids[other] then
		verifyInstCall(ids[other])
		return (GML.place_meeting(this, x, y, ids[other]) ~= 0)
	else
		return (GML.place_meeting(this, x, y, obj_id(other)) ~= 0)
	end
end

-- Check for collisions against the map
function lookup:collidesMap(x, y)
	if not children[self] then methodCallError("Instance:collidesMap", self) end
	if type(x) ~= "number" then typeCheckError("Instance:collidesMap", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("Instance:collidesMap", 2, "y", "number", y) end
	verifyInstCall(ids[self])
	return (GML.map_instance_collision(ids[self], x, y) > 0)
end

-- Coordinates
lookup.x = instanceVarField("Instance.x", "x", "number")
lookup.y = instanceVarField("Instance.y", "y", "number")

-- ID
lookup.id = {
	get = function(t) return ids[t] end
}
lookup.ID = lookup.id

do
	-- Hidden when advanced is false
	local blockedNames = {
		["bullet"] = true, -- Set by fire_bullet and fire_explosion on the GML side, but not useful.
		["player_id"] = true,
		["class"] = true,
		["buff_count"] = true,
		["chef_unlock"] = true,
		["item_count"] = true,
		["dead_body"] = true,
		
		["sprite_idle"] = true, -- All of these contain IDs and are utilized through ActorInstance:setActorSprite
		["sprite_walk"] = true, -- / ActorInstance:getActorSprite anyways so there's no use for them.
		["sprite_jump"] = true,
		["sprite_shoot1"] = true,
		["sprite_shoot1_1"] = true,
		["sprite_shoot1_2"] = true,
		["sprite_shoot2"] = true,
		["sprite_shoot2_1"] = true,
		["sprite_shoot2_2"] = true,
		["sprite_shoot3"] = true,
		["sprite_shoot3_1"] = true,
		["sprite_shoot3_2"] = true,
		["sprite_shoot4"] = true,
		["sprite_shoot4_1"] = true,
		["sprite_shoot4_2"] = true,
		["sprite_climb"] = true,
		["sprite_dead"] = true,
		["sprite_pal"] = true,
		["sprite_decoy"] = true,
		["sprite_death"] = true,
		["sprite_dead"] = true,
		["sprite_palette"] = true,
	}
	-- Always hidden
	local superBlockedNames = {
		["__object_index"] = true, -- Custom GMObject identity which should *never* be touched
		["__lua_activity_active_frame"] = true, -- Used on GML side for custom skill handling
		["__item_map"] = true, -- Player item inventory ds_map index
		["m_id"] = true, -- Multiplayer syncing ID
		["__custom_id"] = true,
		["player_set"] = true, -- Online coop junk
		["sock"] = true,
		["lag"] = true,
		["init"] = true, -- Director junk
		["initial_spawn"] = true,
	}
	-- Map of GML type to Lua type
	local typeMap = {
		["number"] = "number",
		["string"] = "string",
		["int32"] = "number",
		["int64"] = "number",
		["undefined"] = "nil",
	}	

	function lookup:dumpVariables(dumpValues, advanced)
		if not children[self] then methodCallError("Instance:dumpVariables", self) end
		if dumpValues ~= nil and type(dumpValues) ~= "boolean" then typeCheckError("Instance:dumpVariables", 1, "dumpValues", "boolean or nil", dumpValues) end
		if advanced ~= nil and type(advanced) ~= "boolean" then typeCheckError("Instance:dumpVariables", 2, "advanced", "boolean or nil", advanced) end
		verifyInstCall(ids[self])

		-- Function returns variable info in sets of name, type, value
		GML.GML_instance_dump_variables(ids[self])
		local data = PopStrings()
		
		local objName = self:getObject():getOrigin() .. ":".. self:getObject():getName()
		local out = "Instance variable dump for object " .. objName .. ", ID " .. tostring(self.ID) ..":"

		for i = #data, 1, -3 do
			local add = true
			local name = data[i]
			local typ = data[i - 1]
			local val = data[i - 2]
			
			-- Map the type name
			if typeMap[typ] then
				typ = typeMap[typ]
			else
				if not advanced then
					-- Filter unknown types when not advanced
					add = false
				else
					typ = "other (GML: " .. typ ..")"
				end
			end

			if add then
				-- Non-advanced only checks
				if not advanced then
					if name:len() == 1 then
						-- Filter 1 character names
						add = false
					elseif blockedNames[name] then
						-- Filter useless / blocked names
						add = false
					end
				end

				-- Advanced and non-advanced checks
				if add then
					if superBlockedNames[name] then
						add = false
					end
				end

				if add then
					-- Add the name to the list
					out = out .. "\n\t" .. name .. "\t" .. typ
					
					if dumpValues then
						--if type(val) == "number" then
							out = out .. "\t" .. val
						--[[elseif type(val) == "string" then
							out = out .. "\t" .. "\"" .. val .. "\""
						end]]
					end
				end
			end
		end
		GML.log_write(out, "dumpVariables " .. self:getObject():getOrigin() .. "-" .. self:getObject():getName(), 1)
		
		print("Successfully dumped variables for instance of type " .. objName)
	end
end


-- Load other instance classes
require "api/class/object/InstanceAccessor"
require "api/class/object/ActorInstance"
require "api/class/object/PlayerInstance"
require "api/class/object/DamagerInstance"
require "api/class/object/ItemInstance"
