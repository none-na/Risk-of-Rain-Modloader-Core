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

-- -- Field tables
-- local achievement_finished = {}
-- local achievement_progress = {}
-- local achievement_requirement = {}
-- local achievement_sprite = {}
-- local achievement_unlock_message = {}
-- local achievement_death_reset = {}
-- local achievement_description = {}
-- local achievement_highscore_desc = {}
-- local achievement_parent = {}
-- local achievement_name = {}
-- local achievement_origin = {}

local achievement_callbacks = {}
local fieldID = {
    finished = 0,
    progress = 1,
    requirement = 2,
    sprite = 3,
    unlockText = 4,
    deathReset = 5,
    description = 6,
    highscoreText = 7,
    parent = 8,
    name = 9,
    origin = 10
}

local id_to_achievement = {}

local default_sprite = SpriteUtil.fromID(GML.asset_get_index("sRandom"))
local maxachievement = 54 -- 0 also belongs, so 55 total

local function checkCheevoFinished(cheev, max)
	local progress = AnyTypeRet(GML.array_global_read_2("achievement_list", ids[cheev], fieldID.progress))
	local deathReset = AnyTypeRet(GML.array_global_read_2("achievement_list", ids[cheev], fieldID.deathReset)) > 0
	local value = 0
	if progress >= max or (deathReset and progress > 0) then
		value = 2
	end
	GML.array_global_write_2("achievement_list", AnyTypeArg(value), ids[cheev], fieldID.finished)
end

------------------------------------------
-- COMMON -------------------------------
------------------------------------------

function lookup:getName()
	if not children[self] then methodCallError("Achievement:getName", self) end

	--return achievement_name[self]
    return AnyTypeRet(GML.array_global_read_2("achievement_list", ids[self], fieldID["name"]))
end

function lookup:getOrigin()
	if not children[self] then methodCallError("Achievement:getOrigin", self) end

	--return achievement_origin[self]
    return AnyTypeRet(GML.array_global_read_2("achievement_list", ids[self], fieldID["origin"]))
end

function lookup:increment(inc)
    if not children[self] then methodCallError("Achievement:increment", self) end
    --if achievement_origin[self] == "Vanilla" then error("cannot modify vanilla achievement fields", 2) end
    if AnyTypeRet(GML.array_global_read_2("achievement_list", ids[self], fieldID["origin"])) == "Vanilla" then error("cannot modify vanilla achievement fields", 2) end
	if type(inc) ~= "number" then typeCheckError("Achievement:increment", 1, "inc", "number", inc) end
    
    
    GML.achievement_progress(ids[self], inc)
    
    -- GML.array_open("achievement_list")
    -- achievement_finished[self] = (AnyTypeRet(GML.array_read_2(ids[self], 0)) >= 1)
    -- achievement_progress[self] = AnyTypeRet(GML.array_read_2(ids[self], 1))
    -- GML.array_close()
end

function lookup:assignUnlockable(thing)
    if not children[self] then methodCallError("Achievement:assignUnlockable", self) end
    --if achievement_origin[self] == "Vanilla" then error("cannot modify vanilla achievement unlocks", 2) end
    if AnyTypeRet(GML.array_global_read_2("achievement_list", ids[self], fieldID["origin"])) == "Vanilla" then error("cannot modify vanilla achievement fields", 2) end
	local thingType = typeOf(thing)
	if thingType ~= "Item" and thingType ~= "Survivor" then typeCheckError("Achievement:assignUnlockable", 1, "inc", "Item or Survivor", thing) end
    if thing:getOrigin() == "Vanilla" then error("cannot assign vanilla items or survivors as unlockables", 2) end
    
    self.highscoreText = "'" .. thing.displayName .. "' Unlocked"
    local thingID
    if thingType == "Survivor" then
        thingID = RoRSurvivor.toID(thing)
        self.sprite = thing.titleSprite
        self.unlockText = "This character is now playable."
        GML.array_global_write_2("class_info", AnyTypeArg(ids[self]), thingID, 20)
    else
        thingID = RoRItem.toID(thing)
        self.sprite = thing.sprite
        self.unlockText = "This item will now drop."
        GML.array_global_write_2("item_info", AnyTypeArg(ids[self]), thingID, 3)
    end
end

function lookup:isComplete()
    if not children[self] then methodCallError("Achievement:isComplete", self) end
    
    --return achievement_finished[self]
    return AnyTypeRet(GML.array_global_read_2("achievement_list", ids[self], fieldID["finished"])) == 1
end

------------------------------------------
-- FIELDS --------------------------------
------------------------------------------

lookup.requirement = {
	get = function(t)
		--return achievement_requirement[t]
        return AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["requirement"]))
	end,
	set = function(t, v)
        -- should changing this check if it completes the achievement?
        if AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["origin"])) == "Vanilla" then error("cannot modify vanilla achievement fields", 2) end
		if typeOf(v) ~= "number" then fieldTypeError("Achievement.requirement", "number", v) end
        
		--achievement_requirement[t] = v
		GML.array_global_write_2("achievement_list", AnyTypeArg(v), ids[t], fieldID["requirement"])

		checkCheevoFinished(t, v)
	end
}

lookup.sprite = {
	get = function(t)
		--return achievement_sprite[t]
        return SpriteUtil.fromID(AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["sprite"])))
	end,
	set = function(t, v)
        if AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["origin"])) == "Vanilla" then error("cannot modify vanilla achievement fields", 2) end
		if typeOf(v) ~= "Sprite" then fieldTypeError("Achievement.sprite", "Sprite", v) end

		--achievement_sprite[t] = v
		GML.array_global_write_2("achievement_list", AnyTypeArg(SpriteUtil.toID(v)), ids[t], fieldID["sprite"])
	end
}

lookup.unlockText = {
	get = function(t)
		--return achievement_unlock_message[t]
        return AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["unlockText"]))
	end,
	set = function(t, v)
        if AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["origin"])) == "Vanilla" then error("cannot modify vanilla achievement fields", 2) end
		if typeOf(v) ~= "string" then fieldTypeError("Achievement.unlockText", "string", v) end

		--achievement_unlock_message[t] = v
		GML.array_global_write_2("achievement_list", AnyTypeArg(v), ids[t], fieldID["unlockText"])
	end
}

lookup.deathReset = {
	get = function(t)
		--return achievement_death_reset[t]
        return AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["deathReset"])) == 1
	end,
	set = function(t, v)
        if AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["origin"])) == "Vanilla" then error("cannot modify vanilla achievement fields", 2) end
		if typeOf(v) ~= "boolean" then fieldTypeError("Achievement.deathReset", "boolean", v) end

		--achievement_death_reset[t] = v
		GML.array_global_write_2("achievement_list", AnyTypeArg(v and 1 or 0), ids[t], fieldID["deathReset"])

		checkCheevoFinished(t, 1)
	end
}

lookup.description = {
	get = function(t)
		--return achievement_description[t]
        return AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["description"]))
	end,
	set = function(t, v)
        if AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["origin"])) == "Vanilla" then error("cannot modify vanilla achievement fields", 2) end
		if typeOf(v) ~= "string" then fieldTypeError("Achievement.description", "string", v) end

		--achievement_description[t] = v
		GML.array_global_write_2("achievement_list", AnyTypeArg(v), ids[t], fieldID["description"])
	end
}

lookup.highscoreText = {
	get = function(t)
		--return achievement_highscore_desc[t]
        return AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["highscoreText"]))
	end,
	set = function(t, v)
        if AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["origin"])) == "Vanilla" then error("cannot modify vanilla achievement fields", 2) end
		if typeOf(v) ~= "string" then fieldTypeError("Achievement.highscoreText", "string", v) end
        
		--achievement_highscore_desc[t] = v
		GML.array_global_write_2("achievement_list", AnyTypeArg(v), ids[t], fieldID["highscoreText"])
	end
}

lookup.parent = {
	get = function(t)
		--return achievement_parent[t]
        local parentID = AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["parent"]))
        if parentID == -1 then
            return nil
        else
            return id_to_achievement[parentID]
        end
	end,
	set = function(t, v)
        if AnyTypeRet(GML.array_global_read_2("achievement_list", ids[t], fieldID["origin"])) == "Vanilla" then error("cannot modify vanilla achievement fields", 2) end
		if not children[v] and v ~= nil then fieldTypeError("Achievement.parent", "Achievement", v) end
        local p = v
        while p ~= nil do
            if p == t then error("circular parenting", 2) end
            p = p.parent
        end
        
		--achievement_parent[t] = v
        local cheevoID = -1
        if v ~= nil then
            cheevoID = ids[v]
        end
		GML.array_global_write_2("achievement_list", AnyTypeArg(v), ids[t], fieldID["parent"])
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

			GML.array_global_write_2("achievement_list", AnyTypeArg(1), ids[self], events[callback])
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
	for i = 0, 54 do
        local n = static.new(i)

        -- achievement_finished[n] = (AnyTypeRet(GML.array_read_2(i, 0)) >= 1)
        -- achievement_progress[n] = AnyTypeRet(GML.array_read_2(i, 1))
        -- achievement_requirement[n] = AnyTypeRet(GML.array_read_2(i, 2))
        -- achievement_sprite[n] = SpriteUtil.fromID(AnyTypeRet(GML.array_read_2(i, 3)))
        -- achievement_unlock_message[n] = AnyTypeRet(GML.array_read_2(i, 4))
        -- achievement_death_reset[n] = (AnyTypeRet(GML.array_read_2(i, 5)) == 1)
        -- achievement_description[n] = AnyTypeRet(GML.array_read_2(i, 6))
        -- achievement_highscore_desc[n] = AnyTypeRet(GML.array_read_2(i, 7))
        -- local parentID = AnyTypeRet(GML.array_read_2(i, 8))
        -- if parentID == -1 then
            -- achievement_parent[n] = nil
        -- else
            -- achievement_parent[n] = id_to_achievement[parentID]
        -- end
        -- achievement_name[n] = AnyTypeRet(GML.array_read_2(i, 9))
        -- achievement_origin[n] = "Vanilla"
        achievement_callbacks[n] = {}
        
        id_to_achievement[i] = n
        --all_achievements.vanilla[string.lower(achievement_name[n])] = n
        all_achievements.vanilla[string.lower(AnyTypeRet(GML.array_global_read_2("achievement_list", i, fieldID["name"])))] = n
	end
end

------------------------------------------
-- GLOBAL FUNCTIONS ----------------------
------------------------------------------

Achievement.find = contextSearch(all_achievements, "Achievement.find")
Achievement.findAll = contextFindAll(all_achievements, "Achievement.findAll")

local function achievement_new(name)
	local context = GetModContext()
	if name == nil then
		name = "[Achievement" .. tostring(contextCount(all_achievements, context)) .. "]"
	end
	contextVerify(all_achievements, name, context, "Achievement", 1)

	maxachievement = maxachievement + 1
	local nid = maxachievement
	local new = static.new(nid)
	id_to_achievement[nid] = new
	GML.variable_global_set("achievement_number", AnyTypeArg(nid))

	contextInsert(all_achievements, name, context, new)

	-- achievement_finished[new] = 0
    -- achievement_progress[new] = 0
    -- achievement_requirement[new] = 1
    -- achievement_sprite[new] = default_sprite
    -- achievement_unlock_message[new] = ""
    -- achievement_death_reset[new] = true
    -- achievement_description[new] = ""
    -- achievement_highscore_desc[new] = ""
    -- achievement_parent[new] = nil
    -- achievement_name[new] = name
    -- achievement_origin[new] = context
    achievement_callbacks[new] = {}

	GML.achievement_add(nid, name, context)

	checkCheevoFinished(new, 1)

	return new
end

function Achievement.new(name)
	if name ~= nil and type(name) ~= "string" then typeCheckError("Achievement.new", 1, "name", "string or nil", name) end
	return achievement_new(name)
end

setmetatable(Achievement, {__call = function(t, name)
	if name ~= nil and type(name) ~= "string" then typeCheckError("Achievement", 1, "name", "string or nil", name) end
	return achievement_new(name)
end})
