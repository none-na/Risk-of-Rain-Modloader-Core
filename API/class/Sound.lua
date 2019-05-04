-- Create class
local static, lookup, meta, ids, special, children = NewClass("Sound", true)
meta.__tostring = __tostring_default_namespace
-- Create global table
Sound = {}

all_sounds = {vanilla = {}}

-- Properties
sound_origin = {}
id_to_sound = {}
sound_name = {}

-----------------------------------------
-- Class methods ------------------------
-----------------------------------------
function lookup:play(pitch, volume)
	if not children[self] then methodCallError("Sound:play", self) end
	if type(pitch) ~= "number" and pitch ~= nil then typeCheckError("Sound:play", 1, "pitch", "number or nil", pitch) end
	if type(volume) ~= "number" and volume ~= nil then typeCheckError("Sound:play", 1, "volume", "number or nil", volume) end
	GML.sound_play_ext(ids[self], pitch or 1, volume or 1)
end

function lookup:stop()
	if not children[self] then methodCallError("Sound:stop", self) end
	GML.sound_stop(ids[self])
end

function lookup:isPlaying()
	if not children[self] then methodCallError("Sound:isPlaying", self) end
	return (GML.sound_isplaying(ids[self]) > 0)
end

function lookup:loop()
	if not children[self] then methodCallError("Sound:loop", self) end
	GML.sound_loop(ids[self])
end

function lookup:getOrigin()
	if not children[self] then methodCallError("Sound:getOrigin", self) end
	return sound_origin[self]
end

function lookup:getName()
	if not children[self] then methodCallError("Sound:getName", self) end
	return sound_name[self]
end

-----------------------------------------
-- Global methods -----------------------
-----------------------------------------
Sound.find = contextSearch(all_sounds, "Sound.find")
Sound.findAll = contextFindAll(all_sounds, "Sound.findAll")

function load_sound(funcName, name, fname)
	if type(name) ~= "string" then typeCheckError(funcName, 1, fname == nil and "fname" or "name", "string", name) end
	if fname == nil then
		fname = name
		name = getFilename(name)
	else
		if type(fname) ~= "string" then typeCheckError(funcName, 2, "fname", "string", fname) end
	end
	local context = GetModContext()
	local finalfname = ResolveModPath()..fname
	contextVerify(all_sounds, name, context, "Sound")
	
	local s = GML.sound_add(finalfname)
	if s < 0 then
		s = GML.sound_add(finalfname..".wav")
	end
	if s < 0 then
		s = GML.sound_add(finalfname..".ogg")
	end
	
	if s < 0 then
		return error(string.format('unable to load sound %q, the file could not be found', fname))
	else
		local new = static.new(s)
		registerNetID("sound", s, context, name)
		sound_origin[new] = context
		id_to_sound[s] = new
		sound_name[new] = name
		contextInsert(all_sounds, name, context, new)
		return new
	end
end

function Sound.load(name, fname)
	return load_sound("Sound.load", name, fname)
end

setmetatable(Sound, {__call = function(t, name, fname)
	return load_sound("Sound", name, fname)
end})

do
	local ttable = all_sounds.vanilla
	local t = 0
	while true do
		local rawname = ffi.string(GML.sound_get_name(t))
		if rawname == "<undefined>" then
			-- Just checking if sounds exist seems to actually end up returning that more than a thousand nonexistent sounds actually exist
			-- Super weird but its just safer to do this I guess
			break
		else
			local new = static.new(t)
			local name = string.sub(rawname, 2, -1)
			ttable[string.lower(name)] = new

			sound_name[new] = name
			sound_origin[new] = "vanilla"
			id_to_sound[t] = new

			t = t + 1
		end
	end
end

SoundUtil = {}
SoundUtil.ids = ids
SoundUtil.ids_map = id_to_sound

-- Add to mod environment
mods.modenv.Sound = Sound
