-- test application for this under ../tests/evolution.lua
-- usage ---------------------------------------------------------------------------------
-- describes a number of constraints with an ordering                                   --
-- EXPORTS: environment                                                                 --
------------------------------------------------------------------------------------------

local function updateglobal(var, val)
	_G[var] = val
end

local pairs = pairs
local oo = require "oo"
local nd = require "nd"
module(...)

environment = oo.object:intend{

	order       = (function (a, b) return false end),
	constraints = oo.dynamic{},
	vars        = oo.dynamic{},
	solution    = oo.dynamic{},
	living      = false,
	
	new = oo.public (oo.instantiate("order", "constraints")),
	
	getvars = oo.public (oo.getter("vars")),
	
	compare = oo.public (function (this, a, b)
		return (this.order)(a, b)
	end),
	
	constrain = oo.public (function (this, name, constraint)
		this.constraints[name] = constraint
	end),
	
	register = oo.public (function (this, varname, default)
		this.vars[varname] = default or true
	end),
	
	try = oo.public (function (this, setting)
		local ranks = {}
		for name,constraint in pairs(this.constraints) do
			ranks[name] = nd.whatif(constraint, setting, false)
		end
		return ranks
	end),
	
	test = oo.public (function (this, settings)
		local results = {}
		for i,setting in pairs(settings) do
			results[i] = this:try(setting)
		end
		local best
		for i,result in pairs(results) do
			if result then
				best = best or i
				if this:compare(results[best], result) then
					best = i
				end
			end
		end
		return best, results[best]
	end),
	
	max = oo.public (function (this, ...)
		local i = this.test(arg)
		return arg[i]
	end),
	
	current = oo.public (function()
		return this.solution
	end),
	
	updateglobals = (function (this, values)
		values = values or this.solution
		if this.living then
			for name,value in pairs(values) do
				if this.vars[name] then
					updateglobal(name, value)
				end
			end
		end
	end),
	
	live = oo.public (function (this, living)
		this.living = living or true
		this:updateglobals()
	end),
	
	update = oo.public (function (this, values)
		this.solution = values or this.solution
		this:updateglobals(values)
	end)

}
