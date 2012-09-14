-- test application for this under ../tests/evolution.lua
-- usage ---------------------------------------------------------------------------------
-- provides domains for evolution to work with                                          --
-- EXPORTS: natural, float, just                                                        --
------------------------------------------------------------------------------------------

local RNG = RNG or math.random
local unpack = unpack
local math = math
local oo = require "oo"
module(...)

local justdomain = oo.object:intend{
    value = nil,
    new = oo.public (oo.instantiate("value")),
    start = oo.public (function (self)
        return self.value
    end),
    step = oo.public (function (self)
        return self.value
    end),
    combine = oo.public (function (self)
        return self.value
    end)
}

function just(...)
    return justdomain:new(unpack(arg))
end

local naturaldomain = oo.object:intend{
    min = 0,
    max = 1,
    stepsize = 1,
    new = oo.public (oo.instantiate("min", "max", "stepsize")),
    start = oo.public (function (self)
        return RNG(self.min, self.max)
    end),
    step = oo.public (function (self, origin)
        if origin == min then return self.min + stepsize end
        if origin == max then return self.max - stepsize end
        if RNG(0, 1) == 1 then
            return origin + self.stepsize
        else
            return origin - self.stepsize
        end
    end),
    combine = oo.public (function (self, a, b)
        return math.floor(math.abs(a-b+0.5)/2)
    end),
}

function natural(...)
    return naturaldomain:new(unpack(arg))
end

local floatdomain = oo.object:intend{
    min = 0,
    max = 1,
    deviation = 1,
    scale = 1,
    new = oo.public (function (self, min, max, deviation)
        min = min or self.min
        max = max or self.max
        return self:intend{
            min = min,
            max = max,
            deviation = deviation or max - min,
            scale = max - min
        }
    end),
    start = oo.public (function (self)
        return self.scale * RNG()
    end),
    step = oo.public (function (self, origin)
        local stepup   = self.scale * self.deviation * RNG()
        local stepdown = self.scale * self.deviation * RNG()
        local result   = origin + stepup - stepdown
        result = result > self.max and self.max or result
        result = result < self.min and self.min or result
        return result
    end),
    combine = oo.public (function (self, a, b)
        return math.abs(a-b)/2
    end)
}

function float(...)
    return floatdomain:new(unpack(arg))
end

--[[-- experimental incomplete code
local placementdomain = oo.object:intend{
    fields = 1,
    min = 0,
    max = 1,
    mark = true,
    empty = false,
    new = oo.public (oo.instantiate("fields", "min", "max", "mark", "empty")),
    start = oo.public (function (self)
        local placement = {}
        for i=1,self.fields do
            placement[i] = self.empty
        end
        local markers = RNG(self.min, self.max)
        local placed = 0
        while placed < markers do
            local pos = RNG(1, self.fields)
            if not (placement[pos] == self.mark)
                placement[pos] = self.mark
                placed = placed + 1
            end
        end
        return placement
    end),
    step = oo.public (function (self, origin)
    
    end)
}
--]]