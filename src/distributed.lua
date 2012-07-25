-- test application for this under ../tests/distributed.lua
-- usage ---------------------------------------------------------------------------------
-- provides an interface for messaging across a network using the zmq (www.zeromq.org). --
-- DEFINES: init, term, local_(get|put|qry), remote_(get|put|qry), answer               --
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
	local fqry = qry
	local fput = put
	local fack = ack
	get = function (query)
		return local_get(query)
	end
	qry = function (query)
		return local_qry(query)
	end
	put = function (fact)
		return local_put(fact)
	end
	ack = function (fact)
		return fact
	end
	local result = loadstring(code)()
	get = fget
	qry = fqry
	put = fput
	ack = fack
	return result
end

function local_get(query)
	local result = "response to "..tostring(query)
	print("local get of ", serialize.data(query), " returns ", result)
	return result
end

function local_qry(query)
	local result = "response to "..tostring(query)
	print("local qry of ", serialize.data(query), " returns ", result)
	return result
end

function local_put(fact)
	print("local put of ", (serialize.data(fact)))
	return fact
end

local function remote_action(name, server, param)
	local socket = context:socket(zmq.REQ)
	socket:connect("tcp://"..server..":"..srvport)
	socket:send(serialize.command(name, param))
	local reply = socket:recv()
	print("  server responded:", reply)
	socket:close()
	return process(reply)
end

function remote_get(server, query)
	return remote_action("get", server, query)
end

function remote_qry(server, query)
	return remote_action("qry", server, query)
end

function remote_put(server, fact)
	return remote_action("put", server, fact)
end

function answer(tries)
	tries = tries or 100000 --magic number achieved through tests
	local socket = context:socket(zmq.REP)
	socket:bind("tcp://*:"..cltport)
	local request = nil
	local i = 0
	while not request and i < tries do --circumvent random timeout of zmq
		request = socket:recv(zmq.NOBLOCK)
		i = i + 1
	end
	if request then
	    socket:send(serialize.command("ack", process(request)))
	end
    socket:close()
    return true
end
