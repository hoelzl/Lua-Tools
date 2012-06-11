queues = {
	localhost = {},
}
pending = queues["localhost"]
stdserver = arg[0] or "localhost" --the shell needs this

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
	while not tablematch(queue[resultn], constraints) do
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
	enqueue(message.re, {command="ack", content=process(message), cause=message})
end

function process(message)
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

require "tools"
print(helpShell())
print([[
  The prefixed number indicates the current coroutine. New ones are produced on the fly
  when a coroutine blocks. Use the stop command to switch coroutines.]])
calls = {}
current = 1
max = 1
while true do
	calls[current] = calls[current] or coroutine.create(function() runShell(tostring(current)) end)
	if coroutine.status(calls[current]) == "dead" then
		os.exit() --calls should never die anyway
	end
	if coroutine.status(calls[current]) == "suspended" then
		_, unblock = coroutine.resume(calls[current])
		if not unblock then max = max + 1 end
	end
	current = current < max and current+1 or 1
end