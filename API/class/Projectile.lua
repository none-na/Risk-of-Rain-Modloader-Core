-- Locals
local type = type
local typeOf = typeOf
local iwrap = GMInstance.iwrap

-- Class
local static, lookup, meta, ids, special, childeren = NewClass("Projectile", false)
--???
meta.__tostring = __tostring_default_namespace
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
local group_cache = {}
local projectile_current_collisions = {}
local projectile_initialized = {}

-- Exports
Projectile = {}
mods.modenv.Projectile = Projectile

do
	-- Triggers normal callbacks if they exist
	local function triggerCallback(self, callback, ...)
		if projectile_callbacks[self][callback] then
			for k,v in ipairs(projectile_callbacks[self][callback]) do
				v(...)
			end
		end
	end
	
	-- Triggers collision callbacks if they exist
	local function triggerCollisionCallback(self, callback, group, ...)
		local callbacks = projectile_collision_callbacks[self][callback]
		if callbacks then
			callbacks = callbacks[group]
			if callbacks then
				for k,v in ipairs(callbacks) do
					v(...)
				end
			end
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
		group_cache[new] = {}
		
		newObj:addCallback("create", function()
			triggerCallback(new, "onInit", projectileInstance)
		end)
		newObj:addCallback("step", function(projectileInstance)
		
			-- Initialization and onCreate
			if not projectile_initialized[projectileInstance] then
				projectile_current_collisions[projectileInstance] = {}

				projectileInstance:set("dead", 0)

				projectileInstance:set("vx", 0)
				projectileInstance:set("vy", 0)
				projectileInstance:set("ax", 0)
				projectileInstance:set("ay", 0)

				projectile_initialized[projectileInstance] = true
				
				triggerCallback(new, "onCreate", projectileInstance)
			end
			
			-- Checking if the projectile should be dead
			local _signal = projectileInstance:get("death_signal")
			if _signal and (projectileInstance:get("dead") <= 0) then
				projectileInstance.subimage = 1
				projectileInstance:set("life", 0)
				projectileInstance:set("dead", _signal)
				projectileInstance:set("death_signal", nil)
				triggerCallback(new, "onDeath", projectileInstance)
			end
			
			-- Handling life and post-death state
			local _life = projectileInstance:get("life") - 1
			projectileInstance:set("life", _life)
			if _life <= 0 then
				if projectileInstance:get("dead") <= 0 then
					projectileInstance:kill(new.deathSprite)
				else
					if _life <= (-(((projectileInstance.sprite or { frames = 1 }).frames) / (projectileInstance.spriteSpeed or 1)) - 1) then
						projectileInstance:destroy()
						return nil
					end
				end
			end
			
			-- Not running logic if the projectile is dead
			if projectileInstance:get("dead") > 0 then return nil end
			
			-- onStep
			triggerCallback(new, "onStep", projectileInstance)
			
			-- Collision storage and callbacks for groups
			for groupName,group in pairs(group_cache[new]) do
				for _,object in ipairs(group:toList()) do
					if not projectile_current_collisions[projectileInstance][groupName] then
						projectile_current_collisions[projectileInstance][groupName] = {}
					end
					for _,instance in ipairs(object:findAll()) do
						local _vx, _vy = projectileInstance:get("vx", "vy")
						local _hcollision = projectileInstance:collidesWith(instance, projectileInstance.x + _vx, projectileInstance.y)
						local _vcollision = projectileInstance:collidesWith(instance, projectileInstance.x, projectileInstance.y + _vy)
						local _xdirection = _hcollision and math.sign(_vx) or 0
						local _ydirection = _vcollision and math.sign(_vy) or 0
						if (_hcollision or _vcollision) then
							if not projectile_current_collisions[projectileInstance][groupName][instance] then
								triggerCollisionCallback(new, "onEntry", groupName, projectileInstance, instance, _xdirection, _ydirection)
							end
							triggerCollisionCallback(new, "onCollide", groupName, projectileInstance)
							projectile_current_collisions[projectileInstance][groupName][instance] = true
						else
							if projectile_current_collisions[projectileInstance][groupName][instance] then
								triggerCollisionCallback(new, "onExit", groupName, projectileInstance, instance, _xdirection, _ydirection)
							end
							projectile_current_collisions[projectileInstance][groupName][instance] = nil
						end
					end
				end
			end
			
			-- Collision storage and callbacks for map
			local _vx, _vy = projectileInstance:get("vx", "vy")
			local _hcollision = projectileInstance:collidesMap(projectileInstance.x + _vx, projectileInstance.y)
			local _vcollision = projectileInstance:collidesMap(projectileInstance.x, projectileInstance.y + _vy)
			local _xdirection = _hcollision and math.sign(_vx) or 0
			local _ydirection = _vcollision and math.sign(_vy) or 0
			if (_hcollision or _vcollision) then
				if not projectile_current_collisions[projectileInstance]["map"] then
					triggerCollisionCallback(new, "onEntry", "map", projectileInstance, _xdirection, _ydirection)
				end
				triggerCollisionCallback(new, "onCollide", "map", projectileInstance)
				projectile_current_collisions[projectileInstance]["map"] = true
			else
				if projectile_current_collisions[projectileInstance]["map"] then
					triggerCollisionCallback(new, "onExit", "map", projectileInstance, _xdirection, _ydirection)
				end
				projectile_current_collisions[projectileInstance]["map"] = nil
			end
			
			-- Movement
			local _vx, _vy = projectileInstance:get("vx", "vy")
			projectileInstance.x = projectileInstance.x + _vx
			projectileInstance.y = projectileInstance.y + _vy
			projectileInstance:set("vx", _vx + projectileInstance:get("ax"))
			projectileInstance:set("vy", _vy + projectileInstance:get("ay"))
		end)
		newObj:addCallback("destroy", function(projectileInstance)
		
			-- Clean-up
			projectile_current_collisions[projectileInstance] = nil
			projectile_initialized[projectileInstance] = nil
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
		if not isA(instance, "Instance") then typeCheckError("Projectile.fromInstance", 1, "instance", "Instance", instance) end
		return object_to_projectile[instance:getObject()]
	end
	setmetatable(Projectile, { __call = function(t, name) return Projectile.new(name) end } )
end

do
	-- Callbacks functions
	local callbackNames = {
		["onInit"] = true,
		["onCreate"] = true,
		["onDeath"] = true,
		["onStep"] = true,
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

	local groupCallbackNames = {
		["onEntry"] = true,   -- projectileInstance [otherInstance] xdirection ydirection
		["onExit"] = true,    -- projectileInstance [otherInstance] xdirection ydirection
		["onCollide"] = true, -- projectileInstance [otherInstance]
	}
	function lookup:addCollisionCallback(callback, group, bind)
		if not childeren[self] then methodCallError("Projectile:addCollisionCallback", self) end
		if type(callback) ~= "string"   then typeCheckError("Projectile:addCollisionCallback", 1, "callback", "string", callback) end
		if type(group)    ~= "string"   then typeCheckError("Projectile:addCollisionCallback", 2, "group",    "string",    group) end
		if type(bind)     ~= "function" then typeCheckError("Projectile:addCollisionCallback", 3, "bind",     "function",   bind) end
		
		local group_name = string.lower(group)
		if group_name ~= "map" then group = ObjectGroup.find(group) end
		
		--???
		if group == nil then error("Invalid group name for Projectile") end
		if not groupCallbackNames[callback] then error("Invalid callback name for Projectile") end
		
		if projectile_collision_callbacks[self][callback] == nil then projectile_collision_callbacks[self][callback] = {} end
		if projectile_collision_callbacks[self][callback][group_name] == nil then projectile_collision_callbacks[self][callback][group_name] = {} end
		table.insert(projectile_collision_callbacks[self][callback][group_name], bind)
		if group_name ~= "map" then group_cache[self][group_name] = group end
	end
	
	-- Fire
	function lookup:fire(parent, x, y, direction)
		if not childeren[self] then methodCallError("Projectile:fire", self) end
		if not isA(parent, "ActorInstance") then typeCheckError("Projectile:fire", 1, "parent", "ActorInstance", parent) end
		if type(x)         ~= "number" then typeCheckError("Projectile:fire", 2, "x", "number", x) end
		if type(y)         ~= "number" then typeCheckError("Projectile:fire", 3, "y", "number", y) end
		if type(direction) ~= "number" and direction ~= nil then typeCheckError("Projectile:fire", 4, "direction", "number or nil", direction) end
		
		local projectileInstance = iwrap(GML.instance_create(x,y, GMObject.toID(projectile_object[self])))
		projectileInstance:set("parent", parent.id)
		projectileInstance.xscale = (direction ~= nil and direction ~= 0) and math.sign(direction) or (parent.xscale ~= 0 and math.sign(parent.xscale) or 1)
		
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
		if not children[self] then methodCallError("Projectile:getObject", self) end
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