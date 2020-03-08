local config = {
	chdir = false,

	linux = {
		linker = 'ld -r -b binary -o {output} {sources}',
		cc = 'gcc -o {output} {sources}',
		tmpdir = '/tmp',
		output = 'natpack.out',
		symbol = '_binary_{file}_{attribute}'
	},

	windows = {
		linker = 'x86_64-w64-mingw32-ld -r -b binary -o {output} {sources}',
		cc = 'x86_64-w64-mingw32-gcc -o {output} {sources}',
		tmpdir = '.',
		output = 'natpack.out.exe',
		symbol = 'binary_{file}_{attribute}'
	},
}

local function merge(new, fallback)
	if type(fallback) == 'table' and type(new) == 'table' then
		for k, v in pairs(fallback) do
			new[k] = merge(new[k], fallback[k])
		end
		return new
	end
	return new or fallback
end

local file = io.open('natpack.config', 'r')

if not file then
	return config
end

local result, err = load(file:read 'a')

file:close()

if not result then
	io.stderr:write("Failed to parse config file: " .. err .. "\n")
	os.exit(1)
end

result = result()

if type(result) ~= 'table' then
	io.stderr:write("Expected to get a table from config file, got "..type(result).."\n")
	os.exit(1)
end

config = merge(result, config)

local function protect(t)
	setmetatable(t, {
		__index = function(self, k)
			error("No such key in configuration: " .. tostring(key) .. "\n")
		end
	})
	for k, v in pairs(t) do
		print(k)
		if type(v) == 'table' then
			protect(v)
		end
	end
end

protect(config)

return config
