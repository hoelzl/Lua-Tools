-- example usage -------------------------------------------------------------------------
-- 1. Run this script.                                                                  --
-- 2. Compare the generated output to the program code.                                 --
-- 3. ????                                                                              --
-- 4. PROFIT!                                                                           --
------------------------------------------------------------------------------------------

package.path = "../src/?.lua;"..(package.path or "")
require "orelse"

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