# /*
#  * This file is part of lua-zencode
#  * 
#  * Copyright (C) 2021 Dyne.org foundation
#  * designed, written and maintained by Denis Roio <jaromil@dyne.org>
#  * 
#  * This program is free software: you can redistribute it and/or modify
#  * it under the terms of the GNU Affero General Public License v3.0
#  * 
#  * This program is distributed in the hope that it will be useful,
#  * but WITHOUT ANY WARRANTY; without even the implied warranty of
#  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  * GNU Affero General Public License for more details.
#  * 
#  * Along with this program you should have received a copy of the
#  * GNU Affero General Public License v3.0
#  * If not, see http://www.gnu.org/licenses/agpl.txt
#  * 
#  * Last modified by Denis Roio
#  * on Monday, 27th September 2021
#  */

all:
	@echo "Nothing to build, use: make install"

install: PREFIX ?= /usr/local
install: DEST_LIBDIR ?= ${PREFIX}/lib/lua/5.1
install: DEST_SHAREDIR ?= ${PREFIX}/share/lua/5.1
install:
	install src/lua/init.lua -D ${DEST_SHAREDIR}/zencode/init.lua
	install src/lua/statemachine.lua -D ${DEST_SHAREDIR}/zencode/statemachine.lua
	install src/lua/inspect.lua -D ${DEST_SHAREDIR}/zencode/inspect.lua
	cp -v src/lua/zenroom*lua ${DEST_SHAREDIR}/zencode/
	cp -v src/lua/zencode*lua ${DEST_SHAREDIR}/zencode/

check: LUA=lua5.1
check:
	cd test/zencode_hash && LUA=${LUA} ./run.sh

check-luajit: LUA=luajit
check-luajit:
	cd test/zencode_hash && LUA=${LUA} ./run.sh
