local GMClass = require 'util/GMClass'

-- Type field stuff
local num_to_type = { [0] = "classic", [1] = "player", [2] = "origin", [3] = "offscreen" }
local type_to_num = { classic = 0, player = 1, origin = 2, offscreen = 3 }
local function type_get(self) return num_to_type[GMClass.get(self, 1)] end
local function type_set(self, v)
	if type(v) ~= "string" then fieldTypeError("MonsterCard.type", "string", v) end
	if not type_to_num[v:lower()] then error("'" .. v .. "' is not a valid enemy spawn type", 2) end
	GMClass.set(self, 1, type_to_num[v:lower()])
end

local class, wrap, ids = GMClass{
	-- Class properties ------------
	"MonsterCard", "ArrayClass",
	arrayName = "enemy_info",
	nameIndex = 0,
	originIndex = 9,
	allocator = {function(origin, name, obj) return GML.alloc_monster_card(name, origin, obj.ID) end, {"GMObject"}},

	-- Fields ----------------------
	-- Name               Kind     Id  Type
	--type             = {  "f",     1, "number"    },
	cost             = {  "f",     2, "number"    },
	sprite           = {  "f",     3, "Sprite"    },
	object           = {  "f",     4, "GMObject",  "r" },
	sound            = {  "f",     5, "Sound",     "nrw" },
	isBoss           = {  "f",     6, "boolean"   },
	canBlight        = {  "f",     6, "boolean"   },

	-- Enum field of spwan type
	type             = {  "lf", type_get, type_set  },

	-- Read-only field containing a List<EliteType>
	eliteTypes       = {  "lf", function(self) return dsWrapper.list(GMClass.get(self, 11), "EliteType", RoRElite) end, nil  },

	-- Old style object getter
	getObject        = {  "lf", function(self) return self.object end  }
}

-- Temporary until type conv stuff is more standard
RoRMonsterCard = {toID = function(v) return ids[v] end, fromID = wrap}

return class