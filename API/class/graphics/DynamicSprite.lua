local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("DynamicSprite", true, SpriteUtil.baseClass)
meta.__tostring = __tostring_default_namespace

local is_valid = setmetatable({}, {__mode = "k"})

local function verifyCall(self)
	if not is_valid[self] then
		error("attempt to access invalid DynamicSprite reference", 3)
	end
end

function lookup:delete()
	if not children[self] then methodCallError("DynamicSprite:delete", self) end
	verifyCall(self)
	GML.sprite_delete(ids[self])
	is_valid[self] = false
end

function lookup:finalise(name)
	if not children[self] then methodCallError("DynamicSprite:finalise", self) end
	if type(name) ~= "string" then typeCheckError("DynamicSprite:finalise", 1, "name", "string", name) end
	local context = GetModContext()
	contextVerify(SpriteUtil.allSprites, name, context, "Sprite")
	local new = SpriteUtil.createFromID(ids[self], context, name)
	is_valid[self] = false
	return new
end
lookup.finalize = lookup.finalise

function lookup:addFrame(source, x, y, w, h)
	if not children[self] then methodCallError("DynamicSprite:addFrame", self) end
	if typeOf(source) ~= "Surface" then typeCheckError("DynamicSprite:addFrame", 1, "source", "Surface", source) end
	if x ~= nil and type(x) ~= "number" then typeCheckError("DynamicSprite:addFrame", 2, "x", "number or nil", x) end
	if y ~= nil and type(y) ~= "number" then typeCheckError("DynamicSprite:addFrame", 3, "y", "number or nil", y) end
	if w ~= nil and type(w) ~= "number" then typeCheckError("DynamicSprite:addFrame", 4, "w", "number or nil", w) end
	if h ~= nil and type(h) ~= "number" then typeCheckError("DynamicSprite:addFrame", 5, "h", "number or nil", h) end
	if x == nil then x = 0 end
	if y == nil then y = 0 end
	if w == nil then w = source.width end
	if h == nil then h = source.height end
	GML.sprite_add_from_surface(ids[self], SurfaceUtil.ids[source], x, y, w, h, 0, 0)
end

function SpriteUtil.createDynamic(id)
	local new = static.new(id)
	is_valid[new] = GML.sprite_exists(id)
	SpriteUtil.resetBase(new)
	return new
end

function SpriteUtil.isValid(sprite)
	if not children[sprite] then
		return true
	else
		return is_valid[sprite]
	end
end
