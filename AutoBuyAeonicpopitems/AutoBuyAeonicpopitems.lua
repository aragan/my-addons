-- From the highest secrets.
-- AutoBuyAeonicpopitems - Windower addon
-- Explanation and comments are in English only, and chat messages are in English only.
-- addon for Buy Aeonic pop items auto from AuctionHous .
_addon.name     = 'AutoBuyAeonicpopitems'
_addon.author   = 'Aragan'
_addon.version  = '2.0'
_addon.commands = {'autoah', 'autobuyah', 'aba'}

---------------------------------------------------------------
-- General Settings
---------------------------------------------------------------

-- Enable/disable the addon internally (alternative to state.AutoBuyAeonicpopitems in GearSwap)
local auto_enabled   = true
local delay          = 8       -- Delay between each purchase_step attempt
local price_increment = 10000  -- Amount to increase the price each time we fail

local res = require('resources').items

-- الشنط اللي نبحث فيها عن الآيتمات
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
        {name = "Steel Ingot", quantity = 0, max_price = 100000, max_increment = 200000, target_count = 13},

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
        {name = "Bone Chip",                  quantity = 0, max_price = 10000,  max_increment = 100000, target_count = 10},
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
-- HELM list for each group (for the command: buygroup "xxx" helm)

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
-- Function: Calculate the number of pieces available in all bags
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
-- Function: Single purchase step for a specific item

-- quantity = 0 → single mode
-- quantity = 1 → stack mode
---------------------------------------------------------------

local function purchase_step(item, target)
    if not auto_enabled then
        windower.add_to_chat(207, "[AutoAH] AutoBuyAeonicpopitems is OFF.")
        return
    end

    local name         = item.name
    local target_count = target or (item.target_count or 1)
    local current      = get_item_count(name)
    local remaining    = math.max(target_count - current, 0)

    if remaining <= 0 then
        windower.add_to_chat(207,
            ("[AutoAH] Reached target for %s (total: %d)."):format(name, current))
        return
    end

    if item.max_price > item.max_increment then
        windower.add_to_chat(207,
            ("[AutoAH] Price reached max for %s, skipping."):format(name))
        return
    end

    -- Here, quantity means mode (0 single / 1 stack)
    local mode = item.quantity or 0
    local mode_text = (mode == 0) and "single" or "stack"

    windower.send_command(
        ('input //ah buy "%s" %d %d'):format(name, mode, item.max_price)
    )
    windower.add_to_chat(207,
        ("[AutoAH] Attempting %s mode for %s at %d (remaining: %d)"):format(
            mode_text, name, item.max_price, remaining
        )
    )

    -- After 5 seconds, recalculate and decide whether to retry or stop
    coroutine.schedule(function()
        local new_count   = get_item_count(name)
        local still_need  = math.max(target_count - new_count, 0)

        if new_count >= target_count then
            windower.add_to_chat(207,
                ("[AutoAH] Obtained required %s (total: %d)."):format(name, new_count))
            return
        end

        ----------------------------------------------------------------
        -- Correct check here:
        -- If we are already at the maximum price (e.g., 230000)
        -- and we tried at this price but still didn't gather the required quantity → stop.
        ----------------------------------------------------------------
        if item.max_price >= item.max_increment then
            windower.add_to_chat(207,
                ("[AutoAH] Reached max price for %s (%d) and still missing %d. Stopping."):format(
                    name, item.max_price, still_need
                ))
            return
        end

        -- If we haven't reached the maximum price yet, increase the price for the next attempt
        item.max_price = math.min(item.max_price + price_increment, item.max_increment)

        windower.add_to_chat(207,
            ("[AutoAH] Increasing price for %s to %d and retrying."):format(
                name, item.max_price
            ))

        coroutine.schedule(function()
            purchase_step(item, target_count)
        end, delay)
    end, 5)

end

---------------------------------------------------------------
-- Attempt to purchase an item to reach the target_count
---------------------------------------------------------------

local function attempt_purchase_item(item)
    if not auto_enabled then
        return
    end

    local name         = item.name
    local target_count = item.target_count or 1
    local current      = get_item_count(name)

    if current >= target_count then
        windower.add_to_chat(207,
            ("[AutoAH] Already have %d of %s, skipping."):format(current, name))
        return
    end

    local needed = target_count - current
    windower.add_to_chat(207,
        ("[AutoAH] Need %d of %s, starting purchase."):format(needed, name))

    purchase_step(item, target_count)
end

---------------------------------------------------------------
-- Purchase a full group (with an optional mode: helm)

---------------------------------------------------------------

local function purchase_group(group_name, mode)
    mode = mode and mode:lower() or nil

    if not auto_enabled then
        windower.add_to_chat(207, "[AutoAH] AutoBuyAeonicpopitems is OFF. Use //autoah on.")
        return
    end

    local group = ah_groups[group_name]
    if not group then
        windower.add_to_chat(207,
            ("[AutoAH] Group '%s' not found."):format(tostring(group_name)))
        return
    end

    if mode == 'helm' then
        windower.add_to_chat(207,
            ("[AutoAH] Purchasing HELM items only from group '%s'."):format(group_name))
    else
        windower.add_to_chat(207,
            ("[AutoAH] Purchasing ALL items from group '%s'."):format(group_name))
    end

    local idx = 0  -- عدّاد للآيتمات اللي فعلاً راح نشتريها

    for _, item in ipairs(group) do
        if not mode or mode ~= 'helm'
           or (helm_names[group_name] and helm_names[group_name][item.name]) then

            idx = idx + 1
            coroutine.schedule(function()
                attempt_purchase_item(item)
            end, (idx - 1) * delay)   -- First item delay = 0, second = delay, etc...
        end
    end

end

---------------------------------------------------------------
-- Addon commands

---------------------------------------------------------------

windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = command and command:lower() or ''

    if command == 'on' then
        auto_enabled = true
        windower.add_to_chat(207, "[AutoAH] AutoBuyAeonicpopitems ENABLED.")

    elseif command == 'off' then
        auto_enabled = false
        windower.add_to_chat(207, "[AutoAH] AutoBuyAeonicpopitems DISABLED.")

    elseif command == 'toggle' then
        auto_enabled = not auto_enabled
        windower.add_to_chat(207,
            "[AutoAH] AutoBuyAeonicpopitems is now "..(auto_enabled and "ENABLED" or "DISABLED")..".")

    elseif command == 'status' then
        windower.add_to_chat(207,
            ("[AutoAH] Status: %s | delay=%d | price_increment=%d"):format(
                auto_enabled and "ENABLED" or "DISABLED", delay, price_increment
            ))
    elseif command == 'help' then
        windower.add_to_chat(207, "[AutoAH] Help:")
        windower.add_to_chat(207, "  //autoah on - Enable the addon.")
        windower.add_to_chat(207, "  //autoah off - Disable the addon.")
        windower.add_to_chat(207, "  //autoah toggle - Toggle the addon on/off.")
        windower.add_to_chat(207, "  //autoah status - Show the current status of the addon.")
        windower.add_to_chat(207, "  //autoah listgroups - List all available item groups.")
        windower.add_to_chat(207, "  //autoah buygroup \"Group Name\" - Purchase all items in the specified group.")
        windower.add_to_chat(207, "  //autoah buygroup \"Group Name\" helm - Purchase only HELM items in the specified group.")
        windower.add_to_chat(207, "  //autoah buygroup \"Echa Zitah\"")
        windower.add_to_chat(207, "  //autoah buygroup \"Echa Zitah\" helm")
        windower.add_to_chat(207, "  //autoah buygroup \"Echa RuAun\"")
        windower.add_to_chat(207, "  //autoah buygroup \"Echa RuAun\" helm")
        windower.add_to_chat(207, "  //autoah buygroup \"Reisenjima\"")
        windower.add_to_chat(207, "  //autoah buygroup \"Reisenjima\" helm")  
        windower.add_to_chat(207, "  //autoah help - Show this help message.")
    elseif command == 'listgroups' or command == 'groups' then
        windower.add_to_chat(207, "[AutoAH] Available groups:")
        for name, _ in pairs(ah_groups) do
            windower.add_to_chat(207, "  - "..name)
        end

    elseif command == 'buygroup' then
        if #args == 0 then
            windower.add_to_chat(207, "[AutoAH] Usage:")
            windower.add_to_chat(207, "  //autoah buygroup \"Echa Zitah\"")
            windower.add_to_chat(207, "  //autoah buygroup \"Echa Zitah\" helm")
            windower.add_to_chat(207, "  //autoah buygroup \"Echa RuAun\"")
            windower.add_to_chat(207, "  //autoah buygroup \"Echa RuAun\" helm")
            windower.add_to_chat(207, "  //autoah buygroup \"Reisenjima\"")
            windower.add_to_chat(207, "  //autoah buygroup \"Reisenjima\" helm")            return
        end

        -- في ويندوور: "Echa Zitah" تجي في arg واحد بدون علامات تنصيص
        local group_name = args[1]
        local mode       = args[2] and args[2]:lower() or nil

        purchase_group(group_name, mode)

    else
        windower.add_to_chat(207, "[AutoAH] Commands:")
        windower.add_to_chat(207, "  //autoah on | off | toggle | status")
        windower.add_to_chat(207, "  //autoah listgroups")
        windower.add_to_chat(207, "  //autoah buygroup \"Echa Zitah\"")
        windower.add_to_chat(207, "  //autoah buygroup \"Echa Zitah\" helm")
        windower.add_to_chat(207, "  //autoah buygroup \"Echa RuAun\"")
        windower.add_to_chat(207, "  //autoah buygroup \"Echa RuAun\" helm")
        windower.add_to_chat(207, "  //autoah buygroup \"Reisenjima\"")
        windower.add_to_chat(207, "  //autoah buygroup \"Reisenjima\" helm")

    end
end)
