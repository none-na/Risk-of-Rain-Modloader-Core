local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("NetInstance", false, nil)
meta.__tostring = function(obj)
	return "<NetInstance " .. obj.object:getName() .. " " .. tostring(obj.id) .. ">"
end

local iwrap = GMInstance.iwrap

local identity_mid = {}
local identity_obj = {}

lookup.object = { get = function(self)
	return identity_obj[self]
end}

lookup.id = { get = function(self)
	return identity_mid[self]
end}

function lookup:resolve()
	if not children[self] then methodCallError("NetInstance:resolve", self) end
	local id = GML.net_find_object(identity_obj[self], identity_mid[self])
	if id > 0 then
		return iwrap(id)
	else
		return nil
	end
end

function GMInstance.getNetIdentity(mid, obj)
	local new = static.new()
	identity_mid[new] = mid
	identity_obj[new] = obj
	return new
end