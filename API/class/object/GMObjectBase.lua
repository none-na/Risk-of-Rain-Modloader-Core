local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("GMObjectBase", true)

GMObject = {}
GMObject.baseClass = static

require "api/class/object/gmobject"
require "api/class/object/parentobject"

local iwrap = GMInstance.iwrap

function lookup:find(n)
	if not children[self] then methodCallError("GMObjectBase:find", self) end
	if type(n) ~= "number" then typeCheckError("GMObjectBase:find", 1, "n", "number", n) end

	local inst = GML.instance_find(ids[self], n - 1)
	if inst > 0 then
		return iwrap(inst)
	else
		return nil
	end
end

function lookup:findAll()
	if not children[self] then methodCallError("GMObjectBase:findAll", self) end
	
	GML.instance_find_all(ids[self])
	local res = PopNumbers()
	for k, v in ipairs(res) do
		res[k] = iwrap(v)
	end

	return res
end

function lookup:count()
	if not children[self] then methodCallError("GMObjectBase:count", self) end
	return GML.instance_number(ids[self])
end

do
	local legalTypes = {number = true, string = true, ["nil"] = true}
	local legalOperators = {["=="] = true, ["~="] = true, ["<"] = true, [">"] = true, ["<="] = true, [">="] = true, };
	function lookup:findMatching(...)
		if not children[self] then methodCallError("GMObjectBase:findMatching", self) end

		local targs = {...}
		for i = 1, #targs, 2 do
			if type(targs[i]) ~= "string" then typeCheckError("GMObjectBase:findMatching", i, "key", "string", targs[i]) end
			if not legalTypes[type(targs[i + 1])] then typeCheckError("GMObjectBase:findMatching", i + 1, "value", "number, string, or nil", targs[i + 1]) end
		end
		
		PushCBArgs(targs)
		GML.instance_find_matching(ids[self])
		local res = PopNumbers()
		for k, v in ipairs(res) do
			res[k] = iwrap(v)
		end

		return res
	end

	function lookup:findMatchingOp(...)
		if not children[self] then methodCallError("GMObjectBase:findMatchingOp", self) end

		local targs = {...}
		for i = 1, #targs, 3 do
			if type(targs[i]) ~= "string" then typeCheckError("GMObjectBase:findMatchingOp", i, "key", "string", targs[i]) end
			if type(targs[i + 1]) ~= "string" then typeCheckError("GMObjectBase:findMatchingOp", i + 1, "operator", "string", targs[i + 1]) end
			if not legalOperators[targs[i + 1]] then error("'" .. targs[i + 1] .. "' is not a known operator", 3) end
			if not legalTypes[type(targs[i + 2])] then typeCheckError("GMObjectBase:findMatchingOp", i + 2, "value", "number, string, or nil", targs[i + 2]) end
		end

		PushCBArgs(targs)
		GML.instance_find_matching_op(ids[self])
		local res = PopNumbers()
		for k, v in ipairs(res) do
			res[k] = iwrap(v)
		end

		return res
	end
end

-- Shape finds
function lookup:findNearest(x, y)
	if not children[self] then methodCallError("GMObjectBase:findNearest", self) end
	if type(x) ~= "number" then typeCheckError("GMObjectBase:findNearest", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("GMObjectBase:findNearest", 2, "y", "number", y) end
	
	local ti = GML.instance_nearest(x, y, ids[self])
	return (ti and ti > 0) and iwrap(ti) or nil
end

function lookup:findFurthest(x, y)
	if not children[self] then methodCallError("GMObjectBase:findFurthest", self) end
	if type(x) ~= "number" then typeCheckError("GMObjectBase:findFurthest", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("GMObjectBase:findFurthest", 2, "y", "number", y) end

	local ti = GML.instance_furthest(x, y, ids[self])
	return (ti and ti > 0) and iwrap(ti) or nil
end

-- Rectanlge find
function lookup:findRectangle(x1, y1, x2, y2)
	if not children[self] then methodCallError("GMObjectBase:findRectangle", self) end
	if type(x1) ~= "number" then typeCheckError("GMObjectBase:findRectangle", 1, "x1", "number", x1) end
	if type(y1) ~= "number" then typeCheckError("GMObjectBase:findRectangle", 2, "y1", "number", y1) end
	if type(x2) ~= "number" then typeCheckError("GMObjectBase:findRectangle", 3, "x2", "number", x2) end
	if type(y2) ~= "number" then typeCheckError("GMObjectBase:findRectangle", 4, "y2", "number", y2) end
	
	local ti = GML.collision_rectangle(x1, y1, x2, y2, ids[self], 1, 0)
	return ti > 0 and iwrap(ti) or nil
end

function lookup:findAllRectangle(x1, y1, x2, y2)
	if not children[self] then methodCallError("GMObjectBase:findAllRectangle", self) end
	if type(x1) ~= "number" then typeCheckError("GMObjectBase:findAllRectangle", 1, "x1", "number", x1) end
	if type(y1) ~= "number" then typeCheckError("GMObjectBase:findAllRectangle", 2, "y1", "number", y1) end
	if type(x2) ~= "number" then typeCheckError("GMObjectBase:findAllRectangle", 3, "x2", "number", x2) end
	if type(y2) ~= "number" then typeCheckError("GMObjectBase:findAllRectangle", 4, "y2", "number", y2) end
	
	GML.collision_rectangle_list(x1, y1, x2, y2, ids[self], 1, 0)
	local res = PopNumbers()
	for k, v in ipairs(res) do
		res[k] = iwrap(v)
	end
	return res
end

function lookup:findEllipse(x1, y1, x2, y2)
	if not children[self] then methodCallError("GMObjectBase:findEllipse", self) end
	if type(x1) ~= "number" then typeCheckError("GMObjectBase:findEllipse", 1, "x1", "number", x1) end
	if type(y1) ~= "number" then typeCheckError("GMObjectBase:findEllipse", 2, "y1", "number", y1) end
	if type(x2) ~= "number" then typeCheckError("GMObjectBase:findEllipse", 3, "x2", "number", x2) end
	if type(y2) ~= "number" then typeCheckError("GMObjectBase:findEllipse", 4, "y2", "number", y2) end
	
	local ti = GML.collision_ellipse(x1, y1, x2, y2, ids[self], 1, 0)
	return ti > 0 and iwrap(ti) or nil
end

function lookup:findAllEllipse(x1, y1, x2, y2)
	if not children[self] then methodCallError("GMObjectBase:findAllEllipse", self) end
	if type(x1) ~= "number" then typeCheckError("GMObjectBase:findAllEllipse", 1, "x1", "number", x1) end
	if type(y1) ~= "number" then typeCheckError("GMObjectBase:findAllEllipse", 2, "y1", "number", y1) end
	if type(x2) ~= "number" then typeCheckError("GMObjectBase:findAllEllipse", 3, "x2", "number", x2) end
	if type(y2) ~= "number" then typeCheckError("GMObjectBase:findAllEllipse", 4, "y2", "number", y2) end
	
	GML.collision_ellipse_list(x1, y1, x2, y2, ids[self], 1, 0)
	local res = PopNumbers()
	for k, v in ipairs(res) do
		res[k] = iwrap(v)
	end
	return res
end

function lookup:findLine(x1, y1, x2, y2)
	if not children[self] then methodCallError("GMObjectBase:findLine", self) end
	if type(x1) ~= "number" then typeCheckError("GMObjectBase:findLine", 1, "x1", "number", x1) end
	if type(y1) ~= "number" then typeCheckError("GMObjectBase:findLine", 2, "y1", "number", y1) end
	if type(x2) ~= "number" then typeCheckError("GMObjectBase:findLine", 3, "x2", "number", x2) end
	if type(y2) ~= "number" then typeCheckError("GMObjectBase:findLine", 4, "y2", "number", y2) end
	
	local ti = GML.collision_line(x1, y1, x2, y2, ids[self], 1, 0)
	return ti > 0 and iwrap(ti) or nil
end

function lookup:findAllLine(x1, y1, x2, y2)
	if not children[self] then methodCallError("GMObjectBase:findAllLine", self) end
	if type(x1) ~= "number" then typeCheckError("GMObjectBase:findAllLine", 1, "x1", "number", x1) end
	if type(y1) ~= "number" then typeCheckError("GMObjectBase:findAllLine", 2, "y1", "number", y1) end
	if type(x2) ~= "number" then typeCheckError("GMObjectBase:findAllLine", 3, "x2", "number", x2) end
	if type(y2) ~= "number" then typeCheckError("GMObjectBase:findAllLine", 4, "y2", "number", y2) end
	
	GML.collision_line_list(x1, y1, x2, y2, ids[self], 1, 0)
	local res = PopNumbers()
	for k, v in ipairs(res) do
		res[k] = iwrap(v)
	end
	return res
end

function lookup:findPoint(x, y)
	if not children[self] then methodCallError("GMObjectBase:findPoint", self) end
	if type(x) ~= "number" then typeCheckError("GMObjectBase:findPoint", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("GMObjectBase:findPoint", 2, "y", "number", y) end
	
	local ti = GML.collision_point(x, y, ids[self], 1, 0)
	return ti > 0 and iwrap(ti) or nil
end

function lookup:findAllPoint(x, y)
	if not children[self] then methodCallError("GMObjectBase:findAllPoint", self) end
	if type(x) ~= "number" then typeCheckError("GMObjectBase:findAllPoint", 1, "x", "number", x) end
	if type(y) ~= "number" then typeCheckError("GMObjectBase:findAllPoint", 2, "y", "number", y) end
	
	GML.collision_point_list(x, y, ids[self], 1, 0)
	local res = PopNumbers()
	for k, v in ipairs(res) do
		res[k] = iwrap(v)
	end
	return res
end