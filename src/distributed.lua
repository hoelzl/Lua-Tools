-- example usage:
-- 1. run this program twice
-- 2. type "gets hello world" into one of the instances
-- 3. type "a" into the other

require "zmq"

context = zmq.init(1)
srvport = arg[1] or "5555"
cltport = arg[2] or srvport
stdserver = arg[3] or "localhost"


-- external interface for operations -----------------------------------------------------

function local_get(query)
	local result = "response to "..tostring(query)
	print("local get of ", serialize(query), " returns ", result)
	return result
end

function local_put(fact)
	print("local put of ", (serialize(fact)))
	return fact
end

local function remote_action(name, server, param)
	local socket = context:socket(zmq.REQ)
	socket:connect("tcp://"..server..":"..srvport)
	socket:send(command(name, param))
	local reply = socket:recv()
	print("  server repsonded:", reply)
	socket:close()
	return process(reply)
end

function remote_get(server, query)
	return remote_action("get", server, query)
end

function remote_put(server, fact)
	return remote_action("put", server, fact)
end

function process(code)
	local fget = get
	local fput = put
	local fack = ack
	get = function (query)
		return local_get(query)
	end
	put = function (fact)
		return local_put(fact)
	end
	ack = function (fact)
		return fact
	end
	local result = loadstring(code)()
	get = fget
	put = fput
	ack = fack
	return result
end

function answer()
	local socket = context:socket(zmq.REP)
	socket:bind("tcp://*:"..cltport)
	local request = socket:recv()
	if request then
	    socket:send(command("ack", process(request)))
	end
    socket:close()
    return true
end


-- serialization of protocol messages ----------------------------------------------------

function serialize(expr, saved, prologue, index)
	saved = saved or {}
	prologue = prologue or ""
	index = index or 1
	if type(expr) == "number" then
		return tostring(expr), saved, prologue, index
	elseif type(expr) == "string" then
		return string.format("%q", expr), saved, prologue, index
	elseif type(expr) == "table" then
		if not saved[expr] then
			saved[expr] = "x"..tostring(index)
			index = index + 1
			prologue = prologue.."local "..saved[expr].."={}; "
			for key,val in pairs(expr) do
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

require "tools"
print(helpShell())
runShell()


context:term()