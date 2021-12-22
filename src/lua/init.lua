--[[
--This file is part of lua
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
--on Friday, 1st October 2021
--]]

require'zenroom'

local zen = { }
local ZZ = 'zencode.zencode'
zen = require(ZZ)
Given = zen.Given
When = zen.When
IfWhen = zen.IfWhen
Then = zen.Then

ZEN = zen
zen.common = require'zencode.zenroom_common'
zen.machine = require'zencode.statemachine'
zen.inspect = require'zencode.inspect'
zen.semver = require('zencode.semver')

-- MACHINE = require'zencode.statemachine'

zen.data   = require(ZZ..'_data') -- pick/in, conversions etc.
-- ZEN = zen
require(ZZ..'_given')
require(ZZ..'_when')
require(ZZ..'_hash') -- when extension
require(ZZ..'_array') -- when extension
require(ZZ..'_random') -- when extension
require(ZZ..'_dictionary') -- when extension
require(ZZ..'_verify') -- when extension
require(ZZ..'_then')
require(ZZ..'_keys')
require(ZZ..'_debug')
-- scenario are loaded on-demand
-- scenarios can only implement "When ..." steps
_G['Given'] = nil
_G['Then'] = nil
ZEN = nil

-- defaults
zen.CONF = {
	input = {
		encoding = zen.common.input_encoding('base64'),
		tagged = false
	},
	output = {
		encoding = zen.common.output_encoding('base64'),
		versioning = false
	},
	parser = {strict_match = true},
	hash = 'sha256',
    heapguard = true
}
-- do not modify
_G['LICENSE'] =
	[[
Licensed under the terms of the GNU Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.  Unless required by applicable
law or agreed to in writing, software distributed under the License
is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.
]]
_G['COPYRIGHT'] =
	[[
Forked by Jaromil on 18 January 2020 from Coconut Petition
]]
zen.SALT = ECP.hashtopoint(OCTET.from_string(COPYRIGHT .. LICENSE))
-- Calculate a system-wide crypto challenge for ZKP operations
-- returns a BIG INT
-- this is a sort of salted hash for advanced ZKP operations and
-- should not be changed. It may be made configurable in future.
zen.challenge = function(list)
	local challenge =
		ECP.generator():octet() .. ECP2.generator():octet() .. self.SALT:octet()
	local ser = serialize(list)
	return INT.new(
		sha256(challenge .. ser.octets .. OCTET.from_string(ser.strings))
	) % ECP.order()
end

return(zen)
