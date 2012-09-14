-- test application for this under ../tests/shared.lua
-- usage ---------------------------------------------------------------------------------
-- provides an interface for messaging within a LUA state using the global "queues".    --
-- DEFINES: init, term, get, put, qry, answer, stop                                     --
------------------------------------------------------------------------------------------

local pairs = pairs
local coroutine = coroutine
module(...)


local protocol, queues, pending

function init(onsite, me, qs)
	protocol = {
		get = onsite.get,
		qry = onsite.qry,
		put = onsite.out,
		ack = function (fact)
			return fact
		end
	}
	me = me or "localhost"
	queues = qs or {}
	queues[me] = queues[me] or {}
	pending = queues[me]
end

function term()
	--for compatibility reasons
end

local function process(message)
	return (protocol[message.command])(message.content)
end

local function tablematch(table, constraints)
	if constraints == nil then
		return true
	end
	for key,val in pairs(constraints) do
		if not (table[key] == val) then
			return false
		end
	end
	return true
end

local function enqueue(queue, object)
	queue[#queue+1] = object
	return queue
end

local function dequeue(queue, constraints)
	local resultn = 1
	local count = #queue
	while not tablematch(queue[resultn], constraints) and resultn < count do
		resultn = resultn + 1
	end
	local result = queue[resultn]
	queue[resultn] = nil
	for i=resultn,count do
		queue[i] = queue[i+1]
	end
	return result
end

local function action(name, server, param)
	local message = {command=name, content=param, re=pending}
	enqueue(queues[server], message)
	coroutine.yield() --wait for answer
	return process(dequeue(pending, {command="ack", cause=message}))
end

function get(server, query)
	return action("get", server, query)
end

function qry(server, query)
	return action("qry", server, query)
end

function put(server, fact)
	return action("put", server, fact)
end

function stop()
	coroutine.yield(true)
	return "back"
end

function answer()
	local message = dequeue(pending)
	if message then
		if message.command == "ack" then
			answer()
			enqueue(pending, message) --put ack back
		else
			enqueue(message.re, {command="ack", content=process(message), cause=message})
		end
	end
	return true
end
