local GMClass = require 'util/GMClass'

local class, wrap, ids = GMClass{
	-- Class properties ------------
	"EliteType", "ArrayClass",
	arrayName = "elite_info",
	nameIndex = 3,
	originIndex = 4,

	-- Fields ----------------------
	-- Name               Kind     Id  Type
	displayName      = {  "f",     0 , "string"  },
	color            = {  "f",     1 , "Color"   },
	colorHard        = {  "f",     2 , "Color"   },

	colour     = {  "a", "color"      },
	colourHard = {  "a", "colorHard"  },
}

-- Temporary until type conv stuff is more standard
RoRElite = {toID = function(v) return GMClass.ids[v] end, fromID = wrap}

return class
