local function tmpfile(location, suffix)
	local name = os.tmpname():match "[^/\\]+$"
	return location .. (OS=="windows" and '\\' or '/') .. name .. suffix
end

return tmpfile
