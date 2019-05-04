
-- Create class
local static, lookup, meta, ids, special, children = NewClass("ItemInstance", true, GMInstance.Instance)
meta.__tostring = __tostring_default_instance
GMInstance.ItemInstance = static

local iwrap = GMInstance.iwrap
local verifyInstCall = GMInstance.verifyInstCall
local instance_object = GMInstance.instance_object

function lookup:getItem()
	if not children[self] then methodCallError("ItemInstance:getItem", self) end
	verifyInstCall(ids[self])
	return RoRItem.fromObj(instance_object[self])
end
