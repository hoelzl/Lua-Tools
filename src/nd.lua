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
    local saveglobal = not (globalsetting == false)
    local savelocal = not (localsetting == false)
    globalsetting = globalsetting == true and {} or globalsetting
    localsetting = localsetting == true and {} or localsetting
    globalsetting = globalsetting or {}
    localsetting = localsetting or {}
    local fenv = {}
    local globals = {}
    local locals = {}
    local upvalues = {}
    local newvalues = {}
    local nups = 0
    --save local namespace
    if savelocal then
        nups = debug.getinfo(call, "u").nups
        for i = 1,nups do
            name, value = debug.getupvalue(call, i)
            upvalues[i] = value
            debug.setupvalue(call, i, localsetting[name] or tt.deepcopy(value))
        end
    end
    --save global namespace
    if saveglobal then
        fenv = getfenv(call)
        globals = tt.proxy(fenv)
        for name,value in pairs(globalsetting) do
            globals[name] = value
        end
        setfenv(call, globals)
    end
    --evaluate call
    local result = call()
    --restore old global namespace
    if saveglobal then
        setfenv(call, fenv)
    end
    --retrieve new and restore old local namespace
    if savelocal then
        for i = 1,nups do
            name, value = debug.getupvalue(call, i)
            locals[name] = value
            newvalues[i] = value
            debug.setupvalue(call, i, upvalues[i])
        end
    end
    --return
    return result, (saveglobal and globals), (savelocal and locals), (savelocal and newvalues)
end

function orelse(...)
	for _,alternative in ipairs(arg) do
		local result, globals, _, upvalues = whatif(alternative)
		if result then
			for name, value in pairs(globals) do   --write back changes to globals
				_G[name] = value
			end
            for name, value in pairs(upvalues) do  --write back changes to locals
                debug.setupvalue(alternative, name, value)
            end
			return result
		end
	end
	return nil
end

