-- test application for this under ../tests/sa.lua
-- usage ---------------------------------------------------------------------------------
-- allows to optimize for a constraints.environment using simulated annealing           --
-- EXPORTS: process                                                                     --
------------------------------------------------------------------------------------------

math.randomseed(os.time() * os.time() * math.random() - os.time()) -- this sucks again
math.random()

local RNG = RNG or math.random
local pairs = pairs
local math = math
local oo = require "oo"
local tt = require "typetools"
module(...)
local defaulttemperature = function (t) return 1/t end

process = oo.object:intend{

    states      = oo.dynamic{},
	elite       = oo.dynamic(nil),
   	domains     = oo.dynamic{},
	energy      = "_",
	time        = 0,
	temperature = defaulttemperature,
    environment = oo.dynamic(nil),
    
	rank = oo.public (function (this, state)
		return this.environment:try(state)
	end),
    
	compare = oo.public (function (this, a, b)
		return this.environment:compare(this:rank(a), this:rank(b))
	end),
    
    new = oo.public (function (this, environment, domains)
		domains = domains or {}
		for var,default in pairs(environment:getvars()) do
            domains[var] = domains[var] or default
		end
		return this:intend{
			domains = oo.dynamic(domains),
			environment = oo.dynamic(environment)
		}
	end),
    
	best = oo.public (oo.getter("elite")),
    
    start = oo.public (function (self, energy, temperature)
		self.energy = energy or self.energy
		self.temperature = temperature or self.temperature
        for var,domain in pairs(self.domains) do
            self.states[var] = domain:start()
        end
        self.elite = tt.deepcopy(self.states)
		self.environment:update(self.elite)
    end),
    
    next = (function (self)
        local newstates = {}
        for var,state in pairs(self.states) do
            newstates[var] = self.domains[var]:step(state)
        end
        return newstates
    end),

    attemptusurpation = (function (self, candidate)
        if self:compare(self.elite, candidate) then
            self.elite = tt.deepcopy(candidate)
			self.environment:update(self.elite)
        end
    end),
    
    anneal = oo.public (function (self, n, t)
        n = n or 1
		if n <= 0 then return self end
		self.time = self.time + 1
		t = t or self.temperature(self.time)
        local energy = self:rank(self.states)[self.energy]
        local new = self:next()
        local newenergy = self:rank(new)[self.energy]
        if self:compare(self.states, new) then
            self.states = new
        elseif RNG() < math.exp((energy - newenergy)/t) then
            self.states = new
        end
        self:attemptusurpation(self.states)
        return n == 1 and self or self:anneal(n-1, t)
    end),
	
	annealto = oo.public (function (self, t)
		return self:anneal(1, t)
	end)
     
}