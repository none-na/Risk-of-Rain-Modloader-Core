local GML = GML
local type = type
local typeOf = typeOf

-- Create class
local static, lookup, meta, ids, special, children = NewClass("DamagerInstance", true, GMInstance.Instance)
GMInstance.DamagerInstance = static

local iwrap = GMInstance.iwrap
local verifyInstCall = GMInstance.verifyInstCall

function lookup:getParent()
	if not children[self] then methodCallError("DamagerInstance:getParent", self) end
	verifyInstCall(ids[self])
	local t = AnyTypeRet(GML.variable_instance_get(ids[self], "parent"))
	if t < 0 then
		return nil
	else
		return iwrap(t)
	end
end

local instance_object = GMInstance.instance_object
local obj_id = GMObject.ids
local explosion = GML.asset_get_index("oExplosion")
function lookup:isExplosion()
	if not children[self] then methodCallError("DamagerInstance:getParent", self) end
	verifyInstCall(ids[self])
	return (obj_id[instance_object[self]] == explosion)
end