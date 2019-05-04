local GML = GML
local type = type
local typeOf = typeOf

input = {}


input.PRESSED = 3
input.HELD = 2
input.RELEASED = 1
input.NEUTRAL = 0

---------------
---- BINDS ----
---------------

local keybindIDs = {
	left = 0,
	right = 1,
	up = 2,
	down = 3,
	jump = 4,
	ability1 = 5,
	ability2 = 6,
	ability3 = 7,
	ability4 = 8,
	use = 9,
	enter = 10,
	swap = 11
}

local inst_ids = GMInstance.IDs
function input.checkControl(control, player)
	if type(control) ~= "string" then typeCheckError("input.checkControl", 1, "control", "string", control) end
	if player ~= nil and typeOf(player) ~= "PlayerInstance" then typeCheckError("input.checkControl", 2, "player", "PlayerInstance or nil", player) end
	local tc = keybindIDs[string.lower(control)]
	if not tc then error("'" .. control .. "' is not a known control", 2) end
	return GML.control_check_state(tc, player and inst_ids[player] or -1)
end

function input.getButtonKey(control, player)
	if type(control) ~= "string" then typeCheckError("input.getButtonKey", 1, "control", "string", control) end
	if player ~= nil and typeOf(player) ~= "PlayerInstance" then typeCheckError("input.getButtonKey", 2, "player", "PlayerInstance or nil", player) end
	local tc = keybindIDs[string.lower(control)]
	if not tc then error("'" .. control .. "' is not a known control", 2) end
    return ffi.string(GML.control_string(player and inst_ids[player] or -1, tc))
end

------------------
---- KEYBOARD ----
------------------

local keyboardButtons = {
	["nokey"] = 0,
	["anykey"] = 1,
	["left"] = 37,
	["right"] = 39,
	["up"] = 38,
	["down"] = 40,
	["enter"] = 13,
	["escape"] = 27,
	["space"] = 32,
	["shift"] = 16,
	["control"] = 17,
	["alt"] = 18,
	["backspace"] = 8,
	["tab"] = 9,
	["home"] = 36,
	["end"] = 35,
	["delete"] = 46,
	["insert"] = 45,
	["pageup"] = 33,
	["pagedown"] = 34,
	["pause"] = 19,
	["printscreen"] = 44,
	["f1"] = 112,
	["f2"] = 113,
	["f3"] = 114,
	["f4"] = 115,
	["f5"] = 116,
	["f6"] = 117,
	["f7"] = 118,
	["f8"] = 119,
	["f9"] = 120,
	["f10"] = 121,
	["f11"] = 122,
	["f12"] = 123,
	["numpad0"] = 96,
	["numpad1"] = 97,
	["numpad2"] = 98,
	["numpad3"] = 99,
	["numpad4"] = 100,
	["numpad5"] = 101,
	["numpad6"] = 102,
	["numpad7"] = 103,
	["numpad8"] = 104,
	["numpad9"] = 105,
	["multiply"] = 106,
	["divide"] = 111,
	["add"] = 107,
	["subtract"] = 109,
	["decimal"] = 110
}

for i = 48, 57 do -- 0 to 9
	keyboardButtons[string.char(i)] = i
end

for i = 97, 122 do -- A to Z
	keyboardButtons[string.char(i)] = i - 32
end

function input.checkKeyboard(key)
	if type(key) ~= "string" then typeCheckError("input.checkKeyboard", 1, "key", "string", key) end
	local tk = keyboardButtons[string.lower(key)]
	if not tk then error("'" .. key .. "' is not a known keyboard key", 2) end
	return GML.keyboard_check_state(tk)
end

-----------------
---- GAMEPAD ----
-----------------

local gamepadButtons = {
	["face1"] = 32769,
	["face2"] = 32770,
	["face3"] = 32771,
	["face4"] = 32772,
	["shoulderl"] = 32773,
	["shoulderlb"] = 32775,
	["shoulderr"] = 32774,
	["shoulderrb"] = 32776,
	["select"] = 32777,
	["start"] = 32778,
	["stickl"] = 32779,
	["stickr"] = 32780,
	["padu"] = 32781,
	["padd"] = 32782,
	["padl"] = 32783,
	["padr"] = 32784
}

function input.checkGamepad(button, gamepad)
	if type(button) ~= "string" then typeCheckError("input.checkGamepad", 1, "button", "string", button) end
	if type(gamepad) ~= "number" then typeCheckError("input.checkGamepad", 2, "gamepad", "number", gamepad) end
	local tb = gamepadButtons[string.lower(button)]
	if not tb then error("'" .. button .. "' is not a known gamepad button", 2) end
	return GML.gamepad_button_check_state(gamepad, tb)
end

function input.getPlayerGamepad(player)
	if player ~= nil and typeOf(player) ~= "PlayerInstance" then typeCheckError("input.getPlayerGamepad", 1, "player", "PlayerInstance or nil", player) end
	local r = GML.player_get_gamepad_index(player and GMInstance.IDs[player] or -1)
	if r and r < 0 then return nil else return r end
end

local gamepadAxis = {
	["lh"] = 32785,
	["lv"] = 32786,
	["rh"] = 32787,
	["rv"] = 32788
}

function input.getGamepadAxis(axis, gamepad)
	if type(axis) ~= "string" then typeCheckError("input.getGamepadAxis", 1, "axis", "string", axis) end
	if type(gamepad) ~= "number" then typeCheckError("input.getGamepadAxis", 2, "gamepad", "number", gamepad) end
	local ta = gamepadAxis[string.lower(axis)]
	if not ta then error("'" .. axis .. "' is not a known gamepad axis", 2) end
	return GML.gamepad_axis_value(gamepad, ta)
end

---------------
---- MOUSE ----
---------------

local mouseButtons = {
	none = 0,
	left = 1,
	right = 2,
	middle = 3
}

function input.checkMouse(button)
	if type(button) ~= "string" then typeCheckError("input.checkMouse", 1, "button", "string", button) end
	local tb = mouseButtons[string.lower(button)]
	if not tb then error("'" .. key .. "' is not a known mouse button", 2) end
	return GML.mouse_check_button_state(tb)
end

function input.getMousePos(screen)
	if screen ~= nil and type(screen) ~= "boolean" then typeCheckError("input.getMousePos", 1, "screen", "boolean or nil", screen) end
	if screen then
		return GML.mouse_get_screen_x(), GML.mouse_get_screen_y()
	else
		return AnyTypeRet(GML.variable_global_get("mouse_x")), AnyTypeRet(GML.variable_global_get("mouse_y"))
	end
end

function input.getMouseScroll()
	-- uhhhh yeah
	return GML.mouse_wheel_value()
end

-- env
mods.modenv.input = input
