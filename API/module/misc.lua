local GML = GML
local type = type
local typeOf = typeOf
-- Initialize table
misc = {}

misc.players = {} -- Handled in modloader.lua

do
	local optHandlers = {
		["video.quality"] = function() return AnyTypeRet(GML.variable_global_get("graphics")) end,
		["video.fullscreen"] = function() return AnyTypeRet(GML.variable_global_get("fullscreen")) > 0 end,
		["video.scale"] = function() return AnyTypeRet(GML.variable_instance_get(GML_init_instance_id, "scale")) end,
		["video.hud_scale"] = function() return AnyTypeRet(GML.variable_instance_get(GML_init_instance_id, "hud_scale")) end,
		["video.show_money"] = function() return AnyTypeRet(GML.variable_global_get("money_on")) > 0 end,
		["video.show_damage"] = function() return AnyTypeRet(GML.variable_global_get("damage_on")) > 0 end,
		["video.frameskip"] = function() return AnyTypeRet(GML.variable_global_get("frameskip")) > 0 end,
		["video.vsync"] = function() return AnyTypeRet(GML.variable_global_get("vsync")) > 0 end,

		["general.volume"] = function() return AnyTypeRet(GML.variable_global_get("volume")) end,
		["general.music volume"] = function() return AnyTypeRet(GML.variable_global_get("music_volume")) end
	}

	function misc.getOption(name)
		if type(name) ~= "string" then typeCheckError("misc.getOption", 1, "name", "number", name) end
		if not optHandlers[name] then error("'" .. name .. "' is not a valid option name", 2) end
		return optHandlers[name]()
	end
end

-- Money
function misc.getGold()
	if DisableInstanceInteraction then return end
	return AnyTypeRet(GML.variable_instance_get(GML_hud_instance_id, "gold"))
end

function misc.setGold(value)
	if DisableInstanceInteraction then return end
	if type(value) ~= "number" then typeCheckError("misc.setGold", 1, "value", "number", value) end
	GML.variable_instance_set(GML_hud_instance_id, "gold", AnyTypeArg(value))
end

-- Timestop
function misc.getTimeStop()
	return AnyTypeRet(GML.variable_global_get("time_stop"))
end

local tick_sound = GML.asset_get_index("wWatch")
function misc.setTimeStop(value)
	if DisableInstanceInteraction then return end
	if type(value) ~= "number" then typeCheckError("misc.setTimeStop", 1, "value", "number", value) end
	GML.variable_global_set("time_stop", AnyTypeArg(value))
	if GML.sound_isplaying(tick_sound) == 0 then
		GML.sound_loop(tick_sound)
	end
end

-- Time
function misc.getTime()
	if DisableInstanceInteraction then return end
	return AnyTypeRet(GML.variable_instance_get(GML_hud_instance_id, "minute")), AnyTypeRet(GML.variable_instance_get(GML_hud_instance_id, "second"))
end

-- Screenshake
function misc.shakeScreen(frames)
	if DisableInstanceInteraction then return end
	if type(frames) ~= "number" then typeCheckError("misc.shakeScreen", 1, "frames", "number", frames) end
	GML.write_alarm(GML_hud_instance_id, 0, frames)
end

local iwrap = GMInstance.iwrap

-- Shoot bulllet
function misc.fireBullet(x, y, direction, distance, damage, team, hitSprite, properties)
	if type(x) ~= "number" then typeCheckError("misc.fireBullet", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("misc.fireBullet", 2, "y", "number", y) end
	if type(direction) ~= "number" then typeCheckError("misc.fireBullet", 3, "direction", "number", direction) end
	if type(distance) ~= "number" then typeCheckError("misc.fireBullet", 4, "distance", "number", distance) end
	if type(damage) ~= "number" then typeCheckError("misc.fireBullet", 5, "damage", "number", damage) end
	if type(team) ~= "string" then typeCheckError("misc.fireBullet", 6, "team", "string", team) end
	if typeOf(hitSprite) ~= "Sprite" and hitSprite ~= nil then typeCheckError("misc.fireBullet", 7, "hitSprite", "Sprite or nil", hitSprite) end
	if type(properties) ~= "number" and properties ~= nil then typeCheckError("misc.fireBullet", 8, "properties", "number or nil", properties) end
	local ths = hitSprite and SpriteUtil.toID(hitSprite) or -1
	return iwrap(GML.fire_bullet_parentless(x, y, direction, distance, damage, team, ths, properties or 0))
end

-- Shoot explosion
function misc.fireExplosion(x, y, width, height, damage, team, explosionSprite, hitSprite, properties)
	if type(x) ~= "number" then typeCheckError("misc.fireExplosion", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("misc.fireExplosion", 2, "y", "number", y) end
	if type(width) ~= "number" then typeCheckError("misc.fireExplosion", 3, "width", "number", width) end
	if type(height) ~= "number" then typeCheckError("misc.fireExplosion", 4, "height", "number", height) end
	if type(damage) ~= "number" then typeCheckError("misc.fireExplosion", 5, "damage", "number", damage) end
	if type(team) ~= "string" then typeCheckError("misc.fireExplosion", 6, "team", "string", team) end
	if typeOf(explosionSprite) ~= "Sprite" and explosionSprite ~= nil then typeCheckError("misc.fireExplosion", 7, "explosionSprite", "Sprite or nil", explosionSprite) end
	if typeOf(hitSprite) ~= "Sprite" and hitSprite ~= nil then typeCheckError("misc.fireExplosion", 8, "hitSprite", "Sprite or nil", hitSprite) end
	if type(properties) ~= "number" and properties ~= nil then typeCheckError("misc.fireExplosion", 9, "properties", "number or nil", properties) end
	local tes, ths
	tes = explosionSprite and SpriteUtil.toID(explosionSprite) or -1
	ths = hitSprite and SpriteUtil.toID(hitSprite) or -1
	return iwrap(GML.fire_explosion_parentless(x, y, width, height, damage, team, tes, ths, properties or 0))
end

-- Damage text
local floor = math.floor
function misc.damage(damage, x, y, critical, color)
	if type(damage) ~= "number" then typeCheckError("misc.damage", 1, "damage", "number", damage) end
	if type(x) ~= "number" then typeCheckError("misc.damage", 2, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("misc.damage", 3, "y", "number", y) end
	if type(critical) ~= "boolean" then typeCheckError("misc.damage", 4, "critical", "boolean", critical) end
	if typeOf(color) ~= "Color" then typeCheckError("misc.damage", 5, "color", "Color", color) end
	GML.draw_damage(floor(x), floor(y), floor(damage), critical and 1 or 0, GetColorValue(color))
end

-- Set the run seed
function misc.setRunSeed(seed)
	if seed ~= nil and type(seed) ~= "number" then typeCheckError("misc.setRunSeed", 1, "seed", "number or nil", seed) end
	if seed ~= nil then
		seed = math.floor(seed)
		if seed <= 0 then error("run seed must be greater than 0", 2) end
	end
	GML.variable_global_set("game_seed", AnyTypeArg(seed))
end

-- Add to mod environment
mods.modenv.misc = misc
