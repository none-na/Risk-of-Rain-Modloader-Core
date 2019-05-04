local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Surface", true, nil)

Surface = {}

-- List of current surface IDs
local uncleaned = {}
-- Weak ID -> object map
local cleanablecache = setmetatable({}, {__mode = "v"})

-- Properties
local surface_width = setmetatable({}, {__mode = "k"})
local surface_height = setmetatable({}, {__mode = "k"})

-- Current render target, nil is default and otherwise a surface ref
local render_target = nil

-- Garbage collection
--[[
local function surfaceGC()
	-- Loop over current IDs
	local i = 1
	while i < #uncleaned do
		-- Check if object was collected by garbage collection
		if not cleanablecache[v] then
			-- If it was then free the surface
			if GML.surface_exists(v) == 1 then
				GML.surface_free(v)
			end
			table.remove(uncleaned, k)
		else
			i = i + 1
		end
	end
end
]]

local function updateRenderTarget(target)
	if target ~= render_target then
		if target ~= nil then
			if render_target ~= nil then
				GML.surface_reset_target()
			end
			GML.surface_set_target(ids[target])
		else
			GML.surface_reset_target()
		end
		render_target = target
	end
end

local function verifySurfaceCall(self)
	if GML.surface_exists(ids[self]) == 0 then
		error("attempt to access nonexistent surface object", 3)
	end
end

-----------------------------
-----------------------------
-- Static methods -----------
-----------------------------
-----------------------------

-- New surface
function new_surface(fname, width, height)
	if type(width) ~= "number" then typeCheckError(fname, 1, "width", "number", width) end
	if type(height) ~= "number" then typeCheckError(fname, 2, "height", "number", height) end
	if width < 1 then error("Surface width must be at least 1, got " .. tostring(width)) end
	if height < 1 then error("Surface height must be at least 1, got " .. tostring(height)) end
	
	local nid = GML.surface_create(width, height)
	local new = static.new(nid)
	
	cleanablecache[nid] = new
	table.insert(uncleaned, nid)
	
	surface_width[new] = width
	surface_height[new] = height
	
	return new
end
function Surface.new(width, height)
	return new_surface("Surface.new", width, height)
end
setmetatable(Surface, {__call = function(t, width, height)
	return new_surface("Surface", width, height)
end})

-- Set render target
function graphics.setTarget(target)
	if typeOf(target) ~= "Surface" then typeCheckError("graphics.setTarget", 1, "target", "Surface", target) end
	if GML.surface_exists(ids[target]) == 0 then
		error("attempt to set render target to an invalid surface reference", 3)
	end
	updateRenderTarget(target)
end

-- Reset render target
function graphics.resetTarget()
	updateRenderTarget(nil)
end

-- Get the current target
function graphics.getTarget()
	return render_target
end

-- Check if a value is a valid surface
function Surface.isValid(val)
	if val == nil then
		return false
	elseif ids[val] == nil then
		return false
	else
		return GML.surface_exists(ids[val]) == 1
	end
end

-----------------------------
-----------------------------
-- Class methods / fields ---
-----------------------------
-----------------------------

-- Manually frees the surface
function lookup:free() 
	if not children[self] then methodCallError("Surface:free", self) end
	if render_target == self then error("trying to free surface while it is being drawn to", 2) end
	cleanablecache[ids[self]] = nil
	if GML.surface_exists(ids[self]) == 1 then
		GML.surface_free(ids[self])
	end
end

-- Check the validity of a surface ref
function lookup:isValid() 
	if not children[self] then methodCallError("Surface:isValid", self) end
	return (GML.surface_exists(ids[self]) == 1)
end

-- Clears the surface
function lookup:clear() 
	if not children[self] then methodCallError("Surface:clear", self) end
	verifySurfaceCall(self)
	local temptarg = render_target
	updateRenderTarget(self)
	GML.draw_clear_alpha(0, 0)
	updateRenderTarget(temptarg)
end

-- Draw the surface
function lookup:draw(x, y)
	if not children[self] then methodCallError("Surface:draw", self) end
	if type(x) ~= "number" then typeCheckError("Surface:draw", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("Surface:draw", 2, "y", "number", y) end
	verifySurfaceCall(self)
	GML.draw_surface(ids[self], x, y)
end

-- Generate a sprite
function lookup:createSprite(xorigin, yorigin, x, y, w, h)
	if not children[self] then methodCallError("Surface:createSprite", self) end
	if xorigin ~= nil and type(xorigin) ~= "number" then typeCheckError("Surface:createSprite", 1, "xorigin", "number or nil", xorigin) end
	if yorigin ~= nil and type(yorigin) ~= "number" then typeCheckError("Surface:createSprite", 2, "yorigin", "number or nil", yorigin) end
	if x ~= nil and type(x) ~= "number" then typeCheckError("Surface:createSprite", 3, "x", "number or nil", x) end
	if y ~= nil and type(y) ~= "number" then typeCheckError("Surface:createSprite", 4, "y", "number or nil", y) end
	if w ~= nil and type(w) ~= "number" then typeCheckError("Surface:createSprite", 5, "w", "number or nil", w) end
	if h ~= nil and type(h) ~= "number" then typeCheckError("Surface:createSprite", 6, "h", "number or nil", h) end
	verifySurfaceCall(self)
	if xorigin == nil then xorigin = 0 end
	if yorigin == nil then yorigin = 0 end
	if x == nil then x = 0 end
	if y == nil then y = 0 end
	if w == nil then w = surface_width[self] end
	if h == nil then h = surface_height[self] end
	return SpriteUtil.createDynamic(GML.sprite_create_from_surface(ids[self], x, y, w, h, 0, 0, xorigin, yorigin))
end

-- Width
lookup.width = {
	get = function(t) 
		verifySurfaceCall(t)
		return surface_width[t]
	end,
	set = function(t, v)
		if typeOf(v) ~= "number" then fieldTypeError("Surface.width", "number", v) end
		verifySurfaceCall()
		GML.surface_resize(ids[self], v, surface_height[t])
		surface_width[t] = v
	end
}

-- Height
lookup.height = {
	get = function(t) 
		verifySurfaceCall(t)
		return surface_height[t]
	end,
	set = function(t, v)
		if typeOf(v) ~= "number" then fieldTypeError("Surface.height", "number", v) end
		verifySurfaceCall()
		GML.surface_resize(ids[self], surface_width[t], v)
		surface_height[t] = v
	end
}

-- global stuff
SurfaceUtil = {
	ids = ids,
	resetTarget = function()
		if render_target ~= nil then
			updateRenderTarget(nil)
		end
	end
}

mods.modenv.Surface = Surface
