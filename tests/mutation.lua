package.path = "../src/?.lua;"..(package.path or "")
require "evolution"
require "domains"
require "constraints"
require "serialize"

x = constraints.environment:new(function(left, right)
	if left.bigdifference > right.bigdifference then
		return true
	elseif left.bigdifference < right.bigdifference then
		return false
	else
		return left.highc < right.highc
	end
end)
x:constrain("bigdifference", function() return math.abs(5-b) end)
x:constrain("highc", function() return c end)
x:register("b", domains.natural(2, 150))
x:register("c", domains.float(1, 19))

x:register("_", domains.float())
x:live()

e = evolution.population:new(x)
e:seed(10)


n = 1
print(n, b, c, _G["_"], e:average("b"), e:average("c"), e:average("_"))
for i=0,20 do
    e:age(1, 1, 0.9)
    n = n + 1
    print(n, b, c, _G["_"], e:average("b"), e:average("c"), e:average("_"))
end