package.path = "../src/?.lua;"..(package.path or "")
require "evolution"
require "domains"
require "constraints"
require "serialize"

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

--set the general mutation rate:
--x:register("_", domains.just(0.7))

--let evolution determine the general mutation rate:
x:register("_", domains.float())

--let evolution determine the specific mutation rate:
--x:register("_b", domains.float())
--x:register("_c", domains.float())


e = evolution.population:new(x)
e:seed(10)

test2result = e:best()
serialize.print(test2result:gettraits())
test3result = e:age(21):best()
serialize.print(test3result:gettraits())
e:grow(5)
test4result = e:age(21):best()
serialize.print(test4result:gettraits())