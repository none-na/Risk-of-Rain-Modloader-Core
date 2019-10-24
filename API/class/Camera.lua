local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("Camera", true, nil)

local instance = static.new(GML.view_get_camera(0))
mods.modenv.camera = instance

-----------------------------
-----------------------------
-- Class methods / fields ---
-----------------------------
-----------------------------

-- Size
lookup.width = {
	get = function(t)
		return GML.camera_get_view_width(ids[t])
	end,
	set = function(t, v)
		if typeOf(v) ~= "number" then fieldTypeError("Camera.width", "number", v) end
		v = math.floor(v)
		if t == instance then GML.variable_global_set("___view_l_w", AnyTypeArg(v)) end
		if v < 10 or v > 10000 then error("illegal camera width") end
		GML.camera_set_view_size(ids[t], v, GML.camera_get_view_height(ids[t]))
	end
}
lookup.height = {
	get = function(t) 
		verifyCameraCall(t)
		return GML.camera_get_view_height(ids[t])
	end,
	set = function(t, v)
		if typeOf(v) ~= "number" then fieldTypeError("Camera.height", "number", v) end
		v = math.floor(v)
		if t == instance then GML.variable_global_set("___view_l_h", AnyTypeArg(v)) end
		if v < 10 or v > 10000 then error("illegal camera height") end
		GML.camera_set_view_size(ids[t], GML.camera_get_view_width(ids[t]), v)
	end
}

-- Position
lookup.x = {
	get = function(t) 
		return GML.camera_get_view_x(ids[t])
	end,
	set = function(t, v)
		if typeOf(v) ~= "number" then fieldTypeError("Camera.x", "number", v) end
		if t == instance then GML.variable_global_set("___view_l_x", AnyTypeArg(v)) end
		GML.camera_set_view_pos(ids[t], v, GML.camera_get_view_y(ids[t]))
	end
}
lookup.y = {
	get = function(t)
		return GML.camera_get_view_y(ids[self])
	end,
	set = function(t, v)
		if typeOf(v) ~= "number" then fieldTypeError("Camera.y", "number", v) end
		if t == instance then GML.variable_global_set("___view_l_y", AnyTypeArg(v)) end
		GML.camera_set_view_pos(ids[t], GML.camera_get_view_y(ids[t]), v)
	end
}

-- Rotation
lookup.angle = {
	get = function(t)
		return GML.camera_get_view_angle(ids[t])
	end,
	set = function(t, v)
		if typeOf(v) ~= "number" then fieldTypeError("Camera.angle", "number", v) end
		GML.camera_set_view_angle(ids[t], v)
	end
}
