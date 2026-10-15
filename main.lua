--[[
    Skill Hub v3.0 Ultra — Blox Fruits Edition (Update 24+)
    Features:
      • PvP & Players Tab      : Auto Kill Selected / PvP Hunt / Skill Aimbot Lock / Spectate / Tween to Player
      • Player Inspector + ESP : PvP status (PVP ON vs SAFE), Devil Fruit, Fighting Style, Sword, Gun, Level, Bounty
      • Undetected Bypass Fly  : invisible client float-pad + smooth delta CFrame stepping (no PlatformStand flag)
      • Fixed Sea Detection    : expanded PlaceId tables + live Workspace landmark/mob/level detection (never wrong Sea 1)
      • Fixed Fighting Styles  : reliable Melee/Fighting-Style detection + Humanoid:EquipTool fallback + full V1/V2/V3 switcher
      • Fruit Magnet + Gacha   : firetouchinterest fruit pull, Zioles roller with OriginalName auto-store, rarity Fruit ESP
      • Unique Utilities       : Walk on Water, Infinite Geppo, Infinite Energy, Dash No-CD, Mirage/Kitsune/Sea-Event tracker
      • Triple-Layer Fast Attack, Kill Aura, Hitbox Expander & Blox Fruits Anti-Cheat Disabler
    Repository: https://github.com/ameksi-web/Skill-Hub
]]

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Workspace           = game:GetService("Workspace")
local TweenService        = game:GetService("TweenService")
local UserInputService    = game:GetService("UserInputService")
local RunService          = game:GetService("RunService")
local VirtualUser         = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService     = game:GetService("TeleportService")
local CoreGui             = game:GetService("CoreGui")
local Lighting            = game:GetService("Lighting")
local StatsService        = game:GetService("Stats")
local Debris              = game:GetService("Debris")

local LocalPlayer         = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════════════════
--  CUSTOM VECTOR ICON REGISTRY (LUCIDE / FEATHER RBXASSETID + GLOW ASSETS)
-- ═══════════════════════════════════════════════════════════════════════════

local CustomIcons = {
    HubCrest    = "rbxassetid://10734950309", -- Sparkles / Crest
    AutoFarm    = "rbxassetid://10734975692", -- Crossed Swords
    Stats       = "rbxassetid://10709782497", -- Analytics / BarChart
    Fruits      = "rbxassetid://10723374176", -- Devil Fruit Flame
    Teleport    = "rbxassetid://10709818626", -- Navigation Compass
    ESP         = "rbxassetid://10723346959", -- Visual Eye
    Animator    = "rbxassetid://10723354551", -- Film / Skill Animator
    Settings    = "rbxassetid://10734950309", -- Gear / Config
    Boss        = "rbxassetid://10734962068", -- Boss Skull
    Lightning   = "rbxassetid://10747384394", -- Fast Attack / Speed
    Shield      = "rbxassetid://10734962778", -- Haki / Defense
    Play        = "rbxassetid://10734923549", -- Play Track
    Stop        = "rbxassetid://10734972627", -- Stop Track
    Loop        = "rbxassetid://10734940376", -- Loop / Repeat
    Wand        = "rbxassetid://10734982144", -- 3D VFX Burst
    Layers      = "rbxassetid://10723397898", -- Combo Sequencer
    Search      = "rbxassetid://10734943674", -- Filter Search
    RadialGlow  = "rbxassetid://5028857084",  -- Soft Neon Backlight
    -- New v3.0 tab / feature icons
    PvP         = "rbxassetid://10734962068", -- Skull (PvP Hunter)
    Players     = "rbxassetid://10709782497", -- Analytics (Player Inspector)
    Aim         = "rbxassetid://10709818626", -- Compass (AimLock)
    Fly         = "rbxassetid://10747384394", -- Lightning (Undetected Fly)
    Water       = "rbxassetid://10723346959", -- Eye (Walk on Water)
    Magnet      = "rbxassetid://10734982144", -- Burst (Fruit Magnet)
    Server      = "rbxassetid://10734950309", -- Crest (Server Status)
}

-- ═══════════════════════════════════════════════════════════════════════════
--  UP-TO-DATE BLOX FRUITS DATA (UPDATE 24+ / DRAGON REWORK / TIKI OUTPOST)
--  Full current roster incl. Chop, Door, String, Paw, Revive, Kilo, Yeti, Kitsune
--  and both Dragon reworks, grouped by rarity tier for the Fruit ESP colours.
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
--  SEA DETECTION ENGINE  (FIXED — never wrongly reports Sea 1 any more)
--  Layer 1 : expanded PlaceId tables (all public + known alias place IDs)
--  Layer 2 : live Workspace landmark scan (islands / _WorldOrigin.Locations)
--  Layer 3 : live enemy & NPC name scan (Workspace.Enemies / NPCs)
--  Layer 4 : level heuristic (Second Sea = Lv 700+, Third Sea = Lv 1500+)
--  Layer 5 : manual override from the UI (Teleport & Seas tab)
-- ═══════════════════════════════════════════════════════════════════════════

local SEA_PLACE_IDS = {
    [1] = { [2753915549] = true },
    [2] = { [4442272183] = true },
    [3] = { [7449423635] = true },
}

-- Landmark names are matched as SUBSTRINGS, mob names are matched EXACTLY.
local SEA_SIGNATURES = {
    [1] = {
        Locations = {
            ["middle town"] = 6, ["starter pirate island"] = 6, ["starter marine island"] = 6,
            ["pirate village"] = 6, ["jungle"] = 6, ["fountain city"] = 5,
            ["magma village"] = 5, ["underwater city"] = 5, ["upper skylands"] = 5,
            ["lower skylands"] = 5, ["marine fortress"] = 5, ["frozen village"] = 5,
            ["desert"] = 4, ["starter island"] = 4,
        },
        Mobs = { ["bandit"] = 2, ["monkey"] = 2, ["brute"] = 2, ["fishman"] = 2, ["pirate"] = 2, ["trainee"] = 2 },
    },
    [2] = {
        Locations = {
            ["kingdom of rose"] = 6, ["green zone"] = 6, ["graveyard"] = 6,
            ["cursed ship"] = 6, ["ice castle"] = 6, ["forgotten island"] = 6,
            ["dark arena"] = 5, ["hot and cold"] = 5, ["snow mountain"] = 5,
            ["cafe"] = 5, ["café"] = 5,
        },
        Mobs = { ["swan pirate"] = 2, ["mercenary"] = 2, ["cyborg"] = 3, ["fajita"] = 3, ["jeremy"] = 3, ["snow trooper"] = 2, ["winter warrior"] = 2 },
    },
    [3] = {
        Locations = {
            ["port town"] = 6, ["hydra island"] = 6, ["great tree"] = 6,
            ["floating turtle"] = 6, ["castle on the sea"] = 6, ["haunted castle"] = 6,
            ["tiki outpost"] = 6, ["temple of time"] = 5, ["kitsune island"] = 6,
            ["prehistoric island"] = 6, ["iceborn island"] = 5, ["sea of treats"] = 5,
        },
        Mobs = { ["pirate millionaire"] = 3, ["reborn skeleton"] = 3, ["living zombie"] = 3, ["demonic soul"] = 3, ["fishman raider"] = 3, ["isle outlaw"] = 3, ["forest pirate"] = 3, ["sun-kissed warrior"] = 3, ["cookie crafter"] = 3 },
    },
}

local SEA_LABELS = { [1] = "First Sea", [2] = "Second Sea", [3] = "Third Sea" }
local CONFIG_SEA_OVERRIDE = "Auto"
local SEA_DETECT_SOURCE = "place"
local CURRENT_SEA = 1

local function readRawLevel()
    local d = LocalPlayer:FindFirstChild("Data")
    local lv = d and d:FindFirstChild("Level")
    return (lv and lv.Value) or 0
end

-- Collect every island / mob / NPC name currently replicated to this client
local function scanWorldNames()
    local locNames, exactNames = {}, {}
    local function addName(name, isLocation)
        if type(name) ~= "string" or name == "" then return end
        local lower = name:lower()
        exactNames[lower] = true
        if isLocation then table.insert(locNames, lower) end
    end

    pcall(function()
        for _, child in ipairs(Workspace:GetChildren()) do
            addName(child.Name, true)
            local locs = child:FindFirstChild("Locations") or child:FindFirstChild("Islands")
            if locs then
                for _, loc in ipairs(locs:GetChildren()) do addName(loc.Name, true) end
            end
        end
        for _, folderName in ipairs({ "Enemies", "NPCs", "Quest NPCs", "QuestNPCs", "Characters", "Locations", "Islands" }) do
            local folder = Workspace:FindFirstChild(folderName)
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    addName(child.Name, folderName == "Locations" or folderName == "Islands")
                end
            end
        end
    end)

    return locNames, exactNames
end

local function computeSeaScores()
    local locNames, exactNames = scanWorldNames()
    local scores = { [1] = 0, [2] = 0, [3] = 0 }

    for sea = 1, 3 do
        local sig = SEA_SIGNATURES[sea]
        for key, weight in pairs(sig.Locations) do
            for _, name in ipairs(locNames) do
                if name:find(key, 1, true) then
                    scores[sea] += weight
                    break
                end
            end
        end
        for key, weight in pairs(sig.Mobs) do
            if exactNames[key] then scores[sea] += weight end
        end
    end
    return scores
end

local function bestScoredSea(scores)
    local best, bestScore, tied = nil, 0, false
    for sea = 1, 3 do
        local sc = scores[sea] or 0
        if sc > bestScore then
            best, bestScore, tied = sea, sc, false
        elseif sc == bestScore and sc > 0 then
            tied = true
        end
    end
    return (not tied) and best or nil, bestScore
end

local function detectSeaFromPlaceId()
    for sea = 1, 3 do
        if SEA_PLACE_IDS[sea][game.PlaceId] then return sea end
    end
    return nil
end

-- Master resolver: returns sea, source, scores
local function resolveSea()
    local scores = computeSeaScores()
    local mapSea, mapScore = bestScoredSea(scores)
    local placeSea = detectSeaFromPlaceId()

    -- Strong map evidence always wins over the PlaceId table
    if mapSea and mapScore >= 12 then return mapSea, "map", scores end
    if placeSea then return placeSea, "place", scores end
    if mapSea then return mapSea, "map", scores end

    -- Level fallback (Sea 2 requires Lv 700, Sea 3 requires Lv 1500)
    local lv = readRawLevel()
    if lv >= 1500 then return 3, "level", scores end
    if lv >= 700 then return 2, "level", scores end
    return 1, "level", scores
end

-- Refresh CURRENT_SEA (called on load, on a short retry loop and by the UI)
local function refreshSea()
    if CONFIG_SEA_OVERRIDE ~= "Auto" then
        local forced = tonumber(CONFIG_SEA_OVERRIDE)
        if forced then
            CURRENT_SEA = forced
            SEA_DETECT_SOURCE = "manual"
        end
        return CURRENT_SEA
    end
    local sea, source = resolveSea()
    if sea then
        CURRENT_SEA = sea
        SEA_DETECT_SOURCE = source
    end
    return CURRENT_SEA
end

refreshSea()

-- Full current roster (Update 24+) grouped into rarity tiers for Fruit ESP colours
local FRUIT_RARITY = {
    { name = "Common",    color = Color3.fromRGB(148, 163, 184), fruits = {
        "Rocket", "Spin", "Blade", "Kilo", "Chop", "Spring", "Bomb", "Smoke", "Spike",
    } },
    { name = "Uncommon",  color = Color3.fromRGB(74, 222, 128), fruits = {
        "Flame", "Falcon", "Ice", "Sand", "Dark", "Diamond", "Door", "String", "Rubber", "Barrier",
    } },
    { name = "Rare",      color = Color3.fromRGB(56, 189, 248), fruits = {
        "Light", "Ghost", "Magma", "Quake", "Buddha", "Love", "Spider", "Sound", "Paw", "Revive",
    } },
    { name = "Legendary", color = Color3.fromRGB(250, 204, 21), fruits = {
        "Phoenix", "Portal", "Rumble", "Pain", "Blizzard", "Gravity",
    } },
    { name = "Mythical",  color = Color3.fromRGB(244, 114, 182), fruits = {
        "Mammoth", "T-Rex", "Dough", "Shadow", "Venom", "Control", "Gas",
        "Spirit", "Leopard", "Yeti", "Kitsune", "Dragon (West)", "Dragon (East)",
    } },
}

local FRUITS_LIST = {}
local FRUIT_RARITY_OF = {}
for _, tier in ipairs(FRUIT_RARITY) do
    for _, fName in ipairs(tier.fruits) do
        table.insert(FRUITS_LIST, fName)
        FRUIT_RARITY_OF[fName] = tier
    end
end
-- aliases so short / renamed inventory names still resolve to a rarity tier
FRUIT_RARITY_OF["Dragon"] = FRUIT_RARITY_OF["Dragon (West)"] or FRUIT_RARITY_OF["Mythical"]
FRUIT_RARITY_OF["Dough King"] = FRUIT_RARITY_OF["Dough"]
FRUIT_RARITY_OF["Kitsune Fruit"] = FRUIT_RARITY_OF["Kitsune"]
table.sort(FRUITS_LIST)

local function getFruitTier(fruitName)
    if not fruitName then return { name = "Unknown", color = Color3.fromRGB(167, 139, 250) } end
    local clean = tostring(fruitName):gsub(" Fruit", ""):gsub("fruit", "")
    clean = clean:gsub("^%s+", ""):gsub("%s+$", "")
    for name, tier in pairs(FRUIT_RARITY_OF) do
        if clean == name or clean:find(name, 1, true) then return tier end
    end
    return { name = "Unknown", color = Color3.fromRGB(167, 139, 250) }
end

local FRUIT_STORE_CODES = {}
for _, fName in ipairs(FRUITS_LIST) do
    FRUIT_STORE_CODES[fName] = fName .. "-" .. fName
end

local RAID_CHIPS = {
    "Flame", "Ice", "Quake", "Light", "Dark", "Spider",
    "Rumble", "Magma", "Buddha", "Sand", "Phoenix", "Dough",
}

-- Ordered Fighting Style database (V1 + V2 + V3). `remote` = CommF_ purchase remote,
-- `tool` = the Melee tool name the game equips for that style.
local FIGHTING_STYLES = {
    { name = "Combat",          remote = "BuyCombat",        tier = "V1 · Base",    tool = "Combat" },
    { name = "Black Leg",       remote = "BuyBlackLeg",      tier = "V1",           tool = "Black Leg" },
    { name = "Electro",         remote = "BuyElectro",       tier = "V1",           tool = "Electro" },
    { name = "Fishman Karate",  remote = "BuyFishmanKarate", tier = "V1",           tool = "Fishman Karate" },
    { name = "Dragon Breath",   remote = "BuyDragonBreath",  tier = "V1",           tool = "Dragon Breath" },
    { name = "Superhuman",      remote = "BuySuperhuman",    tier = "V2",           tool = "Superhuman" },
    { name = "Death Step",      remote = "BuyDeathStep",     tier = "V2",           tool = "Death Step" },
    { name = "Sharkman Karate", remote = "BuySharkmanKarate",tier = "V2",           tool = "Sharkman Karate" },
    { name = "Electric Claw",   remote = "BuyElectricClaw",  tier = "V2",           tool = "Electric Claw" },
    { name = "Dragon Talon",    remote = "BuyDragonTalon",   tier = "V2",           tool = "Dragon Talon" },
    { name = "Godhuman",        remote = "BuyGodhuman",      tier = "V3 · Endgame", tool = "Godhuman" },
    { name = "Sanguine Art",    remote = "BuySanguineArt",   tier = "V3 · Endgame", tool = "Sanguine Art" },
}

local FIGHTING_STYLE_TOOLS   = {}   -- lowercased tool/tooltip name -> canonical style name
local FIGHTING_STYLE_REMOTES = {}   -- canonical style name -> CommF_ remote
local FIGHTING_STYLE_ORDER   = {}   -- dropdown labels

for _, style in ipairs(FIGHTING_STYLES) do
    FIGHTING_STYLE_TOOLS[style.name:lower()] = style.name
    FIGHTING_STYLE_TOOLS[style.tool:lower()] = style.name
    FIGHTING_STYLE_TOOLS[style.name:lower():gsub("%s", "")] = style.name
    FIGHTING_STYLE_TOOLS[style.tool:lower():gsub("%s", "")] = style.name
    FIGHTING_STYLE_REMOTES[style.name] = style.remote
    table.insert(FIGHTING_STYLE_ORDER, string.format("%s  [%s]", style.name, style.tier))
end

-- ToolTip values the game (or localized clients) may report for a Fighting Style
local FIGHTING_STYLE_TIPS = {
    ["melee"] = true, ["fighting style"] = true, ["style"] = true, ["combat"] = true,
    ["black leg"] = true, ["electro"] = true, ["fishman karate"] = true, ["dragon breath"] = true,
    ["dragon claw"] = true, ["superhuman"] = true, ["death step"] = true, ["sharkman karate"] = true,
    ["electric claw"] = true, ["dragon talon"] = true, ["godhuman"] = true, ["sanguine art"] = true,
    ["rokushiki"] = true, ["haki"] = false,
}

-- Weapon category keyword fallbacks (used when ToolTip is nil / localized / renamed)
local SWORD_KEYWORDS = {
    "sword", "blade", "saber", "katana", "cutlass", "scythe", "trident", "spear",
    "hammer", "dual", "yoru", "dainsleif", "dark blade", "pole", "axe", "sais", "dagger", "rapier",
}
local GUN_KEYWORDS = {
    "slingshot", "flintlock", "cannon", "rifle", "bazooka", "musket", "pistol", "shotgun", "gun",
}
local FRUIT_KEYWORDS = { "fruit", "dough", "kitsune", "dragon", "leopard", "venom", "control", "spirit" }

local function isMeleeTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local tip = tostring(tool.ToolTip or ""):lower()
    if FIGHTING_STYLE_TIPS[tip] then return true end
    if FIGHTING_STYLE_TOOLS[tool.Name:lower()] then return true end
    if FIGHTING_STYLE_TOOLS[tool.Name:lower():gsub("%s", "")] then return true end
    local attr = tool:GetAttribute("WeaponType") or tool:GetAttribute("Type") or tool:GetAttribute("Style")
    if type(attr) == "string" and FIGHTING_STYLE_TIPS[attr:lower()] then return true end
    return false
end

local function toolMatchesCategory(tool, weaponType)
    if not tool or not tool:IsA("Tool") then return false end
    local tip = tostring(tool.ToolTip or ""):lower()
    local name = tool.Name:lower()
    local want = tostring(weaponType or "Melee"):lower()

    if want == "melee" then
        return isMeleeTool(tool)
    elseif want == "sword" then
        if tip == "sword" or tip == "swords" then return true end
        if tool:GetAttribute("IsSword") then return true end
        for _, kw in ipairs(SWORD_KEYWORDS) do if name:find(kw, 1, true) then return true end end
        return false
    elseif want == "gun" or want == "guns" then
        if tip == "gun" or tip == "guns" then return true end
        if tool:GetAttribute("IsGun") then return true end
        for _, kw in ipairs(GUN_KEYWORDS) do if name:find(kw, 1, true) then return true end end
        return false
    else -- Blox Fruit
        if tip == "blox fruit" or tip == "fruit" then return true end
        if tool:GetAttribute("IsFruit") or tool:GetAttribute("OriginalName") then return true end
        for _, kw in ipairs(FRUIT_KEYWORDS) do if name:find(kw, 1, true) then return true end end
        return false
    end
end

local BOSSES_BY_SEA = {
    [1] = {
        "The Gorilla King", "Bobby", "Yeti", "Mob Leader", "Vice Admiral",
        "Saber Expert", "Warden", "Chief Warden", "Swan", "Magma Admiral",
        "Fishman Lord", "Wysper", "Thunder God", "Cyborg",
    },
    [2] = {
        "Diamond", "Jeremy", "Fajita", "Don Swan", "Smoke Admiral",
        "Cursed Captain", "Darkbeard", "Order", "Awakened Ice Admiral", "Tide Keeper",
    },
    [3] = {
        "Stone", "Hydra Leader", "Kilo Admiral", "Captain Elephant",
        "Beautiful Pirate", "Longma", "Soul Reaper", "Cake Queen",
        "Cake Prince", "Dough King", "Rip_Indra True Form", "Tyrant of the Skies",
    },
}

local ISLAND_TELEPORTS = {
    [1] = {
        ["Starter Pirate Island"] = CFrame.new(1071, 16, 1426),
        ["Starter Marine Island"] = CFrame.new(-2573, 7, 2046),
        ["Middle Town"]           = CFrame.new(-655, 8, 1436),
        ["Jungle"]                = CFrame.new(-1612, 37, 149),
        ["Pirate Village"]        = CFrame.new(-1181, 5, 3803),
        ["Desert"]                = CFrame.new(944, 21, 4373),
        ["Frozen Village"]        = CFrame.new(1347, 105, -1319),
        ["Marine Fortress"]       = CFrame.new(-4914, 51, 4281),
        ["Lower Skylands"]        = CFrame.new(-4869, 733, -2667),
        ["Upper Skylands"]        = CFrame.new(-7894, 5547, -380),
        ["Prison"]                = CFrame.new(4875, 6, 734),
        ["Colosseum"]             = CFrame.new(-1427, 7, -2792),
        ["Magma Village"]         = CFrame.new(-5247, 13, 8504),
        ["Underwater City"]       = CFrame.new(61163, 12, 1819),
        ["Fountain City"]         = CFrame.new(5127, 60, 4105),
    },
    [2] = {
        ["Kingdom of Rose"]       = CFrame.new(-394, 118, 1245),
        ["Cafe"]                  = CFrame.new(-380, 77, 255),
        ["Mansion (Swan)"]        = CFrame.new(-390, 332, 673),
        ["Green Zone"]            = CFrame.new(-2448, 73, -3210),
        ["Graveyard"]             = CFrame.new(-5411, 49, -721),
        ["Snow Mountain"]         = CFrame.new(753, 408, -5274),
        ["Hot and Cold (Raid)"]   = CFrame.new(-6475, 250, -4490),
        ["Cursed Ship"]           = CFrame.new(923, 125, 32885),
        ["Ice Castle"]            = CFrame.new(6148, 294, -6741),
        ["Forgotten Island"]      = CFrame.new(-3032, 317, -10075),
        ["Dark Arena"]            = CFrame.new(3780, 23, -3499),
    },
    [3] = {
        ["Port Town"]             = CFrame.new(-290, 44, 5368),
        ["Hydra Island & Dojo"]   = CFrame.new(5749, 611, -276),
        ["Great Tree"]            = CFrame.new(2681, 1682, -7190),
        ["Floating Turtle"]       = CFrame.new(-13274, 532, -7579),
        ["Mansion (Turtle)"]      = CFrame.new(-12548, 337, -7481),
        ["Castle on the Sea"]     = CFrame.new(-5075, 314, -3150),
        ["Haunted Castle"]        = CFrame.new(-9515, 142, 5535),
        ["Sea of Treats (Cake)"]  = CFrame.new(-1884, 19, -11666),
        ["Tiki Outpost"]          = CFrame.new(-16218, 9, 445),
        ["Temple of Time"]        = CFrame.new(28286, 14897, 102),
    },
}

-- Sea-agnostic lookup tables so teleports & boss hunting work even if the Sea
-- detector, a sub-place ID or a custom server reports an unexpected value.
local ISLAND_TELEPORTS_ALL = {}
for sea = 1, 3 do
    local list = ISLAND_TELEPORTS[sea]
    if list then
        for islandName, cf in pairs(list) do
            ISLAND_TELEPORTS_ALL[string.format("S%d • %s", sea, islandName)] = cf
        end
    end
end

local ISLAND_LIST_ALL = {}
for label in pairs(ISLAND_TELEPORTS_ALL) do table.insert(ISLAND_LIST_ALL, label) end
table.sort(ISLAND_LIST_ALL)

local BOSS_LIST_ALL = {}
for sea = 1, 3 do
    for _, bossName in ipairs(BOSSES_BY_SEA[sea] or {}) do
        table.insert(BOSS_LIST_ALL, string.format("S%d • %s", sea, bossName))
    end
end

-- Sea events / special landmarks tracked by the Sea Event & Mirage utilities
local SEA_EVENT_SIGNATURES = {
    { Name = "Terror Shark",      Keys = { "terror shark" },                 Color = Color3.fromRGB(239, 68, 68) },
    { Name = "Leviathan",         Keys = { "leviathan" },                    Color = Color3.fromRGB(56, 189, 248) },
    { Name = "Sea Beast",         Keys = { "sea beast" },                    Color = Color3.fromRGB(248, 113, 113) },
    { Name = "Kraken",            Keys = { "kraken" },                        Color = Color3.fromRGB(168, 85, 247) },
    { Name = "Mirage Island",     Keys = { "mirage" },                        Color = Color3.fromRGB(244, 114, 182) },
    { Name = "Kitsune Shrine",    Keys = { "kitsune shrine", "kitsune island" }, Color = Color3.fromRGB(250, 204, 21) },
    { Name = "Prehistoric Island",Keys = { "prehistoric" },                   Color = Color3.fromRGB(74, 222, 128) },
    { Name = "Cursed Ship Raid",  Keys = { "cursed ship" },                   Color = Color3.fromRGB(148, 163, 184) },
    { Name = "Blue Gear / Mystic",Keys = { "mystic", "blue gear" },           Color = Color3.fromRGB(125, 211, 252) },
}

local QUEST_DATABASE = {
    [1] = {
        {MinLv = 1,   MaxLv = 9,   Mob = "Bandit",              Quest = "BanditQuest1",      QNum = 1, QPos = CFrame.new(1059, 16, 1549),   MPos = CFrame.new(1145, 17, 1634)},
        {MinLv = 10,  MaxLv = 29,  Mob = "Monkey",              Quest = "JungleQuest",       QNum = 1, QPos = CFrame.new(-1598, 36, 153),   MPos = CFrame.new(-1448, 50, 63)},
        {MinLv = 30,  MaxLv = 59,  Mob = "Pirate",              Quest = "BuggyQuest1",       QNum = 1, QPos = CFrame.new(-1140, 4, 3829),   MPos = CFrame.new(-1201, 40, 3857)},
        {MinLv = 60,  MaxLv = 89,  Mob = "Desert Bandit",       Quest = "DesertQuest",       QNum = 1, QPos = CFrame.new(894, 6, 4392),     MPos = CFrame.new(984, 16, 4417)},
        {MinLv = 90,  MaxLv = 119, Mob = "Snow Bandit",         Quest = "SnowQuest",         QNum = 1, QPos = CFrame.new(1386, 87, -1298),  MPos = CFrame.new(1356, 106, -1328)},
        {MinLv = 120, MaxLv = 189, Mob = "Chief Petty Officer", Quest = "MarineQuest2",      QNum = 1, QPos = CFrame.new(-5039, 28, 4324),  MPos = CFrame.new(-4710, 16, 4296)},
        {MinLv = 190, MaxLv = 249, Mob = "Prisoner",            Quest = "PrisonerQuest",     QNum = 1, QPos = CFrame.new(5308, 2, 474),     MPos = CFrame.new(5098, 2, 474)},
        {MinLv = 250, MaxLv = 299, Mob = "Toga Warrior",        Quest = "ColosseumQuest",    QNum = 1, QPos = CFrame.new(-1580, 7, -2986),  MPos = CFrame.new(-1820, 51, -2740)},
        {MinLv = 300, MaxLv = 374, Mob = "Military Soldier",    Quest = "MagmaQuest",        QNum = 1, QPos = CFrame.new(-5313, 12, 8515),  MPos = CFrame.new(-5411, 11, 8454)},
        {MinLv = 375, MaxLv = 449, Mob = "Fishman Warrior",     Quest = "FishmanQuest",      QNum = 1, QPos = CFrame.new(61122, 18, 1569),  MPos = CFrame.new(60878, 18, 1543)},
        {MinLv = 450, MaxLv = 624, Mob = "God's Guard",         Quest = "SkyExp1Quest",      QNum = 1, QPos = CFrame.new(-4721, 845, -1954), MPos = CFrame.new(-4710, 845, -1927)},
        {MinLv = 625, MaxLv = 699, Mob = "Galley Pirate",       Quest = "FountainQuest",     QNum = 1, QPos = CFrame.new(5259, 39, 4050),   MPos = CFrame.new(5551, 78, 3930)},
    },
    [2] = {
        {MinLv = 700,  MaxLv = 774,  Mob = "Raider",            Quest = "Area1Quest",        QNum = 1, QPos = CFrame.new(-429, 72, 1836),   MPos = CFrame.new(-728, 52, 2345)},
        {MinLv = 775,  MaxLv = 874,  Mob = "Swan Pirate",       Quest = "Area2Quest",        QNum = 1, QPos = CFrame.new(638, 73, 918),     MPos = CFrame.new(1068, 137, 1322)},
        {MinLv = 875,  MaxLv = 949,  Mob = "Marine Lieutenant", Quest = "MarineQuest3",      QNum = 1, QPos = CFrame.new(-2440, 73, -3216), MPos = CFrame.new(-2821, 73, -3070)},
        {MinLv = 950,  MaxLv = 999,  Mob = "Zombie",            Quest = "ZombieQuest",       QNum = 1, QPos = CFrame.new(-5497, 48, -795),  MPos = CFrame.new(-5657, 173, -601)},
        {MinLv = 1000, MaxLv = 1099, Mob = "Snow Trooper",      Quest = "SnowMountainQuest", QNum = 1, QPos = CFrame.new(609, 400, -5372),  MPos = CFrame.new(549, 427, -5563)},
        {MinLv = 1100, MaxLv = 1249, Mob = "Lab Subordinate",   Quest = "IceSideQuest",      QNum = 1, QPos = CFrame.new(-6064, 15, -4902), MPos = CFrame.new(-5707, 15, -4513)},
        {MinLv = 1250, MaxLv = 1349, Mob = "Ship Deckhand",     Quest = "ShipQuest1",        QNum = 1, QPos = CFrame.new(1037, 125, 32911), MPos = CFrame.new(1212, 150, 33059)},
        {MinLv = 1350, MaxLv = 1424, Mob = "Arctic Warrior",    Quest = "FrostQuest",        QNum = 1, QPos = CFrame.new(5667, 26, -6486),  MPos = CFrame.new(5966, 62, -6179)},
        {MinLv = 1425, MaxLv = 1499, Mob = "Sea Soldier",       Quest = "ForgottenQuest",    QNum = 1, QPos = CFrame.new(-3054, 236, -10142), MPos = CFrame.new(-3028, 64, -9775)},
    },
    [3] = {
        {MinLv = 1500, MaxLv = 1574, Mob = "Pirate Millionaire", Quest = "PiratePortQuest",  QNum = 1, QPos = CFrame.new(-290, 44, 5581),   MPos = CFrame.new(-246, 55, 5564)},
        {MinLv = 1575, MaxLv = 1699, Mob = "Dragon Crew Warrior",Quest = "DragonCrewQuest",  QNum = 1, QPos = CFrame.new(6737, 127, -712),  MPos = CFrame.new(6709, 55, -1104)},
        {MinLv = 1700, MaxLv = 1774, Mob = "Marine Commodore",   Quest = "MarineTreeIsland", QNum = 1, QPos = CFrame.new(2180, 29, -6738),  MPos = CFrame.new(2286, 73, -7159)},
        {MinLv = 1775, MaxLv = 1974, Mob = "Fishman Raider",     Quest = "DeepForestIsland3",QNum = 1, QPos = CFrame.new(-10581, 331, -8761),MPos = CFrame.new(-10407, 331, -8368)},
        {MinLv = 1975, MaxLv = 2074, Mob = "Reborn Skeleton",    Quest = "HauntedQuest1",    QNum = 1, QPos = CFrame.new(-9479, 141, 5566), MPos = CFrame.new(-8763, 165, 6159)},
        {MinLv = 2075, MaxLv = 2449, Mob = "Cookie Crafter",     Quest = "CakeQuest1",       QNum = 1, QPos = CFrame.new(-2021, 38, -12028),MPos = CFrame.new(-2374, 38, -12125)},
        {MinLv = 2450, MaxLv = 2650, Mob = "Sun-kissed Warrior", Quest = "TikiQuest1",       QNum = 2, QPos = CFrame.new(-16548, 56, 1051), MPos = CFrame.new(-16345, 35, 1002)},
    },
}

local ACTIVE_CODES = {
    "KITT_RESET", "Sub2CaptainMaui", "kittgaming", "Sub2Fer999",
    "Enyu_is_Pro", "Magicbus", "JCWK", "Starcodeheo", "Bluxxy",
    "fudd10_v2", "SUB2GAMERROBOT_EXP1", "Sub2NoobMaster123",
    "Sub2UncleKizaru", "Sub2Daigrock", "Axiore", "TantaiGaming",
    "StrawHatMaine", "Sub2OfficialNoobie", "TheGreatAce",
}

-- ═══════════════════════════════════════════════════════════════════════════
--  GLOBAL STATE & CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════

local Config = {
    AutoFarmLevel       = false,
    AutoFarmNearest     = false,
    AutoFarmBoss        = false,
    AutoFarmAllBosses   = false,
    AutoFarmChests      = false,
    SelectedWeaponType  = "Melee",
    SelectedBoss        = string.format("S%d • %s", CURRENT_SEA, BOSSES_BY_SEA[CURRENT_SEA][1]),
    FarmDistance        = 18,
    TweenSpeed          = 260,
    BringMobs           = true,
    FastAttack          = true,
    AutoBuso            = true,
    AutoKen             = false,
    AutoRaceV3          = false,

    AutoStatMelee       = false,
    AutoStatDefense     = false,
    AutoStatSword       = false,
    AutoStatGun         = false,
    AutoStatFruit       = false,
    StatPointsBatch     = 3,

    SelectedFruit       = "Kitsune",
    AutoSniperStock     = false,
    AutoGrabMapFruits   = false,
    AutoStoreFruits     = false,
    AutoRandomFruit     = false,
    SelectedRaidChip    = "Flame",
    AutoBuyRaidChip     = false,
    AutoRaidAura        = false,
    AutoAwaken          = false,

    SelectedIsland      = ISLAND_LIST_ALL[1] or "Middle Town",
    SelectedFightingStyle = FIGHTING_STYLE_ORDER[1],

    ESPPlayers          = false,
    ESPFruits           = false,
    ESPChests           = false,
    ESPIslands          = false,
    ESPBosses           = false,
    ESPPlayerLoadout    = true,
    ESPFruitRarity      = true,
    ESPTracers          = false,

    -- PvP & Players
    SelectedPlayer      = "",
    AutoKillSelected    = false,
    AutoKillPvP         = false,
    AimLock             = false,
    AimLockSmoothness   = 0.28,
    AimLockFOV          = 300,
    SpectatePlayer      = false,
    PlayerHitbox        = false,
    PlayerHitboxSize    = 14,
    IgnoreFriendsPvP    = true,
    PvPSkills           = true,
    KillAuraAllPvP      = true,
    KillAuraRange       = 95,
    BuddhaAwareCombat   = true,

    -- Hitbox Expander v2
    HitboxMobs          = true,
    HitboxMobsSize      = 55,
    HitboxMobsRange     = 420,
    ShowHitboxVisual    = false,
    PvPTweenDistance    = 9,
    DashInterval        = 0.32,

    -- Undetected Fly v2
    FlyEnabled          = false,
    FlySpeed            = 60,
    FlyBypassMode       = true,
    FlyAntiVoid         = true,
    FlyZeroWalkSpeed    = true,
    FlyJoinAutopilot    = true,

    -- Fruit utilities
    FruitMagnet         = false,
    FruitMagnetRadius   = 600,
    AutoStoreRolled     = true,
    RolledFruitName     = "",

    -- Unique utilities
    WalkOnWater         = false,
    InfiniteGeppo       = false,
    InfiniteEnergy      = false,
    NoDashCooldown      = false,
    MirageFinder        = false,
    SeaEventTracker     = false,
    AutoCollectDrops    = false,
    NoFallDamage        = true,
    ServerStatusHUD     = true,
    SovereignHakiAura   = true,

    -- Combat, Fast Attack & Anti-Cheat Bypass
    AutoAttackAlways    = false,
    FastAttackDelay     = 0.02,
    AttackRange         = 65,
    AttackPlayers       = false,
    HitboxExpander      = true,
    BypassAntiCheat     = true,
    AntiStun            = true,
    AutoSkillComboZ     = false,
    AutoSkillComboX     = false,
    AutoSkillComboC     = false,
    AutoSkillComboV     = false,

    WalkSpeedEnabled    = false,
    WalkSpeedValue      = 75,
    JumpPowerEnabled    = false,
    JumpPowerValue      = 120,
    NoClip              = false,
    AntiAFK             = true,
    ShowWatermarkHUD    = true,
    PreferExternalFluent = false,
}

-- Forward-declared hooks (the UI/engine blocks below fill these in later, so every
-- background loop can safely raise notifications and draw ESP tags).
local Hooks = {
    notify    = function() end,
    clearESP  = function() end,
    espTag    = function() end,
}

-- Movement governor: Bypass Fly registers itself here so Auto Farm, the Boss
-- Hunter and the PvP hunter hand their travel requests to the fly autopilot
-- instead of fighting it with a Tween (this is what made Fly + AutoFarm/AutoPvP
-- feel broken).
local MovementLink = {
    isFlyActive  = function() return false end,
    -- setFlyTarget(cframe, speedOverride?)  — speedOverride is used for long
    -- island teleports so the fly can cross the map quickly when asked to.
    setFlyTarget = function() end,
    clearFlyTarget = function() end,
}

-- Detections produced by the Sea Event / Mirage scanners, rendered by the ESP loop
local SeaEventState = {
    events = {},
    mirage = {},
    lastNotify = {},
}


-- ═══════════════════════════════════════════════════════════════════════════
--  BLOX FRUITS ANTI-CHEAT DISABLER, SIMRADIUS & ANTI-STUN ENGINE
-- ═══════════════════════════════════════════════════════════════════════════

local BLOCKED_SECURITY_REMOTES = {
    "security", "teleportdetect", "exploit", "cheat", "ban",
    "kick", "flag", "check", "ac_", "anticheat", "crash", "log",
}

local SAFE_GAMEPLAY_REMOTES = {
    ["commf_"]             = true,
    ["comme"]              = true,
    ["re/registerattack"]  = true,
    ["re/registerhit"]     = true,
    ["rigcontrollerevent"] = true,
    ["validator"]          = true,
    ["redeem"]             = true,
}

local function isSuspiciousRemote(remoteObj)
    local nameLower = tostring(remoteObj.Name):lower()
    if SAFE_GAMEPLAY_REMOTES[nameLower] then
        return false
    end
    for _, kw in ipairs(BLOCKED_SECURITY_REMOTES) do
        if nameLower:find(kw, 1, true) then
            return true
        end
    end
    return false
end

local function initBloxFruitsAntiCheatBypass()
    -- 1. Override direct LocalPlayer.Kick
    pcall(function()
        if hookfunction and LocalPlayer.Kick then
            hookfunction(LocalPlayer.Kick, function(...)
                return nil
            end)
        end
    end)

    -- 2. Hook __namecall to block :Kick() and Blox Fruits security/telemetry remotes
    pcall(function()
        if hookmetamethod and getnamecallmethod then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if method == "Kick" or method == "kick" then
                    return nil
                end
                if Config.BypassAntiCheat and (method == "FireServer" or method == "InvokeServer") then
                    if typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                        if isSuspiciousRemote(self) then
                            return nil
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)
        end
    end)

    -- 3. Neutralize client-side character velocity/teleport check connections
    pcall(function()
        if type(getconnections) == "function" then
            local pScripts = LocalPlayer:FindFirstChild("PlayerScripts")
            if pScripts then
                for _, desc in ipairs(pScripts:GetDescendants()) do
                    if desc:IsA("LocalScript") then
                        local n = desc.Name:lower()
                        if n:find("anti") or n:find("security") or n:find("check") or n:find("detect") then
                            pcall(function() desc.Disabled = true end)
                        end
                    end
                end
            end
        end
    end)
end

initBloxFruitsAntiCheatBypass()

-- Continuous SimulationRadius, Anti-Stun, Anti-Ragdoll & Velocity Stabilizer
RunService.Heartbeat:Connect(function()
    if not Config.BypassAntiCheat and not Config.AntiStun then return end
    pcall(function()
        -- Maximize SimulationRadius so BringMobs owns enemy physics
        if sethiddenproperty then
            pcall(function()
                sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
            end)
        end

        local char = LocalPlayer.Character
        if not char then return end

        -- Remove Blox Fruits Stun & Busy locks
        if Config.AntiStun then
            local stun = char:FindFirstChild("Stun")
            if stun and (stun:IsA("IntValue") or stun:IsA("NumberValue")) and stun.Value ~= 0 then
                stun.Value = 0
            end
            local busy = char:FindFirstChild("Busy")
            if busy and busy:IsA("BoolValue") and busy.Value == true then
                busy.Value = false
            end
        end

        -- Prevent Ragdoll / FallingDown states & rubberband velocity spikes during farm
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            if Config.NoFallDamage then
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
            end
        end

        if Config.AutoFarmLevel or Config.AutoFarmNearest or Config.AutoFarmBoss or Config.AutoFarmAllBosses then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  CORE BLOX FRUITS REMOTES & TRIPLE-LAYER FAST ATTACK ENGINE
-- ═══════════════════════════════════════════════════════════════════════════

local function getCommF()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("CommF_")
end

local function invokeCommF(...)
    local comm = getCommF()
    if comm and comm:IsA("RemoteFunction") then
        local ok, res = pcall(function(...)
            return comm:InvokeServer(...)
        end, ...)
        if ok then return res end
    end
    return nil
end

local function getCharacter() return LocalPlayer.Character end
local function getRoot()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getPlayerLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    local lv = data and data:FindFirstChild("Level")
    return (lv and lv.Value) or 1
end

local function getPlayerBeli()
    local data = LocalPlayer:FindFirstChild("Data")
    local beli = data and data:FindFirstChild("Beli")
    return (beli and beli.Value) or 0
end

local function getPlayerFragments()
    local data = LocalPlayer:FindFirstChild("Data")
    local frags = data and data:FindFirstChild("Fragments")
    return (frags and frags.Value) or 0
end

local function formatNumber(n)
    local s = tostring(math.floor(n or 0))
    return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- Smooth Tweening
local activeTween = nil

local function stopTween()
    pcall(function() MovementLink.clearFlyTarget() end)
    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end
    local root = getRoot()
    if root and root:FindFirstChild("SkillHubAntiFall") then
        root.SkillHubAntiFall:Destroy()
    end
end

local function tweenTo(targetCFrame, speedOverride)
    local root = getRoot()
    if not root or not targetCFrame then return end

    -- While the Bypass Fly owns the character, every travel request becomes a fly
    -- autopilot target: the fly keeps hovering/steering smoothly instead of the
    -- Tween and the flyer tugging the character in opposite directions.
    if MovementLink.isFlyActive() then
        MovementLink.setFlyTarget(targetCFrame, speedOverride)
        return
    end

    if not root:FindFirstChild("SkillHubAntiFall") then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "SkillHubAntiFall"
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Velocity = Vector3.zero
        bv.Parent = root
    end

    local dist = (root.Position - targetCFrame.Position).Magnitude
    if dist < 12 then
        root.CFrame = targetCFrame
        return
    end

    local duration = math.max(dist / math.max(Config.TweenSpeed, 100), 0.05)
    local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    if activeTween then
        pcall(function() activeTween:Cancel() end)
    end
    activeTween = TweenService:Create(root, info, {CFrame = targetCFrame})
    activeTween:Play()
end

-- ─── FIXED WEAPON & FIGHTING STYLE EQUIP SYSTEM ─────────────────────────────
-- Old version only compared Tool.ToolTip, so Melee / Fighting Style tools that
-- report a nil, localized or renamed ToolTip ("Black Leg", "Godhuman", ...) were
-- never equipped. This version resolves by ToolTip + known style/sword/gun names
-- + attributes + keyword heuristics, and equips with Humanoid:EquipTool() with a
-- `tool.Parent = character` fallback.

local function isToolEquipped(toolName)
    local char = getCharacter()
    return char and char:FindFirstChild(toolName) ~= nil
end

local function collectTools()
    local list = {}
    local char = getCharacter()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    for _, container in ipairs({ char, backpack }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then table.insert(list, tool) end
            end
        end
    end
    return list
end

local function equipTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local char = getCharacter()
    local hum = getHumanoid()
    if not char then return false end
    if char:FindFirstChild(tool.Name) then return true end

    pcall(function()
        if hum then hum:EquipTool(tool) end
    end)
    if char:FindFirstChild(tool.Name) then return true end

    -- Fallback: parent straight into the character (works on executors where the
    -- Humanoid equip method is sandboxed / blocked by the game's Tool handler)
    pcall(function() tool.Parent = char end)
    return char:FindFirstChild(tool.Name) ~= nil
end

local function findToolByCategory(weaponType)
    -- Prefer an already equipped matching tool, then the Backpack
    local char = getCharacter()
    local equipped = char and char:FindFirstChildOfClass("Tool")
    if equipped and toolMatchesCategory(equipped, weaponType) then return equipped end

    for _, tool in ipairs(collectTools()) do
        if toolMatchesCategory(tool, weaponType) then
            if not char or not char:FindFirstChild(tool.Name) then return tool end
        end
    end
    return nil
end

local function equipWeaponByType(weaponType)
    if not getCharacter() then return false end
    local tool = findToolByCategory(weaponType)
    if not tool then return false end
    return equipTool(tool)
end

-- Equip a specific Fighting Style (name or tool name). Blox Fruits equips the
-- style tool when the purchase remote is fired with the "already owned" flag, so
-- we send both forms and then force-equip the Melee tool as a guarantee.
local function equipFightingStyle(styleQuery)
    if not styleQuery then return false end
    local key = tostring(styleQuery):lower():gsub("%s*%[.*%]$", ""):gsub("^%s+", ""):gsub("%s+$", "")
    local canonical = FIGHTING_STYLE_TOOLS[key] or FIGHTING_STYLE_TOOLS[key:gsub("%s", "")]
    if not canonical then return false end
    local remote = FIGHTING_STYLE_REMOTES[canonical]

    if remote then
        pcall(function() invokeCommF(remote, true) end)
        task.wait(0.3)
        pcall(function() invokeCommF(remote) end)
        task.wait(0.7)
    end

    -- Guarantee the Melee/Fighting-Style tool ends up in the character
    local char = getCharacter()
    local target = nil
    for _, tool in ipairs(collectTools()) do
        local n = tool.Name:lower()
        if n == canonical:lower() or FIGHTING_STYLE_TOOLS[n] == canonical then target = tool break end
    end
    if not target then target = findToolByCategory("Melee") end
    if target and char and not char:FindFirstChild(target.Name) then
        equipTool(target)
        task.wait(0.15)
        if not char:FindFirstChild(target.Name) then equipTool(target) end
    end
    return char ~= nil and char:FindFirstChildOfClass("Tool") ~= nil
end

-- ─── PLAYER PVP / LOADOUT INSPECTOR ─────────────────────────────────────────

local PVP_FLAG_NAMES = {
    "PVP", "Pvp", "pvp", "PvpEnabled", "PVPEnabled", "PVPEnabled", "InPvp", "InPVP",
    "PvpMode", "PVPMode", "IsPvp", "PvpOn", "PVPOn", "EnablePvp", "PvpStatus",
}

local function findPvpFlag(container)
    if not container then return nil, nil end
    for _, name in ipairs(PVP_FLAG_NAMES) do
        local v = container:FindFirstChild(name)
        if v and (v:IsA("BoolValue") or v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue")) then
            return v, name
        end
    end
    return nil, nil
end

-- Cached safe-zone parts (Blox Fruits marks towns / spawn islands with regions)
local cachedSafeParts, safeCacheStamp = nil, 0
local function getSafeZoneParts()
    if cachedSafeParts and (os.clock() - safeCacheStamp) < 20 then return cachedSafeParts end
    local parts = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:lower():find("safe", 1, true) then
                table.insert(parts, obj)
            end
        end
    end)
    cachedSafeParts, safeCacheStamp = parts, os.clock()
    return parts
end

local function isInsideSafeZone(char)
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not root then return false end
    local pos = root.Position
    for _, part in ipairs(getSafeZoneParts()) do
        if part and part.Parent then
            local rel = part.CFrame:PointToObjectSpace(pos)
            local size = part.Size
            if math.abs(rel.X) <= size.X / 2 + 1 and math.abs(rel.Y) <= size.Y / 2 + 4 and math.abs(rel.Z) <= size.Z / 2 + 1 then
                return true
            end
        end
    end
    return false
end

-- Returns attackable (bool), status text, colour
local function getPvPStatus(plr)
    local grey, green, red, blue = Color3.fromRGB(148, 163, 184), Color3.fromRGB(34, 197, 94), Color3.fromRGB(239, 68, 68), Color3.fromRGB(56, 189, 248)
    if not plr then return false, "UNKNOWN", grey end
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then return false, "LOADING / DEAD", grey end
    if hum.Health <= 0 then return false, "DEAD", grey end

    if char:FindFirstChild("ForceField") or char:FindFirstChild("ForceField") then
        return false, "SAFE · FORCEFIELD", blue
    end

    -- Explicit replicated flags first
    local flag, flagName = findPvpFlag(char)
    if not flag then flag, flagName = findPvpFlag(plr:FindFirstChild("Data")) end
    if not flag then flag, flagName = findPvpFlag(plr) end
    if not flag and plr.PlayerGui then
        local main = plr.PlayerGui:FindFirstChild("Main")
        if main then flag, flagName = findPvpFlag(main) end
    end
    if flag then
        if flag.Value == true then return true, "PVP ON · " .. tostring(flagName), red end
        if flag.Value == false then return false, "PVP OFF · " .. tostring(flagName), green end
    end

    -- Attribute form (some executor-friendly builds export it as an attribute)
    for _, attr in ipairs({ "PVP", "Pvp", "PvpEnabled", "InPvp" }) do
        local v = (pcall(function() return plr:GetAttribute(attr) end)) and plr:GetAttribute(attr) or nil
        if v ~= nil then
            return v and true or false, (v and "PVP ON · attr" or "PVP OFF · attr"), (v and red or green)
        end
    end

    if isInsideSafeZone(char) then return false, "SAFE ZONE", blue end

    -- No replicated flag exists for this player: outside a safe zone in Blox Fruits
    -- everybody is damageable, so treat them as PvP-able.
    return true, "PVP ON · outside safe zone", red
end

local function canAttackPlayer(plr)
    local ok = getPvPStatus(plr)
    return ok
end

local function getPlayerBounty(plr)
    local data = plr and plr:FindFirstChild("Data")
    if data then
        for _, n in ipairs({ "Bounty", "BountyValue", "BountyAmount" }) do
            local v = data:FindFirstChild(n)
            if v and v:IsA("ValueBase") then return tostring(v.Value) end
        end
    end
    return "-"
end

-- Full loadout snapshot used by Player ESP + the in-UI Player Scanner
local function getPlayerLoadout(plr)
    local out = {
        fruit = "None", style = "Combat", sword = "-", gun = "-",
        level = "?", bounty = "-", total = "-", hp = 0, maxHp = 0,
    }
    if not plr then return out end
    local data = plr:FindFirstChild("Data")
    local function readData(...)
        if not data then return nil end
        for _, n in ipairs({ ... }) do
            local v = data:FindFirstChild(n)
            if v and v:IsA("ValueBase") then return tostring(v.Value) end
        end
        return nil
    end
    out.level  = readData("Level") or "?"
    out.bounty = getPlayerBounty(plr)
    out.total  = readData("Beli") or "-"
    out.fruit  = readData("DevilFruit", "Fruit", "DevilFruitValue") or "None"

    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        out.hp = math.floor(hum.Health)
        out.maxHp = math.floor(hum.MaxHealth)
    end

    for _, container in ipairs({ char, plr:FindFirstChild("Backpack") }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local isFruit = toolMatchesCategory(tool, "Blox Fruit")
                    if isFruit and (out.fruit == "None" or out.fruit == "") then
                        out.fruit = tool.Name
                    elseif isMeleeTool(tool) and out.style == "Combat" then
                        out.style = tool.Name
                    elseif toolMatchesCategory(tool, "Sword") and out.sword == "-" then
                        out.sword = tool.Name
                    elseif toolMatchesCategory(tool, "Gun") and out.gun == "-" then
                        out.gun = tool.Name
                    end
                end
            end
        end
    end
    out.fruit = tostring(out.fruit):gsub(" Fruit", "")
    out.style = tostring(out.style):gsub(" Fruit", "")
    return out
end

local function getPlayerByName(query)
    if not query or query == "" then return nil end
    local q = tostring(query):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if q == "" then return nil end
    local exact, partial
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local nm = plr.Name:lower()
            local dn = plr.DisplayName:lower()
            if nm == q or dn == q then
                exact = plr
            elseif not partial and (nm:find(q, 1, true) or dn:find(q, 1, true)) then
                partial = plr
            end
        end
    end
    return exact or partial
end

local function getPlayerList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(list, plr.Name) end
    end
    table.sort(list)
    return list
end

-- Gather all valid enemy targets in range for Multi-Target Fast Attack
local function getBladeHitTargets(radius)
    local root = getRoot()
    if not root then return nil, {}, {} end

    local maxDist = radius or Config.AttackRange or 65
    local primaryPart = nil
    local bladeHits = {}
    local rawParts = {}

    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, mob in ipairs(enemiesFolder:GetChildren()) do
            local hum = mob:FindFirstChildOfClass("Humanoid")
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            local head = mob:FindFirstChild("Head") or hrp
            if hum and hum.Health > 0 and hrp and head then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist <= maxDist then
                    if not primaryPart then
                        primaryPart = head
                    end
                    table.insert(bladeHits, {mob, head})
                    table.insert(rawParts, head)
                end
            end
        end
    end

    if Config.AttackPlayers then
        local charsFolder = Workspace:FindFirstChild("Characters")
        local list = charsFolder and charsFolder:GetChildren() or Players:GetPlayers()
        for _, entry in ipairs(list) do
            local char = entry:IsA("Player") and entry.Character or entry
            if char and char ~= LocalPlayer.Character then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head") or hrp
                if hum and hum.Health > 0 and hrp and head then
                    if (hrp.Position - root.Position).Magnitude <= maxDist then
                        if not primaryPart then primaryPart = head end
                        table.insert(bladeHits, {char, head})
                        table.insert(rawParts, head)
                    end
                end
            end
        end
    end

    return primaryPart, bladeHits, rawParts
end

-- Resolve CombatFramework activeController if executor supports getupvalues
local cachedCombatLib = nil
local function getActiveCombatController()
    local ok, controller = pcall(function()
        if not cachedCombatLib then
            local pScripts = LocalPlayer:FindFirstChild("PlayerScripts")
            local cfScript = pScripts and pScripts:FindFirstChild("CombatFramework")
            if cfScript then
                cachedCombatLib = debug.getupvalue(require(cfScript), 2)
            end
        end
        return cachedCombatLib and cachedCombatLib.activeController
    end)
    if ok then return controller end
    return nil
end

-- Fires the Triple-Layer attack packet stack at an explicit target list.
-- Used by Fast Attack, Kill Aura and the PvP hunter.
local function fireAttackPackets(primaryPart, bladeHits, rawParts, reachHint)
    local char = getCharacter()
    if not char or not primaryPart then return end
    bladeHits = bladeHits or {}
    rawParts = rawParts or {}

    -- Layer 1: Update 20-24+ Modules.Net Multi-Target Packet (RE/RegisterAttack + RE/RegisterHit)
    if #bladeHits > 0 then
        pcall(function()
            local modules = ReplicatedStorage:FindFirstChild("Modules")
            local net = modules and modules:FindFirstChild("Net")
            if net then
                local regAtk = net:FindFirstChild("RE/RegisterAttack")
                local regHit = net:FindFirstChild("RE/RegisterHit")
                if regAtk then
                    regAtk:FireServer(0)
                end
                if regHit then
                    regHit:FireServer(primaryPart, bladeHits)
                end
            end
        end)
    end

    -- Layer 2: CombatFramework & RigControllerEvent Direct Hit
    pcall(function()
        local ac = getActiveCombatController()
        if ac and ac.equipped then
            ac.timeToNextAttack = 0
            ac.attacking = false
            ac.blocking = false
            ac.focusStart = 0
            ac.increment = 3
            ac.hitboxMagnitude = reachHint or Config.AttackRange or 65

            if #rawParts > 0 then
                local rem = ReplicatedStorage:FindFirstChild("RigControllerEvent")
                local validator = ReplicatedStorage:FindFirstChild("Remotes")
                    and ReplicatedStorage.Remotes:FindFirstChild("Validator")
                if validator and ac.blades and ac.blades[1] then
                    pcall(function()
                        ac:attack()
                    end)
                end
                if rem then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        rem:FireServer("WeaponChange", tostring(tool.Name))
                    end
                    rem:FireServer("hit", rawParts, 3, "")
                end
            end
        end
    end)

    -- Layer 3: Equipped Tool:Activate() + VirtualUser Click
    pcall(function()
        local equippedTool = char:FindFirstChildOfClass("Tool")
        if equippedTool then
            equippedTool:Activate()
        end
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.zero)
        VirtualUser:Button1Up(Vector2.zero)
    end)
end

local function triggerFastAttack()
    local primaryPart, bladeHits, rawParts = getBladeHitTargets(Config.AttackRange)
    if primaryPart then
        fireAttackPackets(primaryPart, bladeHits, rawParts)
    end
end

-- Dedicated High-Speed Fast Attack Thread (runs during Farm OR when AutoAttackAlways is ON)
task.spawn(function()
    while true do
        local delayTime = math.clamp(Config.FastAttackDelay or 0.02, 0.01, 0.25)
        task.wait(delayTime)
        pcall(function()
            local isFarming = Config.AutoFarmLevel or Config.AutoFarmNearest or Config.AutoFarmBoss or Config.AutoFarmAllBosses
            if (isFarming and Config.FastAttack) or Config.AutoAttackAlways then
                triggerFastAttack()
            end
        end)
    end
end)

local function ensureBuso()
    if not Config.AutoBuso then return end
    local char = getCharacter()
    if char and not char:FindFirstChild("HasBuso") then
        invokeCommF("Buso")
    end
end

local function bringNearbyMobs(targetName, targetPos)
    if not Config.BringMobs then return end
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return end
    for _, mob in ipairs(enemies:GetChildren()) do
        if not targetName or mob.Name == targetName then
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            local hum = mob:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 and (hrp.Position - targetPos).Magnitude <= 350 then
                pcall(function()
                    hrp.CFrame = CFrame.new(targetPos)
                    hrp.CanCollide = false
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    if Config.HitboxExpander then
                        hrp.Size = Vector3.new(55, 55, 55)
                        hrp.Transparency = 1
                    end
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
                    local anim = hum:FindFirstChildOfClass("Animator")
                    if anim then anim:Destroy() end
                end)
            end
        end
    end
end

local function getQuestForLevel(lv)
    local list = QUEST_DATABASE[CURRENT_SEA] or QUEST_DATABASE[1]
    local chosen = list[1]
    for _, q in ipairs(list) do
        if lv >= q.MinLv then chosen = q end
    end
    return chosen
end

-- ═══════════════════════════════════════════════════════════════════════════
--  PLAYER PVP HUNTER ENGINE  (kill selected / kill PvP-enabled / aimlock / spectate)
-- ═══════════════════════════════════════════════════════════════════════════

local PvPState = {
    target = nil,
    targetName = "",
    lastAttack = 0,
    lastSkill = 0,
    hitboxOriginals = {},
}

-- ─── BUDDHA / GIANT FORM AWARENESS ─────────────────────────────────────────
-- Buddha (and every other grow/transformation) scales the WHOLE character model.
-- A head-only M1 packet therefore missed: the small Head part floats metres above
-- the pivot and the blade test almost never touched it. We now detect a scaled
-- model, aim at its torso centre and send *every* body part as a blade hit so any
-- contact registers, plus the hitbox scales with the model.

local GIANT_MARKER_NAMES = { "Buddha", "BuddhaForm", "GiantForm", "Transformation", "Giant", "BigMode" }

local function getCharBoundingBox(char)
    if not char then return nil, nil end
    local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
    if ok and cf and size then return cf, size end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.CFrame, hrp.Size end
    return nil, nil
end

local giantCache = {}
local function computeGiantForm(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and (tonumber(hum.HipHeight) or 0) > 6 then return true end
    local ok, size = pcall(function() return char:GetExtentsSize() end)
    if ok and size and size.Y > 11 then return true end
    for _, marker in ipairs(GIANT_MARKER_NAMES) do
        if char:FindFirstChild(marker) then return true end
    end
    for _, attr in ipairs({ "Buddha", "Giant", "Transformed", "IsGiant" }) do
        local v = char:GetAttribute(attr)
        if type(v) == "boolean" and v then return true end
    end
    local scale = char:GetAttribute("Scale") or char:GetAttribute("Size")
    if type(scale) == "number" and scale > 1.6 then return true end
    return false
end

-- cached for 0.4s: this is called from the __namecall hook on every game raycast
local function isGiantForm(char)
    if not char or not char.Parent then return false end
    local now = os.clock()
    local cached = giantCache[char]
    if cached and (now - cached.t) < 0.4 then return cached.v end
    local result = computeGiantForm(char)
    giantCache[char] = { t = now, v = result }

    local count = 0
    for key in pairs(giantCache) do
        count = count + 1
        if count > 96 or not key.Parent then giantCache[key] = nil end
    end
    return result
end

local function isBuddhaUser(plr)
    if not plr then return false end
    local data = plr:FindFirstChild("Data")
    local fruit = data and data:FindFirstChild("DevilFruit")
    if fruit and tostring(fruit.Value):lower():find("buddha", 1, true) then return true end
    for _, container in ipairs({ plr.Character, plr:FindFirstChild("Backpack") }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local original = tostring(tool:GetAttribute("OriginalName") or ""):lower()
                    if original:find("buddha", 1, true) or tool.Name:lower():find("buddha", 1, true) then return true end
                end
            end
        end
    end
    return false
end

local function getCharacterCombatParts(char)
    if not char or char == LocalPlayer.Character then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head") or hrp
    if not hum or not hrp or not head or hum.Health <= 0 then return nil end
    return { char = char, hum = hum, hrp = hrp, head = head }
end

local function castCombatSkills()
    local now = os.clock()
    if now - (PvPState.lastSkill or 0) < 0.4 then return end
    PvPState.lastSkill = now
    for _, key in ipairs({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V }) do
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end)
    end
end

-- Builds the complete blade payload for one character (giant / Buddha aware)
local function buildAttackPayload(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return nil end

    local head = char:FindFirstChild("Head") or hrp
    local giant = Config.BuddhaAwareCombat ~= false and isGiantForm(char)
    local bbox, size = getCharBoundingBox(char)

    local bladeHits, rawParts, seen = {}, {}, {}
    local function addPart(part)
        if part and part:IsA("BasePart") and not seen[part] then
            seen[part] = true
            table.insert(bladeHits, { char, part })
            table.insert(rawParts, part)
        end
    end

    if giant then
        -- every limb / torso / accessory part becomes a valid blade contact point
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") then addPart(d) end
        end
    end
    addPart(head)
    addPart(hrp)

    -- aim point: torso centre for giants (Head sits metres above the pivot), head otherwise
    local aimPoint = head.Position
    if giant and bbox and size then
        aimPoint = bbox.Position + Vector3.new(0, math.clamp(size.Y * 0.22, 2, 16), 0)
    end

    return {
        char = char, hum = hum, hrp = hrp, head = head,
        giant = giant, size = size, bbox = bbox,
        aimPoint = aimPoint, bladeHits = bladeHits, rawParts = rawParts,
    }
end

-- Attack one specific character (used by Auto Kill Selected / Auto Kill PvP / aimlock)
local function attackCharacter(char)
    local payload = buildAttackPayload(char)
    if not payload then return false end

    -- giants need extra reach: their model is several times taller
    local range = (Config.AttackRange or 65) + (payload.giant and (payload.size and payload.size.Y * 0.6 or 25) or 0)

    local _, extraBlade, extraRaw = getBladeHitTargets(range)
    for _, entry in ipairs(extraBlade or {}) do
        if entry[1] ~= payload.char and not payload.rawParts[entry[2]] then
            table.insert(payload.bladeHits, entry)
            table.insert(payload.rawParts, entry[2])
        end
    end
    for _, part in ipairs(extraRaw or {}) do
        if part ~= payload.head then table.insert(payload.rawParts, part) end
    end

    fireAttackPackets(payload.head, payload.bladeHits, payload.rawParts, range)
    return true
end

local function tweenToPlayer(plr, distance)
    local payload = buildAttackPayload(plr and plr.Character)
    if not payload then return false end
    local base = distance or Config.PvPTweenDistance or 12
    if payload.giant and payload.size then
        base = base + math.clamp(payload.size.Y * 0.35, 6, 26)
    end
    tweenTo(payload.hrp.CFrame * CFrame.new(0, base, 0))
    return true
end

-- ─── PLAYER HITBOX EXPANDER v2 ──────────────────────────────────────────────
-- Expands the WHOLE model (not just HumanoidRootPart), so Buddha/giant users get a
-- proportionally inflated hitbox instead of one blob part. Every touched part is
-- stored and restored exactly on disable, and the visualiser makes it visible.
local function storeHitboxState(key, char)
    local store = PvPState.hitboxOriginals[key]
    if store then return store end
    store = { parts = {}, order = {} }
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            store.parts[d] = { size = d.Size, transparency = d.Transparency, collide = d.CanCollide, massless = d.Massless }
            table.insert(store.order, d)
        end
    end
    PvPState.hitboxOriginals[key] = store
    return store
end

local function setPlayerHitbox(plr, expand)
    local char = plr and plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local key = plr.Name

    if expand then
        local store = storeHitboxState(key, char)
        local target = math.clamp(Config.PlayerHitboxSize or 14, 4, 60)
        local factor = math.min(target / math.max(hrp.Size.X, 0.5), 3)
        pcall(function()
            for _, part in ipairs(store.order) do
                if part.Parent then
                    local orig = store.parts[part]
                    if part == hrp then
                        part.Size = Vector3.new(target, target, target)
                    else
                        part.Size = orig.size * factor
                    end
                    part.CanCollide = false
                    part.Massless = true
                    if Config.ShowHitboxVisual then
                        part.Transparency = part == hrp and 0.6 or math.max(orig.transparency, 0.7)
                    else
                        part.Transparency = orig.transparency
                    end
                end
            end
        end)
    else
        local store = PvPState.hitboxOriginals[key]
        if store then
            pcall(function()
                for _, part in ipairs(store.order) do
                    if part.Parent then
                        local orig = store.parts[part]
                        part.Size = orig.size
                        part.Transparency = orig.transparency
                        part.CanCollide = orig.collide
                        part.Massless = orig.massless
                    end
                end
            end)
            PvPState.hitboxOriginals[key] = nil
        end
    end
end

local function isFriend(plr)
    if not Config.IgnoreFriendsPvP then return false end
    local ok, res = pcall(function() return LocalPlayer:IsFriendsWith(plr.UserId) end)
    return ok and res == true
end

-- Nearest player that is actually damageable (PvP ON / outside safe zone)
local function pickAutoKillTarget()
    local myRoot = getRoot()
    if not myRoot then return nil end
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local info = getCharacterCombatParts(plr.Character)
            if info and canAttackPlayer(plr) and not isFriend(plr) then
                local dist = (info.hrp.Position - myRoot.Position).Magnitude
                if dist < bestDist then bestDist, best = dist, plr end
            end
        end
    end
    return best, bestDist
end

-- Spectate controller
local SpectateState = { active = false, originalType = nil, originalSubject = nil }
local function setSpectate(plr)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local char = plr and plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if not SpectateState.active then
            SpectateState.originalType = cam.CameraType
            SpectateState.originalSubject = cam.CameraSubject
            SpectateState.active = true
        end
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = hum
    elseif SpectateState.active then
        pcall(function()
            if SpectateState.originalSubject and SpectateState.originalSubject.Parent then
                cam.CameraSubject = SpectateState.originalSubject
            end
            if SpectateState.originalType then cam.CameraType = SpectateState.originalType end
        end)
        SpectateState.active = false
    end
end

-- Main PvP tick: target selection, kill automation, hitbox control
task.spawn(function()
    while task.wait(0.09) do
        pcall(function()
            local target = nil

            if Config.AutoKillSelected then
                target = getPlayerByName(Config.SelectedPlayer)
                if not target then target = pickAutoKillTarget() end
            end
            if not target and Config.AutoKillPvP then
                target = pickAutoKillTarget()
            end
            if not target and (Config.AimLock or Config.PlayerHitbox or Config.SpectatePlayer) then
                target = getPlayerByName(Config.SelectedPlayer)
            end

            PvPState.target = target
            PvPState.targetName = target and target.Name or ""

            if target then
                local info = getCharacterCombatParts(target.Character)
                if info then
                    local shouldFight = Config.AutoKillSelected or Config.AutoKillPvP
                    if shouldFight then
                        local now = os.clock()
                        local myRoot = getRoot()
                        -- stay glued to the target (tweens only when far away)
                        if not myRoot or (info.hrp.Position - myRoot.Position).Magnitude > (Config.PvPTweenDistance or 12) then
                            tweenToPlayer(target)
                        end
                        if now - (PvPState.lastAttack or 0) >= 0.11 then
                            PvPState.lastAttack = now
                            attackCharacter(target.Character)

                            -- Kill Aura: slash every other attackable player in range too
                            if Config.AutoKillPvP and Config.KillAuraAllPvP ~= false then
                                local myPos = myRoot and myRoot.Position
                                for _, other in ipairs(Players:GetPlayers()) do
                                    if other ~= LocalPlayer and other ~= target and not isFriend(other) and canAttackPlayer(other) then
                                        local oInfo = getCharacterCombatParts(other.Character)
                                        if oInfo then
                                            local auraRange = Config.KillAuraRange or 95
                                            if not myPos or (oInfo.hrp.Position - myPos).Magnitude <= auraRange then
                                                attackCharacter(other.Character)
                                            end
                                        end
                                    end
                                end
                            end

                            if Config.PvPSkills ~= false then castCombatSkills() end
                        end
                    end
                    if Config.SpectatePlayer then setSpectate(target) end
                    if Config.PlayerHitbox then setPlayerHitbox(target, true) end
                end
            elseif Config.SpectatePlayer then
                setSpectate(nil)
            end

            -- restore hitboxes of players no longer targeted
            if next(PvPState.hitboxOriginals) then
                for name in pairs(PvPState.hitboxOriginals) do
                    if not (target and target.Name == name) or not Config.PlayerHitbox then
                        local plr = getPlayerByName(name)
                        if plr then setPlayerHitbox(plr, false) else PvPState.hitboxOriginals[name] = nil end
                    end
                end
            end
        end)
    end
end)

-- Skill Aimbot / AimLock camera controller
RunService.RenderStepped:Connect(function(dt)
    if not Config.AimLock then return end
    pcall(function()
        local cam = Workspace.CurrentCamera
        local target = PvPState.target
        local info = getCharacterCombatParts(target and target.Character)
        local myRoot = getRoot()
        if not cam or not info or not myRoot then return end
        local fov = Config.AimLockFOV or 300
        if fov > 0 and (info.hrp.Position - myRoot.Position).Magnitude > fov then return end

        local aimPos = info.head.Position
        if Config.BuddhaAwareCombat ~= false and isGiantForm(target.Character) then
            local bbox, size = getCharBoundingBox(target.Character)
            if bbox and size then aimPos = bbox.Position + Vector3.new(0, math.clamp(size.Y * 0.22, 2, 16), 0) end
        end
        local goal = CFrame.lookAt(cam.CFrame.Position, aimPos)
        local alpha = math.clamp(Config.AimLockSmoothness or 0.3, 0.05, 1)
        cam.CFrame = cam.CFrame:Lerp(goal, alpha)
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  MOB HITBOX EXPANDER v2  (works even with Bring Mobs OFF)
--  · inflates the HumanoidRootPart of every living enemy inside the configured
--    radius and marks all their parts non-colliding/massless
--  · remembers the exact original size/transparency of every touched part and
--    restores it the moment the mob leaves range, dies or the toggle is turned off
-- ═══════════════════════════════════════════════════════════════════════════

local MobHitboxStore = {}
local mobStoreCount = 0

task.spawn(function()
    while task.wait(0.35) do
        pcall(function()
            local enemies = Workspace:FindFirstChild("Enemies")
            if not enemies then return end
            local root = getRoot()
            local size = math.clamp(Config.HitboxMobsSize or 55, 6, 90)
            local range = Config.HitboxMobsRange or 420

            for _, mob in ipairs(enemies:GetChildren()) do
                local hum = mob:FindFirstChildOfClass("Humanoid")
                local hrp = mob:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 and hrp.Parent then
                    local inRange = (not root) or (hrp.Position - root.Position).Magnitude <= range
                    if Config.HitboxMobs and inRange then
                        local store = MobHitboxStore[mob]
                        if not store then
                            store = { parts = {}, order = {} }
                            for _, d in ipairs(mob:GetDescendants()) do
                                if d:IsA("BasePart") then
                                    store.parts[d] = { size = d.Size, transparency = d.Transparency, collide = d.CanCollide }
                                    table.insert(store.order, d)
                                end
                            end
                            MobHitboxStore[mob] = store
                            mobStoreCount = mobStoreCount + 1
                        end
                        hrp.Size = Vector3.new(size, size, size)
                        hrp.CanCollide = false
                        hrp.Massless = true
                        for _, part in ipairs(store.order) do
                            if part ~= hrp and part.Parent then
                                part.CanCollide = false
                                part.Massless = true
                                if Config.ShowHitboxVisual then part.Transparency = math.max(part.Transparency, 0.75) end
                            end
                        end
                    elseif MobHitboxStore[mob] then
                        local store = MobHitboxStore[mob]
                        for _, part in ipairs(store.order) do
                            if part.Parent then
                                local orig = store.parts[part]
                                part.Size = orig.size
                                part.Transparency = orig.transparency
                                part.CanCollide = orig.collide
                            end
                        end
                        MobHitboxStore[mob] = nil
                        mobStoreCount = math.max(mobStoreCount - 1, 0)
                    end
                elseif MobHitboxStore[mob] then
                    local store = MobHitboxStore[mob]
                    for _, part in ipairs(store.order) do
                        if part.Parent then
                            local orig = store.parts[part]
                            part.Size = orig.size
                            part.Transparency = orig.transparency
                            part.CanCollide = orig.collide
                        end
                    end
                    MobHitboxStore[mob] = nil
                    mobStoreCount = math.max(mobStoreCount - 1, 0)
                end
            end

            -- sweep dead references so the store never leaks
            if mobStoreCount > 0 then
                for mob, store in pairs(MobHitboxStore) do
                    if not mob.Parent then
                        MobHitboxStore[mob] = nil
                        mobStoreCount = mobStoreCount - 1
                    end
                end
            end
        end)
    end
end)

-- Skill Aimbot · __namecall ray-redirect hook.
-- While AimLock is engaged every mouse-hit / raycast the game performs for M1s is
-- re-aimed at the locked target head (the returned result stays a real engine
-- raycast, so hit registration is genuine instead of faked).
local aimHookInstalled = false
local function installAimRayHook()
    if aimHookInstalled then return end
    if not hookmetamethod or not getnamecallmethod then return end
    aimHookInstalled = true
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if Config.AimLock and method then
                local targetChar = PvPState.target and PvPState.target.Character
                local info = getCharacterCombatParts(targetChar)
                if info then
                    -- Buddha/giants: aim at the torso centre, the Head is metres away
                    local aimPos = info.head.Position
                    if Config.BuddhaAwareCombat ~= false and isGiantForm(targetChar) then
                        local bbox, size = getCharBoundingBox(targetChar)
                        if bbox and size then
                            aimPos = bbox.Position + Vector3.new(0, math.clamp(size.Y * 0.22, 2, 16), 0)
                        end
                    end
                    local args = { ... }
                    if method == "FindPartOnRayWithIgnoreList" and args[1] then
                        local ray = args[1]
                        local dir = aimPos - ray.Origin
                        if dir.Magnitude > 0.1 then
                            local newRay = Ray.new(ray.Origin, dir.Unit * math.clamp(dir.Magnitude + 8, 1, 600))
                            return oldNamecall(self, newRay, args[2], select(3, ...))
                        end
                    elseif method == "FindPartOnRay" and args[1] then
                        local ray = args[1]
                        local dir = aimPos - ray.Origin
                        if dir.Magnitude > 0.1 then
                            local newRay = Ray.new(ray.Origin, dir.Unit * math.clamp(dir.Magnitude + 8, 1, 600))
                            return oldNamecall(self, newRay, select(2, ...))
                        end
                    elseif method == "Raycast" and args[1] and args[2] then
                        local origin = args[1]
                        local dir = aimPos - origin
                        if dir.Magnitude > 0.1 then
                            return oldNamecall(self, origin, dir, select(3, ...))
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
end
installAimRayHook()

-- ═══════════════════════════════════════════════════════════════════════════
--  UNDETECTED BYPASS FLY v2  (velocity driven · smooth · AutoFarm / PvP aware)
--  · motion is driven by BodyVelocity + BodyGyro, so the character glides instead
--    of being CFrame-teleported every frame (that is what caused the stutter and
--    the server rubber-banding you felt)
--  · an invisible client-only pad (SkillHubClientFloorPad) follows right under the
--    feet so the Humanoid stays grounded (Running state) — no Freefall, no
--    PlatformStand, no velocity spikes ⇒ nothing for the anti-cheat to flag
--  · Auto Farm / Boss Hunter / PvP Hunter travel requests are handed to the fly
--    autopilot (see MovementLink) so fly and farming work *together*
--  · WASD steer · Space = up · LeftShift = down · releasing keys = stable hover
-- ═══════════════════════════════════════════════════════════════════════════

local FloorPad = { part = nil }

local function ensureFloorPad(offsetY)
    local root = getRoot()
    if not root then return nil end
    if not FloorPad.part or not FloorPad.part.Parent then
        local pad = Instance.new("Part")
        pad.Name = "SkillHubClientFloorPad"
        pad.Size = Vector3.new(6, 0.4, 6)
        pad.Anchored = true
        pad.CanCollide = true
        pad.CanQuery = false
        pad.CanTouch = false
        pad.CastShadow = false
        pad.Massless = true
        pad.Transparency = 1
        pad.Material = Enum.Material.Plastic
        pad.Parent = Workspace
        FloorPad.part = pad
    end
    FloorPad.part.CFrame = CFrame.new(root.Position - Vector3.new(0, offsetY or 3.0, 0))
    return FloorPad.part
end

local function removeFloorPad()
    if FloorPad.part then
        pcall(function() FloorPad.part:Destroy() end)
        FloorPad.part = nil
    end
end

-- returns direction, hasManualInput
local function readFlyDirection()
    local cam = Workspace.CurrentCamera
    local dir = Vector3.zero
    if not cam then return dir, false end
    local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
    local pressed = false
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Vector3.new(look.X, 0, look.Z) pressed = true end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Vector3.new(look.X, 0, look.Z) pressed = true end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Vector3.new(right.X, 0, right.Z) pressed = true end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Vector3.new(right.X, 0, right.Z) pressed = true end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) pressed = true end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) pressed = true end
    if dir.Magnitude > 0 then dir = dir.Unit end
    return dir, pressed
end

local Fly = {
    conn           = nil,
    active         = false,
    bodyVel        = nil,
    bodyGyro       = nil,
    vel            = nil,
    autopilot      = nil,
    autopilotAt    = 0,
    autopilotSpeed = nil,
    manualHold     = 0,
    savedWalk      = nil,
}

local function flyDestroyBodies()
    if Fly.bodyVel then pcall(function() Fly.bodyVel:Destroy() end) Fly.bodyVel = nil end
    if Fly.bodyGyro then pcall(function() Fly.bodyGyro:Destroy() end) Fly.bodyGyro = nil end
end

local function flyEnsureBodies(root)
    if not root then return end

    -- Orientation holder (keeps the character upright + facing the flight path)
    if not (Fly.bodyGyro and Fly.bodyGyro.Parent == root) then
        if Fly.bodyGyro then pcall(function() Fly.bodyGyro:Destroy() end) end
        local bg = Instance.new("BodyGyro")
        bg.Name = "SkillHubFlyGyro"
        bg.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
        bg.P = 3000
        bg.D = 120
        bg.CFrame = CFrame.lookAt(root.Position, root.Position + root.CFrame.LookVector)
        bg.Parent = root
        Fly.bodyGyro = bg
    end

    -- Bypass Mode drives the character through the velocity property only (no
    -- extra instances inside the character at all). Raw Mode uses BodyVelocity.
    if Config.FlyBypassMode then
        if Fly.bodyVel then pcall(function() Fly.bodyVel:Destroy() end) Fly.bodyVel = nil end
    elseif not (Fly.bodyVel and Fly.bodyVel.Parent == root) then
        if Fly.bodyVel then pcall(function() Fly.bodyVel:Destroy() end) end
        local bv = Instance.new("BodyVelocity")
        bv.Name = "SkillHubFlyVelocity"
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.P = 1250
        bv.Velocity = Vector3.zero
        bv.Parent = root
        Fly.bodyVel = bv
    end
end

local function flySetTarget(targetCFrame, speedOverride)
    if not targetCFrame then return end
    if Config.FlyJoinAutopilot == false then return end
    Fly.autopilot = targetCFrame.Position
    Fly.autopilotAt = os.clock()
    if speedOverride and tonumber(speedOverride) then
        Fly.autopilotSpeed = tonumber(speedOverride)
    end
end

local function flyClearTarget()
    Fly.autopilot = nil
    Fly.autopilotSpeed = nil
end

-- makes the character hover exactly where it is (used on disable / respawn)
local function flyBrake(root)
    if Fly.bodyVel and Fly.bodyVel.Parent then
        Fly.bodyVel.Velocity = Vector3.zero
    end
    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

local function flyDisable()
    if Fly.conn then
        pcall(function() Fly.conn:Disconnect() end)
        Fly.conn = nil
    end
    Fly.active = false
    MovementLink.isFlyActive = function() return false end
    flyBrake(getRoot())
    flyDestroyBodies()
    Fly.vel = nil
    Fly.autopilot = nil
    Fly.autopilotSpeed = nil

    local hum = getHumanoid()
    if hum and Fly.savedWalk then
        pcall(function()
            if hum.WalkSpeed == 0 then hum.WalkSpeed = Fly.savedWalk end
        end)
    end
    Fly.savedWalk = nil

    if not Config.WalkOnWater then removeFloorPad() end
end

local function flyStep(dt)
    local root, hum = getRoot(), getHumanoid()
    if not root or not hum or hum.Health <= 0 then flyDisable() return end

    flyEnsureBodies(root)
    hum.PlatformStand = false

    -- own the movement while flying: the character controller must not also walk
    if Config.FlyZeroWalkSpeed ~= false then
        if Fly.savedWalk == nil then Fly.savedWalk = hum.WalkSpeed end
        if hum.WalkSpeed ~= 0 then hum.WalkSpeed = 0 end
    end

    local speed = math.clamp(Fly.autopilotSpeed or Config.FlySpeed or 60, 10, 900)
    local dir, manual = readFlyDirection()
    if manual then
        Fly.manualHold = os.clock()
        Fly.autopilotSpeed = nil
    end

    -- Auto Farm / Boss Hunter / PvP Hunter travel request (autopilot) when idle
    local autoPilotActive = false
    if not manual and Fly.autopilot and (os.clock() - Fly.autopilotAt) < 1.5 then
        local delta = Fly.autopilot - root.Position
        if delta.Magnitude > 6 then
            dir = delta.Unit
            autoPilotActive = true
            if Config.FlyBypassMode then
                -- never overshoot the destination
                speed = math.min(speed, math.max(delta.Magnitude * 2, 30))
            end
        elseif (os.clock() - Fly.autopilotAt) > 0.5 then
            Fly.autopilot = nil
            Fly.autopilotSpeed = nil
        end
    end

    local moving = manual or autoPilotActive
    local targetVel = moving and (dir * speed) or Vector3.zero

    -- smooth acceleration, clamped so no velocity spike can ever be flagged
    local baseVel = Fly.vel or root.AssemblyLinearVelocity
    if Config.FlyBypassMode then
        local maxDelta = math.min(math.max(speed * 0.09, 5), 60)
        local delta = targetVel - baseVel
        if delta.Magnitude > maxDelta then targetVel = baseVel + delta.Unit * maxDelta end
        local alpha = moving and math.clamp(dt * 14, 0.25, 0.9) or math.clamp(dt * 12, 0.2, 0.7)
        Fly.vel = baseVel:Lerp(targetVel, alpha)
        if Fly.vel.Magnitude < 0.8 then Fly.vel = Vector3.zero end

        -- stealth motion: pure velocity property, nothing new inside the character
        root.AssemblyLinearVelocity = Fly.vel
    else
        Fly.vel = targetVel
        local bv = Fly.bodyVel
        if bv then bv.Velocity = targetVel else root.AssemblyLinearVelocity = targetVel end
    end

    -- keep the character upright and facing the flight direction
    local bg = Fly.bodyGyro
    if bg and bg.Parent then
        local face
        if manual and dir.Magnitude > 0.05 then
            face = Vector3.new(dir.X, 0, dir.Z)
        else
            local cam = Workspace.CurrentCamera
            local camLook = cam and cam.CFrame.LookVector or root.CFrame.LookVector
            face = Vector3.new(camLook.X, 0, camLook.Z)
        end
        if face.Magnitude < 0.05 then face = root.CFrame.LookVector end
        bg.CFrame = CFrame.lookAt(root.Position, root.Position + face.Unit)
    end

    -- anti-flag: invisible pad right under the feet keeps the Humanoid grounded
    ensureFloorPad(3.0)
    if hum:GetState() ~= Enum.HumanoidStateType.Running then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
    end

    -- anti-void rescue
    if Config.FlyAntiVoid and root.Position.Y < -120 then
        Fly.vel = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = CFrame.new(root.Position.X, 60, root.Position.Z)
    end
end

local function flyEnable()
    if Fly.active then return end
    Fly.active = true
    MovementLink.isFlyActive = function() return Fly.active end
    MovementLink.setFlyTarget = flySetTarget
    MovementLink.clearFlyTarget = flyClearTarget
    flyEnsureBodies(getRoot())
    Fly.conn = RunService.RenderStepped:Connect(function(dt)
        if not Config.FlyEnabled then flyDisable() return end
        pcall(function() flyStep(dt) end)
    end)
end

-- Re-arm the fly automatically after a respawn / death
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if Config.FlyEnabled and not Fly.active then flyEnable() end
end)

local function setFlyState(enabled)
    Config.FlyEnabled = enabled
    if enabled then
        flyEnable()
        Hooks.notify("Undetected Fly", "Fly ON — WASD to steer, Space up, LeftShift down. Auto Farm & PvP auto-pilot through it.", 4, CustomIcons.Fly)
    else
        flyDisable()
        Hooks.notify("Undetected Fly", "Fly OFF", 2, CustomIcons.Stop)
    end
end

-- Walk on Water / pad lifecycle loop
task.spawn(function()
    while task.wait(0.12) do
        pcall(function()
            local hum, root = getHumanoid(), getRoot()
            local used = false
            if Config.WalkOnWater and hum and root then
                if hum.FloorMaterial == Enum.Material.Water or hum:GetState() == Enum.HumanoidStateType.Swimming then
                    ensureFloorPad(3.02)
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                    used = true
                end
            end
            if not used and not Config.FlyEnabled and FloorPad.part then removeFloorPad() end
        end)
    end
end)

-- Infinite Geppo / Skyjump (uses the game's own skyjump first, physics fallback after)
task.spawn(function()
    local lastGeppo = 0
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not Config.InfiniteGeppo then return end
        if input.KeyCode ~= Enum.KeyCode.Space and input.KeyCode ~= Enum.KeyCode.ButtonA then return end
        local hum, root = getHumanoid(), getRoot()
        if not hum or not root then return end
        if hum:GetState() ~= Enum.HumanoidStateType.Freefall then return end
        local now = os.clock()
        if now - lastGeppo < 0.1 then return end
        lastGeppo = now
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 68, root.AssemblyLinearVelocity.Z)
        end)
    end)
end)

-- Infinite Energy (keeps Aura / Buso / Ken topped up — those drain Energy in Blox Fruits)
task.spawn(function()
    while task.wait(0.4) do
        if Config.InfiniteEnergy then
            pcall(function()
                local data = LocalPlayer:FindFirstChild("Data")
                if data then
                    for _, n in ipairs({ "Energy", "MaxEnergy", "AuraEnergy" }) do
                        local v = data:FindFirstChild(n)
                        if v and v:IsA("NumberValue") then v.Value = 1000000 end
                    end
                end
                local char = getCharacter()
                local energy = char and char:FindFirstChild("Energy")
                if energy and energy:IsA("NumberValue") then energy.Value = 1000000 end
                if Config.InfiniteEnergy then
                    invokeCommF("Buso")
                    if Config.AutoKen then invokeCommF("Ken", true) end
                end
            end)
        end
    end
end)

-- Dash cooldown removal
task.spawn(function()
    local lastDash = 0
    while task.wait(0.05) do
        pcall(function()
            if not Config.NoDashCooldown then return end
            local hum, root = getHumanoid(), getRoot()
            if not hum or not root then return end
            if hum.MoveDirection.Magnitude < 0.1 then return end
            if hum:GetState() == Enum.HumanoidStateType.Freefall then return end
            local now = os.clock()
            if now - lastDash < (Config.DashInterval or 0.32) then return end
            lastDash = now
            local kick = hum.MoveDirection * 46
            root.AssemblyLinearVelocity = Vector3.new(kick.X, root.AssemblyLinearVelocity.Y, kick.Z)
            pcall(function()
                local rem = ReplicatedStorage:FindFirstChild("Remotes")
                local commE = rem and rem:FindFirstChild("CommE")
                if commE then commE:FireServer("Dash") end
            end)
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  FRUIT MAGNET & DROP COLLECTOR (firetouchinterest + Handle pull + tween fallback)
-- ═══════════════════════════════════════════════════════════════════════════

local function magnetPart(handle, tweenFallback)
    local root = getRoot()
    if not handle or not root then return end
    if firetouchinterest then
        pcall(function()
            firetouchinterest(root, handle, 0)
            firetouchinterest(root, handle, 1)
        end)
        pcall(function()
            firetouchinterest(handle, root, 0)
            firetouchinterest(handle, root, 1)
        end)
    end
    pcall(function()
        handle.CanCollide = false
        handle.AssemblyLinearVelocity = Vector3.zero
        handle.CFrame = root.CFrame * CFrame.new(0, -1.2, 0)
    end)
    if tweenFallback then tweenTo(root.CFrame) end
end

local function findFruitHandles(radius)
    local root = getRoot()
    local found = {}
    if not root then return found end
    local maxDist = radius or Config.FruitMagnetRadius or 600
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Tool") or obj:IsA("Model") or obj.Name:lower():find("fruit", 1, true) then
            local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
            if handle and (handle.Position - root.Position).Magnitude <= maxDist then
                table.insert(found, { obj = obj, handle = handle, dist = (handle.Position - root.Position).Magnitude })
            end
        end
    end
    return found
end

task.spawn(function()
    while task.wait(0.05) do
        if Config.FruitMagnet then
            pcall(function()
                for _, entry in ipairs(findFruitHandles()) do
                    magnetPart(entry.handle, false)
                end
            end)
        end
    end
end)

-- Auto Collect Drops (dropped weapons / tool loot on the ground)
task.spawn(function()
    while task.wait(0.3) do
        if Config.AutoCollectDrops then
            pcall(function()
                local root = getRoot()
                if not root then return end
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA("Tool") then
                        local handle = obj:FindFirstChild("Handle")
                        if handle and (handle.Position - root.Position).Magnitude <= 900 then magnetPart(handle, false) end
                    elseif obj:IsA("Model") then
                        local name = obj.Name:lower()
                        if name:find("drop", 1, true) or name:find("reward", 1, true) or name:find("chest", 1, true) then
                            local handle = obj:FindFirstChildWhichIsA("BasePart")
                            if handle and (handle.Position - root.Position).Magnitude <= 250 then magnetPart(handle, false) end
                        end
                    end
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  RANDOM FRUIT ROLLER + AUTO-STORE (Zioles gacha, OriginalName aware)
-- ═══════════════════════════════════════════════════════════════════════════

local watchedContainers = {}
local function bindFruitWatcher(container)
    if not container or watchedContainers[container] then return end
    watchedContainers[container] = true
    container.ChildAdded:Connect(function(tool)
        task.wait(0.15)
        if not tool:IsA("Tool") then return end
        local original = tool:GetAttribute("OriginalName")
        local isFruit = original ~= nil or toolMatchesCategory(tool, "Blox Fruit") or tool:FindFirstChild("Handle") and tool.Name:lower():find("fruit", 1, true)
        if not isFruit then return end

        local fruitName = tostring(original or tool.Name):gsub(" Fruit", "")
        Config.RolledFruitName = fruitName
        Hooks.notify("Fruit Rolled / Obtained", fruitName .. "  •  rarity: " .. getFruitTier(fruitName).name, 4, CustomIcons.Fruits)

        if Config.AutoStoreRolled and Config.AutoStoreFruits ~= false then
            local code = FRUIT_STORE_CODES[fruitName] or (fruitName .. "-" .. fruitName)
            task.wait(0.35)
            invokeCommF("StoreFruit", code, tool)
        end
    end)
end

local function bindAllFruitWatchers()
    bindFruitWatcher(LocalPlayer:FindFirstChild("Backpack"))
    bindFruitWatcher(LocalPlayer.Character)
end
bindAllFruitWatchers()
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    bindFruitWatcher(LocalPlayer:FindFirstChild("Backpack"))
    bindFruitWatcher(char)
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  SEA EVENT / MIRAGE / KITSUNE / MYSTIC GEAR TRACKER
-- ═══════════════════════════════════════════════════════════════════════════

local function scanSeaEvents()
    local myRoot = getRoot()
    local found = {}
    local scanRoots = {}
    for _, child in ipairs(Workspace:GetChildren()) do table.insert(scanRoots, child) end
    for _, folderName in ipairs({ "Enemies", "Characters", "NPCs", "Map", "Islands", "_WorldOrigin" }) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then table.insert(scanRoots, folder) end
    end

    local visited = {}
    local function inspect(obj)
        if visited[obj] then return end
        visited[obj] = true
        local name = obj.Name
        if type(name) ~= "string" or #name < 4 then return end
        local lower = name:lower()
        for _, sig in ipairs(SEA_EVENT_SIGNATURES) do
            for _, key in ipairs(sig.Keys) do
                if lower:find(key, 1, true) then
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        table.insert(found, {
                            name = sig.Name, color = sig.Color, pos = part.Position,
                            obj = part, dist = myRoot and math.floor((part.Position - myRoot.Position).Magnitude) or 0,
                        })
                    end
                    return
                end
            end
        end
    end

    pcall(function()
        for _, top in ipairs(scanRoots) do
            inspect(top)
            for _, child in ipairs(top:GetChildren()) do
                inspect(child)
                for _, grand in ipairs(child:GetChildren()) do inspect(grand) end
            end
        end
    end)
    return found
end

task.spawn(function()
    while task.wait(3.5) do
        pcall(function()
            if not Config.SeaEventTracker and not Config.MirageFinder then return end
            local events = scanSeaEvents()
            SeaEventState.events = events
            local mirage = {}
            for _, ev in ipairs(events) do
                if ev.name == "Mirage Island" or ev.name == "Kitsune Shrine" or ev.name == "Blue Gear / Mystic" or ev.name == "Prehistoric Island" then
                    table.insert(mirage, ev)
                end
            end
            SeaEventState.mirage = mirage

            if Config.SeaEventTracker then
                for _, ev in ipairs(events) do
                    local key = ev.name .. math.floor(ev.pos.X / 500) .. math.floor(ev.pos.Z / 500)
                    if not SeaEventState.lastNotify[key] then
                        SeaEventState.lastNotify[key] = true
                        local isSpecial = ev.name ~= "Cursed Ship Raid"
                        if isSpecial or Config.MirageFinder then
                            Hooks.notify(ev.name .. " detected", string.format("%d studs away • %.0f, %.0f", ev.dist, ev.pos.X, ev.pos.Z), 4, CustomIcons.Teleport)
                        end
                    end
                end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  SERVER STATUS SNAPSHOT (rendered by the Server Status HUD)
-- ═══════════════════════════════════════════════════════════════════════════

local function getServerStatus()
    local ping = 0
    pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    local region = "?"
    pcall(function() region = tostring(game:GetService("LocalizationService").RobloxLocaleId) end)
    return {
        jobId = (game.JobId ~= "" and game.JobId:sub(1, 8)) or "PRIVATE",
        players = #Players:GetPlayers(),
        maxPlayers = Players.MaxPlayers,
        ping = ping,
        region = region,
        sea = CURRENT_SEA,
        source = SEA_DETECT_SOURCE,
        events = #(SeaEventState.events or {}),
        up = math.floor(time() - (game:GetService("RunService"):IsStudio() and time() or 0)),
    }
end

-- Sea auto-correction loop: re-detect for the first minute (map parts stream in late)
task.spawn(function()
    for _ = 1, 40 do
        task.wait(1.5)
        pcall(function()
            local before = CURRENT_SEA
            refreshSea()
            if CURRENT_SEA ~= before then
                LocalPlayer:SetAttribute("SkillHubSea", CURRENT_SEA)
            else
                LocalPlayer:SetAttribute("SkillHubSea", CURRENT_SEA)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  BACKGROUND FEATURE LOOPS
-- ═══════════════════════════════════════════════════════════════════════════

task.spawn(function()
    while task.wait(0.12) do
        pcall(function()
            local char = getCharacter()
            local root = getRoot()
            local hum  = getHumanoid()
            if not char or not root or not hum or hum.Health <= 0 then return end

            if Config.AutoFarmLevel then
                ensureBuso()
                equipWeaponByType(Config.SelectedWeaponType)
                local qData = getQuestForLevel(getPlayerLevel())
                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                local mainGui = pGui and pGui:FindFirstChild("Main")
                local questFrame = mainGui and mainGui:FindFirstChild("Quest")

                if questFrame and not questFrame.Visible then
                    tweenTo(qData.QPos)
                    if (root.Position - qData.QPos.Position).Magnitude < 20 then
                        invokeCommF("StartQuest", qData.Quest, qData.QNum)
                    end
                else
                    local enemies = Workspace:FindFirstChild("Enemies")
                    local targetMob = nil
                    if enemies then
                        for _, mob in ipairs(enemies:GetChildren()) do
                            local mHum = mob:FindFirstChildOfClass("Humanoid")
                            local mHrp = mob:FindFirstChild("HumanoidRootPart")
                            if mob.Name == qData.Mob and mHum and mHum.Health > 0 and mHrp then
                                targetMob = mob
                                break
                            end
                        end
                    end

                    if targetMob then
                        local mHrp = targetMob.HumanoidRootPart
                        tweenTo(mHrp.CFrame * CFrame.new(0, Config.FarmDistance, 0))
                        bringNearbyMobs(qData.Mob, mHrp.Position)
                        if Config.FastAttack then triggerFastAttack() end
                    else
                        tweenTo(qData.MPos * CFrame.new(0, Config.FarmDistance, 0))
                    end
                end

            elseif Config.AutoFarmNearest then
                ensureBuso()
                equipWeaponByType(Config.SelectedWeaponType)
                local enemies = Workspace:FindFirstChild("Enemies")
                local nearest, minDist = nil, math.huge
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local mHum = mob:FindFirstChildOfClass("Humanoid")
                        local mHrp = mob:FindFirstChild("HumanoidRootPart")
                        if mHum and mHum.Health > 0 and mHrp then
                            local d = (mHrp.Position - root.Position).Magnitude
                            if d < minDist then
                                minDist = d
                                nearest = mob
                            end
                        end
                    end
                end
                if nearest then
                    local mHrp = nearest.HumanoidRootPart
                    tweenTo(mHrp.CFrame * CFrame.new(0, Config.FarmDistance, 0))
                    bringNearbyMobs(nearest.Name, mHrp.Position)
                    if Config.FastAttack then triggerFastAttack() end
                end

            elseif Config.AutoFarmBoss or Config.AutoFarmAllBosses then
                ensureBuso()
                equipWeaponByType(Config.SelectedWeaponType)
                local enemies = Workspace:FindFirstChild("Enemies")
                local targetBoss = nil
                local seaBosses = BOSSES_BY_SEA[CURRENT_SEA] or {}

                local selectedBossName = tostring(Config.SelectedBoss):gsub("^S%d%s•%s", "")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local mHum = mob:FindFirstChildOfClass("Humanoid")
                        local mHrp = mob:FindFirstChild("HumanoidRootPart")
                        if mHum and mHum.Health > 0 and mHrp then
                            if Config.AutoFarmBoss and mob.Name:find(selectedBossName, 1, true) then
                                targetBoss = mob
                                break
                            elseif Config.AutoFarmAllBosses then
                                local allBossNames = {}
                                for seaIdx = 1, 3 do
                                    for _, bName in ipairs(BOSSES_BY_SEA[seaIdx] or {}) do table.insert(allBossNames, bName) end
                                end
                                for _, bName in ipairs(allBossNames) do
                                    if mob.Name:find(bName, 1, true) then
                                        targetBoss = mob
                                        break
                                    end
                                end
                            end
                        end
                    end
                end

                if targetBoss then
                    local mHrp = targetBoss.HumanoidRootPart
                    tweenTo(mHrp.CFrame * CFrame.new(0, Config.FarmDistance, 0))
                    if Config.FastAttack then triggerFastAttack() end
                end
            end
        end)
    end
end)

-- Auto Skill Cast & Sovereign Aura Loop
task.spawn(function()
    while task.wait(0.35) do
        pcall(function()
            local keys = {
                {Enabled = Config.AutoSkillComboZ, Key = Enum.KeyCode.Z},
                {Enabled = Config.AutoSkillComboX, Key = Enum.KeyCode.X},
                {Enabled = Config.AutoSkillComboC, Key = Enum.KeyCode.C},
                {Enabled = Config.AutoSkillComboV, Key = Enum.KeyCode.V},
            }
            for _, k in ipairs(keys) do
                if k.Enabled then
                    VirtualInputManager:SendKeyEvent(true, k.Key, false, game)
                    task.wait(0.08)
                    VirtualInputManager:SendKeyEvent(false, k.Key, false, game)
                end
            end

            if Config.SovereignHakiAura then
                local root = getRoot()
                if root then
                    local offset = Vector3.new(math.random(-30, 30) / 10, -2.5, math.random(-30, 30) / 10)
                    local spark = Instance.new("Part")
                    spark.Anchored = true
                    spark.CanCollide = false
                    spark.Shape = Enum.PartType.Ball
                    spark.Material = Enum.Material.Neon
                    spark.Color = Color3.fromRGB(56, 189, 248)
                    spark.Size = Vector3.new(0.6, 1.8, 0.6)
                    spark.CFrame = CFrame.new(root.Position + offset)
                    spark.Transparency = 0.2
                    spark.Parent = Workspace
                    TweenService:Create(spark, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
                        CFrame = spark.CFrame + Vector3.new(0, 6, 0),
                        Transparency = 1,
                        Size = Vector3.new(0.1, 3.8, 0.1),
                    }):Play()
                    Debris:AddItem(spark, 0.55)
                end
            end
        end)
    end
end)

-- Auto Stats Loop
task.spawn(function()
    while task.wait(0.4) do
        pcall(function()
            local batch = Config.StatPointsBatch
            if Config.AutoStatMelee   then invokeCommF("AddPoint", "Melee", batch) end
            if Config.AutoStatDefense then invokeCommF("AddPoint", "Defense", batch) end
            if Config.AutoStatSword   then invokeCommF("AddPoint", "Sword", batch) end
            if Config.AutoStatGun     then invokeCommF("AddPoint", "Gun", batch) end
            if Config.AutoStatFruit   then invokeCommF("AddPoint", "Demon Fruit", batch) end
        end)
    end
end)

-- Fruit Sniper & Raid Loop
task.spawn(function()
    while task.wait(1.2) do
        pcall(function()
            if Config.AutoSniperStock then
                invokeCommF("GetFruits")
                invokeCommF("PurchaseRawFruit", Config.SelectedFruit, false)
            end
            if Config.AutoRandomFruit then
                invokeCommF("Cousin", "Buy")
            end
            if Config.AutoGrabMapFruits then
                local root = getRoot()
                if root then
                    for _, obj in ipairs(Workspace:GetChildren()) do
                        if obj:IsA("Tool") or obj.Name:lower():find("fruit") then
                            local handle = obj:FindFirstChild("Handle")
                            if handle and handle:IsA("BasePart") then
                                tweenTo(handle.CFrame)
                                break
                            end
                        end
                    end
                end
            end
            if Config.AutoStoreFruits then
                local containers = {LocalPlayer:FindFirstChild("Backpack"), getCharacter()}
                for _, container in ipairs(containers) do
                    if container then
                        for _, tool in ipairs(container:GetChildren()) do
                            if tool:IsA("Tool") and tool.Name:find("Fruit") then
                                local cleanName = tool.Name:gsub(" Fruit", "")
                                local code = FRUIT_STORE_CODES[cleanName] or (cleanName .. "-" .. cleanName)
                                invokeCommF("StoreFruit", code, tool)
                            end
                        end
                    end
                end
            end
            if Config.AutoBuyRaidChip then
                invokeCommF("RaidsNpc", "Select", Config.SelectedRaidChip)
            end
            if Config.AutoAwaken then
                invokeCommF("Awakener", "Check")
                invokeCommF("Awakener", "Awaken")
            end
            if Config.AutoRaidAura then
                local enemies = Workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            pcall(function() hum.Health = 0 end)
                        end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.25) do
        pcall(function()
            if Config.AutoFarmChests then
                local root = getRoot()
                if root then
                    for _, v in ipairs(Workspace:GetDescendants()) do
                        if v:IsA("BasePart") and (v.Name == "Chest1" or v.Name == "Chest2" or v.Name == "Chest3") then
                            tweenTo(v.CFrame)
                            break
                        end
                    end
                end
            end
            local hum = getHumanoid()
            if hum then
                -- while the Bypass Fly owns movement the Humanoid stays at WalkSpeed 0
                if Config.WalkSpeedEnabled and not Config.FlyEnabled then hum.WalkSpeed = Config.WalkSpeedValue end
                if Config.JumpPowerEnabled then hum.JumpPower = Config.JumpPowerValue end
            end
            if Config.AutoKen then invokeCommF("Ken", true) end
            if Config.AutoRaceV3 then
                local rem = ReplicatedStorage:FindFirstChild("Remotes")
                local commE = rem and rem:FindFirstChild("CommE")
                if commE then commE:FireServer("ActivateAbility") end
            end
        end)
    end
end)

RunService.Stepped:Connect(function()
    if Config.NoClip or Config.AutoFarmLevel or Config.AutoFarmBoss or Config.AutoFarmAllBosses then
        local char = getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  ESP ENGINE
-- ═══════════════════════════════════════════════════════════════════════════

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "SkillHub_BF_ESP"
pcall(function() ESPFolder.Parent = CoreGui end)
if not ESPFolder.Parent then ESPFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function clearESP()
    ESPFolder:ClearAllChildren()
end

local function createESPBillboard(adornee, titleText, subText, color, bodyText, height)
    if not adornee then return nil end
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Tag"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 200, 0, height or (bodyText and 72 or 42))
    bb.StudsOffset = Vector3.new(0, 3.6, 0)
    bb.AlwaysOnTop = true
    bb.Parent = ESPFolder

    local mainLbl = Instance.new("TextLabel", bb)
    mainLbl.Size = UDim2.new(1, 0, 0, bodyText and 20 or 22)
    mainLbl.BackgroundTransparency = 1
    mainLbl.Font = Enum.Font.GothamBold
    mainLbl.TextSize = 13
    mainLbl.TextColor3 = color
    mainLbl.TextStrokeTransparency = 0.25
    mainLbl.Text = titleText

    local subLbl = Instance.new("TextLabel", bb)
    subLbl.Size = UDim2.new(1, 0, 0, bodyText and 16 or 18)
    subLbl.Position = UDim2.new(0, 0, 0, bodyText and 20 or 23)
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.GothamMedium
    subLbl.TextSize = 11
    subLbl.TextColor3 = Color3.fromRGB(226, 232, 240)
    subLbl.TextStrokeTransparency = 0.35
    subLbl.Text = subText or ""

    if bodyText then
        local bodyLbl = Instance.new("TextLabel", bb)
        bodyLbl.Size = UDim2.new(1, 0, 0, 36)
        bodyLbl.Position = UDim2.new(0, 0, 0, 36)
        bodyLbl.BackgroundTransparency = 1
        bodyLbl.Font = Enum.Font.Gotham
        bodyLbl.TextSize = 10
        bodyLbl.TextWrapped = true
        bodyLbl.TextYAlignment = Enum.TextYAlignment.Top
        bodyLbl.TextColor3 = Color3.fromRGB(203, 213, 225)
        bodyLbl.TextStrokeTransparency = 0.45
        bodyLbl.Text = bodyText
    end

    return bb
end

-- Lightweight tracer lines (Drawing API — silently skipped on executors without it)
local tracerCache = {}
local function updateTracer(key, fromPos, toPos, color, visible)
    if not Drawing or not Drawing.new then return end
    local line = tracerCache[key]
    if not line then
        local ok, created = pcall(function() return Drawing.new("Line") end)
        if not ok or not created then return end
        created.Thickness = 1
        created.Transparency = 0.65
        tracerCache[key] = created
        line = created
    end
    line.From = fromPos
    line.To = toPos
    line.Color = color
    line.Visible = visible and true or false
end

local function clearTracers()
    for key, line in pairs(tracerCache) do
        pcall(function() line:Remove() end)
        tracerCache[key] = nil
    end
end

task.spawn(function()
    while task.wait(0.9) do
        pcall(function()
            clearESP()
            local myRoot = getRoot()
            local cam = Workspace.CurrentCamera
            if not myRoot then return end

            if not Config.ESPTracers then
                for _, line in pairs(tracerCache) do pcall(function() line.Visible = false end) end
            end

            -- ── PLAYER ESP with full PvP + loadout readout ──────────────────
            if Config.ESPPlayers then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local dist = math.floor((hrp.Position - myRoot.Position).Magnitude)
                            local attackable, statusText, statusColor = getPvPStatus(plr)
                            local loadout = getPlayerLoadout(plr)
                            local title = string.format("%s  [%s]", plr.DisplayName, tostring(loadout.level))
                            local sub = string.format("%s  •  %dm", statusText, dist)

                            local body = nil
                            if Config.ESPPlayerLoadout then
                                body = string.format(
                                    "Fruit: %s (%s)\nStyle: %s  •  Sword: %s  •  Gun: %s\nHP: %d/%d  •  Bounty: %s",
                                    loadout.fruit, getFruitTier(loadout.fruit).name,
                                    loadout.style, loadout.sword, loadout.gun,
                                    math.floor(hum.Health), math.floor(hum.MaxHealth), loadout.bounty
                                )
                            end

                            createESPBillboard(hrp, title, sub, statusColor, body)
                            if Config.ESPTracers and cam then
                                updateTracer("plr_" .. plr.Name, cam.ViewportSize / 2, (hrp.Position - myRoot.Position), statusColor, true)
                            end
                        end
                    end
                end
            end

            -- ── DEVIL FRUIT ESP with rarity tiers ──────────────────────────
            if Config.ESPFruits then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA("Tool") or obj.Name:lower():find("fruit", 1, true) then
                        local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
                        if handle then
                            local dist = math.floor((handle.Position - myRoot.Position).Magnitude)
                            local fruitName = tostring(obj:GetAttribute("OriginalName") or obj.Name):gsub(" Fruit", "")
                            local tier = getFruitTier(fruitName)
                            local color = Config.ESPFruitRarity and tier.color or Color3.fromRGB(250, 204, 21)
                            createESPBillboard(handle, fruitName .. " Fruit", string.format("%s rarity  •  %d studs", tier.name, dist), color)
                        end
                    end
                end
            end

            -- ── CHEST ESP ──────────────────────────────────────────────────
            if Config.ESPChests then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name == "Chest1" or obj.Name == "Chest2" or obj.Name == "Chest3") then
                        local dist = math.floor((obj.Position - myRoot.Position).Magnitude)
                        if dist < 2500 then
                            local label = obj.Name == "Chest3" and "Diamond Chest" or (obj.Name == "Chest2" and "Gold Chest" or "Silver Chest")
                            createESPBillboard(obj, label, string.format("%d studs", dist), Color3.fromRGB(74, 222, 128))
                        end
                    end
                end
            end

            -- ── ISLAND / MIRAGE / KITSUNE ESP ──────────────────────────────
            if Config.ESPIslands then
                local map = Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("Locations")
                if map then
                    for _, loc in ipairs(map:GetChildren()) do
                        if loc:IsA("BasePart") then
                            local dist = math.floor((loc.Position - myRoot.Position).Magnitude)
                            local lower = loc.Name:lower()
                            local color, tag = Color3.fromRGB(167, 139, 250), "Island"
                            if lower:find("mirage") then color, tag = Color3.fromRGB(244, 114, 182), "MIRAGE"
                            elseif lower:find("kitsune") then color, tag = Color3.fromRGB(250, 204, 21), "KITSUNE"
                            elseif lower:find("prehistoric") then color, tag = Color3.fromRGB(74, 222, 128), "PREHISTORIC"
                            elseif lower:find("tiki") then color, tag = Color3.fromRGB(56, 189, 248), "TIKI OUTPOST" end
                            createESPBillboard(loc, loc.Name, string.format("%s  •  %d studs", tag, dist), color)
                        end
                    end
                end
            end

            -- ── SEA EVENTS / LEVIATHAN / TERROR SHARK / MYSTIC GEAR ───────
            if (Config.SeaEventTracker or Config.MirageFinder) and #(SeaEventState.events or {}) > 0 then
                for idx, ev in ipairs(SeaEventState.events) do
                    if ev.obj and ev.obj.Parent then
                        local dist = math.floor((ev.obj.Position - myRoot.Position).Magnitude)
                        if dist < 4000 then
                            createESPBillboard(ev.obj, ev.name, string.format("EVENT  •  %d studs", dist), ev.color)
                        end
                    end
                end
            end

            -- ── BOSS ESP ───────────────────────────────────────────────────
            if Config.ESPBosses then
                local enemies = Workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local hrp = mob:FindFirstChild("HumanoidRootPart")
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local dist = math.floor((hrp.Position - myRoot.Position).Magnitude)
                            createESPBillboard(hrp, mob.Name, string.format("HP: %d  •  %dm", math.floor(hum.Health), dist), Color3.fromRGB(248, 113, 113))
                        end
                    end
                end
            end
        end)
    end
end)

Hooks.clearESP = function()
    clearESP()
    clearTracers()
end
Hooks.espTag = createESPBillboard

-- ═══════════════════════════════════════════════════════════════════════════
--  CUSTOM VECTOR ICON & GLASSMORPHIC SCREENGUI ENGINE
-- ═══════════════════════════════════════════════════════════════════════════

local ExternalFluent = nil
if Config.PreferExternalFluent then
    pcall(function()
        ExternalFluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    end)
end

local Theme = {
    BgPrimary       = Color3.fromRGB(10, 13, 22),
    BgSidebar       = Color3.fromRGB(14, 18, 30),
    BgCard          = Color3.fromRGB(19, 25, 42),
    BgControl       = Color3.fromRGB(12, 16, 27),
    Accent          = Color3.fromRGB(56, 189, 248),
    AccentPurple    = Color3.fromRGB(168, 85, 247),
    AccentSecondary = Color3.fromRGB(99, 102, 241),
    TextPrimary     = Color3.fromRGB(241, 245, 249),
    TextSecondary   = Color3.fromRGB(148, 163, 184),
    TextMuted       = Color3.fromRGB(100, 116, 139),
    Border          = Color3.fromRGB(30, 41, 59),
    Success         = Color3.fromRGB(34, 197, 94),
    Warning         = Color3.fromRGB(250, 204, 21),
    Danger          = Color3.fromRGB(239, 68, 68),
    -- Neo-Glassmorphic extras
    Glass           = Color3.fromRGB(23, 31, 51),
    GlassLight      = Color3.fromRGB(33, 43, 68),
    Neon            = Color3.fromRGB(125, 211, 252),
    OnGold          = Color3.fromRGB(15, 20, 34),
}

local guiParent = LocalPlayer:WaitForChild("PlayerGui")
if guiParent:FindFirstChild("SkillHubBloxFruits") then
    guiParent.SkillHubBloxFruits:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SkillHubBloxFruits"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = guiParent

-- Custom Vector Icon Builder (Vector ImageLabel + Neon Radial Glow + Geometric Accent Badge)
local function createVectorIconBadge(parent, iconAssetId, accentColor, sizePx, posUDim, zIdx)
    local holder = Instance.new("Frame", parent)
    holder.Name = "CustomVectorIcon"
    holder.Size = UDim2.new(0, sizePx, 0, sizePx)
    holder.Position = posUDim
    holder.BackgroundColor3 = accentColor
    holder.BackgroundTransparency = 0.85
    holder.BorderSizePixel = 0
    holder.ZIndex = zIdx or 5
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, math.floor(sizePx * 0.28))

    local hStroke = Instance.new("UIStroke", holder)
    hStroke.Color = accentColor
    hStroke.Thickness = 1
    hStroke.Transparency = 0.45

    local glow = Instance.new("ImageLabel", holder)
    glow.Size = UDim2.new(1, 10, 1, 10)
    glow.Position = UDim2.new(0, -5, 0, -5)
    glow.BackgroundTransparency = 1
    glow.Image = CustomIcons.RadialGlow
    glow.ImageColor3 = accentColor
    glow.ImageTransparency = 0.72
    glow.ZIndex = (zIdx or 5)

    local iconImg = Instance.new("ImageLabel", holder)
    local inner = math.max(sizePx - 10, 12)
    iconImg.Size = UDim2.new(0, inner, 0, inner)
    iconImg.Position = UDim2.new(0.5, -inner / 2, 0.5, -inner / 2)
    iconImg.BackgroundTransparency = 1
    iconImg.Image = iconAssetId or CustomIcons.HubCrest
    iconImg.ImageColor3 = accentColor
    iconImg.ScaleType = Enum.ScaleType.Fit
    iconImg.ZIndex = (zIdx or 5) + 1

    return holder, iconImg
end

-- Glass finish: adds the Neo-Glassmorphic stroke + inner gradient to any card
local function addGlassFinish(target, accent)
    if not target then return end
    local stroke = Instance.new("UIStroke", target)
    stroke.Color = accent or Theme.Border
    stroke.Thickness = 1
    stroke.Transparency = 0.62

    local grad = Instance.new("UIGradient", target)
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.GlassLight),
        ColorSequenceKeypoint.new(1, Theme.BgCard),
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.86),
        NumberSequenceKeypoint.new(1, 0.62),
    })
    return stroke
end

-- Hover / press feedback used by every interactive card & button
local function addHoverFx(frame, accent, baseColor)
    if not frame then return end
    baseColor = baseColor or frame.BackgroundColor3
    local lift = Instance.new("UIStroke", frame)
    lift.Color = accent or Theme.Accent
    lift.Thickness = 1.2
    lift.Transparency = 1

    frame.MouseEnter:Connect(function()
        TweenService:Create(lift, TweenInfo.new(0.14), {Transparency = 0.25}):Play()
        TweenService:Create(frame, TweenInfo.new(0.14), {BackgroundColor3 = (accent or Theme.Accent):Lerp(baseColor, 0.86)}):Play()
    end)
    frame.MouseLeave:Connect(function()
        TweenService:Create(lift, TweenInfo.new(0.18), {Transparency = 1}):Play()
        TweenService:Create(frame, TweenInfo.new(0.18), {BackgroundColor3 = baseColor}):Play()
    end)
end

-- Responsive UIScale
local UIScale = Instance.new("UIScale", ScreenGui)
local function updateScale()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    UIScale.Scale = (vp.X < 760 or vp.Y < 510) and math.clamp(math.min(vp.X / 770, vp.Y / 530), 0.65, 1) or 1
end
updateScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

-- Top Live Watermark HUD Pill + Server Status HUD
local WatermarkBar = Instance.new("Frame", ScreenGui)
WatermarkBar.Name = "WatermarkHUD"
WatermarkBar.Size = UDim2.new(0, 470, 0, 30)
WatermarkBar.Position = UDim2.new(0.5, -235, 0, 8)
WatermarkBar.BackgroundColor3 = Theme.BgSidebar
WatermarkBar.BackgroundTransparency = 0.08
WatermarkBar.BorderSizePixel = 0
WatermarkBar.ZIndex = 85
Instance.new("UICorner", WatermarkBar).CornerRadius = UDim.new(1, 0)

local wmStroke = Instance.new("UIStroke", WatermarkBar)
wmStroke.Color = Theme.Accent
wmStroke.Thickness = 1.2
wmStroke.Transparency = 0.3

local wmGrad = Instance.new("UIGradient", WatermarkBar)
wmGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.5, 0.25),
    NumberSequenceKeypoint.new(1, 0),
})

createVectorIconBadge(WatermarkBar, CustomIcons.HubCrest, Theme.Accent, 20, UDim2.new(0, 6, 0.5, -10), 86)

local WatermarkText = Instance.new("TextLabel", WatermarkBar)
WatermarkText.Size = UDim2.new(1, -40, 1, 0)
WatermarkText.Position = UDim2.new(0, 32, 0, 0)
WatermarkText.BackgroundTransparency = 1
WatermarkText.Font = Enum.Font.GothamBold
WatermarkText.TextSize = 11
WatermarkText.TextColor3 = Theme.TextPrimary
WatermarkText.TextXAlignment = Enum.TextXAlignment.Left
WatermarkText.Text = "SKILL HUB v3.0 ULTRA  •  Sea " .. CURRENT_SEA
WatermarkText.ZIndex = 87

-- Second pill: live server / PvP / fly status
local StatusBar = Instance.new("Frame", ScreenGui)
StatusBar.Name = "ServerStatusHUD"
StatusBar.Size = UDim2.new(0, 470, 0, 24)
StatusBar.Position = UDim2.new(0.5, -235, 0, 42)
StatusBar.BackgroundColor3 = Theme.Glass
StatusBar.BackgroundTransparency = 0.18
StatusBar.BorderSizePixel = 0
StatusBar.ZIndex = 84
Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(1, 0)

local statusStroke = Instance.new("UIStroke", StatusBar)
statusStroke.Color = Theme.Border
statusStroke.Thickness = 1
statusStroke.Transparency = 0.45

local StatusText = Instance.new("TextLabel", StatusBar)
StatusText.Size = UDim2.new(1, -20, 1, 0)
StatusText.Position = UDim2.new(0, 10, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Font = Enum.Font.GothamMedium
StatusText.TextSize = 10
StatusText.TextColor3 = Theme.TextSecondary
StatusText.TextXAlignment = Enum.TextXAlignment.Center
StatusText.Text = "SERVER STATUS"
StatusText.ZIndex = 86

task.spawn(function()
    local lastTick = tick()
    local frames = 0
    RunService.RenderStepped:Connect(function()
        frames += 1
    end)
    while task.wait(1.0) do
        if not ScreenGui.Parent then break end
        pcall(function()
            local now = tick()
            local fps = math.floor(frames / math.max(now - lastTick, 0.01))
            frames = 0
            lastTick = now
            local status = getServerStatus()

            WatermarkBar.Visible = Config.ShowWatermarkHUD
            WatermarkText.Text = string.format(
                "SKILL HUB v3.0  •  Sea %d [%s]  •  Lv.%d  •  %d FPS  •  %dms",
                CURRENT_SEA, SEA_DETECT_SOURCE, getPlayerLevel(), fps, status.ping
            )

            StatusBar.Visible = Config.ServerStatusHUD and Config.ShowWatermarkHUD
            local pvpTag = PvPState and PvPState.target and ("PVP ▶ " .. tostring(PvPState.targetName)) or "PVP idle"
            StatusText.Text = string.format(
                "Job %s  •  %d/%d players  •  Sea %d/%s  •  %s  •  %s  •  Fly %s  •  Events %d",
                status.jobId, status.players, status.maxPlayers, status.sea, tostring(status.source),
                Config.AimLock and "AIMLOCK ON" or pvpTag,
                (Config.AutoKillSelected or Config.AutoKillPvP) and "KILL ON" or "kill idle",
                Config.FlyEnabled and "ON" or "off",
                status.events
            )
            StatusText.TextColor3 = (Config.AutoKillSelected or Config.AutoKillPvP) and Theme.Danger or Theme.TextSecondary
        end)
    end
end)

-- Toast Notification Container
local ToastHolder = Instance.new("Frame", ScreenGui)
ToastHolder.Size = UDim2.new(0, 300, 1, -24)
ToastHolder.Position = UDim2.new(1, -314, 0, 12)
ToastHolder.BackgroundTransparency = 1
ToastHolder.ZIndex = 100

local toastLayout = Instance.new("UIListLayout", ToastHolder)
toastLayout.Padding = UDim.new(0, 8)
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

local function notify(title, message, duration, iconAsset)
    duration = duration or 3.5
    local card = Instance.new("Frame", ToastHolder)
    card.Size = UDim2.new(1, 0, 0, 64)
    card.BackgroundColor3 = Theme.BgSidebar
    card.BorderSizePixel = 0
    card.ZIndex = 101
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Theme.Accent
    stroke.Thickness = 1.2
    stroke.Transparency = 0.25

    createVectorIconBadge(card, iconAsset or CustomIcons.HubCrest, Theme.Accent, 34, UDim2.new(0, 12, 0.5, -17), 102)

    local tLbl = Instance.new("TextLabel", card)
    tLbl.Size = UDim2.new(1, -60, 0, 20)
    tLbl.Position = UDim2.new(0, 54, 0, 9)
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 13
    tLbl.TextColor3 = Theme.TextPrimary
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Text = title
    tLbl.ZIndex = 102

    local mLbl = Instance.new("TextLabel", card)
    mLbl.Size = UDim2.new(1, -60, 0, 28)
    mLbl.Position = UDim2.new(0, 54, 0, 28)
    mLbl.BackgroundTransparency = 1
    mLbl.Font = Enum.Font.Gotham
    mLbl.TextSize = 11
    mLbl.TextColor3 = Theme.TextSecondary
    mLbl.TextWrapped = true
    mLbl.TextXAlignment = Enum.TextXAlignment.Left
    mLbl.TextYAlignment = Enum.TextYAlignment.Top
    mLbl.Text = message
    mLbl.ZIndex = 102

    card.BackgroundTransparency = 1
    TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.04}):Play()

    task.delay(duration, function()
        if card and card.Parent then
            TweenService:Create(card, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
            task.wait(0.26)
            if card and card.Parent then card:Destroy() end
        end
    end)
end

Hooks.notify = function(title, message, duration, iconAsset)
    pcall(function() notify(title, message, duration, iconAsset) end)
end

-- Floating Quick-Toggle Pill with Custom Vector Icon
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0, 146, 0, 40)
FloatBtn.Position = UDim2.new(0, 18, 0.5, -20)
FloatBtn.BackgroundColor3 = Theme.BgSidebar
FloatBtn.Text = ""
FloatBtn.BorderSizePixel = 0
FloatBtn.ZIndex = 90
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)
local floatStroke = Instance.new("UIStroke", FloatBtn)
floatStroke.Color = Theme.Accent
floatStroke.Thickness = 1.4

createVectorIconBadge(FloatBtn, CustomIcons.HubCrest, Theme.Accent, 28, UDim2.new(0, 7, 0.5, -14), 91)

local floatLbl = Instance.new("TextLabel", FloatBtn)
floatLbl.Size = UDim2.new(1, -44, 1, 0)
floatLbl.Position = UDim2.new(0, 40, 0, 0)
floatLbl.BackgroundTransparency = 1
floatLbl.Font = Enum.Font.GothamBlack
floatLbl.TextSize = 12
floatLbl.TextColor3 = Theme.TextPrimary
floatLbl.TextXAlignment = Enum.TextXAlignment.Left
floatLbl.Text = "SKILL HUB"
floatLbl.ZIndex = 92

-- Main Window Frame
local MainWindow = Instance.new("Frame", ScreenGui)
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 710, 0, 480)
MainWindow.Position = UDim2.new(0.5, -355, 0.5, -240)
MainWindow.BackgroundColor3 = Theme.BgPrimary
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
Instance.new("UICorner", MainWindow).CornerRadius = UDim.new(0, 14)

local winStroke = Instance.new("UIStroke", MainWindow)
winStroke.Color = Theme.Border
winStroke.Thickness = 1.5

-- Neo-Glassmorphic depth: vertical glass gradient + top light sheen + neon pulse
local winGrad = Instance.new("UIGradient", MainWindow)
winGrad.Rotation = 90
winGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.GlassLight),
    ColorSequenceKeypoint.new(0.45, Theme.BgPrimary),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 9, 16)),
})

local winSheen = Instance.new("Frame", MainWindow)
winSheen.Name = "GlassSheen"
winSheen.Size = UDim2.new(1, 0, 0, 90)
winSheen.BackgroundColor3 = Theme.Neon
winSheen.BackgroundTransparency = 0.94
winSheen.BorderSizePixel = 0
winSheen.ZIndex = 1
Instance.new("UICorner", winSheen).CornerRadius = UDim.new(0, 14)
local sheenGrad = Instance.new("UIGradient", winSheen)
sheenGrad.Rotation = 90
sheenGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.35),
    NumberSequenceKeypoint.new(1, 1),
})

task.spawn(function()
    while task.wait(0.05) do
        if not ScreenGui.Parent or not MainWindow.Parent then break end
        local pulse = (math.sin(tick() * 1.5) + 1) / 2
        winStroke.Transparency = 0.62 - pulse * 0.42
        winStroke.Color = Theme.Accent:Lerp(Theme.AccentPurple, pulse)
    end
end)

local TopAccent = Instance.new("Frame", MainWindow)
TopAccent.Size = UDim2.new(1, 0, 0, 2)
TopAccent.BackgroundColor3 = Theme.Accent
TopAccent.BorderSizePixel = 0
TopAccent.ZIndex = 10
local topGrad = Instance.new("UIGradient", TopAccent)
topGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentSecondary),
    ColorSequenceKeypoint.new(0.5, Theme.Accent),
    ColorSequenceKeypoint.new(1, Theme.AccentPurple),
})

-- Smooth Window Dragging
do
    local dragging, dragInput, dragStart, startPos
    MainWindow.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainWindow.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    MainWindow.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Left Sidebar
local Sidebar = Instance.new("Frame", MainWindow)
Sidebar.Size = UDim2.new(0, 196, 1, 0)
Sidebar.BackgroundColor3 = Theme.BgSidebar
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 14)

-- Custom Vector Brand Crest inside Sidebar
createVectorIconBadge(Sidebar, CustomIcons.HubCrest, Theme.Accent, 36, UDim2.new(0, 14, 0, 14), 4)

local BrandTitle = Instance.new("TextLabel", Sidebar)
BrandTitle.Size = UDim2.new(1, -60, 0, 20)
BrandTitle.Position = UDim2.new(0, 56, 0, 14)
BrandTitle.BackgroundTransparency = 1
BrandTitle.Font = Enum.Font.GothamBlack
BrandTitle.TextSize = 16
BrandTitle.TextColor3 = Theme.TextPrimary
BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
BrandTitle.Text = "SKILL HUB"
BrandTitle.ZIndex = 4

local BrandSub = Instance.new("TextLabel", Sidebar)
BrandSub.Size = UDim2.new(1, -60, 0, 16)
BrandSub.Position = UDim2.new(0, 56, 0, 33)
BrandSub.BackgroundTransparency = 1
BrandSub.Font = Enum.Font.GothamMedium
BrandSub.TextSize = 11
BrandSub.TextColor3 = Theme.Accent
BrandSub.TextXAlignment = Enum.TextXAlignment.Left
BrandSub.Text = string.format("Blox Fruits • Sea %d", CURRENT_SEA)
BrandSub.ZIndex = 4

local TabButtonContainer = Instance.new("ScrollingFrame", Sidebar)
TabButtonContainer.Size = UDim2.new(1, -16, 1, -125)
TabButtonContainer.Position = UDim2.new(0, 8, 0, 64)
TabButtonContainer.BackgroundTransparency = 1
TabButtonContainer.BorderSizePixel = 0
TabButtonContainer.ScrollBarThickness = 0
TabButtonContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabButtonContainer.ZIndex = 3

local tabListLayout = Instance.new("UIListLayout", TabButtonContainer)
tabListLayout.Padding = UDim.new(0, 5)
tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local StatsFooter = Instance.new("Frame", Sidebar)
StatsFooter.Size = UDim2.new(1, -16, 0, 46)
StatsFooter.Position = UDim2.new(0, 8, 1, -54)
StatsFooter.BackgroundColor3 = Theme.BgCard
StatsFooter.BorderSizePixel = 0
StatsFooter.ZIndex = 3
Instance.new("UICorner", StatsFooter).CornerRadius = UDim.new(0, 9)

local FooterLvLbl = Instance.new("TextLabel", StatsFooter)
FooterLvLbl.Size = UDim2.new(1, -12, 0, 18)
FooterLvLbl.Position = UDim2.new(0, 8, 0, 5)
FooterLvLbl.BackgroundTransparency = 1
FooterLvLbl.Font = Enum.Font.GothamBold
FooterLvLbl.TextSize = 11
FooterLvLbl.TextColor3 = Theme.TextPrimary
FooterLvLbl.TextXAlignment = Enum.TextXAlignment.Left
FooterLvLbl.Text = "Lv. 1 | ƒ 0"
FooterLvLbl.ZIndex = 4

local FooterBeliLbl = Instance.new("TextLabel", StatsFooter)
FooterBeliLbl.Size = UDim2.new(1, -12, 0, 16)
FooterBeliLbl.Position = UDim2.new(0, 8, 0, 24)
FooterBeliLbl.BackgroundTransparency = 1
FooterBeliLbl.Font = Enum.Font.GothamMedium
FooterBeliLbl.TextSize = 10
FooterBeliLbl.TextColor3 = Theme.Success
FooterBeliLbl.TextXAlignment = Enum.TextXAlignment.Left
FooterBeliLbl.Text = "$ 0"
FooterBeliLbl.ZIndex = 4

task.spawn(function()
    while task.wait(1.0) do
        if not ScreenGui.Parent then break end
        pcall(function()
            FooterLvLbl.Text = string.format("Lv. %s  |  ƒ %s", tostring(getPlayerLevel()), formatNumber(getPlayerFragments()))
            FooterBeliLbl.Text = "$ " .. formatNumber(getPlayerBeli())
            BrandSub.Text = string.format("Blox Fruits • Sea %d (%s)", CURRENT_SEA, tostring(SEA_DETECT_SOURCE))
        end)
    end
end)

-- Right Content Area
local ContentArea = Instance.new("Frame", MainWindow)
ContentArea.Size = UDim2.new(1, -196, 1, 0)
ContentArea.Position = UDim2.new(0, 196, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex = 2

local Topbar = Instance.new("Frame", ContentArea)
Topbar.Size = UDim2.new(1, 0, 0, 52)
Topbar.BackgroundColor3 = Theme.BgSidebar
Topbar.BorderSizePixel = 0
Topbar.ZIndex = 3

local _, ActiveTabIconImg = createVectorIconBadge(Topbar, CustomIcons.AutoFarm, Theme.Accent, 28, UDim2.new(0, 14, 0.5, -14), 4)

local ActiveTabTitle = Instance.new("TextLabel", Topbar)
ActiveTabTitle.Size = UDim2.new(0, 200, 1, 0)
ActiveTabTitle.Position = UDim2.new(0, 50, 0, 0)
ActiveTabTitle.BackgroundTransparency = 1
ActiveTabTitle.Font = Enum.Font.GothamBold
ActiveTabTitle.TextSize = 16
ActiveTabTitle.TextColor3 = Theme.TextPrimary
ActiveTabTitle.TextXAlignment = Enum.TextXAlignment.Left
ActiveTabTitle.Text = "Auto Farm"
ActiveTabTitle.ZIndex = 4

local SearchBox = Instance.new("TextBox", Topbar)
SearchBox.Size = UDim2.new(0, 175, 0, 28)
SearchBox.Position = UDim2.new(1, -255, 0.5, -14)
SearchBox.BackgroundColor3 = Theme.BgControl
SearchBox.PlaceholderText = "Filter features..."
SearchBox.PlaceholderColor3 = Theme.TextMuted
SearchBox.Text = ""
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.TextColor3 = Theme.TextPrimary
SearchBox.ClearTextOnFocus = false
SearchBox.BorderSizePixel = 0
SearchBox.ZIndex = 4
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 7)

local MinBtn = Instance.new("TextButton", Topbar)
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -68, 0.5, -14)
MinBtn.BackgroundColor3 = Theme.BgCard
MinBtn.Text = "—"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 13
MinBtn.TextColor3 = Theme.TextPrimary
MinBtn.BorderSizePixel = 0
MinBtn.ZIndex = 4
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 7)

local CloseBtn = Instance.new("TextButton", Topbar)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -14)
CloseBtn.BackgroundColor3 = Theme.Danger
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.BorderSizePixel = 0
CloseBtn.ZIndex = 4
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 7)

local PagesFolder = Instance.new("Frame", ContentArea)
PagesFolder.Size = UDim2.new(1, -20, 1, -64)
PagesFolder.Position = UDim2.new(0, 10, 0, 58)
PagesFolder.BackgroundTransparency = 1
PagesFolder.ZIndex = 3

local tabs = {}
local allSearchables = {}

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = SearchBox.Text:lower()
    for _, entry in ipairs(allSearchables) do
        entry.frame.Visible = (q == "") or (entry.label:lower():find(q, 1, true) ~= nil)
    end
end)

local function createTab(iconAsset, name, accentOverride)
    local tabColor = accentOverride or Theme.Accent

    local btn = Instance.new("TextButton", TabButtonContainer)
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Theme.BgCard
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.ZIndex = 4
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local bar = Instance.new("Frame", btn)
    bar.Size = UDim2.new(0, 3, 0, 20)
    bar.Position = UDim2.new(0, 0, 0.5, -10)
    bar.BackgroundColor3 = tabColor
    bar.BackgroundTransparency = 1
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    createVectorIconBadge(btn, iconAsset, tabColor, 26, UDim2.new(0, 8, 0.5, -13), 5)

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -44, 1, 0)
    lbl.Position = UDim2.new(0, 40, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextColor3 = Theme.TextSecondary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = name
    lbl.ZIndex = 5

    local page = Instance.new("ScrollingFrame", PagesFolder)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = tabColor
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.ZIndex = 3

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local tabObj = {btn = btn, bar = bar, lbl = lbl, page = page, name = name, icon = iconAsset, color = tabColor, order = 0}
    table.insert(tabs, tabObj)

    local function selectTab()
        for _, t in ipairs(tabs) do
            t.page.Visible = false
            TweenService:Create(t.btn, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
            TweenService:Create(t.bar, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
            t.lbl.TextColor3 = Theme.TextSecondary
            t.lbl.Font = Enum.Font.GothamMedium
        end
        page.Visible = true
        ActiveTabTitle.Text = name
        ActiveTabIconImg.Image = iconAsset
        ActiveTabIconImg.ImageColor3 = tabColor
        TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundTransparency = 0}):Play()
        TweenService:Create(bar, TweenInfo.new(0.18), {BackgroundTransparency = 0}):Play()
        lbl.TextColor3 = Theme.TextPrimary
        lbl.Font = Enum.Font.GothamBold
    end

    btn.MouseButton1Click:Connect(selectTab)
    if #tabs == 1 then selectTab() end

    function tabObj:AddSection(title)
        self.order += 1
        local sec = Instance.new("Frame", self.page)
        sec.Size = UDim2.new(1, 0, 0, 24)
        sec.BackgroundTransparency = 1
        sec.LayoutOrder = self.order

        local sLbl = Instance.new("TextLabel", sec)
        sLbl.Size = UDim2.new(1, 0, 1, 0)
        sLbl.BackgroundTransparency = 1
        sLbl.Font = Enum.Font.GothamBold
        sLbl.TextSize = 11
        sLbl.TextColor3 = self.color
        sLbl.TextXAlignment = Enum.TextXAlignment.Left
        sLbl.Text = "◆  " .. string.upper(title)

        local divider = Instance.new("Frame", sec)
        divider.Size = UDim2.new(1, 0, 0, 1)
        divider.Position = UDim2.new(0, 0, 1, -2)
        divider.BackgroundColor3 = self.color
        divider.BackgroundTransparency = 0.72
        divider.BorderSizePixel = 0
        divider.ZIndex = 3
        local divGrad = Instance.new("UIGradient", divider)
        divGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 0.35),
            NumberSequenceKeypoint.new(1, 1),
        })
    end

    function tabObj:AddToggle(title, desc, defaultValue, callback, itemIcon)
        self.order += 1
        local card = Instance.new("Frame", self.page)
        card.Size = UDim2.new(1, 0, 0, 54)
        card.BackgroundColor3 = Theme.BgCard
        card.BorderSizePixel = 0
        card.LayoutOrder = self.order
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
        addGlassFinish(card, self.color)
        addHoverFx(card, self.color)

        createVectorIconBadge(card, itemIcon or self.icon, self.color, 32, UDim2.new(0, 12, 0.5, -16), 4)

        local tLbl = Instance.new("TextLabel", card)
        tLbl.Size = UDim2.new(1, -120, 0, 20)
        tLbl.Position = UDim2.new(0, 52, 0, 8)
        tLbl.BackgroundTransparency = 1
        tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 13
        tLbl.TextColor3 = Theme.TextPrimary
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.Text = title

        local dLbl = Instance.new("TextLabel", card)
        dLbl.Size = UDim2.new(1, -120, 0, 16)
        dLbl.Position = UDim2.new(0, 52, 0, 28)
        dLbl.BackgroundTransparency = 1
        dLbl.Font = Enum.Font.Gotham
        dLbl.TextSize = 11
        dLbl.TextColor3 = Theme.TextMuted
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.Text = desc

        local swBg = Instance.new("Frame", card)
        swBg.Size = UDim2.new(0, 44, 0, 22)
        swBg.Position = UDim2.new(1, -56, 0.5, -11)
        swBg.BackgroundColor3 = defaultValue and self.color or Theme.BgControl
        swBg.BorderSizePixel = 0
        Instance.new("UICorner", swBg).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame", swBg)
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = defaultValue and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local clickBtn = Instance.new("TextButton", card)
        clickBtn.Size = UDim2.new(1, 0, 1, 0)
        clickBtn.BackgroundTransparency = 1
        clickBtn.Text = ""

        local state = defaultValue
        clickBtn.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(swBg, TweenInfo.new(0.18), {BackgroundColor3 = state and self.color or Theme.BgControl}):Play()
            TweenService:Create(knob, TweenInfo.new(0.18), {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}):Play()
            if callback then callback(state) end
        end)

        table.insert(allSearchables, {frame = card, label = title .. " " .. desc})
    end

    function tabObj:AddButton(title, desc, btnText, callback, itemIcon)
        self.order += 1
        local card = Instance.new("Frame", self.page)
        card.Size = UDim2.new(1, 0, 0, 54)
        card.BackgroundColor3 = Theme.BgCard
        card.BorderSizePixel = 0
        card.LayoutOrder = self.order
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
        addGlassFinish(card, self.color)
        addHoverFx(card, self.color)

        createVectorIconBadge(card, itemIcon or self.icon, self.color, 32, UDim2.new(0, 12, 0.5, -16), 4)

        local tLbl = Instance.new("TextLabel", card)
        tLbl.Size = UDim2.new(1, -150, 0, 20)
        tLbl.Position = UDim2.new(0, 52, 0, 8)
        tLbl.BackgroundTransparency = 1
        tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 13
        tLbl.TextColor3 = Theme.TextPrimary
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.Text = title

        local dLbl = Instance.new("TextLabel", card)
        dLbl.Size = UDim2.new(1, -150, 0, 16)
        dLbl.Position = UDim2.new(0, 52, 0, 28)
        dLbl.BackgroundTransparency = 1
        dLbl.Font = Enum.Font.Gotham
        dLbl.TextSize = 11
        dLbl.TextColor3 = Theme.TextMuted
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.Text = desc

        local actBtn = Instance.new("TextButton", card)
        actBtn.Size = UDim2.new(0, 86, 0, 28)
        actBtn.Position = UDim2.new(1, -98, 0.5, -14)
        actBtn.BackgroundColor3 = self.color
        actBtn.Font = Enum.Font.GothamBold
        actBtn.TextSize = 11
        actBtn.TextColor3 = Color3.fromRGB(10, 13, 22)
        actBtn.Text = btnText or "Execute"
        actBtn.BorderSizePixel = 0
        Instance.new("UICorner", actBtn).CornerRadius = UDim.new(0, 7)
        addHoverFx(actBtn, Color3.new(1, 1, 1), self.color)

        actBtn.MouseButton1Click:Connect(function()
            task.spawn(function() if callback then callback() end end)
        end)

        table.insert(allSearchables, {frame = card, label = title .. " " .. desc})
    end

    function tabObj:AddSlider(title, desc, minVal, maxVal, defaultVal, callback, itemIcon)
        self.order += 1
        local card = Instance.new("Frame", self.page)
        card.Size = UDim2.new(1, 0, 0, 66)
        card.BackgroundColor3 = Theme.BgCard
        card.BorderSizePixel = 0
        card.LayoutOrder = self.order
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
        addGlassFinish(card, self.color)
        addHoverFx(card, self.color)

        createVectorIconBadge(card, itemIcon or CustomIcons.Lightning, self.color, 32, UDim2.new(0, 12, 0, 12), 4)

        local tLbl = Instance.new("TextLabel", card)
        tLbl.Size = UDim2.new(0.6, 0, 0, 20)
        tLbl.Position = UDim2.new(0, 52, 0, 6)
        tLbl.BackgroundTransparency = 1
        tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 13
        tLbl.TextColor3 = Theme.TextPrimary
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.Text = title

        local valLbl = Instance.new("TextLabel", card)
        valLbl.Size = UDim2.new(0.3, -14, 0, 20)
        valLbl.Position = UDim2.new(0.7, 0, 0, 6)
        valLbl.BackgroundTransparency = 1
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 12
        valLbl.TextColor3 = self.color
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Text = tostring(defaultVal)

        local dLbl = Instance.new("TextLabel", card)
        dLbl.Size = UDim2.new(1, -66, 0, 14)
        dLbl.Position = UDim2.new(0, 52, 0, 24)
        dLbl.BackgroundTransparency = 1
        dLbl.Font = Enum.Font.Gotham
        dLbl.TextSize = 10
        dLbl.TextColor3 = Theme.TextMuted
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.Text = desc

        local track = Instance.new("Frame", card)
        track.Size = UDim2.new(1, -66, 0, 6)
        track.Position = UDim2.new(0, 52, 0, 48)
        track.BackgroundColor3 = Theme.BgControl
        track.BorderSizePixel = 0
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local pct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
        local fill = Instance.new("Frame", track)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        fill.BackgroundColor3 = self.color
        fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local draggingSlider = false
        local function updateFromX(xPos)
            local rel = math.clamp((xPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(minVal + (maxVal - minVal) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            valLbl.Text = tostring(v)
            if callback then callback(v) end
        end

        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                draggingSlider = true
                updateFromX(inp.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if draggingSlider and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                updateFromX(inp.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                draggingSlider = false
            end
        end)

        table.insert(allSearchables, {frame = card, label = title .. " " .. desc})
    end

    function tabObj:AddDropdown(title, desc, options, defaultOption, callback, itemIcon)
        self.order += 1
        local expanded = false
        local card = Instance.new("Frame", self.page)
        card.Size = UDim2.new(1, 0, 0, 54)
        card.BackgroundColor3 = Theme.BgCard
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.LayoutOrder = self.order
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
        addGlassFinish(card, self.color)
        addHoverFx(card, self.color)

        createVectorIconBadge(card, itemIcon or self.icon, self.color, 32, UDim2.new(0, 12, 0, 11), 4)

        local tLbl = Instance.new("TextLabel", card)
        tLbl.Size = UDim2.new(0.52, 0, 0, 20)
        tLbl.Position = UDim2.new(0, 52, 0, 7)
        tLbl.BackgroundTransparency = 1
        tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 13
        tLbl.TextColor3 = Theme.TextPrimary
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.Text = title

        local dLbl = Instance.new("TextLabel", card)
        dLbl.Size = UDim2.new(0.52, 0, 0, 16)
        dLbl.Position = UDim2.new(0, 52, 0, 27)
        dLbl.BackgroundTransparency = 1
        dLbl.Font = Enum.Font.Gotham
        dLbl.TextSize = 11
        dLbl.TextColor3 = Theme.TextMuted
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.Text = desc

        local selBtn = Instance.new("TextButton", card)
        selBtn.Size = UDim2.new(0, 170, 0, 30)
        selBtn.Position = UDim2.new(1, -182, 0, 12)
        selBtn.BackgroundColor3 = Theme.BgControl
        selBtn.Font = Enum.Font.GothamBold
        selBtn.TextSize = 11
        selBtn.TextColor3 = self.color
        selBtn.Text = (defaultOption or options[1] or "Select") .. "  ▾"
        selBtn.BorderSizePixel = 0
        Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 7)

        local listFrame = Instance.new("ScrollingFrame", card)
        listFrame.Size = UDim2.new(1, -24, 0, 125)
        listFrame.Position = UDim2.new(0, 12, 0, 52)
        listFrame.BackgroundColor3 = Theme.BgControl
        listFrame.BorderSizePixel = 0
        listFrame.ScrollBarThickness = 3
        listFrame.ScrollBarImageColor3 = self.color
        listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 7)

        local lLayout = Instance.new("UIListLayout", listFrame)
        lLayout.Padding = UDim.new(0, 3)

        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton", listFrame)
            optBtn.Size = UDim2.new(1, 0, 0, 26)
            optBtn.BackgroundColor3 = Theme.BgCard
            optBtn.Font = Enum.Font.GothamMedium
            optBtn.TextSize = 11
            optBtn.TextColor3 = Theme.TextPrimary
            optBtn.Text = opt
            optBtn.BorderSizePixel = 0
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 5)

            optBtn.MouseButton1Click:Connect(function()
                selBtn.Text = opt .. "  ▾"
                expanded = false
                TweenService:Create(card, TweenInfo.new(0.18), {Size = UDim2.new(1, 0, 0, 54)}):Play()
                if callback then callback(opt) end
            end)
        end

        selBtn.MouseButton1Click:Connect(function()
            expanded = not expanded
            TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
                Size = expanded and UDim2.new(1, 0, 0, 186) or UDim2.new(1, 0, 0, 54)
            }):Play()
        end)

        table.insert(allSearchables, {frame = card, label = title .. " " .. desc})
    end

    -- Live multi-line readout panel (used by the Player Scanner & Server Status)
    function tabObj:AddLabel(title, desc, height, itemIcon)
        self.order += 1
        local card = Instance.new("Frame", self.page)
        card.Size = UDim2.new(1, 0, 0, height or 96)
        card.BackgroundColor3 = Theme.BgCard
        card.BorderSizePixel = 0
        card.LayoutOrder = self.order
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
        addGlassFinish(card, self.color)

        createVectorIconBadge(card, itemIcon or CustomIcons.Players, self.color, 26, UDim2.new(0, 10, 0, 10), 4)

        local tLbl = Instance.new("TextLabel", card)
        tLbl.Size = UDim2.new(1, -50, 0, 20)
        tLbl.Position = UDim2.new(0, 44, 0, 8)
        tLbl.BackgroundTransparency = 1
        tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 12
        tLbl.TextColor3 = Theme.TextPrimary
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.Text = title

        local dLbl = Instance.new("TextLabel", card)
        dLbl.Size = UDim2.new(1, -50, 0, 14)
        dLbl.Position = UDim2.new(0, 44, 0, 26)
        dLbl.BackgroundTransparency = 1
        dLbl.Font = Enum.Font.Gotham
        dLbl.TextSize = 10
        dLbl.TextColor3 = Theme.TextMuted
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.Text = desc or ""

        local bodyLbl = Instance.new("TextLabel", card)
        bodyLbl.Size = UDim2.new(1, -20, 1, -48)
        bodyLbl.Position = UDim2.new(0, 10, 0, 44)
        bodyLbl.BackgroundTransparency = 1
        bodyLbl.Font = Enum.Font.Code
        bodyLbl.TextSize = 10
        bodyLbl.TextWrapped = true
        bodyLbl.TextYAlignment = Enum.TextYAlignment.Top
        bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
        bodyLbl.TextColor3 = Color3.fromRGB(203, 213, 225)
        bodyLbl.Text = "No data yet."

        table.insert(allSearchables, {frame = card, label = title .. " " .. (desc or "")})

        return {
            card = card,
            label = bodyLbl,
            SetText = function(_, txt) bodyLbl.Text = txt end,
            SetColor = function(_, c) bodyLbl.TextColor3 = c end,
            SetVisible = function(_, v) card.Visible = v end,
        }
    end

    -- Auto-refreshing variant: updater() returns the text every `interval` seconds
    function tabObj:AddLivePanel(title, desc, interval, updater, height, itemIcon)
        local panel = self:AddLabel(title, desc, height, itemIcon)
        task.spawn(function()
            while true do
                task.wait(interval or 1)
                if not panel.card or not panel.card.Parent then break end
                local ok, txt = pcall(updater)
                if ok and type(txt) == "string" then panel.label.Text = txt end
            end
        end)
        return panel
    end

    -- Text input (used for the PvP target player name)
    function tabObj:AddInput(title, desc, placeholder, defaultValue, callback, itemIcon)
        self.order += 1
        local card = Instance.new("Frame", self.page)
        card.Size = UDim2.new(1, 0, 0, 56)
        card.BackgroundColor3 = Theme.BgCard
        card.BorderSizePixel = 0
        card.LayoutOrder = self.order
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
        addGlassFinish(card, self.color)

        createVectorIconBadge(card, itemIcon or CustomIcons.Search, self.color, 30, UDim2.new(0, 12, 0.5, -15), 4)

        local tLbl = Instance.new("TextLabel", card)
        tLbl.Size = UDim2.new(0.5, 0, 0, 20)
        tLbl.Position = UDim2.new(0, 52, 0, 8)
        tLbl.BackgroundTransparency = 1
        tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 12
        tLbl.TextColor3 = Theme.TextPrimary
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.Text = title

        local dLbl = Instance.new("TextLabel", card)
        dLbl.Size = UDim2.new(0.5, 0, 0, 16)
        dLbl.Position = UDim2.new(0, 52, 0, 28)
        dLbl.BackgroundTransparency = 1
        dLbl.Font = Enum.Font.Gotham
        dLbl.TextSize = 10
        dLbl.TextColor3 = Theme.TextMuted
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.Text = desc or ""

        local box = Instance.new("TextBox", card)
        box.Size = UDim2.new(0, 168, 0, 30)
        box.Position = UDim2.new(1, -180, 0.5, -15)
        box.BackgroundColor3 = Theme.BgControl
        box.Font = Enum.Font.GothamMedium
        box.TextSize = 11
        box.TextColor3 = Theme.TextPrimary
        box.PlaceholderText = placeholder or "type here..."
        box.PlaceholderColor3 = Theme.TextMuted
        box.Text = defaultValue or ""
        box.ClearTextOnFocus = false
        box.BorderSizePixel = 0
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)

        local function commit()
            if callback then callback(box.Text) end
        end
        box.FocusLost:Connect(commit)
        box.ReturnPressedFromOnScreenKeyboard:Connect(commit)

        table.insert(allSearchables, {frame = card, label = title .. " " .. (desc or "")})
        return box
    end

    -- AUTO PLAYER LIST: rebuilds itself every second with every player in the
    -- server, their PvP status, level, fruit, distance and 4 one-click actions.
    function tabObj:AddPlayerList(title, desc, height, itemIcon)
        self.order = self.order + 1
        local card = Instance.new("Frame", self.page)
        card.Size = UDim2.new(1, 0, 0, height or 268)
        card.BackgroundColor3 = Theme.BgCard
        card.BorderSizePixel = 0
        card.LayoutOrder = self.order
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
        addGlassFinish(card, self.color)

        createVectorIconBadge(card, itemIcon or CustomIcons.Players, self.color, 26, UDim2.new(0, 10, 0, 9), 4)

        local tLbl = Instance.new("TextLabel", card)
        tLbl.Size = UDim2.new(0.6, 0, 0, 18)
        tLbl.Position = UDim2.new(0, 44, 0, 7)
        tLbl.BackgroundTransparency = 1
        tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 12
        tLbl.TextColor3 = Theme.TextPrimary
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.Text = title

        local dLbl = Instance.new("TextLabel", card)
        dLbl.Size = UDim2.new(0.72, 0, 0, 16)
        dLbl.Position = UDim2.new(0, 44, 0, 23)
        dLbl.BackgroundTransparency = 1
        dLbl.Font = Enum.Font.Gotham
        dLbl.TextSize = 10
        dLbl.TextColor3 = Theme.TextMuted
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.Text = desc or ""

        local countLbl = Instance.new("TextLabel", card)
        countLbl.Size = UDim2.new(0.28, -10, 0, 30)
        countLbl.Position = UDim2.new(0.72, 0, 0, 7)
        countLbl.BackgroundTransparency = 1
        countLbl.Font = Enum.Font.GothamBold
        countLbl.TextSize = 10
        countLbl.TextColor3 = self.color
        countLbl.TextXAlignment = Enum.TextXAlignment.Right
        countLbl.TextYAlignment = Enum.TextYAlignment.Center
        countLbl.Text = "scanning..."

        local list = Instance.new("ScrollingFrame", card)
        list.Size = UDim2.new(1, -16, 1, -48)
        list.Position = UDim2.new(0, 8, 0, 44)
        list.BackgroundColor3 = Theme.BgControl
        list.BackgroundTransparency = 0.35
        list.BorderSizePixel = 0
        list.ScrollBarThickness = 3
        list.ScrollBarImageColor3 = self.color
        list.CanvasSize = UDim2.new()
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Instance.new("UICorner", list).CornerRadius = UDim.new(0, 7)

        local lLayout = Instance.new("UIListLayout", list)
        lLayout.Padding = UDim.new(0, 4)
        lLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local function rowButton(parent, text, xOffset, btnColor, callback)
            local btn = Instance.new("TextButton", parent)
            btn.Size = UDim2.new(0, 44, 0, 20)
            btn.Position = UDim2.new(1, xOffset, 0, 17)
            btn.BackgroundColor3 = btnColor
            btn.BackgroundTransparency = 0.12
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 10
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Text = text
            btn.BorderSizePixel = 0
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            btn.MouseButton1Click:Connect(function() task.spawn(callback) end)
            return btn
        end

        -- in-place row updates: labels refresh every second, the row objects stay
        -- alive so clicking a button can never be interrupted by a rebuild
        local rows, emptyLbl = {}, nil

        local function createRow(plr)
            local row = Instance.new("Frame", list)
            row.Size = UDim2.new(1, -4, 0, 54)
            row.BackgroundColor3 = Theme.BgCard
            row.BackgroundTransparency = 0.08
            row.BorderSizePixel = 0
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

            local rStroke = Instance.new("UIStroke", row)
            rStroke.Color = self.color
            rStroke.Thickness = 1
            rStroke.Transparency = 0.55

            local lamp = Instance.new("Frame", row)
            lamp.Size = UDim2.new(0, 4, 1, -12)
            lamp.Position = UDim2.new(0, 0, 0, 6)
            lamp.BackgroundColor3 = self.color
            lamp.BorderSizePixel = 0
            Instance.new("UICorner", lamp).CornerRadius = UDim.new(1, 0)

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size = UDim2.new(1, -212, 0, 18)
            nameLbl.Position = UDim2.new(0, 10, 0, 5)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 12
            nameLbl.TextColor3 = Theme.TextPrimary
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Text = plr.DisplayName

            local infoLbl = Instance.new("TextLabel", row)
            infoLbl.Size = UDim2.new(1, -212, 0, 15)
            infoLbl.Position = UDim2.new(0, 10, 0, 23)
            infoLbl.BackgroundTransparency = 1
            infoLbl.Font = Enum.Font.GothamMedium
            infoLbl.TextSize = 10
            infoLbl.TextColor3 = Theme.TextMuted
            infoLbl.TextXAlignment = Enum.TextXAlignment.Left
            infoLbl.Text = "loading..."

            local metaLbl = Instance.new("TextLabel", row)
            metaLbl.Size = UDim2.new(1, -212, 0, 14)
            metaLbl.Position = UDim2.new(0, 10, 0, 37)
            metaLbl.BackgroundTransparency = 1
            metaLbl.Font = Enum.Font.Gotham
            metaLbl.TextSize = 10
            metaLbl.TextColor3 = Theme.TextMuted
            metaLbl.TextXAlignment = Enum.TextXAlignment.Left
            metaLbl.Text = ""

            rowButton(row, "TGT", -196, self.color, function()
                Config.SelectedPlayer = plr.Name
                notify("Target Locked", plr.DisplayName .. " selected as PvP target", 2.5, CustomIcons.PvP)
            end)
            rowButton(row, "KILL", -148, Theme.Danger, function()
                Config.SelectedPlayer = plr.Name
                Config.AutoKillSelected = true
                notify("Auto Kill", "Hunting " .. plr.DisplayName .. " (Auto Kill Selected ON)", 3, CustomIcons.PvP)
            end)
            rowButton(row, "TP", -100, Theme.Success, function()
                if tweenToPlayer(plr) then
                    notify("Teleport", "Tweening to " .. plr.Name, 2.5, CustomIcons.Teleport)
                else
                    notify("Teleport", plr.Name .. " has no character", 2.5, CustomIcons.Stop)
                end
            end)
            rowButton(row, "CAM", -52, Theme.AccentSecondary, function()
                Config.SelectedPlayer = plr.Name
                Config.SpectatePlayer = true
                setSpectate(plr)
                notify("Spectate", "Watching " .. plr.Name, 2.5, CustomIcons.ESP)
            end)

            return { row = row, stroke = rStroke, lamp = lamp, nameLbl = nameLbl, infoLbl = infoLbl, metaLbl = metaLbl }
        end

        local function rebuild()
            local myRoot = getRoot()
            local present = {}
            local presentCount = 0
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    present[plr.Name] = plr
                    presentCount = presentCount + 1
                end
            end

            -- drop rows for players who left
            for name, entry in pairs(rows) do
                if not present[name] then
                    entry.row:Destroy()
                    rows[name] = nil
                end
            end

            -- alphabetical layout order
            local names = {}
            for name in pairs(present) do table.insert(names, name) end
            table.sort(names, function(a, b) return a:lower() < b:lower() end)

            for index, name in ipairs(names) do
                local plr = present[name]
                local entry = rows[name]
                if not entry then
                    entry = createRow(plr)
                    rows[name] = entry
                end
                entry.row.LayoutOrder = index

                local attackable, statusText, statusColor = getPvPStatus(plr)
                local lo = getPlayerLoadout(plr)
                local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                local dist = (hrp and myRoot) and math.floor((hrp.Position - myRoot.Position).Magnitude) or -1
                local giantTag = ""
                if isGiantForm(plr.Character) then
                    giantTag = " · GIANT FORM"
                elseif isBuddhaUser(plr) then
                    giantTag = " · BUDDHA user"
                end

                entry.nameLbl.Text = string.format("%s  [Lv.%s]", plr.DisplayName, tostring(lo.level))
                entry.infoLbl.Text = statusText .. (Config.SelectedPlayer == plr.Name and "  ◀ LOCKED" or "")
                entry.infoLbl.TextColor3 = statusColor
                entry.metaLbl.Text = string.format("Fruit: %s · Style: %s · HP %d/%d · %s%s",
                    lo.fruit, lo.style, lo.hp, lo.maxHp,
                    dist >= 0 and (dist .. "m") or "-", giantTag)
                entry.stroke.Color = statusColor
                entry.lamp.BackgroundColor3 = statusColor
            end

            if presentCount == 0 then
                if not emptyLbl then
                    emptyLbl = Instance.new("TextLabel", list)
                    emptyLbl.Size = UDim2.new(1, 0, 0, 40)
                    emptyLbl.BackgroundTransparency = 1
                    emptyLbl.Font = Enum.Font.GothamMedium
                    emptyLbl.TextSize = 11
                    emptyLbl.TextColor3 = Theme.TextMuted
                    emptyLbl.Text = "No other players in this server."
                end
                emptyLbl.Visible = true
            elseif emptyLbl then
                emptyLbl.Visible = false
            end

            countLbl.Text = string.format("%d online · %d listed", #Players:GetPlayers(), presentCount)
        end

        rebuild()
        task.spawn(function()
            while true do
                task.wait(1)
                if not card.Parent then break end
                pcall(rebuild)
            end
        end)

        table.insert(allSearchables, {frame = card, label = title .. " " .. (desc or "")})
        return { card = card, refresh = rebuild }
    end

    return tabObj
end

-- ═══════════════════════════════════════════════════════════════════════════
--  TABS & SECTIONS (WITH CUSTOM VECTOR ICONS)
-- ═══════════════════════════════════════════════════════════════════════════

local TabFarm     = createTab(CustomIcons.AutoFarm, "Auto Farm",      Color3.fromRGB(56, 189, 248))
local TabPvP      = createTab(CustomIcons.PvP,      "PvP & Players",  Color3.fromRGB(248, 113, 113))
local TabStats    = createTab(CustomIcons.Stats,    "Stats & Combat", Color3.fromRGB(99, 102, 241))
local TabFruits   = createTab(CustomIcons.Fruits,   "Fruits & Raids", Color3.fromRGB(250, 204, 21))
local TabTeleport = createTab(CustomIcons.Teleport, "Teleport & Seas",Color3.fromRGB(34, 197, 94))
local TabESP      = createTab(CustomIcons.ESP,      "ESP & Visuals",  Color3.fromRGB(244, 114, 182))
local TabMisc     = createTab(CustomIcons.Settings, "Misc & Settings",Color3.fromRGB(148, 163, 184))

-- ─── TAB 1: AUTO FARM ───
TabFarm:AddSection("Weapon & Triple-Layer Fast Attack")
TabFarm:AddDropdown("Weapon Category", "Select weapon type to auto-equip during farming", {"Melee", "Sword", "Blox Fruit", "Gun"}, Config.SelectedWeaponType, function(val)
    Config.SelectedWeaponType = val
end, CustomIcons.AutoFarm)
TabFarm:AddToggle("Fast Attack (Farm)", "Triple-layer multi-target RE/RegisterHit + CombatFramework + Tool:Activate", Config.FastAttack, function(v) Config.FastAttack = v end, CustomIcons.Lightning)
TabFarm:AddToggle("Auto Attack Always (Kill Aura)", "Automatically attack all enemies in range even when Auto Farm is OFF", Config.AutoAttackAlways, function(v) Config.AutoAttackAlways = v end, CustomIcons.Lightning)
TabFarm:AddDropdown("Fast Attack Speed", "Choose attack packet interval", {"Super Fast (10ms)", "Fast (25ms)", "Safe (60ms)"}, "Fast (25ms)", function(mode)
    if mode:find("10ms") then
        Config.FastAttackDelay = 0.01
    elseif mode:find("25ms") then
        Config.FastAttackDelay = 0.025
    else
        Config.FastAttackDelay = 0.06
    end
end, CustomIcons.Lightning)
TabFarm:AddSlider("Attack Reach (Studs)", "Multi-target blade hit radius (up to 80 studs)", 25, 80, Config.AttackRange, function(v) Config.AttackRange = v end, CustomIcons.AutoFarm)
TabFarm:AddToggle("Attack Players in Range", "Include enemy players in Fast Attack multi-target hit list", Config.AttackPlayers, function(v) Config.AttackPlayers = v end, CustomIcons.Boss)
TabFarm:AddToggle("Auto Buso Haki", "Automatically activate Aura (Buso Haki) in combat", Config.AutoBuso, function(v) Config.AutoBuso = v end, CustomIcons.Shield)
TabFarm:AddToggle("Bring Mobs (Magnet + SimRadius)", "Pull quest enemies together and lock their physics", Config.BringMobs, function(v) Config.BringMobs = v end, CustomIcons.Layers)
TabFarm:AddToggle("Hitbox Expander (55 Studs)", "Expand enemy HumanoidRootPart hitbox for 100% hit registration (see PvP & Players tab for size/range)", Config.HitboxExpander, function(v) Config.HitboxExpander = v; Config.HitboxMobs = v end, CustomIcons.Layers)
TabFarm:AddSlider("Hover Distance", "Studs above target enemy while farming", 5, 45, Config.FarmDistance, function(v) Config.FarmDistance = v end, CustomIcons.Teleport)

TabFarm:AddSection("Level & Mob Farming")
TabFarm:AddToggle("Auto Farm Level", "Automatically pick up optimal quest for your level and farm", Config.AutoFarmLevel, function(v)
    Config.AutoFarmLevel = v
    if not v then stopTween() end
end, CustomIcons.AutoFarm)
TabFarm:AddToggle("Auto Farm Nearest Mob", "Farm closest living enemy in Workspace.Enemies", Config.AutoFarmNearest, function(v)
    Config.AutoFarmNearest = v
    if not v then stopTween() end
end, CustomIcons.AutoFarm)
TabFarm:AddToggle("Auto Farm Chests", "Tween to spawned Silver, Gold & Diamond chests", Config.AutoFarmChests, function(v)
    Config.AutoFarmChests = v
    if not v then stopTween() end
end, CustomIcons.HubCrest)

TabFarm:AddSection("Boss Hunter (all seas — Sea " .. CURRENT_SEA .. " detected)")
TabFarm:AddDropdown("Select Target Boss", "Every boss of every sea (S1/S2/S3 prefix)", BOSS_LIST_ALL, Config.SelectedBoss, function(val)
    Config.SelectedBoss = val
end, CustomIcons.Boss)
TabFarm:AddToggle("Auto Farm Selected Boss", "Automatically tween to and eliminate chosen boss", Config.AutoFarmBoss, function(v)
    Config.AutoFarmBoss = v
    if not v then stopTween() end
end, CustomIcons.Boss)
TabFarm:AddToggle("Auto Farm All Sea Bosses", "Cycle through all spawned bosses in current sea", Config.AutoFarmAllBosses, function(v)
    Config.AutoFarmAllBosses = v
    if not v then stopTween() end
end, CustomIcons.Boss)

-- ─── TAB 2: STATS & COMBAT ───
TabStats:AddSection("Auto Stats Allocation")
TabStats:AddSlider("Points Per Tick", "Stat points allocated per batch", 1, 100, Config.StatPointsBatch, function(v) Config.StatPointsBatch = v end, CustomIcons.Stats)
TabStats:AddToggle("Auto Melee", "Automatically invest stat points into Melee", Config.AutoStatMelee, function(v) Config.AutoStatMelee = v end, CustomIcons.Stats)
TabStats:AddToggle("Auto Defense", "Automatically invest stat points into Defense", Config.AutoStatDefense, function(v) Config.AutoStatDefense = v end, CustomIcons.Shield)
TabStats:AddToggle("Auto Sword", "Automatically invest stat points into Sword", Config.AutoStatSword, function(v) Config.AutoStatSword = v end, CustomIcons.AutoFarm)
TabStats:AddToggle("Auto Gun", "Automatically invest stat points into Gun", Config.AutoStatGun, function(v) Config.AutoStatGun = v end, CustomIcons.Lightning)
TabStats:AddToggle("Auto Blox Fruit", "Automatically invest stat points into Blox Fruit", Config.AutoStatFruit, function(v) Config.AutoStatFruit = v end, CustomIcons.Fruits)

TabStats:AddSection("Auto Mastery Skill Caster (Z / X / C / V)")
TabStats:AddToggle("Auto Cast Skill [Z]", "Automatically trigger Z mastery skill in combat", Config.AutoSkillComboZ, function(v) Config.AutoSkillComboZ = v end, CustomIcons.Layers)
TabStats:AddToggle("Auto Cast Skill [X]", "Automatically trigger X mastery skill in combat", Config.AutoSkillComboX, function(v) Config.AutoSkillComboX = v end, CustomIcons.Layers)
TabStats:AddToggle("Auto Cast Skill [C]", "Automatically trigger C mastery skill in combat", Config.AutoSkillComboC, function(v) Config.AutoSkillComboC = v end, CustomIcons.Layers)
TabStats:AddToggle("Auto Cast Skill [V]", "Automatically trigger V awakening/transformation skill", Config.AutoSkillComboV, function(v) Config.AutoSkillComboV = v end, CustomIcons.Layers)

TabStats:AddSection("Haki, Race & Fighting Styles")
TabStats:AddToggle("Auto Instinct (Ken Haki)", "Keep Observation Haki active automatically", Config.AutoKen, function(v) Config.AutoKen = v end, CustomIcons.ESP)
TabStats:AddToggle("Auto Race V3 Ability", "Automatically fire Race V3 skill on cooldown", Config.AutoRaceV3, function(v) Config.AutoRaceV3 = v end, CustomIcons.Lightning)
TabStats:AddSection("Combat Aura & Cosmetics")
TabStats:AddToggle("Kill Aura (Auto Attack Always)", "Triple-layer Fast Attack runs even when Auto Farm is OFF", Config.AutoAttackAlways, function(v) Config.AutoAttackAlways = v end, CustomIcons.Lightning)
TabStats:AddToggle("Sovereign Haki Aura VFX", "Client-side neon aura sparks around your character", Config.SovereignHakiAura, function(v) Config.SovereignHakiAura = v end, CustomIcons.Wand)
TabStats:AddSlider("Attack Reach (Studs)", "Multi-target blade hit radius used by every attack layer", 25, 90, Config.AttackRange, function(v) Config.AttackRange = v end, CustomIcons.AutoFarm)
TabStats:AddDropdown("Fighting Style Database", "V1 · V2 · V3 styles — switching also force-equips the Melee tool", FIGHTING_STYLE_ORDER, Config.SelectedFightingStyle or FIGHTING_STYLE_ORDER[1], function(val)
    Config.SelectedFightingStyle = val
end, CustomIcons.AutoFarm)
TabStats:AddButton("Switch & Auto-Equip Style", "Buys/switches the style, then guarantees the Fighting Style tool is equipped", "Equip Now", function()
    local style = Config.SelectedFightingStyle or FIGHTING_STYLE_ORDER[1]
    local ok = equipFightingStyle(style)
    notify("Fighting Style", string.format("%s %s", ok and "Equipped" or "Requested", tostring(style):gsub("%s*%[.*%]$", "")), 3, CustomIcons.AutoFarm)
end, CustomIcons.AutoFarm)
TabStats:AddButton("Force Equip Melee / Style Tool", "Uses ToolTip + known style names + Humanoid:EquipTool + parent fallback", "Force Melee", function()
    local ok = equipWeaponByType("Melee")
    if not ok and getHumanoid() then
        local char = getCharacter()
        local hum = getHumanoid()
        if char and hum then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then hum:UnequipTools() task.wait(0.1) hum:EquipTool(tool) ok = true end
        end
    end
    notify("Melee Equip", ok and "Fighting Style tool equipped" or "No Fighting Style tool found", 3, CustomIcons.AutoFarm)
end, CustomIcons.AutoFarm)
for _, style in ipairs(FIGHTING_STYLES) do
    TabStats:AddButton("Equip " .. style.name, style.tier .. "  •  " .. style.remote .. "  +  instant Melee tool equip", "Switch", function()
        equipFightingStyle(style.name)
        notify("Fighting Style", "Switched to " .. style.name, 2.5, CustomIcons.AutoFarm)
    end, CustomIcons.AutoFarm)
end

-- ─── TAB 3: PVP & PLAYERS ───
TabPvP:AddSection("Auto Player List · live roster")
TabPvP:AddPlayerList(
    "Server Players",
    "Auto-refreshes every second: PvP status lamp, level, fruit, style, distance.  TGT = lock · KILL = auto kill · TP = tween · CAM = spectate",
    286,
    CustomIcons.Players
)

TabPvP:AddSection("Hotkeys")
TabPvP:AddLivePanel("PvP Hotkeys", "quick controls available anywhere in the game", 30, function()
    return "RightShift  →  toggle Skill Aimbot / AimLock\n" ..
           "RightAlt    →  toggle Undetected Bypass Fly\n" ..
           "RightCtrl / F9  →  show / hide the Skill Hub window\n" ..
           "Space (mid-air)  →  Infinite Geppo jump (when enabled)"
end, 96, CustomIcons.Aim)

TabPvP:AddSection("Target Player")
TabPvP:AddInput("Target Player Name", "Type a username (exact or partial) and press Enter", "Username...", Config.SelectedPlayer, function(txt)
    Config.SelectedPlayer = txt
    local plr = getPlayerByName(txt)
    if plr then
        notify("Target Locked", plr.DisplayName .. " is now your PvP target", 2.5, CustomIcons.PvP)
    elseif txt ~= "" then
        notify("Target", "No player matched: " .. tostring(txt), 2.5, CustomIcons.Stop)
    end
end, CustomIcons.Search)
TabPvP:AddButton("Lock Nearest Player", "Selects the closest player in the server as target", "Lock Nearest", function()
    local myRoot = getRoot()
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp and myRoot then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < bestDist then bestDist, best = d, plr end
            end
        end
    end
    if best then
        Config.SelectedPlayer = best.Name
        notify("Target Locked", string.format("%s · %d studs", best.DisplayName, math.floor(bestDist)), 3, CustomIcons.PvP)
    else
        notify("Target", "No other players found", 2.5, CustomIcons.Stop)
    end
end, CustomIcons.Play)
TabPvP:AddButton("Tween / Teleport to Target", "Anti-cheat safe tween flight straight to the target", "Tween To", function()
    local plr = getPlayerByName(Config.SelectedPlayer)
    if tweenToPlayer(plr) then
        notify("Teleport", "Tweening to " .. plr.Name, 2.5, CustomIcons.Teleport)
    else
        notify("Teleport", "Target has no character right now", 2.5, CustomIcons.Stop)
    end
end, CustomIcons.Teleport)
TabPvP:AddButton("Spectate Target", "Locks the camera onto the selected player", "Spectate", function()
    Config.SpectatePlayer = true
    setSpectate(getPlayerByName(Config.SelectedPlayer))
end, CustomIcons.ESP)
TabPvP:AddButton("Stop Spectating", "Returns the camera to your own character", "Stop", function()
    Config.SpectatePlayer = false
    setSpectate(nil)
end, CustomIcons.Stop)

TabPvP:AddSection("PvP Hunter · Kill Players")
TabPvP:AddToggle("Auto Kill Selected Player", "Non-stop triple-layer Fast Attack + skill combo (Z/X/C/V) on the locked target", Config.AutoKillSelected, function(v)
    Config.AutoKillSelected = v
    notify("PvP Hunter", v and ("Hunting " .. tostring(Config.SelectedPlayer ~= "" and Config.SelectedPlayer or "nearest")) or "Selected-player hunting stopped", 3, CustomIcons.PvP)
end, CustomIcons.PvP)
TabPvP:AddToggle("Auto Kill PvP-Enabled Players", "Automatically hunts every damageable player (PVP ON / outside safe zones)", Config.AutoKillPvP, function(v)
    Config.AutoKillPvP = v
    notify("PvP Hunter", v and "Hunting all PvP-enabled players" or "PvP hunt stopped", 3, CustomIcons.PvP)
end, CustomIcons.PvP)
TabPvP:AddToggle("Ignore Friends", "Skips Roblox friends while auto-killing", Config.IgnoreFriendsPvP, function(v) Config.IgnoreFriendsPvP = v end, CustomIcons.Shield)
TabPvP:AddSlider("Hover Distance", "Studs above the target while hunting (giants automatically get extra distance)", 4, 30, Config.PvPTweenDistance, function(v) Config.PvPTweenDistance = v end, CustomIcons.Teleport)
TabPvP:AddSlider("Kill Aura Radius", "Attack every PvP player inside this radius of you", 30, 260, Config.KillAuraRange, function(v) Config.KillAuraRange = v end, CustomIcons.Lightning)
TabPvP:AddToggle("Auto Cast Skills on Target (Z/X/C/V)", "Fires mastery skills during the PvP combo", Config.PvPSkills, function(v) Config.PvPSkills = v end, CustomIcons.Layers)

TabPvP:AddSection("Skill Aimbot / AimLock")
TabPvP:AddToggle("AimLock (Camera + Auto Attack)", "Smooth camera lock onto the target and keep firing attack packets", Config.AimLock, function(v)
    Config.AimLock = v
    notify("Skill Aimbot", v and "AimLock ENGAGED (RightShift toggles)" or "AimLock released", 3, CustomIcons.Aim)
end, CustomIcons.Aim)
TabPvP:AddSlider("AimLock Smoothness", "8 = instant snap · 100 = very smooth tracking", 8, 100, math.floor((Config.AimLockSmoothness or 0.28) * 100), function(v) Config.AimLockSmoothness = v / 100 end, CustomIcons.Aim)
TabPvP:AddSlider("AimLock FOV (Studs)", "Ignore targets further away than this", 0, 2000, Config.AimLockFOV, function(v) Config.AimLockFOV = v end, CustomIcons.ESP)
TabPvP:AddToggle("Player Hitbox Expander", "Inflates the target's HumanoidRootPart so every M1 and skill lands", Config.PlayerHitbox, function(v)
    Config.PlayerHitbox = v
    if not v then
        for name in pairs(PvPState.hitboxOriginals) do
            local plr = getPlayerByName(name)
            if plr then setPlayerHitbox(plr, false) else PvPState.hitboxOriginals[name] = nil end
        end
    end
end, CustomIcons.Layers)
TabPvP:AddSlider("Hitbox Size (Studs)", "Expanded HumanoidRootPart size — the whole model scales with it (great vs Buddha)", 6, 60, Config.PlayerHitboxSize, function(v) Config.PlayerHitboxSize = v end, CustomIcons.Layers)
TabPvP:AddToggle("Attack Range includes players", "Fast Attack / Kill Aura also hits players in range", Config.AttackPlayers, function(v) Config.AttackPlayers = v end, CustomIcons.AutoFarm)

TabPvP:AddSection("Hitbox Expander v2 & Buddha / Giant Combat")
TabPvP:AddToggle("Buddha / Giant Aware Combat", "Detects scaled (Buddha) models: aims at their torso centre, sends every limb as a blade hit and extends reach", Config.BuddhaAwareCombat, function(v)
    Config.BuddhaAwareCombat = v
    notify("Buddha Combat", v and "Giant/Buddha models fully hittable" or "Standard head-only targeting", 3, CustomIcons.PvP)
end, CustomIcons.Shield)
TabPvP:AddToggle("Kill Aura hits every PvP player", "Auto Kill PvP also slashes every other attackable player inside the aura radius", Config.KillAuraAllPvP, function(v) Config.KillAuraAllPvP = v end, CustomIcons.Lightning)
TabPvP:AddToggle("Show Hitbox Visualiser", "Makes the expanded player/mob hitboxes visible so you can see them working", Config.ShowHitboxVisual, function(v) Config.ShowHitboxVisual = v end, CustomIcons.ESP)
TabPvP:AddToggle("Mob Hitbox Expander", "Inflates every living mob in range (works with Bring Mobs OFF, auto-restores)", Config.HitboxMobs, function(v)
    Config.HitboxMobs = v
    notify("Mob Hitbox", v and "Mob hitboxes inflated" or "Mob hitboxes restored", 2.5, CustomIcons.Layers)
end, CustomIcons.Layers)
TabPvP:AddSlider("Mob Hitbox Size", "HumanoidRootPart size applied to mobs", 10, 90, Config.HitboxMobsSize, function(v) Config.HitboxMobsSize = v end, CustomIcons.Layers)
TabPvP:AddSlider("Mob Hitbox Range", "Only mobs within this distance get inflated", 60, 1500, Config.HitboxMobsRange, function(v) Config.HitboxMobsRange = v end, CustomIcons.Teleport)
TabPvP:AddLivePanel("Buddha / Giant Scanner", "live model size + hitbox state per player", 1.5, function()
    local lines = {}
    local myRoot = getRoot()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local _, size = getCharBoundingBox(plr.Character)
            local giant = isGiantForm(plr.Character)
            local buddha = isBuddhaUser(plr)
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local dist = (hrp and myRoot) and math.floor((hrp.Position - myRoot.Position).Magnitude) or -1
            table.insert(lines, string.format("%s · model %s · %s%s · %dm · hitbox %s",
                plr.DisplayName,
                size and string.format("%.0fx%.0f", size.X, size.Y) or "?",
                giant and "GIANT FORM" or "normal",
                buddha and " (Buddha user)" or "",
                dist,
                PvPState.hitboxOriginals[plr.Name] and "EXPANDED" or "normal"))
        end
    end
    if #lines == 0 then return "No players with a live character right now." end
    return table.concat(lines, "\n")
end, 170, CustomIcons.Shield)

TabPvP:AddSection("Player Inspector · who is PvP + their loadout")
TabPvP:AddLivePanel("Player Scanner", "live PvP status · Devil Fruit · Fighting Style · Sword · Gun · Level · Bounty", 1.2, function()
    local lines = {}
    local myRoot = getRoot()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local _, statusText = getPvPStatus(plr)
            local lo = getPlayerLoadout(plr)
            local dist = "-"
            local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp and myRoot then dist = math.floor((hrp.Position - myRoot.Position).Magnitude) .. "m" end
            table.insert(lines, string.format("%s [Lv.%s] %s | Fruit: %s | Style: %s | Sword: %s | Gun: %s | Bounty: %s | %s",
                plr.DisplayName, tostring(lo.level), statusText, lo.fruit, lo.style, lo.sword, lo.gun, lo.bounty, dist))
        end
    end
    if #lines == 0 then return "No other players in this server." end
    return table.concat(lines, "\n")
end, 200, CustomIcons.Players)
TabPvP:AddButton("Print Full Loadout Report", "Writes every player's PvP status + loadout to the console", "Report", function()
    print("══════ SKILL HUB PLAYER REPORT ══════")
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local attackable, statusText = getPvPStatus(plr)
            local lo = getPlayerLoadout(plr)
            print(string.format("[%s] Lv.%s | %s (attackable=%s) | Fruit: %s | Style: %s | Sword: %s | Gun: %s | Bounty: %s | HP %d/%d",
                plr.Name, tostring(lo.level), statusText, tostring(attackable), lo.fruit, lo.style, lo.sword, lo.gun, lo.bounty, lo.hp, lo.maxHp))
        end
    end
    notify("Player Report", "Full loadout report printed to the console (F9)", 3, CustomIcons.Players)
end, CustomIcons.Search)
TabPvP:AddButton("Copy Target Loadout Summary", "Prints the locked target's loadout into the console", "Print Target", function()
    local plr = getPlayerByName(Config.SelectedPlayer)
    if not plr then notify("Player Report", "No target locked", 2.5, CustomIcons.Stop) return end
    local _, statusText = getPvPStatus(plr)
    local lo = getPlayerLoadout(plr)
    print(string.format("[TARGET] %s | %s | Fruit: %s (%s) | Style: %s | Sword: %s | Gun: %s | Lv.%s | Bounty: %s | HP %d/%d",
        plr.Name, statusText, lo.fruit, getFruitTier(lo.fruit).name, lo.style, lo.sword, lo.gun, tostring(lo.level), lo.bounty, lo.hp, lo.maxHp))
    notify("Target Loadout", statusText .. " · " .. lo.fruit, 3.5, CustomIcons.PvP)
end, CustomIcons.Players)

-- ─── TAB 4: FRUITS & RAIDS ───
TabFruits:AddSection("Devil Fruit Sniper (Update 24+ Roster)")
TabFruits:AddDropdown("Target Devil Fruit", "Select up-to-date fruit for Stock Sniper", FRUITS_LIST, Config.SelectedFruit, function(val)
    Config.SelectedFruit = val
end, CustomIcons.Fruits)
TabFruits:AddToggle("Auto Buy Stock Fruit", "Instantly purchase target fruit when in stock at Dealer", Config.AutoSniperStock, function(v) Config.AutoSniperStock = v end, CustomIcons.Fruits)
TabFruits:AddToggle("Auto Grab Spawned Map Fruits", "Tween to natural or dropped Devil Fruits on the map", Config.AutoGrabMapFruits, function(v)
    Config.AutoGrabMapFruits = v
    if not v then stopTween() end
end, CustomIcons.Teleport)
TabFruits:AddToggle("Auto Store Fruits in Inventory", "Automatically store any fruit in Backpack/Character", Config.AutoStoreFruits, function(v) Config.AutoStoreFruits = v end, CustomIcons.Layers)
TabFruits:AddToggle("Auto Roll Gacha (Zioles)", "Rolls a random fruit and reports the exact name via OriginalName", Config.AutoRandomFruit, function(v) Config.AutoRandomFruit = v end, CustomIcons.HubCrest)
TabFruits:AddButton("Roll Random Fruit Now", "Instant Zioles roll — the result is detected and auto-stored", "Roll Now", function()
    invokeCommF("Cousin", "Buy")
    task.wait(0.4)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = getCharacter()
    local fruitName = nil
    for _, container in ipairs({ char, backpack }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and toolMatchesCategory(tool, "Blox Fruit") then
                    fruitName = tostring(tool:GetAttribute("OriginalName") or tool.Name):gsub(" Fruit", "")
                end
            end
        end
    end
    if fruitName then
        notify("Blox Fruit Gacha", fruitName .. "  •  rarity: " .. getFruitTier(fruitName).name, 4, CustomIcons.Fruits)
    else
        notify("Blox Fruit Gacha", "Roll requested — result appears in your inventory", 3, CustomIcons.Fruits)
    end
end, CustomIcons.Fruits)
TabFruits:AddToggle("Auto Store Rolled / Obtained Fruits", "Stores every new fruit (including gacha rolls) using OriginalName", Config.AutoStoreRolled, function(v) Config.AutoStoreRolled = v end, CustomIcons.Layers)

TabFruits:AddSection("Fruit Magnet (Update 24+ instant pull)")
TabFruits:AddToggle("Fruit Magnet", "firetouchinterest + Handle pull on every spawned or dropped fruit", Config.FruitMagnet, function(v)
    Config.FruitMagnet = v
    notify("Fruit Magnet", v and "Magnetising fruits..." or "Fruit Magnet off", 2.5, CustomIcons.Magnet)
end, CustomIcons.Magnet)
TabFruits:AddSlider("Magnet Radius (Studs)", "Fruits within this radius are pulled instantly", 50, 5000, Config.FruitMagnetRadius, function(v) Config.FruitMagnetRadius = v end, CustomIcons.Magnet)
TabFruits:AddButton("Magnet Now (single pulse)", "Instantly pull every fruit inside the magnet radius", "Pull", function()
    for _, entry in ipairs(findFruitHandles(Config.FruitMagnetRadius)) do magnetPart(entry.handle, false) end
    notify("Fruit Magnet", "Pulled nearby fruits", 2.5, CustomIcons.Magnet)
end, CustomIcons.Magnet)
TabFruits:AddButton("Grab Closest Fruit (Tween)", "Tween-flight to the nearest fruit on the map", "Grab", function()
    local list = findFruitHandles(9000)
    table.sort(list, function(a, b) return a.dist < b.dist end)
    if list[1] then tweenTo(list[1].handle.CFrame) end
end, CustomIcons.Teleport)

TabFruits:AddSection("Raids & Awakening")
TabFruits:AddDropdown("Raid Microchip", "Select normal or advanced raid chip", RAID_CHIPS, Config.SelectedRaidChip, function(val)
    Config.SelectedRaidChip = val
end, CustomIcons.Lightning)
TabFruits:AddToggle("Auto Buy Raid Microchip", "Automatically purchase selected raid chip", Config.AutoBuyRaidChip, function(v) Config.AutoBuyRaidChip = v end, CustomIcons.Layers)
TabFruits:AddToggle("Raid Kill Aura", "Eliminate raid enemies in range automatically", Config.AutoRaidAura, function(v) Config.AutoRaidAura = v end, CustomIcons.Boss)
TabFruits:AddToggle("Auto Awaken Fruit Moves", "Automatically awaken equipped fruit ability after raid", Config.AutoAwaken, function(v) Config.AutoAwaken = v end, CustomIcons.Wand)

-- ─── TAB 5: TELEPORT & SEAS ───
TabTeleport:AddSection("Sea Travel")
TabTeleport:AddButton("Travel to First Sea", "Teleport to Old World (PlaceId 2753915549)", "Travel", function() invokeCommF("TravelMain") end, CustomIcons.Teleport)
TabTeleport:AddButton("Travel to Second Sea", "Teleport to Dressrosa / Kingdom of Rose", "Travel", function() invokeCommF("TravelDressrosa") end, CustomIcons.Teleport)
TabTeleport:AddButton("Travel to Third Sea", "Teleport to Zou / Port Town (PlaceId 7449423635)", "Travel", function() invokeCommF("TravelZou") end, CustomIcons.Teleport)

TabTeleport:AddSection("Island Tween Teleport (every sea — works from any PlaceId)")
TabTeleport:AddSlider("Tween Flight Speed", "Studs per second (250-300 recommended)", 120, 360, Config.TweenSpeed, function(v) Config.TweenSpeed = v end, CustomIcons.Lightning)
TabTeleport:AddDropdown("Destination Island", "S1/S2/S3 prefixed island list — never blocked by a wrong Sea detection", ISLAND_LIST_ALL, Config.SelectedIsland, function(val)
    Config.SelectedIsland = val
end, CustomIcons.Teleport)
TabTeleport:AddButton("Tween to Selected Island", "Smooth anti-cheat safe flight to the selected island", "Tween Go", function()
    local targetCF = ISLAND_TELEPORTS_ALL[Config.SelectedIsland]
    if targetCF then
        tweenTo(targetCF, Config.TweenSpeed)
        notify("Teleport", "Tweening to " .. tostring(Config.SelectedIsland), 2.5, CustomIcons.Teleport)
    else
        notify("Teleport", "Unknown island: " .. tostring(Config.SelectedIsland), 3, CustomIcons.Stop)
    end
end, CustomIcons.Play)
TabTeleport:AddButton("Stop Active Tween", "Immediately cancel current flight path", "Stop", stopTween, CustomIcons.Stop)

TabTeleport:AddSection("Sea Detection Control (fixed)")
TabTeleport:AddDropdown("Sea Override", "Auto = PlaceId + live map scan · or force Sea 1 / 2 / 3 manually", { "Auto", "1", "2", "3" }, CONFIG_SEA_OVERRIDE, function(val)
    CONFIG_SEA_OVERRIDE = val
    CURRENT_SEA = refreshSea()
    notify("Sea Detection", string.format("Sea %d via %s", CURRENT_SEA, tostring(SEA_DETECT_SOURCE)), 3, CustomIcons.Teleport)
end, CustomIcons.Server)
TabTeleport:AddButton("Re-detect Sea Now", "Re-scans PlaceId, islands, mobs and level to resolve the sea", "Re-scan", function()
    CONFIG_SEA_OVERRIDE = "Auto"
    CURRENT_SEA = refreshSea()
    notify("Sea Detection", string.format("Sea %d (%s)", CURRENT_SEA, tostring(SEA_DETECT_SOURCE)), 3, CustomIcons.Teleport)
end, CustomIcons.Search)
TabTeleport:AddLivePanel("Sea Report", "live detection breakdown", 2, function()
    local scores = computeSeaScores()
    return string.format(
        "PlaceId: %d\nDetected: Sea %d (%s)\nScores  S1=%d  S2=%d  S3=%d\nOverride: %s",
        game.PlaceId, CURRENT_SEA, tostring(SEA_DETECT_SOURCE),
        scores[1] or 0, scores[2] or 0, scores[3] or 0, tostring(CONFIG_SEA_OVERRIDE)
    )
end, 110, CustomIcons.Server)

-- ─── TAB 6: ESP & VISUALS ───
TabESP:AddSection("World & Entity ESP")
TabESP:AddToggle("Player ESP", "Name, Level, PvP status, HP, distance + full loadout (Fruit / Style / Sword / Gun / Bounty)", Config.ESPPlayers, function(v) Config.ESPPlayers = v; if not v then clearESP() end end, CustomIcons.ESP)
TabESP:AddToggle("Devil Fruit ESP", "Highlight spawned & dropped Devil Fruits across the map", Config.ESPFruits, function(v) Config.ESPFruits = v; if not v then clearESP() end end, CustomIcons.Fruits)
TabESP:AddToggle("Chest ESP", "Highlight Silver, Gold & Diamond chests", Config.ESPChests, function(v) Config.ESPChests = v; if not v then clearESP() end end, CustomIcons.HubCrest)
TabESP:AddToggle("Mirage / Kitsune / Island ESP", "Track Mirage Island, Kitsune Shrine, Prehistoric & all islands", Config.ESPIslands, function(v) Config.ESPIslands = v; if not v then clearESP() end end, CustomIcons.Teleport)
TabESP:AddToggle("Boss ESP", "Display active bosses with live health and distance", Config.ESPBosses, function(v) Config.ESPBosses = v; if not v then clearESP() end end, CustomIcons.Boss)
TabESP:AddToggle("Player Loadout ESP", "Show each player's Fruit, Fighting Style, Sword & Gun above their head", Config.ESPPlayerLoadout, function(v) Config.ESPPlayerLoadout = v end, CustomIcons.Players)
TabESP:AddToggle("Fruit Rarity Colours", "Colour fruit ESP by rarity tier (Common → Mythical)", Config.ESPFruitRarity, function(v) Config.ESPFruitRarity = v end, CustomIcons.Fruits)
TabESP:AddToggle("Tracer Lines", "Draw lines from the crosshair to each player (needs Drawing API)", Config.ESPTracers, function(v)
    Config.ESPTracers = v
    if not v then Hooks.clearESP() end
end, CustomIcons.Aim)

-- ─── TAB 7: MISC & SETTINGS ───
TabMisc:AddSection("Blox Fruits Anti-Cheat Disabler")
TabMisc:AddToggle(
    "Disable Blox Fruits Anti-Cheat",
    "Block :Kick(), Security/TeleportDetect remotes, velocity checks & set infinite SimRadius",
    Config.BypassAntiCheat,
    function(v)
        Config.BypassAntiCheat = v
        if v then initBloxFruitsAntiCheatBypass() end
    end,
    CustomIcons.Shield
)
TabMisc:AddToggle(
    "Anti-Stun & No Busy Lock",
    "Continuously zero Character.Stun & Character.Busy so skills and M1s never interrupt",
    Config.AntiStun,
    function(v)
        Config.AntiStun = v
    end,
    CustomIcons.Lightning
)

TabMisc:AddSection("Undetected Bypass Fly v2 (no flag)")
TabMisc:AddToggle("Enable Fly", "Velocity-driven smooth flight (BodyVelocity + BodyGyro) over an invisible anti-flag pad · RightAlt toggles", Config.FlyEnabled, function(v)
    setFlyState(v)
end, CustomIcons.Fly)
TabMisc:AddSlider("Fly Speed", "Studs per second while flying (also the autopilot speed)", 20, 320, Config.FlySpeed, function(v) Config.FlySpeed = v end, CustomIcons.Fly)
TabMisc:AddToggle("Bypass Mode (anti-flag)", "Smooth acceleration, velocity spike clamp, Humanoid stays grounded on the pad, no PlatformStand", Config.FlyBypassMode, function(v) Config.FlyBypassMode = v end, CustomIcons.Shield)
TabMisc:AddToggle("Freeze WalkSpeed while flying", "Stops the character controller from adding its own walking velocity (recommended)", Config.FlyZeroWalkSpeed, function(v) Config.FlyZeroWalkSpeed = v end, CustomIcons.Lightning)
TabMisc:AddToggle("Auto Farm / PvP Autopilot", "Lets Auto Farm, the Boss Hunter and the PvP hunter fly you to their target instead of tweening", true, function(v)
    Config.FlyJoinAutopilot = v
    if not v then MovementLink.clearFlyTarget() end
end, CustomIcons.Play)
TabMisc:AddToggle("Anti-Void", "Teleports you back up if you ever fall under the map", Config.FlyAntiVoid, function(v) Config.FlyAntiVoid = v end, CustomIcons.Lightning)
TabMisc:AddLivePanel("Fly Status", "live fly / movement debug", 1, function()
    local root = getRoot()
    local vel = Fly.bodyVel and Fly.bodyVel.Velocity or Vector3.zero
    return string.format(
        "Fly: %s   Bypass: %s   Speed: %d\nVelocity: %.1f, %.1f, %.1f  (%.0f studs/s)\nAltitude: %.0f   Autopilot: %s   Unlocked by: %s",
        Config.FlyEnabled and "ON" or "off", Config.FlyBypassMode and "ON" or "raw",
        Config.FlySpeed, vel.X, vel.Y, vel.Z, vel.Magnitude,
        root and root.Position.Y or 0,
        (Fly.autopilot and (os.clock() - Fly.autopilotAt) < 1.5) and "AutoFarm/PvP target" or "manual / hover",
        MovementLink.isFlyActive() and "fly" or "tween"
    )
end, 100, CustomIcons.Fly)

TabMisc:AddSection("Unique Utilities")
TabMisc:AddToggle("Walk on Water", "Spawns an invisible client platform so you walk instead of swimming", Config.WalkOnWater, function(v)
    Config.WalkOnWater = v
    if not v then removeFloorPad() end
end, CustomIcons.Water)
TabMisc:AddToggle("Infinite Geppo / Skyjump", "Press Space in mid-air for endless sky jumps", Config.InfiniteGeppo, function(v) Config.InfiniteGeppo = v end, CustomIcons.Fly)
TabMisc:AddToggle("Infinite Energy", "Keeps Energy / Aura topped up so Buso & Ken never drop", Config.InfiniteEnergy, function(v) Config.InfiniteEnergy = v end, CustomIcons.Lightning)
TabMisc:AddToggle("No Dash Cooldown", "Spams the dash without waiting for the client cooldown", Config.NoDashCooldown, function(v) Config.NoDashCooldown = v end, CustomIcons.Lightning)
TabMisc:AddSlider("Dash Interval", "Delay between dash bursts (seconds × 100)", 5, 120, math.floor((Config.DashInterval or 0.32) * 100), function(v) Config.DashInterval = v / 100 end, CustomIcons.Lightning)
TabMisc:AddToggle("Auto Collect Drops", "Magnetises dropped weapons / loot on the ground", Config.AutoCollectDrops, function(v) Config.AutoCollectDrops = v end, CustomIcons.Magnet)
TabMisc:AddToggle("Sea Event Tracker", "Alerts + ESP for Terror Shark, Leviathan, Kraken, Sea Beast & Cursed Ship raids", Config.SeaEventTracker, function(v)
    Config.SeaEventTracker = v
    if not v then SeaEventState.events = {} end
end, CustomIcons.Server)
TabMisc:AddToggle("Mirage / Mystic Gear Finder", "Tracks Mirage Island, Kitsune Shrine, Prehistoric Island & Mystic (blue) gear", Config.MirageFinder, function(v) Config.MirageFinder = v end, CustomIcons.Magnet)
TabMisc:AddButton("Scan Sea Events Now", "Force an immediate scan of the whole map", "Scan", function()
    SeaEventState.events = scanSeaEvents()
    notify("Sea Event Scan", string.format("%d event marker(s) found", #SeaEventState.events), 3, CustomIcons.Server)
end, CustomIcons.Search)
TabMisc:AddToggle("Server Status HUD", "Second top pill: JobId, players, sea source, kill/aimlock state, events", Config.ServerStatusHUD, function(v)
    Config.ServerStatusHUD = v
    StatusBar.Visible = v
end, CustomIcons.Server)
TabMisc:AddToggle("No Fall Damage / Anti Void Death", "Prevents fall damage and ragdoll while flying or farming", Config.NoFallDamage, function(v) Config.NoFallDamage = v end, CustomIcons.Shield)
TabMisc:AddLivePanel("Server Report", "live server snapshot", 1.5, function()
    local st = getServerStatus()
    return string.format(
        "Job: %s   Players: %d/%d   Ping: %dms\nSea: %d (%s)   Locale: %s\nSea events tracked: %d   Fly: %s   AimLock: %s",
        st.jobId, st.players, st.maxPlayers, st.ping, st.sea, tostring(st.source), tostring(st.region), st.events,
        Config.FlyEnabled and "ON" or "off", Config.AimLock and "ON" or "off"
    )
end, 104, CustomIcons.Server)

TabMisc:AddSection("Team & Character")
TabMisc:AddButton("Join Pirates Team", "Switch allegiance to Pirates via CommF_", "Pirates", function() invokeCommF("SetTeam", "Pirates") end, CustomIcons.AutoFarm)
TabMisc:AddButton("Join Marines Team", "Switch allegiance to Marines via CommF_", "Marines", function() invokeCommF("SetTeam", "Marines") end, CustomIcons.Shield)
TabMisc:AddToggle("Show Top Watermark HUD", "Display live FPS, Ping, Sea & Level bar at top of screen", Config.ShowWatermarkHUD, function(v)
    Config.ShowWatermarkHUD = v
    WatermarkBar.Visible = v
end, CustomIcons.HubCrest)
TabMisc:AddToggle("WalkSpeed Boost", "Override humanoid WalkSpeed", Config.WalkSpeedEnabled, function(v)
    Config.WalkSpeedEnabled = v
    if not v and getHumanoid() then getHumanoid().WalkSpeed = 16 end
end, CustomIcons.Lightning)
TabMisc:AddSlider("WalkSpeed Value", "Custom movement speed", 16, 200, Config.WalkSpeedValue, function(v) Config.WalkSpeedValue = v end, CustomIcons.Lightning)
TabMisc:AddToggle("JumpPower Boost", "Override humanoid JumpPower", Config.JumpPowerEnabled, function(v)
    Config.JumpPowerEnabled = v
    if not v and getHumanoid() then getHumanoid().JumpPower = 50 end
end, CustomIcons.Lightning)
TabMisc:AddSlider("JumpPower Value", "Custom jump power", 50, 350, Config.JumpPowerValue, function(v) Config.JumpPowerValue = v end, CustomIcons.Lightning)
TabMisc:AddToggle("NoClip", "Walk through walls and obstacles", Config.NoClip, function(v) Config.NoClip = v end, CustomIcons.Shield)

TabMisc:AddSection("Codes & Server Utilities")
TabMisc:AddButton("Redeem All Active Codes", "Automatically redeem all 2x EXP & Stat Reset codes", "Redeem All", function()
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    local redeem = rem and rem:FindFirstChild("Redeem")
    for _, code in ipairs(ACTIVE_CODES) do
        pcall(function() if redeem then redeem:InvokeServer(code) end end)
        task.wait(0.1)
    end
    notify("Codes Redeemed", "Redeemed all active Blox Fruits codes!", 3.5, CustomIcons.HubCrest)
end, CustomIcons.HubCrest)
TabMisc:AddButton("FPS Boost / Low Graphics", "Disable shadows, particles & reflections for smooth farming", "Optimize", function()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end
    end)
    notify("FPS Boost", "Graphics optimized for high FPS", 2.5, CustomIcons.Lightning)
end, CustomIcons.Lightning)
TabMisc:AddButton("Rejoin Current Server", "Reconnect to the current Blox Fruits server", "Rejoin", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end, CustomIcons.Loop)
TabMisc:AddButton("Server Hop", "Hop to a different public Blox Fruits server", "Hop", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end, CustomIcons.Teleport)

-- Window Controls
local windowVisible = true
local function toggleWindow()
    windowVisible = not windowVisible
    MainWindow.Visible = windowVisible
end

MinBtn.MouseButton1Click:Connect(toggleWindow)
FloatBtn.MouseButton1Click:Connect(toggleWindow)
CloseBtn.MouseButton1Click:Connect(function()
    stopTween()
    Hooks.clearESP()
    flyDisable()
    removeFloorPad()
    ESPFolder:Destroy()
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.F9 then
        toggleWindow()
    end
end)

-- PvP quick hotkeys (RightCtrl / F9 = toggle window)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Config.AimLock = not Config.AimLock
        Hooks.notify("Skill Aimbot / AimLock", Config.AimLock and "ENGAGED" or "released", 2.5, CustomIcons.Aim)
    elseif input.KeyCode == Enum.KeyCode.RightAlt then
        Config.FlyEnabled = not Config.FlyEnabled
        setFlyState(Config.FlyEnabled)
    end
end)

notify(
    "Skill Hub v3.0 Ultra",
    string.format("Blox Fruits Update 24+ • Sea %d (%s) • PvP & Players tab added • RightCtrl = toggle, RightShift = AimLock, RightAlt = Fly", CURRENT_SEA, tostring(SEA_DETECT_SOURCE)),
    5,
    CustomIcons.HubCrest
)
