require'zencode'
JSON = require'rapidjson'
pp = STR.printerr

function readfile(file)
    local f = assert(io.open(file, "rb"))
    -- f:read("*line") -- EOF pipe empty and newline
    local content = f:read("*all")
    f:close()
    return content
end

local script = io.read('*a')
local fdata, fkeys
if arg[1] then
	toks = strtok(arg[1])
	fdata = toks[1]
	fkeys = toks[2]
end

local data, keys, err
if fdata then
	data, err = JSON.decode( I.spy( readfile(fdata) ) )
	if not data then error("JSON DATA ERROR: "..err) end
end
if fkeys then
	keys, err = JSON.decode( readfile(fkeys) )
	if not keys then error("JSON KEYS ERROR: "..err) end
end

ZEN:begin()
ZEN:parse(script)
local res = ZEN:run(data, keys)

print(JSON.encode(res))

