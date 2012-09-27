-- test application for this under ../tests/oo.lua
-- usage ---------------------------------------------------------------------------------
-- provides versatile framework for OOP with a uniform interface across different       --
-- implementations of objects in LUA.                                                   --
-- EXPORTS: object, public, dynamic, instantiate, getter, setter, default               --
------------------------------------------------------------------------------------------

local pairs = pairs
local ipairs = ipairs
local type = type
local unpack = unpack
local error = error
local tt = require "typetools"
local types = require "ootypes"
module(...)
local defaultobjecttype = "tab"

-- tag management (~DSL for the object notation) -----------------------------------------

local publictag = {}
local dynamictag = {}

function public(method)
    if not (type(method) == "function") then
        error("only functions can be public")
    end
    return {tag=publictag, entity=method}
end

function dynamic(property)
    if not (type(property) == "table" or type(property) == "nil") then
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
        intension._super = self._representation
        return construct(self._spawntype, tt.update(template(self), intension))
    end),
    new = public (function (self)
        return self:intend{}
    end),
    clone = public (function (self)
        return self:intend{}
    end),
    super = (function (self)
        return self._super
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

function getter(...)
    local names = arg
    return function(self)
        local values = {}
        for i,name in ipairs(names) do
            values[i] = self[name]
        end
        return unpack(values)
    end
end

function setter(...)
    local names = arg
    return function(self, ...)
        local values = arg
        for i,name in ipairs(names) do
            self[name] = values[i]
        end
        return self
    end
end

-- general module management -------------------------------------------------------------

object = nil --real declaration happens inside default()

function default(type)
    type = type or defaultobjecttype
    object = construct(type, tt.shallowcopy(origin))
end

default()