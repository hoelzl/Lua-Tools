-- test application for this under ../tests/nd.lua
-- usage ---------------------------------------------------------------------------------
-- provides a non-deterministic choice operator                                         --
-- EXPORTS: whatif, orelse                                                              --
------------------------------------------------------------------------------------------

local debug = debug
local pairs = pairs
local ipairs = ipairs
local getfenv = getfenv
local setfenv = setfenv
local _G = _G
local tt = require "typetools"
module(...)

function whatif(call, globalsetting, localsetting)
    --deconstruct call patterns
    local saveglobal = not globalsetting == false
    local savelocal = not localsetting == false
    globalsetting = globalsetting == true and {} or globalsetting
    localsetting = localsetting == true and {} or localsetting
    globalsetting = globalsetting or {}
    localsetting = localsetting or {}
    --save local namespace
    if savelocal then
        local upvalues = {}
        local nups = debug.getinfo(call, "u").nups
        for i = 1,nups do
            name, value = debug.getupvalue(call, i)
            upvalues[i] = value
            debug.setupvalue(call, i, localsetting[name] or tt.deepcopy(value))
        end
    end
    --save global namespace
    if saveglobal then
        local globals = tt.proxy(getfenv(call))
        for name,value in pairs(globalsetting) do
            globals[name] = value
        end
        setfenv(call, globals)
    end
    --evaluate call
    local result = call()
    --retrieve new and restore old local namespace
    if savelocals then
        local locals = {}
        for i = 1,nups do
            _, locals[i] = debug.getupvalue(call, i)
            debug.setupvalue(call, i, upvalues[i])
        end
    end
    --return
    return result, saveglobal and globals, savelocal and locals
end

function orelse(...)
	for _,alt in ipairs(arg) do
		local result, globals, locals = whatif(alt)
		if result then
			for name, value in pairs(globals) do  --write back changes to globals
				_G[name] = value
			end
            for name, value in pairs(locals) do   --write back changes to locals
                debug.setupvalue(alt, name, value)
            end
			return result
		end
	end
	return nil
end

