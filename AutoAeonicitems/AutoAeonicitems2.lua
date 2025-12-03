-- From the highest secrets.
-- Aeonicitems - Windower addon (with integrated AutoTrade for Aeonic NMs)
_addon.name     = 'AutoAeonicitems'
_addon.author   = 'Aragan'
_addon.version  = '2.2'
_addon.commands = {'AutoAeonicitems', 'aai'}

---------------------------------------------------------------
-- General Settings
---------------------------------------------------------------

-- Enable/disable the addon internally (alternative to state.Aeonicitems in GearSwap)
-- Customizable settings are automatically saved in data/settings.xml
local config = require('config')

local defaults = {
    auto_enabled    = true,  -- Enable/disable the addon by default
    delay           = 8,     -- Delay between purchase attempts for the same item
    price_increment = 10000, -- Amount to increase the price after each failed attempt
    delay_random    = false, -- Use random delay?
    delay_min       = 6,     -- Minimum delay when using random delay
    delay_max       = 11,    -- Maximum delay when using random delay
    item_overrides  = {},    -- Table for per-item settings (max_price / target)
}

local settings = config.load(defaults)

-- Actual working variables (loaded from settings)
local auto_enabled    = true
local delay           = settings.delay
local price_increment = settings.price_increment
local delay_random    = settings.delay_random
local delay_min       = settings.delay_min
local delay_max       = settings.delay_max
local item_overrides  = settings.item_overrides or {}
settings.item_overrides = item_overrides

-- Force auto_enabled ON at load, and persist it
settings.auto_enabled = true
config.save(settings)

local res = require('resources').items

-- Bags to search for items
local bag_ids = {
    "inventory", "safe", "safe2", "locker",
    "satchel", "sack", "case", "wardrobe",
}

---------------------------------------------------------------
-- Define AH groups
-- quantity here means:
--   0 = single (individual purchase)
--   1 = stack (bulk/stack purchase)
-- target_count = the final number of items required across all bags
---------------------------------------------------------------

local ah_groups = {

    ["Echa Zitah"] = {
        -- Tier I NMs
        {name = "Darksteel Ingot", quantity = 1, max_price = 100000, max_increment = 200000, target_count = 24},

        -- Tier II NMs
        {name = "Ethereal Incense", quantity = 1, max_price = 600000, max_increment = 800000, target_count = 15},
        {name = "Ayapec's Shell",   quantity = 1, max_price = 80000,  max_increment = 150000, target_count = 15},

        -- Tier III NMs
        {name = "Riftborn Boulder", quantity = 0, max_price = 2000,  max_increment = 10000,  target_count = 5},
        {name = "Beitetsu",         quantity = 0, max_price = 10000, max_increment = 50000,  target_count = 5},
        {name = "Pluton",           quantity = 0, max_price = 2000,  max_increment = 10000,  target_count = 5},

        -- HELM NMs
        {name = "Ashweed",       quantity = 0, max_price = 10000,  max_increment = 50000,  target_count = 3},
        {name = "Gravewood Log", quantity = 0, max_price = 190000, max_increment = 230000, target_count = 3},
        {name = "Duskcrawler",   quantity = 0, max_price = 40000,  max_increment = 80000,  target_count = 3},
    },

    ["Echa RuAun"] = {
        -- Tier I NMs
        {name = "Steel Ingot", quantity = 1, max_price = 100000, max_increment = 200000, target_count = 13},

        -- Tier II NMs
        {name = "Mhuufya's Beak",          quantity = 1, max_price = 350000, max_increment = 600000, target_count = 5},
        {name = "Vedrfolnir's Wing",       quantity = 1, max_price = 80000,  max_increment = 200000, target_count = 5},
        {name = "Tuft of Camahueto's Fur", quantity = 0, max_price = 60000,  max_increment = 150000, target_count = 5},
        {name = "Vidmapire's Claw",        quantity = 0, max_price = 80000,  max_increment = 200000, target_count = 5},
        {name = "Centurio's Armor",        quantity = 0, max_price = 120000, max_increment = 300000, target_count = 5},
        {name = "Azrael's Eye",            quantity = 1, max_price = 300000, max_increment = 400000, target_count = 5},

        -- Tier III NMs
        {name = "Yggdreant Root",          quantity = 0, max_price = 50000,  max_increment = 100000, target_count = 1},
        {name = "Waktza Crest",            quantity = 0, max_price = 600000, max_increment = 900000, target_count = 1},
        {name = "Cehuetzi Pelt",           quantity = 0, max_price = 700000, max_increment = 900000, target_count = 1},

        -- Ark Angels
        {name = "Ashen Crayfish",          quantity = 0, max_price = 40000,  max_increment = 100000, target_count = 3},
        {name = "Ashweed",                 quantity = 0, max_price = 10000,  max_increment = 80000,  target_count = 2},
        {name = "Gravewood Log",           quantity = 0, max_price = 190000, max_increment = 230000, target_count = 3},
        {name = "Duskcrawler",             quantity = 0, max_price = 50000,  max_increment = 800000, target_count = 2},
        {name = "Parchment",               quantity = 1, max_price = 150000, max_increment = 230000, target_count = 5},
    },

    ["Reisenjima"] = {
        -- Tier I NMs
        {name = "Behem. Leather", quantity = 1, max_price = 70000,  max_increment = 180000, target_count = 12},

        -- Tier III NMs (Level 145)
        {name = "Sovereign Behemoth's Hide", quantity = 0, max_price = 20000,  max_increment = 80000,  target_count = 1},
        {name = "Tolba's Shell",             quantity = 0, max_price = 40000,  max_increment = 100000, target_count = 1},
        {name = "Hidhaegg's Scale",          quantity = 0, max_price = 40000,  max_increment = 100000, target_count = 1},

        -- HELM NMs (Level 150)
        {name = "Ashweed",                    quantity = 0, max_price = 10000,  max_increment = 80000,  target_count = 6},
        {name = "Ashen Crayfish",             quantity = 0, max_price = 40000,  max_increment = 100000, target_count = 3},
        {name = "Bone Chip",                  quantity = 1, max_price = 10000,  max_increment = 100000, target_count = 10},
        {name = "Duskcrawler",                quantity = 0, max_price = 50000,  max_increment = 800000, target_count = 3},
        {name = "Flan Meat",                  quantity = 1, max_price = 200000, max_increment = 300000, target_count = 10},
        {name = "Gravewood Log",              quantity = 0, max_price = 160000, max_increment = 230000, target_count = 3},
        {name = "Titanite",                   quantity = 1, max_price = 200000, max_increment = 400000, target_count = 10},
        {name = "Void Crystal",               quantity = 1, max_price = 300000, max_increment = 500000, target_count = 9},
        {name = "Void Grass",                 quantity = 1, max_price = 200000, max_increment = 300000, target_count = 9},
        {name = "Voidsnapper",                quantity = 1, max_price = 200000, max_increment = 300000, target_count = 9},
        {name = "Black Pudding",              quantity = 0, max_price = 300000, max_increment = 500000, target_count = 1},
        {name = "Coalition Humus",            quantity = 0, max_price = 50000,  max_increment = 200000, target_count = 1},
        {name = "Leisure Table",              quantity = 0, max_price = 150000, max_increment = 300000, target_count = 1},
        {name = "Mistmelt",                   quantity = 0, max_price = 100000, max_increment = 300000, target_count = 1},
        {name = "Scarletite Ingot",           quantity = 0, max_price = 10000,  max_increment = 50000,  target_count = 1},
        {name = "Siren's Hair",               quantity = 0, max_price = 30000,  max_increment = 100000, target_count = 1},
        {name = "Scroll of Maiden's Virelai", quantity = 0, max_price = 400000, max_increment = 700000, target_count = 1},
        {name = "Scroll of Tornado",          quantity = 0, max_price = 50000,  max_increment = 100000, target_count = 1},
        {name = "Trump Card Case",            quantity = 0, max_price = 50000,  max_increment = 100000, target_count = 1},
        {name = "Vermihumus",                 quantity = 0, max_price = 50000,  max_increment = 200000, target_count = 1},
        {name = "Worm Mulch",                 quantity = 0, max_price = 400000, max_increment = 700000, target_count = 1},
    },
}

---------------------------------------------------------------
-- HELM names per group (for helm-only mode)
---------------------------------------------------------------

local helm_names = {
    ["Echa Zitah"] = {
        ["Ashweed"]       = true,
        ["Gravewood Log"] = true,
        ["Duskcrawler"]   = true,
    },
    ["Echa RuAun"] = {
        ["Ashen Crayfish"] = true,
        ["Ashweed"]        = true,
        ["Gravewood Log"]  = true,
        ["Duskcrawler"]    = true,
    },
    ["Reisenjima"] = {
        ["Ashweed"]                    = true,
        ["Ashen Crayfish"]             = true,
        ["Bone Chip"]                  = true,
        ["Duskcrawler"]                = true,
        ["Flan Meat"]                  = true,
        ["Gravewood Log"]              = true,
        ["Titanite"]                   = true,
        ["Void Crystal"]               = true,
        ["Void Grass"]                 = true,
        ["Voidsnapper"]                = true,
        ["Black Pudding"]              = true,
        ["Coalition Humus"]            = true,
        ["Leisure Table"]              = true,
        ["Mistmelt"]                   = true,
        ["Scarletite Ingot"]           = true,
        ["Siren's Hair"]               = true,
        ["Scroll of Maiden's Virelai"] = true,
        ["Scroll of Tornado"]          = true,
        ["Trump Card Case"]            = true,
        ["Vermihumus"]                 = true,
        ["Worm Mulch"]                 = true,
    },
}

---------------------------------------------------------------
-- Group aliases and Tier mapping
--  - group_aliases: shortcuts for zone names (Echa Zitah/Zitah/Zi/Z, etc.)
--  - tier_names:    which items belong to T1/T2/T3 per group
---------------------------------------------------------------

local group_aliases = {
    ["echa zitah"] = "Echa Zitah",
    ["zitah"]      = "Echa Zitah",
    ["zi"]         = "Echa Zitah",
    ["z"]          = "Echa Zitah",

    ["echa ruaun"] = "Echa RuAun",
    ["ruaun"]      = "Echa RuAun",
    ["ru"]         = "Echa RuAun",

    ["reisenjima"] = "Reisenjima",
    ["reis"]       = "Reisenjima",
    ["re"]         = "Reisenjima",
}

local function normalize_group_name(name)
    if not name then
        return nil
    end
    local key = name:lower()
    return group_aliases[key] or name
end

-- Tier mapping used for modes: t1 / t2 / t3
local tier_names = {
    ["Echa Zitah"] = {
        t1 = {
            ["Darksteel Ingot"] = true,
        },
        t2 = {
            ["Ethereal Incense"] = true,
            ["Ayapec's Shell"]   = true,
        },
        t3 = {
            ["Riftborn Boulder"] = true,
            ["Beitetsu"]         = true,
            ["Pluton"]           = true,
        },
    },
    ["Echa RuAun"] = {
        t1 = {
            ["Steel Ingot"] = true,
        },
        t2 = {
            ["Mhuufya's Beak"]          = true,
            ["Vedrfolnir's Wing"]       = true,
            ["Tuft of Camahueto's Fur"] = true,
            ["Vidmapire's Claw"]        = true,
            ["Centurio's Armor"]        = true,
            ["Azrael's Eye"]            = true,
        },
        t3 = {
            ["Yggdreant Root"] = true,
            ["Waktza Crest"]   = true,
            ["Cehuetzi Pelt"]  = true,
        },
    },
    ["Reisenjima"] = {
        t1 = {
            ["Behem. Leather"] = true,
        },
        t3 = {
            ["Sovereign Behemoth's Hide"] = true,
            ["Tolba's Shell"]             = true,
            ["Hidhaegg's Scale"]          = true,
        },
    },
}

-- Helper: does an item belong to the requested mode? (nil/all, helm, t1/t2/t3)
local function item_matches_mode(group_name, item_name, mode)
    if not mode or mode == "" then
        return true
    end

    mode = mode:lower()

    if mode == "helm" then
        return helm_names[group_name] and helm_names[group_name][item_name] or false
    end

    if mode == "t1" or mode == "t2" or mode == "t3" then
        local tmap = tier_names[group_name]
        if not tmap then
            return false
        end
        local tier_table = tmap[mode]
        return tier_table and tier_table[item_name] or false
    end

    -- unknown mode
    return false
end

---------------------------------------------------------------
-- Count item across all bags
---------------------------------------------------------------

local function get_item_count(name)
    local count     = 0
    local all_items = windower.ffxi.get_items()

    if not all_items then
        return 0
    end

    for _, bag_id in ipairs(bag_ids) do
        local bag = all_items[bag_id]
        if bag and type(bag) == 'table' then
            for _, item in pairs(bag) do
                if type(item) == 'table' and item.id and item.id > 0 then
                    local item_info = res[item.id]
                    if item_info and item_info.en:lower() == name:lower() then
                        count = count + (item.count or 1)
                    end
                end
            end
        end
    end

    return count
end

---------------------------------------------------------------
-- Single purchase step for a given item
---------------------------------------------------------------

local function purchase_step(item, target)
    if not auto_enabled then
        windower.add_to_chat(207, "[Aeonicitems] Aeonicitems is OFF.")
        return
    end

    local name         = item.name
    local target_count = target or (item.target_count or 1)
    local current      = get_item_count(name)
    local remaining    = math.max(target_count - current, 0)

    if remaining <= 0 then
        windower.add_to_chat(207,
            ("[Aeonicitems] Reached target for %s (total: %d)."):format(name, current))
        return
    end

    if item.max_price > item.max_increment then
        windower.add_to_chat(207,
            ("[Aeonicitems] Price already above max for %s, skipping."):format(name))
        return
    end

    -- quantity = mode (0 single / 1 stack)
    local mode      = item.quantity or 0
    local mode_text = (mode == 0) and "single" or "stack"

    ----------------------------------------------------------------
    -- If inventory is full, try to move this item with Itemizer
    --   Requires: Itemizer addon loaded (//lua load itemizer)
    --   Moves the item (if present) from inventory → case / sack / satchel
    ----------------------------------------------------------------
    local all_items = windower.ffxi.get_items()
    local inv_full  = false
    if all_items and all_items.inventory and type(all_items.inventory) == 'table' then
        local inv = all_items.inventory
        local max = inv.max or inv.max_capacity or 80
        local cnt = inv.count or inv.n or 0
        if max > 0 and cnt >= max then
            inv_full = true
        end
    end

    if inv_full then
        windower.add_to_chat(207,
            "[Aeonicitems] Inventory is FULL, sending Itemizer command for all items to sack/satchel, then retrying.")
        -- استخدم Itemizer لتحريك أي شيء من الشنطة إلى الشنط الثانوية
        windower.send_command('put * sack all;put * satchel all;put * case all')

        -- أعط Itemizer وقتاً بسيطاً يشتغل، ثم أعد المحاولة بدون تغيير السعر
        coroutine.schedule(function()
            purchase_step(item, target_count)
        end, 3)

        return
    end

    windower.send_command(
        ('input //ah buy "%s" %d %d'):format(name, mode, item.max_price)
    )
    windower.add_to_chat(207,
        ("[Aeonicitems] Attempting %s mode for %s at %d (remaining: %d)"):format(
            mode_text, name, item.max_price, remaining
        )
    )

    -- After 5 seconds, recalculate and decide whether to retry or stop
    coroutine.schedule(function()
        local new_count   = get_item_count(name)
        local still_need  = math.max(target_count - new_count, 0)

        if new_count >= target_count then
            windower.add_to_chat(207,
                ("[Aeonicitems] Obtained required %s (total: %d)."):format(name, new_count))
            return
        end

        ----------------------------------------------------------------
        -- Correct check here:
        -- If we are already at the maximum price (e.g., 230000)
        -- and we tried at this price but still didn't gather the required quantity → stop.
        ----------------------------------------------------------------
        if item.max_price >= item.max_increment then
            windower.add_to_chat(207,
                ("[Aeonicitems] Reached max price for %s (%d) and still missing %d. Stopping."):format(
                    name, item.max_price, still_need
                ))
            return
        end

        -- If we haven't reached the maximum price yet, increase the price for the next attempt
        item.max_price = math.min(item.max_price + price_increment, item.max_increment)

        windower.add_to_chat(207,
            ("[Aeonicitems] Increasing price for %s to %d and retrying."):format(
                name, item.max_price
            ))

        local step_delay = delay
        if delay_random then
            local dmin = delay_min or delay
            local dmax = delay_max or delay
            if dmax < dmin then
                dmin, dmax = dmax, dmin
            end
            step_delay = math.random(dmin, dmax)
        end

        coroutine.schedule(function()
            purchase_step(item, target_count)
        end, step_delay)
    end, 5)

end

---------------------------------------------------------------
-- Attempt to purchase an item to reach the target_count
---------------------------------------------------------------

local function attempt_purchase_item(item)
    if not auto_enabled then
        return
    end

    local name = item.name

    -- Apply specific settings for this item (if any)
    local override     = item_overrides[name]
    local target_count = (override and override.target_count) or item.target_count or 1
    local current      = get_item_count(name)

    if current >= target_count then
        windower.add_to_chat(207,
            ("[Aeonicitems] Already have %d of %s, skipping."):format(current, name))
        return
    end

    local needed = target_count - current
    windower.add_to_chat(207,
        ("[Aeonicitems] Need %d of %s, starting purchase."):format(needed, name))

    -- ننسخ تعريف الآيتم لو فيه overrides للسعر عشان ما نعدّل الجدول الأصلي
    local effective_item = item
    if override and (override.max_price or override.target_count) then
        effective_item = {}
        for k, v in pairs(item) do
            effective_item[k] = v
        end
        if override.max_price then
            effective_item.max_price = override.max_price
        end
    end

    purchase_step(effective_item, target_count)
end

---------------------------------------------------------------
-- Purchase all items for a group, with optional mode:
--   mode = nil       → all items
--   mode = 'helm'    → HELM items only
--   mode = 't1/t2/t3' → specific tier only (if defined)
---------------------------------------------------------------

local function purchase_group(group_name, mode)
    mode = mode and mode:lower() or nil

    if not auto_enabled then
        auto_enabled = true
        settings.auto_enabled = true
        config.save(settings)
        windower.add_to_chat(207, "[Aeonicitems] Aeonicitems was OFF  now ENABLED automatically.")
    end

    local original = group_name
    group_name = normalize_group_name(group_name)

    local group = ah_groups[group_name]
    if not group then
        windower.add_to_chat(207,
            ("[Aeonicitems] Group '%s' not found."):format(tostring(original or group_name)))
        return
    end

    if mode == 'helm' then
        windower.add_to_chat(207,
            ("[Aeonicitems] Purchasing HELM items only from group '%s'."):format(group_name))
    elseif mode == 't1' or mode == 't2' or mode == 't3' then
        windower.add_to_chat(207,
            ("[Aeonicitems] Purchasing %s items only from group '%s'."):format(mode:upper(), group_name))
    else
        windower.add_to_chat(207,
            ("[Aeonicitems] Purchasing ALL items from group '%s'."):format(group_name))
    end

    -- عدّاد للآيتمات اللي فعلاً راح نشتريها
    local idx = 0

    for _, item in ipairs(group) do
        if item_matches_mode(group_name, item.name, mode) then
            idx = idx + 1
            coroutine.schedule(function()
                attempt_purchase_item(item)
            end, (idx - 1) * delay)   -- First item delay = 0, second = delay, etc...
        end
    end
end

---------------------------------------------------------------
-- AutoTrade groups (NPC trades for Aeonic NMs)
--   Uses the same logical zone names (Echa Zitah / Echa RuAun / Reisenjima)
--   and targets a single NPC per zone.
---------------------------------------------------------------

local trade_groups = {
    ["Echa Zitah"] = {
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

    ["Echa RuAun"] = {
        npc = "Dremi",
        nms = {
            -- Tier I NMs
            { nm = "Asida",           command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Bia",             command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Emputa",          command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Khon",            command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Khun",            command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Ma",              command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Met",             command = 'TradeNPC 1 "Steel Ingot"' },
            { nm = "Peirithoos",      command = 'TradeNPC 1 "Steel Ingot"' },
            { nm = "Ruea",            command = 'TradeNPC 1 "Steel Ingot"' },
            { nm = "Sava Savanovic",  command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Tenodera",        command = 'TradeNPC 2 "Steel Ingot"' },
            { nm = "Wasserspeier",    command = 'TradeNPC 2 "Steel Ingot"' },

            -- Tier II NMs
            { nm = "Amymone",         command = 'TradeNPC 5 "Mhuufya\'s Beak"' },
            { nm = "Hanbi",           command = 'TradeNPC 5 "Azrael\'s Eye"' },
            { nm = "Kammavaca",       command = 'TradeNPC 5 "Vedrfolnir\'s Wing"' },
            { nm = "Naphula",         command = 'TradeNPC 5 "Tuft of Camahueto\'s Fur"' },
            { nm = "Palila",          command = 'TradeNPC 5 "Vidmapire\'s Claw"' },
            { nm = "Yilan",           command = 'TradeNPC 5 "Centurio\'s Armor"' },

            -- Tier III NMs
            { nm = "Duke Vepar",      command = 'TradeNPC 1 "Yggdreant Root"' },
            { nm = "Pakecet",         command = 'TradeNPC 1 "Waktza Crest"' },
            { nm = "Vir\'ava",        command = 'TradeNPC 1 "Cehuetzi Pelt"' },

            -- Ark Angels
            { nm = "Ark Angel EV",    command = 'TradeNPC 1 "Ashen Crayfish" 1 "Ashweed" 1 "Illuminink" 1 "Parchment"' },
            { nm = "Ark Angel GK",    command = 'TradeNPC 1 "Ashen Crayfish" 1 "Gravewood Log" 1 "Illuminink" 1 "Parchment"' },
            { nm = "Ark Angel HM",    command = 'TradeNPC 1 "Ashweed" 1 "Gravewood Log" 1 "Illuminink" 1 "Parchment"' },
            { nm = "Ark Angel MR",    command = 'TradeNPC 1 "Ashen Crayfish" 1 "Duskcrawler" 1 "Illuminink" 1 "Parchment"' },
            { nm = "Ark Angel TT",    command = 'TradeNPC 1 "Duskcrawler" 1 "Gravewood Log" 1 "Illuminink" 1 "Parchment"' },

            -- Heavenly Beasts
            { nm = "Byakko",          command = 'TradeNPC 3 "Byakko Scrap"' },
            { nm = "Genbu",           command = 'TradeNPC 3 "Genbu Scrap"' },
            { nm = "Kirin",           command = 'TradeNPC 5 "Byakko Scrap" 5 "Genbu Scrap" 5 "Seiryu Scrap" 5 "Suzaku Scrap"' },
            { nm = "Seiryu",          command = 'TradeNPC 3 "Seiryu Scrap"' },
            { nm = "Suzaku",          command = 'TradeNPC 3 "Suzaku Scrap"' },
        },
    },

    ["Reisenjima"] = {
        npc = "Shiftrix",
        nms = {
            -- Tier I NMs (Level 129)
            { nm = "Belphegor",               command = 'TradeNPC 1 "Behem. Leather"' },
            { nm = "Crom Dubh",               command = 'TradeNPC 1 "Behem. Leather"' },
            { nm = "Dazzling Dolores",        command = 'TradeNPC 1 "Behem. Leather"' },
            { nm = "Golden Kist",             command = 'TradeNPC 1 "Behem. Leather"' },
            { nm = "Kabandha",                command = 'TradeNPC 1 "Behem. Leather"' },
            { nm = "Mauve-wristed Gomberry",  command = 'TradeNPC 1 "Behem. Leather"' },
            { nm = "Oryx",                    command = 'TradeNPC 1 "Behem. Leather"' },
            { nm = "Sabotender Royal",        command = 'TradeNPC 1 "Behem. Leather"' },
            { nm = "Sang Buaya",              command = 'TradeNPC 1 "Behem. Leather"' },
            { nm = "Selkit",                  command = 'TradeNPC 1 "Behem. Leather"' },
            { nm = "Taelmoth the Diremaw",    command = 'TradeNPC 1 "Behem. Leather"' },
            { nm = "Zduhac",                  command = 'TradeNPC 1 "Behem. Leather"' },

            -- Tier II NMs (Level 135)
            { nm = "Bashmu",                  command = 'TradeNPC 1 "Gramk-Droog\'s Grand Coffer"' },
            { nm = "Gajasimha",               command = 'TradeNPC 1 "Ignor-Mnt\'s Grand Coffer"' },
            { nm = "Ironside",                command = 'TradeNPC 1 "Durs-Vike\'s Grand Coffer"' },
            { nm = "Old Shuck",               command = 'TradeNPC 1 "Liij-Vok\'s Grand Coffer"' },
            { nm = "Sarsaok",                 command = 'TradeNPC 1 "Tryl-Wuj\'s Grand Coffer"' },
            { nm = "Strophadia",              command = 'TradeNPC 1 "Ymmr-Ulvid\'s Grand Coffer"' },

            -- Tier III NMs (Level 145)
            { nm = "Maju",                    command = 'TradeNPC 1 "Sovereign Behemoth\'s Hide"' },
            { nm = "Neak",                    command = 'TradeNPC 1 "Tolba\'s Shell"' },
            { nm = "Yakshi",                  command = 'TradeNPC 1 "Hidhaegg\'s Scale"' },

            -- HELM NMs (Level 150)
            { nm = "Albumen",                 command = 'TradeNPC 3 "Ashweed" 3 "Void Grass" 1 "Vermihumus" 1 "Coalition Humus"' },
            { nm = "Erinys",                  command = 'TradeNPC 3 "Voidsnapper" 3 "Ashweed" 1 "Mistmelt" 1 "Scroll of Tornado"' },
            { nm = "Onychophora",             command = 'TradeNPC 3 "Void Crystal" 3 "Void Grass" 10 "Titanite" 1 "Worm Mulch"' },
            { nm = "Schah",                   command = 'TradeNPC 3 "Voidsnapper" 3 "Gravewood Log" 1 "Leisure Table" 1 "Trump Card Case"' },
            { nm = "Teles",                   command = 'TradeNPC 3 "Void Crystal" 3 "Voidsnapper" 1 "Scroll of Maiden\'s Virelai" 1 "Siren\'s Hair"' },
            { nm = "Vinipata",                command = 'TradeNPC 3 "Void Crystal" 3 "Duskcrawler" 1 "Bone Chip" 1 "Scarletite Ingot"' },
            { nm = "Zerde",                   command = 'TradeNPC 3 "Void Grass" 3 "Ashen Crayfish" 10 "Flan Meat" 1 "Black Pudding"' },
        },
    },
}

-- Runtime state for AutoTrade
local running       = false
local current_group = nil
local current_index = 1
local trade_delay   = 10   -- seconds between trades
local trade_timer   = 0

-- Start auto trade
local function start_autotrade(group_name)
    if running then
        windower.add_to_chat(207, "[AutoTrade] Already running.")
        return
    end

    if not group_name then
        windower.add_to_chat(207, "[AutoTrade] Usage: //aai autotrade <zitah|ruaun|reisenjima>")
        return
    end

    local original = group_name
    group_name = normalize_group_name(group_name)

    local group = trade_groups[group_name]
    if not group then
        windower.add_to_chat(207, "[AutoTrade] No group found: " .. tostring(original))
        return
    end

    local target = windower.ffxi.get_mob_by_name(group.npc)
    if not target or not target.valid_target or not target.is_npc or target.distance > 35 then
        windower.add_to_chat(207, "[AutoTrade] NPC not found or too far: " .. group.npc)
        return
    end

    running       = true
    current_group = group_name
    current_index = 1
    trade_timer   = os.clock() + 0.5

    -- Target NPC once (game will keep it as last target)
    windower.send_command('input /targetnpc')
    windower.add_to_chat(207, "[AutoTrade] Targeting NPC: " .. group.npc)
end

-- Stop trading
local function stop_autotrade()
    if running then
        windower.add_to_chat(207, "[AutoTrade] Stopped.")
    end
    running       = false
    current_group = nil
    current_index = 1
end

---------------------------------------------------------------
-- Addon commands
---------------------------------------------------------------

-- أوامر الإضافة: on / off / toggle / status / set / item / listgroups / buygroup / buyall / autotrade / help
windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = command and command:lower() or ''

    -----------------------------------------------------------
    -- AutoTrade commands (integrated)
    -----------------------------------------------------------
    if command == 'autotrade' then
        local group_name = args[1]
        if not group_name then
            windower.add_to_chat(207, "[AutoTrade] Usage: //aai autotrade <zitah|ruaun|reisenjima|zi|ru|re>")
            return
        end
        start_autotrade(group_name)

    elseif command == 'stoptrade' or (command == 'stop' and running) then
        stop_autotrade()

    elseif command == 'listtrade' then
        windower.add_to_chat(207, "[AutoTrade] Available trade groups:")
        for name, data in pairs(trade_groups) do
            windower.add_to_chat(207, ("  - %s (NPC: %s)"):format(name, data.npc))
        end

    -----------------------------------------------------------
    -- on / off / toggle / status
    -----------------------------------------------------------
    elseif command == 'on' then
        auto_enabled = true
        settings.auto_enabled = true
        config.save(settings)
        windower.add_to_chat(207, "[Aeonicitems] Aeonicitems ENABLED.")

    elseif command == 'off' then
        auto_enabled = false
        settings.auto_enabled = false
        config.save(settings)
        windower.add_to_chat(207, "[Aeonicitems] Aeonicitems DISABLED.")

    elseif command == 'toggle' then
        auto_enabled = not auto_enabled
        settings.auto_enabled = auto_enabled
        config.save(settings)
        windower.add_to_chat(207,
            "[Aeonicitems] Aeonicitems is now " .. (auto_enabled and "ENABLED" or "DISABLED") .. ".")

    elseif command == 'status' then
        windower.add_to_chat(207,
            ("[Aeonicitems] Status: %s | delay=%d | price_increment=%d"):format(
                auto_enabled and "ENABLED" or "DISABLED", delay, price_increment
            ))

    -----------------------------------------------------------
    -- set options: delay / price_increment
    -----------------------------------------------------------
    elseif command == 'set' then
        -- Usage examples:
        --   //aai set delay 8
        --   //aai set delay_min 6
        --   //aai set delay_max 11
        --   //aai set delay_random 1
        --   //aai set price_increment 20000
        local key     = args[1] and args[1]:lower() or nil
        local raw_val = args[2]

        if not key or raw_val == nil then
            windower.add_to_chat(207, "[Aeonicitems] Usage: //aai set delay <number> | set price_increment <number> | set delay_min <number> | set delay_max <number> | set delay_random 0/1")
            return
        end

        local num_val = tonumber(raw_val)

        if key == 'delay' then
            if not num_val then
                windower.add_to_chat(207, "[Aeonicitems] delay must be a number.")
                return
            end
            delay = num_val
            settings.delay = num_val
            windower.add_to_chat(207,
                ("[Aeonicitems] delay set to %d seconds."):format(delay))

        elseif key == 'delay_min' then
            if not num_val then
                windower.add_to_chat(207, "[Aeonicitems] delay_min must be a number.")
                return
            end
            delay_min = num_val
            settings.delay_min = num_val
            windower.add_to_chat(207,
                ("[Aeonicitems] delay_min set to %d."):format(delay_min))

        elseif key == 'delay_max' then
            if not num_val then
                windower.add_to_chat(207, "[Aeonicitems] delay_max must be a number.")
                return
            end
            delay_max = num_val
            settings.delay_max = num_val
            windower.add_to_chat(207,
                ("[Aeonicitems] delay_max set to %d."):format(delay_max))

        elseif key == 'delay_random' then
            local v = tostring(raw_val):lower()
            local flag
            if v == '1' or v == 'on' or v == 'true' then
                flag = true
            elseif v == '0' or v == 'off' or v == 'false' then
                flag = false
            else
                flag = (num_val and num_val ~= 0) or false
            end

            delay_random = flag
            settings.delay_random = flag
            windower.add_to_chat(207,
                ("[Aeonicitems] delay_random is now %s. Range = [%d, %d]."):format(
                    delay_random and "ON" or "OFF",
                    delay_min or delay, delay_max or delay
                ))

        elseif key == 'price_increment' or key == 'step' or key == 'price' or key == 'increment' then
            if not num_val then
                windower.add_to_chat(207, "[Aeonicitems] price_increment must be a number.")
                return
            end
            price_increment = num_val
            settings.price_increment = num_val
            windower.add_to_chat(207,
                ("[Aeonicitems] price_increment set to %d."):format(price_increment))
        else
            windower.add_to_chat(207, "[Aeonicitems] Unknown setting. Use: delay, price_increment, delay_min, delay_max, delay_random.")
            return
        end

        settings.auto_enabled = auto_enabled
        config.save(settings)

    -----------------------------------------------------------
    -- per-item overrides: //aai item "Name" ...
    -----------------------------------------------------------
    elseif command == 'item' then
        if #args == 0 then
            windower.add_to_chat(207, "[Aeonicitems] Item override usage:")
            windower.add_to_chat(207, "  //aai item \"Name\" set max_price <number>")
            windower.add_to_chat(207, "  //aai item \"Name\" set target <number>")
            windower.add_to_chat(207, "  //aai item \"Name\" show")
            windower.add_to_chat(207, "  //aai item \"Name\" reset")
            windower.add_to_chat(207, "  //aai item resetall")
            return
        end

        -- reset all overrides
        if args[1] and type(args[1]) == 'string' and args[1]:lower() == 'resetall' then
            settings.item_overrides = {}
            item_overrides = settings.item_overrides
            config.save(settings)
            windower.add_to_chat(207, "[Aeonicitems] All item overrides reset.")
            return
        end

        local item_name = args[1]
        local action    = args[2] and args[2]:lower() or 'show'

        if not item_name or item_name == '' then
            windower.add_to_chat(207, "[Aeonicitems] Usage: //aai item \"Name\" set max_price <number> | set target <number> | show | reset | resetall")
            return
        end

        if action == 'show' then
            local ov = item_overrides[item_name]
            if not ov then
                windower.add_to_chat(207,
                    ("[Aeonicitems] No overrides for '%s'."):format(item_name))
            else
                windower.add_to_chat(207,
                    ("[Aeonicitems] Item '%s' overrides   max_price=%s, target=%s"):format(
                        item_name,
                        ov.max_price or "default",
                        ov.target_count or "default"
                    ))
            end
            return

        elseif action == 'reset' then
            item_overrides[item_name] = nil
            settings.item_overrides = item_overrides
            config.save(settings)
            windower.add_to_chat(207,
                ("[Aeonicitems] Overrides for '%s' have been cleared."):format(item_name))
            return

        elseif action == 'set' then
            local field = args[3] and args[3]:lower() or nil
            local raw   = args[4]
            local num   = raw and tonumber(raw) or nil
            if not field or not raw or not num then
                windower.add_to_chat(207, "[Aeonicitems] Usage: //aai item \"Name\" set max_price <number> | set target <number>")
                return
            end

            local ov = item_overrides[item_name]
            if not ov then
                ov = {}
                item_overrides[item_name] = ov
            end

            if field == 'max_price' then
                ov.max_price = num
                windower.add_to_chat(207,
                    ("[Aeonicitems] Item '%s': max_price override set to %d."):format(item_name, num))
            elseif field == 'target' or field == 'target_count' then
                ov.target_count = num
                windower.add_to_chat(207,
                    ("[Aeonicitems] Item '%s': target override set to %d."):format(item_name, num))
            else
                windower.add_to_chat(207, "[Aeonicitems] Unknown item field. Use 'max_price' or 'target'.")
                return
            end

            settings.item_overrides = item_overrides
            config.save(settings)
            return
        else
            windower.add_to_chat(207, "[Aeonicitems] Unknown item action. Use: set / show / reset / resetall.")
            return
        end

    -----------------------------------------------------------
    -- gather: pull all Aeonic items from storage to inventory
    -----------------------------------------------------------
    elseif command == 'gather' or command == 'pull' or command == 'getitems' then
        windower.add_to_chat(207, "[Aeonicitems] Gathering all Aeonic items from storage to inventory (city/mog zones recommended).")
        gather_all_aeonic_items()

    -----------------------------------------------------------
    -- help
    -----------------------------------------------------------
    elseif command == 'help' then
        windower.add_to_chat(207, "[Aeonicitems] Help:")
        windower.add_to_chat(207, "  Basic:")
        windower.add_to_chat(207, "    //aai on | off | toggle | status")
        windower.add_to_chat(207, "  Global settings:")
        windower.add_to_chat(207, "    //aai set delay <number>           - Base delay between attempts when random is OFF.")
        windower.add_to_chat(207, "    //aai set delay_min <number>       - Min delay when delay_random is ON.")
        windower.add_to_chat(207, "    //aai set delay_max <number>       - Max delay when delay_random is ON.")
        windower.add_to_chat(207, "    //aai set delay_random 0|1         - Enable/disable random delay mode.")
        windower.add_to_chat(207, "    //aai set price_increment <number> - Step to increase price on failure.")
        windower.add_to_chat(207, "  Per-item settings:")
        windower.add_to_chat(207, "    //aai item \"Name\" set max_price <number> - Override starting max_price for this item.")
        windower.add_to_chat(207, "    //aai item \"Name\" set target <number>    - Override target count for this item.")
        windower.add_to_chat(207, "    //aai item \"Name\" show                  - Show overrides for this item.")
        windower.add_to_chat(207, "    //aai item \"Name\" reset                 - Clear overrides for this item.")
        windower.add_to_chat(207, "    //aai item resetall                      - Clear ALL item overrides.")
        windower.add_to_chat(207, "  Buying groups (Auction House):")
        windower.add_to_chat(207, "    //aai listgroups                             - List all available AH groups.")
        windower.add_to_chat(207, "    //aai buygroup \"Group\" [helm|t1|t2|t3]   - Buy from one group (aliases: buy / b / bg).")
        windower.add_to_chat(207, "    //aai buyall [helm|t1|t2|t3]                 - Buy from ALL groups with optional filter.")
        windower.add_to_chat(207, "  AutoTrade (NPC pop-item trades):")
        windower.add_to_chat(207, "    //aai autotrade <GroupAlias>                - Trade pops to NPC for that group.")
        windower.add_to_chat(207, "       Aliases: Zitah/Zi/Z, RuAun/Ru, Reisenjima/Reis/Re.")
        windower.add_to_chat(207, "    //aai stoptrade                             - Stop current AutoTrade loop.")
        windower.add_to_chat(207, "    //aai listtrade                             - List all AutoTrade groups & NPCs.")
        windower.add_to_chat(207, "  Examples:")
        windower.add_to_chat(207, "    //aai set delay 8")
        windower.add_to_chat(207, "    //aai set delay_min 6")
        windower.add_to_chat(207, "    //aai set delay_max 11")
        windower.add_to_chat(207, "    //aai set delay_random 1")
        windower.add_to_chat(207, "    //aai item \"Gravewood Log\" set max_price 220000")
        windower.add_to_chat(207, "    //aai item \"Gravewood Log\" set target 6")
        windower.add_to_chat(207, "    //aai item \"Gravewood Log\" show")
        windower.add_to_chat(207, "    //aai item \"Gravewood Log\" reset")
        windower.add_to_chat(207, "    //aai item resetall")
        windower.add_to_chat(207, "    //aai buygroup \"Echa Zitah\" t1")
        windower.add_to_chat(207, "    //aai buygroup \"Zitah\" t2")
        windower.add_to_chat(207, "    //aai buy \"Ru\" helm")
        windower.add_to_chat(207, "    //aai bg \"Re\" t3")
        windower.add_to_chat(207, "    //aai buyall t3")
        windower.add_to_chat(207, "    //aai autotrade zitah")
        windower.add_to_chat(207, "    //aai autotrade re")
        windower.add_to_chat(207, "  Groups & aliases:")
        windower.add_to_chat(207, "    Echa Zitah    Echa Zitah / Zitah / Zi / Z")
        windower.add_to_chat(207, "    Echa RuAun    Echa RuAun / RuAun / Ru")
        windower.add_to_chat(207, "    Reisenjima    Reisenjima / Reis / Re")
    -----------------------------------------------------------
    -- listgroups
    -----------------------------------------------------------
    elseif command == 'listgroups' or command == 'groups' then
        windower.add_to_chat(207, "[Aeonicitems] Available AH groups:")
        for name, _ in pairs(ah_groups) do
            windower.add_to_chat(207, "  - " .. name)
        end

    -----------------------------------------------------------
    -- buygroup "Group" [helm|t1|t2|t3] (aliases: buy/b/bg)
    -----------------------------------------------------------
    elseif command == 'buygroup' or command == 'buy' or command == 'b' or command == 'bg' then
        if #args == 0 then
            windower.add_to_chat(207, "[Aeonicitems] Usage:")
            windower.add_to_chat(207, "  //aai buygroup \"Group\" [helm|t1|t2|t3]  (aliases: buy / b / bg)")
            windower.add_to_chat(207, "  Examples:")
            windower.add_to_chat(207, "    //aai buygroup \"Echa Zitah\" t1")
            windower.add_to_chat(207, "    //aai buygroup \"Zitah\" t2")
            windower.add_to_chat(207, "    //aai buy \"Ru\" helm")
            windower.add_to_chat(207, "    //aai bg \"Re\" t3")
            return
        end

        local group_name = args[1]
        local mode       = args[2] and args[2]:lower() or nil

        if mode and mode ~= 'helm' and mode ~= 't1' and mode ~= 't2' and mode ~= 't3' then
            windower.add_to_chat(207, "[Aeonicitems] Unknown mode. Use: helm | t1 | t2 | t3")
            return
        end

        purchase_group(group_name, mode)

    -----------------------------------------------------------
    -- buyall [helm|t1|t2|t3]
    -----------------------------------------------------------
    elseif command == 'buyall' then
        local mode = args[1] and args[1]:lower() or nil

        if mode and mode ~= 'helm' and mode ~= 't1' and mode ~= 't2' and mode ~= 't3' then
            windower.add_to_chat(207, "[Aeonicitems] Usage: //aai buyall [helm|t1|t2|t3]")
            return
        end

        if mode == 'helm' then
            windower.add_to_chat(207, "[Aeonicitems] Buying HELM items from ALL groups.")
        elseif mode == 't1' or mode == 't2' or mode == 't3' then
            windower.add_to_chat(207,
                ("[Aeonicitems] Buying %s items from ALL groups."):format(mode:upper()))
        else
            windower.add_to_chat(207, "[Aeonicitems] Buying ALL items from ALL groups.")
        end

        local gidx = 0
        for group_name, _ in pairs(ah_groups) do
            gidx = gidx + 1
            coroutine.schedule(function()
                purchase_group(group_name, mode)
            end, (gidx - 1) * delay)
        end

    -----------------------------------------------------------
    -- default / summary
    -----------------------------------------------------------
    else
        windower.add_to_chat(207, "[Aeonicitems] Commands (quick):")
        windower.add_to_chat(207, "  //aai on | off | toggle | status")
        windower.add_to_chat(207, "  //aai set delay <number>")
        windower.add_to_chat(207, "  //aai set delay_min <number>")
        windower.add_to_chat(207, "  //aai set delay_max <number>")
        windower.add_to_chat(207, "  //aai set delay_random 0|1")
        windower.add_to_chat(207, "  //aai set price_increment <number>")
        windower.add_to_chat(207, "  //aai item \"Name\" set max_price <number>")
        windower.add_to_chat(207, "  //aai item \"Name\" set target <number>")
        windower.add_to_chat(207, "  //aai item \"Name\" show | reset | resetall")
        windower.add_to_chat(207, "  //aai listgroups")
        windower.add_to_chat(207, "  //aai buygroup \"Group\" [helm|t1|t2|t3]  (alias: buy/b/bg)")
        windower.add_to_chat(207, "  //aai buyall [helm|t1|t2|t3]")
        windower.add_to_chat(207, "  //aai autotrade <GroupAlias>")
        windower.add_to_chat(207, "  //aai help")
    end
end)

---------------------------------------------------------------

---------------------------------------------------------------
-- Helpers for AutoTrade: check inventory & pull pops from storage
---------------------------------------------------------------

-- أكياس التخزين (نستثني inventory لأنه هدفنا نسحب منها فقط)
local storage_locations = {
    'safe', 'safe2', 'locker', 'satchel', 'sack', 'case',
    'wardrobe', 'wardrobe2', 'wardrobe3', 'wardrobe4',
    'wardrobe5', 'wardrobe6', 'wardrobe7', 'wardrobe8',
}

-- عدّ عدد آيتم معيّن داخل الـ inventory فقط (للـ TradeNPC)
local function get_inventory_count_for_trade(item_name)
    local items = windower.ffxi.get_items()
    if not items or not items.inventory then
        return 0
    end

    local inv   = items.inventory
    local total = 0

    for slot, entry in ipairs(inv) do
        if type(entry) == 'table' and entry.id and entry.id > 0 then
            local info = res[entry.id]
            if info and info.en and info.en:lower() == item_name:lower() then
                total = total + (entry.count or 1)
            end
        end
    end

    return total
end

-- سحب آيتم من حقائب التخزين إلى الشنطة بعدد معيّن
local function move_item_from_storage(item_name, needed)
    if needed <= 0 then
        return
    end

    local items = windower.ffxi.get_items()
    if not items then
        return
    end

    for _, loc in ipairs(storage_locations) do
        local bag = items[loc]
        if bag and type(bag) == 'table' then
            for slot, entry in ipairs(bag) do
                if type(entry) == 'table' and entry.id and entry.id > 0 then
                    local info = res[entry.id]
                    if info and info.en and info.en:lower() == item_name:lower() then
                        local move_count = math.min(entry.count or 1, needed)

                        -- نرسل أمر /get لكل قطعة نحتاجها (أعداد بوبات الآيونك قليلة غالباً)
                        for i = 1, move_count do
                            windower.send_command(('get "%s" %s'):format(item_name, loc)
                            )
                        end

                        needed = needed - move_count
                        if needed <= 0 then
                            return
                        end
                    end
                end
            end
        end
    end
end

-- قبل كل TradeNPC: نحاول التأكد أن جميع البوبات موجودة في الـ inventory
local function fetch_trade_items_for_nm(nm_data)
    if not nm_data or not nm_data.command then
        return
    end

    local cmd = nm_data.command

    -- نقرأ كل الأزواج: رقم + اسم آيتم داخل ""
    for qty_str, item_name in cmd:gmatch('(%d+)%s+"([^"]+)"') do
        local needed = tonumber(qty_str) or 0
        if needed > 0 and item_name and item_name ~= "" then
            local have  = get_inventory_count_for_trade(item_name)
            local short = needed - have
            if short > 0 then
                move_item_from_storage(item_name, short)
            end
        end
    end

-- سحب كل آيتمات الآيونك من حقائب التخزين إلى الشنطة
local function gather_all_aeonic_items()
    -- نبني لستة بأسماء كل الآيتمات المستخدمة في المود (كل الجروبات)
    local names = {}

    for _, group in pairs(ah_groups) do
        for _, item in ipairs(group) do
            if item.name then
                names[item.name] = true
            end
        end
    end

    windower.add_to_chat(207, "[Aeonicitems] Gathering all Aeonic items from storage to inventory...")

    for item_name, _ in pairs(names) do
        -- نطلب عدد كبير عشان يسحب كل الموجود (الدالة نفسها توقف لما تخلص القطع)
        move_item_from_storage(item_name, 9999)
    end

    windower.add_to_chat(207, "[Aeonicitems] Done gather request (some /get may fail if inventory is full or mog not accessible).")
end

end

-- prerender event loop for executing AutoTrade NPC trades
---------------------------------------------------------------
windower.register_event('prerender', function()
    if running and current_group and os.clock() >= trade_timer then
        local group_data = trade_groups[current_group]
        if not group_data then
            stop_autotrade()
            return
        end

        if current_index <= #group_data.nms then
            local nm_data  = group_data.nms[current_index]
            local npc_name = group_data.npc

            -- قبل كل عملية TradeNPC نسحب البوبات من التخزين إذا ما كانت في الشنطة
            fetch_trade_items_for_nm(nm_data)

            -- Retarget NPC (just in case)
            windower.send_command('input /targetnpc')
            -- Use TradeNPC (external addon or alias) بعد 2 ثانية لإعطاء وقت لأوامر /get
            windower.send_command('@wait 2;' .. nm_data.command)
            windower.add_to_chat(207,
                string.format("[AutoTrade] Trading pops for %s  NPC: %s", nm_data.nm, npc_name))

            current_index = current_index + 1
            trade_timer   = os.clock() + trade_delay
        else
            windower.add_to_chat(207,
                string.format("[AutoTrade] Completed group '%s'.", current_group))
            stop_autotrade()
        end
    end
end)
