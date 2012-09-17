package.path = "../src/?.lua;"..(package.path or "")
require "sa"
require "domains"
require "constraints"
require "serialize"

--note: this is NOT a typical usecase for SA, it's merely a comparison to evolution.lua


a = 5

x = constraints.environment:new(function(left, right)
	if left.bigdifference > right.bigdifference then
		return true
	elseif left.bigdifference < right.bigdifference then
		return false
	else
		return left.highc < right.highc
	end
end)
x:constrain("bigdifference", function() return math.abs(a-b) end)
x:constrain("highc", function() return c end)
x:register("b", domains.natural(2, 150))
x:register("c", domains.float(1, 19))


e = sa.process:new(x)
e:start("bigdifference")

test2result = e:best()
serialize.print(test2result)
test3result = e:anneal(21):best()
serialize.print(test3result)
test4result = e:anneal(21):best()
serialize.print(test4result)