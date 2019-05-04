local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Enemy", true)
meta.__tostring = __tostring_default_namespace

local all_enemies = {vanilla = {}}

local obj_parent = {
    enemy = GML.asset_get_index("pEnemy"),
    boss = GML.asset_get_index("pBoss"),
    classicEnemy = GML.asset_get_index("pClassicEnemy"),
    classicBoss = GML.asset_get_index("pClassicBoss")
}

-- Definition tables
local enemy_callbacks = {}
local enemyGlobalTable = "enemy_info"
local enemyFields = {
    realName = 0,
    spawnType = 1,
    pointsCost = 2,
    spawnSprite = 3,
    spawnObject = 4,
    spawnSound = 5,
    isBoss = 6,
    isClassic = 7,
    displayName = 8,
    origin = 9
}
local logGlobalTable = "mons_info"
local logFields = {
    visible = {
        displayName = 0,
        logStory = 1,
        logHP = 2,
        logDamage = 3,
        logSpeed = 4,
        logSprite = 5,
        logPortrait = 7
    },
    internal = {
        unlocked = 6,
        origin = 8,
        realName = 9,
        hasLog = 10,
        remapId = 11
    }
}
local enemy_number = 46 -- 47 total vanilla enemies
local log_number = 40 -- 41 total vanilla logs

local iwrap = GMInstance.iwrap

local obj_fromID = GMObject.fromID
local obj_toID = GMObject.toID

local id_to_enemy = {}
local object_to_enemy = {}
local enemy_to_log_id = {}

do
    ---------------------
    ------ Methods ------
    ---------------------
    
	-- Get object from enemy
	function lookup:getObject()
		if not children[self] then methodCallError("Enemy:getObject", self) end
        return obj_fromID(AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, ids[self], enemyFields.spawnObject)))
	end

	-- Get origin from enemy
	function lookup:getOrigin()
		if not children[self] then methodCallError("Enemy:getOrigin", self) end
		return AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, ids[self], enemyFields.origin))
	end

	-- Get real name
	function lookup:getName()
		if not children[self] then methodCallError("Enemy:getName", self) end
		return AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, ids[self], enemyFields.realName))
	end

	-- Bind a function to an enemy callback
	local events = {
		spawn = 0,
		step = 1,
		draw = 2,
        death = 3,
        onSkill = 4
	}
	function lookup:addCallback(callback, bind)
		if not children[self] then methodCallError("Enemy:addCallback", self) end
		if type(callback) ~= "string" then typeCheckError("Enemy:addCallback", 1, "callback", "string", callback) end
		if type(bind) ~= "function" then typeCheckError("Enemy:addCallback", 2, "bind", "function", bind) end
		if not events[callback] then error(string.format("'%s' is not a valid enemy callback", callback), 2) end
		verifyCallback(bind)
		
		modFunctionSources[bind] = GetModContext()
		local current = enemy_callbacks[self][callback]
		if current == nil then
			current = {}
			enemy_callbacks[self][callback] = current
			GML.enemy_enable_callback(ids[self], events[callback])
		end
		table.insert(current, bind)
	end

	-- Set enemy log
	function lookup:setLog(args)
		if not children[self] then methodCallError("Enemy:setLog", self) end
		if typeOf(args) ~= "table" then typeCheckError("Enemy:setLog", 1, "args", "named arguments", args) end
        
		local iid = enemy_to_log_id[self]

        if AnyTypeRet(GML.array_global_read_2(logGlobalTable, iid, logFields.internal.hasLog)) ~= 1 then
            GML.array_global_write_2(logGlobalTable, AnyTypeArg(1), iid, logFields.internal.hasLog)
            GML.array_global_write_1("mons_id_map", logNid, noid)
        end
        
		for k, _ in pairs(args) do
			if logFields.visible[k] then
				local v = rawget(args, k)
                if logFields.visible[k] == logFields.visible.logSprite or logFields.visible[k] == logFields.visible.logPortrait then
                    -- lets not let the player set sprites at nil; if they want it empty then don't set it
                    if type(v) ~= "Sprite" then typeCheckError("Enemy:setLog", 1, "args."..tostring(k), "Sprite", v) end
                    GML.array_global_write_2(logGlobalTable, AnyTypeArg(SpriteUtil.toID(v)), iid, logFields.visible[k])
                else
                    if logFields.visible[k] == logFields.visible.logHP or logFields.visible[k] == logFields.visible.logDamage or logFields.visible[k] == logFields.visible.logSpeed then
                        if type(v) ~= "number" then typeCheckError("Enemy:setLog", 1, "args."..tostring(k), "number", v) end
                    else
                        if type(v) ~= "string" then typeCheckError("Enemy:setLog", 1, "args."..tostring(k), "string", v) end
                    end
                    GML.array_global_write_2(logGlobalTable, AnyTypeArg(v), iid, logFields.visible[k])
                end
			end
		end
	end
	
    -- remap log
    function lookup:remapLog(enemy)
		if not children[self] then methodCallError("Enemy:remapLog", self) end
        if type(enemy) ~= "Enemy" then typeCheckError("Enemy:remapLog", 1, "enemy", "Enemy", enemy) end
        local logID = enemy_to_log_id[self]
        local remapLogID = enemy_to_log_id[enemy]
        GML.array_global_write_2(logGlobalTable, AnyTypeArg(-1), logID, logFields.internal.hasLog)
        GML.array_global_write_2(logGlobalTable, AnyTypeArg(remapLogID), logID, logFields.internal.remapId)
    end
    
    -- use skill
    function lookup:useSkill(index, sprite, speed, cooldown, resetHSpeed)
    	if not children[self] then methodCallError("Enemy.useSkill", self) end
        if type(index) ~= "number" then typeCheckError("Enemy.useSkill", 1, "index", "number", index) end
        if typeOf(sprite) ~= "Sprite" then typeCheckError("Enemy.useSkill", 2, "sprite", "Sprite", sprite) end
        if type(speed) ~= "number" then typeCheckError("Enemy.useSkill", 3, "speed", "number", speed) end
        if type(cooldown) ~= "number" then typeCheckError("Enemy.useSkill", 4, "cooldown", "number", cooldown) end
        if type(resetHSpeed) ~= "boolean" then typeCheckError("Enemy.useSkill", 5, "resetHSpeed", "boolean", resetHSpeed) end
        verifyInstCall(ids[self])

        -- TODO: change thsiisiisisiis
        
        -- set activity
        local t = GML.enemy_set_custom_activity_state(ids[self], index, SpriteUtil.toID(sprite), speed, 1, cooldown, resetHSpeed)
        if t and t > 0 then
            local msg
            if t == 1 then
                msg = "invalid activity index, expected < 5 and >= 1, got " .. tostring(index)
            elseif t == 2 then
                msg = "unable to make vanilla enemy use skill"
            else
                msg = "attempt to set custom activity state when activity is not zero"
            end
            error(msg, 3)
        end
    end
    
    ---------------------
    ------ Fields  ------
    ---------------------
    
	-- display name
	lookup.displayName = {
		get = function(t)
			return AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, ids[t], enemyFields.displayName))
		end,
		set = function(t, v)
			if type(v) ~= "string" then fieldTypeError("Enemy.displayName", "string", v) end
			GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(v), ids[t], enemyFields.displayName)
		end
	}

	-- spawn type
	lookup.spawnType = {
		get = function(t)
            local st = AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, ids[t], enemyFields.spawnType))
            local result
			if st == 0 then result = "inView"
            elseif st == 1 then result = "bossSpawn"
            elseif st == 2 then result = "atOrigin"
            elseif st == 3 then result = "outOfView"
            else result = "undefined" end
            return result
		end,
		set = function(t, v)
			if typeOf(v) ~= "string" then fieldTypeError("Enemy.spawnType", "string", v) end
			local result
			if v == "inView" then result = 0
            elseif v == "bossSpawn" then result = 1
            elseif v == "atOrigin" then result = 2
            elseif v == "outOfView" then result = 3
            else error("'"..v.."' is not a valid spawn type", 2) end
            GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(result), ids[t], enemyFields.spawnType)
		end
	}
    
	-- points cost
	lookup.pointsCost = {
		get = function(t)
			return AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, ids[t], enemyFields.pointsCost))
		end,
		set = function(t, v)
			if type(v) ~= "number" then fieldTypeError("Enemy.pointsCost", "numver", v) end
            if v < 0 then error("points cost has to be greater than zero", 2) end
			GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(v), ids[t], enemyFields.pointsCost)
		end
	}
    
	-- spawn sprite
	lookup.spawnSprite = {
		get = function(t)
			local sID = AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, ids[t], enemyFields.spawnSprite))
            if sID == -1 then return nil else return SpriteUtil.fromID(sID) end
		end,
		set = function(t, v)
			if typeOf(v) ~= "Sprite" and v ~= nil then fieldTypeError("Enemy.spawnSprite", "Sprite or nil", v) end
            local sID
            if v == nil then sID = -1 else sID = SpriteUtil.toID(v) end
			GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(sID), ids[t], enemyFields.spawnSprite)
		end
	}

	-- spawn sound
	lookup.spawnSound = {
		get = function(t)
            local sID = AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, ids[t], enemyFields.spawnSound))
			if sID == -1 then return nil else return SoundUtil.ids_map[sID] end
		end,
		set = function(t, v)
			if typeOf(v) ~= "Sound" and v ~= nil then fieldTypeError("Enemy.spawnSound", "Sound or nil", v) end
            local sID
            if v == nil then sID = -1 else sID = SoundUtil.ids[v] end
			GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(sID), ids[t], enemyFields.spawnSound)
		end
	}

	-- -- is boss
	-- lookup.isBoss = {
		-- get = function(t)
			-- return AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, ids[t], enemyFields.isBoss)) == 1
		-- end,
		-- set = function(t, v)
			-- if type(v) ~= "boolean" then fieldTypeError("Enemy.isBoss", "boolean", v) end
			-- GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(v and 1 or 0), ids[t], enemyFields.isBoss)
		-- end
	-- }
    
	-- -- is classic
	-- lookup.isClassic = {
		-- get = function(t)
			-- return AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, ids[t], enemyFields.isClassic)) == 1
		-- end,
		-- set = function(t, v)
			-- if type(v) ~= "boolean" then fieldTypeError("Enemy.isClassic", "boolean", v) end
			-- GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(v and 1 or 0), ids[t], enemyFields.isClassic)
		-- end
	-- }
    
	-- Shortcut to enemy:getObject():create()
	function lookup:create(x, y)
		if not children[self] then methodCallError("Enemy:create", self) end
		if type(x) ~= "number" then typeCheckError("Enemy:create", 1, "x", "number", x) end
		if type(y) ~= "number" then typeCheckError("Enemy:create", 2, "y", "number", y) end
		return iwrap(GML.instance_create(x, y, AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, ids[self], enemyFields.spawnObject))))
	end
end
----------------------------
------ Static Methods ------
----------------------------

Enemy = {}

do
	local function enemy_new(name, isClassic, isBoss)
		local context = GetModContext()
		contextVerify(all_enemies, name, context, "Enemy", 1)

		enemy_number = enemy_number + 1
		local nid = enemy_number
        log_number = log_number + 1
        local logNid = log_number
		--GML.variable_global_set("mons_number", AnyTypeArg(nid))

		-- Create new GMObject
		overrideModContext = "modLoaderCore"
		local newObj = Object.new(context.."_enemy_"..name)
		GMObject.setObjectType(newObj, "enemy")
		overrideModContext = nil
		local noid = obj_toID(newObj)
        
        local common_parent = obj_parent.enemy
        if isClassic then
            if isBoss then
                common_parent = obj_parent.classicBoss
            else
                common_parent = obj_parent.classicEnemy
            end
        else
            if isBoss then
                common_parent = obj_parent.boss
            end
        end
		GML.object_set_parent(noid, common_parent)
		GML.object_set_depth(noid, -99)

		-- Create new enemy
		local new = static.new(nid)
		-- Add to mod enemy table
		contextInsert(all_enemies, name, context, new)

		-- Set default enemy properties
		GML.array_global_write_2(enemyGlobalTable, name, nid, enemyFields.realName)
		GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(-1), nid, enemyFields.spawnType)
		GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(0), nid, enemyFields.pointsCost)
		GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(-1), nid, enemyFields.spawnSprite)
		GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(noid), nid, enemyFields.spawnObject)
		GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(-1), nid, enemyFields.spawnSound)
		GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(isBoss and 1 or 0), nid, enemyFields.isBoss)
		GML.array_global_write_2(enemyGlobalTable, AnyTypeArg(isClassic and 1 or 0), nid, enemyFields.isClassic)
		GML.array_global_write_2(enemyGlobalTable, name, nid, enemyFields.displayName)
		GML.array_global_write_2(enemyGlobalTable, context, nid, enemyFields.origin)
		enemy_callbacks[new] = {}
        
        -- Setup default log
        GML.array_global_write_2(logGlobalTable, name, logNid, logFields.visible.displayName)
        GML.array_global_write_2(logGlobalTable, AnyTypeArg(""), logNid, logFields.visible.logStory)
        GML.array_global_write_2(logGlobalTable, AnyTypeArg(0), logNid, logFields.visible.logHP)
        GML.array_global_write_2(logGlobalTable, AnyTypeArg(0), logNid, logFields.visible.logDamage)
        GML.array_global_write_2(logGlobalTable, AnyTypeArg(0), logNid, logFields.visible.logSpeed)
        GML.array_global_write_2(logGlobalTable, AnyTypeArg(-1), logNid, logFields.visible.logSprite)
        GML.array_global_write_2(logGlobalTable, AnyTypeArg(-1), logNid, logFields.visible.logPortrait)
        GML.array_global_write_2(logGlobalTable, AnyTypeArg(0), logNid, logFields.internal.unlocked)
        GML.array_global_write_2(logGlobalTable, context, logNid, logFields.internal.origin)
        GML.array_global_write_2(logGlobalTable, name, logNid, logFields.internal.realName)
        GML.array_global_write_2(logGlobalTable, AnyTypeArg(0), logNid, logFields.internal.hasLog)
        GML.array_global_write_2(logGlobalTable, AnyTypeArg(0), logNid, logFields.internal.remapId)
        
		-- GML side function which automatically initializes all enemy info and loads from the save
        -- NOTE: probably also has to insert into "enemy_id_map"
		GML.init_enemy(nid, logNid)
        
        object_to_enemy[newObj] = new
        id_to_enemy[nid] = new
        enemy_to_log_id[new] = logNid
        
		return new
	end
	-- New enemy
	function Enemy.new(name, isClassic, isBoss)
		if type(name) ~= "string" then typeCheckError("Enemy.new", 1, "name", "string", name) end
		if type(isClassic) ~= "boolean" then typeCheckError("Enemy.new", 2, "isClassic", "boolean", isClassic) end
		if type(isBoss) ~= "boolean" then typeCheckError("Enemy.new", 3, "isBoss", "boolean", isBoss) end
		return enemy_new(name, isClassic, isBoss)
	end
	Enemy.find = contextSearch(all_enemies, "Enemy.find")
	Enemy.findAll = contextFindAll(all_enemies, "Enemy.findAll")
	setmetatable(Enemy, {__call = function(t, name, isClassic, isBoss)
		if type(name) ~= "string" then typeCheckError("Enemy", 1, "name", "string", name) end
		if type(isClassic) ~= "boolean" then typeCheckError("Enemy", 2, "isClassic", "boolean", isClassic) end
		if type(isBoss) ~= "boolean" then typeCheckError("Enemy", 3, "isBoss", "boolean", isBoss) end
		return enemy_new(name, isClassic, isBoss)
	end})
end

-- Find an enemy from its object
function Enemy.fromObject(object)
	if typeOf(object) ~= "GMObject" then typeCheckError("Enemy.fromObject", 1, "object", "GMObject", object) end
	return object_to_enemy[object]
end

-- Set enemy initial stats

function Enemy.setInitialStats(enemyInstance, health, damage, exp_worth, armor)
	if typeOf(enemyInstance) ~= "ActorInstance" then typeCheckError("Enemy.setInitialStats", 1, "enemyInstance", "ActorInstance", enemyInstance) end
	if type(health) ~= "number" then typeCheckError("Enemy.setInitialStats", 2, "health", "number", health) end
	if type(damage) ~= "number" then typeCheckError("Enemy.setInitialStats", 3, "damage", "number", damage) end
	if type(exp_worth) ~= "number" then typeCheckError("Enemy.setInitialStats", 4, "exp_worth", "number", exp_worth) end
	if type(armor) ~= "number" then typeCheckError("Enemy.setInitialStats", 5, "armor", "number", armor) end

	local id = GMInstance.IDs[enemyInstance]
    local stats = {
        hp = 1,
        damage = 2,
        exp_worth = 3,
        armor = 4
    }
    
	-- Health
	local thp = health * GML.get_stats_multiplier(AnyTypeArg(stats.hp))
	GML.variable_instance_set(id, "hp", AnyTypeArg(thp))
	GML.variable_instance_set(id, "maxhp", AnyTypeArg(thp))

	-- Damage
	local tdamage = damage * GML.get_stats_multiplier(AnyTypeArg(stats.damage))
	GML.variable_instance_set(id, "damage", AnyTypeArg(tdamage))

	-- Exp Worth
	local texp = exp_worth * GML.get_stats_multiplier(AnyTypeArg(stats.exp_worth))
	GML.variable_instance_set(id, "exp_worth", AnyTypeArg(texp))
    
	-- Armor
	local tarmor = armor * GML.get_stats_multiplier(AnyTypeArg(stats.armor))
	GML.variable_instance_set(id, "armor", AnyTypeArg(tarmor))
end


----------------
----- Misc -----
----------------
-- Wrap vanilla enemies
for i = 0, enemy_number do
	local n = static.new(i)
    enemy_callbacks[n] = {}
    
    local eObj = AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, AnyTypeArgs(i), enemyFields.spawnObject))
    
    object_to_enemy[eObj] = n
    id_to_enemy[i] = n
    enemy_to_log_id[n] = AnyTypeRet(GML.array_global_read_1("mons_id_map", obj_toID(eObj)))

    all_enemies.vanilla[string.lower(AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, i, enemyFields.realName)))] = n
end

-- Handle callback
function SpecialCallbacks.enemy(callback, enemy, actor)
	enemy = object_to_enemy[obj_fromID(enemy)]
	local call = enemy_callbacks[enemy][callback]
	if not call then
		return
	else
		local args = {iwrap(actor)}
		for _, v in ipairs(call) do
			CallModdedFunction(v, args)
		end
	end
end

-- API internals table
RoREnemy = {}
function RoREnemy.toID(enemy)
	return ids[enemy]
end
function RoREnemy.fromID(enemy)
	return id_to_enemy[enemy]
end
function RoREnemy.toObjID(enemy)
	return AnyTypeRet(GML.array_global_read_2(enemyGlobalTable, ids[enemy], enemyFields.spawnObject))
end
function RoREnemy.fromObjID(enemy)
	return object_to_enemy[obj_fromID(enemy)]
end
function RoREnemy.fromObj(enemy)
	return object_to_enemy[item]
end

-- env
mods.modenv.Enemy = Enemy
