--It is from the highest secrets.
-- AutoTrade Addon: Escha/Reisenjima NM pops via single NPC trades

_addon.name     = 'AutoTrade'
_addon.author   = 'Aragan'
_addon.version  = '1.0'
_addon.commands = {'autotrade', 'at'}

require('tables')
require('strings')

-- جدول الأيتمات (لو احتجناه لاحقاً للبحث بالـ ID بدال الاسم)
local res_items = require('resources').items

----------------------------------------------------------
-- إعداد مجموعات الـ Trade لكل منطقة
----------------------------------------------------------
local trade_groups = {
    -- Escha - Zi'Tah (NPC: Affi)
    ["zitah"] = {
        npc = "Affi",
        nms = {
            { nm = "Aglaophotis",      command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Angrboda",         command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Cunnast",          command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Ferrodon",         command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Gestalt",          command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Gulltop",          command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Lustful Lydia",    command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Revetaur",         command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Tangata Manu",     command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Vidala",           command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Vyala",            command = 'TradeNPC 2 "Darksteel Ingot"' },
            { nm = "Wepwawet",         command = 'TradeNPC 2 "Darksteel Ingot"' },

            { nm = "Brittlis",         command = 'TradeNPC 5 "Ethereal Incense"' },
            { nm = "Ionos",            command = 'TradeNPC 5 "Ayapec\'s Shell"' },
            { nm = "Kamohoalii",       command = 'TradeNPC 5 "Ayapec\'s Shell"' },
            { nm = "Nosoi",            command = 'TradeNPC 5 "Ayapec\'s Shell"' },
            { nm = "Sensual Sandy",    command = 'TradeNPC 5 "Ethereal Incense"' },
            { nm = "Umdhlebi",         command = 'TradeNPC 5 "Ethereal Incense"' },

            { nm = "Fleetstalker",     command = 'TradeNPC 5 "Riftborn Boulder"' },
            { nm = "Shockmaw",         command = 'TradeNPC 5 "Beitetsu"' },
            { nm = "Urmahlullu",       command = 'TradeNPC 5 "Pluton"' },

            { nm = "Alpluachra, Bucca & Puca", command = 'TradeNPC 1 "Ashweed" 1 "Gravewood Log"' },
            { nm = "Blazewing",        command = 'TradeNPC 1 "Duskcrawler" 1 "Gravewood Log"' },
            { nm = "Pazuzu",           command = 'TradeNPC 1 "Ashweed" 1 "Duskcrawler"' },
            { nm = "Wrathare",         command = 'TradeNPC 1 "Ashweed" 1 "Duskcrawler" 1 "Gravewood Log"' },
        },
    },

    -- Escha - Ru'Aun (NPC: Dremi)
    ["ruaun"] = {
        npc = "Dremi",
        nms = {
            -- Tier I NMs
            { nm = "Asida",        command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Bia",          command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Emputa",       command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Khon",         command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Khun",         command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Ma",           command = 'TradeNPC 2 "Steel Ingot"' }, -- كانت ناقصة "
            { nm = "Met",          command = 'TradeNPC 1 "Steel Ingot"' },
            { nm = "Peirithoos",   command = 'TradeNPC 1 "Steel Ingot"' },
            { nm = "Ruea",         command = 'TradeNPC 1 "Steel Ingot"' },
            { nm = "Sava Savanovic", command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Tenodera",     command = 'TradeNPC 2 "Steel Ingot"' }, -- عدلت ESteel → Steel
            { nm = "Wasserspeier", command = 'TradeNPC 2 "Steel Ingot"' },

            -- Tier II NMs
            { nm = "Amymone",      command = 'TradeNPC 5 "Mhuufya\'s Beak"' },
            { nm = "Hanbi",        command = 'TradeNPC 5 "Azrael\'s Eye"' },
            { nm = "Kammavaca",    command = 'TradeNPC 5 "Vedrfolnir\'s Wing"' },
            { nm = "Naphula",      command = 'TradeNPC 5 "Tuft of Camahueto\'s Fur"' },
            { nm = "Palila",       command = 'TradeNPC 5 "Vidmapire\'s Claw"' },
            { nm = "Yilan",        command = 'TradeNPC 5 "Centurio\'s Armor"' },

            -- Tier III NMs
            { nm = "Duke Vepar",   command = 'TradeNPC 1 "Yggdreant Root"' },
            { nm = "Pakecet",      command = 'TradeNPC 1 "Waktza Crest"' },
            { nm = "Vir\'ava",     command = 'TradeNPC 1 "Cehuetzi Pelt"' },

            -- Ark Angels
            { nm = "Ark Angel EV", command = 'TradeNPC 1 "Ashen Crayfish" 1 "Ashweed" 1 "Illuminink" 1 "Parchment"' },
            { nm = "Ark Angel GK", command = 'TradeNPC 1 "Ashen Crayfish" 1 "Gravewood Log" 1 "Illuminink" 1 "Parchment"' },
            { nm = "Ark Angel HM", command = 'TradeNPC 1 "Ashweed" 1 "Gravewood Log" 1 "Illuminink" 1 "Parchment"' },
            { nm = "Ark Angel MR", command = 'TradeNPC 1 "Ashen Crayfish" 1 "Duskcrawler" 1 "Illuminink" 1 "Parchment"' },
            { nm = "Ark Angel TT", command = 'TradeNPC 1 "Duskcrawler" 1 "Gravewood Log" 1 "Illuminink" 1 "Parchment"' },

            -- Heavenly Beasts
            { nm = "Byakko",       command = 'TradeNPC 3 "Byakko Scrap"' },
            { nm = "Genbu",        command = 'TradeNPC 3 "Genbu Scrap"' },
            { nm = "Kirin",        command = 'TradeNPC 5 "Byakko Scrap" 5 "Genbu Scrap" 5 "Seiryu Scrap" 5 "Suzaku Scrap"' }, -- عدلت 51 → 5
            { nm = "Seiryu",       command = 'TradeNPC 3 "Seiryu Scrap"' },
            { nm = "Suzaku",       command = 'TradeNPC 3 "Suzaku Scrap"' },
        },
    },

    -- Reisenjima (NPC: Shiftrix)
    ["reisenjima"] = {
        npc = "Shiftrix",
        nms = {
            -- Tier I NMs (Level 129)
            { nm = "Belphegor",               command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Crom Dubh",               command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Dazzling Dolores",        command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Golden Kist",             command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Kabandha",                command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Mauve-wristed Gomberry",  command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Oryx",                    command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Sabotender Royal",        command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Sang Buaya",              command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Selkit",                  command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Taelmoth the Diremaw",    command = 'TradeNPC 1 "Behem. Leather";' },
            { nm = "Zduhac",                  command = 'TradeNPC 1 "Behem. Leather";' },

            -- Tier II NMs (Level 135)
            { nm = "Bashmu",       command = 'TradeNPC 1 "Gramk-Droog\'s Grand Coffer";' },
            { nm = "Gajasimha",    command = 'TradeNPC 1 "Ignor-Mnt\'s Grand Coffer";' },
            { nm = "Ironside",     command = 'TradeNPC 1 "Durs-Vike\'s Grand Coffer";' },
            { nm = "Old Shuck",    command = 'TradeNPC 1 "Liij-Vok\'s Grand Coffer";' },
            { nm = "Sarsaok",      command = 'TradeNPC 1 "Tryl-Wuj\'s Grand Coffer";' },
            { nm = "Strophadia",   command = 'TradeNPC 1 "Ymmr-Ulvid\'s Grand Coffer";' }, -- صححت الـ case والمسافة

            -- Tier III NMs (Level 145)
            { nm = "Maju",         command = 'TradeNPC 1 "Sovereign Behemoth\'s Hide";' },
            { nm = "Neak",         command = 'TradeNPC 1 "Tolba\'s Shell";' },
            { nm = "Yakshi",       command = 'TradeNPC 1 "Hidhaegg\'s Scale";' },

            -- HELM NMs (Level 150)
            { nm = "Albumen",      command = 'TradeNPC 3 "Ashweed" 3 "Void Grass" 1 "Vermihumus" 1 "Coalition Humus";' },
            { nm = "Erinys",       command = 'TradeNPC 3 "Voidsnapper" 3 "Ashweed" 1 "mistmelt" 1 "Tornado";' },
            { nm = "Onychophora",  command = 'TradeNPC 3 "Void Crystal" 3 "Void Grass" 10 "titanite" 1 "Worm Mulch";' },
            { nm = "Schah",        command = 'TradeNPC 3 "Voidsnapper" 3 "Gravewood Log" 1 "leisure table" 1 "trump card case";' },
            { nm = "Teles",        command = 'TradeNPC 3 "Void Crystal" 3 "Voidsnapper" 1 "maiden\'s virelai" 1 "siren\'s hair";' },
            { nm = "Vinipata",     command = 'TradeNPC 3 "Void Crystal" 3 "Duskcrawler" 1 "bone chip" 1 "scarletite ingot";' },
            { nm = "Zerde",        command = 'TradeNPC 3 "Void Grass" 3 "Ashen Crayfish" 10 "Flan Meat" 1 "Black Pudding";' },
        },
    },
}

----------------------------------------------------------
-- متغيّرات حالة الإضافة
----------------------------------------------------------
local running       = false   -- هل الأوتو شغال الآن؟
local current_group = nil     -- اسم الجروب الحالي (مفتاح الجدول)
local current_index = 1       -- رقم الـ NM الحالي داخل الجروب
local trade_delay   = 10      -- الفترة بين كل Trade والثاني (بالثواني)
local trade_timer   = 0       -- توقيت التنفيذ القادم (os.clock)

----------------------------------------------------------
-- دالة لكتابة رسائل في الشات
----------------------------------------------------------
local function log(msg)
    windower.add_to_chat(207, '[AutoTrade] ' .. msg)
end

----------------------------------------------------------
-- تشغيل الأوتو تريد لجروب معيّن
----------------------------------------------------------
local function start_autotrade(group_name)
    if running then
        log('Already running. Use "stop" first if you want to restart.')
        return
    end

    if not group_name then
        log('No group name given.')
        return
    end

    group_name = group_name:lower()
    local group = trade_groups[group_name]
    if not group then
        log('Unknown group: ' .. tostring(group_name))
        return
    end

    -- نتأكد أن الـ NPC موجود وقريب
    local npc = windower.ffxi.get_mob_by_name(group.npc)
    if not npc or not npc.valid_target or not npc.is_npc or npc.distance > 36 then
        log('NPC not found or too far: ' .. group.npc)
        return
    end

    running       = true
    current_group = group_name
    current_index = 1
    trade_timer   = os.clock() + 0.5

    -- نستهدف الـ NPC مرة واحدة في البداية
    windower.send_command('input /targetnpc')
    log(string.format('Started group "%s" (NPC: %s).', group_name, group.npc))
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
end

----------------------------------------------------------
-- طباعة قائمة الجروبات المتاحة
----------------------------------------------------------
local function list_groups()
    log('Available groups:')
    for key, data in pairs(trade_groups) do
        windower.add_to_chat(207, string.format('  - %s (NPC: %s)', key, data.npc))
    end
end

----------------------------------------------------------
-- أوامر الإضافة من داخل اللعبة
-- أمثلة:
--   //autotrade zitah
--   //autotrade ruaun
--   //autotrade reisenjima
--   //autotrade stop
--   //autotrade list
----------------------------------------------------------
windower.register_event('addon command', function(cmd, ...)
    cmd = cmd and cmd:lower() or ''
    local args = {...}

    if cmd == '' then
        log('Commands: //autotrade <zitah|ruaun|reisenjima> | stop | list')
        return
    end

    if cmd == 'stop' then
        stop_autotrade()
        return
    elseif cmd == 'list' then
        list_groups()
        return
    end

    -- إذا كان cmd نفسه اسم الجروب (zitah / ruaun / reisenjima)
    if trade_groups[cmd] then
        start_autotrade(cmd)
        return
    end

    -- خيار بديل: //autotrade start <group>
    if cmd == 'start' then
        local g = args[1] and args[1]:lower() or nil
        if not g then
            log('Usage: //autotrade start <zitah|ruaun|reisenjima>')
            return
        end
        start_autotrade(g)
        return
    end

    -- لو كتب شيء غريب
    log('Unknown command: ' .. cmd)
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

    local group_data = trade_groups[current_group]
    if not group_data then
        stop_autotrade()
        return
    end

    -- لو خلصنا كل الـ NMs في الجروب
    if current_index > #group_data.nms then
        log(string.format('Completed group "%s".', current_group))
        stop_autotrade()
        return
    end

    local nm_data  = group_data.nms[current_index]
    local npc_name = group_data.npc

    -- نتأكد أن الـ NPC ما زال موجود وقريب
    local npc = windower.ffxi.get_mob_by_name(npc_name)
    if not npc or not npc.valid_target or not npc.is_npc or npc.distance > 36 then
        log('NPC lost or too far: ' .. npc_name .. ' (stopping).')
        stop_autotrade()
        return
    end

    -- نعيد target للـ NPC، ثم ننفذ أمر الـ TradeNPC
    windower.send_command('input /targetnpc')
    windower.send_command('@wait 1;' .. nm_data.command)

    log(string.format('Trading for NM: %s → NPC: %s', nm_data.nm, npc_name))

    current_index = current_index + 1
    trade_timer   = os.clock() + trade_delay
end)
