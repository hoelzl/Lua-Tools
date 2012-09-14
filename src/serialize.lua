-- this script is used by distributed.lua
-- usage ---------------------------------------------------------------------------------
-- provides a simple serializer                                                         --
-- EXPORTS: serialize, command                                                          --
------------------------------------------------------------------------------------------
local type = type
local string = string
local tostring = tostring
local error = error
local pairs = pairs
local ipairs = ipairs
local stdprint = print
local unpack = unpack
module(...)

local function serialize(expr, saved, prologue, index)
	saved = saved or {}
	prologue = prologue or ""
	index = index or 1
	if type(expr) == "number" or type(expr) == "boolean" then
		return tostring(expr), saved, prologue, index
	elseif type(expr) == "string" then
		return string.format("%q", expr), saved, prologue, index
	elseif type(expr) == "table" then
		if not saved[expr] then
			saved[expr] = "x"..tostring(index)
			prologue = prologue..string.format("local %s={}; ", saved[expr])
			index = index + 1
			for key,val in pairs(expr) do
                local kexpr, vexpr
				kexpr, saved, prologue, index = serialize(key, saved, prologue, index)
				vexpr, saved, prologue, index = serialize(val, saved, prologue, index)
				prologue = prologue..string.format("%s[%s]=%s; ", saved[expr], kexpr, vexpr)
			end
		end
		return saved[expr], saved, prologue, index
	else
		error("cannot serialize "..type(expr))
	end
end

function command(name, param)
	local object, library, prologue = serialize(param)
	return prologue.."return "..name.."("..object..")"
end

function data(param)
	local object, library, prologue = serialize(param)
	return prologue.."return ("..object..")"
end

function print(...)
	local printargs = {}
	for i,param in ipairs(arg) do
		printargs[i] = data(param)
	end
	return stdprint(unpack(printargs))
end