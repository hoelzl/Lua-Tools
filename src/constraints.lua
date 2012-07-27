-- test application for this under ../tests/evolution.lua
-- usage ---------------------------------------------------------------------------------
-- describes a number of constraints with an ordering                                   --
-- EXPORTS: environment                                                                 --
------------------------------------------------------------------------------------------

local oo = require "oo"
local pairs = pairs
local _G = _G
module(...)

environment = oo.object:intend{

	order = (function (a, b)
		return false
	end),
	constraints = {},
	vars = oo.dynamic{},
	
	new = oo.public (oo.instantiate("order", "constraints")),
	
	getvars = oo.public (function (this)
		return this.vars
	end),
	
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
		--apply given data
		local vals = {}
		for varname,default in pairs(setting or {}) do
			vals[varname] = _G[varname]
			_G[varname] = setting[varname] or default
		end
		--evaluate constraints
		local ranks = {}
		for name,constraint in pairs(this.constraints) do
			ranks[name] = constraint()
		end
		--restore global state
		for varname,value in pairs(vals) do
			_G[varname] = value
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
	
	max = oo.public (function (...)
		local i = this.test(arg)
		return arg[i]
	end)

}
