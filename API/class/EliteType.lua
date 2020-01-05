local GMClass = require 'util/GMClass'

local class, wrap, ids = GMClass{
	-- Class properties ------------
	"EliteType", "ArrayClass",
	arrayName = "elite_info",
	nameIndex = 3,
	originIndex = 4,
	allocator = {function(origin, name) return GML.alloc_elite_type(origin, name) end},

	-- Fields -------------------------------------
	-- Name               Kind     Id  Type
	displayName      = {  "f",     0 , "string"  },
	color            = {  "f",     1 , "Color"   },
	colorHard        = {  "f",     2 , "Color"   },
	palette          = {  "f",     5 , "Sprite"  },
	-- Aliases ------------------------------------
	colour           = {  "a", "color"           },
	colourHard       = {  "a", "colorHard"       },
}

local gm_map_palette = AnyTypeRet(GML.variable_global_get("object_to_palette"))
local gm_list_palette = AnyTypeRet(GML.variable_global_get("elite_palette_list"))

-- Palettify a sprite
function class.registerPalette(palette, object)
	if typeOf(palette) ~= "Sprite" then typeCheckError("EliteType.registerPalette", 1, "palette", "Sprite", palette) end
	if typeOf(object) ~= "GMObject" then typeCheckError("EliteType.registerPalette", 2, "object", "GMObject", object) end
	local spr_id = SpriteUtil.toID(palette)
	local obj_id = GMObject.toID(object)
	GML.ds_map_replace(gm_map_palette, AnyTypeArg(obj_id), AnyTypeArg(spr_id))
	GML.ds_list_add(gm_list_palette, AnyTypeArg(spr_id))
	GML.elite_generate_palettes(AnyTypeArg(spr_id))
end

-- Force refresh of all palettes
function class.refreshPalettes()
	GML.elite_generate_palettes(AnyTypeArg(nil))
end

-- Temporary until type conv stuff is more standard
RoRElite = {toID = function(v) return GMClass.ids[v] end, fromID = wrap}

return class
