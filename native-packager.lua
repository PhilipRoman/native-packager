-- detect operating system based on what programs/files are present
-- remember that linux tools are commonly found on windows machines
if io.popen('echo %OS%'):read() == "Windows_NT" then
	OS = 'windows'
elseif os.execute 'cat /dev/null > /dev/null' then
	OS = 'linux'
else
	io.stderr:write("Failed to detect OS\n")
	os.exit(1)
end

local config = require 'config'

local tmpfile = require 'tmpfile'

local sources = table.concat({...}, " ")

local resourcefile = tmpfile(config[OS].tmpdir, ".o")
local sourcefile = tmpfile(config[OS].tmpdir, ".c")
local objectfile = tmpfile(config[OS].tmpdir, ".o")

local linker = config[OS].linker
local cc = config[OS].cc

local file = io.open(sourcefile, 'w')
file:write '#include <stdlib.h>\n'
file:write '#include <stdio.h>\n'
file:write '#include <string.h>\n'
file:write '#include <stdint.h>\n'
file:write '#include <unistd.h>\n'
file:write '#include <sys/stat.h>\n'
local args = {...}
local symbols = {}
for i, filename in ipairs(args) do
	symbols[filename] = {
		start = config[OS].symbol:gsub("(%b{})", {
			['{file}'] = filename:gsub("[^a-zA-Z0-9]", "_"),
			['{attribute}'] = 'start'
		}),
		['end'] = config[OS].symbol:gsub("(%b{})", {
			['{file}'] = filename:gsub("[^a-zA-Z0-9]", "_"),
			['{attribute}'] = 'end'
		}),
	}
end

for filename, symbol in pairs(symbols) do
	file:write("extern char ", symbol.start, ';');
	file:write("extern char ", symbol['end'], ';');
end
file:write 'int main(int argc, char **argv) {\n'
file:write '	char dir[L_tmpnam];'
file:write '	tmpnam(dir);'
file:write '	setenv("NATPACK", dir, 1);'
file:write '	mkdir(dir, 0777);'
file:write '	char *filename = malloc(1024);\n'
for filename, symbol in pairs(symbols) do
	file:write '	{\n'
	file:write '	strcpy(filename, dir);\n'
	file:write '	strcat(filename, "/");\n'
	file:write('	strcat(filename, "', filename, '");\n')
	file:write('	printf("Inflating %s\\n", filename);\n')
	file:write '	FILE *file = fopen(filename, "w+");\n'
	file:write('	fwrite(&', symbol.start, ', 1, &', symbol['end'], ' - &', symbol.start, ', file);\n')
	file:write '	fclose(file);\n'
	file:write '	}\n'
end
file:write '	free(filename);\n'
if config.chdir then
file:write('	chdir(dir);\n')
end
file:write('	system("', config[OS].command, '");\n')
file:write '}\n'
file:close()

os.execute(linker:gsub("(%b{})", {['{sources}'] = sources, ['{output}'] = resourcefile}))
os.execute(cc:gsub("(%b{})", {['{sources}'] = sourcefile..' '..resourcefile, ['{output}'] = config[OS].output}))
