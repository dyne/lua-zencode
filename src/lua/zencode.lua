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
--on Friday, 1st October 2021
--]]
--- <h1>Zencode language parser</h1>
--
-- <a href="https://dev.zenroom.org/zencode/">Zencode</a> is a Domain
-- Specific Language (DSL) made to be understood by humans. Its
-- purpose is detailed in <a
-- href="https://files.dyne.org/zenroom/Zencode_Whitepaper.pdf">the
-- Zencode Whitepaper</a> and DECODE EU project.
--
-- @module ZEN
--
-- @author Denis "Jaromil" Roio
-- @license AGPLv3
-- @copyright Dyne.org foundation 2018-2020
--
-- The Zenroom VM is capable of parsing specific scenarios written in
-- Zencode and execute high-level cryptographic operations described
-- in them; this is to facilitate the integration of complex
-- operations in software and the non-literate understanding of what a
-- distributed application does.
--
-- This section doesn't provide the documentation on how to write
-- Zencode. Refer to the links above to learn it. This documentation
-- continues to illustrate internals: how the Zencode direct-syntax
-- parser is made, how it integrates in the Zenroom memory model.

-- This is also the reference implementation to learn how to code
-- Zencode simple scenario using Zeroom's Lua.
--
-- @module ZEN


-- set_sentence
-- set_rule

local function set_sentence(self, event, from, to, ctx)
	local index = self.current
	if self.current == 'whenif' then index = 'when' end
	if self.current == 'thenif' then index = 'then' end
	local reg = ctx.Z[index .. '_steps']
	ctx.Z.OK = false
	xxx('Zencode parser from: ' .. from .. " to: "..to, 3)
	assert(reg,'Callback register not found: ' .. self.current)
	assert(#reg,'Callback register empty: '..self.current)
	local gsub = string.gsub -- optimization
	-- TODO: optimize in C
	-- remove '' contents, lower everything, expunge prefixes
	-- ignore 'the' only in Then statements
	local tt = gsub(trim(ctx.msg), "'(.-)'", "''")
	tt = gsub(tt, ' I ', ' ', 1) -- eliminate first person pronoun
	tt = tt:lower() -- lowercase all statement
	if to == 'then' then
		tt = gsub(tt, ' the ', ' ', 1)
	end
	if to == 'given' then
	   tt = gsub(tt, ' the ', ' a ', 1)
	   tt = gsub(tt, ' have ', ' ', 1)
	end
	-- prefixes found at beginning of statement
	tt = gsub(tt, '^when ', '', 1)
	tt = gsub(tt, '^then ', '', 1)
	tt = gsub(tt, '^given ', '', 1)
	tt = gsub(tt, '^if ', '', 1)
	tt = gsub(tt, '^and ', '', 1) -- TODO: expunge only first 'and'
	-- generic particles
	tt = gsub(tt, '^that ', ' ', 1)
	tt = gsub(tt, ' valid ', ' ', 1) -- backward compat
	tt = gsub(tt, ' known as ', ' ', 1)
	tt = gsub(tt, ' all ', ' ', 1)
	tt = gsub(tt, ' inside ', ' in ', 1) -- equivalence
	tt = gsub(tt, '^an ', 'a ', 1)
	tt = gsub(tt, ' +', ' ') -- eliminate multiple internal spaces
	-- TODO: OPTIMIZE here to avoid iteration over all zencode language every time
	for pattern, func in pairs(reg) do
		if (type(func) ~= 'function') then
			error('Zencode function missing: ' .. pattern, 2)
			return false
		end
	    -- xxx(tt .. ' == ' ..pattern)
		if strcasecmp(tt, pattern) then
			xxx(tt)
			local args = {} -- handle multiple arguments in same string
			for arg in string.gmatch(ctx.msg, "'(.-)'") do
				-- convert all spaces to underscore in argument strings
				arg = uscore(arg, ' ', '_')
				table.insert(args, arg)
			end
			ctx.Z.id = ctx.Z.id + 1
			-- AST data prototype
			table.insert(
				ctx.Z.AST,
				{
					id = ctx.Z.id, -- ordered number
					args = args, -- array of vars
					source = ctx.msg, -- source text
					section = self.current,
					from = from,
					to = to,
					hook = func
				}
			) -- function
			ctx.Z.OK = true
			break
		end
	end
	if not ctx.Z.OK and ctx.Z.CONF.parser.strict_match then
		debug_traceback()
		ZEN.exitcode=1
		error('Zencode pattern not found (missing scenario?): ' .. trim(ctx.msg), 1)
		return false
	-- elseif not ctx.Z.OK and not CONF.parser.strict_match then
	-- 	warning('Zencode pattern ignored: ' .. trim(ctx.msg), 1)
	end
end

local function set_rule(text, zz)
	local res = false
	local tr = text.msg:gsub(' +', ' ') -- eliminate multiple internal spaces
	local rule = strtok(trim(tr):lower())
	if rule[2] == 'check' and rule[3] == 'version' and rule[4] then
		-- TODO: check version of running VM
		-- elseif rule[2] == 'load' and rule[3] then
		--     act("zencode extension: "..rule[3])
		--     require("zencode_"..rule[3])
		zz.version = zz.semver(ZENROOM_VERSION)
		local ver = SEMVER(rule[4])
		if ver == VERSION then
			-- act('Zencode version match: ' .. ZENROOM_VERSION.original)
			res = true
		elseif ver < VERSION then
			-- warning('Zencode written for an older version: ' .. ver.original)
			res = true
		elseif ver > VERSION then
			-- warning('Zencode written for a newer version: ' .. ver.original)
			res = true
		else
			error('Version check error: ' .. rule[4])
		end
		text.Z.checks.version = res
	elseif rule[2] == 'input' and rule[3] then
		-- rule input encoding|format ''
		if rule[3] == 'encoding' and rule[4] then
			zz.CONF.input.encoding = input_encoding(rule[4])
			res = true and zz.CONF.input.encoding
		elseif rule[3] == 'untagged' then
			res = true
			zz.CONF.input.tagged = false
		end
	elseif rule[2] == 'output' and rule[3] then
		-- TODO: rule debug [ format | encoding ]
		-- rule input encoding|format ''
		if rule[3] == 'encoding' then
			zz.CONF.output.encoding = output_encoding(rule[4])
			res = true and zz.CONF.output.encoding
		elseif rule[3] == 'versioning' then
			zz.CONF.output.versioning = true
			res = true
		elseif strcasecmp(rule[3], 'ast') then
			zz.CONF.output.AST = true
			res = true
		end
	elseif rule[2] == 'unknown' and rule[3] then
		if rule[3] == 'ignore' then
			zz.CONF.parser.strict_match = false
			res = true
		end
		-- alias of unknown ignore for specific callers
	elseif rule[2] == 'caller' and rule[3] then
		if rule[3] == 'restroom-mw' then
			zz.CONF.parser.strict_match = false
			res = true
		end
	elseif rule[2] == 'set' and rule[4] then
		zz.CONF[rule[3]] = fif( tonumber(rule[4]), tonumber(rule[4]),
							fif( rule[4]=='true', true,
							fif( rule[4]=='false', false,
							rule[4])))
		res = true
	end
	if not res then
		error('Rule invalid: ' .. text.msg, 3)
	else
--		act(text.msg)
	end
	return res
end


local function new_state_machine(zz)
	-- stateDiagram
    -- [*] --> Given
    -- Given --> When
    -- When --> Then
    -- state branch {
    --     IF 
    --     when then
    --     --
    --     EndIF
    -- }
    -- When --> branch
    -- branch --> When
    -- Then --> [*]
	local machine =
		zz.machine.create(
		{
			initial = 'init',
			events = {
				{name = 'enter_rule', from = {'init', 'rule', 'scenario'}, to = 'rule'},
				{name = 'enter_scenario', from = {'init', 'rule', 'scenario'}, to = 'scenario'},
				{name = 'enter_given', from = {'init', 'rule', 'scenario'},	to = 'given'},
				{name = 'enter_given', from = {'given'}, to = 'given'},

				{name = 'enter_when', from = {'given', 'when', 'then', 'endif'}, to = 'when'},
				{name = 'enter_then', from = {'given', 'when', 'then', 'endif'}, to = 'then'},

				{name = 'enter_if', from = {'if', 'given', 'when', 'then', 'endif'}, to = 'if'},
				{name = 'enter_whenif', from = {'if', 'whenif', 'thenif'}, to = 'whenif'},
				{name = 'enter_thenif', from = {'if', 'whenif', 'thenif'}, to = 'thenif'},
				{name = 'enter_endif', from = {'whenif', 'thenif'}, to = 'endif'},

				{name = 'enter_and', from = 'given', to = 'given'},
				{name = 'enter_and', from = 'when', to = 'when'},
				{name = 'enter_and', from = 'then', to = 'then'},
				{name = 'enter_and', from = 'whenif', to = 'whenif'},
				{name = 'enter_and', from = 'thenif', to = 'thenif'},	
				{name = 'enter_and', from = 'if', to = 'if'}

			},
			-- graph TD
			--     Given --> When
			--     IF --> When
			--     Then --> When
			--     Given --> IF
			--     When --> IF
			--     Then --> IF
			--     IF --> Then
			--     When --> Then
			--     Given --> Then
			callbacks = {
				-- msg is a table: { msg = "string", Z = ZEN (self) }
				onscenario = function(self, event, from, to, msg)
					-- first word until the colon
					local scenarios =
						strtok(string.match(trim(msg.msg):lower(), '[^:]+'))
					for k, scen in ipairs(scenarios) do
						if k ~= 1 then -- skip first (prefix)
							local _require = require
							require = function (modname) _require('zencode.'..modname) end							
							require('zencode_' .. trimq(scen))
							require = _require
							ZEN:trace('Scenario ' .. scen)
							return
						end
					end
				end,
				onrule = function(self, event, from, to, msg)
					-- process rules immediately
					if msg then	set_rule(msg) end
				end,
				ongiven = set_sentence,
				onwhen = set_sentence,
				onif = set_sentence,
				onendif = set_sentence,
				onthen = set_sentence,
				onand = set_sentence,
				onwhenif = set_sentence,
				onthenif = set_sentence
			}
		}
	)
	return machine
end

local zencode = { }

-- -- Zencode HEAP globals
-- zencode.IN = {} -- Given processing, import global DATA from json
-- zencode.IN.KEYS = {} -- Given processing, import global KEYS from json
-- zencode.TMP = TMP or {} -- Given processing, temp buffer for ack*->validate->push*
-- zencode.ACK = ACK or {} -- When processing,  destination for push*
-- zencode.OUT = OUT or {} -- print out
-- zencode.AST = AST or {} -- AST of parsed Zencode
-- zencode.WHO = nil

-- init statements
zencode.given_steps = { }
zencode.when_steps = { }
zencode.if_steps = { }
zencode.endif_steps = { endif = function() return end } --nop
zencode.then_steps = { }
zencode.schemas = { }

function zencode.Given(text, fn)
	assert(
		not zencode.given_steps[text],
		'Conflicting GIVEN statement loaded by scenario: ' .. text, 2
	)
	zencode.given_steps[text] = fn
end
function zencode.When(text, fn)
	assert(
		not zencode.when_steps[text],
		'Conflicting WHEN statement loaded by scenario: ' .. text, 2
	)
	zencode.when_steps[text] = fn
end
function zencode.IfWhen(text, fn)
	assert(
		not zencode.if_steps[text],
		'Conflicting IF-WHEN statement loaded by scenario: ' .. text, 2
	)
	assert(
		not zencode.when_steps[text],
		'Conflicting IF-WHEN statement loaded by scenario: ' .. text, 2
	)
	zencode.if_steps[text]   = fn
	zencode.when_steps[text] = fn
end
function zencode.Then(text, fn)
	assert(
		not zencode.then_steps[text],
		'Conflicting THEN statement loaded by scenario : ' .. text, 2
	)
	zencode.then_steps[text] = fn
end

---
-- Declare 'my own' name that will refer all uses of the 'my' pronoun
-- to structures contained under this name.
--
-- @function Iam(name)
-- @param name own name to be saved in WHO
function zencode.Iam(name)
	if name then
		ZEN.assert(not WHO, 'Identity already defined in WHO')
		ZEN.assert(type(name) == 'string', 'Own name not a string')
		Z.WHO = name
	else
		Z.assert(WHO, 'No identity specified in WHO')
	end
end

-- init schemas
function zencode.add_schema(arr)
	local _illegal_schemas = {
		-- const
		whoami = true,
	}
	for k, v in pairs(arr) do
		-- check overwrite / duplicate to avoid scenario namespace clash
		if zencode.schemas[k] then
			error('Add schema denied, already registered schema: ' .. k, 2)
		end
		if _illegal_schemas[k] then
			error('Add schema denied, reserved name: ' .. k, 2)
		end
		zencode.schemas[k] = v
	end
end

function zencode.have(obj) -- accepts arrays for depth checks
	local res
	if luatype(obj) == 'table' then
		local prev = ACK
		for k, v in ipairs(obj) do
			res = prev[uscore(v)]
			if not res then
				error('Cannot find object: ' .. v, 2)
			end
			prev = res
		end
	else
		res = ACK[uscore(obj)]
		if not res then
			error('Cannot find object: ' .. obj, 2)
		end
	end
	return res
end
function zencode.empty(obj)
	-- convert all spaces to underscore in argument
	if ACK[uscore(obj)] then
		error('Cannot overwrite existing object: ' .. obj, 2)
	end
end


function zencode.new()
	local res = {
		branch = false,
		branch_valid = false,
		id = 0,
		AST = {},
		traceback = {}, -- execution backtrace
		eval_cache = {}, -- zencode_eval if...then conditions
		checks = {version = false}, -- version, scenario checked, etc.
		OK = true, -- set false by asserts
		exitcode = 0
	}

	-- Reset HEAP
	res.IN = {} -- Given processing, import global DATA from json
	res.IN.KEYS = {} -- Given processing, import global KEYS from json
	res.TMP = {} -- Given processing, temp buffer for ack*->validate->push*
	res.ACK = {} -- When processing,  destination for push*
	res.OUT = {} -- print out
	res.AST = {} -- AST of parsed Zencode
	res.CODEC = {} -- saves input conversions for to decode using same
	res.WHO = nil
	-- Zencode init traceback
	res.machine = new_state_machine(zencode)
	collectgarbage 'collect'
	return(res)
end
---------------------------------------------------------------
-- ZENCODE PARSER

local function zencode_iscomment(b)
	local x = string.char(b:byte(1))
	if x == '#' then
		return true
	else
		return false
	end
end
local function zencode_isempty(b)
	if b == nil or trim(b) == '' then
		return true
	else
		return false
	end
end
-- returns an iterator for newline termination
local function zencode_newline_iter(text)
	s = trim(text) -- implemented in zen_io.c
	if s:sub(-1) ~= '\n' then
		s = s .. '\n'
	end
	return s:gmatch('(.-)\n') -- iterators return functions
end


function zencode.parse(ctx, text)
	if #text < 9 then -- strlen("and debug") == 9
   	  error("Zencode text too short to parse")
		 return false
	end
	local linenum=0
   -- xxx(text,3)
	local prefix
	local branching = false
	local parse_prefix = parse_prefix -- optimization
   for line in zencode_newline_iter(text) do
	linenum = linenum + 1
	  if not zencode_isempty(line) and not zencode_iscomment(line) then
	--   xxx('Line: '.. text, 3)
	  -- max length for single zencode line is #define MAX_LINE
	  -- hard-coded inside zenroom.h
	  prefix = parse_prefix(line)
	  assert(prefix, "Invalid Zencode line "..linenum..": "..line)
	  ctx.OK = true
	  ctx.exitcode=0
	  if prefix == 'if' then branching = true end
	  if branching and (prefix == 'when') then prefix = prefix..'if' end
	  if branching and (prefix == 'then') then prefix = prefix..'if' end
	  if prefix == 'endif' then branching = false end
	  -- try to enter the machine state named in prefix
	  -- xxx("Zencode machine enter_"..prefix..": "..text, 3)
	  local fm = ctx.machine["enter_"..prefix]
	  assert(fm, "Invalid Zencode line "..linenum..": "..line)
	  assert(fm(ctx.machine, { msg = line, Z = ctx }),
				line.."\n    "..
				"Invalid transition from: "..ctx.machine.current)
	  end
   end
   collectgarbage'collect'
   return true
end

function zencode.trace(ctx, src)
	-- take current line of zencode
	local tr = trim(src)
	-- TODO: tabbing, ugly but ok for now
	if string.sub(tr, 1, 1) == '[' then
		table.insert(ctx.traceback, tr)
	else
		table.insert(ctx.traceback, ' .  ' .. tr)
	end
end

-- trace function execution also on success
function zencode.ftrace(ctx, src)
	-- take current line of zencode
	table.insert(ctx.traceback, ' D  ZEN:' .. trim(src))
end

-- log zencode warning in traceback
function zencode.wtrace(ctx, src)
	-- take current line of zencode
	table.insert(ctx.traceback, ' W  ZEN:' .. trim(src))
end

local function IN_uscore(i)
	-- convert all element keys of IN to underscore
	local res = {}
    for k,v in pairs(i) do
	if luatype(v) == 'table' then
		 res[uscore(k)] = IN_uscore(v) -- recursion
	  else
		 res[uscore(k)] = v
	  end
   end
   return setmetatable(res, getmetatable(i))
end

-- return true: caller skip execution and go to ::continue::
-- return false: execute statement
local function manage_branching(x)
	if x.section == 'if' then
		xxx("START conditional execution: "..x.source, 2)
		if not ZEN.branch then ZEN.branch_valid = true end
		ZEN.branch = true
		return false
	end
	if x.section == 'endif' then
		xxx("END   conditional execution: "..x.source, 2)
		ZEN.branch = false
		return true
	end
	if not ZEN.branch then return false end
	if not ZEN.branch_valid then
		xxx('skip execution in false conditional branch: '..x.source, 2)
		return true
	end
	return false
end

function zencode.run(ctx, DATA, KEYS)

	-- HEAP setup
	ctx.IN = DATA or { }
	ctx.IN.KEYS = KEYS or { }
	-- convert all spaces in keys to underscore
	ctx.IN = IN_uscore(ctx.IN)

	-- EXEC zencode
	for _, x in pairs(ctx.AST) do
		-- ZEN:trace(x.source)
		if not manage_branching(x) then
		-- HEAP integrity guard
		if ctx.CONF.heapguard then
			-- trigger upon switch to when or then section
			if x.section == 'then' or x.section == 'when' then
				-- delete IN memory
				ctx.IN.KEYS = {}
				ctx.IN = {}
				collectgarbage 'collect'
				-- guard ACK's contents on section switch
				deepmap(function(val) -- zenguard was in zenroom_common
					if not (iszen(type(val)) or tonumber(val)) then
						error("Zenguard detected an invalid value in HEAP: type "..type(val), 2)
					end
				end, ctx.ACK)
			end
		end
		-- prepare the protected execution environment
		ctx.OK = true
		ctx.exitcode=0
		IN = ctx.IN
		ACK = ctx.ACK
		OUT = ctx.OUT
		CONF = ctx.CONF
		CODEC = ctx.CODEC
		empty = ctx.empty
		have = ctx.have
		WHO = ctx.WHO
		Iam = ctx.Iam
		MACHINE = ctx.machine
		I = ctx.inspect
		ZEN = ctx
		-- call execution and watch out for errors
		local ok, err = pcall(x.hook, unpack(x.args))
		if not ok or not ctx.OK then
			if err then
				ctx.trace('[!] ' .. err)
			end
			error(err ..'\nstatement:\t'.. x.source, 2) -- traceback print inside
		end
		collectgarbage 'collect'
		end -- not manage_branching
	end
	-- PRINT output
	ctx.trace('--- Zencode execution completed')
	return(ctx.OUT)
end

function zencode.serialize(A)
   local t = luatype(A)
   if t == 'table' then
      local res
      res = serialize(A)
      return OCTET.from_string(res.strings) .. res.octets
   elseif t == 'number' then
      return O.from_string(tostring(A))
   elseif t == 'string' then
      return O.from_string(A)
   else
      local zt = type(A)
      if not iszen(zt) then
	 error('Cannot convert value to octet: '..zt, 2)
      end
      -- all zenroom types have :octet() method to export
      return A:octet()
   end
   error('Unknown type, cannot convert to octet: '..type(A), 2)
end


function zencode.debug()
	debug_traceback()
	debug_heap_dump()
end

function zencode.assert(condition, errmsg)
	if condition then
	   return true
	else
	   EXE.branch_valid = false
	end
	-- in conditional branching ZEN.assert doesn't quit
	if EXE.branch then
		ZEN.trace(errmsg)
		xxx(errmsg)
	else
		-- ZEN.debug() -- prints all data in memory
		ZEN.trace('ERR ' .. errmsg)
		EXE.OK = false
		EXE.exitcode=1
		error(errmsg, 2)
	end
end

return zencode
