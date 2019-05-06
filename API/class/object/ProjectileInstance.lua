-- Locals
local type = type
local typeOf = typeOf
local fastSet = GMInstance.fastSet
local iwrap = GMInstance.iwrap
local verifyInstCall = GMInstance.verifyInstCall

-- Class
local static, lookup, meta, ids, special, childeren = NewClass("ProjectileInstance", true, GMInstance.Instance)
--???
meta.__tostring = __tostring_default_instance
GMInstance.ProjectileInstance = static

do
	-- Fire functions
	function lookup:fireBullet(direction, distance, damage, hitSprite, properties, x, y)
		if not childeren[self] then methodCallError("ProjectileInstance:fireBullet", self) end
		if type(direction)   ~= "number" then typeCheckError("ProjectileInstance:fireBullet", 1, "direction", "number", direction) end
		if type(distance)    ~= "number" then typeCheckError("ProjectileInstance:fireBullet", 2, "distance",  "number",  distance) end
		if type(damage)      ~= "number" then typeCheckError("ProjectileInstance:fireBullet", 3, "damage",    "number",    damage) end
		if typeOf(hitSprite) ~= "Sprite" and hitSprite  ~= nil then typeCheckError("ProjectileInstance:fireBullet", 4, "hitSprite",  "Sprite or nil",  hitSprite) end
		if tye(properties)   ~= "number" and properties ~= nil then typeCheckError("ProjectileInstance:fireBullet", 5, "properties", "number or nil", properties) end
		if type(x)           ~= "number" and x          ~= nil then typeCheckError("ProjectileInstance:fireBullet", 6, "x",          "number or nil",          x) end
		if type(y)           ~= "number" and y          ~= nil then typeCheckError("ProjectileInstance:fireBullet", 7, "y",          "number or nil",          y) end
		--???
		verifyInstCall(ids[self])
		
		local ths = hitSprite and SpriteUtil.toID(hitSprite) or -1
		return iwrap(GML.fire_bullet(self:get("parent"), x or self.x, y or self.y, direction, damage, ths, properties or 0))
	end

	function lookup:fireExplosion(width, height, damage, explosionSprite, hitSprite, properties, x, y)
		if not childeren[self] then methodCallError("ProjectileInstance:fireExplosion", self) end
		if type(width)             ~= "number" then typeCheckError("ProjectileInstance:fireExplosion", 1, "width",  "number",  width) end
		if type(height)            ~= "number" then typeCheckError("ProjectileInstance:fireExplosion", 2, "height", "number", height) end
		if type(damage)            ~= "number" then typeCheckError("ProjectileInstance:fireExplosion", 3, "damage", "number", damage) end
		if typeOf(explosionSprite) ~= "Sprite" and explosionSprite ~= nil then typeCheckError("ProjectileInstance:fireExplosion", 4, "explosionSprite", "Sprite or nil", explosionSprite) end
		if typeOf(hitSprite)       ~= "Sprite" and hitSprite       ~= nil then typeCheckError("ProjectileInstance:fireExplosion", 5, "hitSprite",       "Sprite or nil",       hitSprite) end
		if type(properties)        ~= "number" and properties      ~= nil then typeCheckError("ProjectileInstance:fireExplosion", 6, "properties",      "number or nil",      properties) end
		if type(x)                 ~= "number" and x               ~= nil then typeCheckError("ProjectileInstance:fireExplosion", 6, "x",               "number or nil",               x) end
		if type(y)                 ~= "number" and y               ~= nil then typeCheckError("ProjectileInstance:fireExplosion", 7, "y",               "number or nil",               y) end
		--???
		verifyInstCall(ids[self])
		
		local tes, ths = (explosionSprite and SpriteUtil.toID(explosionSprite) or -1), (hitSprite and SpriteUtil.toID(hitSprite) or -1)
		return iwrap(GML.fire_explosion(self:get("parent"), x or self.x, y or self.y, width, height, damage, tes, ths, properties or 0))
	end
	
	-- Kill signalling
	function lookup:kill(deathSprite, signal)
		if not childeren[self] then methodCallError("ProjectileInstance:fireExplosion", self) end
		if typeOf(deathSprite) ~= "Sprite" and deathSprite ~= nil then typeCheckError("ProjectileInstance:kill", 1, "deathSprite", "Sprite or nil", deathSprite) end
		if type(signal) ~= "number" and signal ~= nil then typeCheckError("ProjectileInstance:kill", 2, "signal", "number or nil", signal) end
		--???
		if signal and (signal <= 0) then error("Non-positive signal for ProjectileInstance:kill") end
		verifyInstCall(ids[self])
		
		if deathSprite then fastSet(ids[self], "sprite_index", SpriteUtil.toID(deathSprite)) end
		
		fastSet(ids[self], "death_signal", signal or 1)
	end
	
	-- Custom set function
	local _set = lookup.set
	local setvars = {
		vx     = "number",
		vy     = "number",
		ax     = "number",
		ay     = "number",
		life   = "number",
		dead   = "number",
		parent = "number",
	}
	function lookup:set(varName, value)
		if setvars[varName] and type(value) ~= setvars[varName] then typeCheckError("ProjectileInstance:set", 2, "value", setvars[varName], value) end
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