
function newConstraintEnvironment(order, constraints)
	local function alwaysfirst(a, b)
		return false
	end
	local this = {
		order = order,
		constraints = constraints or {},
		vars = {}
	}
	function this.setOrder(new)
		this.order = new
	end
	function this.constrain(name, constraint)
		this.constraints[name] = constraint
	end
	function this.register(varname, default)
		this.vars[varname] = default
	end
	function this.try(setting)
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
	end
	function this.test(settings)
		local results = {}
		for i,setting in pairs(settings) do
			results[i] = this.try(setting)
		end
		local best
		for i,result in pairs(results) do
			if result then
				best = best or i
				if (this.order or alwaysfirst)(results[best], result) then
					best = i
				end
			end
		end
		return best, results[best]
	end
	function this.max(...)
		local i = this.test(arg)
		return arg[i]
	end
	return this
end
