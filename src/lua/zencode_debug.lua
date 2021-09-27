--[[
--This file is part of zenroom
--
--Copyright (C) 2021 Dyne.org foundation
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

_inspect = require'inspect'
local I = { warn = function(t) print(_inspect(t)) end }

-- limit output of string if too long
function limit(anystr)
   local t = luatype(anystr)
   ZEN.assert(t=='string',"Argument to limit on-screen not a string")
   if #anystr > 32 then
	  return(string.sub(anystr,1,32).."..")
   end
   return(anystr)
end

-- debug functions
function debug_traceback()
   for k,v in pairs(ZEN.traceback) do
	  warn(v)
   end
end
Given("backtrace", function() debug_traceback() end)
When("backtrace", function() debug_traceback() end)
Then("backtrace", function() debug_traceback() end)
Given("trace", function() debug_traceback() end)
When("trace", function() debug_traceback() end)
Then("trace", function() debug_traceback() end)

function debug_heap_dump()
   local HEAP = ZEN.heap()
   I.warn({a_GIVEN_in = HEAP.IN,
		   b_WHEN_ack = HEAP.ACK,
		   c_THEN_out = HEAP.OUT})
end

function debug_heap_schema()
   I.schema({SCHEMA = ZEN.heap()})
   -- print only keys without values
end

-- local function debug_obj_dump()
-- local function debug_obj_schema()

Given("debug", function() ZEN.debug() end)
When("debug",  function() ZEN.debug() end)
Then("debug",  function() ZEN.debug() end)

Given("schema", function() debug_heap_schema() end)
When("schema",  function() debug_heap_schema() end)
Then("schema",  function() debug_heap_schema() end)

function debug_codec()
   I.warn({CODEC = ZEN.CODEC})
end

Given("codec", function() debug_codec() end)
When("codec", function() debug_codec() end)
Then("codec", function() debug_codec() end)

Given("config", function() I.warn(_G["CONF"]) end)
When("config", function() I.warn(_G["CONF"]) end)
Then("config", function() I.warn(_G["CONF"]) end)