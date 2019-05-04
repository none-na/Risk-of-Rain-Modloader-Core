
local bit = require("bit")

local static, lookup, meta, ids, special, children = NewClass("Color", false, nil)

local col_value = setmetatable({}, {__mode = "k"})

-- Global function for getting the GM color number of a color object
function GetColorValue(col)
	return col_value[col]
end

-- Construct color object from GML color value
function ConstructColorObject(val)
	local new = static.new()
	col_value[new] = val
	return new
end

-- Converts between BGR and RGB
local function flipRB(value)
	local low = bit.rol(bit.band(value, 0x0000ff), 16)
	local high = bit.ror(bit.band(value, 0xff0000), 16)
	return low + high + bit.band(value, 0x00ff00)
end

-- Set up API table
Color = {}
mods.modenv.Color = Color
mods.aliases.Colour = "Color"

-----------------------------
-----------------------------
-- Constructors -------------
-----------------------------
-----------------------------

function Color.fromRGB(red, green, blue)
	if type(red) ~= "number" then typeCheckError("Color.fromRGB", 1, "red", "number", red) end
	if type(green) ~= "number" then typeCheckError("Color.fromRGB", 2, "green", "number", green) end
	if type(blue) ~= "number" then typeCheckError("Color.fromRGB", 3, "blue", "number", blue) end
	local new = static.new()
	col_value[new] = GML.make_color_rgb(red, green, blue)
	return new
end

function Color.fromHSV(hue, saturation, value)
	if type(hue) ~= "number" then typeCheckError("Color.fromHSV", 1, "hue", "number", hue) end
	if type(saturation) ~= "number" then typeCheckError("Color.fromHSV", 2, "saturation", "number", saturation) end
	if type(value) ~= "number" then typeCheckError("Color.fromHSV", 3, "value", "number", value) end
	local new = static.new()
	col_value[new] = GML.make_color_hsv(hue, saturation, value)
	return new
end

function Color.fromHex(value)
	if type(value) ~= "number" then typeCheckError("Color.fromHex", 1, "value", "number", value) end
	local new = static.new()
	col_value[new] = flipRB(value)
	return new
end

function Color.mix(color1, color2, amount)
	if not children[color1] then typeCheckError("Color.mix", 1, "color1", "Color", color1) end
	if not children[color2] then typeCheckError("Color.mix", 2, "color2", "Color", color2) end
	if type("amount") == "number" then typeCheckError("Color.mix", 3, "amount", "Color", amount) end
	local new = static.new()
	col_value[new] = GML.merge_color(col_value[color1], col_value[color2], amount)
	return new
end

function Color.darken(color, amount)
	if not children[color] then typeCheckError("Color.darken", 1, "color", "Color", color) end
	if type("amount") == "number" then typeCheckError("Color.darken", 2, "amount", "Color", amount) end
	local new = static.new()
	col_value[new] = GML.merge_color(col_value[color], 0x000000, amount)
	return new
end

function Color.lighten(color, amount)
	if not children[color] then typeCheckError("Color.lighten", 1, "color", "Color", color) end
	if type("amount") == "number" then typeCheckError("Color.lighten", 2, "amount", "Color", amount) end
	local new = static.new()
	col_value[new] = GML.merge_color(col_value[color], 0xffffff, amount)
	return new
end

function Color.equals(color1, color2)
	if not children[color1] then typeCheckError("Color.equals", 1, "color1", "Color", color1) end
	if not children[color2] then typeCheckError("Color.equals", 2, "color2", "Color", color2) end
	return col_value[color1] == col_value[color2]
end

setmetatable(Color, {__call = function(t, red, green, blue)
	local new = static.new()
	if green ~= nil or blue ~= nil then
		if type(red) ~= "number" then typeCheckError("Color", 1, "red", "number", red) end
		if type(green) ~= "number" then typeCheckError("Color", 2, "green", "number", green) end
		if type(blue) ~= "number" then typeCheckError("Color", 3, "blue", "number", blue) end
		col_value[new] = GML.make_color_rgb(red, green, blue)
	else
		if type(red) ~= "number" then typeCheckError("Color", 1, "value", "number", value) end
		col_value[new] = flipRB(red)
	end
	return new
end})
	
-----------------------------
-----------------------------
-- Fields -------------------
-----------------------------
-----------------------------

lookup.red = {
	get = function(t)
		return GML.color_get_red(col_value[t])
	end
}
lookup.r = lookup.red
lookup.R = lookup.red

lookup.green = {
	get = function(t)
		return GML.color_get_green(col_value[t])
	end
}
lookup.g = lookup.green
lookup.G = lookup.green

lookup.blue = {
	get = function(t)
		return GML.color_get_blue(col_value[t])
	end
}
lookup.b = lookup.blue
lookup.B = lookup.blue

lookup.hue = {
	get = function(t)
		return GML.color_get_hue(col_value[t])
	end
}
lookup.h = lookup.hue
lookup.H = lookup.hue

lookup.saturation = {
	get = function(t)
		return GML.color_get_saturation(col_value[t])
	end
}
lookup.s = lookup.saturation
lookup.S = lookup.saturation

lookup.value = {
	get = function(t)
		return GML.color_get_value(col_value[t])
	end
}
lookup.v = lookup.value
lookup.V = lookup.value

lookup.hex = {
	get = function(t)
		return flipRB(col_value[t])
	end
}

-----------------------------
-----------------------------
-- Constants ----------------
-----------------------------
-----------------------------

local function const(name, r, g, b)
	local new = static.new()
	col_value[new] = GML.make_color_rgb(r, g, b)
	Color[name:upper()] = new
end

const("WHITE", 255, 255, 255)
const("DARK_GREY", 64, 64, 64)
const("GREY", 128, 128, 128)
const("LIGHT_GREY", 192, 192, 192)
Color.DARK_GRAY = Color.DARK_GREY
Color.GRAY = Color.GREY
Color.LIGHT_GRAY = Color.LIGHT_GREY
const("BLACK", 0, 0, 0)

const("RED", 255, 0, 0)
const("GREEN", 0, 255, 0)
const("BLUE", 0, 0, 255)

const("DARK_RED", 128, 0, 0)
const("DARK_GREEN", 0, 128, 0)
const("DARK_BLUE", 0, 0, 128)

const("LIGHT_RED", 255, 128, 128)
const("LIGHT_GREEN", 128, 255, 128)
const("LIGHT_BLUE", 128, 128, 255)

const("AQUA", 128, 255, 255)
const("FUCHSIA", 255, 0, 255)
const("YELLOW", 255, 255, 0)
const("ORANGE", 255, 128, 0)
const("LIME", 128, 255, 0)
const("PURPLE", 128, 0, 255)
const("PINK", 255, 0, 128)
const("CORAL", 255, 128, 128)

const("ROR_RED", 207, 102, 102)
const("ROR_GREEN", 126, 182, 134)
const("ROR_BLUE", 124, 136, 184)
const("ROR_YELLOW", 239, 210, 123)
const("ROR_ORANGE", 243, 165, 86)

const("DAMAGE_HEAL", 132, 215, 104)
const("DAMAGE_POISON", 201, 242, 77)
const("DAMAGE_ENEMY", 124, 97, 169)
Color.DAMAGE_NEUTRAL = Color.ROR_BLUE
