do
	local traversed
	local function _reccopy(t, newtable, blacklist)
		newtable = newtable or {}
		for k, v in pairs(t) do
			if traversed[v] then
				newtable[k] = traversed[v]
			elseif not blacklist[k] then
				if typeOf(v) == "table" then
					local t2 = {}
					newtable[k] = t2
					traversed[v] = t2
					_reccopy(v, t2, blacklist)
					local mt = getmetatable(v)
					if mt then
						local t3 = {}
						traversed[mt] = t3
						setmetatable(t2, _reccopy(mt, t3, blacklist))
					end
				else
					newtable[k] = v
				end
			end
		end
		return newtable
	end

	reccopy = function(t, blacklist)
		local t2 = {}
		traversed = {[t]=t2}
		return _reccopy(t, t2, blacklist or {})
	end
end