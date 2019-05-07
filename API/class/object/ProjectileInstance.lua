-- Locals
local type = type
local typeOf = typeOf
local fastSet = GMInstance.fastSet
local iwrap = GMInstance.iwrap
local verifyInstCall = GMInstance.verifyInstCall

-- Class
local static, lookup, meta, ids, special, childeren = NewClass("ProjectileInstance", true, GMInstance.Instance)
meta.__tostring = __tostring_default_instance
GMInstance.ProjectileInstance = static

do
	-- Fire functions
	function lookup:fireBullet(x, y, direction, distance, damage, hitSprite, properties)
		if not childeren[self] then methodCallError("ProjectileInstance:fireBullet", self) end
		if type(x)           ~= "number" then typeCheckError("ProjectileInstance:fireBullet", 1, "x",         "number",         x) end
		if type(y)           ~= "number" then typeCheckError("ProjectileInstance:fireBullet", 2, "y",         "number",         y) end
		if type(direction)   ~= "number" then typeCheckError("ProjectileInstance:fireBullet", 3, "direction", "number", direction) end
		if type(distance)    ~= "number" then typeCheckError("ProjectileInstance:fireBullet", 4, "distance",  "number",  distance) end
		if type(damage)      ~= "number" then typeCheckError("ProjectileInstance:fireBullet", 5, "damage",    "number",    damage) end
		if typeOf(hitSprite) ~= "Sprite" and hitSprite  ~= nil then typeCheckError("ProjectileInstance:fireBullet", 6, "hitSprite",  "Sprite or nil",  hitSprite) end
		if type(properties)  ~= "number" and properties ~= nil then typeCheckError("ProjectileInstance:fireBullet", 7, "properties", "number or nil", properties) end
		verifyInstCall(ids[self])
		
		local ths = hitSprite and SpriteUtil.toID(hitSprite) or -1
		if isA(Object.findInstance(self:get("parent")), "ActorInstance") then
			return iwrap(GML.fire_bullet(self:get("parent"), x, y, direction, distance, damage, ths, properties or 0))
		else
			return misc.fireBullet(x, y, direction, distance, damage, self:get("team"), ths, properties or 0)
		end
	end

	function lookup:fireExplosion(x, y, width, height, damage, explosionSprite, hitSprite, properties)
		if not childeren[self] then methodCallError("ProjectileInstance:fireExplosion", self) end
		if type(x)                 ~= "number" then typeCheckError("ProjectileInstance:fireExplosion", 1, "x",      "number",      x) end
		if type(y)                 ~= "number" then typeCheckError("ProjectileInstance:fireExplosion", 2, "y",      "number",      y) end
		if type(width)             ~= "number" then typeCheckError("ProjectileInstance:fireExplosion", 3, "width",  "number",  width) end
		if type(height)            ~= "number" then typeCheckError("ProjectileInstance:fireExplosion", 4, "height", "number", height) end
		if type(damage)            ~= "number" then typeCheckError("ProjectileInstance:fireExplosion", 5, "damage", "number", damage) end
		if typeOf(explosionSprite) ~= "Sprite" and explosionSprite ~= nil then typeCheckError("ProjectileInstance:fireExplosion", 6, "explosionSprite", "Sprite or nil", explosionSprite) end
		if typeOf(hitSprite)       ~= "Sprite" and hitSprite       ~= nil then typeCheckError("ProjectileInstance:fireExplosion", 7, "hitSprite",       "Sprite or nil",       hitSprite) end
		if type(properties)        ~= "number" and properties      ~= nil then typeCheckError("ProjectileInstance:fireExplosion", 8, "properties",      "number or nil",      properties) end
		verifyInstCall(ids[self])
		
		local tes, ths = (explosionSprite and SpriteUtil.toID(explosionSprite) or -1), (hitSprite and SpriteUtil.toID(hitSprite) or -1)
		if isA(Object.findInstance(self:get("parent")), "ActorInstance") then
			return iwrap(GML.fire_explosion(self:get("parent"), x, y, width, height, damage, tes, ths, properties or 0))
		else
			return misc.fireExplosion(x, y, width, height, damage, self:get("team"), tes, ths, properties or 0)
		end
	end
	
	-- Kill signalling
	function lookup:kill(deathSprite, signal)
		if not childeren[self] then methodCallError("ProjectileInstance:fireExplosion", self) end
		if typeOf(deathSprite) ~= "Sprite" and deathSprite ~= nil then typeCheckError("ProjectileInstance:kill", 1, "deathSprite", "Sprite or nil", deathSprite) end
		if type(signal)        ~= "number" and signal      ~= nil then typeCheckError("ProjectileInstance:kill", 2, "signal",       "number or nil",     signal) end
		--???
		if signal and (signal <= 0) then error("Non-positive signal for ProjectileInstance:kill") end
		verifyInstCall(ids[self])
		
		if deathSprite then
			fastSet(ids[self], "sprite_index", SpriteUtil.toID(deathSprite))
			self:set("death_sprite", 1)
		end
		
		self:set("death_signal", signal or 1)
	end
	
	-- Custom set function
	local _set = lookup.set
	local allowed_types = {
		life   = "number",
		dead   = "number",
		parent = "number",
		vaccel = "number",
		haccel = "number",
	}
	local prohibited_types = {
		death_signal = "string",
		death_sprite = "string",
	}
	function lookup:set(varName, value)
		if allowed_types[varName]    and type(value) ~= allowed_types[varName]    then typeCheckError("ProjectileInstance:set", 2, "value", allowed_types[varName],              value) end
		if prohibited_types[varName] and type(value) == prohibited_types[varName] then typeCheckError("ProjectileInstance:set", 2, "value", "not " .. prohibited_types[varName], value) end
		if varName == "vaccel" then
			_set(self,"gravity", math.sqrt(value^2 + (self:get("haccel") or 0)^2))
			_set(self,"gravity_direction", math.deg(math.atan2(value, self:get("haccel"))))
		elseif varName == "haccel" then
			_set(self,"gravity", math.sqrt(value^2 + (self:get("vaccel") or 0)^2))
			_set(self,"gravity_direction", math.deg(math.atan2(self:get("haccel"), value)))
		elseif varName == "gravity" then
			_set(self,"haccel", value * math.cos(math.rad(self:get("gravity_direction"))))
			_set(self,"vaccel", value * math.sin(math.rad(self:get("gravity_direction"))))
		elseif varName == "gravity_direction" then
			_set(self,"haccel", self:get("gravity") * math.cos(math.rad(value)))
			_set(self,"vaccel", self:get("gravity") * math.sin(math.rad(value)))
		end
		return _set(self, varName, value)
	end

	-- Standard instance functions
	function lookup:getParent()
		if not childeren[self] then methodCallError("ProjectileInstance:getParent", self) end
		verifyInstCall(ids[self])
		
		local t = AnyTypeRet(GML.variable_instance_get(ids[self], "parent"))
		return ((t >= 0) and iwrap(t) or nil)
	end
end