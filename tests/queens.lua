package.path = "../src/?.lua;"..(package.path or "")

RNG = math.random

require "oo"
require "typetools"
require "domains"
require "constraints"
require "serialize"
require "evolution"
require "sa"

topology = {a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8}

queensdomain = oo.object:intend{
    columns = {"a", "b", "c", "d", "e", "f", "g", "h"},
    start = oo.public (function (self)
        local placement = {}
        local pos = {}
        for i,c in ipairs(self.columns) do
            local r = RNG(1, 8)
            while pos[r] do
                r = RNG(1, 8)
            end
            placement[c] = r
            pos[r] = true
        end
        return placement
    end),
    step = oo.public (function (self, origin)
        local x, y = RNG(1, 8), RNG(1, 8)
        local placement = typetools.deepcopy(origin)
        placement[self.columns[x]], placement[self.columns[y]] = placement[self.columns[y]], placement[self.columns[x]]
        return placement
    end),
    combine = oo.public (function (self, a, b)
        local cut = RNG(1, 7)
        local placement = {}
        local pos = {}
        for i=1,cut do
            placement[self.columns[i]] = a[self.columns[i]]
            pos[placement[self.columns[i]]] = true
        end
        local bi = 1
        for i=cut+1,8 do
            while pos[b[self.columns[bi]]] do
                bi = bi + 1
            end
            placement[self.columns[i]] = b[self.columns[bi]]
            pos[placement[self.columns[i]]] = true
        end
        return placement
    end)
}

board = constraints.environment:new(function (left, right)
    return left.check > right.check
end)
board:register("queens", queensdomain)
board:register("_", domains.just(0.8))

board:constrain("check", function()
    local checks = 0
    for q,queen in pairs(queens) do
        for o,other in pairs(queens) do
            if not (q == o) then
                if math.abs(topology[q] - topology[o]) == math.abs(queen - other) then
                    checks = checks + 1
                end
            end
        end
    end
    return checks
end)

mode = arg[1] or "both"

if mode == "evolution" or mode == "both" then
    print("+---+ evolutionary algorithm +-------------------+")
    constellations = evolution.population:new(board)
    constellations:seed(100)
    serialize.print(constellations:rank(constellations:best()), constellations:best():gettraits())
    
    constellations:age(100, 0.05, 1.0)
    serialize.print(constellations:rank(constellations:best()), constellations:best():gettraits())
end

if mode == "sa" or mode == "both" then
    print("+---+ simulated annealing +----------------------+")
    constellation = sa.process:new(board)
    constellation:start("check", function (t) return 1000-t end)
    serialize.print(constellation:rank(constellation:best()), constellation:best())
    
    constellation:anneal(1000)
    serialize.print(constellation:rank(constellation:best()), constellation:best())
end