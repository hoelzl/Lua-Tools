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
		traits = traits or {},
		mutationrate = 0.1
	}
	for name,domain in pairs(this.domains) do
		this.traits[name] = this.traits[name] or domain.start()
	end
	function this.mutate()
		for name,trait in pairs(this.traits) do
			if RNG() < this.mutationrate then
				this.traits[name] = this.domains[name].step(trait)
			end
		end
		return this
	end
	function this.clone()
		return newIndividual(domains, deepcopy(this.traits))
	end
	return this
end

function newPopulation(environment, domains)
	local this = {
		individuals = {},
		environment = environment,
		elite = nil
 	}
 	domains = domains or {}
 	for var,default in pairs(environment.vars) do
 		domains[var] = domains[var] or default
 	end
 	local function attemptusurpation(candidate)
		if candidate == nil then
			return false
		end
		if this.elite == nil then
			this.elite = candidate.clone()
			return true
		end
		if this.compare(this.elite, candidate) then
			this.elite = candidate.clone()
			return true
		end
		return false
	end
	function this.seed(n)
		n = n or 1
		local adam = newIndividual(domains)
		this.individuals[adam] = this.environment.try(adam.traits)
		attemptusurpation(adam)
		if n == 1 then
			return adam
		end
		return adam, this.seed(n-1)
	end
	function this.best()
		return this.elite
	end
	function this.compare(a, b)
		local arank = this.individuals[a] or this.environment.try(a.traits)
		local brank = this.individuals[b] or this.environment.try(b.traits)
		return this.environment.order(arank, brank)
	end
	function this.age(n)
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
			if not (individual == this.elite) then --elite always survives
				individuals[#individuals+1] = individual
			end
		end
		local deaths = 0
		for i,individual in pairs(individuals) do
			local mate = individuals[RNG(1, #individuals)]
			if this.compare(individual, mate) then
				this.individuals[individual] = nil
				deaths = deaths + 1
			end
		end
		this.seed(deaths)
		return this
	end
	return this
end

