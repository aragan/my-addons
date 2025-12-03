-- AraganSortie Minimal HUD + Auto Sector + Bitzer Track
-- التعليقات بالعربي فقط / رسائل الشات بالإنجليزية فقط

_addon.name     = 'AraganSortieMinimal'
_addon.author   = 'Aragan + ChatGPT'
_addon.version  = '1.5'
_addon.commands = {'st'}

local packets = require('packets')
local texts   = require('texts')

------------------------------------------------------------
-- متغيرات رئيسية
------------------------------------------------------------
local enabled        = true      -- تشغيل / إيقاف الإضافة
local location       = 'A'       -- المنطقة الحالية A-H
local hunt_index     = 1         -- أي NM نتابع
local zone_1, zone_2, zone_3 = 133, 189, 275  -- زونات Sortie

local tracking_time        = os.clock()
local last_prerender       = 0         -- لتقليل تكرار التحديث (كل 0.1 ثانية مثلاً)
local last_bitzer_request  = 0         -- لتقليل إرسال طلبات 0x016

------------------------------------------------------------
-- نافذة HUD
------------------------------------------------------------
local tracking_window = texts.new("", {
    text={size=12,font='Consolas',red=0,green=255,blue=140,alpha=255},
    pos={x=980,y=40},
    bg={visible=true,red=0,green=0,blue=0,alpha=100},
})

------------------------------------------------------------
-- جدول الـ NMs
-- نخزن X/Y/Z عشان نعيد حساب المسافة والاتجاه كل فريم
------------------------------------------------------------
local mob_tracking = {
    [1]={name='Obdella',  index=144, dist='?', dir='?', x=nil,y=nil,z=nil},
    [2]={name='Porxie',   index=223, dist='?', dir='?', x=nil,y=nil,z=nil},
    [3]={name='Bhoot',    index=285, dist='?', dir='?', x=nil,y=nil,z=nil},
    [4]={name='Demin',    index=373, dist='?', dir='?', x=nil,y=nil,z=nil},
    [5]={name='Botulus',  index=427, dist='?', dir='?', x=nil,y=nil,z=nil},
    [6]={name='Ixion',    index=498, dist='?', dir='?', x=nil,y=nil,z=nil},
    [7]={name='Naraka',   index=552, dist='?', dir='?', x=nil,y=nil,z=nil},
    [8]={name='Tulittia', index=622, dist='?', dir='?', x=nil,y=nil,z=nil},
}

------------------------------------------------------------
-- جدول الـ Bitzer في البدروم E/F/G/H
------------------------------------------------------------
local bitzer_position = {
    [1] = {name='Diaphanous Bitzer (E)', index=837, x=0,y=0,z=0},
    [2] = {name='Diaphanous Bitzer (F)', index=838, x=0,y=0,z=0},
    [3] = {name='Diaphanous Bitzer (G)', index=839, x=0,y=0,z=0},
    [4] = {name='Diaphanous Bitzer (H)', index=840, x=0,y=0,z=0},
}

-- خريطة أي قطاع لأي بتزر
local basement_map = { E=1, F=2, G=3, H=4 }

------------------------------------------------------------
-- نقاط مميزة نستخدمها للكشف التلقائي عن الـ sector
-- (نقاط دخول البدروم + البتزر اللي فوق)
------------------------------------------------------------
local sector_markers = {
    -- Top bitzers
    {L='A', x=-460, y= 96,   z=-150},
    {L='B', x=-344, y=-20,   z=-150},
    {L='C', x=-460, y=-136,  z=-150},
    {L='D', x=-576, y=-20,   z=-150},

    -- Basement E/F/G/H (دخول البدروم)
    {L='E', x= 580,  y= 31.5, z=100},
    {L='F', x= 631.5,y=-20,   z=100},
    {L='G', x= 580,  y=-71.5, z=100},
    {L='H', x= 528.5,y=-20,   z=100},
}

------------------------------------------------------------
-- دوال مساعدة مختصرة
------------------------------------------------------------
local function me()    return windower.ffxi.get_mob_by_target('me') end
local function world() return windower.ffxi.get_info() end
local function newp(d,i,t) return packets.new(d,i,t) end
local function inject(p)   packets.inject(p) end
local function parse(d,p)  return packets.parse(d,p) end
local function log(m)      windower.add_to_chat(8,m) end

------------------------------------------------------------
-- حساب زاوية بين اللاعب والنقطة (x,y)
------------------------------------------------------------
local function angle_to(x, y)
    local m = me()
    if not m then return 0 end

    local dx = x - m.x
    local dy = y - m.y
    local a  = math.deg(math.atan2(dy, dx))
    if a < 0 then a = a + 360 end
    return a
end

------------------------------------------------------------
-- تحويل زاوية إلى اتجاه كاردينال بسيط
------------------------------------------------------------
local function cardinal(a)
    local d = {'E','NE','N','NW','W','SW','S','SE'}
    return d[math.floor(((a + 22.5) % 360) / 45) + 1]
end

------------------------------------------------------------
-- HUD: تحديث النص (يعرض NM + Bitzer لو موجود)
------------------------------------------------------------
local function update_HUD()
    if not enabled then
        tracking_window:hide()
        return
    end

    local lines = {}
    local m     = me()
    local t     = mob_tracking[hunt_index]

    -- سطر NM
    if t and t.x and t.y and m then
        local dist = math.sqrt((m.x - t.x)^2 + (m.y - t.y)^2)
        local ang  = angle_to(t.x, t.y)
        local dir  = cardinal(ang)
        table.insert(lines, string.format("[%s] %s | %.1f %s", location, t.name, dist, dir))
    elseif t then
        table.insert(lines, string.format("[%s] %s | ?? ??", location, t.name))
    else
        table.insert(lines, string.format("[%s] (no NM)", location))
    end

    -- سطر Bitzer للقطاعات E/F/G/H فقط
    local bidx = basement_map[location]
    if bidx then
        local b = bitzer_position[bidx]
        if b and m and (b.x ~= 0 or b.y ~= 0 or b.z ~= 0) then
            local dist = math.sqrt((m.x - b.x)^2 + (m.y - b.y)^2)
            local ang  = angle_to(b.x, b.y)
            local dir  = cardinal(ang)
            table.insert(lines, string.format("[Bitzer] %s | %.1f %s", b.name, dist, dir))
        else
            local name = (b and b.name) or ("Bitzer "..location)
            table.insert(lines, string.format("[Bitzer] %s | ?? ??", name))
        end
    end

    tracking_window:text(table.concat(lines, '\n'))
    tracking_window:show()
end

------------------------------------------------------------
-- تغيير القطاع + اختيار NM + طلب تتبع من السيرفر
------------------------------------------------------------
local function set_zone_auto(L)
    location   = L
    hunt_index = ({A=1,B=2,C=3,D=4,E=5,F=6,G=7,H=8})[L] or 1

    local t = mob_tracking[hunt_index]

    log(string.format("[Sortie %s] Tracking: %s", L, t.name))

    -- طلب تتبع NM من السيرفر (0x0F5)
    inject(newp('outgoing', 0x0F5, {Index = t.index}))
end

------------------------------------------------------------
-- كشف تلقائي للـ sector عن طريق الإحداثيات (قريب من marker معين)
------------------------------------------------------------
local function auto_detect_sector_from_pos(m)
    -- نصف قطر صغير (2 yalms) حوالين كل marker
    local radius2 = 2 * 2

    for _, mark in ipairs(sector_markers) do
        local dx = m.x - mark.x
        local dy = m.y - mark.y
        local dz = m.z - mark.z
        local dist2 = dx*dx + dy*dy + dz*dz

        if dist2 <= radius2 then
            if location ~= mark.L then
                set_zone_auto(mark.L)
            end
            return
        end
    end
end

------------------------------------------------------------
-- استلام الباكيتات:
-- 0x0F5 = تتبع NM
-- 0x0E  = تحديث NPC (نلتقط منه Bitzer)
------------------------------------------------------------
windower.register_event('incoming chunk', function(id, data)
    -- تتبع NM
    if id == 0x0F5 then
        local p = parse('incoming', data)
        local t = mob_tracking[hunt_index]
        if not t then return end
        if p.Index ~= t.index then return end

        if p.X and p.Y then
            -- حالة موت الـ NM: يرجع X,Y = 0
            if p.X == 0 and p.Y == 0 then
                t.x, t.y, t.z = nil, nil, nil
                t.dist = 'Dead'
                t.dir  = 'X'
                update_HUD()
                return
            end

            -- نخزن آخر إحداثيات معروفة
            t.x = p.X
            t.y = p.Y
            t.z = p.Z

            -- نحسب مسافة مبدئية
            local m = me()
            if m then
                t.dist = string.format("%.1f", math.sqrt((m.x - t.x)^2 + (m.y - t.y)^2))
                t.dir  = cardinal(angle_to(t.x, t.y))
            end

            update_HUD()
        end

    -- تحديث NPC → نستخدمه للـ Bitzer
    elseif id == 0x0E then
        local p = parse('incoming', data)
        if not p.Index then return end

        for i = 1, 4 do
            local b = bitzer_position[i]
            if p.Index == b.index then
                if p.X and p.Y and p.Z then
                    -- لو رجعت 0,0,0 نعتبره غير معروف
                    if p.X == 0 and p.Y == 0 and p.Z == 0 then
                        b.x, b.y, b.z = 0, 0, 0
                    else
                        b.x = p.X
                        b.y = p.Y
                        b.z = p.Z
                        log(string.format("[Sortie] Bitzer %s found at (%.1f, %.1f, %.1f)", b.name, b.x, b.y, b.z))
                    end
                    update_HUD()
                end
                break
            end
        end
    end
end)

------------------------------------------------------------
-- prerender: يحدث كل فريم → نعيد حساب المسافة/الاتجاه + نكشف الـ sector تلقائياً
-- ونطلب إحداثيات Bitzer لو كنا في E/F/G/H وما نعرف مكانه
------------------------------------------------------------
windower.register_event('prerender', function()
    if not enabled then return end

    local w = world()
    if not w or (w.zone ~= zone_1 and w.zone ~= zone_2 and w.zone ~= zone_3) then
        return
    end

    local m = me()
    if not m then return end

    --------------------------------------------------------
    -- أولاً: كشف تلقائي للـ sector حسب مكانك
    --------------------------------------------------------
    auto_detect_sector_from_pos(m)

    --------------------------------------------------------
    -- ثانياً: طلب مكان Bitzer في البدروم لو ما عندنا إحداثيات
    --------------------------------------------------------
    local now = os.clock()
    local bidx = basement_map[location]
    if bidx then
        local b = bitzer_position[bidx]
        if b and (b.x == 0 and b.y == 0 and b.z == 0) and (now - last_bitzer_request > 3) then
            -- نرسل 0x016 للـ Bitzer Target Index عشان السيرفر يرد علينا بإحداثياته
            inject(newp('outgoing', 0x016, {['Target Index'] = b.index}))
            last_bitzer_request = now
            log(string.format("[Sortie] Requesting Bitzer position for %s", b.name))
        end
    end

    --------------------------------------------------------
    -- ثالثاً: تحديث HUD كل 0.1 ثانية
    --------------------------------------------------------
    if now - last_prerender < 0.1 then
        return
    end
    last_prerender = now

    update_HUD()
end)

------------------------------------------------------------
-- zone change: لو دخلت/طلعت من Sortie
------------------------------------------------------------
windower.register_event('zone change', function()
    local w = world()
    if w and (w.zone == zone_1 or w.zone == zone_2 or w.zone == zone_3) then
        enabled = true
        set_zone_auto('A')  -- افتراضياً يبدأ يتتبع A
    else
        enabled = false
        tracking_window:hide()
    end
end)

------------------------------------------------------------
-- أوامر الإضافة:
-- //st off   -> إيقاف HUD
-- //st on    -> تشغيل + يبقى على القطاع الحالي
-- //st a–h   -> تغيير القطاع والـ NM يدوياً
------------------------------------------------------------
windower.register_event('addon command', function(cmd, arg1)
    if not cmd then return end
    cmd = cmd:lower()

    if cmd == 'off' then
        enabled = false
        tracking_window:hide()
        log("[Sortie] HUD OFF")

    elseif cmd == 'on' then
        enabled = true
        set_zone_auto(location)
        log("[Sortie] HUD ON")

    else
        local up = cmd:upper()
        if up:match('^[A-H]$') then
            enabled = true
            set_zone_auto(up)
        end
    end
end)

------------------------------------------------------------
-- load: عند تحميل الإضافة
------------------------------------------------------------
windower.register_event('load', function()
    local w = world()
    if w and (w.zone == zone_1 or w.zone == zone_2 or w.zone == zone_3) then
        enabled = true
        set_zone_auto('A')
    else
        enabled = false
        tracking_window:hide()
    end
end)
