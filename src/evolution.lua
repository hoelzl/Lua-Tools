require "constraints"
require "domains"

math.randomseed(os.time() * os.time() * math.random() - os.time()) -- this sucks
math.random()
RNG = math.random

local function deepcopy(thing)
	if type(thing) == "table" then
		local copy = {}
		for key,val in pairs(thing) do
			copy[deepcopy(key)] = deepcopy(val)
		end
		return copy
	else
		return thing
	end
end

function newIndividual(domains, traits)
	local this = {
		domains = domains or {},
		traits = traits or {}
	}
	for name,domain in pairs(this.domains) do
		this.traits[name] = this.traits[name] or domain.start()
	end
	local function rate(name)
		return this.traits["_"..name] or this.traits["__"] or 0.1 
	end
	function this.mutate()
		for name,trait in pairs(this.traits) do
			if RNG() < rate(name) then
				this.traits[name] = this.domains[name].step(trait)
			end
		end
		return this
	end
	function this.clone()
		return newIndividual(domains, deepcopy(this.traits))
	end
	function this.recombine(other)
		local offspringtraits = {}
		for name,domain in pairs(this.domains) do
			offspringtraits[name] = domain.combine(this.traits[name], other.traits[name])
		end
		return newIndividual(this.domains, offspringtraits)
	end
	return this
end

function newPopulation(environment, domains)
 	local elite
	local this = {
		individuals = {},
		environment = environment
 	}
 	domains = domains or {}
 	for var,default in pairs(environment.vars) do
 		domains[var] = domains[var] or default
 	end
 	local function attemptusurpation(candidate)
		if candidate == nil then
			return false
		end
		if elite == nil then
			elite = candidate.clone()
			return true
		end
		if this.compare(elite, candidate) then
			elite = candidate.clone()
			return true
		end
		return false
	end
 	local function integrate(individual)
 		this.individuals[individual] = this.environment.try(individual.traits)
 		attemptusurpation(individual)
 	end
	function this.seed(n)
		if n <= 0 then return nil end
		n = n or 1
		local adam = newIndividual(domains)
		integrate(adam)
		if n == 1 then
			return adam
		end
		return adam, this.seed(n-1)
	end
	function this.best()
		return elite
	end
	function this.compare(a, b)
		local arank = this.individuals[a] or this.environment.try(a.traits)
		local brank = this.individuals[b] or this.environment.try(b.traits)
		return this.environment.order(arank, brank)
	end
	function this.age(n)
		if n <= 0 then return this end
		n = n or 1
		for individual,_ in pairs(this.individuals) do
			individual.mutate()
			attemptusurpation(individual)
		end
		this.survive()
		if n == 1 then
			return this
		end
		return this.age(n-1)
	end
	function this.survive()
		local individuals = {}
		for individual,ranks in pairs(this.individuals) do
			if not (individual == elite) then --elite always survives
				individuals[#individuals+1] = individual
			end
		end
		local deaths = 0
		for i,individual in pairs(individuals) do
			local mate = individuals[RNG(1, #individuals)]
			if this.compare(individual, mate) then
				this.individuals[individual] = nil
				if 0.5 < RNG() then
					local child = individual.recombine(mate)
					integrate(child)
				else
					deaths = deaths + 1
				end
			end
		end
		this.seed(deaths)
		return this
	end
	return this
end

