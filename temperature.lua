-- 
-- This collectd Lua plugin greps envstat output for temperatures on NetBSD.
-- 
-- Output of envstat looks like this:
--                                      Current  CritMax  WarnMax  WarnMin  CritMin  Unit
-- [acpitz0]
--   cpu0/cpu1/cpu2/cpu3 temperature:    42.000  103.000                             degC
-- [coretemp0]
--                  cpu0 temperature:    41.000                                      degC
-- [coretemp1]
--                  cpu1 temperature:    41.000                                      degC

local hostname = io.popen("/bin/hostname"):read()

local function read_temperature(temperature)
	temperature = temperature or {}

	for l in io.popen("/usr/sbin/envstat"):lines() do
		local k, v = l:match("^%s*(%S+)%s+temperature:%s+([.0-9]+)")
		if k and v then
			k = 'temperature-' .. k:gsub("/", "-")
			temperature[k] = tonumber(v)
		end
	end

	return temperature
end

-- Cache tables for a slightly better performance.
local temperature = read_temperature()
local values = { host = hostname, type = 'gauge', values = { 0 } }

local function read()
	read_temperature(temperature)

	for plugin, value in pairs(temperature) do
		values.plugin = plugin
		values.values[1] = value
		collectd.dispatch_values(values)
	end

	return 0
end

local function log_success()
	local msg = "temperature.lua will report "
	for s, _ in pairs(temperature) do msg = msg .. s .. " " end
	msg = msg .. "on hostname " .. hostname
	collectd.log_info(msg)
end

collectd.register_read(read)
log_success()
