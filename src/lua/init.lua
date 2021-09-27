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
--on Monday, 27th September 2021
--]]

require'zenroom'

MACHINE = require'zencode.statemachine'
Z = 'zencode.zencode'
ZEN = require(Z)

require'zencode.zenroom_common'

require(Z..'_data') -- pick/in, conversions etc.
require('zencode.zencode_given')
require('zencode.zencode_when')
require('zencode.zencode_hash') -- when extension
require('zencode.zencode_array') -- when extension
require('zencode.zencode_random') -- when extension
require('zencode.zencode_dictionary') -- when extension
require('zencode.zencode_verify') -- when extension
require('zencode.zencode_then')
require('zencode.zencode_keys')
require('zencode.zencode_debug')
-- scenario are loaded on-demand
-- scenarios can only implement "When ..." steps
_G['Given'] = nil
_G['Then'] = nil

-- defaults
ZEN.CONF = {
	input = {
		encoding = input_encoding('base64'),
		tagged = false
	},
	output = {
		encoding = output_encoding('base64'),
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
ZEN.SALT = ECP.hashtopoint(OCTET.from_string(COPYRIGHT .. LICENSE))
-- Calculate a system-wide crypto challenge for ZKP operations
-- returns a BIG INT
-- this is a sort of salted hash for advanced ZKP operations and
-- should not be changed. It may be made configurable in future.
ZEN.challenge = function(list)
	local challenge =
		ECP.generator():octet() .. ECP2.generator():octet() .. SALT:octet()
	local ser = serialize(list)
	return INT.new(
		sha256(challenge .. ser.octets .. OCTET.from_string(ser.strings))
	) % ECP.order()
end

return(ZEN)