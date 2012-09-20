-- test application for this under ../tests/evolution.lua
-- usage ---------------------------------------------------------------------------------
-- allows to optimize for a constraints.environment using an evolutionary algorithm     --
-- EXPORTS: individual, population                                                      --
------------------------------------------------------------------------------------------

math.randomseed(os.time() * os.time() * math.random() - os.time()) -- this sucks
math.random()

local RNG = RNG or math.random
local pairs = pairs
local oo = require "oo"
module(...)
local defaultmutationrate = 0.1
local defaultmeetrate     = 1.0
local defaultbirthrate    = 0.5

individual = oo.object:intend{

	domains = {},
	traits = oo.dynamic{},
	
	rate = (function (self, name)
		return self.traits["_"..name] or self.traits["_"] or defaultmutationrate
	end),
	
	new = oo.public (function (this, domains, traits)
		domains = domains or {}
		traits = traits or {}
		for name,domain in pairs(domains) do
			traits[name] = traits[name] or domain:start()
		end
		return this:intend{
			domains = domains,
			traits = oo.dynamic(traits)
		}
	end),
	
	gettraits = oo.public (oo.getter("traits")),
	
	mutate = oo.public (function (this)
		for name,trait in pairs(this.traits) do
			if RNG() < this:rate(name) then
				this.traits[name] = this.domains[name]:step(trait)
			end
		end
		return this
	end),
	
	recombine = oo.public (function (this, other)
		local offspringtraits = {}
		for name,domain in pairs(this.domains) do
			offspringtraits[name] = domain:combine(this.traits[name], other:gettraits()[name])
		end
		return individual:new(this.domains, offspringtraits)
	end)

}

population = oo.object:intend{

	elite = oo.dynamic(nil),
	count = 0,
	domains = oo.dynamic{},
	individuals = oo.dynamic{},
	environment = oo.dynamic(nil),
	
	attemptusurpation = (function (this, candidate)
		if candidate == nil then
			return false
		end
		if (this.elite == nil) or this:compare(this.elite, candidate) then
			this.elite = candidate:clone()
			this.environment:update(this.elite:gettraits())
			return true
		end
		return false
	end),
	
	integrate = (function (this, individual)
 		this.individuals[individual] = this:rank(individual)
		this.count = this.count + 1
 		this:attemptusurpation(individual)
 	end),
	
	kill = (function (this, individual)
		this.individuals[individual] = nil
		this.count = this.count - 1
	end),
	
	pick = (function (this)
		local index = RNG(1, this.count)
		local i = 1
		for individual,_ in pairs(this.individuals) do
			if i == index then
				return individual
			else
				i = i + 1
			end
		end
		error("unexpected error while picking an individual")
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
	
	seed = oo.public (function (this, n)
		if n <= 0 then return nil end
		n = n or 1
		local adam = individual:new(this.domains)
		this:integrate(adam)
		if n == 1 then
			return adam
		end
		return adam, this:seed(n-1)
	end),
	
	grow = oo.public (function (this, n)
		if n <= 0 then return nil end
		n = n or 1
		local child = this:pick():recombine(this:pick())
		this:integrate(child)
		if n == 1 then
			return child
		end
		return child, this:grow(n-1)
	end),
	
	rank = oo.public (function (this, individual)
		return this.individuals[individual] or this.environment:try(individual:gettraits())
	end),
	
	best = oo.public (oo.getter("elite")),
	
	compare = oo.public (function (this, a, b)
		return this.environment:compare(this:rank(a), this:rank(b))
	end),
	
	age = oo.public (function (this, n, meetrate, birthrate)
		if n <= 0 then return this end
		n = n or 1
		for individual,_ in pairs(this.individuals) do
			individual:mutate()
			this:attemptusurpation(individual)
		end
		this:survive(meetrate, birthrate)
		if n == 1 then
			return this
		end
		return this:age(n-1, meetrate, birthrate)
	end),
	
	survive = oo.public (function (this, meetrate, birthrate)
		meetrate = meetrate or defaultmeetrate
		birthrate = birthrate or defaultbirthrate
		local individuals = {}
		for individual,ranks in pairs(this.individuals) do
			if not (individual == this.elite) then --elite always survives
				individuals[#individuals+1] = individual
			end
		end
		local deaths = 0
		for i,individual in pairs(individuals) do
			if RNG() < meetrate then
				local mate = individuals[RNG(1, #individuals)]
				if this:compare(individual, mate) then
					this:kill(individual)
					if RNG() < birthrate then
						local child = individual:recombine(mate)
						this:integrate(child)
					else
						deaths = deaths + 1
					end
				end
			end
		end
		this:seed(deaths)
		return this
	end),

}