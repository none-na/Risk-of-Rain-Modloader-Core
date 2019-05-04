
-- Create class
local static, lookup, meta, ids, special, children = NewClass("PlayerInstance", true, GMInstance.ActorInstance)
meta.__tostring = __tostring_default_instance
GMInstance.PlayerInstance = static

local verifyInstCall = GMInstance.verifyInstCall

lookup.playerIndex = {
	get = function(t)
		verifyInstCall(ids[t])
		return AnyTypeRet(GML.variable_instance_get(ids[t], "player_id"))
	end
}

function lookup:getSurvivor()
	if not children[self] then methodCallError("PlayerInstance:getSurvivor", self) end
	verifyInstCall(ids[self])
	return RoRSurvivor.fromID(AnyTypeRet(GML.variable_instance_get(ids[self], "class")))
end

do
	-- copy-paste from Input.lua lmao
	local keybindIDs = {
		left = 0,
		right = 1,
		up = 2,
		down = 3,
		jump = 4,
		ability1 = 5,
		ability2 = 6,
		ability3 = 7,
		ability4 = 8,
		use = 9,
		enter = 10,
		swap = 11
	}

	function lookup:control(name)
		if not children[self] then methodCallError("PlayerInstance:control", self) end
		if type(name) ~= "string" then typeCheckError("PlayerInstance:control", 1, "name", "string", name) end
		verifyInstCall(ids[self])
		local tc = keybindIDs[string.lower(name)]
		if not tc then error("'" .. control .. "' is not a known control", 3) end
		return GML.control_check_state(tc, ids[self])
	end
end

-- Use item stuff

lookup.useItem = {
	get = function(p)
		verifyInstCall(ids[p])
		return RoRItem.fromID(GML.player_get_use_item(ids[p]))
	end,
	set = function(p, v)
		if v ~= nil and typeOf(v) ~= "Item" then fieldTypeError("PlayerInstance.useItem", "nil or Item", v) end
		verifyInstCall(ids[p])
		GML.player_set_use_item(ids[p], v and RoRItem.toID(v) or -1)
	end
}

function lookup:activateUseItem(noCooldown, item)
	if not children[self] then methodCallError("PlayerInstance:activateUseItem", self) end
	if noCooldown ~= nil and type(noCooldown) ~= "boolean" then typeCheckError("PlayerInstance:activateUseItem", 1, "noCooldown", "nil or boolean", noCooldown) end
	if item ~= nil and typeOf(item) ~= "Item" then typeCheckError("PlayerInstance:activateUseItem", 2, "item", "nil or Item", item) end
	verifyInstCall(ids[self])
	GML.use_item(ids[self], item and RoRItem.toObjID(item) or -1, noCooldown and 1 or 0)
end

-- Item things

function lookup:giveItem(item, count)
	if not children[self] then methodCallError("PlayerInstance:giveItem", self) end
	if typeOf(item) ~= "Item" then typeCheckError("PlayerInstance:giveItem", 1, "item", "Item", item) end
	if count ~= nil and type(count) ~= "number" then typeCheckError("PlayerInstance:giveItem", 2, "count", "number", count) end
	verifyInstCall(ids[self])
	GML.player_item_give(ids[self], RoRItem.toID(item), count or 1)
end

function lookup:countItem(item)
	if not children[self] then methodCallError("PlayerInstance:countItem", self) end
	if typeOf(item) ~= "Item" then typeCheckError("PlayerInstance:countItem", 1, "item", "Item", item) end
	verifyInstCall(ids[self])
	return GML.player_item_count(ids[self], RoRItem.toID(item))
end

function lookup:removeItem(item, count)
	if not children[self] then methodCallError("PlayerInstance:removeItem", self) end
	if typeOf(item) ~= "Item" then typeCheckError("PlayerInstance:removeItem", 1, "item", "Item", item) end
	if count ~= nil and type(count) ~= "number" then typeCheckError("PlayerInstance:removeItem", 2, "count", "number", count) end
	verifyInstCall(ids[self])
	return GML.player_item_remove(ids[self], RoRItem.toID(item), count or 1)
end

function lookup:setItemSprite(item, sprite)
	if not children[self] then methodCallError("PlayerInstance:setItemSprite", self) end
	if typeOf(item) ~= "Item" then typeCheckError("PlayerInstance:setItemSprite", 1, "item", "Item", item) end
	if typeOf(sprite) ~= "Sprite" then typeCheckError("PlayerInstance:setItemSprite", 1, "sprite", "Sprite", sprite) end
	GML.player_item_hud_set_sprite(ids[self], RoRItem.toObjID(item), SpriteUtil.toID(sprite))
end

function lookup:setItemText(item, text)
	if not children[self] then methodCallError("PlayerInstance:setItemText", self) end
	if typeOf(item) ~= "Item" then typeCheckError("PlayerInstance:setItemText", 1, "item", "Item", item) end
	if type(text) ~= "string" then typeCheckError("PlayerInstance:setItemText", 1, "text", "string", text) end
	GML.player_item_hud_set_text(ids[self], RoRItem.toObjID(item), text)
end

-- Custom survivor stuff

function lookup:survivorSetInitialStats(health, damage, regen)
	if not children[self] then methodCallError("PlayerInstance:survivorSetInitialStats", self) end
	if type(health) ~= "number" then typeCheckError("PlayerInstance:survivorSetInitialStats", 1, "health", "number", health) end
	if type(damage) ~= "number" then typeCheckError("PlayerInstance:survivorSetInitialStats", 2, "damage", "number", damage) end
	if type(regen) ~= "number" then typeCheckError("PlayerInstance:survivorSetInitialStats", 3, "regen", "number", regen) end
	verifyInstCall(ids[self])

	local id = ids[self]
	local glass_on = AnyTypeRet(GML.variable_global_get("artifact_glass")) > 0

	-- Health
	local thp = health * (glass_on and 0.1 or 1)
	GML.variable_instance_set(id, "hp", AnyTypeArg(thp))
	GML.variable_instance_set(id, "maxhp", AnyTypeArg(thp))
	GML.variable_instance_set(id, "maxhp_base", AnyTypeArg(thp))

	-- Damage
	local tdamage = damage * (glass_on and 5 or 1)
	GML.variable_instance_set(id, "damage", AnyTypeArg(tdamage))

	-- Regen
	local drizzle_on = AnyTypeRet(GML.variable_global_get("diff_level")) == 1
	local tregen = regen + (drizzle_on and 0.03 or 0)
	GML.variable_instance_set(id, "hp_regen", AnyTypeArg(tregen))
end

function lookup:survivorLevelUpStats(health, damage, regen, armor)
	if not children[self] then methodCallError("PlayerInstance:survivorLevelUpStats", self) end
	if type(health) ~= "number" then typeCheckError("PlayerInstance:survivorLevelUpStats", 1, "health", "number", health) end
	if type(damage) ~= "number" then typeCheckError("PlayerInstance:survivorLevelUpStats", 2, "damage", "number", damage) end
	if type(regen) ~= "number" then typeCheckError("PlayerInstance:survivorLevelUpStats", 3, "regen", "number", regen) end
	if type(armor) ~= "number" then typeCheckError("PlayerInstance:survivorLevelUpStats", 4, "armor", "number", armor) end
	verifyInstCall(ids[self])

	local id = ids[self]
	local glass_on = AnyTypeRet(GML.variable_global_get("artifact_glass")) > 0

	-- Health
	local thp = health * (glass_on and 0.25 or 1)
	GML.variable_instance_set(id, "hp", AnyTypeArg(AnyTypeRet(GML.variable_instance_get(id, "hp")) + thp))
	GML.variable_instance_set(id, "maxhp", AnyTypeArg(AnyTypeRet(GML.variable_instance_get(id, "maxhp")) + thp))
	GML.variable_instance_set(id, "maxhp_base", AnyTypeArg(AnyTypeRet(GML.variable_instance_get(id, "maxhp_base")) + thp))

	-- Damage
	local tdamage = damage * (glass_on and 3 or 1)
	GML.variable_instance_set(id, "damage", AnyTypeArg(AnyTypeRet(GML.variable_instance_get(id, "damage")) + tdamage))

	-- Regen
	GML.variable_instance_set(id, "hp_regen", AnyTypeArg(AnyTypeRet(GML.variable_instance_get(id, "hp_regen")) + regen))

	-- Armor
	GML.variable_instance_set(id, "armor", AnyTypeArg(AnyTypeRet(GML.variable_instance_get(id, "armor")) + armor))
end

function lookup:survivorActivityState(index, sprite, speed, scaleSpeed, resetHSpeed)
	if not children[self] then methodCallError("PlayerInstance:survivorActivityState", self) end
	if type(index) ~= "number" then typeCheckError("PlayerInstance:survivorActivityState", 1, "index", "number", index) end
	if typeOf(sprite) ~= "Sprite" then typeCheckError("PlayerInstance:survivorActivityState", 2, "sprite", "Sprite", sprite) end
	if type(speed) ~= "number" then typeCheckError("PlayerInstance:survivorActivityState", 3, "speed", "number", speed) end
	if type(scaleSpeed) ~= "boolean" then typeCheckError("PlayerInstance:survivorActivityState", 4, "scaleSpeed", "boolean", scaleSpeed) end
	if type(resetHSpeed) ~= "boolean" then typeCheckError("PlayerInstance:survivorActivityState", 5, "resetHSpeed", "boolean", resetHSpeed) end
	verifyInstCall(ids[self])

	local t = GML.player_set_custom_activity_state(ids[self], index, SpriteUtil.toID(sprite), speed, scaleSpeed, 1, resetHSpeed)
	if t and t > 0 then
		local msg
		if t == 1 then
			msg = "invalid activity index, expected < 5 and >= 1, got " .. tostring(index)
		elseif t == 2 then
			msg = "unable to assign a custom skill activity state to a vanilla survivor"
		else
			msg = "attempt to set custom activity state when activity is not zero"
		end
		error(msg, 3)
	end
end

function lookup:survivorFireHeavenCracker(damage)
	if not children[self] then methodCallError("PlayerInstance:survivorUpdateHeavenCracker", self) end
	if damage ~= nil and type(damage) ~= "number" then typeCheckError("PlayerInstance:survivorUpdateHeavenCracker", 1, "damage", "number or nil", damage) end
	verifyInstCall(ids[self])
	local b = GML.player_update_heaven_cracker(ids[self], damage or 1)
	return (b and b > 0) and GMInstance.iwrap(b) or nil
end

function lookup:activateSkillCooldown(index)
	if not children[self] then methodCallError("PlayerInstance:activateSkillCooldown", self) end
	if type(index) ~= "number" then typeCheckError("PlayerInstance:activateSkillCooldown", 1, "index", "number", index) end
	if index > 4 or index < 1 then error("invalid skill index " .. tostring(index) .. ", expected 1 to 4", 3) end
	verifyInstCall(ids[self])
	GML.skill_cooldown(ids[self], index)
end

function lookup:setSkill(index, name, desc, sprite, subimage, cooldown)
	if not children[self] then methodCallError("PlayerInstance:setSkill", self) end
	if type(index) ~= "number" then typeCheckError("PlayerInstance:setSkill", 1, "index", "number", index) end
	if type(name) ~= "string" then typeCheckError("PlayerInstance:setSkill", 2, "name", "string", name) end
	if type(desc) ~= "string" then typeCheckError("PlayerInstance:setSkill", 3, "desc", "string", desc) end
	if typeOf(sprite) ~= "Sprite" then typeCheckError("PlayerInstance:setSkill", 4, "sprite", "Sprite", sprite) end
	if type(subimage) ~= "number" then typeCheckError("PlayerInstance:setSkill", 5, "subimage", "number", subimage) end
	if type(cooldown) ~= "number" then typeCheckError("PlayerInstance:setSkill", 6, "cooldown", "number", cooldown) end
	if index > 4 or index < 1 then error("invalid skill index " .. tostring(index) .. ", expected 1 to 4", 3) end
	verifyInstCall(ids[self])
	GML.skill_set(ids[self], index, name, desc, cooldown)
	GML.skill_set_icon(ids[self], index, SpriteUtil.toID(sprite), subimage - 1)
end

function lookup:setSkillIcon(index, sprite, subimage)
	if not children[self] then methodCallError("PlayerInstance:setSkillIcon", self) end
	if type(index) ~= "number" then typeCheckError("PlayerInstance:setSkillIcon", 1, "index", "number", index) end
	if typeOf(sprite) ~= "Sprite" then typeCheckError("PlayerInstance:setSkillIcon", 2, "sprite", "Sprite", sprite) end
	if type(subimage) ~= "number" then typeCheckError("PlayerInstance:setSkillIcon", 3, "subimage", "number", subimage) end
	if index > 4 or index < 1 then error("invalid skill index " .. tostring(index) .. ", expected 1 to 4", 3) end
	verifyInstCall(ids[self])
	GML.skill_set_icon(ids[self], index, SpriteUtil.toID(sprite), subimage - 1)
end
