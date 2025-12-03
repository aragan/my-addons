_addon.name     = 'gateway'
_addon.author   = 'Aragan'
_addon.version  = '1.0'
_addon.commands = {'gateway', 'gate'}

------------------------------------------------------------
-- تفعيل / تعطيل العمل من داخل اللعبة
------------------------------------------------------------
local enabled = true

-- دالة لطباعة الرسائل في الشات
local function log(msg)
    windower.add_to_chat(207, '[Gateway] ' .. msg)
end

------------------------------------------------------------
-- أوامر الإضافة:
--   //gateway          → يطبع الحالة
--   //gateway on       → تشغيل
--   //gateway off      → إيقاف
--   //gateway toggle   → تبديل
------------------------------------------------------------
windower.register_event('addon command', function(cmd, ...)
    cmd = cmd and cmd:lower() or ''

    if cmd == '' then
        log('Status: ' .. (enabled and 'ON' or 'OFF'))
        return
    end

    if cmd == 'on' then
        enabled = true
        log('Enabled.')
    elseif cmd == 'off' then
        enabled = false
        log('Disabled.')
    elseif cmd == 'toggle' then
        enabled = not enabled
        log('Toggled: ' .. (enabled and 'ON' or 'OFF'))
    else
        log('Commands: //gateway [on|off|toggle]')
    end
end)

------------------------------------------------------------
-- تحويل كود Ashita إلى Windower:
--  - نراقب incoming chunk 0x0E (Entity Update)
--  - البايت 0x20 (32) يمثل حالة الأنيميشن:
--      9 = باب مقفول
--      8 = باب مفتوح
--  - لو لقينا 9 نغيرها إلى 8 ونرجّع الباكيت المعدّل
------------------------------------------------------------
windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    -- لو الإضافة مطفية ما نسوي شيء
    if not enabled then
        return
    end

    -- نتأكد إنه مو باكيت مضاف من إضافة ثانية
    if injected then
        return
    end

    -- 0x0E = Entity Update
    if id ~= 0x0E then
        return
    end

    -- نستخدم النسخة المعدّلة لو فيه إضافات ثانية عدلتها قبلي، وإلا نستخدم الأصل
    local data = modified or original
    if not data then
        return
    end

    -- البايت رقم 0x20 (32 بالعشري)، في Lua الفهرسة تبدأ من 1
    local anim = data:byte(0x20)
    if not anim then
        return
    end

    -- لو مو باب مقفول (9) نطلع
    if anim ~= 9 then
        return
    end

    -- نغيّر الـ byte من 9 (door closed) إلى 8 (door open)
    local before = data:sub(1, 0x20 - 1)
    local after  = data:sub(0x20 + 1)
    local new    = before .. string.char(8) .. after

    -- نرجّع الباكيت المعدّل؛ ويندوور يمرره للكلانت بدل الأصلي
    return new
end)
