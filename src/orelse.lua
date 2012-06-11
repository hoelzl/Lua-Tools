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

--only test code form here on

testg = "Hello"
testh = "Hello"
local test = 33
local testable = {a=71, b=72, c=73}

-- test code here
function test1()
	test = 7
	testg = "Wiedersehen"
	testh = "Wiedersehen"
	return nil
end

function test2()
	testable.a = 53
	return nil
end

function test3()
	test = 55
	testable.a = 6
	testg = "Arrivederci"
	return nil
end

function test4()
	test = 42
	testg = "Goodbye"
	return testable.a
end

function test5()
	test = 77
	return nil
end

function test6()
	return 42
end

function dotest()
	local result = orelse(test1, test2, test3, test4, test5, test6)
	--stop this from being a tail call
	return result
end

print(dotest())
print(test, testh, testg)