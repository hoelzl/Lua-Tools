local math = math
local RNG = RNG or math.random
module(...)

function natural(min, max, stepsize)
    min = min or 0
    max = max or 1
    stepsize = stepsize or 1
    local this = {}
    function this.start()
        return RNG(min, max)
    end
    function this.step(origin)
        if origin == min then return min + stepsize end
        if origin == max then return max - stepsize end
        if RNG(0, 1) == 1 then
            return origin + stepsize
        else
            return origin - stepsize
        end
    end
    function this.combine(a, b)
        return math.floor(math.abs(a-b+0.5)/2)
    end
    return this
end

function float(min, max, deviation)
    min = min or 0
    max = max or 1
    deviation = deviation or max - min
    local scale = max - min
    local this = {}
    function this.start()
        return scale*RNG()
    end
    function this.step(origin)
        local stepup = scale*deviation*RNG()
        local stepdown = scale*deviation*RNG()
        local result = origin + stepup - stepdown
        result = result > max and max or result
        result = result < min and min or result
        return result
    end
    function this.combine(a, b)
        return math.abs(a-b)/2
    end
    return this
end

function just(value)
    local this = {}
    function this.start()
        return value
    end
    function this.step(origin)
        return value
    end
    function this.combine(a, b)
        return value
    end
    return this
end
