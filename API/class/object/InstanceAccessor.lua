
-- Create class
local static, _, meta, ids, special, children = NewClass("InstanceAccessor", true, nil)

GMInstance.InstanceAccessor = static
local verifyInstCall = GMInstance.verifyInstCall

-- Field management
function meta.__index(t, k)
	if type(k) ~= "string" then error(string.format("attempt to index InstanceAccessor with non-string key '%s' of type %s", tostring(k), typeOf(k)), 2) end
	verifyInstCall(ids[t])
	return AnyTypeRet(GML.variable_instance_get(ids[t], k))
end

do
	local legalTypes = {number = true, string = true, ["nil"] = true}
	function meta.__newindex(t, k, v)
		if type(k) ~= "string" then error(string.format("attempt to index InstanceAccessor with non-string key '%s' of type %s", tostring(k), typeOf(k)), 2) end
		if not legalTypes[type(v)] then error(string.format("attempt to set InstanceAccessor field %s to illegal value type %s", k, typeOf(v))) end
		verifyInstCall(ids[t])
		GML.variable_instance_set(ids[t], k, AnyTypeArg(v))
	end
end