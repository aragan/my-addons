_addon.name     = 'DoorHelper'
_addon.author   = 'Aragan'
_addon.version  = '1.3'
_addon.commands = {'doorhelper', 'dh'}

packets = require('packets')
config  = require('config')

----------------------------------------------------------
-- الإعدادات العامة للإضافة
-- auto_yes : تشغيل/إيقاف Auto-Yes
-- debug    : إذا true يطبع Menu ID / NPC / Index لكل Menu
----------------------------------------------------------
local settings = config.load({
    auto_yes = true,
    debug    = true,
})

-- متغيّرات منطق الأبواب
local last_menu_id       = 0
local auto_busy          = false
local last_door_id       = nil -- آخر باب
local door_message_shown = false -- هل طُبعت رسالة الباب؟

----------------------------------------------------------
-- دالة Debug بسيطة
----------------------------------------------------------
local function debug_print(msg)
    if settings.debug then
        windower.add_to_chat(207, '[DoorHelper-DEBUG] ' .. msg)
    end
end

----------------------------------------------------------
-- دالة حساب المسافة بين اللاعب وأي موب
----------------------------------------------------------
local function get_distance(a, b)
    if not a or not b then
        return 999
    end
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end

----------------------------------------------------------
-- دالة "نقزة" على الهدف (تفتح قائمة الـ NPC / الباب)
----------------------------------------------------------
local function poke(target)
    if not target then
        return
    end
    local p = packets.new('outgoing', 0x01A, {
        ["Target"]       = target.id,
        ["Target Index"] = target.index,
        ["Category"]     = 0,
        ["Param"]        = 0,
        ["_unknown1"]    = 0,
    })
    packets.inject(p)
end

----------------------------------------------------------
-- اختيار Yes باستخدام آخر Menu ID (منطق الأبواب القديم)
----------------------------------------------------------
local function select_yes_old(target)
    if not target or last_menu_id == 0 then
        return
    end
    local zone = windower.ffxi.get_info().zone
    local p = packets.new('outgoing', 0x05B, {
        ["Target"]            = target.id,
        ["Target Index"]      = target.index,
        ["Option Index"]      = 1, -- Yes
        ["_unknown1"]         = 0,
        ["_unknown2"]         = 0,
        ["Automated Message"] = false,
        ["Zone"]              = zone,
        ["Menu ID"]           = last_menu_id,
    })
    packets.inject(p)
end

----------------------------------------------------------
-- Auto-Yes عام لأي Menu (يقرا من 0x034/0x032 مباشرة)
-- هذه الدالة هي الأهم لمود Yes/No
----------------------------------------------------------
local function auto_select_yes_from_menu(pkt)
    if not pkt then
        return
    end

    -- Menu ID = 0 يعني لا يوجد Menu حقيقي
    if not pkt['Menu ID'] or pkt['Menu ID'] == 0 then
        return
    end

    -- بعض المينوز لا تحتوي NPC/NPC Index (حماية)
    if not pkt['NPC'] or not pkt['NPC Index'] then
        return
    end

    local zone = windower.ffxi.get_info().zone

    local yes = packets.new('outgoing', 0x05B, {
        ["Target"]            = pkt['NPC'],
        ["Target Index"]      = pkt['NPC Index'],
        ["Option Index"]      = 1,                     -- نفترض Yes = 1 في قوائم Yes/No
        ["_unknown1"]         = pkt['_unknown1'] or 0, -- ننسخ نفس القيمة للأمان
        ["_unknown2"]         = 0,
        ["Automated Message"] = false,
        ["Zone"]              = zone,
        ["Menu ID"]           = pkt['Menu ID'],
    })

    packets.inject(yes)
    windower.add_to_chat(207,
        ('[DoorHelper] Auto-Yes sent (MenuID: %d).'):format(pkt['Menu ID']))
end

----------------------------------------------------------
-- إيجاد أقرب Door من اللاعب (منطق الأبواب القديم)
-- 📌 مضاف: دعم خاص لـ Gilded Gateway (ID: 17084923)
----------------------------------------------------------
local function find_nearest_door()
    local player = windower.ffxi.get_mob_by_target('me')
    if not player then
        return nil
    end

    local mobs = windower.ffxi.get_mob_array()
    local nearest
    local min_dist = 3.2 -- نفس القيمة القديمة

    for _, mob in pairs(mobs) do
        if mob and mob.is_npc then
            local is_door = false

            -- 1) الأبواب العادية: الاسم يحتوي "door"
            if mob.name and mob.name:lower():find('door', 1, true) then
                is_door = true
            end

            -- 2) استثناء خاص: Gilded Gateway (باب البوس الأخير)
            -- ID = 17084923
            if mob.id == 17084923 then
                is_door = true
            end

            if is_door then
                local dist = get_distance(player, mob)
                if dist < min_dist then
                    nearest  = mob
                    min_dist = dist
                end
            end
        end
    end

    return nearest
end

----------------------------------------------------------
-- أوامر الإضافة:
-- //dh yes on/off/toggle/status
-- //dh debug on/off/toggle/status
----------------------------------------------------------
windower.register_event('addon command', function(cmd, ...)
    cmd = cmd and cmd:lower() or ''
    local args = {...}

    if cmd == 'yes' then
        local sub = (args[1] or 'toggle'):lower()

        if sub == 'on' then
            settings.auto_yes = true
            config.save(settings)
            windower.add_to_chat(207, '[DoorHelper] Auto-Yes: ON')

        elseif sub == 'off' then
            settings.auto_yes = false
            windower.add_to_chat(207, '[DoorHelper] Auto-Yes: OFF')

        elseif sub == 'toggle' then
            settings.auto_yes = not settings.auto_yes
            config.save(settings)
            windower.add_to_chat(207,
                ('[DoorHelper] Auto-Yes toggled → %s'):format(settings.auto_yes and 'ON' or 'OFF'))

        elseif sub == 'status' then
            windower.add_to_chat(207,
                ('[DoorHelper] Auto-Yes status: %s'):format(settings.auto_yes and 'ON' or 'OFF'))
        else
            windower.add_to_chat(207,
                '[DoorHelper] Usage: //dh yes [on|off|toggle|status]')
        end

    elseif cmd == 'debug' then
        local sub = (args[1] or 'toggle'):lower()

        if sub == 'on' then
            settings.debug = true
            config.save(settings)
            windower.add_to_chat(207, '[DoorHelper] DEBUG: ON (show MenuID / ID / Index)')

        elseif sub == 'off' then
            settings.debug = false
            config.save(settings)
            windower.add_to_chat(207, '[DoorHelper] DEBUG: OFF')

        elseif sub == 'toggle' then
            settings.debug = not settings.debug
            config.save(settings)
            windower.add_to_chat(207,
                ('[DoorHelper] DEBUG toggled → %s'):format(settings.debug and 'ON' or 'OFF'))

        elseif sub == 'status' then
            windower.add_to_chat(207,
                ('[DoorHelper] DEBUG status: %s'):format(settings.debug and 'ON' or 'OFF'))
        else
            windower.add_to_chat(207,
                '[DoorHelper] Usage: //dh debug [on|off|toggle|status]')
        end

    else
        windower.add_to_chat(207,
            '[DoorHelper] Commands: //dh yes [...]  |  //dh debug [...]')
    end
end)

----------------------------------------------------------
-- التقاط حزم القوائم 0x034 و 0x032 (Menu)
-- إذا Auto-Yes مفعّل و المينيو مصدره هو الباب الأخير فقط → نرسل Yes
-- HP / Lamp / NPCs ثانية ما نلمسها نهائياً
-- مع DEBUG: نطبع MenuID و NPC و Index لكل Menu
----------------------------------------------------------
windower.register_event('incoming chunk', function(id, data)

    -- نهتم فقط بحزم الـ Menu
    if id ~= 0x034 and id ~= 0x032 then
        return
    end

    local p = packets.parse('incoming', data)
    if not p then
        return
    end

    --------------------------------------------------
    -- جزء الـ DEBUG: يطبع IDs لكل Menu تصله الحزمة
    --------------------------------------------------
    if settings.debug then
        local info = windower.ffxi.get_info()
        windower.add_to_chat(207,
            ('[DoorHelper-DEBUG] MenuID:%d | NPC:%d | Index:%d | Zone:%d'):format(
                p['Menu ID'] or 0,
                p['NPC'] or 0,
                p['NPC Index'] or 0,
                info.zone or 0
            ))
    end

    --------------------------------------------------
    -- من هنا وطالع: منطق Auto-Yes العادي
    --------------------------------------------------

    -- ❌ منع Auto-Yes في Alzadaal Undersea Ruins (Zone ID = 72)
    local info = windower.ffxi.get_info()
    if info.zone == 72 then
        return -- لا نلمس أي قائمة Yes/No في هذا الزون (لكن DEBUG اشتغل فوق)
    end

    -- لو Auto-Yes مطفي: لا نغيّر شيء، المينيو شغّاله طبيعي
    if not settings.auto_yes then
        return
    end

    -- إذا ما عندنا باب آخر معروف، أو هذا المينيو ليس من نفس الباب → لا تلمسه
    -- هذا يخلي HP / Lamp / أي NPC ثاني يشتغل عادي
    if not last_door_id or p['NPC'] ~= last_door_id then
        return
    end

    -- هنا فقط: المينيو حق الباب اللي poked عليه
    -- 1) نرسل حزمة Yes (0x05B) بعد تأخير بسيط
    -- 2) نرجع true عشان نمنع ظهور المينيو للعميل (فما يعلق)
    coroutine.schedule(function()
        auto_select_yes_from_menu(p)
    end, 5.1)

    -- نمنع المينيو لهذا الباب فقط
    return true
end)

----------------------------------------------------------
-- منطق الأبواب: يقرب من الباب ويضغط Yes (أو poke فقط)
----------------------------------------------------------
windower.register_event('prerender', function()
    -- لو في عملية حالياً لا نكرر
    if auto_busy then
        return
    end
    auto_busy = true

    local door = find_nearest_door()

    if door then
        if last_door_id ~= door.id then
            last_door_id       = door.id
            door_message_shown = false
        end

        if not door_message_shown then
            windower.add_to_chat(200, '[DoorHelper] Found door: ' .. door.name .. ' (ID: ' .. door.id .. ')')
            door_message_shown = true
        end

        -- كليك (poke) على الباب (يكفي لـ Gilded Gateway لأن ما عنده Yes/No)
        poke(door)

        -- للأبواب اللي فيها Menu ID / Yes/No، select_yes_old يحاول يستخدم last_menu_id
        coroutine.schedule(function()
            select_yes_old(door)
            auto_busy = false
        end, 6.2)
    else
        auto_busy = false
    end
end)
