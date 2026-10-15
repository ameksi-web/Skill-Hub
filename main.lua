--[[
    Skill Hub v2.5 Ultra — Blox Fruits Edition (Update 24+)
    Features:
      • Custom Vector Icon System (Lucide/Feather rbxassetid + Glowing Vector Badges)
      • Hybrid Fluent UI Library + Native Glassmorphic ScreenGui
      • Up-to-Date Blox Fruits Data (Kitsune, Dragon West/East, T-Rex, Mammoth, Gas, Yeti, Blade, Rocket, Ghost, Pain, Tiki Outpost)
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
}

-- ═══════════════════════════════════════════════════════════════════════════
--  UP-TO-DATE BLOX FRUITS DATA (UPDATE 24+ / DRAGON REWORK / TIKI OUTPOST)
--  Outdated names (Kilo, Revive, Paw, Door, String, Chop, Soul) replaced.
-- ═══════════════════════════════════════════════════════════════════════════

local PLACE_IDS = {
    FirstSea  = 2753915549,
    SecondSea = 4442272183,
    ThirdSea  = 7449423635,
}

local CURRENT_SEA = 1
if game.PlaceId == PLACE_IDS.SecondSea then
    CURRENT_SEA = 2
elseif game.PlaceId == PLACE_IDS.ThirdSea then
    CURRENT_SEA = 3
end

local FRUITS_LIST = {
    -- Common
    "Rocket", "Spin", "Blade", "Spring", "Bomb", "Smoke", "Spike",
    -- Uncommon
    "Flame", "Falcon", "Ice", "Sand", "Dark", "Diamond",
    -- Rare
    "Light", "Rubber", "Barrier", "Ghost", "Magma",
    -- Legendary
    "Quake", "Buddha", "Love", "Spider", "Sound", "Phoenix", "Portal", "Rumble", "Pain", "Blizzard",
    -- Mythical
    "Gravity", "Mammoth", "T-Rex", "Dough", "Shadow", "Venom", "Control", "Gas", "Spirit", "Leopard", "Yeti", "Kitsune", "Dragon (West)", "Dragon (East)",
}

local FRUIT_STORE_CODES = {}
for _, fName in ipairs(FRUITS_LIST) do
    FRUIT_STORE_CODES[fName] = fName .. "-" .. fName
end

local RAID_CHIPS = {
    "Flame", "Ice", "Quake", "Light", "Dark", "Spider",
    "Rumble", "Magma", "Buddha", "Sand", "Phoenix", "Dough",
}

local FIGHTING_STYLES = {
    ["Sanguine Art"]    = "BuySanguineArt",
    ["Godhuman"]        = "BuyGodhuman",
    ["Dragon Talon"]    = "BuyDragonTalon",
    ["Electric Claw"]   = "BuyElectricClaw",
    ["Sharkman Karate"] = "BuySharkmanKarate",
    ["Death Step"]      = "BuyDeathStep",
    ["Superhuman"]      = "BuySuperhuman",
}

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
    SelectedBoss        = BOSSES_BY_SEA[CURRENT_SEA][1],
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

    SelectedIsland      = next(ISLAND_TELEPORTS[CURRENT_SEA]) or "Middle Town",

    ESPPlayers          = false,
    ESPFruits           = false,
    ESPChests           = false,
    ESPIslands          = false,
    ESPBosses           = false,

    -- Moon Animator & Skill Caster State
    SovereignHakiAura   = false,
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

-- ═══════════════════════════════════════════════════════════════════════════
--  CORE BLOX FRUITS REMOTES, ANIMATOR & VFX HELPERS
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
    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end
    local root = getRoot()
    if root and root:FindFirstChild("SkillHubAntiFall") then
        root.SkillHubAntiFall:Destroy()
    end
end

local function tweenTo(targetCFrame)
    local root = getRoot()
    if not root or not targetCFrame then return end

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

local function equipWeaponByType(weaponType)
    local char = getCharacter()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return end

    local targetTooltip = weaponType or "Melee"
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == targetTooltip then return end
    end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == targetTooltip then
            local hum = getHumanoid()
            if hum then hum:EquipTool(tool) end
            return
        end
    end
end

local function triggerFastAttack()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(1280, 672))
    end)
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("Modules")
            and ReplicatedStorage.Modules:FindFirstChild("Net")
        if net then
            local regAtk = net:FindFirstChild("RE/RegisterAttack")
            local regHit = net:FindFirstChild("RE/RegisterHit")
            if regAtk then regAtk:FireServer(0) end
            if regHit then
                local enemies = Workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local hrp = mob:FindFirstChild("HumanoidRootPart")
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            regHit:FireServer(hrp)
                            break
                        end
                    end
                end
            end
        end
    end)
end

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
            if hrp and hum and hum.Health > 0 and (hrp.Position - targetPos).Magnitude <= 300 then
                pcall(function()
                    hrp.CFrame = CFrame.new(targetPos)
                    hrp.CanCollide = false
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
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

                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local mHum = mob:FindFirstChildOfClass("Humanoid")
                        local mHrp = mob:FindFirstChild("HumanoidRootPart")
                        if mHum and mHum.Health > 0 and mHrp then
                            if Config.AutoFarmBoss and mob.Name:find(Config.SelectedBoss, 1, true) then
                                targetBoss = mob
                                break
                            elseif Config.AutoFarmAllBosses then
                                for _, bName in ipairs(seaBosses) do
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
                if Config.WalkSpeedEnabled then hum.WalkSpeed = Config.WalkSpeedValue end
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

local function createESPBillboard(adornee, titleText, subText, color)
    if not adornee then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Tag"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 180, 0, 42)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = ESPFolder

    local mainLbl = Instance.new("TextLabel", bb)
    mainLbl.Size = UDim2.new(1, 0, 0.55, 0)
    mainLbl.BackgroundTransparency = 1
    mainLbl.Font = Enum.Font.GothamBold
    mainLbl.TextSize = 13
    mainLbl.TextColor3 = color
    mainLbl.TextStrokeTransparency = 0.25
    mainLbl.Text = titleText

    local subLbl = Instance.new("TextLabel", bb)
    subLbl.Size = UDim2.new(1, 0, 0.45, 0)
    subLbl.Position = UDim2.new(0, 0, 0.55, 0)
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.GothamMedium
    subLbl.TextSize = 11
    subLbl.TextColor3 = Color3.fromRGB(220, 230, 255)
    subLbl.TextStrokeTransparency = 0.35
    subLbl.Text = subText or ""
end

task.spawn(function()
    while task.wait(1.0) do
        pcall(function()
            clearESP()
            local myRoot = getRoot()
            if not myRoot then return end

            if Config.ESPPlayers then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and hum then
                            local dist = math.floor((hrp.Position - myRoot.Position).Magnitude)
                            local lv = (plr:FindFirstChild("Data") and plr.Data:FindFirstChild("Level") and plr.Data.Level.Value) or "?"
                            createESPBillboard(hrp, string.format("%s [Lv.%s]", plr.DisplayName, tostring(lv)), string.format("HP: %d/%d • %dm", math.floor(hum.Health), math.floor(hum.MaxHealth), dist), Color3.fromRGB(56, 189, 248))
                        end
                    end
                end
            end

            if Config.ESPFruits then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA("Tool") or obj.Name:find("Fruit") then
                        local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
                        if handle then
                            local dist = math.floor((handle.Position - myRoot.Position).Magnitude)
                            createESPBillboard(handle, obj.Name, string.format("%d studs away", dist), Color3.fromRGB(250, 204, 21))
                        end
                    end
                end
            end

            if Config.ESPChests then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name == "Chest1" or obj.Name == "Chest2" or obj.Name == "Chest3") then
                        local dist = math.floor((obj.Position - myRoot.Position).Magnitude)
                        if dist < 2500 then
                            createESPBillboard(obj, obj.Name, string.format("%d studs", dist), Color3.fromRGB(74, 222, 128))
                        end
                    end
                end
            end

            if Config.ESPIslands then
                local map = Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("Locations")
                if map then
                    for _, loc in ipairs(map:GetChildren()) do
                        if loc:IsA("BasePart") then
                            local dist = math.floor((loc.Position - myRoot.Position).Magnitude)
                            local isSpecial = loc.Name:find("Mirage") or loc.Name:find("Kitsune") or loc.Name:find("Prehistoric")
                            createESPBillboard(loc, loc.Name, string.format("%d studs", dist), isSpecial and Color3.fromRGB(244, 114, 182) or Color3.fromRGB(167, 139, 250))
                        end
                    end
                end
            end

            if Config.ESPBosses then
                local enemies = Workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local hrp = mob:FindFirstChild("HumanoidRootPart")
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local dist = math.floor((hrp.Position - myRoot.Position).Magnitude)
                            createESPBillboard(hrp, mob.Name, string.format("HP: %d • %dm", math.floor(hum.Health), dist), Color3.fromRGB(248, 113, 113))
                        end
                    end
                end
            end
        end)
    end
end)

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

-- Top Live Watermark HUD Pill
local WatermarkBar = Instance.new("Frame", ScreenGui)
WatermarkBar.Name = "WatermarkHUD"
WatermarkBar.Size = UDim2.new(0, 450, 0, 32)
WatermarkBar.Position = UDim2.new(0.5, -225, 0, 10)
WatermarkBar.BackgroundColor3 = Theme.BgSidebar
WatermarkBar.BackgroundTransparency = 0.08
WatermarkBar.BorderSizePixel = 0
WatermarkBar.ZIndex = 85
Instance.new("UICorner", WatermarkBar).CornerRadius = UDim.new(1, 0)

local wmStroke = Instance.new("UIStroke", WatermarkBar)
wmStroke.Color = Theme.Accent
wmStroke.Thickness = 1.2
wmStroke.Transparency = 0.3

createVectorIconBadge(WatermarkBar, CustomIcons.HubCrest, Theme.Accent, 22, UDim2.new(0, 6, 0.5, -11), 86)

local WatermarkText = Instance.new("TextLabel", WatermarkBar)
WatermarkText.Size = UDim2.new(1, -40, 1, 0)
WatermarkText.Position = UDim2.new(0, 34, 0, 0)
WatermarkText.BackgroundTransparency = 1
WatermarkText.Font = Enum.Font.GothamBold
WatermarkText.TextSize = 11
WatermarkText.TextColor3 = Theme.TextPrimary
WatermarkText.TextXAlignment = Enum.TextXAlignment.Left
WatermarkText.Text = "SKILL HUB v2.5 ULTRA  •  Sea " .. CURRENT_SEA .. "  •  FPS: 60"
WatermarkText.ZIndex = 87

task.spawn(function()
    local lastTick = tick()
    local frames = 0
    RunService.RenderStepped:Connect(function()
        frames += 1
    end)
    while task.wait(1.0) do
        if not ScreenGui.Parent then break end
        local now = tick()
        local fps = math.floor(frames / math.max(now - lastTick, 0.01))
        frames = 0
        lastTick = now
        local ping = 0
        pcall(function()
            ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        WatermarkBar.Visible = Config.ShowWatermarkHUD
        WatermarkText.Text = string.format(
            "SKILL HUB v2.5  •  Sea %d  •  Lv.%d  •  %d FPS  •  %dms",
            CURRENT_SEA, getPlayerLevel(), fps, ping
        )
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
    end

    function tabObj:AddToggle(title, desc, defaultValue, callback, itemIcon)
        self.order += 1
        local card = Instance.new("Frame", self.page)
        card.Size = UDim2.new(1, 0, 0, 54)
        card.BackgroundColor3 = Theme.BgCard
        card.BorderSizePixel = 0
        card.LayoutOrder = self.order
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)

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

    return tabObj
end

-- ═══════════════════════════════════════════════════════════════════════════
--  TABS & SECTIONS (WITH CUSTOM VECTOR ICONS)
-- ═══════════════════════════════════════════════════════════════════════════

local TabFarm     = createTab(CustomIcons.AutoFarm, "Auto Farm",      Color3.fromRGB(56, 189, 248))
local TabStats    = createTab(CustomIcons.Stats,    "Stats & Combat", Color3.fromRGB(99, 102, 241))
local TabFruits   = createTab(CustomIcons.Fruits,   "Fruits & Raids", Color3.fromRGB(250, 204, 21))
local TabTeleport = createTab(CustomIcons.Teleport, "Teleport & Seas",Color3.fromRGB(34, 197, 94))
local TabESP      = createTab(CustomIcons.ESP,      "ESP & Visuals",  Color3.fromRGB(244, 114, 182))
local TabMisc     = createTab(CustomIcons.Settings, "Misc & Settings",Color3.fromRGB(148, 163, 184))

-- ─── TAB 1: AUTO FARM ───
TabFarm:AddSection("Weapon & Attack Configuration")
TabFarm:AddDropdown("Weapon Category", "Select weapon type to auto-equip during farming", {"Melee", "Sword", "Blox Fruit", "Gun"}, Config.SelectedWeaponType, function(val)
    Config.SelectedWeaponType = val
end, CustomIcons.AutoFarm)
TabFarm:AddToggle("Fast Attack", "Zero-cooldown attack register & VirtualUser clicker", Config.FastAttack, function(v) Config.FastAttack = v end, CustomIcons.Lightning)
TabFarm:AddToggle("Auto Buso Haki", "Automatically activate Aura (Buso Haki) in combat", Config.AutoBuso, function(v) Config.AutoBuso = v end, CustomIcons.Shield)
TabFarm:AddToggle("Bring Mobs (Magnet)", "Stack quest enemies closely under your farm hover point", Config.BringMobs, function(v) Config.BringMobs = v end, CustomIcons.Layers)
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

TabFarm:AddSection("Boss Hunter (Sea " .. CURRENT_SEA .. ")")
TabFarm:AddDropdown("Select Target Boss", "Up-to-date bosses for Current Sea", BOSSES_BY_SEA[CURRENT_SEA], Config.SelectedBoss, function(val)
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
for styleName, remoteArg in pairs(FIGHTING_STYLES) do
    TabStats:AddButton("Equip " .. styleName, "Switch to " .. styleName .. " via CommF_ remote", "Switch", function()
        invokeCommF(remoteArg)
        notify("Fighting Style", "Switched to " .. styleName, 2.5, CustomIcons.AutoFarm)
    end, CustomIcons.AutoFarm)
end

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
TabFruits:AddToggle("Auto Roll Gacha (Zioles)", "Automatically roll random fruit from Blox Fruit Gacha", Config.AutoRandomFruit, function(v) Config.AutoRandomFruit = v end, CustomIcons.HubCrest)
TabFruits:AddButton("Roll Random Fruit Now", "Single instant purchase from Zioles Gacha NPC", "Roll Now", function()
    invokeCommF("Cousin", "Buy")
    notify("Blox Fruit Gacha", "Rolled random fruit from Zioles", 2.5, CustomIcons.Fruits)
end, CustomIcons.Fruits)

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

TabTeleport:AddSection("Island Tween Teleport (Sea " .. CURRENT_SEA .. ")")
local currentSeaIslands = {}
for islandName in pairs(ISLAND_TELEPORTS[CURRENT_SEA]) do table.insert(currentSeaIslands, islandName) end
table.sort(currentSeaIslands)

TabTeleport:AddSlider("Tween Flight Speed", "Studs per second (250-300 recommended)", 120, 360, Config.TweenSpeed, function(v) Config.TweenSpeed = v end, CustomIcons.Lightning)
TabTeleport:AddDropdown("Destination Island", "Choose island in current sea", currentSeaIslands, currentSeaIslands[1], function(val)
    Config.SelectedIsland = val
end, CustomIcons.Teleport)
TabTeleport:AddButton("Tween to Selected Island", "Smooth anti-cheat safe flight to selected island", "Tween Go", function()
    local targetCF = ISLAND_TELEPORTS[CURRENT_SEA][Config.SelectedIsland]
    if targetCF then tweenTo(targetCF) end
end, CustomIcons.Play)
TabTeleport:AddButton("Stop Active Tween", "Immediately cancel current flight path", "Stop", stopTween, CustomIcons.Stop)

-- ─── TAB 6: ESP & VISUALS ───
TabESP:AddSection("World & Entity ESP")
TabESP:AddToggle("Player ESP", "Display player names, levels, HP and distance", Config.ESPPlayers, function(v) Config.ESPPlayers = v; if not v then clearESP() end end, CustomIcons.ESP)
TabESP:AddToggle("Devil Fruit ESP", "Highlight spawned & dropped Devil Fruits across the map", Config.ESPFruits, function(v) Config.ESPFruits = v; if not v then clearESP() end end, CustomIcons.Fruits)
TabESP:AddToggle("Chest ESP", "Highlight Silver, Gold & Diamond chests", Config.ESPChests, function(v) Config.ESPChests = v; if not v then clearESP() end end, CustomIcons.HubCrest)
TabESP:AddToggle("Mirage / Kitsune / Island ESP", "Track Mirage Island, Kitsune Shrine, Prehistoric & all islands", Config.ESPIslands, function(v) Config.ESPIslands = v; if not v then clearESP() end end, CustomIcons.Teleport)
TabESP:AddToggle("Boss ESP", "Display active bosses with live health and distance", Config.ESPBosses, function(v) Config.ESPBosses = v; if not v then clearESP() end end, CustomIcons.Boss)

-- ─── TAB 7: MISC & SETTINGS ───
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
    clearESP()
    ESPFolder:Destroy()
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.F9 then
        toggleWindow()
    end
end)

notify("Skill Hub v2.5 Ultra", string.format("Blox Fruits Update 24+ Ready (Sea %d) • RightCtrl to toggle", CURRENT_SEA), 4, CustomIcons.HubCrest)
