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
local object_cache                   = {}
local projectile_current_collisions  = {}

-- Environment
Projectile = {}
mods.modenv.Projectile = Projectile

do
	-- Triggers normal callbacks if they exist
	local function triggerCallback(self, callback, ...)
		local callbacks = projectile_callbacks[self]
		if not callbacks then return nil end
		callbacks = callbacks[callback]
		if not callbacks then return nil end
		for k,v in ipairs(callbacks) do
			v(...)
		end
	end
	
	-- Triggers collision callbacks if they exist
	local function triggerCollisionCallback(self, callback, group, ...)
		local callbacks = projectile_collision_callbacks[self]
		if not callbacks then return nil end
		callbacks = callbacks[group]
		if not callbacks then return nil end
		callbacks = callbacks[callback]
		if not callbacks then return nil end
		for k,v in ipairs(callbacks) do
			v(...)
		end
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
		object_cache[new] = {}
		
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
				if (not projectileInstance:get("death_sprite")) or (_life <= (-(((projectileInstance.sprite or { frames = 1 }).frames) / (projectileInstance.spriteSpeed or 1)) - 1)) then
					projectileInstance:destroy()
					return nil
				end
			end
			
			-- Not running logic if the projectile is dead
			if projectileInstance:get("dead") > 0 then return nil end
			
			-- step callback
			triggerCallback(new, "step", projectileInstance)
			if projectileInstance:get("death_signal") then return nil end
			
			-- Collisions and callbacks
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
		end)
		
		newObj:addCallback("draw", function(projectileInstance)
			triggerCallback(new, "draw", projectileInstance)
		end)
		
		newObj:addCallback("destroy", function(projectileInstance)
			-- Clean-up
			projectile_current_collisions[projectileInstance] = nil
			triggerCallback(new, "destroy", projectileInstance)
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
		["create"]  = true,
		["death"]   = true,
		["step"]    = true,
		["destroy"] = true,
		["draw"]    = true,
	}
	function lookup:addCallback(callback, bind)
		if not childeren[self] then methodCallError("Projectile:addCallback", self) end
		if type(callback) ~= "string"   then typeCheckError("Projectile:addCallback", 1, "callback", "string", callback) end
		if type(bind)     ~= "function" then typeCheckError("Projectile:addCallback", 2, "bind",     "function",   bind) end
		--???
		if not callbackNames[callback] then error("Invalid callback name for Projectile") end
		if projectile_callbacks[self][callback] == nil then projectile_callbacks[self][callback] = {} end
		table.insert(projectile_callbacks[self][callback], bind)
	end

	local function objectFromName(name)
		local name = string.lower(name)
		local parent = ParentObject.find(name)
		return parent and parent or Object.find(name)
	end
	local groupCallbackNames = {
		["entry"] = true,   -- projectileInstance [otherInstance]
		["exit"] = true,    -- projectileInstance [otherInstance]
		["collide"] = true, -- projectileInstance [otherInstance]
	}
	function lookup:addCollisionCallback(callback, objects, bind)
		if not childeren[self] then methodCallError("Projectile:addCollisionCallback", self) end
		if type(callback) ~= "string"   then typeCheckError("Projectile:addCollisionCallback", 1, "callback", "string", callback) end
		if type(bind)     ~= "function" then typeCheckError("Projectile:addCollisionCallback", 3, "bind",     "function",   bind) end
		
		--???
		-- This part needs a rework
		local is_string = type(objects) == "string"
		local is_map
		if (not is_string) and (not (type(objects) == "table")) then typeCheckError("Projectile:addCollisionCallback", 2, "objects", "table or string", objects) end
		local _objects = {}
		if is_string then
			local name = string.lower(objects)
			if name == "map" then
				is_map = true
			else
				table.insert(_objects, objectFromName(objects))
			end
		else
			for k,v in pairs(objects) do
				if type(v) == "string" then
					table.insert(_objects, objectFromName(v))
				elseif isA(v, "GMObjectBase") then
					table.insert(_objects, v)
				else
					--???
					-- Copied from typeCheckError
					error(string.format("bad argument #%i ('%s') to '%s' (%s expected, got %s)", 2, "objects", "Projectile:addCollisionCallback", "table of objects or table of object names", "table with " .. typeOf(v)), 3)
				end
			end
		end
		if not projectile_collision_callbacks[self] then projectile_collision_callbacks[self] = {} end
		if is_map then
			if not projectile_collision_callbacks[self]["map"] then projectile_collision_callbacks[self]["map"] = {} end
			if not projectile_collision_callbacks[self]["map"][callback] then projectile_collision_callbacks[self]["map"][callback] = {} end
			table.insert(projectile_collision_callbacks[self]["map"][callback], bind)
		else
			for k,v in ipairs(_objects) do
				if not projectile_collision_callbacks[self][v] then projectile_collision_callbacks[self][v] = {} end
				if not projectile_collision_callbacks[self][v][callback] then projectile_collision_callbacks[self][v][callback] = {} end
				table.insert(projectile_collision_callbacks[self][v][callback], bind)
				if not object_cache[self] then object_cache[self] = {} end
				table.insert(object_cache[self], v)
			end
		end
	end
	
	-- Fire
	function lookup:fire(parent, x, y, direction)
		if not childeren[self] then methodCallError("Projectile:fire", self) end
		if not isA(parent, "ActorInstance") then typeCheckError("Projectile:fire", 1, "parent", "ActorInstance", parent) end
		if type(x)         ~= "number" then typeCheckError("Projectile:fire", 2, "x", "number", x) end
		if type(y)         ~= "number" then typeCheckError("Projectile:fire", 3, "y", "number", y) end
		if type(direction) ~= "number" and direction ~= nil then typeCheckError("Projectile:fire", 4, "direction", "number or nil", direction) end
		
		local projectileInstance = iwrap(GML.instance_create(x,y, GMObject.toID(projectile_object[self])))
		
		:set("parent", parent.id)
		:set("team", parent:get("team"))
		:set("dead", 0)
		:set("vaccel", 0)
		:set("haccel", 0)
		
		projectileInstance.xscale = (direction ~= nil and direction ~= 0) and math.sign(direction) or (parent.xscale ~= 0 and math.sign(parent.xscale) or 1)
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