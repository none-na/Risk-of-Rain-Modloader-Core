
mods.modenv.io = {
    close = function(file)
        --if io.output() == io.stdout then error("no output file currently open", 2) end
        if io.file(file) == nil then error("not a file descriptor", 2) end
        return io.close(file)
    end,
    flush = function(file)
        --if io.output() == io.stdout then error("no output file currently open", 2) end
        if io.file(file) == nil then error("not a file descriptor", 2) end
        return io.flush(file)
    end,
    input = function(file)
        if not file and io.input() == io.stdin then error("no input file currently open", 2) end
        if io.file(file) == nil and type(file) ~= "string" then error("not a file descriptor or string", 2) end
        return io.input(file)
    end,
    lines = function(file)
        if io.file(file) == nil and type(file) ~= "string" then error("not a file descriptor or string", 2) end
        if type(file) == "string" and file:find("..") then error("cannot navigate upwards in directory", 2) end
        return io.lines(file)
    end,
    open = function(filename, mode)
        if type(filename) ~= "string" then error("not a file path", 2) end
        if type(filename) == "string" and filename:find("..") then error("cannot navigate upwards in directory", 2) end
        return io.open(filename, mode)
    end,
    output = function(file)
        if not file and io.output() == io.stdout then error("no output file currently open", 2) end
        if io.file(file) == nil and type(file) ~= "string" then error("not a file descriptor or string", 2) end
        return io.output(file)
    end,
    read = function(file, format)
        if io.file(file) == nil then error("not a file descriptor", 2) end
        return io.read(file, format)
    end,
    tmpfile = function()
        return io.tmpfile()
    end,
    type = function(obj)
        return io.type(obj)
    end,
    write = function(file, args)
        if io.file(file) == nil then error("not a file descriptor", 2) end
        return io.write(file, args)
    end,
    seek = function(file, whence, offset)
        if io.file(file) == nil then error("not a file descriptor", 2) end
        return io.seek(file, whence, offset)
    end,
    setvbuf = function(file, mode, size)
        if io.file(file) == nil then error("not a file descriptor", 2) end
        return io.setvbuf(file, mode, size)
    end
}