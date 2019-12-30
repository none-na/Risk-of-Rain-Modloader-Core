local GMClass = require 'util/GMClass'

local class, wrap, ids = GMClass{
	-- Class properties ------------
	"MonsterLog", "ArrayClass",
	arrayName = "mons_info",
	nameIndex = 0,
	originIndex = 7,
	allocator = function(origin, name) return GML.alloc_monster_log(origin, name) end,

	-- Fields ----------------------
	-- Name               Kind     Id  Type
	displayName      = {  "f",     9 , "string"  },
	story            = {  "f",     1 , "string"  },
	statHP           = {  "f",     2 , "number"  },
	statDamage       = {  "f",     3 , "number"  },
	statSpeed        = {  "f",     4 , "number"  },
	sprite           = {  "f",     5 , "Sprite"  },
	portrait         = {  "f",     6 , "Sprite"  },
	portraitSubimage = {  "f",     8 , "number"  },
}

class.map = dsWrapper.map(AnyTypeRet(GML.variable_global_get("mons_id_map")),
	"GMObject", GMObject, nil,
	"MonsterLog", function(v) return ids[v] end, function(v) return wrap(v) end)

return class
