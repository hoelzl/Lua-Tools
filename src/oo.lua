-- test application for this under ../tests/oo.lua
-- usage ---------------------------------------------------------------------------------
-- provides versatile framework for OOP with a uniform interface across different       --
-- implementations of objects in LUA.                                                   --
-- EXPORTS: object, public, dynamic, default                                            --
------------------------------------------------------------------------------------------

local pairs = pairs
local type = type
local setmetatable = setmetatable
local getmetatable = getmetatable
local unpack = unpack
local error = error
module(...)

-- basic table functions -------------------------------------------------------
local function update(table, update)
    for key,val in pairs(update) do
        table[key] = val
    end
    return table
end

local function deepcopy(thing)
	if type(thing) == "table" then
        local metatable = getmetatable(thing)
        if metatable and metatable.copy then
            return metatable.copy(thing)
        end
		local copy = {}
		for key,val in pairs(thing) do
			copy[deepcopy(key)] = deepcopy(val)
		end
        if metatable then
            setmetatable(copy, metatable)
        end
		return copy
	else
		return thing
	end
end

local function shallowcopy(thing)
    if type(thing) == "table" then
        local copy = {}
        for key,val in pairs(thing) do
            copy[key] = val
        end
        return copy
    else
        return thing
    end
end

-- tag management (~DSL for the object notation) -------------------------------

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

-- tab object management -------------------------------------------------------

local objects = {}
setmetatable(objects, {__mode = "k"})

local function register(pointer, state)
    objects[pointer] = state
end

local function retrieve(pointer)
    return objects[pointer]
end

-- object type definitions -----------------------------------------------------

local lolclass = {
    __index = function (interface, name)
        error("method "..name.." not public or non-existing")
    end,
    __newindex == function ()
        error("no write access on object")
    end,
    copy = function (original)
        return original:clone()
    end
}

local tabclass = {
    __index = function (pointer, key)
        local state = retrieve(pointer, "state")
        if state._interface[key] then
            return function (_, ...)
                return state[key](state, unpack(arg))
            end
        else
            if state[key] then
                error("method "..key.." not public")
            else
                error("method "..key.." does not exist")
            end
        end
    end,
    __newindex = function ()
        error("no write access on object")
    end,
    copy = function (original)
        return original:clone()
    end
}

local types = {
    lol = {
        name = "lol",
        publish = function (state, name)
            return function(_, ...)
                return state[name](state, unpack(arg))
            end
        end,
        represent = function (state)
            local interface = shallowcopy(state._interface)
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
    }
}

-- abstract object construction ------------------------------------------------

local function construct(otype, template)
    if type(otype) == "string" then
        otype = types[otype] or error("object type "..otype.." does not exist")
    end
    local state = {_spawntype = otype.name}
    local interface = {}
    local dynamics = {}
    for name, value in pairs(template) do
        if type(value) == "table" and value.tag == publictag then
            state[name] = value.entity
            interface[name] = otype.publish(state, name)
        elseif type(value) == "table" and value.tag == dynamictag then 
            state[name] = deepcopy(value.entity)
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
        return construct(self._spawntype, update(template(self), intension))
    end),
    new = public (function (self)
        return self:intend{}
    end),
    clone = public (function (self)
        return self:intend{}
    end)
}

-- general module management ---------------------------------------------------

function default(type)
    object = construct(type, shallowcopy(origin))
end

default("lol")