_addon.name = 'DynaMobScan'
_addon.author = 'Aragan'
_addon.version = '1.0.0'
_addon.commands = {'dms', 'dynamobscan'}


local active = false
local zone_id = 134
local radius = 35
local interval = 1.0
local seen = {}
local log_path = nil
local last_scan = 0

local function now_stamp()
    return os.date('%Y-%m-%d %H:%M:%S')
end

local function file_stamp()
    return os.date('%Y%m%d_%H%M%S')
end

local function reset_seen()
    seen = {}
end

local function ensure_log()
    if log_path ~= nil then
        return
    end
    log_path = windower.addon_path .. 'data\\scan_' .. file_stamp() .. '.csv'
    local f = io.open(log_path, 'w')
    if f then
        f:write('time,zone,id,index,name,x,y,z,distance\n')
        f:close()
    end
end

local function append_row(row)
    if log_path == nil then
        return
    end
    local f = io.open(log_path, 'a')
    if not f then
        return
    end
    f:write(row .. '\n')
    f:close()
end

local function mob_distance(m)
    if not m or not m.distance then
        return 9999
    end
    local d = m.distance
    if d < 0 then
        d = 0
    end
    return math.sqrt(d)
end

local function normalize_name(name)
    if not name then
        return ''
    end
    local n = tostring(name)
    n = n:gsub('"', '\'\'')
    return n
end

local function record_mob(m, source)
    if not m or not m.id then
        return
    end
    local dist = mob_distance(m)
    local row = string.format(
        '%s,%d,%d,%d,"%s",%.3f,%.3f,%.3f,%.2f',
        now_stamp(),
        zone_id,
        m.id or 0,
        m.index or -1,
        normalize_name(m.name),
        m.x or 0,
        m.y or 0,
        m.z or 0,
        dist
    )
    append_row(row)
    windower.add_to_chat(207, string.format('[DMS] %s: %s (id:%d idx:%d) @ %.1f, %.1f, %.1f [%.1f]', source, m.name or 'Unknown', m.id or 0, m.index or -1, m.x or 0, m.y or 0, m.z or 0, dist))
end

local function scan_once()
    if not active then
        return
    end

    local info = windower.ffxi.get_info()
    if not info or not info.zone or info.zone ~= zone_id then
        return
    end

    local me = windower.ffxi.get_mob_by_target('me')
    if not me then
        return
    end

    local now = os.clock()
    if now - last_scan < interval then
        return
    end
    last_scan = now

    local arr = windower.ffxi.get_mob_array()
    if not arr then
        return
    end

    for _, m in pairs(arr) do
        if type(m) == 'table'
            and m.id and m.id > 0
            and m.is_npc
            and m.valid_target
            and m.hpp and m.hpp > 0
            and (m.name ~= nil and m.name ~= '')
        then
            local dist = mob_distance(m)
            if dist <= radius and not seen[m.id] then
                seen[m.id] = true
                record_mob(m, 'scan')
            end
        end
    end
end

windower.register_event('prerender', scan_once)

windower.register_event('zone change', function(new_id)
    if active then
        windower.add_to_chat(207, string.format('[DMS] Zone changed to %s. Seen cache reset.', tostring(new_id)))
        reset_seen()
    end
end)

windower.register_event('addon command', function(...)
    local args = {...}
    local cmd = args[1] and args[1]:lower() or 'help'

    if cmd == 'start' then
        if args[2] then
            local z = tonumber(args[2])
            if z then
                zone_id = z
            end
        end
        ensure_log()
        active = true
        reset_seen()
        windower.add_to_chat(207, string.format('[DMS] Started. zone=%d radius=%.1f log=%s', zone_id, radius, log_path))
        return
    end

    if cmd == 'stop' then
        active = false
        windower.add_to_chat(207, '[DMS] Stopped.')
        return
    end

    if cmd == 'radius' then
        local r = tonumber(args[2])
        if r and r > 0 then
            radius = r
            windower.add_to_chat(207, string.format('[DMS] Radius set to %.1f', radius))
        else
            windower.add_to_chat(123, '[DMS] Usage: //dms radius <number>')
        end
        return
    end

    if cmd == 'zone' then
        local z = tonumber(args[2])
        if z and z > 0 then
            zone_id = z
            reset_seen()
            windower.add_to_chat(207, string.format('[DMS] Zone set to %d', zone_id))
        else
            windower.add_to_chat(123, '[DMS] Usage: //dms zone <id>')
        end
        return
    end

    if cmd == 'target' then
        ensure_log()
        local t = windower.ffxi.get_mob_by_target('t')
        if t and t.is_npc and t.valid_target then
            record_mob(t, 'target')
        else
            windower.add_to_chat(123, '[DMS] No valid target selected.')
        end
        return
    end

    if cmd == 'reset' then
        reset_seen()
        windower.add_to_chat(207, '[DMS] Seen cache reset.')
        return
    end

    if cmd == 'status' then
        windower.add_to_chat(207, string.format('[DMS] active=%s zone=%d radius=%.1f log=%s', tostring(active), zone_id, radius, tostring(log_path)))
        return
    end

    if cmd == 'help' then
        windower.add_to_chat(207, '[DMS] Commands:')
        windower.add_to_chat(207, '[DMS] //dms start [zone]')
        windower.add_to_chat(207, '[DMS] //dms stop')
        windower.add_to_chat(207, '[DMS] //dms radius <n>')
        windower.add_to_chat(207, '[DMS] //dms zone <id>')
        windower.add_to_chat(207, '[DMS] //dms target')
        windower.add_to_chat(207, '[DMS] //dms reset')
        windower.add_to_chat(207, '[DMS] //dms status')
        return
    end

    windower.add_to_chat(123, '[DMS] Unknown command. Use //dms help')
end)
