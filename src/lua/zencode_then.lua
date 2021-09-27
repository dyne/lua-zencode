--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2021 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--Last modified by Denis Roio
--on Tuesday, 28th September 2021
--]]

--- THEN combinations:
-- the
-- the from
-- the as
-- the in
-- my
-- my from
-- my as
-- the from as
-- the from in
-- the as in
-- the from as in
-- my from as
----------------------

local function then_outcast(val, sch)
	if not val then
		error("Then outcast called on empty variable", 2)
	end
	local fun = guess_outcast(sch)
	if luatype(val) == 'table' then
		return deepmap(fun, val)
	else
		return fun(val)
	end
end

local function then_insert(dest, val, key)
	if not ACK[dest] then
		ZEN.OUT[dest] = val
	elseif luatype(ZEN.OUT[dest]) == 'table' then
		if isarray(ZEN.OUT[dest]) then
			table.insert(ZEN.OUT[dest], val)
		else
			assert(key, 'Then statement targets dictionary with empty key: '..dest)
			ZEN.OUT[dest][key] = val
		end
	else -- extend string to array
		local tmp = ZEN.OUT[dest]
		ZEN.OUT[dest] = { tmp }
		table.insert(ZEN.OUT[dest], val)
	end
end

Then("nothing", function() return end) -- nop to terminate if

Then("print string ''", function(k)
	if not ZEN.OUT.output then
		ZEN.OUT.output = {}
	end
	table.insert(ZEN.OUT.output, k) -- raw string value
end)

Then("print ''", function(name)
	local val = have(name)
	ZEN.OUT[name] = then_outcast( val, check_codec(name) )
end)

Then(
	"print '' as ''",
	function(k, s)
		local val = have(k)
		ZEN.OUT[k] = then_outcast( val, s )
	end
)

Then(
	"print '' from ''",
	function(k, f)
		local val = have({f,k}) -- use array to check in depth
		ZEN.OUT[k] = then_outcast( val, check_codec(f) )
	end
)

Then(
	"print '' from '' as ''",
	function(k, f, s)
		local val = have({f,k}) -- use array to check in depth
		ZEN.OUT[k] = then_outcast( val, s )
	end
)

Then(
	"print '' from '' as '' in ''",
	function(k, f, s, d)
		local val = have({f,k}) -- use array to check in depth
		then_insert( d, then_outcast( val, s ), k)
	end
)

Then(
	"print '' as '' in ''",
	function(k, s, d)
		local val = have(k) -- use array to check in depth
		then_insert( d, then_outcast( val, s ), k)
	end
)

Then(
	"print my '' from '' as ''",
	function(k, f, s)
		local val = have({f,k}) -- use array to check in depth
		then_insert( WHO, then_outcast( val, s ), k)
	end
)

Then(
	"print my '' from ''",
	function(k, f)
		local val = have({f,k}) -- use array to check in depth
		-- my statements always print to a dictionary named after WHO
		if not ZEN.OUT[WHO] then ZEN.OUT[WHO] = { } end
		ZEN.OUT[WHO][k] = then_outcast( val, check_codec(f) )
	end
)

Then(
	"print my '' as ''",
	function(k, s)
		local val = have(k) -- use array to check in depth
		then_insert( WHO, then_outcast( val, s ), k)
	end
)

Then(
	"print my ''",
	function(k)
		local val = have(k)
		-- my statements always print to a dictionary named after WHO
		if not ZEN.OUT[WHO] then ZEN.OUT[WHO] = { } end
		ZEN.OUT[WHO][k] = then_outcast( val, check_codec(k) )
	end
)

Then(
	'print data',
	function()
		local fun
		for k, v in pairs(ACK) do
			fun = guess_outcast(check_codec(k))
			if luatype(v) == 'table' then
				ZEN.OUT[k] = deepmap(fun, v)
			else
				ZEN.OUT[k] = fun(v)
			end
		end
	end
)

Then(
	"print data as ''",
	function(e)
		local fun
		for k, v in pairs(ACK) do
			fun = guess_outcast(e)
			if luatype(v) == 'table' then
				ZEN.OUT[k] = deepmap(fun, v)
			else
				ZEN.OUT[k] = fun(v)
			end
		end
	end
)

Then(
	'print my data',
	function()
		Iam() -- sanity checks
		local fun
		ZEN.OUT[WHO] = {}
		for k, v in pairs(ACK) do
			fun = guess_outcast(check_codec(k))
			if luatype(v) == 'table' then
				ZEN.OUT[WHO][k] = deepmap(fun, v)
			else
				ZEN.OUT[WHO][k] = fun(v)
			end
		end
	end
)

Then(
	"print my data as ''",
	function(s)
		Iam() -- sanity checks
		local fun
		ZEN.OUT[WHO] = {}
		for k, v in pairs(ACK) do
			fun = guess_outcast(s)
			if luatype(v) == 'table' then
				ZEN.OUT[WHO][k] = deepmap(fun, v)
			else
				ZEN.OUT[WHO][k] = fun(v)
			end
		end
	end
)
