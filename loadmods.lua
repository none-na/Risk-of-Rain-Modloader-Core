local json = require "json"
local semver = require "semver"

local moddatalist = {}
local moddata = {}

local unpack = unpack or table.unpack -- 5.1/5.3 compat

local function loadFailure(n, r)
	GML.error_error("Failed to load mod "..n..": "..r, 0)
end

mods.loadWithDependencies = function(data)
	--if data.failed then
	--	print(string.format("Mod failed to load: %s", data.name))
	--end
	
	if data.loaded then
		return data.retcache and unpack(data.retcache)
	end

	if data.isloading then
		data.failed = true
		loadFailure(data.name, "circular dependency detected")
		return false
	end

	data.isloading = true

	if data.dependencies then
		for k, v in ipairs(data.dependencies) do
			local ok, err = pcall(mods.loadWithDependencies, v.data) 
			if not ok then
				data.failed = true
				loadFailure(data.name, "unable to load dependency " .. v.name)
				return false
			end
		end
	end

	data.loaded = true
	local ret = {pcall(mods.loadMod, data.path, {metadata=data})}
	data.retcache = ret
	if not ret[1] then
		loadFailure(data.name, ret[2] or "unknown")
	end
	return unpack(ret)
end

function CallbackHandlers.loadAllMods(args)
	local noOnlineList = {}
	mods.initFunctionQueue = {}
	for i = 1, #args do
		repeat
			local v = args[i]
			local f = io.open(string.format("mods/%s/metadata.json", v), "r")
			
			if not f then
				loadFailure(v, "unable to open metadata.json.")
				break
			end
			
			local s = f:read("*all")
			f:close()

			local ok, metadata = pcall(json.decode, s)
			if not ok then
				loadFailure(v, "metadata.json failed to decode with error:\n    "..metadata)
				break
			end

			if type(metadata) ~= "table" or (type(metadata.name) ~= "string" or type(metadata.version) ~= "string") then
				loadFailure(v, "metadata.json: missing fields (should be object with name:string, version:string)")
				break
			end

			metadata.dependencyList = {}
			metadata.rawversion = metadata.version
			metadata.version = semver(metadata.version)
			if metadata.mpcompat ~= true then
				table.insert(noOnlineList, metadata.name)
				metadata.mpcompat = false
			end
			if metadata.dependencies then
				for k, v in ipairs(metadata.dependencies) do
					v.version = semver(v.version)
					metadata.dependencyList[#metadata.dependencyList + 1] = string.lower(v.name)
				end
			end

			metadata.internalname = metadata.internalname or metadata.name
			metadata.path = v

			moddata[string.lower(metadata.internalname)] = metadata
			moddatalist[#moddatalist + 1] = metadata
		until true
	end

	if #noOnlineList ~= 0 then
		GML.variable_global_set("online_mp_enabled", AnyTypeArg(0))
		GML.variable_global_set("online_incompatibility_count", AnyTypeArg(#noOnlineList))
		local incompatStr = "There are " .. tostring(#noOnlineList) .. " multiplayer-incompatible mods enabled:"
		for _, incompat in ipairs(noOnlineList) do
			incompatStr = incompatStr .. "\n" .. incompat
		end
		GML.variable_global_set("online_incompatibility_string", AnyTypeArg(incompatStr))
	end

	for _, mod in ipairs(moddatalist) do
		if mod.dependencies then
			for k, dep in ipairs(mod.dependencies) do
				dep.data = moddata[string.lower(dep.name)]
				if not dep.data then 
					if dep.optional then
						mod.dependencies[k] = nil
					end
				end
			end
		end
	end

	for _, v in ipairs(moddatalist) do
		mods.loadWithDependencies(v)
	end
	
	mods.preInitializeMods()
	for _, v in ipairs(mods.initFunctionQueue) do
		CallModdedFunction(v)
	end
	mods.initFunctionQueue = nil
	FireCallback({"onLoad"})
	FireCallback({"postLoad"})
	LOAD_IN_PROGRESS = false
end