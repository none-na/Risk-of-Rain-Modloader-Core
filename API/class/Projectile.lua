-- Locals
local type = type
local typeOf = typeOf
local iwrap = GMInstance.iwrap

-- Class
local static, lookup, meta, ids, special, childeren = NewClass("Projectile", false)
meta.__tostring = __tostring_default_namespace

-- Creation
local projectile_number = 0
local all_projectiles = {}

-- Projectile Information
local projectile_name                = {}
local projectile_origin              = {}
local projectile_sprite              = {}
local projectile_death_sprite        = {}
local projectile_object              = {}
local object_to_projectile           = {}

-- Callbacks
local projectile_callbacks           = {}
local projectile_collision_callbacks = {}
--local object_cache                   = {}
local projectile_current_collisions  = {}

-- Environment
Projectile = {}
mods.modenv.Projectile = Projectile

do
	-- Triggers normal callbacks if they exist
	local function triggerCallback(object, name, ...)
		local pc = projectile_callbacks
		if pc[object] and pc[object][name] then
			for _,bind in ipairs(pc[object][name]) do
				bind(...)
			end
		end
	end
	
	-- Triggers collision callbacks if they exist
	local function triggerCollisionCallback(object, name, group, ...)
		local pcc = projectile_collision_callbacks
		if pcc[object] and pcc[object][group] and pcc[object][group][name] then
			for _,bind in ipairs(pcc[object][group][name]) do
				bind(...)
			end
		end
	end
	
	local function killed(instance)
		return (not instance:isValid()) or (instance:get("dead") > 0) or (instance:get("death_signal") ~= nil)
	end

	-- New projectile
	local function projectile_new(name)
		local context = GetModContext()
		if not name then name = "[Projectile_" .. tostring(contextCount(all_projectiles, context)) .. "]" end
		contextVerify(all_projectiles, name, context, "Projectile", 1)
		
		projectile_number = projectile_number + 1
		local nid = projectile_number
		
		local new = static.new(nid)
		contextInsert(all_projectiles, name, context, new)
		
		local newObj = Object.new(context.."_projectile_"..name)
		GMObject.setObjectType(newObj, "projectile")
		
		projectile_name[new] = name
		projectile_origin[new] = context
		projectile_callbacks[new] = {}
		projectile_collision_callbacks[new] = {}
		projectile_sprite[new] = nil
		projectile_death_sprite[new] = nil
		projectile_object[new] = newObj
		object_to_projectile[newObj] = new
		--object_cache[new] = {}
		
		newObj:addCallback("step", function(projectileInstance)	
			-- Checking if the projectile should be dead and isn't
			local _signal = projectileInstance:get("death_signal")
			if _signal and (projectileInstance:get("dead") <= 0) then
				projectileInstance.subimage = 1
				projectileInstance:set("life", 0)
				projectileInstance:set("dead", _signal)
				projectileInstance:set("speed", 0)
				projectileInstance:set("gravity", 0)
				projectileInstance:set("death_signal", nil)
				triggerCallback(new, "death", projectileInstance)
			end
			
			-- Handling life and post-death state
			local _life = projectileInstance:get("life")
			if _life then
				_life = _life - 1
				projectileInstance:set("life", _life)
				if (_life <= 0) and (projectileInstance:get("dead") <= 0) then
					projectileInstance:kill(new.deathSprite)
				end
			end
			if projectileInstance:get("dead") > 0 then
				local frames = projectileInstance.sprite and projectileInstance.sprite.frames or 1
				if (not projectileInstance:get("death_sprite")) or (_life <= (-(frames / (projectileInstance.spriteSpeed or 1)) - 1)) then
					projectileInstance:destroy()
					return nil
				end
			end
			
			-- Not running logic if the projectile is dead
			if killed(projectileInstance) then return nil end
			
			-- step callback
			triggerCallback(new, "step", projectileInstance)
			if killed(projectileInstance) then return nil end
			
			-- Collisions and callbacks
			--[[
			if object_cache[new] then
				for _,object in ipairs(object_cache[new]) do
					if not projectile_current_collisions[projectileInstance][object] then projectile_current_collisions[projectileInstance][object] = {} end
					for _,instance in ipairs(object:findAll()) do
						if projectileInstance:collidesWith(instance, projectileInstance.x, projectileInstance.y) then
							if not projectile_current_collisions[projectileInstance][object][instance] then
								triggerCollisionCallback(new, "entry", object, projectileInstance, instance)
								if projectileInstance:get("death_signal") then return nil end
								projectile_current_collisions[projectileInstance][object][instance] = true
							end
							triggerCollisionCallback(new, "collide", object, projectileInstance, instance)
							if projectileInstance:get("death_signal") then return nil end
						elseif projectile_current_collisions[projectileInstance][object][instance] then
							triggerCollisionCallback(new, "exit", object, projectileInstance, instance)
							if projectileInstance:get("death_signal") then return nil end
							projectile_current_collisions[projectileInstance][object][instance] = nil
						end
					end
				end
			end
			--]]
			
			--[[
			if projectileInstance:collidesMap(projectileInstance.x, projectileInstance.y) then
				if not projectile_current_collisions[projectileInstance]["map"] then
					triggerCollisionCallback(new, "entry", "map", projectileInstance)
					if projectileInstance:get("death_signal") then return nil end
					projectile_current_collisions[projectileInstance]["map"] = true
				end
				triggerCollisionCallback(new, "collide", "map", projectileInstance)
				if projectileInstance:get("death_signal") then return nil end
			elseif projectile_current_collisions[projectileInstance]["map"] then
				triggerCollisionCallback(new, "exit", "map", projectileInstance)
				if projectileInstance:get("death_signal") then return nil end
				projectile_current_collisions[projectileInstance]["map"] = nil
			end
			--]]
			
			-- Collisions and collision callback triggering
			-- The next line should be ran once or maybe twice for most projectiles
			local current_collisions = projectile_current_collisions[projectileInstance]
			for object,callbacks in pairs(projectile_collision_callbacks[new]) do
				if object == "map" then
					local previous_state = current_collisions["map"]
					local current_state = projectileInstance:collidesMap(projectileInstance.x, projectileInstance.y)
					if current_state then
						if not previous_state then
							triggerCollisionCallback(new, "entry", "map", projectileInstance)
							if killed(projectileInstance) then return nil end
							current_collisions["map"] = true
						end
						triggerCollisionCallback(new, "collide", "map", projectileInstance)
						if killed(projectileInstance) then return nil end
					elseif previous_state then
						triggerCollisionCallback(new, "exit", "map", projectileInstance)
						if killed(projectileInstance) then return nil end
						current_collisions["map"] = nil
					end
				else
					for _,instance in ipairs(object:findAll()) do
						local previous_state = current_collisions[instance]
						local current_state = projectileInstance:collidesWith(instance, projectileInstance.x, projectileInstance.y)
						if current_state then
							if not previous_state then
								triggerCollisionCallback(new, "entry", object, projectileInstance, instance)
								if killed(projectileInstance) then return nil end
								current_collisions[instance] = true
							end
							triggerCollisionCallback(new, "collide", object, projectileInstance, instance)
							if killed(projectileInstance) then return nil end
						elseif previous_state then
							triggerCollisionCallback(new, "exit", object, projectileInstance, instance)
							if killed(projectileInstance) then return nil end
							current_collisions[instance] = nil
						end
					end
				end
			end
		end)
		
		newObj:addCallback("draw", function(projectileInstance)
			triggerCallback(new, "draw", projectileInstance)
			if killed(projectileInstance) then return nil end
		end)
		
		newObj:addCallback("destroy", function(projectileInstance)
			-- Clean-up
			projectile_current_collisions[projectileInstance] = nil
			triggerCallback(new, "destroy", projectileInstance)
			if killed(projectileInstance) then return nil end
		end)
		
		return new
	end
	
	-- Standard class functions
	function Projectile.new(name)
		if name ~= nil and type(name) ~= "string" then typeCheckError("Projectile.new", 1, "name", "string or nil", name) end
		return projectile_new(name)
	end
	Projectile.find = contextSearch(all_projectiles, "Projectile.find")
	Projectile.findAll = contextFindAll(all_projectiles, "Projectile.findAll")
	function Projectile.fromObject(object)
		if typeOf(object) ~= "GMObject" then typeCheckError("Projectile.fromObject", 1, "object", "GMObject", object) end
		return object_to_projectile[object]
	end
	function Projectile.fromInstance(instance)
		if not isA(instance, "ProjectileInstance") then typeCheckError("Projectile.fromInstance", 1, "instance", "Instance", instance) end
		return object_to_projectile[instance:getObject()]
	end
	setmetatable(Projectile, { __call = function(t, name) return Projectile.new(name) end } )
	
	-- Callbacks functions
	local callbackNames = {
		["create"]  = true, -- projectileInstance
		["death"]   = true, -- projectileInstance
		["step"]    = true, -- projectileInstance
		["destroy"] = true, -- projectileInstance
		["draw"]    = true, -- projectileInstance
	}
	local callbacks_str
	do
		local names = {}
		for name,_ in pairs(callbackNames) do
			names[#names + 1] = string.format('"%s"', name)
		end
		callbacks_str = table.concat(names, " or ")
	end
	function lookup:addCallback(callback, bind)
		if not childeren[self] then methodCallError("Projectile:addCallback", self) end
		if type(callback) ~= "string"  then typeCheckError("Projectile:addCallback", 1, "callback", "string",      callback) end
		if not callbackNames[callback] then typeCheckError("Projectile:addCallback", 1, "callback", callbacks_str, callback) end
		if type(bind) ~= "function"    then typeCheckError("Projectile:addCallback", 2, "bind",     "function",        bind) end
		if projectile_callbacks[self][callback] == nil then
			projectile_callbacks[self][callback] = {}
		end
		table.insert(projectile_callbacks[self][callback], bind)
	end

	local function objectFromName(name)
		local parent = ParentObject.find(name)
		return parent or Object.find(name)
	end
	local groupCallbackNames = {
		["entry"] = true,   -- projectileInstance, [otherInstance]
		["exit"] = true,    -- projectileInstance, [otherInstance]
		["collide"] = true, -- projectileInstance, [otherInstance]
	}
	local gcallbacks_str
	do
		local names = {}
		for name,_ in pairs(groupCallbackNames) do
			names[#names + 1] = string.format('"%s"', name)
		end
		gcallbacks_str = table.concat(names, " or ")
	end
	function lookup:addCollisionCallback(callback, objects, bind)
		if not childeren[self] then methodCallError("Projectile:addCollisionCallback", self) end
		if type(callback) ~= "string"       then typeCheckError("Projectile:addCollisionCallback", 1, "callback", "string",       callback) end
		if not groupCallbackNames[callback] then typeCheckError("Projectile:addCollisionCallback", 1, "callback", gcallbacks_str, callback) end
		if type(bind) ~= "function"         then typeCheckError("Projectile:addCollisionCallback", 3, "bind",     "function",         bind) end
		
		local objects_error
		local valid_objects = {}
		if objects == "map" then
			table.insert(valid_objects, "map")
		elseif type(objects) == "string" then
			local object = objectFromName(objects)
			if object then
				table.insert(valid_objects, object)
			else
				objects_error = true
			end
		elseif isA(objects, "GMObjectBase") then
			table.insert(valid_objects, objects)
		elseif type(objects) == "table" then
			for _,object in pairs(objects) do
				if isA(object, "GMObjectBase") then
					table.insert(valid_objects, object)
				elseif type(object) == "string" then
					local from_name = objectFromName(object)
					if from_name then
						table.insert(valid_objects, from_name)
					else
						objects_error = true
						break
					end
				else
					objects_error = true
					break
				end
			end
		else
			objects_error = true
		end
		
		if objects_error then
			typeCheckError("Projectile:addCollisionCallback", 2, "objects", "\"map\" or GMObjectBase or table of GMObjectBases", objects)
		end
		
		local pcc = projectile_collision_callbacks
		if not pcc[self] then
			pcc[self] = {}
		end
		for _,object in ipairs(valid_objects) do
			if not pcc[self][object] then
				pcc[self][object] = {}
			end
			if not pcc[self][object][callback] then
				pcc[self][object][callback] = {}
			end
			table.insert(pcc[self][object][callback], bind)
		end
	end
	
	-- Fire
	function lookup:fire(x, y, parent, direction)
		if not childeren[self] then methodCallError("Projectile:fire", self) end
		if type(x)         ~= "number" then typeCheckError("Projectile:fire", 1, "x", "number", x) end
		if type(y)         ~= "number" then typeCheckError("Projectile:fire", 2, "y", "number", y) end
		if not isA(parent, "ActorInstance") and parent ~= nil then typeCheckError("Projectile:fire", 3, "parent", "ActorInstance", parent) end
		if type(direction) ~= "number" and direction ~= nil then typeCheckError("Projectile:fire", 4, "direction", "number or nil", direction) end
	
		local projectileInstance = iwrap(GML.instance_create(x,y, GMObject.toID(projectile_object[self])))
		
		:set("parent", parent and parent.id or -1)
		:set("team", parent and parent:get("team") or "neutral")
		:set("damage", parent and parent:get("damage") or 0)
		:set("dead", 0)
		:set("vaccel", 0)
		:set("haccel", 0)
		
		projectileInstance.xscale = (direction ~= nil and direction ~= 0) and math.sign(direction) or ((parent and parent.xscale ~= 0) and math.sign(parent.xscale) or 1)
		projectileInstance:set("direction", 90 * (1 - projectileInstance.xscale))
		
		projectile_current_collisions[projectileInstance] = {}
		
		triggerCallback(self, "create", projectileInstance)
		return projectileInstance
	end
	
	-- Standard class functions
	function lookup:getOrigin()
		if not childeren[self] then methodCallError("Projectile:getOrigin", self) end
		return projectile_origin[self]
	end
	
	function lookup:getName()
		if not childeren[self] then methodCallError("Projectile:getName", self) end
		return projectile_name[self]
	end
	
	function lookup:getObject()
		if not childeren[self] then methodCallError("Projectile:getObject", self) end
		return projectile_object[self]
	end
	
	-- Sprites
	lookup.sprite = {
		get = function(t)
			return projectile_sprite[t]
		end,
		set = function(t, v)
			if typeOf(v) ~= "Sprite" then fieldTypeError("Projectile.sprite", "Sprite", v) end
			projectile_sprite[t] = v
			projectile_object[t].sprite = v
		end,
	}
	
	lookup.deathSprite = {
		get = function(t)
			return projectile_death_sprite[t]
		end,
		set = function(t, v)
			if typeOf(v) ~= "Sprite" then fieldTypeError("Projectile.deathSprite", "Sprite", v) end
			projectile_death_sprite[t] = v
		end,
	}
end