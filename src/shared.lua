-- test application for this under ../tests/shared.lua
-- usage ---------------------------------------------------------------------------------
-- provides an interface for messaging within a LUA state using the global "queues".    --
-- EXPORTS: init, term, local_(get|put|qry), remote_(get|put|qry), answer, stop         --
------------------------------------------------------------------------------------------

local queues, pending

function init(me, qs)
	me = me or "localhost"
	queues = qs or {}
	queues[me] = queues[me] or {}
	pending = queues[me]
end

function term()
	--for compatibility reasons
end

local function process(message)
	local commands = {
		get = function (query)
			return local_get(query)
		end,
		put = function (fact)
			return local_put(fact)
		end,
		ack = function (fact)
			return fact
		end
	}
	return (commands[message.command])(message.content)
end

function local_get(query)
	local result = "response to "..tostring(query)
	print("local get of ", query, " returns ", result)
	return result
end

function local_put(fact)
	print("local put of ", fact)
	return fact
end

local function tablematch(table, constraints)
	if constraints == nil then
		return true
	end
	for key,val in pairs(constraints) do
		if not table[key] == val then
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

local function remote_action(name, server, param)
	local message = {command=name, content=param, re=pending}
	enqueue(queues[server], message)
	coroutine.yield() --wait for answer
	return process(dequeue(pending, {command="ack", cause=message}))
end

function remote_get(server, query)
	return remote_action("get", server, query)
end

function remote_put(server, fact)
	return remote_action("put", server, fact)
end

function stop()
	coroutine.yield(true)
	return "back"
end

function answer()
	local message = dequeue(pending)
	if message then
		enqueue(message.re, {command="ack", content=process(message), cause=message})
	end
	return true
end
