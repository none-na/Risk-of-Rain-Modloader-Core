
local ffi_string = ffi.string
local Apollo = Apollo
local GML = GML
local type = type
local typeOf = typeOf

function GetCBArgs()
	local args = {}
	local argType = Apollo.pop_arg_type()
	while argType ~= -1 do
		if argType == 1 then
			args[#args + 1] = Apollo.pop_arg_number()
		elseif argType == 2 then
			--Apollo.discard_arg()
			args[#args + 1] = ffi.string(Apollo.pop_arg_string())
		else
			args[#args + 1] = nil
		end
		argType = Apollo.pop_arg_type()
	end
	return args
end

function GetCBReturn()
	local retType = Apollo.callback_get_return()
	if retType == -1 then
		return nil
	elseif retType == 1 then
		return Apollo.callback_get_return_number()
	else
		return ffi.string(Apollo.callback_get_return_string())
	end
end

function PopStrings()
	local ret = {}
	while not Apollo.out_strings_empty() do
		ret[#ret + 1] = ffi_string(Apollo.out_strings_pop())
	end
	return ret
end

function PopNumbers()
	local ret = {}
	while not Apollo.out_doubles_empty() do
		ret[#ret + 1] = Apollo.out_doubles_pop()
	end
	return ret
end

function PushStrings(d)
	for _, v in ipairs(d) do
		Apollo.out_strings_push(v)
	end
end

function PushNumbers(d)
	for _, v in ipairs(d) do
		Apollo.out_doubles_push(v)
	end
end

function PushCBArgs(d)
	for i = #d, 1, -1 do
		local v = d[i]
		local ty = type(v)
		if ty == "number" then
			Apollo.push_arg_number(v)
		elseif ty == "string" then
			Apollo.push_arg_string(v)
		else
			error("Bad argument type pushing callback args: " .. typeOf(v))
		end
	end
end

local ArgObjPool = {}
for i = 1, 60 do
	ArgObjPool[i] = ffi.new("any_type[?]", 1)
end
local ArgObjPos = 1

function AnyTypeArg(val)
	local ptr = ArgObjPool[ArgObjPos]
	local obj = ptr[0]
	local typ = type(val)
	if typ == "number" or typ == "bool" then
		obj.kind = 1
		obj.asNumber = val
	elseif typ == "string" then
		obj.kind = 2
		obj.asString = val
	else
		obj.kind = 3
	end
	ArgObjPos = ArgObjPos + 1
	if ArgObjPos > 60 then
		ArgObjPos = 1
	end
	return ptr
end

function AnyTypeRet(kind)
	if kind == 1 then
		return GML.getReturnNumber()
	elseif kind == 2 then
		return ffi_string(GML.getReturnString())
	else
		return nil
	end
end


CallbackHandlers = {}
local callbackHandlers = CallbackHandlers
local getCBArgs = GetCBArgs
local type = type

local callbackName
local collectGarbage
local function handle_callback()
	local args = getCBArgs()
	collectGarbage()
	local rt = callbackHandlers[callbackName](args)
	Apollo.clean_strings()
	if rt ~= nil then
		local ty = type(rt)
		if ty == "number" then
			Apollo.callback_return_number(rt)
		elseif ty == "string" then
			Apollo.callback_return_string(rt)
		else
			error("Bad return type for internal callback " .. callbackName .. ": " .. typeOf(rt))
		end
	end
end

local err_txt, err_msg, err_err
local function super_handle_error()
	err_txt = err_txt .. "Error: " .. err_err .."\n"
	err_txt = err_txt .. debug.traceback()
end
local function handle_error(err)
	err_err = err
	err_txt = "Critical error begin:\n"
	err_msg = "Critical error in internal modloader code."
	local s, e = pcall(super_handle_error)
	if not s then
		err_txt = err_txt .. "\nError occurred while processing critical error:\n" .. e
	end
	GML.error_error(err_txt, 0)
	GML.error_alert(err_msg, 1000)
end

Apollo.set_callback_handler(function(name)
	VerifiedInstances = {}
	callbackName = ffi_string(name)
	xpcall(handle_callback, handle_error)
end)

table.insert(CallWhenLoaded, function()
	collectGarbage = GMInstance.collectGarbage
end)


