
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor
local math_ceil = math.ceil

---------------------------------------------
---------------------------------------------
-- Table library ----------------------------
---------------------------------------------
---------------------------------------------

function table.irandom(t)
	if typeOf(t) ~= "table" then typeCheckError("table.irandom", 1, "t", "table", t) end
	return t[math_random(#t)]
end

function table.random(t)
	if typeOf(t) ~= "table" then typeCheckError("table.random", 1, "t", "table", t) end
	local count = 0
	for _, _ in pairs(t) do
		count = count + 1
	end
	
	count = math_random(1, count)
	
	for _, v in pairs(t) do
		count = count - 1
		if(count == 0) then
			return v
		end
	end
end

---------------------------------------------
---------------------------------------------
-- Math library -----------------------------
---------------------------------------------
---------------------------------------------

function math.chance(percent)
	if type(percent) ~= "number" then typeCheckError("math.chance", 1, "percent", "number", percent) end
	return math.random(100) <= percent
end

function math.approach(value, target, step)
	if type(value) ~= "number" then typeCheckError("math.approach", 1, "value", "number", value) end
	if type(target) ~= "number" then typeCheckError("math.approach", 2, "target", "number", target) end
	if step ~= nil and type(step) ~= "number" then typeCheckError("math.approach", 3, "step", "number or nil", step) end
	step = step and math_abs(step) or 1
	if math_abs(target - value) <= step then
		return target
	elseif target > value then
		return value + step
	else
		return value - step
	end
end

function math.sign(n)
	if type(n) ~= "number" then typeCheckError("math.sign", 1, "n", "number", n) end
	if n > 0 then
		return 1
	elseif n < 0 then
		return -1
	else
		return 0
	end
end

function math.round(n)
	if type(n) ~= "number" then typeCheckError("math.round", 1, "n", "number", n) end
	if n >= 0 then
		return math_floor(n + 0.5)
	else
		return math_ceil(n - 0.5)
	end
end

function math.clamp(value, lower, upper)
	if type(value) ~= "number" then typeCheckError("math.clamp", 1, "value", "number", value) end
	if type(lower) ~= "number" then typeCheckError("math.clamp", 2, "lower", "number", lower) end
	if type(upper) ~= "number" then typeCheckError("math.clamp", 3, "upper", "number", upper) end
	if value > upper then
		return upper
	elseif value < lower then
		return lower
	else
		return value
	end
end

function math.lerp(from, to, amount)
	if type(from) ~= "number" then typeCheckError("math.lerp", 1, "from", "number", from) end
	if type(to) ~= "number" then typeCheckError("math.lerp", 2, "to", "number", to) end
	if type(amount) ~= "number" then typeCheckError("math.lerp", 3, "amount", "number", amount) end
	return a + (b - a) * t
end
