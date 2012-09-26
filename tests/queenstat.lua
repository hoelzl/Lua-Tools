arg[1] = "none"
require "queens"

results = {}
results["sa"] = {}
results["evolution"] = {}
avgs = {}
avgs["sa"] = {}
avgs["evolution"] = {}
n = 100


for i=1,n do
    results["sa"][i] = {}
    constellation = sa.process:new(board)
    constellation:start("check", function (t) return 1000-t end)
    constellation:anneal(100)
    
    for c=1,100 do
        constellation:anneal(100)
        results["sa"][i][c] = constellation:rank(constellation:best())["check"]
    end
end

for i=1,n do
    results["evolution"][i] = {}
    constellations = evolution.population:new(board)
    constellations:seed(100)
    
    for c=1,100 do
        constellations:age(1, 0.05, 1.0)
        results["evolution"][i][c] = constellations:rank(constellations:best())["check"]
    end
end

table = "# & sa & evolution\\\\"
sagraph = ""
evgraph = ""


for c=1,100 do
    sum = 0
    for i=1,n do
        sum = sum + results["sa"][i][c]
    end
    avgs["sa"][c] = sum / n
    
    sum = 0
    for i=1,n do
        sum = sum + results["evolution"][i][c]
    end
    avgs["evolution"][c] = sum / n
    table = table..tostring(c).." & "..tostring(avgs["sa"][c]).." & "..tostring(avgs["evolution"][c]).."\\\\\n"
    sagraph = sagraph..tostring(c).." "..tostring(avgs["sa"][c]).."\n"
    evgraph = evgraph..tostring(c).." "..tostring(avgs["evolution"][c]).."\n"
end

print(table)
print()
print(sagraph)
print()
print(evgraph)