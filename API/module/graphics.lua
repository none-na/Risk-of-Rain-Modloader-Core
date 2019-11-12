local GML = GML
local type = type
local typeOf = typeOf
graphics = {}

require("api/class/Color")
require("api/class/graphics/BaseSprite")
require("api/class/graphics/Surface")

-- Used to make sure alpha is reset after drawing when needed
-- Also returned by graphics.getAlpha but GML.draw_get_alpha would work just as well there
local set_alpha = 1
-- Used to make sure blend mode is reset after drawing
local set_blend = false

-- Called between graphics callbacks to make sure stuff is set appropriately
local resetSurface = SurfaceUtil.resetTarget
function CallbackResetGraphics()
	resetSurface()
	if set_alpha ~= 1 then
		GML.draw_set_alpha(1)
		set_alpha = 1
	end
	if set_blend then
		GML.gpu_set_blendmode(0)
	end
end

----------------------------------------------------
-- Setters and getters -----------------------------
----------------------------------------------------

-- Alpha
function graphics.alpha(value)
	if type(value) ~= "number" then typeCheckError("graphics.alpha", 1, "value", "number", value) end
	GML.draw_set_alpha(value)
	set_alpha = value
end
function graphics.getAlpha()
	return set_alpha
end

-- Color
function graphics.color(value)
	if typeOf(value) ~= "Color" then typeCheckError("graphics.color", 1, "value", "Color", value) end
	GML.draw_set_colour(GetColorValue(value))
end
graphics.colour = graphics.color
function graphics.getColor()
	return ConstructColorObject(GML.draw_get_colour())
end
graphics.getColour = graphics.getColor

-- Resolution
function graphics.getHUDResolution()
	return AnyTypeRet(GML.variable_global_get("_gui_width")), AnyTypeRet(GML.variable_global_get("_gui_height"))
end
function graphics.getGameResolution()
	return AnyTypeRet(GML.variable_global_get("_game_width")), AnyTypeRet(GML.variable_global_get("_game_height"))
end

-- Change active colour channels
function graphics.setChannels(red, green, blue, alpha)
	if type(red) ~= "boolean" then typeCheckError("graphics.setChannels", 1, "red", "boolean", red) end
	if type(green) ~= "boolean" then typeCheckError("graphics.setChannels", 2, "green", "boolean", green) end
	if type(blue) ~= "boolean" then typeCheckError("graphics.setChannels", 3, "blue", "boolean", blue) end
	if type(alpha) ~= "boolean" then typeCheckError("graphics.setChannels", 4, "alpha", "boolean", alpha) end
	GML.gpu_set_colorwriteenable(red and 1 or 0, green and 1 or 0, blue and 1 or 0, alpha and 1 or 0)
end
function graphics.resetChannels()
	GML.gpu_set_colorwriteenable(1, 1, 1, 1)
end

----------------------------------------------------
-- Blend mode --------------------------------------
----------------------------------------------------

do
	local modes = {
		normal = 0,
		additive = 1,
		subtract = 3,
		max = 2
	}

	function graphics.setBlendMode(mode)
		if type(mode) ~= "string" then typeCheckError("graphics.setBlendMode", 1, "mode", "string", mode) end
		if not modes[mode] then error("'" .. mode .. "' is not a valid blend mode for graphics.setBlendMode", 2) end
		GML.gpu_set_blendmode(modes[mode])
		set_blend = mode ~= "normal"
	end

	local extmodes = {
		zero = 1,
		one = 2,
		sourceColour = 3,
		sourceColourInv = 4,
		sourceAlpha = 5,
		sourceAlphaInv = 6,
		destColour = 9,
		destColourInv = 10,
		sourceColor = 3,
		sourceColorInv = 4,
		destColor = 9,
		destColorInv = 10,
		sourceAlphaSaturation = 11
	}

	function graphics.setBlendModeAdvanced(source, dest)
		if type(source) ~= "string" then typeCheckError("graphics.setBlendModeAdvanced", 1, "source", "string", source) end
		if type(dest) ~= "string" then typeCheckError("graphics.setBlendModeAdvanced", 2, "dest", "string", dest) end
		if not extmodes[source] then error("'" .. mode .. "' is not a valid blend mode for graphics.setBlendModeAdvanced", 2) end
		if not extmodes[dest] then error("'" .. mode .. "' is not a valid blend mode for graphics.setBlendModeAdvanced", 2) end
		GML.gpu_set_blendmode_ext(extmodes[source], extmodes[dest])
		set_blend = true
	end
end

----------------------------------------------------
-- Image drawing -----------------------------------
----------------------------------------------------

do
	local function argError(name, typ, got)
		error("graphics.drawImage incorrect type for " .. name .. ", expected " .. typ .. ", got " .. typeOf(got), 3)
	end
	
	local _get = rawget
	local white = Color.WHITE
	local sprite_id = SpriteUtil.baseIDs
	local surface_id = SurfaceUtil.ids
	local color_val = GetColorValue
	local sprite_valid = SpriteUtil.isValid
	
	function graphics.drawImage(args)
		if typeOf(args) ~= "table" then typeCheckError("graphics.drawImage", 1, "args", "table", args) end
		
		-----------------------
		-- Primary arguments --
		-----------------------
		
		-- Image to draw
		local image = _get(args, "image")
		-- Numerical index alias
		if image == nil then
			image = _get(args, 1)
		end
		-- Type checking
		local is_sprite = isA(image, "BaseSprite")
		if not is_sprite and typeOf(image) ~= "Surface" then
			argError("image", "Sprite or Surface", image)
		end
		
		-- Coordinates
		local x, y = _get(args, "x"), _get(args, "y")
		-- Numerical aliases
		if x == nil and y == nil then
			x, y = _get(args, 2), _get(args, 3)
		end
		-- Type checking
		if type(x) ~= "number" then
			argError("x", "number", x)
		end
		if type(y) ~= "number" then
			argError("y", "number", y)
		end
		
		-- Sprite subimage
		local subimage
		if is_sprite then
			subimage = _get(args, "subimage")
			-- Numerical alias
			if subimage == nil then
				subimage = _get(args, 4)
			end
			if subimage ~= nil then
				-- Type checking
				if type(subimage) ~= "number" then
					argError("subimage", "number", subimage)
				end
				-- 
				if subimage < 1 then
					subimage = 1
				end
			else
				-- Default value
				subimage = 1
			end
		end
		
		---------------------
		-- Extra arguments --
		---------------------
		
		-- X / Y scale
		local xscale, yscale = _get(args, "xscale"), _get(args, "yscale")
		if xscale ~= nil then
			-- Type checking
			if type(xscale) ~= "number" then
				argError("xscale", "number", xscale)
			end
		else
			xscale = 1
		end
		if yscale ~= nil then
			if type(yscale) ~= "number" then
				argError("yscale", "number", yscale)
			end
		else
			yscale = 1
		end
		
		-- Scale
		local scale = _get(args, "scale")
		if scale ~= nil then
			-- Type checking
			if type(scale) ~= "number" then
				argError("scale", "number", scale)
			end
			--
			xscale = xscale * scale
			yscale = yscale * scale
		end

		-- Width / height
		local width, height = _get(args, "width"), _get(args, "height")
		if width ~= nil then
			-- Type checking
			if type(width) ~= "number" then
				argError("width", "number", width)
			end
			--
			xscale = width / image.width * xscale
		end
		if height ~= nil then
			-- Type checking
			if type(height) ~= "number" then
				argError("height", "number", height)
			end
			--
			yscale = height / image.height * yscale
		end
		
		-- Rotation
		local angle = _get(args, "angle")
		if angle ~= nil then
			-- Type checking
			if type(angle) ~= "number" then
				argError("angle", "number", angle)
			end
		else
			-- Default value
			angle = 0
		end
		
		-- Solid color takes priority
		local color
		local solidColor = _get(args, "solidColor")
		-- Alias
		if solidColor == nil then
			solidColor = _get(args, "solidColour")
		end
		if solidColor ~= nil then
			-- Type checking
			if typeOf(solidColor) ~= "Color" then
				argError("solidColor", "Color", solidColor)
			end
			color = white
		else
			-- Color
			color = _get(args, "color")
			-- Alias colour
			if color == nil then
				color = _get(args, "colour")
			end
			if color ~= nil then
				-- Type checking
				if typeOf(color) ~= "Color" then
					argError("color", "Color", color)
				end
			else
				-- Default value
				color = white
			end
		end
		
		-- Alpha
		local alpha = _get(args, "alpha")
		if alpha ~= nil then
			-- Type checking
			if type(alpha) ~= "number" then
				argError("alpha", "number", alpha)
			end
		else
			-- Default value
			alpha = 1
		end

		-- Region
		local region = _get(args, "region")
		local _region_x, _region_y, _region_w, _region_h
		if region ~= nil then
			if typeOf(region) ~= "table" then argError("region", "table", region) end
			_region_x = _get(region, "x") or _get(region, 1)
			if type(_region_x) ~= "number" then argError("region.x", "number", _region_x) end
			_region_y = _get(region, "y") or _get(region, 2)
			if type(_region_y) ~= "number" then argError("region.y", "number", _region_y) end
			_region_w = _get(region, "width") or _get(region, 3)
			if type(_region_w) ~= "number" then argError("region.width", "number", _region_w) end
			_region_h = _get(region, "height") or _get(region, 4)
			if type(_region_h) ~= "number" then argError("region.height", "number", _region_h) end
		end
		
		--------------
		-- Draw it! --
		--------------
		
		if is_sprite then
			-- Sprite
			if not sprite_valid(image) then
				error("trying to draw nonexistent sprite", 2)
			end
			if solidColor then
				GML.gpu_set_fog(1, color_val(solidColor), 0, 0)
			end
			if region then
				local col = color_val(color)
				GML.draw_sprite_general(sprite_id[image], subimage - 1, _region_x, _region_y, _region_w, _region_h, x, y, xscale, yscale, angle, col, col, col, col, alpha)
			else
				GML.draw_sprite_ext(sprite_id[image], subimage - 1, x, y, xscale, yscale, angle, color_val(color), alpha)
			end
		else
			-- Surface
			if GML.surface_exists(surface_id[image]) == 0 then
				error("trying to draw nonexistent surface", 2)
			end
			if solidColor then
				GML.gpu_set_fog(1, color_val(solidColor), 0, 0)
			end
			if region then
				local col = color_val(color)
				GML.draw_surface_part_ext(surface_id[image], _region_x, _region_y, _region_w, _region_h, x, y, xscale, yscale, angle, col, col, col, col, alpha)
			else
				GML.draw_surface_ext(surface_id[image], x, y, xscale, yscale, angle, color_val(color), alpha)
			end
		end
		if solidColor then
			GML.gpu_set_fog(0, 0, 0, 0)
		end
	end
end

----------------------------------------------------
-- Shape drawing -----------------------------------
----------------------------------------------------

-- Rectangle
function graphics.rectangle(x1, y1, x2, y2, outline)
	if type(x1) ~= "number" then typeCheckError("graphics.rectangle", 1, "x1", "number", x1) end
	if type(y1) ~= "number" then typeCheckError("graphics.rectangle", 2, "y1", "number", y1) end
	if type(x2) ~= "number" then typeCheckError("graphics.rectangle", 3, "x2", "number", x2) end
	if type(y2) ~= "number" then typeCheckError("graphics.rectangle", 4, "y2", "number", y2) end
	if outline ~= nil and type(outline) ~= "boolean" then typeCheckError("graphics.rectangle", 5, "outline", "boolean or nil", outline) end
	if outline then outline = 1 else outline = 0 end
	GML.draw_rectangle(x1, y1, x2, y2, outline)
end

-- Circle
function graphics.circle(x, y, radius, outline)
	if type(x) ~= "number" then typeCheckError("graphics.circle", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("graphics.circle", 2, "y", "number", y) end
	if type(radius) ~= "number" then typeCheckError("graphics.circle", 3, "radius", "number", radius) end
	if outline ~= nil and type(outline) ~= "boolean" then typeCheckError("graphics.circle", 4, "outline", "boolean or nil", outline) end
	if outline then outline = 1 else outline = 0 end
	GML.draw_circle(x, y, radius, outline)
end

-- Ellipse
function graphics.ellipse(x1, y1, x2, y2, outline)
	if type(x1) ~= "number" then typeCheckError("graphics.ellipse", 1, "x1", "number", x1) end
	if type(y1) ~= "number" then typeCheckError("graphics.ellipse", 2, "y1", "number", y1) end
	if type(x2) ~= "number" then typeCheckError("graphics.ellipse", 3, "x2", "number", x2) end
	if type(y2) ~= "number" then typeCheckError("graphics.ellipse", 4, "y2", "number", y2) end
	if outline ~= nil and type(outline) ~= "boolean" then typeCheckError("graphics.ellipse", 5, "outline", "boolean or nil", outline) end
	if outline then outline = 1 else outline = 0 end
	GML.draw_ellipse(x1, y1, x2, y2, outline)
end

-- Triangle
function graphics.triangle(x1, y1, x2, y2, x3, y3, outline)
	if type(x1) ~= "number" then typeCheckError("graphics.triangle", 1, "x1", "number", x1) end
	if type(y1) ~= "number" then typeCheckError("graphics.triangle", 2, "y1", "number", y1) end
	if type(x2) ~= "number" then typeCheckError("graphics.triangle", 3, "x2", "number", x2) end
	if type(y2) ~= "number" then typeCheckError("graphics.triangle", 4, "y2", "number", y2) end
	if type(x3) ~= "number" then typeCheckError("graphics.triangle", 5, "x3", "number", x3) end
	if type(y3) ~= "number" then typeCheckError("graphics.triangle", 6, "y3", "number", y3) end
	if outline ~= nil and type(outline) ~= "boolean" then typeCheckError("graphics.triangle", 7, "outline", "boolean or nil", outline) end
	if outline then outline = 1 else outline = 0 end
	GML.draw_triangle(x1, y1, x2, y2, x3, y3, outline)
end

-- Line
function graphics.line(x1, y1, x2, y2, width)
	if type(x1) ~= "number" then typeCheckError("graphics.line", 1, "x1", "number", x1) end
	if type(y1) ~= "number" then typeCheckError("graphics.line", 2, "y1", "number", y1) end
	if type(x2) ~= "number" then typeCheckError("graphics.line", 3, "x2", "number", x2) end
	if type(y2) ~= "number" then typeCheckError("graphics.line", 4, "y2", "number", y2) end
	if width ~= nil and type(width) ~= "number" then typeCheckError("graphics.line", 5, "width", "number or nil", width) end
	if width == nil or width <= 1 then
		GML.draw_line(x1, y1, x2, y2)
	else
		GML.draw_line_width(x1, y1, x2, y2, width)
	end
end

-- Point
function graphics.pixel(x, y)
	if type(x) ~= "number" then typeCheckError("graphics.pixel", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("graphics.pixel", 2, "y", "number", y) end
	GML.draw_point(x, y)
end

----------------------------------------------------
-- Text --------------------------------------------
----------------------------------------------------

-- Fonts
local fontCount = 0
local fontIDMap = {}
local fontBuiltin = {}
local function addFont(gmid)
	fontCount = fontCount + 1
	fontIDMap[fontCount] = gmid
	return fontCount
end
local function builtinFont(name, ...)
	local id = addFont(AnyTypeRet(GML.variable_global_get(name)))
	fontBuiltin[id] = {name, ...}
	return id
end
local function checkFont(font)
	if fontIDMap[font] == nil then error("no font exists with ID " .. tostring(font), 3) end
end

graphics.FONT_DEFAULT = builtinFont("fntTiny", "fntTinyAlt")
graphics.FONT_LARGE = builtinFont("fntSmall", "fntSmallAlt", "fntMedium")
graphics.FONT_SMALL = builtinFont("fntMicro")
graphics.FONT_DAMAGE = builtinFont("fntDamage")
graphics.FONT_CRITICAL = builtinFont("fntCrit")
graphics.FONT_MONEY = builtinFont("fntDamageLarge")

-- Align constants
graphics.ALIGN_LEFT = 0
graphics.ALIGN_MIDDLE = 1
graphics.ALIGN_RIGHT = 2
graphics.ALIGN_TOP = 0
graphics.ALIGN_CENTER = 1
graphics.ALIGN_CENTRE = 1
graphics.ALIGN_BOTTOM = 2

local floor = math.floor

local font_default = graphics.FONT_DEFAULT

-- Load inspect library
inspect = require("inspect")

-- Simple text
function graphics.print(text, x, y, font, halign, valign)
	if type(x) ~= "number" then typeCheckError("graphics.print", 2, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("graphics.print", 3, "y", "number", y) end
	if font ~= nil and type(font) ~= "number" then typeCheckError("graphics.print", 4, "font", "number", font) end
	if halign ~= nil and type(halign) ~= "number" then typeCheckError("graphics.print", 5, "halign", "number", halign) end
	if valign ~= nil and type(valign) ~= "number" then typeCheckError("graphics.print", 6, "valign", "number", valign) end
	if font ~= nil then checkFont(font) end
	if type(text) ~= "string" then text = inspect(text) end
	if text == "" then return end
	GML.draw_set_text(GML.draw_get_colour(), fontIDMap[font or font_default], halign or 0, valign or 0)
	GML.draw_text(floor(x), floor(y), text)
end

-- Colored text
function graphics.printColor(text, x, y, font)
	if type(text) ~= "string" then typeCheckError("graphics.printColor", 1, "text", "number", text) end
	if type(x) ~= "number" then typeCheckError("graphics.printColor", 2, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("graphics.printColor", 3, "y", "number", y) end
	if font ~= nil and type(font) ~= "number" then typeCheckError("graphics.printColor", 4, "font", "number", font) end
	if halign ~= nil and type(halign) ~= "number" then typeCheckError("graphics.printColor", 5, "halign", "number", halign) end
	if halign ~= nil and type(valign) ~= "number" then typeCheckError("graphics.printColor", 6, "valign", "number", valign) end
	if font ~= nil then checkFont(font) end
	if text == "" then return end
	GML.draw_set_text(GML.draw_get_colour(), fontIDMap[font or font_default], 0, 0)
	GML.draw_ctext(floor(x), floor(y), text)
end
graphics.printColour = graphics.printColor

-- Load a font from a file
function graphics.fontFromFile(fname, size, bold, italic)
	if type(fname) ~= "string" then typeCheckError("graphics.fontFromFile", 1, "fname", "string", fname) end
	if type(size) ~= "number" then typeCheckError("graphics.fontFromFile", 2, "size", "number", size) end
	if bold ~= nil and type(bold) ~= "boolean" then typeCheckError("graphics.fontFromFile", 3, "bold", "boolean or nil", bold) end
	if bold ~= nil and type(italic) ~= "boolean" then typeCheckError("graphics.fontFromFile", 4, "italic", "boolean or nil", italic) end
	-- Get the path to the file
	local path = ResolveModPath() .. fname
	if GML.file_exists(path) == 0 then
		path = path .. ".ttf"
	end
	-- Error if it doesn't exist
	if GML.file_exists(path) == 0 then
		error(string.format('unable to load font %q, the file could not be found', fname), 2)
	end
	-- Add the font
	local gmid = GML.font_add(path, size, bold and 1 or 0, italic and 1 or 0, 32, 128)
	return addFont(gmid)
end

-- Create a font from a sprite
function graphics.fontFromSprite(sprite, characters, separation, monospace)
	if typeOf(sprite) ~= "Sprite" then typeCheckError("graphics.fontFromSprite", 1, "sprite", "Sprite", sprite) end
	if type(characters) ~= "string" then typeCheckError("graphics.fontFromSprite", 2, "characters", "string", characters) end
	if separation ~= nil and type(separation) ~= "number" then typeCheckError("graphics.fontFromSprite", 3, "separation", "number or nil", separation) end
	if monospace ~= nil and type(monospace) ~= "boolean" then typeCheckError("graphics.fontFromSprite", 4, "monospace", "boolean or nil", monospace) end
	local gmid = GML.font_add_sprite_ext(SpriteUtil.toID(sprite), characters, monospace and false or true, separation and separation or 1)
	return addFont(gmid)
end

-- Check if a font exists 
function graphics.fontIsValid(font)
	if type(font) ~= "number" then return false end
	return fontIDMap[font] ~= nil
end

-- Delete a font
function graphics.fontDelete(font)
	if type(font) ~= "number" then typeCheckError("graphics.fontDelete", 1, "font", "number", font) end
	if fontBuiltin[font] then error("trying to delete a built-in font", 2) end
	local gmid = fontIDMap[font]

	local found = false
	-- Check each font ID to see if it's a copy of this one
	for i = 1, fontCount do
		if fontIDMap[i] == gmid then
			found = true
		end
	end
	-- If we didn't find the font anywhere else, delete it
	if not found then
		GML.font_delete(gmid)
	end

	-- Clear the slot in the array
	fontIDMap[font] = nil
end

-- Replace a font with another one
function graphics.fontReplace(original, new)
	if type(original) ~= "number" then typeCheckError("graphics.fontReplace", 1, "original", "number", original) end
	if type(new) ~= "number" then typeCheckError("graphics.fontReplace", 1, "new", "number", new) end
	checkFont(original)
	checkFont(new)
	local oldID = fontIDMap[original]

	-- Change the font ID in the map
	fontIDMap[original] = fontIDMap[new]

	if fontBuiltin[original] then
		-- If the font is a buitlt-in font, update the global with the new ID
		for _, v in ipairs(fontBuiltin[original]) do
			-- We loop over a list here since the game stores each font several places for some reason
			GML.variable_global_set(v, AnyTypeArg(fontIDMap[new]))
		end
	else
		-- Rremove custom fonts if they're no longer accessible
		local found = false
		-- Loop over each font slot
		for i = 1, fontCount do
			-- Check if it's the one we're replacing
			if fontIDMap[i] == oldID then
				found = true
			end
		end
		-- If we didn't find the replaced font anywhere else, delete it
		if not found then
			GML.font_delete(oldID)
		end
	end 
end

-- Get the pixel width of a string
function graphics.textWidth(text, font)
	if type(text) ~= "string" then typeCheckError("graphics.textWidth", 1, "text", "string", text) end
	if type(font) ~= "number" then typeCheckError("graphics.textWidth", 2, "font", "number", font) end
	checkFont(font)
	GML.draw_set_font(fontIDMap[font])
	return GML.string_width(text)
end

-- Same for pixel height
function graphics.textHeight(text, font)
	if type(text) ~= "string" then typeCheckError("graphics.textHeight", 1, "text", "string", text) end
	if type(font) ~= "number" then typeCheckError("graphics.textHeight", 2, "font", "number", font) end
	checkFont(font)
	GML.draw_set_font(fontIDMap[font])
	return GML.string_height(text)
end

----------------------------------------------------
-- Depth Binding -----------------------------------
----------------------------------------------------

local DrawDepth_id = GML.asset_get_index("oDrawDepth")
local drawBindHandler = {}

function graphics.bindDepth(depth, bind)
	if type(depth) ~= "number" then typeCheckError("graphics.bindDepth", 1, "depth", "number", depth) end
	if type(bind) ~= "function" then typeCheckError("graphics.bindDepth", 2, "bind", "function", bind) end
	verifyCallback(bind)
	
	local inst = GML.instance_create(0, 0, DrawDepth_id)
	drawBindHandler[inst] = bind
	modFunctionSources[bind] = GetModContext()
	GML.variable_instance_set(inst, "depth", AnyTypeArg(depth))
	
	return GMInstance.iwrap(inst)
end

function CallbackHandlers.DrawBindEvent(args)
	-- id, event, timer
	-- ev 0: draw
	-- ev 1: destroy
	
	local id = args[1]
	local ev = args[2]
	
	if ev == 1 then
		drawBindHandler[id] = nil
	elseif drawBindHandler[id] then
		CallModdedFunction(drawBindHandler[id], {GMInstance.iwrap(id), args[3]})
	end
end



function ResetGraphics()
	drawBindHandler = {}
end


-- env
mods.modenv.graphics = graphics
