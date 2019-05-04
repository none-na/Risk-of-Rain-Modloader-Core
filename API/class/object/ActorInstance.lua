local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("ActorInstance", true, GMInstance.Instance)
meta.__tostring = __tostring_default_instance
GMInstance.ActorInstance = static

local iwrap = GMInstance.iwrap
local verifyInstCall = GMInstance.verifyInstCall

local function noBuiltinError(method)
	error("method "..method.." does not work on instances of built-in actors", 3)
end
--if self:getObject():getOrigin() == "vanilla" then noBuiltinError() end



-----------------------------------------------
----------------------------------- SHOOTING --
-----------------------------------------------
-----------------------------------------------

-- Get the facing direction
function lookup:getFacingDirection()
	if not children[self] then methodCallError("ActorInstance:getFacingDirection", self) end
	local tcompare = AnyTypeRet(GML.variable_instance_get(ids[self], "image_xscale"))
	-- This is the exact same math the game uses for getting facing directions
	return (90 - (90 * tcompare))
end

-- Shoot bulllet
function lookup:fireBullet(x, y, direction, distance, damage, hitSprite, properties)
	if not children[self] then methodCallError("ActorInstance:fireBullet", self) end
	if type(x) ~= "number" then typeCheckError("ActorInstance:fireBullet", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("ActorInstance:fireBullet", 2, "y", "number", y) end
	if type(direction) ~= "number" then typeCheckError("ActorInstance:fireBullet", 3, "direction", "number", direction) end
	if type(distance) ~= "number" then typeCheckError("ActorInstance:fireBullet", 4, "distance", "number", distance) end
	if type(damage) ~= "number" then typeCheckError("ActorInstance:fireBullet", 5, "damage", "number", damage) end
	if typeOf(hitSprite) ~= "Sprite" and hitSprite ~= nil then typeCheckError("ActorInstance:fireBullet", 6, "hitSprite", "Sprite or nil", hitSprite) end
	if type(properties) ~= "number" and properties ~= nil then typeCheckError("ActorInstance:fireBullet", 7, "properties", "number or nil", properties) end
	verifyInstCall(ids[self])
	local ths = hitSprite and SpriteUtil.toID(hitSprite) or -1
	return iwrap(GML.fire_bullet(ids[self], x, y, direction, distance, damage, ths, properties or 0))
end

-- Shoot explosion
function lookup:fireExplosion(x, y, width, height, damage, explosionSprite, hitSprite, properties)
	if not children[self] then methodCallError("ActorInstance:fireExplosion", self) end
	if type(x) ~= "number" then typeCheckError("ActorInstance:fireExplosion", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("ActorInstance:fireExplosion", 2, "y", "number", y) end
	if type(width) ~= "number" then typeCheckError("ActorInstance:fireExplosion", 3, "width", "number", width) end
	if type(height) ~= "number" then typeCheckError("ActorInstance:fireExplosion", 4, "height", "number", height) end
	if type(damage) ~= "number" then typeCheckError("ActorInstance:fireExplosion", 5, "damage", "number", damage) end
	if typeOf(explosionSprite) ~= "Sprite" and explosionSprite ~= nil then typeCheckError("ActorInstance:fireExplosion", 6, "explosionSprite", "Sprite or nil", explosionSprite) end
	if typeOf(hitSprite) ~= "Sprite" and hitSprite ~= nil then typeCheckError("ActorInstance:fireExplosion", 7, "hitSprite", "Sprite or nil", hitSprite) end
	if type(properties) ~= "number" and properties ~= nil then typeCheckError("ActorInstance:fireExplosion", 8, "properties", "number or nil", properties) end
	verifyInstCall(ids[self])
	local tes, ths
	tes = explosionSprite and SpriteUtil.toID(explosionSprite) or -1
	ths = hitSprite and SpriteUtil.toID(hitSprite) or -1
	return iwrap(GML.fire_explosion(ids[self], x, y, width, height, damage, tes, ths, properties or 0))
end

-----------------------------------------------
------------------------------------ SPRITES --
-----------------------------------------------
-----------------------------------------------

local function resolveSpriteKey(inst, key)
	if key == "death" then
		if typeOf(inst) == "PlayerInstance" then
			key = "dead"
		end
	end
	return "sprite_"..key
end

-- Get sprite
function lookup:getAnimation(key)
	if not children[self] then methodCallError("ActorInstance:getAnimation", self) end
	if type(key) ~= "string" then typeCheckError("ActorInstance:getAnimation", 1, "key", "string", key) end
	verifyInstCall(ids[self])
	local key = resolveSpriteKey(self, key)
	local t = AnyTypeRet(GML.variable_instance_get(ids[self], key))
	if t then
		return SpriteUtil.fromID(t)
	else
		return nil
	end
end

-- Set sprite
function lookup:setAnimation(key, sprite)
	if not children[self] then methodCallError("ActorInstance:setAnimation", self) end
	if type(key) ~= "string" then typeCheckError("ActorInstance:setAnimation", 1, "key", "string", key) end
	if typeOf(sprite) ~= "Sprite" then typeCheckError("ActorInstance:setAnimation", 2, "sprite", "Sprite", sprite) end
	verifyInstCall(ids[self])
	local key = resolveSpriteKey(self, key)
	GML.variable_instance_set(ids[self], key, AnyTypeArg(SpriteUtil.toID(sprite)))
end

-- Set several sprites
function lookup:setAnimations(args)
	if not children[self] then methodCallError("ActorInstance:setAnimations", self) end
	if typeOf(args) ~= "table" then typeCheckError("ActorInstance:setAnimations", 1, "args", "table", args) end
	verifyInstCall(ids[self])

	for k, _ in pairs(args) do
		if type(k) == "string" then
			local v = rawget(args, k)
			if typeOf(v) ~= "Sprite" then typeCheckError("ActorInstance:setActorSprites", 1, "args[" .. k .. "]", "Sprite", v) end
			GML.variable_instance_set(ids[self], resolveSpriteKey(self, k), AnyTypeArg(SpriteUtil.toID(v)))
		end
	end
end

-----------------------------------------------
-------------------------------------- BUFFS --
-----------------------------------------------
-----------------------------------------------

function lookup:applyBuff(buff, duration)
	if not children[self] then methodCallError("ActorInstance:applyBuff", self) end
	if typeOf(buff) ~= "Buff" then typeCheckError("ActorInstance:applyBuff", 1, "buff", "Buff", buff) end
	if type(duration) ~= "number" then typeCheckError("ActorInstance:applyBuff", 2, "duration", "number", duration) end
	verifyInstCall(ids[self])
	GML.apply_buff(ids[self], RoRBuff.toID(buff), duration)
end

function lookup:removeBuff(buff)
	if not children[self] then methodCallError("ActorInstance:removeBuff", self) end
	if typeOf(buff) ~= "Buff" then typeCheckError("ActorInstance:removeBuff", 1, "buff", "Buff", buff) end
	verifyInstCall(ids[self])
	GML.remove_buff(ids[self], RoRBuff.toID(buff))
end

function lookup:hasBuff(buff)
	if not children[self] then methodCallError("ActorInstance:hasBuff", self) end
	if typeOf(buff) ~= "Buff" then typeCheckError("ActorInstance:hasBuff", 1, "buff", "Buff", buff) end
	verifyInstCall(ids[self])
	return GML.has_buff(ids[self], RoRBuff.toID(buff)) == 1
end

function lookup:getBuffs()
	if not children[self] then methodCallError("ActorInstance:getBuffs", self) end
	verifyInstCall(ids[self])
	GML.get_buffs(ids[self])
	local list = PopNumbers()
	for k, v in ipairs(list) do
		list[k] = RoRBuff.fromID(v)
	end
	return list
end

-----------------------------------------------
--------------------------------------- MISC --
-----------------------------------------------
-----------------------------------------------

function lookup:kill()
	if not children[self] then methodCallError("ActorInstance:kill", self) end
	verifyInstCall(ids[self])
	GML.variable_instance_set(ids[self], "force_death", AnyTypeArg(1))
end

local instance_object = GMInstance.instance_object
local obj_id = GMObject.toID
function lookup:isClassic()
	if not children[self] then methodCallError("ActorInstance:isClassic", self) end
	verifyInstCall(ids[self])
	return GML.actor_is_classic(obj_id(instance_object[self])) == 1
end
function lookup:isBoss()
	if not children[self] then methodCallError("ActorInstance:isBoss", self) end
	verifyInstCall(ids[self])
	return GML.actor_is_boss(obj_id(instance_object[self])) == 1
end
