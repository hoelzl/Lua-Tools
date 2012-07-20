package.path = "../src/?.lua;"..(package.path or "")
require "evolution"
require "domains"
require "constraints"
require "serialize"


a = 5
--b = 7
--c = 3

x = newConstraintEnvironment(function(a, b)
	if a.bigdifference > b.bigdifference then
		return true
	elseif a.bigdifference < b.bigdifference then
		return false
	else
		return a.highc < b.highc
	end
end)
x.constrain("bigdifference", function() return math.abs(a-b) end)
x.constrain("highc", function() return c end)
x.register("b", domains.natural(2, 150))
x.register("c", domains.float(1, 19))
--let evolution determine the general mutation rate:
--x.register("__", domains.float())

--test1, test1result = x.test({{b=8}, {b=4}, {b=9}})
--print(test1, command("id", test1result))

e = newPopulation(x)
e.seed(10)

test2result = e.best()
serialize.print(test2result.traits)
test3result = e.age(21).best()
serialize.print(test3result.traits)
test4result = e.age(21).best()
serialize.print(test4result.traits)

