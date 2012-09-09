-- this script is used in the tests for distributed.lua as well as shared.lua
-- usage ---------------------------------------------------------------------------------
-- provides a simple, shell based user interface for testing purposes                   --
-- EXPORTS: help, run                                                                   --
------------------------------------------------------------------------------------------

module(..., package.seeall)
local remote_get = function (...) return remote.get(unpack(arg)) end
local remote_put = function (...) return remote.put(unpack(arg)) end
local remote_qry = function (...) return remote.qry(unpack(arg)) end
local id = function (x) return x end
local ignore = function () return nil end
local interpret = function (x) return loadstring("return "..x)() end

local commands = {
	gets = {       --shortcut for get of a string
		preprocess = id,
		process    = remote_get,
		help       = "Call remote_get with given string."
	},
	get = {
		preprocess = interpret,
		process    = remote_get,
		help       = "Call remote_get with given lua expression."
	},
	qrys = {       --shortcut for qry of a string
		preprocess = id,
		process    = remote_qry,
		help       = "Call remote_qry with given string."
	},
	qry = {
		preprocess = interpret,
		process    = remote_qry,
		help       = "Call remote_qry with given lua expression."
	},
	puts = {       --shortcut for put of a string
		preprocess = id,
		process    = remote_put,
		help       = "Call remote_put with given string."
	},
	put = { 
		preprocess = interpret,
		process    = remote_put,
		help       = "Call remote_put with given lua expression."
	},
	test = {       --tests handling (especially serialization) of cyclic tables
		preprocess = function ()
			local param = {a = 40, b = 41, c = 42}
			param.c = param
			return param
		end,
		process    = remote_put,
		help       = "Call remote_put with a predefined circular table"
	},
	stop = {
		preprocess = id,
		process    = remote.stop or function () return "not supported" end,
		help       = "If working with coroutines, do a manual yield."
	},
	answer = {     --causes program to process pending messages
		preprocess = id,
		process    = function() return remote.answer() end,
		help       = "Answer to pending message."
	},
	quit = {       --quit the program
		preprocess = id,
		process    = function () os.exit() end,
		help       = "Quit the execution of this program."
	}
}
commands.a = commands.answer
commands.q = commands.quit
commands.cmds = {
	preprocess = ignore,
	process    = function ()
		local res = ""
		for name,_ in pairs(commands) do
			res = res..name..", "
		end
		return res
	end,
	help       = "Returns a list of all available commands"
}
commands.help = {
	preprocess = id,
	process    = function (_,param)
		return commands[param] and commands[param].help or "no command "..param
	end,
	help       = "Print a help for goven command."
}

-- print a simple help string for the user
function help()
	return "  Type cmds for a list of available commands. Type help <command> for help."
end

-- run the shell (this call never returns)
function run(stdserver, prefix)
	prefix = prefix or ""
	while true do
		io.write(prefix, "> ")
		local command = io.read("*line")
		local recognized = false
		for name,steps in pairs(commands) do
			if string.match(command, "^"..name.."$") or string.match(command, "^"..name.."%s") then
				recognized = true
				local param = steps.preprocess(string.gsub(command, "^"..name.."%s+(.*)$", "%1"))
				local result = steps.process(stdserver, param)
				io.write(prefix, ": ", tostring(result), "\n")
				--break
			end
		end
		if not recognized then
			io.write("  unrecognized command\n")
		end
	end
end
