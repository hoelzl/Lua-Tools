local pairs = pairs
local type = type
local setmetatable = setmetatable
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
		local copy = {}
		for key,val in pairs(thing) do
			copy[deepcopy(key)] = deepcopy(val)
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

function public(method)
    if not type(method) == "function" then
        error("only functions can be public")
    end
    return {tag=publictag, entity=method}
end

local function tag(state, interface)
    local template = {}
    for name,value in pairs(state) do
        template[name] = interface[name] and public(state[name]) or state[name]
    end
    return template
end

-- tab objects (based on weak and meta tables) ---------------------------------

local objects = {}
setmetatable(objects, {__mode = "k"})

local function register(pointer, state, interface)
    objects[pointer] = {state=state or {}, interface=interface or {}}
end

local function retrieve(pointer, key)
    if key == nil then
        return objects[pointer] or {}
    end
    if objects[pointer] then
        return objects[pointer][key] or {}
    end
    return {}
end


local class = {
    __index = function (table, key)
        if retrieve(table, "interface")[key] then
            local state = retrieve(table, "state")
            return function (_, ...)
                return state[key](state, unpack(arg))
            end
        else
            if retrieve(table, "state")[key] then
                error("method "..key.." not public")
            else
                error("method "..key.." does not exist")
            end
        end
    end,
    __newindex = function ()
        error("no write access on object")
    end
}

local function tabobject(state)
    state = state or {}
    local pointer = {}
    setmetatable(pointer, class)
    register(pointer, state)
    for name, value in pairs(state) do
        if type(value) == "table" and value.tag == publictag then
            state[name] = value.entity
            objects[pointer].interface[name] = true
        end
    end
    state.intend = function (_, intension)
        return tabobject(update(tag(state, objects[pointer].interface), intension))
    end
    objects[pointer].interface.intend = true
    return pointer
end

-- lol objects (based on a let over lambda mechanism) --------------------------

local function lolobject(state)
    state = state or {}
    local interface = {}
    for name, value in pairs(state) do
        if type(value) == "table" and value.tag == publictag then
            state[name] = value.entity
            interface[name] = function(_, ...)
                return state[name](state, unpack(arg))
            end
        end
    end
    state.intend = function (_, intension)
        return lolobject(update(tag(state, interface), intension))
    end
    interface.intend = state.intend
    return interface
end

-- general module management ---------------------------------------------------

local origin = {
    new = public (function (self)
        return self:intend{}
    end),
    clone = public (function (self)
        return self:intend{}
    end)
}

object = lolobject(shallowcopy(origin))

function default(type)
    if type == "lol" then
        object = lolobject(shallowcopy(origin))
    elseif type == "tab" then
        object = tabobject(shallowcopy(origin))
    else
        error("unrecognized object type")
    end
end