-- test application for this under ../tests/distributed.lua
-- usage ---------------------------------------------------------------------------------
-- provides an interface for messaging across a network using the zmq (www.zeromq.org). --
-- EXPORTS: init, term, local_(get|put|qry), remote_(get|put|qry), answer               --
------------------------------------------------------------------------------------------

require "zmq"
require "serialize"

local context, srvport, cltport

function init(srv, clt)
	srvport = srv or "5555"
	cltport = clt or srvport
	context = zmq.init(1)
end

function term()
	context:term()
end

local function process(code)
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
	print("  server responded:", reply)
	socket:close()
	return process(reply)
end

function remote_get(server, query)
	return remote_action("get", server, query)
end

function remote_put(server, fact)
	return remote_action("put", server, fact)
end

function answer()
	local socket = context:socket(zmq.REP)
	socket:bind("tcp://*:"..cltport)
	local request = socket:recv() --TODO: make this non-blocking
	if request then
	    socket:send(command("ack", process(request)))
	end
    socket:close()
    return true
end
