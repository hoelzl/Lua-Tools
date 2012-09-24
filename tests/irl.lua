package.path = "../src/?.lua;"..(package.path or "")

RNG = math.random

require "oo"
require "typetools"
require "domains"
require "constraints"
require "serialize"
require "evolution"
require "sa"

mode = arg[1] or "both"

world = constraints.environment:new(function (a, b)
    if a.tag == 1 and b.tag == 1 then
        return a.left < b.left
    elseif a.tag == 2 and b.tag == 2 then
        return a.right < b.right
    elseif a.tag == 1 and b.tag == 2 then
        return a.left < b.right
    else
        return a.right < b.left
    end
end)
world:register("tag", domains.natural(1, 2))
world:register("orientation", domains.float(0, 180))
world:constrain("tag", function () return tag end)
world:constrain("left", function ()
    if orientation <= 90 then
        return 90-orientation
    else
        return 0
    end
end)
world:constrain("right", function ()
    if orientation >= 90 then
        return orientation-90
    else
        return 0
    end
end)
    
if mode == "evolution" or mode == "both" then
    print("+---+ evolutionary algorithm +-------------------+")
    p = evolution.population:new(world)
    p:seed(10)
    serialize.print(p:rank(p:best()), p:best():gettraits())
    
    p:age(10)
    serialize.print(p:rank(p:best()), p:best():gettraits())
end

if mode == "sa" or mode == "both" then
    print("+---+ simulated annealing +----------------------+")
    p = sa.process:new(world)
    p:start("left", function (t) return 20-t end)
    serialize.print(p:rank(p:best()), p:best())
    
    p:anneal(100)
    serialize.print(p:rank(p:best()), p:best())
end