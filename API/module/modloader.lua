modloader = {}

------------------------
  ------------------------
   ---- Launch settings ----
  ------------------------
------------------------

-- Get profile name
local profileName = AnyTypeRet(GML.variable_global_get("current_modpack"))
function modloader.getProfileName()
	return profileName
end

-- Get save file name
local saveName = AnyTypeRet(GML.variable_instance_get(GML_init_instance_id, "save_name_short"))
function modloader.getSaveName()
	return saveName
end
----------------------
  ----------------------
   ---- Profile Flags ----
  ----------------------
----------------------

local flagsList = {}
local flagsMap = {}

do
	-- Load flag list
	local id = AnyTypeRet(GML.variable_global_get("profile_flags"))
	-- Loop over internal flag list
	for i = 0, GML.ds_list_size(id) - 1 do
		-- Get value and store in both tables
		local f = AnyTypeRet(GML.ds_list_find_value(id, i))
		flagsList[#flagsList + 1] = f
		flagsMap[f] = true
	end
end

-- Get list of all active flags
function modloader.getFlags()
	-- Copy the flag list table and return it
	local r = {}
	for k, v in ipairs(flagsList) do
		r[k] = v
	end
	return r
end

-- Check if a specific flag is active
function modloader.checkFlag(flag)
	if type(flag) ~= "string" then typeCheckError("modloader.checkFlag", 1, "flag", "string", flag) end
	return flagsMap[flag] or false
end

-------------
  -------------
   ---- Mods ----
  -------------
-------------

-- Get internalname of all active mods
function modloader.getMods()
	-- Copies the mod internalname list and returns it
	local r = {}
	for k, v in ipairs(mods.modlist) do
		r[k] = v
	end
	return r
end

-- Check if a specific mod is active
function modloader.checkMod(mod)
	if type(mod) ~= "string" then typeCheckError("modloader.checkMod", 1, "mod", "string", mod) end
	return mods.mods[string.lower(mod)] and true or false
end

local function yellAboutMissingMod(s)
	error("attempt to retrieve information from unloaded mod '" .. s .. "'", 3)
end

-- Get displayed name
function modloader.getModName(mod)
	if type(mod) ~= "string" then typeCheckError("modloader.getModName", 1, "mod", "string", mod) end
	if not mods.mods[mod] then yellAboutMissingMod() end
	return mods.mods[mod].metadata.name
end

-- Get description
function modloader.getModDescription(mod)
	if type(mod) ~= "string" then typeCheckError("modloader.getModDescription", 1, "mod", "string", mod) end
	if not mods.mods[mod] then yellAboutMissingMod() end
	return mods.mods[mod].metadata.description or ""
end

-- Get raw version string
function modloader.getModVersion(mod)
	if type(mod) ~= "string" then typeCheckError("modloader.getModVersion", 1, "mod", "string", mod) end
	if not mods.mods[mod] then yellAboutMissingMod() end
	return mods.mods[mod].metadata.rawversion
end

-- Get author
function modloader.getModAuthor(mod)
	if type(mod) ~= "string" then typeCheckError("modloader.getModAuthor", 1, "mod", "string", mod) end
	if not mods.mods[mod] then yellAboutMissingMod() end
	return mods.mods[mod].metadata.author or ""
end

-------------
  -------------
   ---- Misc ----
  -------------
-------------

-- Get current namespace
function modloader.getActiveNamespace()
	return GetModContext()
end

mods.modenv.modloader = modloader