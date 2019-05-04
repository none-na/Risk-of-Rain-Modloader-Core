local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("ParticleType", true)
meta.__tostring = __tostring_default_namespace
-- Create global table
ParticleType = {}

type_name = {}
type_origin = {}

all_types = {vanilla = {}}

------------------------------------------
-- COMMON --------------------------------
------------------------------------------

function lookup:getName()
	if not children[self] then methodCallError("ParticleType:getName", self) end

	return type_name[self]
end

function lookup:getOrigin()
	if not children[self] then methodCallError("ParticleType:getOrigin", self) end

	return type_origin[self]
end

------------------------------------------
-- SETTERS -------------------------------
------------------------------------------

function lookup:sprite(sprite, animate, stretch, random)
	if not children[self] then methodCallError("ParticleType:sprite", self) end
	if typeOf(sprite) ~= "Sprite" then typeCheckError("ParticleType:sprite", 1, "sprite", "Sprite", sprite) end
	if type(animate) ~= "boolean" then typeCheckError("ParticleType:sprite", 2, "animate", "boolean", animate) end
	if type(stretch) ~= "boolean" then typeCheckError("ParticleType:sprite", 3, "stretch", "boolean", stretch) end
	if type(random) ~= "boolean" then typeCheckError("ParticleType:sprite", 4, "random", "boolean", random) end

	GML.part_type_sprite(ids[self], SpriteUtil.toID(sprite), animate and 1 or 0, stretch and 1 or 0, random and 1 or 0)
end

local typeShape = {
	pixel = 0,
	disk = 1,
	disc = 1,
	square = 2,
	line = 3,
	star = 4,
	circle = 5,
	ring = 6,
	sphere = 7,
	flare = 8,
	spark = 9,
	explosion = 10,
	cloud = 11,
	smoke = 12,
	snow = 13
}

function lookup:shape(shape)
	if not children[self] then methodCallError("ParticleType:shape", self) end
	if type(shape) ~= "string" then typeCheckError("ParticleType:shape", 1, "shape", "string", shape) end

	local ts = typeShape[string.lower(shape)]
	if not ts then error("'" .. shape .. "' is not a known particle shape", 2) end
	GML.part_type_shape(ids[self], ts)
end

-- Colour
function lookup:color(c1, c2, c3)
	if not children[self] then methodCallError("ParticleType:color", self) end
	if typeOf(c1) ~= "Color" then typeCheckError("ParticleType:color", 1, "c1", "Color", c1) end
	if c2 ~= nil and typeOf(c2) ~= "Color" then typeCheckError("ParticleType:color", 2, "c2", "Color or nil", c2) end
	if c3 ~= nil and typeOf(c3) ~= "Color" then typeCheckError("ParticleType:color", 3, "c3", "Color or nil", c3) end

	if c2 == nil then
		GML.part_type_color1(ids[self], GetColorValue(c1))
	elseif c3 == nil then
		GML.part_type_color2(ids[self], GetColorValue(c1), GetColorValue(c2))
	else
		GML.part_type_color3(ids[self], GetColorValue(c1), GetColorValue(c2), GetColorValue(c3))
	end
end
lookup.colour = lookup.color

-- Alpha
function lookup:alpha(a1, a2, a3)
	if not children[self] then methodCallError("ParticleType:alpha", self) end
	if type(a1) ~= "number" then typeCheckError("ParticleType:alpha", 1, "a1", "number", a1) end
	if a2 ~= nil and type(a2) ~= "number" then typeCheckError("ParticleType:alpha", 2, "a2", "number or nil", a2) end
	if a3 ~= nil and type(a3) ~= "number" then typeCheckError("ParticleType:alpha", 3, "a3", "number or nil", a3) end

	if a2 == nil then
		GML.part_type_alpha1(ids[self], a1)
	elseif a3 == nil then
		GML.part_type_alpha2(ids[self], a1, a2)
	else
		GML.part_type_alpha3(ids[self], a1, a2, a3)
	end
end

-- Size
function lookup:scale(xscale, yscale)
	if not children[self] then methodCallError("ParticleType:scale", self) end
	if type(xscale) ~= "number" then typeCheckError("ParticleType:scale", 1, "xscale", "number", xscale) end
	if type(yscale) ~= "number" then typeCheckError("ParticleType:scale", 2, "yscale", "number", yscale) end

	GML.part_type_scale(ids[self], xscale, yscale)
end

function lookup:size(min, max, add, wiggle)
	if not children[self] then methodCallError("ParticleType:size", self) end
	if type(min) ~= "number" then typeCheckError("ParticleType:size", 1, "min", "number", min) end
	if type(max) ~= "number" then typeCheckError("ParticleType:size", 2, "max", "number", max) end
	if type(add) ~= "number" then typeCheckError("ParticleType:size", 3, "add", "number", add) end
	if type(wiggle) ~= "number" then typeCheckError("ParticleType:size", 4, "wiggle", "number", wiggle) end

	GML.part_type_size(ids[self], min, max, add, wiggle)
end

-- Blend mode
function lookup:additive(additive)
	if not children[self] then methodCallError("ParticleType:additive", self) end
	if type(additive) ~= "boolean" then typeCheckError("ParticleType:additive", 1, "additive", "boolean", additive) end

	GML.part_type_blend(ids[self], additive)
end

-- Rotation
function lookup:angle(min, max, add, wiggle, relative)
	if not children[self] then methodCallError("ParticleType:angle", self) end
	if type(min) ~= "number" then typeCheckError("ParticleType:angle", 1, "min", "number", min) end
	if type(max) ~= "number" then typeCheckError("ParticleType:angle", 2, "max", "number", max) end
	if type(add) ~= "number" then typeCheckError("ParticleType:angle", 3, "add", "number", add) end
	if type(wiggle) ~= "number" then typeCheckError("ParticleType:angle", 4, "wiggle", "number", wiggle) end
	if type(relative) ~= "boolean" then typeCheckError("ParticleType:angle", 5, "relative", "boolean", relative) end

	GML.part_type_orientation(ids[self], min, max, add, wiggle, relative)
end

-- Movement
function lookup:speed(min, max, add, wiggle)
	if not children[self] then methodCallError("ParticleType:speed", self) end
	if type(min) ~= "number" then typeCheckError("ParticleType:speed", 1, "min", "number", min) end
	if type(max) ~= "number" then typeCheckError("ParticleType:speed", 2, "max", "number", max) end
	if type(add) ~= "number" then typeCheckError("ParticleType:speed", 3, "add", "number", add) end
	if type(wiggle) ~= "number" then typeCheckError("ParticleType:speed", 4, "wiggle", "number", wiggle) end

	GML.part_type_speed(ids[self], min, max, add, wiggle)
end

function lookup:direction(min, max, add, wiggle)
	if not children[self] then methodCallError("ParticleType:direction", self) end
	if type(min) ~= "number" then typeCheckError("ParticleType:direction", 1, "min", "number", min) end
	if type(max) ~= "number" then typeCheckError("ParticleType:direction", 2, "max", "number", max) end
	if type(add) ~= "number" then typeCheckError("ParticleType:direction", 3, "add", "number", add) end
	if type(wiggle) ~= "number" then typeCheckError("ParticleType:direction", 4, "wiggle", "number", wiggle) end

	GML.part_type_direction(ids[self], min, max, add, wiggle)
end

function lookup:gravity(amount, direction)
	if not children[self] then methodCallError("ParticleType:gravity", self) end
	if type(amount) ~= "number" then typeCheckError("ParticleType:gravity", 1, "amount", "number", amount) end
	if type(direction) ~= "number" then typeCheckError("ParticleType:gravity", 2, "direction", "number", direction) end

	GML.part_type_gravity(ids[self], amount, direction)
end

-- Life
function lookup:life(min, max)
	if not children[self] then methodCallError("ParticleType:life", self) end
	if type(min) ~= "number" then typeCheckError("ParticleType:life", 1, "min", "number", min) end
	if type(max) ~= "number" then typeCheckError("ParticleType:life", 2, "max", "number", max) end

	GML.part_type_life(ids[self], min, max)
end

-- Children
function lookup:createOnStep(child, amount)
	if not children[self] then methodCallError("ParticleType:createOnStep", self) end
	if not children[child] then typeCheckError("ParticleType:createOnStep", 1, "child", "ParticleType", particle) end
	if type(amount) ~= "number" then typeCheckError("ParticleType:createOnStep", 2, "amount", "number", amount) end
	if child == self then error("A particle can not spawn itself each step since this would create an infinite loop", 3) end
	
	GML.part_type_step(ids[self], amount, ids[child])
end

function lookup:createOnDeath(child, amount)
	if not children[self] then methodCallError("ParticleType:createOnDeath", self) end
	if not children[child] then typeCheckError("ParticleType:createOnDeath", 1, "child", "ParticleType", particle) end
	if type(amount) ~= "number" then typeCheckError("ParticleType:createOnDeath", 2, "amount", "number", amount) end
	if child == self then error("A particle can not spawn itself on death since this would create an infinite loop", 3) end
	
	GML.part_type_death(ids[self], amount, ids[child])
end

-- Reset
function lookup:reset()
	GML.part_type_clear(ids[self])
end

------------------------------------------
-- SPAWNERS ------------------------------
------------------------------------------

local systems = {
	above = AnyTypeRet(GML.variable_global_get("above")),
	below = AnyTypeRet(GML.variable_global_get("below")),
	middle = AnyTypeRet(GML.variable_global_get("middle"))
}

function lookup:burst(depth, x, y, amount, color)
	if not children[self] then methodCallError("ParticleType:burst", self) end
	if type(depth) ~= "string" then typeCheckError("ParticleType:burst", 1, "depth", "string", depth) end
	if type(x) ~= "number" then typeCheckError("ParticleType:burst", 2, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("ParticleType:burst", 3, "y", "number", y) end
	if type(amount) ~= "number" then typeCheckError("ParticleType:burst", 4, "amount", "number", y) end
	if color ~= nil and typeOf(color) ~= "Color" then typeCheckError("ParticleType:burst", 5, "color", "Color or nil", color) end

	local system = systems[string.lower(depth)]
	if not system then error("'" .. depth .. "' is not a valid particle depth", 3) end
	if color == nil then
		GML.part_particles_create(system, x, y, ids[self], amount)
	else
		GML.part_particles_create_color(system, x, y, ids[self], GetColorValue(color), amount)
	end
end

------------------------------------------
-- WRAP VANILLA --------------------------
------------------------------------------

do
	local partList = {
		"Fire", "Fire2", "FireIce", "Fire3", "Fire4",
		"Spark", "Rubble1", "Rubble2", "Poison",
		"Dust1", "Dust2", "JellyDust", "Assassin",
		"Speed", "SpeedPoison", "Lightning", "Heal",
		"Smoke", "Smoke2", "Smoke3", "Smoke4",
		"Smoke5", "Snow", "SporeOld", "Spore", "Ice",
		"Hero", "Lava", "PixelDust", "Leaf", "Mortar",
		"Radioactive", "HuntressBolt1",
		"HuntressBolt2", "HuntressBolt3", "TempleSnow",
		"Blood2", "Blood1", "Fire3", "EngiHarpoon",
		"HarpoonEnemy", "Rain", "Rain2", "RainSplash",
		"CyborgBullet1", "Bubble", "SpaceDust",
		"DiagFire", "CutsceneSmoke", "SmokeFirework",
		"IceRelic", "FireworkFlare", "FireworkSmoke"
	}

	for _, v in ipairs(partList) do
		local new = static.new(AnyTypeRet(GML.variable_global_get("p"..v)))
		type_origin[new] = "Vanilla"
		type_name[new] = v
		all_types.vanilla[string.lower(v)] = new
	end
end

------------------------------------------
-- GLOBAL METHODS ------------------------
------------------------------------------

ParticleType.find = contextSearch(all_types, "ParticleType.find")
ParticleType.findAll = contextFindAll(all_types, "ParticleType.findAll")

local function new_particle(fname, name)
	if name ~= nil and type(name) ~= "string" then typeCheckError(fname, 1, "name", "string or nil", name) end

	local context = GetModContext()
	if name == nil then
		name = "[CustomObject" .. tostring(contextCount(all_types, context)) .. "]"
	end
	
	contextVerify(all_types, name, context, "ParticleType")

	local nid = GML.part_type_create()
	local new = static.new(nid)
	contextInsert(all_types, name, context, new)
	type_origin[new] = context
	type_name[new] = name

	return new
end

function ParticleType.new(name)
	return new_particle("ParticleType.new", name)
end

setmetatable(ParticleType, {__call = function(t, name)
	return new_particle("ParticleType", name)
end})


mods.modenv.ParticleType = ParticleType
