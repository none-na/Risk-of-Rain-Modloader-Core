local GMClass = require 'util/GMClass'

local class, wrap, ids = GMClass{
	-- Class properties ------------
	"MonsterCard", "ArrayClass",
	arrayName = "enemy_info",
	nameIndex = 0,
	originIndex = 9,
	allocator = {function(origin, name, obj) return GML.alloc_monster_card(name, origin, obj.ID) end, {"GMObject"}},

	-- Fields ----------------------
	-- Name               Kind     Id  Type
	type             = {  "f",     1, "number"    },
	cost             = {  "f",     2, "number"    },
	sprite           = {  "f",     3, "Sprite"    },
	object           = {  "f",     4, "GMObject",  "r" },
	sound            = {  "f",     5, "Sound"     },
	isBoss           = {  "f",     6, "boolean"   },
	canBlight        = {  "f",     6, "boolean"   },

	-- Read-only field containing a List<EliteType>
	--eliteTypes       = {  "lf", function(self) return dsWrapper.list(GMClass.get(self, 11), "EliteType", RoRElite) end, nil   },
}

-- Temporary until type conv stuff is more standard
RoRMonsterCard = {toID = function(v) return ids[v] end, fromID = wrap}

return class