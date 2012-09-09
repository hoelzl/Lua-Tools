-- test application for this under ../tests/distributed.lua
-- usage ---------------------------------------------------------------------------------
-- provides an interface for messaging across a network using the zmq (www.zeromq.org). --
-- DEFINES: init, term, get, put, qry, answer                                           --
------------------------------------------------------------------------------------------

local loadstring = loadstring
local zmq = require "zmq"
local serialize = require "serialize"
local nd = require "nd"
module(...)

local trustpeers = true

local context, protocol, srvport, cltport

function init(onsite, srv, clt)
	context = zmq.init(1)
	protocol = {
		get = onsite.get,
		qry = onsite.qry,
		put = onsite.put,
		ack = function (fact)
			return fact
		end
	}
	srvport = srv or "5555"
	cltport = clt or srvport
end

function term()
	context:term()
end

local function process(code)
	return (nd.whatif(loadstring(code), protocol, not trustpeers))
end

local function remote_action(name, server, param)
	local socket = context:socket(zmq.REQ)
	socket:connect("tcp://"..server..":"..srvport)
	socket:send(serialize.command(name, param))
	local reply = socket:recv()
	socket:close()
	return process(reply)
end

function get(server, query)
	return remote_action("get", server, query)
end

function qry(server, query)
	return remote_action("qry", server, query)
end

function put(server, fact)
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
