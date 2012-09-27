-- test application for this under ../tests/oo.lua
-- usage ---------------------------------------------------------------------------------
-- provides object implementation for the module oo.                                    --
-- EXPORTS: lol, tab, noo                                                               --
------------------------------------------------------------------------------------------

local pairs = pairs
local ipairs = ipairs
local setmetatable = setmetatable
local unpack = unpack
local error = error
local tt = require "typetools"
module(...)

-- tab object management -----------------------------------------------------------------

local objects = {}
setmetatable(objects, {__mode = "k"})

local function register(pointer, state)
    objects[pointer] = state
end

local function retrieve(pointer)
    return objects[pointer]
end


-- object representation metatables ------------------------------------------------------

local function method(state, name)
    return function(callee, ...)
        local result = state[name](state, unpack(arg))
        if result == state then --prevent state from leaking out
            return callee
        else
            return result
        end
    end
end

local function writeerror()
    error("no write access on object")
end

local function clone(original)
    return original:clone()
end

local lolclass = {
    __index = function () return nil end,
    __newindex = writeerror,
    __copy = clone
}

local tabclass = {
    __index = function (pointer, key)
        local state = retrieve(pointer, "state")
        if state._interface[key] then
            return method(state, key)
        else
            return nil
        end
    end,
    __newindex = writeerror,
    __copy = clone
}

local nooclass = {
    __copy = clone
}


-- type library --------------------------------------------------------------------------

lol = {
    name = "lol",
    publish = method,
    represent = function (state)
        local interface = tt.shallowcopy(state._interface)
        setmetatable(interface, lolclass)
        state._represenation = interface
        return interface
    end
}

tab = {
    name = "tab",
    publish = function (state, name)
        return true
    end,
    represent = function (state)
        local pointer = {}
        setmetatable(pointer, tabclass)
        state._representation = pointer
        register(pointer, state, state._interface)
        return pointer
    end
}

noo = {
    name= "noo",
    publish = function (state, name)
        return nil
    end,
    represent = function (state)
        state._representation = state
        setmetatable(state, nooclass)
        return state
    end
}