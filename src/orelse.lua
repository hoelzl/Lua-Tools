-- test application for this under ../tests/orelse.lua
-- usage ---------------------------------------------------------------------------------
-- provides a non-deterministic choice operator                                         --
-- EXPORTS: proxy, orelse                                                               --
------------------------------------------------------------------------------------------

function proxy(target)
	if type(target) == "table" then
		local proxytable = {}
		local proxymetatable = {
			__index = function(_, key)
				return proxy(target[key])
			end
		}
		setmetatable(proxytable, proxymetatable)
		return proxytable
	else
		return target --only non-destructive operations on non-tables anyway
	end
end

function orelse(...)
	local alternatives = arg
	alternatives.n = nil --remove standard attribute of arg
	for _,alt in pairs(alternatives) do
		local upvalues = {}
		local nups = debug.getinfo(alt, "u").nups
		for i = 1,nups do  --save local namespace and prevent changes on the originals
			name, value = debug.getupvalue(alt, i)
			upvalues[i] = value
			debug.setupvalue(alt, i, proxy(value))
		end
		setfenv(alt, proxy(_G))  --prevent changes in the global namespace
		local result = alt()
		if result then
			for name, value in pairs(getfenv(alt)) do  --write back changes to globals
				_G[name] = value
			end
			return result
		end
		for i = 1,nups do  --restore local namespace from before the call
			debug.setupvalue(alt, i, upvalues[i])
		end
	end
	return nil
end
