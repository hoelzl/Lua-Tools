-- this script is mainly used by oo.lua
-- usage ---------------------------------------------------------------------------------
-- provides tools for handling complex data types                                       --
-- EXPORTS: update, deepcopy, shallowcopy, proxy                                        --
------------------------------------------------------------------------------------------

local type = type
local getmetatable = getmetatable
local setmetatable = setmetatable
local stdpairs = pairs
module(...)

function update(table, update)
    for key,val in pairs(update) do
        table[key] = val
    end
    return table
end

function deepcopy(thing, cache)
    cache = cache or {}
	if type(thing) == "table" then
        local metatable = getmetatable(thing)
        if metatable and metatable.__copy then
            return metatable.__copy(thing)
        end
		local copy = {}
		for key,val in stdpairs(thing) do
            if not cache[key] then
                cache[key] = {}
                cache[key] = deepcopy(key, cache)
            end
            if not cache[val] then
                cache[val] = {}
                cache[val] = deepcopy(val, cache)
            end
            copy[cache[key]] = cache[val]
		end
        if metatable then
            setmetatable(copy, metatable)
        end
		return copy
	else
		return thing
	end
end

function shallowcopy(thing)
    if type(thing) == "table" then
        local copy = {}
        for key,val in stdpairs(thing) do
            copy[key] = val
        end
        return copy
    else
        return thing
    end
end

function proxy(target)
	if type(target) == "table" then
		local proxytable = {}
		local proxymetatable = {
			__index = function(table, key)
                table[key] = deepcopy(target[key])
				return target[key] and table[key]
			end
		}
		setmetatable(proxytable, proxymetatable)
		return proxytable
	else
		return target --only non-destructive operations on non-tables anyway
	end
end

function pairs(table)
    local metatable = getmetatable(table)
    if metatable and metatable.__pairs then
        return metatable.__pairs(table)
    end
    return stdpairs(table)
end