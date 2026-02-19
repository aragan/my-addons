_addon.name = 'vagary'
_addon.author = 'Aragan'
_addon.version = '1.2.0'
_addon.commands = {'vagary', 'vg'}

local config = require('config')
local texts = require('texts')
require('chat')

local defaults = {
    pos = {x = 60, y = 220},
    text = {
        font = 'Consolas',
        size = 12,
        red = 255,
        green = 255,
        blue = 255,
        alpha = 255,
        stroke = {
            width = 2,
            alpha = 200,
            red = 0,
            green = 0,
            blue = 0,
        },
    },
    bg = {
        alpha = 140,
        red = 20,
        green = 20,
        blue = 20,
        visible = true,
    },
    flags = {
        right = false,
        bottom = false,
        draggable = true,
        bold = false,
    },
    visible = true,
    hud_anywhere = false, -- false = only Vagary zones
    display_mode = 'full', -- full | short
    text_color_mode = 'gold', -- gold | blue | purple
}

local settings = config.load(defaults)
settings.flags = settings.flags or {}
settings.flags.draggable = true
if settings.display_mode ~= 'full' and settings.display_mode ~= 'short' then
    settings.display_mode = 'full'
end
if settings.text_color_mode ~= 'gold' and settings.text_color_mode ~= 'blue' and settings.text_color_mode ~= 'purple' then
    settings.text_color_mode = 'gold'
end
config.save(settings)

local color_modes = {
    gold = {
        pending = '\\cs(255,210,140)',
        done = '\\cs(255,236,170)',
    },
    blue = {
        pending = '\\cs(140,190,255)',
        done = '\\cs(180,220,255)',
    },
    purple = {
        pending = '\\cs(210,160,255)',
        done = '\\cs(230,190,255)',
    },
}

local C = {white = '\\cs(255,255,255)'}

local function active_colors()
    return color_modes[settings.text_color_mode] or color_modes.gold
end

-- Vagary zones only (not Sortie)
local vagary_zone_ids = {
    [259] = true, -- Rala Waterways [U]
    [264] = true, -- Yorcia Weald [U]
    [271] = true, -- Cirdas Caverns [U]
    [275] = true, -- Outer Ra'Kaznar [U1]
}

local tracks = {
    perfidien = {
        name = 'Perfidien',
        step = 1,
        steps = {
            {
                mission = 'Ashen Wings',
                ki = 'Umbral Hue',
                tokens = {'ashen wings', 'umbral hue'},
            },
            {
                mission = 'Ashen Wings',
                ki = 'Deeper Black Hue',
                tokens = {'ashen wings', 'deeper black hue'},
            },
            {
                mission = 'Ashen Wings',
                ki = 'Dead of Night (Spawn)',
                tokens = {'ashen wings', 'indistinguishable from the dead of night'},
            },
        },
    },
    plouton = {
        name = 'Plouton',
        step = 1,
        steps = {
            {
                mission = 'False Kings',
                ki = 'Deeper Red Hue',
                tokens = {'false kings', 'deeper red hue'},
            },
            {
                mission = 'False Kings',
                ki = 'Crimson Hue',
                tokens = {'false kings', 'crimson hue'},
            },
            {
                mission = 'False Kings',
                ki = 'Pool of Blood (Spawn)',
                tokens = {'false kings', 'indistinguishable from a pool of blood'},
            },
        },
    },
}

local box = texts.new('', settings)
pcall(function() box:draggable(true) end)

local last_pos_save = 0

local function lower(s)
    if not s then
        return ''
    end
    return s:lower()
end

local function contains_all(s, tokens)
    for _, token in ipairs(tokens) do
        if not s:find(token, 1, true) then
            return false
        end
    end
    return true
end

local function clamp(v, min_v, max_v)
    if v < min_v then
        return min_v
    end
    if v > max_v then
        return max_v
    end
    return v
end

local function save_position_if_changed()
    local x, y = box:pos()
    if type(x) == 'table' then
        y = x.y
        x = x.x
    end
    if type(x) ~= 'number' or type(y) ~= 'number' then
        return
    end
    if x == settings.pos.x and y == settings.pos.y then
        return
    end
    local now = os.clock()
    if now - last_pos_save < 0.5 then
        return
    end
    settings.pos.x = x
    settings.pos.y = y
    config.save(settings)
    last_pos_save = now
end

local function ensure_on_screen()
    local ws = windower.get_windower_settings() or {}
    local max_x = math.max(0, (ws.ui_x_res or 1920) - 520)
    local max_y = math.max(0, (ws.ui_y_res or 1080) - 70)
    local x = tonumber(settings.pos and settings.pos.x) or defaults.pos.x
    local y = tonumber(settings.pos and settings.pos.y) or defaults.pos.y
    local nx = clamp(x, 0, max_x)
    local ny = clamp(y, 0, max_y)
    settings.pos.x = nx
    settings.pos.y = ny
    box:pos(nx, ny)
end

local function in_vagary_zone()
    local info = windower.ffxi.get_info()
    if not info then
        return false
    end
    return vagary_zone_ids[info.zone] == true
end

local function should_show_hud()
    if not settings.visible then
        return false
    end
    if settings.hud_anywhere then
        return true
    end
    return in_vagary_zone()
end

local function track_line(t)
    local col = active_colors()
    local current = t.steps[t.step]
    if not current then
        return string.format('%s%s [3/3]%s: DONE', col.done, t.name, C.white)
    end

    if settings.display_mode == 'short' then
        return string.format(
            '%s%s [%d/3]%s %sKI:%s %s%s%s',
            col.pending,
            t.name,
            t.step,
            C.white,
            col.pending,
            C.white,
            col.pending,
            current.ki,
            C.white
        )
    end

    return string.format(
        '%s%s [%d/3]%s: %s%s%s %s/ KI:%s %s%s%s',
        col.pending,
        t.name,
        t.step,
        C.white,
        col.pending,
        current.mission,
        C.white,
        col.pending,
        C.white,
        col.pending,
        current.ki,
        C.white
    )
end

local function refresh_box()
    ensure_on_screen()
    box:text(track_line(tracks.perfidien) .. '\n' .. track_line(tracks.plouton))
    if should_show_hud() then
        box:show()
    else
        box:hide()
    end
end

local function reset_tracks()
    tracks.perfidien.step = 1
    tracks.plouton.step = 1
    refresh_box()
end

local function advance_track(name, message)
    local t = tracks[name]
    if not t or t.step > #t.steps then
        return
    end

    for i = t.step, #t.steps do
        if contains_all(message, t.steps[i].tokens) then
            t.step = i + 1
            if t.step > #t.steps then
                windower.add_to_chat(207, '[Vagary] ' .. t.name .. ' complete.')
            else
                windower.add_to_chat(207, '[Vagary] ' .. t.name .. ' advanced to next KI.')
            end
            refresh_box()
            return
        end
    end
end

local function print_help()
    windower.add_to_chat(207, '[Vagary] Commands:')
    windower.add_to_chat(207, '//vagary help')
    windower.add_to_chat(207, '//vagary reset')
    windower.add_to_chat(207, '//vagary show | hide')
    windower.add_to_chat(207, '//vagary pos <x> <y>')
    windower.add_to_chat(207, '//vagary hud on|off|toggle|status   (on = show in any zone)')
    windower.add_to_chat(207, '//vagary hud <x> <y>              (move + show in any zone)')
    windower.add_to_chat(207, '//vagary mode full|short')
    windower.add_to_chat(207, '//vagary text gold|blue|purple|status')
end

windower.register_event('incoming text', function(original)
    if not in_vagary_zone() and not settings.hud_anywhere then
        return
    end
    local msg = lower(original)
    if msg == '' then
        return
    end
    advance_track('perfidien', msg)
    advance_track('plouton', msg)
end)

windower.register_event('zone change', function()
    refresh_box()
end)

windower.register_event('prerender', function()
    save_position_if_changed()
    if should_show_hud() then
        box:show()
    else
        box:hide()
    end
end)

windower.register_event('addon command', function(cmd, ...)
    cmd = lower(cmd)
    local args = {...}

    if cmd == 'reset' then
        reset_tracks()
        windower.add_to_chat(207, '[Vagary] Reset done.')
        return
    end

    if cmd == 'show' then
        settings.visible = true
        config.save(settings)
        refresh_box()
        return
    end

    if cmd == 'hide' then
        settings.visible = false
        config.save(settings)
        refresh_box()
        return
    end

    if cmd == 'pos' then
        local x = tonumber(args[1])
        local y = tonumber(args[2])
        if x and y then
            settings.pos.x = x
            settings.pos.y = y
            config.save(settings)
            refresh_box()
        else
            windower.add_to_chat(123, '[Vagary] Usage: //vagary pos <x> <y>')
        end
        return
    end

    if cmd == 'hud' then
        local x = tonumber(args[1])
        local y = tonumber(args[2])
        if x and y then
            settings.pos.x = x
            settings.pos.y = y
            settings.visible = true
            settings.hud_anywhere = true
            config.save(settings)
            refresh_box()
            windower.add_to_chat(207, string.format('[Vagary] HUD moved to (%d, %d), anywhere ON.', x, y))
            return
        end

        local sub = lower(args[1] or 'toggle')
        if sub == 'on' then
            settings.hud_anywhere = true
        elseif sub == 'off' then
            settings.hud_anywhere = false
        elseif sub == 'status' then
            windower.add_to_chat(207, '[Vagary] HUD-anywhere: ' .. (settings.hud_anywhere and 'ON' or 'OFF'))
            return
        else
            settings.hud_anywhere = not settings.hud_anywhere
        end
        config.save(settings)
        refresh_box()
        windower.add_to_chat(207, '[Vagary] HUD-anywhere: ' .. (settings.hud_anywhere and 'ON' or 'OFF'))
        return
    end

    if cmd == 'mode' then
        local mode = lower(args[1] or '')
        if mode == 'full' or mode == 'short' then
            settings.display_mode = mode
            config.save(settings)
            refresh_box()
            windower.add_to_chat(207, '[Vagary] Display mode: ' .. mode)
        else
            windower.add_to_chat(123, '[Vagary] Usage: //vagary mode full|short')
        end
        return
    end

    if cmd == 'text' then
        local tmode = lower(args[1] or 'status')
        if tmode == 'status' then
            windower.add_to_chat(207, '[Vagary] Text color: ' .. settings.text_color_mode)
            return
        end
        if tmode == 'gold' or tmode == 'blue' or tmode == 'purple' then
            settings.text_color_mode = tmode
            config.save(settings)
            refresh_box()
            windower.add_to_chat(207, '[Vagary] Text color: ' .. tmode)
        else
            windower.add_to_chat(123, '[Vagary] Usage: //vagary text gold|blue|purple')
        end
        return
    end

    if cmd == 'help' or cmd == nil or cmd == '' then
        print_help()
        return
    end

    windower.add_to_chat(123, '[Vagary] Unknown command. Use //vagary help')
end)

windower.register_event('load', function()
    ensure_on_screen()
    pcall(function() box:draggable(true) end)
    refresh_box()
    windower.add_to_chat(207, '[Vagary] Loaded. //vagary help')
end)

windower.register_event('unload', function()
    if box then
        box:destroy()
    end
end)

refresh_box()
