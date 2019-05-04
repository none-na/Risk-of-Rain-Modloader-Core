local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Achievement", true)
meta.__tostring = __tostring_default_namespace
-- Create global table
Achievement = {}
mods.modenv.Achievement = Achievement

local all_achievements = {vanilla = {}}

-- Field tables
local achievement_requirement = {}
local achievement_sprite = {}
local achievement_parent = {}
local achievement_name = {}
local achievement_origin = {}
local achievement_callbacks = {}

local id_to_achievement = {}

local default_sprite = SpriteUtil.fromID(GML.asset_get_index("sRandom"))
local maxachievement = 54 -- 0 also belongs, so 55 total

------------------------------------------
-- COMMON -------------------------------
------------------------------------------

function lookup:getName()
	if not children[self] then methodCallError("Achievement:getName", self) end

	return achievement_name[self]
end

function lookup:getOrigin()
	if not children[self] then methodCallError("Achievement:getOrigin", self) end

	return achievement_origin[self]
end

function lookup:increment(inc)
    if not children[self] then methodCallError("Achievement:increment", self) end
	if type(inc) ~= "number" then typeCheckError("Achievement:increment", 1, "inc", "number", inc) end
    
    
    GML.achievement_progress(ids[self], inc)
end

function lookup:assignUnlockable(thing)
    if not children[self] then methodCallError("Achievement:assignUnlockable", self) end
    if achievement_origin[self] == "Vanilla" then error("cannot modify vanilla achievement unlocks", 2) end
    local thingType = typeOf(thing)
	if thingType ~= "Item" and thingType ~= "Survivor" then typeCheckError("Achievement:assignUnlockable", 1, "inc", "Item or Survivor", thing) end
    if thing:getOrigin() == "Vanilla" then error("cannot assign vanilla items or survivors as unlockables", 2) end
    
    self.highscoreText = "'" .. thing.displayName .. "' Unlocked"
    local thingID
    if thingType == "Survivor" then
        thingID = RoRSurvivor.toID(thing)
        self.sprite = thing.titleSprite
        self.unlockText = "This character is now playable."
        GML.array_open("class_info")
        GML.array_write_2(thingID, 3, AnyTypeArg(ids[self]))
        GML.array_close()
    else
        thingID = RoRItem.toID(thing)
        self.sprite = thing.sprite
        self.unlockText = "This item will now drop."
        GML.array_open("item_info")
        GML.array_write_2(thingID, 20, AnyTypeArg(ids[self]))
        GML.array_close()
    end
end

function lookup:isComplete()
    if not children[self] then methodCallError("Achievement:isComplete", self) end
    
    return (AnyTypeRet(GML.array_global_read_2("achievement_list", ids[self], 0)) >= 1)
end

------------------------------------------
-- FIELDS --------------------------------
------------------------------------------

local syncAchievementField
do
	local fieldID = {
        requirement = 2,
        sprite = 3,
        unlockText = 4,
        deathReset = 5,
        description = 6,
        highscoreText = 7,
        parent = 8
	}
	function syncAchievementField(achieve, field, value)
		GML.array_global_write_2("achievement_list", AnyTypeArg(value), ids[achieve], fieldID[field])
	end
end

lookup.requirement = {
	get = function(t)
		return AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], 2))
	end,
	set = function(t, v)
        -- should changing this check if it completes the achievement?
		if typeOf(v) ~= "number" then fieldTypeError("Achievement.requirement", "number", v) end
		syncAchievementField(t, "requirement", v)
	end
}

lookup.sprite = {
	get = function(t)
		return achievement_sprite[t]
	end,
	set = function(t, v)
		if typeOf(v) ~= "Sprite" then fieldTypeError("Achievement.sprite", "Sprite", v) end
		achievement_sprite[t] = v
		syncAchievementField(t, "sprite", SpriteUtil.toID(v))
	end
}

lookup.unlockText = {
	get = function(t)
		return AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], 4))
	end,
	set = function(t, v)
		if typeOf(v) ~= "string" then fieldTypeError("Achievement.unlockText", "string", v) end
		syncAchievementField(t, "unlockText", v)
	end
}

lookup.deathReset = {
	get = function(t)
		return (AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], 5)) == 1)
	end,
	set = function(t, v)
		if typeOf(v) ~= "boolean" then fieldTypeError("Achievement.deathReset", "boolean", v) end
		syncAchievementField(t, "deathReset", v and 1 or 0)
	end
}

lookup.description = {
	get = function(t)
		return AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], 6))
	end,
	set = function(t, v)
		if typeOf(v) ~= "string" then fieldTypeError("Achievement.description", "string", v) end
		syncAchievementField(t, "description", v)
	end
}

lookup.highscoreText = {
	get = function(t)
		return AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], 7))
	end,
	set = function(t, v)
		if typeOf(v) ~= "string" then fieldTypeError("Achievement.highscoreText", "string", v) end
		syncAchievementField(t, "highscoreText", v)
	end
}

lookup.parent = {
	get = function(t)
		local parentID = AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], 8))
		if parentID == -1 then
			return nil
		else
			return id_to_achievement[parentID]
		end
	end,
	set = function(t, v)
		if not children[v] and v ~= nil then fieldTypeError("Achievement.parent", "Achievement or nil", v) end
        local p = v
        while p ~= nil do
            if p == t then error("circular parenting", 2) end
            p = p.parent
        end
        local cheevoID = -1
        if v ~= nil then
            cheevoID = ids[v]
        end
		syncAchievementField(t, "parent", cheevoID)
	end
}

------------------------------------------
-- CALLBACKS -----------------------------
------------------------------------------

do
	local events = {
		onIncrement = 11,
		onComplete = 12
	}
	function lookup:addCallback(callback, bind)
		if not children[self] then methodCallError("Achievement:addCallback", self) end
		if type(callback) ~= "string" then typeCheckError("Achievement:addCallback", 1, "callback", "string", callback) end
		if type(bind) ~= "function" then typeCheckError("Achievement:addCallback", 2, "bind", "function", bind) end
		if not events[callback] then error(string.format("'%s' is not a valid achievement callback", callback), 2) end
		verifyCallback(bind)
		
		modFunctionSources[bind] = GetModContext()

		local current = achievement_callbacks[self][callback]
		if current == nil then
			current = {}
			achievement_callbacks[self][callback] = current

			GML.array_open("achievement_list")
			GML.array_write_2(ids[self], events[callback], AnyTypeArg(1))
			GML.array_close()
		end
		table.insert(current, bind)
	end
end

function SpecialCallbacks.achievement(callback, achieveid)--, actor, time)
	local achieve = id_to_achievement[achieveid]
	local call = achievement_callbacks[achieve][callback]
	if not call then
		return
	else
		--local args = {GMInstance.iwrap(actor), time}
        local args = nil
		for _, v in ipairs(call) do
			CallModdedFunction(v, args)
		end
	end
end



------------------------------------------
-- WRAP VANILLA --------------------------
------------------------------------------

do
    GML.array_open("achievement_list")
	for i = 0, 54 do
        local n = static.new(i)

        achievement_sprite[n] = SpriteUtil.fromID(AnyTypeRet(GML.array_read_2(i, 3)))
        achievement_name[n] = AnyTypeRet(GML.array_read_2(i, 9))
        achievement_origin[n] = "Vanilla"
        achievement_callbacks[n] = {}
        
        id_to_achievement[i] = n
        all_achievements.vanilla[string.lower(achievement_name[n])] = n
	end
	GML.array_close()
end

------------------------------------------
-- GLOBAL FUNCTIONS ----------------------
------------------------------------------

Achievement.find = contextSearch(all_achievements, "Achievement.find")
Achievement.findAll = contextFindAll(all_achievements, "Achievement.findAll")

local function achievement_new(name)
	local context = GetModContext()
	contextVerify(all_achievements, name, context, "Achievement", 1)

	maxachievement = maxachievement + 1
	local nid = maxachievement
	local new = static.new(nid)
	id_to_achievement[nid] = new
	GML.variable_global_set("achievement_number", AnyTypeArg(nid))

	contextInsert(all_achievements, name, context, new)

    achievement_sprite[new] = default_sprite
    achievement_name[new] = name
    achievement_origin[new] = context
    achievement_callbacks[new] = {}

	GML.achievement_add(nid, name, context)

	return new
end

function Achievement.new(name)
	if type(name) ~= "string" then typeCheckError("Achievement.new", 1, "name", "string", name) end
	return achievement_new(name)
end

setmetatable(Achievement, {__call = function(t, name)
	if type(name) ~= "string" then typeCheckError("Achievement", 1, "name", "string", name) end
	return achievement_new(name)
end})
