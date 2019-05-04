local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("BaseSprite", true)

local sprite_properties = setmetatable({}, {__mode = "k"})

function lookup:draw(x, y, subimage)
	if not children[self] then methodCallError("Sprite:draw", self) end
	if type(x) ~= "number" then typeCheckError("Sprite:draw", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("Sprite:draw", 2, "y", "number", y) end
	if subimage ~= nil and type(subimage) ~= "number" then typeCheckError("Sprite:draw", 3, "subimage", "nil or number", subimage) end
	if subimage == nil or subimage < 1 then subimage = 1 end
	GML.draw_sprite(ids[self], subimage and subimage - 1, x, y)
end

do
	local function makeProperty(name, getter)
		return {
			get = function(self)
				if not SpriteUtil.isValid(self) then 
					error("attempt to access invalid DynamicSprite reference", 2) 
				end 
				local props = sprite_properties[self]
				if props[name] then
					return props[name]
				else
					local v = getter(ids[self])
					props[name] = v
					return v
				end
			end
		}
	end
	
	lookup.xorigin = makeProperty("xorigin", GML.sprite_get_xoffset)
	lookup.yorigin = makeProperty("yorigin", GML.sprite_get_yoffset)
	lookup.width = makeProperty("width", GML.sprite_get_width)
	lookup.height = makeProperty("height", GML.sprite_get_height)
	lookup.frames = makeProperty("frames", GML.sprite_get_number)
	lookup.boundingBoxLeft = makeProperty("lbb", GML.sprite_get_bbox_left)
	lookup.boundingBoxRight = makeProperty("rbb", GML.sprite_get_bbox_right)
	lookup.boundingBoxTop = makeProperty("tbb", GML.sprite_get_bbox_top)
	lookup.boundingBoxBottom = makeProperty("bbb", GML.sprite_get_bbox_bottom)
end


SpriteUtil = {}
SpriteUtil.baseClass = static
function SpriteUtil.resetBase(spr)
    sprite_properties[spr] = {}
end
SpriteUtil.baseIDs = ids

require("api/class/graphics/Sprite")
require("api/class/graphics/DynamicSprite")
