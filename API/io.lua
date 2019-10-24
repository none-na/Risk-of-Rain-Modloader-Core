
local static, lookup, meta, _, special, children = NewClass("file", false, nil)
local file_unwrap = setmetatable({}, {__mode = "k"})

local function checkFile(f)
    if not children[f] then error("not a file descriptor", 3) end
end

mods.modenv.io = {
    close = function(file)
        checkFile(file)
        file_unwrap[file]:close()
    end,
    flush = function(file)
        checkFile(file)
        file_unwrap[file]:flush()
    end,
    lines = function(filename)
        if type(filename) ~= "string" then error("not a file path", 2) end
        if filename:find("%.%.") then error("cannot navigate upwards in directory", 2) end
        return io.lines(filename)
    end,
    open = function(filename, mode)
        if type(filename) ~= "string" then error("not a file path", 2) end
        if filename:find("%.%.") then error("cannot navigate upwards in directory", 2) end
        local new
        local val, err = io.open(filename, mode)
        if val ~= nil then
            new = static.new()
            file_unwrap[new] = val
        end
        return new, err
    end,
    read = function(file, ...)
        checkFile(file)
        return file_unwrap[file]:read(...)
    end,
    tmpfile = function()
        local new
        local val, err = io.tmpfile()
        if val ~= nil then
            new = static.new()
            file_unwrap[new] = val
        end
        return new, err
    end,
    type = function(obj)
        if obj == nil or file_unwrap[obj] == nil then return nil end
        return io.type(file_unwrap[obj])
    end,
    write = function(file, ...)
        checkFile(file)
        return file_unwrap[file]:write(...)
    end,
    seek = function(file, whence, offset)
        checkFile(file)
        return file_unwrap[file]:seek(whence, offset)
    end,
    setvbuf = function(file, mode, size)
        checkFile(file)
        return file_unwrap[file]:setvbuf(mode, size)
    end
}

for _, v in ipairs({
    "close",
    "flush",
    "read",
    "type",
    "write",
    "seek",
    "setvbuf"
}) do
    lookup[v] = mods.modenv.io[v]
end