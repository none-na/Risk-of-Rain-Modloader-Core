local GML = GML
local type = type
local typeOf = typeOf
-- Create class
local static, lookup, meta, ids, special, children = NewClass("ParentObject", true, GMObject.baseClass)
meta.__tostring = __tostring_default_namespace

ParentObject = {}

local all_parents = {vanilla = {}}

local parent_name = {}

-- No custom parents for now, custom parents aren't really possible without a considerable
-- amount of gml hackery using ""removed"" functions.

function lookup:getOrigin()
	if not children[self] then methodCallError("ParentObject:getOrigin", self) end
	return "Vanilla"
end

function lookup:getName()
	if not children[self] then methodCallError("ParentObject:getName", self) end
	return parent_name[self]
end

ParentObject.find = contextSearch(all_parents, "ParentObject.find")
ParentObject.findAll = contextFindAll(all_parents, "ParentObject.findAll")

-- Wrap vanilla
do
	local function create(name, parentName)
		local new = static.new(GML.asset_get_index(parentName))
		parent_name[new] = name
		all_parents.vanilla[string.lower(name)] = new
	end

	-- Actors
	create("actors", "pNPC")

	create("enemies", "pEnemy")
	create("classicEnemies", "pEnemyClassic")
	create("flyingEnemies", "pFlying")
	create("bosses", "pBoss")

	create("drones", "pDrone")

	-- MapObjects
	create("mapObjects", "pMapObjects")
	create("droneItems", "pDroneItem")
	create("chests", "pChest")

	-- Misc
	create("items", "pItem")
	create("artifacts", "pArtifact")
	create("commandCrates", "pArtifact8Box")
end

-- env
mods.modenv.ParentObject = ParentObject
