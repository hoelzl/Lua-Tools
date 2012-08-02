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
--let evolution determine the general mutation rate:
x:register("__", domains.float())

--test1, test1result = x.test({{b=8}, {b=4}, {b=9}})
--print(test1, command("id", test1result))

e = evolution.population:new(x)
e:seed(10)

test2result = e:best()
serialize.print(test2result:gettraits())
test3result = e:age(21):best()
e:grow(5)
serialize.print(test3result:gettraits())
test4result = e:age(21):best()
serialize.print(test4result:gettraits())