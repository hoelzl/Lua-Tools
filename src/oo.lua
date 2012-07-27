-- test application for this under ../tests/oo.lua
-- usage ---------------------------------------------------------------------------------
-- provides versatile framework for OOP with a uniform interface across different       --
-- implementations of objects in LUA.                                                   --
-- EXPORTS: object, public, dynamic, instantiate, default                               --
------------------------------------------------------------------------------------------

local pairs = pairs
local ipairs = ipairs
local type = type
local setmetatable = setmetatable
local getmetatable = getmetatable
local unpack = unpack
local error = error
local tt = require "typetools"
module(...)

-- tag management (~DSL for the object notation) -----------------------------------------

local publictag = {}
local dynamictag = {}

function public(method)
    if not type(method) == "function" then
        error("only functions can be public")
    end
    return {tag=publictag, entity=method}
end

function dynamic(property)
    if not type(property) == "table" then
        error("only referential types (i.e. tables) can be marked as dynamic")
    end
    return {tag=dynamictag, entity=property}
end

local function tag(state, interface, dynamics)
    local template = {}
    for name,value in pairs(state) do
        template[name] = interface[name] and public(state[name]) or state[name]
        template[name] = dynamics[name] and dynamic(state[name]) or template[name]
    end
    return template
end

local function template(state)
    return tag(state, state._interface, state._dynamics)
end

-- tab object management -----------------------------------------------------------------

local objects = {}
setmetatable(objects, {__mode = "k"})

local function register(pointer, state)
    objects[pointer] = state
end

local function retrieve(pointer)
    return objects[pointer]
end

-- object type definitions ---------------------------------------------------------------

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
    __index = function () return nil end,
    __newindex = writeerror,
    __copy = clone
}

local types = {
    lol = {
        name = "lol",
        publish = method,
        represent = function (state)
            local interface = tt.shallowcopy(state._interface)
            setmetatable(interface, lolclass)
            return interface
        end
    },
    tab = {
        name = "tab",
        publish = function (state, name)
            return true
        end,
        represent = function (state)
            local pointer = {}
            setmetatable(pointer, tabclass)
            register(pointer, state, state._interface)
            return pointer
        end
    },
    noo = {
        name= "noo",
        publish = function (state, name)
            return nil
        end,
        represent = function (state)
            setmetatable(state, nooclass)
            return state
        end
    }
}

-- abstract object construction ----------------------------------------------------------

local function construct(typename, template)
    otype = types[typename] or error("object type "..tostring(typename).." doesn't exist")
    local state = {_spawntype = otype.name}
    local interface = {}
    local dynamics = {}
    for name, value in pairs(template) do
        if type(value) == "table" and value.tag == publictag then
            state[name] = value.entity
            interface[name] = otype.publish(state, name)
        elseif type(value) == "table" and value.tag == dynamictag then 
            state[name] = tt.deepcopy(value.entity)
            dynamics[name] = true
        else
            state[name] = value
        end
    end
    state._interface = interface
    state._dynamics = dynamics
    return otype.represent(state)
end

local origin = {
    intend = public (function (self, intension)
        return construct(self._spawntype, tt.update(template(self), intension))
    end),
    new = public (function (self)
        return self:intend{}
    end),
    clone = public (function (self)
        return self:intend{}
    end)
}

function instantiate(...)
    local names = arg
    return function (self, ...)
        local template = {}
        for i,name in ipairs(names) do
            template[name] = arg[i] or self[name]
        end
        return self:intend(template)
    end
end

-- general module management -------------------------------------------------------------

function default(type)
    object = construct(type, tt.shallowcopy(origin))
end

default("lol")