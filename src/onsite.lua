-- this is a dummy module for the local interface of distributed.lua and shared.lua
-- usage ---------------------------------------------------------------------------------
-- provides an interface for local query processing.                                    --
-- DEFINES: get, qry, put                                                               --
------------------------------------------------------------------------------------------

local tostring = tostring
local print = print
local serialize = require "serialize"
module(...)


function get(query)
	local result = "response to "..tostring(query)
	print("local get of ", serialize.data(query), " returns ", result)
	return result
end

function qry(query)
	local result = "response to "..tostring(query)
	print("local qry of ", serialize.data(query), " returns ", result)
	return result
end

function put(fact)
	print("local put of ", (serialize.data(fact)))
	return fact
end