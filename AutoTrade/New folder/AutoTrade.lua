--It is from the highest secrets.
-- AutoTrade Addon: Escha/Reisenjima NM pops via single NPC trades
-- v1.3 - zone aliases + modes (all/t1/t2/t3/helm) + itemizer get

_addon.name     = 'AutoTrade'
_addon.author   = 'Aragan'
_addon.version  = '1.3'
_addon.commands = {'autotrade', 'at'}

require('tables')
require('strings')

config = require('config')

-- جدول الأيتمات (لو احتجناه لاحقاً للبحث بالـ ID بدال الاسم)
local res_items = require('resources').items

----------------------------------------------------------
-- إعدادات قابلة للحفظ
----------------------------------------------------------
local defaults = {
    trade_delay = 10,   -- الفترة بين كل Trade والثاني (بالثواني)
}

local settings = config.load(defaults)

----------------------------------------------------------
-- Aliases لأسماء المناطق (اختصارات)
----------------------------------------------------------
local zone_aliases = {
    -- Escha - Zi'Tah
    ["zitah"]       = "zitah",
    ["zi"]          = "zitah",
    ["z"]           = "zitah",
    ["echa zitah"]  = "zitah",
    ["escha zitah"] = "zitah",

    -- Escha - Ru'Aun
    ["ruaun"]       = "ruaun",
    ["ru"]          = "ruaun",
    ["er"]          = "ruaun",
    ["echa ruaun"]  = "ruaun",
    ["escha ruaun"] = "ruaun",

    -- Reisenjima
    ["reisenjima"] = "reisenjima",
    ["reis"]       = "reisenjima",
    ["r"]          = "reisenjima",
}

local function normalize_group_name(name)
    if not name then
        return nil
    end
    name = name:lower()
    return zone_aliases[name] or name
end

----------------------------------------------------------
-- إعداد مجموعات الـ Trade لكل منطقة
-- mode: "t1" / "t2" / "t3" / "helm"
----------------------------------------------------------
local trade_groups = {
    -- Escha - Zi'Tah (NPC: Affi)
    ["zitah"] = {
        npc = "Affi",
        nms = {
            -- Tier I
            { nm = "Aglaophotis",      mode = "t1",   command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Angrboda",         mode = "t1",   command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Cunnast",          mode = "t1",   command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Ferrodon",         mode = "t1",   command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Gestalt",          mode = "t1",   command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Gulltop",          mode = "t1",   command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Lustful Lydia",    mode = "t1",   command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Revetaur",         mode = "t1",   command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Tangata Manu",     mode = "t1",   command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Vidala",           mode = "t1",   command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Vyala",            mode = "t1",   command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Wepwawet",         mode = "t1",   command = 'TradeNPC 2 "Darksteel Ingot"' },

            -- Tier II
            { nm = "Brittlis",         mode = "t2",   command = 'TradeNPC 5 "Ethereal Incense"' },
            { nm = "Ionos",            mode = "t2",   command = 'TradeNPC 5 "Ayapec\'s Shell"' },
            { nm = "Kamohoalii",       mode = "t2",   command = 'TradeNPC 5 "Ayapec\'s Shell"' },
            { nm = "Nosoi",            mode = "t2",   command = 'TradeNPC 5 "Ayapec\'s Shell"' },
            { nm = "Sensual Sandy",    mode = "t2",   command = 'TradeNPC 5 "Ethereal Incense"' },
            { nm = "Umdhlebi",         mode = "t2",   command = 'TradeNPC 5 "Ethereal Incense"' },

            -- Tier III
            { nm = "Fleetstalker",     mode = "t3",   command = 'TradeNPC 5 "Riftborn Boulder"' },
            { nm = "Shockmaw",         mode = "t3",   command = 'TradeNPC 5 "Beitetsu"' },
            { nm = "Urmahlullu",       mode = "t3",   command = 'TradeNPC 5 "Pluton"' },

            -- HELM
            { nm = "Alpluachra, Bucca & Puca", mode = "helm", command = 'TradeNPC 1 "Ashweed" 1 "Gravewood Log"' },
            { nm = "Blazewing",        mode = "helm", command = 'TradeNPC 1 "Duskcrawler" 1 "Gravewood Log"' },
            { nm = "Pazuzu",           mode = "helm", command = 'TradeNPC 1 "Ashweed" 1 "Duskcrawler"' },
            { nm = "Wrathare",         mode = "helm", command = 'TradeNPC 1 "Ashweed" 1 "Duskcrawler" 1 "Gravewood Log"' },
        },
    },

    -- Escha - Ru'Aun (NPC: Dremi)
    ["ruaun"] = {
        npc = "Dremi",
        nms = {
            -- Tier I NMs
            { nm = "Asida",        mode = "t1", command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Bia",          mode = "t1", command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Emputa",       mode = "t1", command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Khon",         mode = "t1", command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Khun",         mode = "t1", command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Ma",           mode = "t1", command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Met",          mode = "t1", command = 'TradeNPC 1 "Steel Ingot"' },
            { nm = "Peirithoos",   mode = "t1", command = 'TradeNPC 1 "Steel Ingot"' },
            { nm = "Ruea",         mode = "t1", command = 'TradeNPC 1 "Steel Ingot"' },
            { nm = "Sava Savanovic", mode = "t1", command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Tenodera",     mode = "t1", command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Wasserspeier", mode = "t1", command = 'TradeNPC 2 "Steel Ingot"' },

            -- Tier II NMs
            { nm = "Amymone",      mode = "t2", command = 'TradeNPC 5 "Mhuufya\'s Beak"' },
            { nm = "Hanbi",        mode = "t2", command = 'TradeNPC 5 "Azrael\'s Eye"' },
            { nm = "Kammavaca",    mode = "t2", command = 'TradeNPC 5 "Vedrfolnir\'s Wing"' },
            { nm = "Naphula",      mode = "t2", command = 'TradeNPC 5 "Tuft of Camahueto\'s Fur"' },
            { nm = "Palila",       mode = "t2", command = 'TradeNPC 5 "Vidmapire\'s Claw"' },
            { nm = "Yilan",        mode = "t2", command = 'TradeNPC 5 "Centurio\'s Armor"' },

            -- Tier III NMs
            { nm = "Duke Vepar",   mode = "t3", command = 'TradeNPC 1 "Yggdreant Root"' },
            { nm = "Pakecet",      mode = "t3", command = 'TradeNPC 1 "Waktza Crest"' },
            { nm = "Vir\'ava",     mode = "t3", command = 'TradeNPC 1 "Cehuetzi Pelt"' },

            -- Ark Angels (HELM-style)
            { nm = "Ark Angel EV", mode = "helm", command = 'TradeNPC 1 "Ashen Crayfish" 1 "Ashweed" 1 "Illuminink" 1 "Parchment"' },
            { nm = "Ark Angel GK", mode = "helm", command = 'TradeNPC 1 "Ashen Crayfish" 1 "Gravewood Log" 1 "Illuminink" 1 "Parchment"' },
            { nm = "Ark Angel HM", mode = "helm", command = 'TradeNPC 1 "Ashweed" 1 "Gravewood Log" 1 "Illuminink" 1 "Parchment"' },
            { nm = "Ark Angel MR", mode = "helm", command = 'TradeNPC 1 "Ashen Crayfish" 1 "Duskcrawler" 1 "Illuminink" 1 "Parchment"' },
            { nm = "Ark Angel TT", mode = "helm", command = 'TradeNPC 1 "Duskcrawler" 1 "Gravewood Log" 1 "Illuminink" 1 "Parchment"' },

            -- Heavenly Beasts (HELM)
            { nm = "Byakko",       mode = "helm", command = 'TradeNPC 3 "Byakko Scrap"' },
            { nm = "Genbu",        mode = "helm", command = 'TradeNPC 3 "Genbu Scrap"' },
            { nm = "Kirin",        mode = "helm", command = 'TradeNPC 5 "Byakko Scrap" 5 "Genbu Scrap" 5 "Seiryu Scrap" 5 "Suzaku Scrap"' },
            { nm = "Seiryu",       mode = "helm", command = 'TradeNPC 3 "Seiryu Scrap"' },
            { nm = "Suzaku",       mode = "helm", command = 'TradeNPC 3 "Suzaku Scrap"' },
        },
    },

    -- Reisenjima (NPC: Shiftrix)
    ["reisenjima"] = {
        npc = "Shiftrix",
        nms = {
            -- Tier I NMs (Level 129)
            { nm = "Belphegor",               mode = "t1", command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Crom Dubh",               mode = "t1", command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Dazzling Dolores",        mode = "t1", command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Golden Kist",             mode = "t1", command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Kabandha",                mode = "t1", command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Mauve-wristed Gomberry",  mode = "t1", command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Oryx",                    mode = "t1", command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Sabotender Royal",        mode = "t1", command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Sang Buaya",              mode = "t1", command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Selkit",                  mode = "t1", command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Taelmoth the Diremaw",    mode = "t1", command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Zduhac",                  mode = "t1", command = 'TradeNPC 1 "Behem. Leather";' },

            -- Tier II NMs (Level 135)
            { nm = "Bashmu",       mode = "t2", command = 'TradeNPC 1 "Gramk-Droog\'s Grand Coffer";' },
            { nm = "Gajasimha",    mode = "t2", command = 'TradeNPC 1 "Ignor-Mnt\'s Grand Coffer";' },
            { nm = "Ironside",     mode = "t2", command = 'TradeNPC 1 "Durs-Vike\'s Grand Coffer";' },
            { nm = "Old Shuck",    mode = "t2", command = 'TradeNPC 1 "Liij-Vok\'s Grand Coffer";' },
            { nm = "Sarsaok",      mode = "t2", command = 'TradeNPC 1 "Tryl-Wuj\'s Grand Coffer";' },
            { nm = "Strophadia",   mode = "t2", command = 'TradeNPC 1 "Ymmr-Ulvid\'s Grand Coffer";' },

            -- Tier III NMs (Level 145)
            { nm = "Maju",         mode = "t3", command = 'TradeNPC 1 "Sovereign Behemoth\'s Hide";' },
            { nm = "Neak",         mode = "t3", command = 'TradeNPC 1 "Tolba\'s Shell";' },
            { nm = "Yakshi",       mode = "t3", command = 'TradeNPC 1 "Hidhaegg\'s Scale";' },

            -- HELM NMs (Level 150)
            { nm = "Albumen",      mode = "helm", command = 'TradeNPC 3 "Ashweed" 3 "Void Grass" 1 "Vermihumus" 1 "Coalition Humus";' },
            { nm = "Erinys",       mode = "helm", command = 'TradeNPC 3 "Voidsnapper" 3 "Ashweed" 1 "mistmelt" 1 "Tornado";' },
            { nm = "Onychophora",  mode = "helm", command = 'TradeNPC 3 "Void Crystal" 3 "Void Grass" 10 "titanite" 1 "Worm Mulch";' },
            { nm = "Schah",        mode = "helm", command = 'TradeNPC 3 "Voidsnapper" 3 "Gravewood Log" 1 "leisure table" 1 "trump card case";' },
            { nm = "Teles",        mode = "helm", command = 'TradeNPC 3 "Void Crystal" 3 "Voidsnapper" 1 "maiden\'s virelai" 1 "siren\'s hair";' },
            { nm = "Vinipata",     mode = "helm", command = 'TradeNPC 3 "Void Crystal" 3 "Duskcrawler" 1 "bone chip" 1 "scarletite ingot";' },
            { nm = "Zerde",        mode = "helm", command = 'TradeNPC 3 "Void Grass" 3 "Ashen Crayfish" 10 "Flan Meat" 1 "Black Pudding";' },
        },
    },
}

----------------------------------------------------------
-- متغيّرات حالة الإضافة
----------------------------------------------------------
local running       = false   -- هل الأوتو شغال الآن؟
local current_group = nil     -- اسم الجروب الحالي
local current_index = 1       -- رقم الـ NM الحالي داخل الجروب
local trade_delay   = settings.trade_delay or 10
local trade_timer   = 0       -- توقيت التنفيذ القادم (os.clock)
local current_mode  = "all"   -- "all" / "t1" / "t2" / "t3" / "helm"

----------------------------------------------------------
-- دوال مساعدة
----------------------------------------------------------
local function log(msg)
    windower.add_to_chat(207, '[AutoTrade] ' .. msg)
end

local function normalize_mode(mode)
    if not mode or mode == '' then
        return "all"
    end
    mode = mode:lower()
    if mode == "all" or mode == "t1" or mode == "t2" or mode == "t3" or mode == "helm" then
        return mode
    end
    return nil
end

local function mode_matches(nm_mode)
    if current_mode == "all" or current_mode == nil then
        return true
    end
    if not nm_mode then
        return false
    end
    return nm_mode == current_mode
end

-- استخراج أسماء الأيتمات من سطر الـ TradeNPC
-- مثال: 'TradeNPC 1 "Ashweed" 1 "Gravewood Log"' → {"Ashweed", "Gravewood Log"}
local function get_items_from_command(cmd)
    local set = {}
    local list = {}

    if not cmd or cmd == '' then
        return list
    end

    for name in cmd:gmatch('"(.-)"') do
        if name and name ~= '' and not set[name] then
            set[name] = true
            table.insert(list, name)
        end
    end

    return list
end

----------------------------------------------------------
-- تشغيل الأوتو تريد لجروب معيّن
----------------------------------------------------------
local function start_autotrade(group_name, mode)
    if running then
        log('Already running. Use "stop" first if you want to restart.')
        return
    end

    if not group_name then
        log('No group name given.')
        return
    end

    local gname = normalize_group_name(group_name)
    local group = trade_groups[gname]
    if not group then
        log('Unknown group: ' .. tostring(group_name))
        return
    end

    local m = normalize_mode(mode)
    if not m then
        log('Unknown mode: ' .. tostring(mode) .. ' (use all/t1/t2/t3/helm)')
        m = "all"
    end

    -- نتأكد أن الـ NPC موجود وقريب
    local npc = windower.ffxi.get_mob_by_name(group.npc)
    if not npc or not npc.valid_target or not npc.is_npc or npc.distance > 36 then
        log('NPC not found or too far: ' .. group.npc)
        return
    end

    running       = true
    current_group = gname
    current_index = 1
    trade_timer   = os.clock() + 0.5
    current_mode  = m

    windower.send_command('input /targetnpc')
    log(string.format('Started group "%s" (mode: %s, NPC: %s).', gname, current_mode, group.npc))
end

----------------------------------------------------------
-- إيقاف الأوتو تريد
----------------------------------------------------------
local function stop_autotrade()
    if running then
        log('Stopped.')
    end
    running       = false
    current_group = nil
    current_index = 1
    current_mode  = "all"
end

----------------------------------------------------------
-- طباعة قائمة الجروبات المتاحة
----------------------------------------------------------
local function list_groups()
    log('Available groups (modes: all, t1, t2, t3, helm):')
    for key, data in pairs(trade_groups) do
        windower.add_to_chat(207, string.format('  - %s (NPC: %s)', key, data.npc))
    end
end

----------------------------------------------------------
-- عرض الحالة الحالية
----------------------------------------------------------
local function show_status()
    local group  = current_group or '-'
    local index  = '-'
    local total  = '-'

    if current_group and trade_groups[current_group] then
        index = tostring(current_index)
        total = tostring(#trade_groups[current_group].nms)
    end

    log(string.format('Running: %s | Group: %s | Mode: %s | Index: %s/%s | Delay: %d sec',
        running and 'YES' or 'NO',
        group,
        current_mode or 'all',
        index,
        total,
        trade_delay))
end

----------------------------------------------------------
-- أوامر الإضافة من داخل اللعبة
-- أمثلة:
--   //autotrade zitah
--   //autotrade zitah t1
--   //autotrade ruaun helm
--   //autotrade stop
--   //autotrade list
--   //autotrade delay 8
--   //autotrade status
--   //autotrade first   → يضغط Enter يدوياً على منيو الوحوش (يتطلب plugin: setkey)
----------------------------------------------------------
windower.register_event('addon command', function(cmd, ...)
    cmd = cmd and cmd:lower() or ''
    local args = {...}

    -- الأوامر الأساسية
    if cmd == '' or cmd == 'help' then
        log('Commands:')
        log('  //autotrade <zone> [all|t1|t2|t3|helm]')
        log('     zone aliases: zitah/zi/z, ruaun/ru, reisenjima/reis/r')
        log('  //autotrade stop')
        log('  //autotrade list')
        log('  //autotrade delay <seconds>')
        log('  //autotrade status')
        log('  //autotrade first   → يضغط Enter يدوياً على منيو الوحوش (يتطلب plugin: setkey)')
        return
    end

    if cmd == 'stop' then
        stop_autotrade()
        return

    elseif cmd == 'list' then
        list_groups()
        return

    elseif cmd == 'delay' then
        local sec = tonumber(args[1] or '')
        if not sec then
            log('Current delay: ' .. trade_delay .. ' seconds.')
            return
        end
        if sec < 2 then
            sec = 2
        end
        trade_delay = sec
        settings.trade_delay = trade_delay
        config.save(settings)
        log('Trade delay set to ' .. trade_delay .. ' seconds.')
        return

    elseif cmd == 'status' then
        show_status()
        return

    elseif cmd == 'first' or cmd == 'menu' then
        -- أمر يدوي: يضغط Enter على القائمة الحالية (أول اختيار)
        windower.send_command('setkey enter down; wait 0.1; setkey enter up')
        return
    end

    -- إذا cmd كان اسم زون أو اختصارها مباشرة: //autotrade zitah t1
    local gname = normalize_group_name(cmd)
    if trade_groups[gname] then
        local mode = args[1]  -- الكلمة الثانية هي المود (اختياري)
        start_autotrade(gname, mode)
        return
    end

    -- خيار بديل: //autotrade start <zone> [mode]
    if cmd == 'start' then
        local zone = args[1]
        local mode = args[2]
        if not zone then
            log('Usage: //autotrade start <zone> [all|t1|t2|t3|helm]')
            return
        end
        start_autotrade(zone, mode)
        return
    end

    log('Unknown command: ' .. cmd)
end)

----------------------------------------------------------
-- إيقاف الأوتو تريد عند تغيير الزون
----------------------------------------------------------
windower.register_event('zone change', function()
    if running then
        log('Zone changed, stopping.')
        stop_autotrade()
    end
end)

----------------------------------------------------------
-- حلقة الـ prerender لتنفيذ التريدات وحدة وحدة
----------------------------------------------------------
windower.register_event('prerender', function()
    if not running or not current_group then
        return
    end

    if os.clock() < trade_timer then
        return
    end

    local group_data = current_group and trade_groups[current_group]
    if not group_data then
        stop_autotrade()
        return
    end

    local nms = group_data.nms
    local nm_data = nil
    local idx = current_index

    -- نبحث عن أول NM يطابق الـ mode الحالي
    while idx <= #nms do
        local cand = nms[idx]
        if mode_matches(cand.mode) then
            nm_data = cand
            break
        end
        idx = idx + 1
    end

    -- لو ما لقينا أي NM مطابق للـ mode → خلصنا
    if not nm_data then
        log(string.format('Completed group "%s" (mode: %s).', current_group, current_mode))
        stop_autotrade()
        return
    end

    local npc_name = group_data.npc

    -- نتأكد أن الـ NPC ما زال موجود وقريب
    local npc = windower.ffxi.get_mob_by_name(npc_name)
    if not npc or not npc.valid_target or not npc.is_npc or npc.distance > 36 then
        log('NPC lost or too far: ' .. npc_name .. ' (stopping).')
        stop_autotrade()
        return
    end

    --------------------------------------------------
    -- 1) نجهّز أوامر itemizer get لكل آيتم في الـ Trade
    --------------------------------------------------
    local item_names = get_items_from_command(nm_data.command)
    local cmd_str

    if #item_names > 0 then
        local first = true
        for _, iname in ipairs(item_names) do
            if first then
                cmd_str = string.format('get *%s all', iname)
                first = false
            else
                cmd_str = cmd_str .. string.format(';@wait 1;get *%s all', iname)
            end
        end
        -- بعد سحب الأيتمات، نستهدف الـ NPC ثم نعمل TradeNPC ثم نختار أول وحش تلقائياً
        cmd_str = cmd_str .. ';@wait 1;input /targetnpc;@wait 2;' .. nm_data.command .. ';@wait 3;setkey down down;wait 0.1;setkey down up; wait 0.1;setkey enter down; wait 0.1; setkey enter up'
    else
        -- لو ما فيه أيتمات في السطر (حالة نادرة) نستخدم السلوك القديم مع اختيار أول وحش
        cmd_str = 'input /targetnpc;@wait 1;' .. nm_data.command .. ';@wait 3;setkey enter down; wait 0.1; setkey enter up'
    end

    windower.send_command(cmd_str)

    log(string.format('Trading for NM: %s → NPC: %s (mode: %s)', nm_data.nm, npc_name, nm_data.mode or 'all'))

    current_index = idx + 1
    trade_timer   = os.clock() + trade_delay
end)
