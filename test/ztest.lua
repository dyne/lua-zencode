require'zencode'
JSON = require'rapidjson'

local script = io.read('*a')

ZEN:begin()
ZEN:parse(script)
local res = ZEN:run()

print(JSON.encode(res))

