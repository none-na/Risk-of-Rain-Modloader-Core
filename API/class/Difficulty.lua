
Difficulty = {}

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

mods.modenv.Difficulty = Difficulty
