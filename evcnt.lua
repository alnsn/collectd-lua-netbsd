-- 
-- This collectd Lua plugin parses vmstat -e output on NetBSD.
-- 

local hostname = io.popen("/bin/hostname"):read()

local function read_vmstat(stats)
	stats = stats or {}

	for l in io.popen("/usr/bin/vmstat -e"):lines() do
		local k, v = l:match("^(.-)%s+(%d+)%s+%d+%s+%a+$")
		if k and v then
			k = "evcnt-" .. k:gsub("[/%s]", "-")
			stats[k] = tonumber(v)
		end
	end

	return stats
end

-- Cache tables for a slightly better performance.
local stats = read_vmstat()
local values = { host = hostname, type = 'counter', values = { 0 } }

local function read()
	read_vmstat(stats)

	for plugin, value in pairs(stats) do
		values.plugin = plugin
		values.values[1] = value
		collectd.dispatch_values(values)
	end

	return 0
end

local function log_success()
	local msg = "evcnt.lua will report "
	for s, _ in pairs(stats) do msg = msg .. s .. " " end
	msg = msg .. "on hostname " .. hostname
	collectd.log_info(msg)
end

collectd.register_read(read)
log_success()
