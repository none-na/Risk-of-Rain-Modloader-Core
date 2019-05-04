
local all_types = {}

function mods.modenv.newtype(name)
	if type(name) ~= "string" then typeCheckError("newtype", 1, "name", "string", name) end
	
	local context = GetModContext()
	
	contextVerify(all_types, name, context, "type")
	
	local identifier = context .. ":" .. name
	local static, lookup, meta, ids, special, children = NewClass(identifier, false)
	
	meta.__index = nil
	meta.__newindex = nil
	meta.__tostring = function() return name end
	
	contextInsert(all_types, name, context, meta)
	
	return static.new, meta
end
