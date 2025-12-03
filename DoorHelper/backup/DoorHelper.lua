_addon.name = 'DoorHelper'
_addon.author = 'Aragan'
_addon.version = '1.2'
_addon.commands = {'doorhelper', 'dh'}

packets = require('packets')
config  = require('config')

-- الإعدادات العامة للإضافة
-- auto_yes : إذا كانت true يختار "Yes" تلقائياً لأي قائمة Yes/No أو Menu مشابه
local settings = config.load({
    auto_yes = true,
})

-- متغيّرات منطق الأبواب القديم (اختياري)
local last_menu_id       = 0
local auto_busy          = false
local last_door_id       = nil -- آخر باب
local door_message_shown = false -- هل طُبعت رسالة الباب؟

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
        ["Target"]           = target.id,
        ["Target Index"]     = target.index,
        ["Option Index"]     = 1, -- Yes
        ["_unknown1"]        = 0,
        ["_unknown2"]        = 0,
        ["Automated Message"]= false,
        ["Zone"]             = zone,
        ["Menu ID"]          = last_menu_id,
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
        ["Target"]           = pkt['NPC'],
        ["Target Index"]     = pkt['NPC Index'],
        ["Option Index"]     = 1,                     -- نفترض Yes = 1 في قوائم Yes/No
        ["_unknown1"]        = pkt['_unknown1'] or 0, -- ننسخ نفس القيمة للأمان
        ["_unknown2"]        = 0,
        ["Automated Message"]= false,
        ["Zone"]             = zone,
        ["Menu ID"]          = pkt['Menu ID'],
    })

    packets.inject(yes)
    windower.add_to_chat(207,
        ('[DoorHelper] Auto-Yes sent (MenuID: %d).'):format(pkt['Menu ID']))
end

----------------------------------------------------------
-- إيجاد أقرب Door من اللاعب (منطق الأبواب القديم)
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
        if mob and mob.name and mob.is_npc then
            if mob.name:lower():find('door', 1, true) then
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
-- //dh yes on      → تشغيل Auto-Yes
-- //dh yes off     → إيقاف Auto-Yes
-- //dh yes toggle  → تبديل
-- //dh yes status  → عرض الحالة
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
            config.save(settings)
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
    else
        windower.add_to_chat(207,
            '[DoorHelper] Commands: //dh yes [on|off|toggle|status]')
    end
end)

----------------------------------------------------------
-- التقاط حزم 0x034 / 0x032 (Menu) لتخزين Menu ID
-- + تفعيل Auto-Yes العام عند فتح أي Menu
----------------------------------------------------------
----------------------------------------------------------
-- التقاط حزم القوائم 0x034 و 0x032 (Menu)
-- إذا Auto-Yes مفعّل و المينيو مصدره هو الباب الأخير فقط → نرسل Yes
-- HP / Lamp / NPCs ثانية ما نلمسها نهائياً
----------------------------------------------------------
windower.register_event('incoming chunk', function(id, data)

    -- ❌  منع Auto-Yes في Alzadaal Undersea Ruins (Zone ID = 72)
    local info = windower.ffxi.get_info()
    if info.zone == 72 then
        return -- لا نلمس أي قائمة Yes/No في هذا الزون
    end
    -- 0x034 و 0x032 كلاهما حزم Menu
    if id ~= 0x034 and id ~= 0x032 then
        return
    end

    local p = packets.parse('incoming', data)
    if not p then
        return
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
-- منطق الأبواب القديم: يقرب من الباب ويضغط Yes
-- هذا الجزء مستقل عن Auto-Yes العام، وموجود فقط لو
-- كنت تستخدمه سابقاً لفتح الأبواب العادية.
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
            windower.add_to_chat(200, '[DoorHelper] Found door: ' .. door.name)
            door_message_shown = true
        end

        poke(door)

        coroutine.schedule(function()
            select_yes_old(door)
            auto_busy = false
        end, 6.2)
    else
        auto_busy = false
    end
end)
