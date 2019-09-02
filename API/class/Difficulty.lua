local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Difficulty", true)
meta.__tostring = __tostring_default_namespace

local all_diff = {vanilla = {}}
local diff_origin = {}
local diff_name = {}
local diff_from_id = {}
diff_id_max = 3

lookup.displayName = {
	get = function(t)
		return AnyTypeRet(GML.array_global_read_2("diff_info", ids[t], 0))
	end,
	set = function(t, v)
		if typeOf(v) ~= "string" then fieldTypeError("Difficulty.displayName", "string", v) end
		GML.array_global_write_2("diff_info", AnyTypeArg(v), ids[t], 0)
	end
}

lookup.icon = {
	get = function(t)
		return Sprite.fromID(AnyTypeRet(GML.array_global_read_2("diff_info", ids[t], 1)))
	end,
	set = function(t, v)
		if typeOf(v) ~= "Sprite" then fieldTypeError("Difficulty.icon", "Sprite", v) end
		GML.array_global_write_2("diff_info", AnyTypeArg(v.ID), ids[t], 1)
	end
}

lookup.scale = {
	get = function(t)
		return AnyTypeRet(GML.array_global_read_2("diff_info", ids[t], 2))
	end,
	set = function(t, v)
		if typeOf(v) ~= "number" then fieldTypeError("Difficulty.scale", "number", v) end
		GML.array_global_write_2("diff_info", AnyTypeArg(v), ids[t], 2)
	end
}

lookup.scaleOnline = {
	get = function(t)
		return AnyTypeRet(GML.array_global_read_2("diff_info", ids[t], 3))
	end,
	set = function(t, v)
		if typeOf(v) ~= "number" then fieldTypeError("Difficulty.scaleOnline", "number", v) end
		GML.array_global_write_2("diff_info", AnyTypeArg(v), ids[t], 3)
	end
}

lookup.description = {
	get = function(t)
		return AnyTypeRet(GML.array_global_read_2("diff_info", ids[t], 4))
	end,
	set = function(t, v)
		if typeOf(v) ~= "string" then fieldTypeError("Difficulty.description", "string", v) end
		GML.array_global_write_2("diff_info", AnyTypeArg(v), ids[t], 4)
	end
}

lookup.enableMissileIndicators = {
	get = function(t)
		return AnyTypeRet(GML.array_global_read_2("diff_info", ids[t], 6)) > 0
	end,
	set = function(t, v)
		if typeOf(v) ~= "boolean" then fieldTypeError("Difficulty.enableMissileIndicators", "boolean", v) end
		GML.array_global_write_2("diff_info", AnyTypeArg(v and 1 or 0), ids[t], 6)
	end
}

lookup.forceHardElites = {
	get = function(t)
		return AnyTypeRet(GML.array_global_read_2("diff_info", ids[t], 7)) > 0
	end,
	set = function(t, v)
		if typeOf(v) ~= "boolean" then fieldTypeError("Difficulty.forceHardElites", "boolean", v) end
		GML.array_global_write_2("diff_info", AnyTypeArg(v and 1 or 0), ids[t], 7)
	end
}

lookup.enableBlightedEnemies = {
	get = function(t)
		return AnyTypeRet(GML.array_global_read_2("diff_info", ids[t], 8)) > 0
	end,
	set = function(t, v)
		if typeOf(v) ~= "boolean" then fieldTypeError("Difficulty.enableBlightedEnemies", "boolean", v) end
		GML.array_global_write_2("diff_info", AnyTypeArg(v and 1 or 0), ids[t], 8)
	end
}



function lookup:getName()
	if not children[self] then methodCallError("Difficulty:getName", self) end
	return diff_name[self]
end
function lookup:getOrigin()
	if not children[self] then methodCallError("Difficulty:getOrigin", self) end
	return diff_origin[self]
end



Difficulty = {}

Difficulty.find = contextSearch(all_diff, "Difficulty.find")
Difficulty.findAll = contextFindAll(all_diff, "Difficulty.findAll")

-- Create new
do
	local default_icon = GML.asset_get_index("sDifficultyRainstorm")

	local function new_diff(fname, name)
		if type(name) ~= "string" then typeCheckError(fname, 1, "name", "string", name) end
		local context = GetModContext()

		contextVerify(all_diff, name, context, "Difficulty", 1)

		diff_id_max = diff_id_max + 1
		local n = static.new(diff_id_max)
		GML.variable_global_set("diff_number", AnyTypeArg(diff_id_max))

		diff_name[n] = name
		diff_origin[n] = context

		GML.array_global_write_2("diff_info", AnyTypeArg(name), diff_id_max, 0)
		GML.array_global_write_2("diff_info", AnyTypeArg(default_icon), diff_id_max, 1)
		GML.array_global_write_2("diff_info", AnyTypeArg(0.12), diff_id_max, 2)
		GML.array_global_write_2("diff_info", AnyTypeArg(0.017), diff_id_max, 3)
		GML.array_global_write_2("diff_info", AnyTypeArg("&y&-" .. name:upper() .. "-&!&"), diff_id_max, 4)
		GML.array_global_write_2("diff_info", AnyTypeArg(context .. "-" .. name), diff_id_max, 5)
		GML.array_global_write_2("diff_info", AnyTypeArg(1), diff_id_max, 6)
		GML.array_global_write_2("diff_info", AnyTypeArg(0), diff_id_max, 7)
		GML.array_global_write_2("diff_info", AnyTypeArg(0), diff_id_max, 8)

		contextInsert(all_diff, name, context, n)

		return n
	end

	function Difficulty.new(obj, name)
		return new_diff("Difficulty.new", obj, name)
	end
	setmetatable(Difficulty, {__call = function(t, obj, name)
		return new_diff("Difficulty", obj, name)
	end})
end

for i = 1, diff_id_max do
	local n = static.new(i)
	local name = AnyTypeRet(GML.array_global_read_2("diff_info", i, 0))
	print(i)
	diff_origin[n] = "Vanilla"
	diff_name[n] = name
	all_diff.vanilla[name:lower()] = n
end


-- Used to get multipliers for damage, hp, costs, etc
function Difficulty.getScaling(kind)
	if kind ~= nil and type(kind) ~= "string" then typeCheckError("Difficulty.getScaling", 1, "kind", "string or nil", kind) end

	local typ = 0
	if kind ~= nil then
		kind = kind:lower()
		if kind == "hp" then
			typ = 1
		elseif kind == "damage" then
			typ = 2
		elseif kind ~= "cost" then
			error("Unknown scaling type '" .. kind .. "'", 2)
		end
	end

	local mul = GML.get_stats_multiplier(typ)

	if kind == "cost" then
		mul = mul * 2
	end

	return mul
end

function Difficulty.getActive()
	return diff_from_id[AnyTypeRet(GML.variable_global_get("diff_level"))]
end

mods.modenv.Difficulty = Difficulty
