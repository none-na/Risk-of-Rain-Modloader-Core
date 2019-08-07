local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Sprite", true, SpriteUtil.baseClass)
meta.__tostring = __tostring_default_namespace

-- Table for all sprites by context
local all_sprites = {vanilla = {}}

-- Sprite properties
local sprite_name = {}
local sprite_origin = {}
local id_to_sprite = {}

function lookup:getOrigin()
	if not children[self] then methodCallError("Sprite:getOrigin", self) end
	return sprite_origin[self]
end

function lookup:getName()
	if not children[self] then methodCallError("Sprite:getName", self) end
	return sprite_name[self]
end

function lookup:replace(new)
	if not children[self] then methodCallError("Sprite:replace", self) end
	if typeOf(new) ~= "Sprite" then typeCheckError("Sprite:replace", 1, "new", "Sprite", new) end

	SpriteUtil.resetBase(self)
	GML.sprite_assign(ids[self], ids[new])
end

lookup.id = {get = function(sound)
	return ids[self]
end}
lookup.ID = lookup.id

-- Wrap basegame sprites
do
	local noRename = {
		sprTitle = true,
		background90 = true,
		background38 = true,
		background104 = true,
		background81 = true,
		background115 = true,
		sprite653 = true,
		sprite634 = true
	}
	local ttable = all_sprites.vanilla
	local t = 0
	while GML.sprite_exists(t) == 1 do
		local new = static.new(t)
		local name = ffi.string(GML.sprite_get_name(t))
		if not noRename[name] then
			name = string.sub(name, 2, -1)
		end
		ttable[string.lower(name)] = new

		sprite_name[new] = name
		sprite_origin[new] = "Vanilla"
		id_to_sprite[t] = new
		SpriteUtil.resetBase(new)
		
		t = t + 1
	end
end

--
Sprite = {}
Sprite.find = contextSearch(all_sprites, "Sprite.find")
Sprite.findAll = contextFindAll(all_sprites, "Sprite.findAll")

-- Load sprite
local function load_sprite(funcName, name, fname, frames, xorigin, yorigin)
	if type(name) ~= "string" then typeCheckError(funcName, 1, yorigin == nil and "fname" or "name", "string", name) end
	local arg_off
	if yorigin == nil then
		-- Shift args for optional name
		fname, frames, xorigin, yorigin = name, fname, frames, xorigin
		name = getFilename(name)
		arg_off = -1
	else
		if type(fname) ~= "string" then typeCheckError(funcName, 2, "fname", "string", fname) end
		arg_off = 0
	end
	if type(frames) ~= "number" then typeCheckError(funcName, 3 + arg_off, "frames", "number", frames) end
	if type(xorigin) ~= "number" then typeCheckError(funcName, 4 + arg_off, "xorigin", "number", xorigin) end
	if type(yorigin) ~= "number" then typeCheckError(funcName, 5 + arg_off, "yorigin", "number", yorigin) end

	local context = GetModContext()
	contextVerify(all_sprites, name, context, "Sprite")

	local s = GML.sprite_add(ResolveModPath()..fname, frames, xorigin, yorigin)
	if s < 0 then
		s = GML.sprite_add(ResolveModPath()..fname..".png", frames, xorigin, yorigin)
	end
	
	if s < 0 then
		return error(string.format('unable to load sprite %q, the file could not be found', fname), 2)
	else
		local new = static.new(s)
		registerNetID("sprite", s, context, name)
		sprite_origin[new] = context
		id_to_sprite[s] = new
		sprite_name[new] = name
		SpriteUtil.resetBase(new)
		contextInsert(all_sprites, name, context, new)
		return new
	end
end

function Sprite.load(name, fname, frames, xorigin, yorigin)
	return load_sprite("Sprite.load", name, fname, frames, xorigin, yorigin)
end

setmetatable(Sprite, {__call = function(t, name, fname, frames, xorigin, yorigin)
	return load_sprite("Sprite", name, fname, frames, xorigin, yorigin)
end})

function Sprite.fromID(id)
	if type(id) ~= "number" then typeCheckError("Sprite.fromID", 1, "id", "number", id) end
	return id_to_sprite[id]
end
--
SpriteUtil.class = static
function SpriteUtil.fromID(id)
	return id_to_sprite[id]
end
function SpriteUtil.toID(sprite)
	return ids[sprite]
end
function SpriteUtil.createFromID(id, context, name)
	local new = static.new(id)
	registerNetID("sprite", id, context, name)
	sprite_origin[new] = context
	id_to_sprite[id] = new
	sprite_name[new] = name
	SpriteUtil.resetBase(new)
	contextInsert(all_sprites, name, context, new)
	return new
end
SpriteUtil.allSprites = all_sprites

-- env
mods.modenv.Sprite = Sprite

