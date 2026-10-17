--[[
    ██╗  ██╗██╗██╗     ██╗         ██╗  ██╗██╗   ██╗██████╗
    ██║ ██╔╝██║██║     ██║         ██║  ██║██║   ██║██╔══██╗
    █████╔╝ ██║██║     ██║         ███████║██║   ██║██████╔╝
    ██╔═██╗ ██║██║     ██║         ██╔══██║██║   ██║██╔══██╗
    ██║  ██╗██║███████╗███████╗    ██║  ██║╚██████╔╝██████╔╝
    ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    Skill Hub — FREE BLOX FRUIT  ·  free edition (no key, readable, no loader)
    by ameksi-web  ·  https://github.com/ameksi-web/Skill-Hub

    ── how to run ──────────────────────────────────────────────────────────────
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/Free%20Blox%20Fruit/SkillHub.lua"))()

    ── what this is ────────────────────────────────────────────────────────────
        The Skill Hub farm for Blox Fruits with the "Porcelain" design system:
        soft layered surfaces, hairline borders, muted editorial accents and a
        hand-drawn vector icon set — six complete themes included.

        Two tabs, and only two:  Auto Farm  ·  Settings

        Auto Farm is the farm the closed build has — target picking, travel,
        fast attack, kill aura, bring mobs, mob hitbox, chests, fruit, drops,
        auto skill — but nothing is enabled when the script loads. Every switch
        starts OFF, and no loop touches your character until you turn it on.

        Settings is the part the closed build never had in the open: six themes
        (each restyles the whole window live), a UI scale, a real config file
        with autosave, manual save / load / reset, and export / import as text
        so a config can be shared even on an executor without file access.

    ── READ THIS BEFORE TURNING ANYTHING ON ────────────────────────────────────
        Blox Fruits resolves damage, drops and quest progress on the server.
        This hub is an input layer: it picks targets, walks the character, and
        presses the same buttons you would press — it cannot make a hit land,
        grant items, or hide the fact that an executor is injected. Farm rates
        are paced on purpose; the "Safe mode" switch lowers them further.

        Use an account you can afford to lose. That is not a disclaimer bolted
        on the end — it is the honest summary of what a client script can do.
]]

local META = {
    version = "v1.1",
    build   = "Free Blox Fruit · farm + config · six themes",
    author  = "ameksi-web",
    game    = "Blox Fruits",
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 0 · SERVICES AND CHEAP HELPERS  (never let a missing service break the load)
-- ═══════════════════════════════════════════════════════════════════════════
local function getService(name)
    local ok, service = pcall(function() return game:GetService(name) end)
    return ok and service or nil
end

local Players      = getService("Players")
local RunService   = getService("RunService")
local TweenService = getService("TweenService")
local UserInput    = getService("UserInputService")
local Lighting     = getService("Lighting")
local Workspace    = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = getService("CollectionService")
local VirtualUser  = getService("VirtualUser")
local VirtualInputManager = getService("VirtualInputManager")
local Camera       = Workspace.CurrentCamera

local function refreshCamera()
    local live = Workspace.CurrentCamera
    if live and live ~= Camera then Camera = live end
    return Camera
end

local LocalPlayer  = Players and Players.LocalPlayer

local SharedEnv = (getgenv and getgenv()) or _G

local function safe(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function safeCall(name, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        local log = SharedEnv.__SkillHubErrorLog
        if log then table.insert(log, tostring(name) .. ": " .. tostring(result)) end
    end
    return ok and result or nil
end

local function clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

local function fmtNum(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.2ft", n / 1e12) end
    if n >= 1e9 then return string.format("%.2fb", n / 1e9) end
    if n >= 1e6 then return string.format("%.2fm", n / 1e6) end
    if n >= 1e4 then return string.format("%.2fk", n / 1e4) end
    return tostring(math.floor(n))
end

local function clockString()
    return os.date("%H:%M:%S")
end

local function monotonic()
    return os.clock()
end

local function round(n, places)
    local mult = 10 ^ (places or 0)
    return math.floor((tonumber(n) or 0) * mult + 0.5) / mult
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 1 · CONFIG  (one table, every feature reads and writes it)
--     Every feature switch starts false. The hub never turns anything on by
--     itself, and a saved config is only applied when you press Load (or when
--     Autoload is on — and even then only the harmless interface keys).
-- ═══════════════════════════════════════════════════════════════════════════
local Config = {
    -- ── the farm ──────────────────────────────────────────────────────────
    AutoFarm            = false,       -- master: pick a target, travel, attack
    FarmMode            = "Nearest mob",   -- Nearest mob | Quest area | Boss
    AutoQuest           = false,       -- talk to the quest NPC when it is near
    AutoAttack          = false,       -- fast attack on the current target
    AttackRate          = 0.18,        -- seconds between attacks
    AttackRange         = 16,          -- studs; melee reach plus a little slack
    KillAura            = false,       -- attack every mob inside the radius
    AuraRadius          = 14,
    BringMobs           = false,       -- drag nearby mobs to your feet
    BringRadius         = 60,
    MobHitbox           = false,       -- scale mob hitboxes so hits land
    HitboxSize          = 2.2,
    AutoSkill           = false,       -- Z / X / C / V on a cadence
    SkillInterval       = 0.9,

    -- ── loot ──────────────────────────────────────────────────────────────
    AutoChest           = false,
    AutoFruit           = false,
    AutoDrops           = false,
    ScanRange           = 250,

    -- ── travel ────────────────────────────────────────────────────────────
    TweenTravel         = true,        -- paced steps instead of one jump
    TravelSpeed         = 90,          -- studs per second
    TravelStep          = 10,          -- max studs per step
    TravelDelay         = 0.08,        -- seconds between steps
    MouseClicks         = false,       -- the tool is always activated; this adds a click

    -- ── movement ──────────────────────────────────────────────────────────
    WalkSpeedEnabled    = false,
    WalkSpeed           = 40,
    JumpPowerEnabled    = false,
    JumpPower           = 70,
    InfiniteJump        = false,

    -- ── safety ────────────────────────────────────────────────────────────
    SafeMode            = true,        -- caps rates below the aggressive values
    SpeedCap            = 60,

    -- ── interface ─────────────────────────────────────────────────────────
    Theme               = "Porcelain",
    UiScale             = 1.00,
    HideUiKey           = "RightControl",
    PanicKey            = "F1",
    UiVisible           = true,
    UiX                 = 0,            -- window position, 0 = centred
    UiY                 = 0,

    -- ── config file ───────────────────────────────────────────────────────
    Autosave            = true,
    Autoload            = false,
    ConfigPath          = "FreeBloxFruit/config.json",
    ProfileSlot         = "1",
    NotifyActions       = true,
}

SharedEnv.SkillHubConfig = SharedEnv.SkillHubConfig or Config
SharedEnv.__SkillHubErrorLog = SharedEnv.__SkillHubErrorLog or {}

-- ═══════════════════════════════════════════════════════════════════════════
-- 2 · THEMES — six complete palettes, applied by rebuilding the window
--     A theme is not a tint: surfaces, text, accents, hairline strength, the
--     shadow, and the corner radii all change, which is what makes them read
--     as different menu styles instead of six colour swaps.
-- ═══════════════════════════════════════════════════════════════════════════
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local THEMES = {
    Porcelain = {
        label = "Porcelain · graphite",
        BgApp = rgb(9, 10, 12), BgSurface = rgb(17, 19, 23), BgElevated = rgb(23, 26, 31),
        BgRaised = rgb(29, 33, 39), BgInset = rgb(13, 15, 18), BgHover = rgb(33, 37, 44),
        BgSidebar = rgb(15, 17, 20),
        Hairline = rgb(58, 63, 72), Stroke = rgb(44, 49, 57), StrokeSoft = rgb(35, 39, 46),
        TextPrimary = rgb(243, 244, 246), TextSecondary = rgb(158, 165, 175),
        TextMuted = rgb(110, 117, 127), TextFaint = rgb(78, 84, 93),
        OnAccent = rgb(13, 14, 17), Shadow = rgb(4, 5, 7),
        Accent = rgb(126, 141, 255), AccentSecondary = rgb(150, 158, 186),
        Iris = rgb(126, 141, 255), Clay = rgb(226, 132, 122), Sand = rgb(223, 181, 133),
        Sage = rgb(128, 182, 155), Mauve = rgb(173, 143, 222), Steel = rgb(150, 158, 186),
        Sky = rgb(136, 170, 203), Rose = rgb(201, 141, 178),
        Success = rgb(122, 190, 146), Warning = rgb(224, 184, 116), Danger = rgb(223, 118, 116),
        radius = { window = 20, panel = 14, card = 12, control = 10, chip = 8, pill = 999 },
    },
    Midnight = {
        label = "Midnight · deep navy",
        BgApp = rgb(4, 7, 14), BgSurface = rgb(10, 15, 26), BgElevated = rgb(14, 21, 36),
        BgRaised = rgb(19, 28, 47), BgInset = rgb(7, 11, 20), BgHover = rgb(24, 35, 58),
        BgSidebar = rgb(8, 12, 22),
        Hairline = rgb(44, 61, 92), Stroke = rgb(33, 47, 71), StrokeSoft = rgb(24, 35, 54),
        TextPrimary = rgb(232, 241, 255), TextSecondary = rgb(139, 160, 194),
        TextMuted = rgb(96, 116, 148), TextFaint = rgb(66, 83, 110),
        OnAccent = rgb(4, 8, 16), Shadow = rgb(1, 2, 5),
        Accent = rgb(96, 176, 255), AccentSecondary = rgb(140, 168, 210),
        Iris = rgb(96, 176, 255), Clay = rgb(120, 190, 255), Sand = rgb(150, 206, 255),
        Sage = rgb(96, 214, 196), Mauve = rgb(166, 156, 255), Steel = rgb(132, 162, 200),
        Sky = rgb(96, 176, 255), Rose = rgb(190, 158, 240),
        Success = rgb(86, 210, 168), Warning = rgb(230, 190, 120), Danger = rgb(240, 120, 130),
        radius = { window = 16, panel = 12, card = 10, control = 8, chip = 6, pill = 999 },
    },
    Obsidian = {
        label = "Obsidian · sharp amber",
        BgApp = rgb(5, 5, 5), BgSurface = rgb(12, 12, 12), BgElevated = rgb(18, 18, 18),
        BgRaised = rgb(25, 24, 22), BgInset = rgb(8, 8, 8), BgHover = rgb(30, 29, 26),
        BgSidebar = rgb(9, 9, 9),
        Hairline = rgb(66, 62, 52), Stroke = rgb(46, 43, 36), StrokeSoft = rgb(32, 30, 26),
        TextPrimary = rgb(245, 242, 234), TextSecondary = rgb(174, 166, 148),
        TextMuted = rgb(126, 119, 104), TextFaint = rgb(88, 83, 72),
        OnAccent = rgb(10, 9, 6), Shadow = rgb(0, 0, 0),
        Accent = rgb(232, 176, 88), AccentSecondary = rgb(180, 168, 142),
        Iris = rgb(232, 176, 88), Clay = rgb(220, 132, 96), Sand = rgb(232, 176, 88),
        Sage = rgb(164, 190, 122), Mauve = rgb(190, 150, 120), Steel = rgb(160, 156, 146),
        Sky = rgb(150, 176, 186), Rose = rgb(206, 142, 116),
        Success = rgb(150, 196, 116), Warning = rgb(232, 176, 88), Danger = rgb(214, 92, 84),
        radius = { window = 6, panel = 4, card = 3, control = 2, chip = 2, pill = 2 },
    },
    Ivory = {
        label = "Ivory · paper light",
        BgApp = rgb(226, 224, 218), BgSurface = rgb(247, 245, 240), BgElevated = rgb(255, 255, 252),
        BgRaised = rgb(250, 248, 243), BgInset = rgb(236, 234, 228), BgHover = rgb(240, 238, 232),
        BgSidebar = rgb(241, 239, 233),
        Hairline = rgb(196, 192, 183), Stroke = rgb(214, 210, 201), StrokeSoft = rgb(226, 223, 215),
        TextPrimary = rgb(34, 34, 38), TextSecondary = rgb(88, 88, 96),
        TextMuted = rgb(122, 122, 130), TextFaint = rgb(160, 158, 152),
        OnAccent = rgb(252, 251, 248), Shadow = rgb(140, 136, 128),
        Accent = rgb(74, 84, 168), AccentSecondary = rgb(108, 112, 130),
        Iris = rgb(74, 84, 168), Clay = rgb(176, 92, 78), Sand = rgb(170, 130, 66),
        Sage = rgb(80, 132, 104), Mauve = rgb(122, 92, 160), Steel = rgb(96, 106, 120),
        Sky = rgb(66, 118, 156), Rose = rgb(158, 92, 128),
        Success = rgb(58, 138, 92), Warning = rgb(168, 124, 44), Danger = rgb(178, 70, 66),
        radius = { window = 18, panel = 12, card = 10, control = 8, chip = 6, pill = 999 },
    },
    Sakura = {
        label = "Sakura · warm rose",
        BgApp = rgb(238, 226, 228), BgSurface = rgb(252, 244, 245), BgElevated = rgb(255, 250, 250),
        BgRaised = rgb(250, 240, 242), BgInset = rgb(243, 231, 234), BgHover = rgb(248, 236, 238),
        BgSidebar = rgb(247, 236, 238),
        Hairline = rgb(214, 186, 192), Stroke = rgb(228, 204, 209), StrokeSoft = rgb(238, 218, 222),
        TextPrimary = rgb(48, 34, 38), TextSecondary = rgb(112, 84, 92),
        TextMuted = rgb(140, 110, 118), TextFaint = rgb(176, 148, 154),
        OnAccent = rgb(255, 250, 250), Shadow = rgb(150, 122, 128),
        Accent = rgb(168, 82, 112), AccentSecondary = rgb(150, 118, 128),
        Iris = rgb(168, 82, 112), Clay = rgb(188, 96, 96), Sand = rgb(186, 140, 96),
        Sage = rgb(96, 138, 110), Mauve = rgb(148, 96, 156), Steel = rgb(130, 112, 124),
        Sky = rgb(96, 128, 158), Rose = rgb(188, 92, 128),
        Success = rgb(72, 138, 100), Warning = rgb(172, 124, 60), Danger = rgb(184, 72, 84),
        radius = { window = 22, panel = 16, card = 14, control = 12, chip = 10, pill = 999 },
    },
    Forest = {
        label = "Forest · moss dark",
        BgApp = rgb(7, 12, 9), BgSurface = rgb(13, 20, 16), BgElevated = rgb(18, 27, 21),
        BgRaised = rgb(24, 35, 28), BgInset = rgb(9, 15, 12), BgHover = rgb(29, 42, 33),
        BgSidebar = rgb(10, 16, 13),
        Hairline = rgb(48, 74, 58), Stroke = rgb(36, 55, 44), StrokeSoft = rgb(26, 40, 32),
        TextPrimary = rgb(232, 242, 234), TextSecondary = rgb(148, 172, 154),
        TextMuted = rgb(108, 130, 114), TextFaint = rgb(76, 94, 80),
        OnAccent = rgb(8, 12, 9), Shadow = rgb(2, 5, 3),
        Accent = rgb(122, 196, 138), AccentSecondary = rgb(148, 170, 152),
        Iris = rgb(122, 196, 138), Clay = rgb(196, 142, 104), Sand = rgb(206, 186, 118),
        Sage = rgb(122, 196, 138), Mauve = rgb(170, 160, 196), Steel = rgb(138, 156, 142),
        Sky = rgb(118, 166, 168), Rose = rgb(190, 148, 156),
        Success = rgb(122, 196, 138), Warning = rgb(210, 184, 112), Danger = rgb(208, 108, 104),
        radius = { window = 12, panel = 10, card = 8, control = 6, chip = 6, pill = 999 },
    },
}

local THEME_ORDER = { "Porcelain", "Midnight", "Obsidian", "Ivory", "Sakura", "Forest" }

local Theme = {}
local RADIUS = {}
local function applyTheme(name)
    local palette = THEMES[name] or THEMES.Porcelain
    for key, value in pairs(palette) do
        if key ~= "label" and key ~= "radius" then Theme[key] = value end
    end
    for key, value in pairs(palette.radius) do RADIUS[key] = value end
    return name
end
applyTheme(Config.Theme)

local FONT = { UI = Enum.Font.GothamMedium, Bold = Enum.Font.GothamBold, Mono = Enum.Font.Code }

-- Instances are built by the thousand when the window opens, and one closure
-- plus one pcall per *property* was the most expensive thing this file did.
-- Now the whole styling pass runs inside a single pcall; only if a property is
-- actually refused do we fall back to the old per-property retry, so a client
-- that dislikes one key still gets every other one applied.
local function new(class, props, parent)
    local inst = Instance.new(class)
    local ok = pcall(function()
        if props then
            for key, value in pairs(props) do
                inst[key] = value
            end
        end
        if parent ~= nil then inst.Parent = parent end
    end)
    if not ok then
        if props then
            for key, value in pairs(props) do
                pcall(function() inst[key] = value end)
            end
        end
        if parent ~= nil then pcall(function() inst.Parent = parent end) end
    end
    return inst
end

local function corner(parent, radius)
    radius = radius or RADIUS.card
    -- on a bar that is two or three pixels wide a 2 px radius is not something
    -- the eye can see, and the glyphs are made of hundreds of such bars — each
    -- one used to drag a UICorner instance along with it
    if radius <= 2 and parent ~= nil then return nil end
    local c = Instance.new("UICorner")
    pcall(function()
        c.CornerRadius = UDim.new(0, radius)
        if parent ~= nil then c.Parent = parent end
    end)
    return c
end

local function hairline(parent, color, thickness, transparency, radius)
    local s = Instance.new("UIStroke")
    pcall(function()
        s.Color = color or Theme.Stroke
        s.Thickness = thickness or 1
        s.Transparency = transparency or 0.35
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        if radius then s.UICorner = radius end
        if parent ~= nil then s.Parent = parent end
    end)
    return s
end

local function tint(color, amount)
    return color:Lerp(Theme.BgElevated, amount or 0.86)
end

local function SafeTween(inst, info, goal)
    local ok, tween = pcall(function() return TweenService:Create(inst, info, goal) end)
    if ok and tween then return tween end
    return { Play = function() end, Cancel = function() end }
end

local function Text(props, parent)
    props.BackgroundTransparency = 1
    props.BorderSizePixel = 0
    props.Font = props.Font or FONT.UI
    return new("TextLabel", props, parent)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 3 · ICONS — drawn from geometry, same primitive as the Blox Fruits build
--     put(px, py, w, h, rotation, radius, fill, stroke, alpha)
--       fill   = override colour (Theme.BgApp cuts a hole in the shape)
--       stroke = draw an OUTLINE instead of a fill (that is what makes the set
--                read like icons instead of coloured bars)
--       alpha  = fade a secondary part
-- ═══════════════════════════════════════════════════════════════════════════
local function drawVectorGlyph(holder, kind, color, size, zBase, out)
    out = out or {}

    local function put(px, py, w, h, rotation, radius, fill, stroke, alpha)
        local strokePx = stroke and math.max(math.floor(stroke * size), 1) or 0
        local transparency = alpha or 0
        local part = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = fill or color,
            BackgroundTransparency = strokePx > 0 and 1 or transparency,
            BorderSizePixel = 0,
            Position = UDim2.new(px, 0, py, 0),
            Size = UDim2.new(0, math.max(math.floor(w * size), 1), 0, math.max(math.floor(h * size), 1)),
            Rotation = rotation or 0,
            ZIndex = zBase,
        }, holder)
        if radius == -1 then
            corner(part, math.max(math.floor(size / 2), 2))
        else
            local px = math.max(math.floor(radius or 2), 1)
            if px > 1 then corner(part, px) end
        end
        if strokePx > 0 then
            table.insert(out, new("UIStroke", {
                Color = fill or color,
                Thickness = strokePx,
                Transparency = transparency,
            }, part))
        end
        table.insert(out, part)
        return part
    end

    if kind == "swords" then
        put(0.5, 0.5, 0.085, 0.84, 45, 3)
        put(0.5, 0.5, 0.085, 0.84, -45, 3)
        put(0.76, 0.24, 0.24, 0.07, 45, 3, nil, nil, 0.35)
        put(0.24, 0.24, 0.24, 0.07, -45, 3, nil, nil, 0.35)
        put(0.79, 0.79, 0.26, 0.075, 45, 3)
        put(0.21, 0.79, 0.26, 0.075, -45, 3)
        put(0.88, 0.88, 0.15, 0.15, 0, -1)
        put(0.12, 0.88, 0.15, 0.15, 0, -1)
    elseif kind == "katana" then
        put(0.5, 0.5, 0.075, 0.86, 52, 3)
        put(0.5, 0.5, 0.075, 0.30, -128, 3, nil, nil, 0.45)
        put(0.30, 0.74, 0.30, 0.07, -38, 3)
        put(0.18, 0.86, 0.14, 0.14, 0, -1, nil, nil, 0.5)
    elseif kind == "skull" then
        put(0.5, 0.40, 0.78, 0.68, 0, math.floor(size * 0.33))
        put(0.33, 0.38, 0.21, 0.21, 0, -1, Theme.BgApp)
        put(0.67, 0.38, 0.21, 0.21, 0, -1, Theme.BgApp)
        put(0.5, 0.62, 0.17, 0.14, 0, 2, Theme.BgApp)
        put(0.5, 0.84, 0.44, 0.19, 0, 4)
        put(0.5, 0.84, 0.08, 0.19, 0, 2, Theme.BgApp)
        put(0.36, 0.84, 0.05, 0.19, 0, 2, Theme.BgApp)
        put(0.64, 0.84, 0.05, 0.19, 0, 2, Theme.BgApp)
    elseif kind == "chart" then
        put(0.5, 0.91, 0.9, 0.06, 0, 3, nil, nil, 0.5)
        put(0.2, 0.64, 0.15, 0.44, 0, 4)
        put(0.5, 0.56, 0.15, 0.6, 0, 4)
        put(0.8, 0.7, 0.15, 0.32, 0, 4)
    elseif kind == "scroll" then
        put(0.5, 0.5, 0.62, 0.78, 0, 5, nil, 0.08)
        put(0.5, 0.34, 0.34, 0.055, 0, 3)
        put(0.5, 0.5, 0.34, 0.055, 0, 3)
        put(0.5, 0.66, 0.22, 0.055, 0, 3, nil, nil, 0.5)
    elseif kind == "flame" then
        put(0.5, 0.58, 0.6, 0.72, 0, -1)
        put(0.5, 0.30, 0.28, 0.44, 18, -1, nil, nil, 0.25)
        put(0.5, 0.44, 0.30, 0.34, 0, -1, Theme.BgApp, nil, 0.15)
        put(0.5, 0.80, 0.34, 0.16, 0, -1, nil, nil, 0.35)
    elseif kind == "drop" then
        put(0.5, 0.60, 0.62, 0.62, 0, -1)
        put(0.5, 0.26, 0.34, 0.34, 45, 4)
        put(0.38, 0.62, 0.12, 0.12, 0, -1, nil, nil, 0.45)
    elseif kind == "wind" then
        put(0.44, 0.30, 0.66, 0.075, 0, 3)
        put(0.5, 0.5, 0.8, 0.075, 0, 3)
        put(0.38, 0.70, 0.54, 0.075, 0, 3)
        put(0.80, 0.40, 0.14, 0.14, 0, -1, nil, nil, 0.45)
    elseif kind == "bolt" then
        put(0.44, 0.27, 0.115, 0.46, 18, 3)
        put(0.5, 0.5, 0.36, 0.115, 0, 3)
        put(0.56, 0.73, 0.115, 0.46, 18, 3)
        put(0.40, 0.13, 0.10, 0.10, 45, 3)
        put(0.60, 0.87, 0.10, 0.10, 45, 3)
    elseif kind == "bell" then
        put(0.5, 0.52, 0.72, 0.66, 0, 6)
        put(0.5, 0.90, 0.20, 0.14, 0, -1)
        put(0.5, 0.16, 0.12, 0.12, 0, -1, nil, nil, 0.4)
    elseif kind == "eye" then
        put(0.5, 0.5, 0.92, 0.56, 0, math.floor(size * 0.3), nil, 0.1)
        put(0.5, 0.5, 0.26, 0.26, 0, -1)
        put(0.56, 0.44, 0.07, 0.07, 0, -1, nil, nil, 0.35)
    elseif kind == "compass" then
        put(0.5, 0.5, 0.94, 0.94, 0, -1, nil, 0.09)
        put(0.5, 0.33, 0.1, 0.34, 0, 3)
        put(0.5, 0.67, 0.1, 0.34, 0, 3, nil, nil, 0.5)
        put(0.5, 0.5, 0.13, 0.13, 0, -1)
    elseif kind == "gear" then
        put(0.94, 0.5, 0.18, 0.18, 0, 3)
        put(0.72, 0.12, 0.18, 0.18, 60, 3)
        put(0.28, 0.12, 0.18, 0.18, 120, 3)
        put(0.06, 0.5, 0.18, 0.18, 0, 3)
        put(0.28, 0.88, 0.18, 0.18, 60, 3)
        put(0.72, 0.88, 0.18, 0.18, 120, 3)
        put(0.5, 0.5, 0.56, 0.56, 0, -1, nil, 0.1)
        put(0.5, 0.5, 0.17, 0.17, 0, -1)
    elseif kind == "shield" then
        put(0.5, 0.48, 0.76, 0.86, 0, math.floor(size * 0.26), nil, 0.1)
        put(0.5, 0.45, 0.28, 0.1, 0, 3)
        put(0.5, 0.53, 0.1, 0.4, 0, 3)
    elseif kind == "play" then
        put(0.31, 0.5, 0.11, 0.62, 0, 3)
        put(0.55, 0.35, 0.11, 0.55, 57, 3)
        put(0.55, 0.65, 0.11, 0.55, 123, 3)
    elseif kind == "stop" then
        put(0.5, 0.5, 0.48, 0.48, 0, 5)
    elseif kind == "loop" then
        put(0.5, 0.52, 0.8, 0.8, 0, -1, nil, 0.1)
        put(0.5, 0.13, 0.19, 0.19, 45, 3)
        put(0.5, 0.13, 0.34, 0.1, 0, 3, nil, nil, 0.5)
    elseif kind == "layers" then
        put(0.5, 0.24, 0.6, 0.14, 0, 4, nil, nil, 0.45)
        put(0.5, 0.5, 0.84, 0.15, 0, 4)
        put(0.5, 0.76, 0.6, 0.14, 0, 4, nil, nil, 0.45)
    elseif kind == "search" then
        put(0.42, 0.42, 0.58, 0.58, 0, -1, nil, 0.11)
        put(0.73, 0.73, 0.11, 0.32, -45, 4)
    elseif kind == "magnet" then
        put(0.5, 0.30, 0.66, 0.38, 0, -1)
        put(0.26, 0.45, 0.17, 0.56, 0, 3)
        put(0.74, 0.45, 0.17, 0.56, 0, 3)
        put(0.26, 0.79, 0.19, 0.15, 0, 3, nil, nil, 0.45)
        put(0.74, 0.79, 0.19, 0.15, 0, 3, nil, nil, 0.45)
    elseif kind == "loot" then
        put(0.5, 0.62, 0.78, 0.5, 0, 4)
        put(0.5, 0.34, 0.6, 0.18, 0, -1)
        put(0.5, 0.52, 0.16, 0.24, 0, 3, Theme.BgApp)
    elseif kind == "chest" then
        put(0.5, 0.62, 0.8, 0.46, 0, 4)
        put(0.5, 0.36, 0.8, 0.2, 0, -1, nil, nil, 0.45)
        put(0.5, 0.5, 0.16, 0.26, 0, 3, Theme.BgApp)
    elseif kind == "fish" then
        put(0.42, 0.52, 0.66, 0.5, 0, -1)
        put(0.80, 0.52, 0.26, 0.4, 0, 3)
        put(0.30, 0.42, 0.10, 0.10, 0, -1, Theme.BgApp)
    elseif kind == "star" then
        put(0.5, 0.5, 0.44, 0.9, 0, 4)
        put(0.5, 0.5, 0.44, 0.9, 60, 4)
        put(0.5, 0.5, 0.44, 0.9, 120, 4)
        put(0.5, 0.5, 0.22, 0.22, 0, -1, Theme.BgApp)
    elseif kind == "user" then
        put(0.5, 0.34, 0.34, 0.34, 0, -1)
        put(0.5, 0.74, 0.62, 0.36, 0, -1)
    elseif kind == "ghost" then
        put(0.5, 0.48, 0.68, 0.62, 0, -1)
        put(0.34, 0.44, 0.14, 0.14, 0, -1, Theme.BgApp)
        put(0.66, 0.44, 0.14, 0.14, 0, -1, Theme.BgApp)
        put(0.5, 0.86, 0.7, 0.16, 0, 3, nil, nil, 0.4)
    elseif kind == "fist" then
        put(0.5, 0.56, 0.68, 0.56, 0, 4)
        put(0.5, 0.2, 0.42, 0.22, 0, 3, nil, nil, 0.25)
        put(0.32, 0.34, 0.16, 0.22, 0, 3)
        put(0.5, 0.34, 0.16, 0.22, 0, 3)
        put(0.68, 0.34, 0.16, 0.22, 0, 3)
        put(0.5, 0.66, 0.52, 0.08, 0, -1, Theme.BgApp)
        put(0.5, 0.86, 0.3, 0.2, 0, 3, nil, nil, 0.3)
    elseif kind == "spark" then
        put(0.5, 0.5, 1.0, 0.16, 0, 3)
        put(0.5, 0.5, 0.16, 1.0, 0, 3)
        put(0.5, 0.5, 0.62, 0.12, 45, 3, nil, nil, 0.35)
        put(0.5, 0.5, 0.12, 0.62, 45, 3, nil, nil, 0.35)
        put(0.5, 0.5, 0.3, 0.3, 0, 2)
        put(0.5, 0.5, 0.12, 0.12, 0, -1, Theme.BgApp)
    elseif kind == "hex" then
        put(0.5, 0.5, 0.86, 0.86, 45, 5, nil, 0.12)
        put(0.5, 0.5, 0.5, 0.5, 45, 4, Theme.BgApp)
        put(0.5, 0.5, 0.3, 0.3, 0, -1)
        put(0.5, 0.5, 0.14, 0.14, 0, -1, Theme.BgApp)
    elseif kind == "warning" then
        put(0.5, 0.5, 0.86, 0.86, 45, 5)
        put(0.5, 0.44, 0.1, 0.42, 0, 2, Theme.BgApp)
        put(0.5, 0.78, 0.12, 0.12, 0, -1, Theme.BgApp)
    elseif kind == "crown" then
        put(0.16, 0.62, 0.2, 0.44, 0, 3)
        put(0.5, 0.54, 0.2, 0.6, 0, 3)
        put(0.84, 0.62, 0.2, 0.44, 0, 3)
        put(0.34, 0.42, 0.18, 0.24, 0, 3, nil, nil, 0.3)
        put(0.66, 0.42, 0.18, 0.24, 0, 3, nil, nil, 0.3)
        put(0.5, 0.84, 0.74, 0.18, 0, 3)
    elseif kind == "fruit" then
        put(0.5, 0.62, 0.66, 0.66, 0, -1)
        put(0.63, 0.33, 0.10, 0.20, 24, 3)
        put(0.74, 0.26, 0.28, 0.12, -22, 3)
        put(0.36, 0.52, 0.11, 0.16, 0, -1, nil, nil, 0.45)
    elseif kind == "coin" then
        put(0.5, 0.5, 0.84, 0.84, 0, -1, nil, 0.11)
        put(0.5, 0.5, 0.58, 0.58, 0, -1, nil, 0.05)
        put(0.5, 0.5, 0.18, 0.34, 0, 3)
    elseif kind == "paw" then
        put(0.5, 0.62, 0.52, 0.42, 0, -1)
        put(0.28, 0.34, 0.18, 0.22, -18, -1)
        put(0.5, 0.28, 0.18, 0.22, 0, -1)
        put(0.72, 0.34, 0.18, 0.22, 18, -1)
        put(0.82, 0.52, 0.15, 0.18, 32, -1, nil, nil, 0.6)
    elseif kind == "bag" then
        put(0.5, 0.62, 0.74, 0.54, 0, 5)
        put(0.5, 0.31, 0.34, 0.22, 0, -1, nil, 0.06)
        put(0.5, 0.64, 0.06, 0.24, 0, 2, Theme.BgApp)
    elseif kind == "save" then
        put(0.5, 0.5, 0.78, 0.78, 0, 4)
        put(0.5, 0.32, 0.42, 0.2, 0, 2, Theme.BgApp)
        put(0.5, 0.68, 0.5, 0.3, 0, 2, Theme.BgApp)
        put(0.5, 0.66, 0.08, 0.16, 0, 2, nil, nil, 0.4)
    elseif kind == "palette" then
        put(0.5, 0.5, 0.84, 0.84, 0, -1, nil, 0.1)
        put(0.34, 0.38, 0.15, 0.15, 0, -1)
        put(0.62, 0.34, 0.13, 0.13, 0, -1, nil, nil, 0.55)
        put(0.52, 0.62, 0.13, 0.13, 0, -1, nil, nil, 0.35)
        put(0.73, 0.6, 0.11, 0.11, 0, -1, nil, nil, 0.7)
    elseif kind == "sun" then
        put(0.5, 0.5, 0.36, 0.36, 0, -1)
        for index = 0, 7 do
            local angle = index * 22.5
            put(0.5, 0.5, 0.07, 0.86, -angle, 2, nil, nil, 0.35)
        end
        put(0.5, 0.5, 0.62, 0.62, 0, -1, Theme.BgApp)
        put(0.5, 0.5, 0.46, 0.46, 0, -1)
    elseif kind == "moon" then
        put(0.5, 0.5, 0.78, 0.78, 0, -1)
        put(0.32, 0.38, 0.62, 0.62, 0, -1, Theme.BgApp)
        put(0.74, 0.72, 0.09, 0.09, 0, -1, nil, nil, 0.5)
    elseif kind == "reset" then
        put(0.5, 0.54, 0.72, 0.72, 0, -1, nil, 0.1)
        put(0.5, 0.16, 0.30, 0.13, 0, 3, Theme.BgApp)
        put(0.5, 0.19, 0.2, 0.2, 45, 3)
        put(0.5, 0.54, 0.18, 0.18, 0, -1, nil, nil, 0.45)
    elseif kind == "folder" then
        put(0.5, 0.62, 0.82, 0.5, 0, 4)
        put(0.34, 0.34, 0.34, 0.18, 0, 3)
        put(0.5, 0.82, 0.5, 0.12, 0, 2, nil, nil, 0.4)
    elseif kind == "book" then
        put(0.5, 0.52, 0.68, 0.78, 0, 4)
        put(0.5, 0.52, 0.07, 0.72, 0, 2, Theme.BgApp)
        put(0.34, 0.4, 0.2, 0.06, 0, 2, nil, nil, 0.5)
        put(0.66, 0.4, 0.2, 0.06, 0, 2, nil, nil, 0.5)
    elseif kind == "scale" then
        put(0.5, 0.54, 0.74, 0.5, 0, 3, nil, 0.08)
        for index = 1, 4 do
            put(0.26 + index * 0.12, 0.54, 0.045, 0.3, 0, 1)
        end
        put(0.5, 0.76, 0.5, 0.1, 0, 2, nil, nil, 0.5)
    elseif kind == "aura" then
        put(0.5, 0.5, 0.9, 0.9, 0, -1, nil, 0.06)
        put(0.5, 0.5, 0.58, 0.58, 0, -1, nil, 0.06)
        put(0.5, 0.5, 0.2, 0.2, 0, -1)
    elseif kind == "hitbox" then
        put(0.5, 0.5, 0.8, 0.8, 0, 4, nil, 0.07)
        put(0.5, 0.5, 0.06, 0.66, 0, 1, nil, nil, 0.5)
        put(0.5, 0.5, 0.66, 0.06, 0, 1, nil, nil, 0.5)
        put(0.5, 0.5, 0.2, 0.2, 0, -1)
    elseif kind == "speed" then
        put(0.34, 0.5, 0.1, 0.66, 32, 3)
        put(0.56, 0.5, 0.1, 0.66, 32, 3)
        put(0.78, 0.5, 0.1, 0.66, 32, 3, nil, nil, 0.45)
    elseif kind == "copy" then
        put(0.42, 0.42, 0.6, 0.6, 0, 4, nil, 0.09)
        put(0.58, 0.58, 0.6, 0.6, 0, 4)
        put(0.58, 0.58, 0.46, 0.46, 0, 3, Theme.BgApp)
    elseif kind == "arrow" then
        put(0.42, 0.5, 0.6, 0.1, 0, 3)
        put(0.76, 0.5, 0.1, 0.42, 45, 3)
        put(0.76, 0.5, 0.1, 0.42, -45, 3)
    elseif kind == "crest" then
        put(0.5, 0.5, 0.9, 0.9, 45, 6, nil, 0.1)
        put(0.5, 0.5, 0.26, 0.26, 45, 4)
    else
        put(0.5, 0.5, 0.26, 0.26, 0, -1)
    end
    return holder
end

local ICON = {
    Crest    = "crest",
    Farm     = "swords",
    Sword    = "katana",
    Swords   = "swords",
    Katana   = "katana",
    Skull    = "skull",
    Chart    = "chart",
    Quest    = "scroll",
    Scroll   = "scroll",
    Flame    = "flame",
    Water    = "drop",
    Wind     = "wind",
    Bolt     = "bolt",
    Bell     = "bell",
    Eye      = "eye",
    Teleport = "compass",
    Settings = "gear",
    Gear     = "gear",
    Guard    = "shield",
    Play     = "play",
    Stop     = "stop",
    Loop     = "loop",
    Layers   = "layers",
    Search   = "search",
    Magnet   = "magnet",
    Loot     = "loot",
    Chest    = "chest",
    Fish     = "fish",
    Star     = "star",
    Player   = "user",
    Ghost    = "ghost",
    -- Jujutsu Shenanigans additions
    Fist     = "fist",
    Spark    = "spark",
    Hex      = "hex",
    Warning  = "warning",
    Crown    = "crown",
    -- Free Blox Fruit additions
    Fruit    = "fruit",
    Coin     = "coin",
    Mob      = "paw",
    Bag      = "bag",
    Save     = "save",
    Palette  = "palette",
    Sun      = "sun",
    Moon     = "moon",
    Reset    = "reset",
    Folder   = "folder",
    Book     = "book",
    Scale    = "scale",
    Aura     = "aura",
    Hitbox   = "hitbox",
    Speed    = "speed",
    Arrow    = "arrow",
    Copy     = "copy",
}

local function iconTile(parent, kind, accent, sizePx, position, zIndex, out)
    local holder = new("Frame", {
        BackgroundColor3 = tint(accent, 0.86),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = position,
        Size = UDim2.new(0, sizePx, 0, sizePx),
        ZIndex = zIndex or 5,
    }, parent)
    corner(holder, math.floor(sizePx * 0.3))
    hairline(holder, tint(accent, 0.5), 1, 0.5)
    drawVectorGlyph(holder, kind, accent, sizePx * 0.54, (zIndex or 5) + 1, out)
    return holder
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 4 · TOASTS  (top-right stack, draining progress hairline)
-- ═══════════════════════════════════════════════════════════════════════════
local Window, Body, Rail, PageHolder, Toast, ActiveTab
local TOAST = { order = 0, holder = nil }
local Tabs = {}
local ToggleRegistry = {}


local function notify(title, message, duration, accent, iconKind)
    if not TOAST.holder then return end
    duration = duration or 4
    accent = accent or Theme.Accent

    local card = new("Frame", {
        BackgroundColor3 = Theme.BgElevated,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -312, 0, 16),
        Size = UDim2.new(0, 296, 0, message and 62 or 44),
        ZIndex = 60,
    }, TOAST.holder)
    corner(card, RADIUS.card)
    hairline(card, Theme.Stroke, 1, 0.3)

    local bar = new("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 14),
        Size = UDim2.new(0, 3, 0, 18),
        ZIndex = 61,
    }, card)
    corner(bar, RADIUS.pill)

    iconTile(card, iconKind or "crest", accent, 24, UDim2.new(0, 22, 0, 11), 61)

    Text({
        Font = FONT.Bold, Position = UDim2.new(0, 54, 0, 11), Size = UDim2.new(1, -66, 0, 14),
        Text = tostring(title), TextColor3 = Theme.TextPrimary, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 61,
    }, card)
    if message then
        Text({
            Position = UDim2.new(0, 54, 0, 27), Size = UDim2.new(1, -66, 0, 26),
            Text = tostring(message), TextColor3 = Theme.TextMuted, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 61,
        }, card)
    end

    local drain = new("Frame", {
        BackgroundColor3 = accent, BackgroundTransparency = 0.45, BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 1, -2), Size = UDim2.new(1, -2, 0, 2), ZIndex = 61,
    }, card)
    corner(drain, 1)

    TOAST.order = TOAST.order + 1
    card.LayoutOrder = TOAST.order

    task.spawn(function()
        safeCall("toast drain", function()
            local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
            SafeTween(drain, info, { Size = UDim2.new(0, 0, 0, 2) }):Play()
        end)
        task.wait(duration)
        safeCall("toast remove", function()
            local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad)
            local hover = SafeTween(card, info, { BackgroundTransparency = 1 })
            hover:Play()
            task.wait(0.2)
            card:Destroy()
        end)
    end)
    return card
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 4b · CONTROL HEALTH — every card reports in, every callback is guarded
--      A callback used to die in its own thread: the switch stayed ON, the
--      toast said "executed", and nothing happened. Now a throw is counted,
--      logged, shown as a toast, and the build fails if any control in any
--      tab cannot be used.
-- ═══════════════════════════════════════════════════════════════════════════
local ControlRegistry = {}

local CONTROLS = { faults = 0, last = nil }
function CONTROLS.register(kind, title, tab, api)
    ControlRegistry[#ControlRegistry + 1] = {
        kind = kind, title = title, tab = tab and tab.title or "?", api = api,
    }
    return api
end
function CONTROLS.run(label, fn, ...)
    if not fn then return true end
    local ok, err = pcall(fn, ...)
    if ok then return true end
    CONTROLS.faults = CONTROLS.faults + 1
    CONTROLS.last = tostring(label) .. " · " .. tostring(err)
    local log = SharedEnv.__SkillHubErrorLog
    if log and #log < 40 then table.insert(log, CONTROLS.last) end
    pcall(notify, "Control failed", tostring(label), 4, Theme.Danger, "shield")
    return false
end
function CONTROLS.spawnWith(label, fn, onFail, ...)
    if not fn then return end
    local packed = table.pack(...)
    task.spawn(function()
        local ok = CONTROLS.run(label, fn, table.unpack(packed, 1, packed.n))
        if not ok and onFail then pcall(onFail) end
    end)
end
function CONTROLS.spawn(label, fn, ...)
    CONTROLS.spawnWith(label, fn, nil, ...)
end
-- live panels repaint every half second: one bad frame must not end the
-- painter, and it must not spam a toast either — it is counted and logged once
function CONTROLS.tick(label, body)
    local ok, err = pcall(body)
    if ok then return true end
    CONTROLS.faults = CONTROLS.faults + 1
    CONTROLS.last = tostring(label) .. " · " .. tostring(err)
    local log = SharedEnv.__SkillHubErrorLog
    if log and #log < 40 then table.insert(log, CONTROLS.last) end
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 5 · WINDOW FRAMEWORK  (chrome + rail + components)
-- ═══════════════════════════════════════════════════════════════════════════

-- the window table is created by buildWindow(); this accessor is how the tab
-- layer (which runs in its own closure) reads it live
local function getWindow()
    return Window
end

local function guiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if get_hidden_gui then
        local ok, hid = pcall(get_hidden_gui)
        if ok and hid then return hid end
    end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")
end

local function buildWindow()
    local parent = guiParent()
    if not parent then return nil end

    local screen = new("ScreenGui", {
        Name = "SkillHubFreeBloxFruit",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, parent)
    if protect_gui then pcall(protect_gui, screen) end
    -- one UIScale on the ScreenGui scales the entire window (text, icons,
    -- hit areas) without touching a single offset in the layout code
    new("UIScale", { Scale = clamp(tonumber(Config.UiScale) or 1, 0.75, 1.3) }, screen)

    Toast = new("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(0, 320, 1, 0),
        Position = UDim2.new(1, -336, 0, 0), ZIndex = 59,
    }, screen)
    new("UIListLayout", {
        Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder,
    }, Toast)
    TOAST.holder = Toast

    local shadow = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Shadow, BackgroundTransparency = 0.45,
        BorderSizePixel = 0, Position = UDim2.new(0.5, 6, 0.5, 8),
        Size = UDim2.new(0, 748, 0, 486), ZIndex = 1,
    }, screen)
    corner(shadow, RADIUS.window + 4)

    local root = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.BgSurface, BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 748, 0, 486), ZIndex = 2,
    }, screen)
    corner(root, RADIUS.window)
    local rootStroke = hairline(root, Theme.Hairline, 1, 0.55)

    Window = { Screen = screen, Root = root, Shadow = shadow, Stroke = rootStroke, Minimized = false }

    -- where the player dragged the window last time (0, 0 = centred)
    local savedX = tonumber(Config.UiX) or 0
    local savedY = tonumber(Config.UiY) or 0
    if savedX ~= 0 or savedY ~= 0 then
        root.Position = UDim2.new(0.5, savedX, 0.5, savedY)
        shadow.Position = UDim2.new(root.Position.X.Scale, root.Position.X.Offset + 6,
            root.Position.Y.Scale, root.Position.Y.Offset + 8)
    end

    -- topbar
    local topbar = new("Frame", {
        BackgroundColor3 = Theme.BgElevated, BackgroundTransparency = 0.35, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 48), ZIndex = 3,
    }, root)
    corner(topbar, RADIUS.window)
    new("Frame", {
        BackgroundColor3 = Theme.BgSurface, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -14), Size = UDim2.new(1, 0, 0, 14), ZIndex = 3,
    }, topbar)
    new("Frame", {
        BackgroundColor3 = Theme.StrokeSoft, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), ZIndex = 4,
    }, topbar)

    iconTile(topbar, ICON.Crest, Theme.Accent, 30, UDim2.new(0, 16, 0, 9), 5)
    Text({
        Font = FONT.Bold, Position = UDim2.new(0, 54, 0, 9), Size = UDim2.new(0, 260, 0, 16),
        Text = "Skill Hub", TextColor3 = Theme.TextPrimary, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
    }, topbar)
    Text({
        Position = UDim2.new(0, 54, 0, 25), Size = UDim2.new(0, 300, 0, 14),
        Text = META.game .. " · " .. META.version .. " · free edition", TextColor3 = Theme.TextMuted,
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
    }, topbar)

    local chips = {}
    local chipHolder = new("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -252, 0, 14),
        Size = UDim2.new(0, 172, 0, 20), ZIndex = 5,
    }, topbar)
    new("UIListLayout", {
        Padding = UDim.new(0, 6), FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center,
    }, chipHolder)
    local function makeChip(label)
        local chip = new("Frame", {
            BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
            Size = UDim2.new(0, 48, 0, 20), ZIndex = 5,
        }, chipHolder)
        corner(chip, RADIUS.chip)
        hairline(chip, Theme.StrokeSoft, 1, 0.4)
        local text = Text({
            Font = FONT.Mono, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0),
            Text = label .. " —", TextColor3 = Theme.TextSecondary, TextSize = 10, ZIndex = 6,
        }, chip)
        return chip, text
    end
    chips.state, chips.stateText = makeChip("STATE")
    chips.ac, chips.acText = makeChip("AC")
    chips.perf, chips.perfText = makeChip("PERF")

    local function ghostButton(text, x, callback)
        local button = new("TextButton", {
            AutoButtonColor = false, BackgroundColor3 = Theme.BgInset, BackgroundTransparency = 0.35,
            BorderSizePixel = 0, Position = UDim2.new(1, x, 0, 14), Size = UDim2.new(0, 22, 0, 20),
            Text = "", ZIndex = 6,
        }, topbar)
        corner(button, RADIUS.chip)
        Text({
            Font = FONT.Bold, Size = UDim2.new(1, 0, 1, 0), Text = text,
            TextColor3 = Theme.TextSecondary, TextSize = 13, ZIndex = 7,
        }, button)
        button.MouseEnter:Connect(function() button.BackgroundColor3 = Theme.BgHover end)
        button.MouseLeave:Connect(function() button.BackgroundColor3 = Theme.BgInset end)
        button.MouseButton1Click:Connect(callback)
        return button
    end

    ghostButton("—", -58, function()
        Window.Minimized = not Window.Minimized
        local goal = Window.Minimized and 48 or 486
        safeCall("minimize", function()
            SafeTween(root, TweenInfo.new(0.18, Enum.EasingStyle.Quart), { Size = UDim2.new(0, 748, 0, goal) }):Play()
            SafeTween(shadow, TweenInfo.new(0.18, Enum.EasingStyle.Quart), { Size = UDim2.new(0, 748, 0, goal + 8) }):Play()
        end)
        Body.Visible = not Window.Minimized
    end)
    ghostButton("×", -30, function()
        -- hiding, not disconnecting: the screen stays enabled so the hide key
        -- can bring the window back. Disabling the ScreenGui here left the
        -- player with a script that was running but impossible to reach.
        Config.UiVisible = false
        root.Visible = false
        Window.Screen.Enabled = true
    end)

    -- drag
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, root.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    -- the window is where the player left it next time
                    Config.UiX = root.Position.X.Offset
                    Config.UiY = root.Position.Y.Offset
                end
            end)
        end
    end)
    if UserInput then
        UserInput.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                shadow.Position = UDim2.new(0.5, 6, 0.5, 8)
                shadow.Position = UDim2.new(root.Position.X.Scale, root.Position.X.Offset + 6, root.Position.Y.Scale, root.Position.Y.Offset + 8)
            end
        end)
    end

    -- body: rail + content + status strip
    Body = new("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 48),
        Size = UDim2.new(1, 0, 1, -48), ZIndex = 3,
    }, root)

    Rail = new("Frame", {
        BackgroundColor3 = Theme.BgSidebar, BackgroundTransparency = 0.2, BorderSizePixel = 0,
        Size = UDim2.new(0, 196, 1, -26), ZIndex = 4,
    }, Body)
    corner(Rail, RADIUS.window)
    new("Frame", {
        BackgroundColor3 = Theme.BgSidebar, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -12), Size = UDim2.new(1, 0, 0, 12), ZIndex = 4,
    }, Rail)
    new("Frame", {
        BackgroundColor3 = Theme.StrokeSoft, BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 10), Size = UDim2.new(0, 1, 1, -20), ZIndex = 5,
    }, Rail)

    local searchShell = new("Frame", {
        BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 12), Size = UDim2.new(1, -24, 0, 30), ZIndex = 5,
    }, Rail)
    corner(searchShell, RADIUS.control)
    hairline(searchShell, Theme.StrokeSoft, 1, 0.4)
    iconTile(searchShell, ICON.Search, Theme.TextMuted, 16, UDim2.new(0, 7, 0.5, -8), 6)
    local searchBox = new("TextBox", {
        BackgroundTransparency = 1, Font = FONT.UI, PlaceholderText = "search options…",
        PlaceholderColor3 = Theme.TextFaint, Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(1, -38, 1, 0),
        Text = "", TextColor3 = Theme.TextPrimary, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 6,
    }, searchShell)

    local railList = new("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(1, 0, 1, -100), ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Stroke, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 5,
    }, Rail)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, railList)
    new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 4) }, railList)

    Text({
        Position = UDim2.new(0, 14, 1, -26), Size = UDim2.new(1, -28, 0, 12),
        Text = META.version .. " · free · no key", TextColor3 = Theme.TextFaint, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
    }, Rail)
    Text({
        Position = UDim2.new(0, 14, 1, -14), Size = UDim2.new(1, -28, 0, 12),
        Text = LocalPlayer and ("@" .. LocalPlayer.Name) or "@player", TextColor3 = Theme.TextFaint,
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
    }, Rail)

    local content = new("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 196, 0, 0),
        Size = UDim2.new(1, -196, 1, -26), ZIndex = 4,
    }, Body)

    local header = new("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), ZIndex = 5,
    }, content)
    local headerIcon = new("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 9),
        Size = UDim2.new(0, 28, 0, 28), ZIndex = 6,
    }, header)
    local headerTitle = Text({
        Font = FONT.Bold, Position = UDim2.new(0, 54, 0, 10), Size = UDim2.new(1, -70, 0, 16),
        Text = "Auto Farm", TextColor3 = Theme.TextPrimary, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
    }, header)
    local headerDesc = Text({
        Position = UDim2.new(0, 54, 0, 26), Size = UDim2.new(1, -70, 0, 14),
        Text = "", TextColor3 = Theme.TextMuted, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
    }, header)
    new("Frame", {
        BackgroundColor3 = Theme.StrokeSoft, BorderSizePixel = 0, Position = UDim2.new(0, 14, 1, 0),
        Size = UDim2.new(1, -28, 0, 1), ZIndex = 5,
    }, header)

    PageHolder = new("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 46),
        Size = UDim2.new(1, 0, 1, -46), ZIndex = 5,
    }, content)

    local strip = new("Frame", {
        BackgroundColor3 = Theme.BgElevated, BackgroundTransparency = 0.4, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -26), Size = UDim2.new(1, 0, 0, 26), ZIndex = 6,
    }, Body)
    corner(strip, RADIUS.window)
    Text({
        Position = UDim2.new(0, 14, 0, 7), Size = UDim2.new(0, 420, 0, 12),
        Text = Config.HideUiKey .. " — show / hide · " .. Config.PanicKey .. " — panic (turn everything off)", TextColor3 = Theme.TextFaint,
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, strip)
    local stripRight = Text({
        Font = FONT.Mono, Position = UDim2.new(1, -320, 0, 7), Size = UDim2.new(0, 306, 0, 12),
        Text = "", TextColor3 = Theme.TextMuted, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7,
    }, strip)

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(searchBox.Text or "")
        for _, tab in ipairs(Tabs) do
            local show = true
            if #query > 0 then
                local haystack = string.lower(tab.title .. " " .. (tab.desc or ""))
                for _, entry in ipairs(tab.searchIndex) do
                    haystack = haystack .. " " .. string.lower(entry)
                end
                show = string.find(haystack, query, 1, true) ~= nil
            end
            tab.button.Visible = show
        end
    end)

    iconTile(headerIcon, ICON.Crest, Theme.Accent, 28, UDim2.new(0, 0, 0, 0), 7)

    Window.HeaderIcon = headerIcon
    Window.HeaderTitle = headerTitle
    Window.HeaderDesc = headerDesc
    Window.Topbar = topbar
    Window.Chrome = { chips = chips, strip = stripRight, header = header }
    return screen
end

-- ── tabs and their components ───────────────────────────────────────────────

local function makeTab(title, desc, iconKind, accent)
    Window.tabOrder = (Window.tabOrder or 0) + 1
    accent = accent or Theme.Accent
    local railList = Rail:FindFirstChildOfClass("ScrollingFrame")

    local button = new("TextButton", {
        AutoButtonColor = false, BackgroundColor3 = Theme.BgElevated, BackgroundTransparency = 1,
        BorderSizePixel = 0, LayoutOrder = Window.tabOrder, Size = UDim2.new(1, 0, 0, 34),
        Text = "", ZIndex = 6,
    }, railList)
    corner(button, RADIUS.control)

    local pill = new("Frame", {
        BackgroundColor3 = accent, BorderSizePixel = 0, Position = UDim2.new(0, -6, 0.5, -8),
        Size = UDim2.new(0, 3, 0, 16), ZIndex = 7,
    }, button)
    corner(pill, RADIUS.pill)
    pill.Visible = false

    local tile = iconTile(button, iconKind, accent, 22, UDim2.new(0, 9, 0.5, -11), 7)
    local label = Text({
        Font = FONT.Bold, Position = UDim2.new(0, 40, 0, 0), Size = UDim2.new(1, -46, 1, 0),
        Text = title, TextColor3 = Theme.TextSecondary, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 7,
    }, button)

    local page = new("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Stroke,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false, ZIndex = 5,
    }, PageHolder)
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
        PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14),
    }, page)

    local tab = {
        title = title, desc = desc, color = accent, icon = iconKind,
        page = page, button = button, label = label, pill = pill, tile = tile,
        order = 0, searchIndex = {},
    }

    local function select()
        if ActiveTab == tab then return end
        for _, other in ipairs(Tabs) do
            other.page.Visible = false
            other.pill.Visible = false
            other.label.TextColor3 = Theme.TextSecondary
            SafeTween(other.button, TweenInfo.new(0.16), { BackgroundTransparency = 1 }):Play()
        end
        ActiveTab = tab
        tab.page.Visible = true
        tab.pill.Visible = true
        tab.label.TextColor3 = Theme.TextPrimary
        SafeTween(tab.button, TweenInfo.new(0.16), { BackgroundTransparency = 0.25 }):Play()
        Window.HeaderTitle.Text = tab.title
        Window.HeaderDesc.Text = tab.desc or ""
        safeCall("header icon", function()
            for _, child in ipairs(Window.HeaderIcon:GetChildren()) do child:Destroy() end
            iconTile(Window.HeaderIcon, tab.icon, tab.color, 28, UDim2.new(0, 0, 0, 0), 7)
        end)
        tab.button.BackgroundColor3 = tint(tab.color, 0.9)
    end

    button.MouseEnter:Connect(function()
        if ActiveTab ~= tab then SafeTween(button, TweenInfo.new(0.14), { BackgroundTransparency = 0.75 }):Play() end
    end)
    button.MouseLeave:Connect(function()
        if ActiveTab ~= tab then SafeTween(button, TweenInfo.new(0.14), { BackgroundTransparency = 1 }):Play() end
    end)
    button.MouseButton1Click:Connect(select)
    tab.Select = select

    -- ── components ──────────────────────────────────────────────────────────
    local function nextOrder()
        tab.order = tab.order + 1
        return tab.order
    end

    function tab:AddSection(text)
        local holder = new("Frame", {
            BackgroundTransparency = 1, LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 22),
        }, page)
        Text({
            Font = FONT.Bold, Position = UDim2.new(0, 2, 1, -14), Size = UDim2.new(1, -4, 0, 14),
            Text = string.upper(text), TextColor3 = Theme.TextFaint, TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
        }, holder)
        new("Frame", {
            BackgroundColor3 = Theme.StrokeSoft, BorderSizePixel = 0, Position = UDim2.new(0, 2, 1, 0),
            Size = UDim2.new(1, -4, 0, 1), ZIndex = 5,
        }, holder)
        table.insert(tab.searchIndex, text)
        return holder
    end

    function tab:AddToggle(title, desc, value, callback, iconKind)
        local card = new("Frame", {
            BackgroundColor3 = Theme.BgElevated, BorderSizePixel = 0,
            LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 58),
        }, page)
        corner(card, RADIUS.card)
        hairline(card, Theme.StrokeSoft, 1, 0.45)
        iconTile(card, iconKind or tab.icon, tab.color, 30, UDim2.new(0, 14, 0.5, -15), 6)

        Text({
            Font = FONT.Bold, Position = UDim2.new(0, 56, 0, 11), Size = UDim2.new(1, -170, 0, 16),
            Text = title, TextColor3 = Theme.TextPrimary, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
        }, card)
        Text({
            Position = UDim2.new(0, 56, 0, 29), Size = UDim2.new(1, -170, 0, 16),
            Text = desc or "", TextColor3 = Theme.TextMuted, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
        }, card)
        local stateLabel = Text({
            Font = FONT.Bold, Position = UDim2.new(1, -112, 0.5, -7), Size = UDim2.new(0, 30, 0, 14),
            Text = "OFF", TextColor3 = Theme.TextFaint, TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6,
        }, card)

        local track = new("Frame", {
            BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
            Position = UDim2.new(1, -68, 0.5, -12), Size = UDim2.new(0, 44, 0, 24), ZIndex = 6,
        }, card)
        corner(track, RADIUS.pill)
        local trackStroke = hairline(track, Theme.StrokeSoft, 1, 0.35)
        local knob = new("Frame", {
            BackgroundColor3 = Color3.fromRGB(238, 240, 244), BorderSizePixel = 0,
            Position = UDim2.new(0, 3, 0.5, -9), Size = UDim2.new(0, 18, 0, 18), ZIndex = 7,
        }, track)
        corner(knob, RADIUS.pill)

        local state = value and true or false
        local function render(animate)
            local info = TweenInfo.new(animate and 0.2 or 0, Enum.EasingStyle.Quart)
            SafeTween(track, info, { BackgroundColor3 = state and tint(tab.color, 0.52) or Theme.BgInset }):Play()
            SafeTween(trackStroke, info, { Color = state and tab.color or Theme.StrokeSoft, Transparency = state and 0.45 or 0.35 }):Play()
            SafeTween(knob, info, { Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) }):Play()
            stateLabel.Text = state and "ON" or "OFF"
            stateLabel.TextColor3 = state and tab.color or Theme.TextFaint
        end
        render(false)

        local function commit(target)
            state = target
            render(true)
            CONTROLS.spawnWith("toggle · " .. title, callback, function()
                -- a switch must never sit ON with a dead callback behind it:
                -- put it back, and run the off path so the config agrees
                state = not target
                render(true)
                CONTROLS.run("toggle · " .. title .. " (revert)", callback, not target)
            end, target)
        end
        local click = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", ZIndex = 8 }, card)
        click.MouseButton1Click:Connect(function()
            commit(not state)
        end)
        click.MouseEnter:Connect(function() SafeTween(card, TweenInfo.new(0.14), { BackgroundColor3 = Theme.BgRaised }):Play() end)
        click.MouseLeave:Connect(function() SafeTween(card, TweenInfo.new(0.14), { BackgroundColor3 = Theme.BgElevated }):Play() end)

        local api = {}
        api.Set = function(v, silent)
            local target = v and true or false
            if silent then
                state = target
                render(true)
            else
                commit(target)
            end
        end
        api.Get = function() return state end
        table.insert(tab.searchIndex, title)
        tab.toggles = tab.toggles or {}
        table.insert(tab.toggles, api)
        table.insert(ToggleRegistry, { title = title, tab = tab, set = api.Set, get = api.Get })
        CONTROLS.register("toggle", title, tab, { set = api.Set, get = api.Get })
        return api
    end

    function tab:AddSlider(title, desc, min, max, value, suffix, callback, iconKind)
        local card = new("Frame", {
            BackgroundColor3 = Theme.BgElevated, BorderSizePixel = 0,
            LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 70),
        }, page)
        corner(card, RADIUS.card)
        hairline(card, Theme.StrokeSoft, 1, 0.45)
        iconTile(card, iconKind or tab.icon, tab.color, 30, UDim2.new(0, 14, 0, 12), 6)
        Text({
            Font = FONT.Bold, Position = UDim2.new(0, 56, 0, 12), Size = UDim2.new(1, -170, 0, 16),
            Text = title, TextColor3 = Theme.TextPrimary, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
        }, card)
        Text({
            Position = UDim2.new(0, 56, 0, 29), Size = UDim2.new(1, -110, 0, 14),
            Text = desc or "", TextColor3 = Theme.TextMuted, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
        }, card)

        local pill = new("Frame", {
            BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
            Position = UDim2.new(1, -74, 0, 12), Size = UDim2.new(0, 60, 0, 22), ZIndex = 6,
        }, card)
        corner(pill, RADIUS.pill)
        hairline(pill, Theme.StrokeSoft, 1, 0.4)
        local pillText = Text({
            Font = FONT.Mono, Size = UDim2.new(1, 0, 1, 0),
            Text = tostring(round(value, 2)) .. (suffix or ""), TextColor3 = Theme.TextSecondary,
            TextSize = 10, ZIndex = 7,
        }, pill)

        local track = new("Frame", {
            BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
            Position = UDim2.new(0, 56, 0, 50), Size = UDim2.new(1, -126, 0, 4), ZIndex = 6,
        }, card)
        corner(track, RADIUS.pill)
        local fill = new("Frame", {
            BackgroundColor3 = tab.color, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), ZIndex = 7,
        }, track)
        corner(fill, RADIUS.pill)
        local knob = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(238, 240, 244),
            BorderSizePixel = 0, Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 12, 0, 12), ZIndex = 8,
        }, track)
        corner(knob, RADIUS.pill)

        local current = clamp(tonumber(value) or min, min, max)
        local function render()
            local alpha = (current - min) / math.max(max - min, 0.0001)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            knob.Position = UDim2.new(alpha, 0, 0.5, 0)
            pillText.Text = tostring(round(current, 2)) .. (suffix or "")
        end
        render()

        local dragging = false
        local function setFromX(x)
            local rel = clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            current = min + (max - min) * rel
            if max - min > 20 then current = math.floor(current + 0.5) else current = round(current, 2) end
            render()
            CONTROLS.run("slider · " .. title, callback, current)
        end
        local hit = new("TextButton", {
            BackgroundTransparency = 1, Position = UDim2.new(0, -8, 0, -18), Size = UDim2.new(1, 16, 0, 40),
            Text = "", ZIndex = 9,
        }, track)
        hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                setFromX(input.Position.X)
            end
        end)
        if UserInput then
            UserInput.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    setFromX(input.Position.X)
                end
            end)
            UserInput.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
        end
        table.insert(tab.searchIndex, title)
        local api = {
            Set = function(v)
                current = clamp(tonumber(v) or min, min, max)
                render()
                CONTROLS.run("slider · " .. title, callback, current)
            end,
            Get = function() return current end,
        }
        CONTROLS.register("slider", title, tab, { set = api.Set, get = api.Get })
        return api
    end

    function tab:AddButton(title, desc, callback, iconKind, danger)
        local card = new("Frame", {
            BackgroundColor3 = Theme.BgElevated, BorderSizePixel = 0,
            LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 58),
        }, page)
        corner(card, RADIUS.card)
        hairline(card, Theme.StrokeSoft, 1, 0.45)
        iconTile(card, iconKind or tab.icon, danger and Theme.Danger or tab.color, 30, UDim2.new(0, 14, 0.5, -15), 6)
        Text({
            Font = FONT.Bold, Position = UDim2.new(0, 56, 0, 11), Size = UDim2.new(1, -120, 0, 16),
            Text = title, TextColor3 = Theme.TextPrimary, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
        }, card)
        Text({
            Position = UDim2.new(0, 56, 0, 29), Size = UDim2.new(1, -120, 0, 16),
            Text = desc or "", TextColor3 = Theme.TextMuted, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
        }, card)

        local action = new("TextButton", {
            AutoButtonColor = false, BackgroundColor3 = danger and Color3.fromRGB(58, 33, 34) or tint(tab.color, 0.86),
            BorderSizePixel = 0, Font = FONT.Bold, Position = UDim2.new(1, -96, 0.5, -13),
            Size = UDim2.new(0, 82, 0, 26), Text = "RUN", TextColor3 = danger and Theme.Danger or tab.color,
            TextSize = 10, ZIndex = 7,
        }, card)
        corner(action, RADIUS.chip)
        action.MouseEnter:Connect(function() SafeTween(action, TweenInfo.new(0.14), { BackgroundTransparency = 0.2 }):Play() end)
        action.MouseLeave:Connect(function() SafeTween(action, TweenInfo.new(0.14), { BackgroundTransparency = 0 }):Play() end)
        action.MouseButton1Click:Connect(function()
            CONTROLS.spawn("button · " .. title, callback)
            notify(title, "executed", 2, danger and Theme.Danger or tab.color, iconKind or tab.icon)
        end)
        table.insert(tab.searchIndex, title)
        CONTROLS.register("button", title, tab, {
            press = function() CONTROLS.spawn("button · " .. title, callback) end,
        })
        return action
    end

    function tab:AddDropdown(title, desc, options, value, callback, iconKind)
        local expanded = false
        local card = new("Frame", {
            BackgroundColor3 = Theme.BgElevated, BorderSizePixel = 0,
            LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 58), ClipsDescendants = false,
        }, page)
        corner(card, RADIUS.card)
        hairline(card, Theme.StrokeSoft, 1, 0.45)
        iconTile(card, iconKind or tab.icon, tab.color, 30, UDim2.new(0, 14, 0.5, -15), 6)
        Text({
            Font = FONT.Bold, Position = UDim2.new(0, 56, 0, 11), Size = UDim2.new(1, -170, 0, 16),
            Text = title, TextColor3 = Theme.TextPrimary, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
        }, card)
        Text({
            Position = UDim2.new(0, 56, 0, 29), Size = UDim2.new(1, -170, 0, 16),
            Text = desc or "", TextColor3 = Theme.TextMuted, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
        }, card)

        local current = value or (options[1] or "—")
        local selector = new("TextButton", {
            AutoButtonColor = false, BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
            Position = UDim2.new(1, -152, 0.5, -12), Size = UDim2.new(0, 138, 0, 24),
            Text = "", ZIndex = 7,
        }, card)
        corner(selector, RADIUS.chip)
        hairline(selector, Theme.StrokeSoft, 1, 0.4)
        local selectorText = Text({
            Font = FONT.Bold, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -26, 1, 0),
            Text = tostring(current), TextColor3 = Theme.TextSecondary, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8,
        }, selector)
        Text({
            Position = UDim2.new(1, -18, 0, 0), Size = UDim2.new(0, 16, 1, 0), Text = "▾",
            TextColor3 = Theme.TextFaint, TextSize = 11, ZIndex = 8,
        }, selector)

        local list = new("Frame", {
            BackgroundColor3 = Theme.BgRaised, BorderSizePixel = 0, ClipsDescendants = true,
            Position = UDim2.new(1, -152, 0.5, 14), Size = UDim2.new(0, 138, 0, 0),
            Visible = false, ZIndex = 40,
        }, card)
        corner(list, RADIUS.chip)
        hairline(list, Theme.Stroke, 1, 0.3)
        local listLayout = new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)
        new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, list)

        -- declared before the rows: their handlers compare against it
        local function close()
            expanded = false
            list.Visible = false
            list.Size = UDim2.new(0, 138, 0, 0)
        end

        local api = {}
        function api.SetOptions(newOptions)
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            for index, option in ipairs(newOptions) do
                local row = new("TextButton", {
                    AutoButtonColor = false, BackgroundTransparency = 1, Font = FONT.UI,
                    LayoutOrder = index, Size = UDim2.new(1, 0, 0, 22), Text = "   " .. tostring(option),
                    TextColor3 = Theme.TextSecondary, TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 41,
                }, list)
                row.MouseEnter:Connect(function() row.BackgroundTransparency = 0.8 end)
                row.MouseLeave:Connect(function() row.BackgroundTransparency = 1 end)
                row.MouseButton1Click:Connect(function()
                    current = option
                    selectorText.Text = tostring(option)
                    if CONTROLS.open == close then CONTROLS.open = nil end
                    close()
                    CONTROLS.spawn("dropdown · " .. title, callback, option)
                end)
            end
        end
        api.SetOptions(options)
        api.Get = function() return current end
        api.Set = function(option)
            current = option
            selectorText.Text = tostring(option)
            if CONTROLS.open == close then CONTROLS.open = nil end
            close()
            CONTROLS.spawn("dropdown · " .. title, callback, option)
        end

        selector.MouseButton1Click:Connect(function()
            -- two open lists overlap and the one on top steals the click
            if CONTROLS.open and CONTROLS.open ~= close then CONTROLS.open() end
            expanded = not expanded
            if not expanded then close() CONTROLS.open = nil return end
            local rows = 0
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("TextButton") then rows = rows + 1 end
            end
            local height = math.min(rows, 7) * 24 + 8
            CONTROLS.open = close
            list.Visible = true
            list.Size = UDim2.new(0, 138, 0, height)
        end)
        table.insert(tab.searchIndex, title)
        CONTROLS.register("dropdown", title, tab, {
            set = api.Set, get = api.Get, options = options,
        })
        return api
    end

    -- a real theme picker: six swatches, each painted in its own palette, so
    -- the choice is made by looking at the menu, not by reading a label
    function tab:AddThemePicker(title, desc, entries, currentKey, callback)
        local card = new("Frame", {
            BackgroundColor3 = Theme.BgElevated, BorderSizePixel = 0,
            LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 108),
        }, page)
        corner(card, RADIUS.card)
        hairline(card, Theme.StrokeSoft, 1, 0.45)
        Text({
            Font = FONT.Bold, Position = UDim2.new(0, 16, 0, 12), Size = UDim2.new(1, -32, 0, 16),
            Text = title, TextColor3 = Theme.TextPrimary, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
        }, card)
        Text({
            Position = UDim2.new(0, 16, 0, 29), Size = UDim2.new(1, -32, 0, 14),
            Text = desc or "", TextColor3 = Theme.TextMuted, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
        }, card)

        local holder = new("Frame", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 50),
            Size = UDim2.new(1, -32, 0, 46), ZIndex = 6,
        }, card)

        local order, byLabel, swatches = {}, {}, {}
        local selected = nil
        local function paint()
            for key, swatch in pairs(swatches) do
                local active = key == selected
                swatch.Stroke.Color = active and Theme.Accent or Theme.StrokeSoft
                swatch.Stroke.Thickness = active and 2 or 1
                swatch.Stroke.Transparency = active and 0.1 or 0.45
                swatch.Dot.BackgroundTransparency = active and 0 or 0.35
            end
        end
        local choose
        choose = function(key, silent)
            if not swatches[key] then return false end
            selected = key
            paint()
            if not silent and callback then CONTROLS.spawn("theme · " .. title, callback, key) end
            return true
        end

        local count = #entries
        local width = math.floor((524 - (count - 1) * 6) / count)
        for index, entry in ipairs(entries) do
            local button = new("TextButton", {
                AutoButtonColor = false, BackgroundColor3 = entry.bg, BorderSizePixel = 0,
                Position = UDim2.new(0, (index - 1) * (width + 6), 0, 0),
                Size = UDim2.new(0, width, 0, 46), Text = "", ZIndex = 7,
            }, holder)
            corner(button, math.min(RADIUS.chip, 8))
            local stroke = new("UIStroke", {
                Color = Theme.StrokeSoft, Thickness = 1, Transparency = 0.45,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }, button)
            Text({
                Position = UDim2.new(0, 7, 0, 6), Size = UDim2.new(1, -14, 0, 12),
                Text = entry.short or entry.key, TextColor3 = entry.text, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
            }, button)
            local dotChoices = { entry.accent, entry.accent2, entry.accent3 }
            for dotIndex = 1, 3 do
                local dot = new("Frame", {
                    BackgroundColor3 = dotChoices[dotIndex] or entry.accent,
                    BorderSizePixel = 0, Position = UDim2.new(0, 7 + (dotIndex - 1) * 10, 0, 27),
                    Size = UDim2.new(0, 7, 0, 7), ZIndex = 8,
                }, button)
                corner(dot, RADIUS.pill)
                if dotIndex == 1 then button.Dot = dot end
            end
            button.MouseEnter:Connect(function() stroke.Transparency = 0.1 end)
            button.MouseLeave:Connect(function()
                if selected ~= entry.key then stroke.Transparency = 0.45 end
            end)
            button.MouseButton1Click:Connect(function() choose(entry.key, false) end)
            swatches[entry.key] = { Frame = button, Stroke = stroke, Dot = button.Dot }
            order[index] = entry.key
            byLabel[entry.label or entry.key] = entry.key
            byLabel[entry.key] = entry.key
        end
        selected = currentKey
        paint()

        CONTROLS.register("theme", title, tab, {
            set = function(value) choose(byLabel[value] or value, false) end,
            get = function() return selected end,
            options = order,
        })
        table.insert(tab.searchIndex, title)
        return {
            Set = function(value) choose(byLabel[value] or value, true) end,
            Get = function() return selected end,
        }
    end

    function tab:AddInput(title, desc, placeholder, callback, iconKind)
        local card = new("Frame", {
            BackgroundColor3 = Theme.BgElevated, BorderSizePixel = 0,
            LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 58),
        }, page)
        corner(card, RADIUS.card)
        hairline(card, Theme.StrokeSoft, 1, 0.45)
        iconTile(card, iconKind or tab.icon, tab.color, 30, UDim2.new(0, 14, 0.5, -15), 6)
        Text({
            Font = FONT.Bold, Position = UDim2.new(0, 56, 0, 11), Size = UDim2.new(1, -170, 0, 16),
            Text = title, TextColor3 = Theme.TextPrimary, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
        }, card)
        Text({
            Position = UDim2.new(0, 56, 0, 29), Size = UDim2.new(1, -170, 0, 16),
            Text = desc or "", TextColor3 = Theme.TextMuted, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
        }, card)

        local shell = new("Frame", {
            BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
            Position = UDim2.new(1, -152, 0.5, -12), Size = UDim2.new(0, 138, 0, 24), ZIndex = 7,
        }, card)
        corner(shell, RADIUS.chip)
        local stroke = hairline(shell, Theme.StrokeSoft, 1, 0.4)
        local box = new("TextBox", {
            BackgroundTransparency = 1, ClearTextOnFocus = false, Font = FONT.UI,
            PlaceholderText = placeholder or "…", PlaceholderColor3 = Theme.TextFaint,
            Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -18, 1, 0),
            Text = "", TextColor3 = Theme.TextPrimary, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
        }, shell)
        local function commit()
            if box.Text and #box.Text > 0 then
                CONTROLS.spawn("input · " .. title, callback, box.Text)
            end
        end
        box.FocusLost:Connect(function()
            stroke.Color = Theme.StrokeSoft
            commit()
        end)
        box.Focused:Connect(function() stroke.Color = tab.color end)
        table.insert(tab.searchIndex, title)
        CONTROLS.register("input", title, tab, {
            get = function() return box.Text end,
            commit = function(text)
                if text ~= nil then box.Text = tostring(text) end
                commit()
            end,
        })
        return box
    end

    function tab:AddKeybind(title, desc, default, callback, iconKind)
        local card = new("Frame", {
            BackgroundColor3 = Theme.BgElevated, BorderSizePixel = 0,
            LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 58),
        }, page)
        corner(card, RADIUS.card)
        hairline(card, Theme.StrokeSoft, 1, 0.45)
        iconTile(card, iconKind or tab.icon, tab.color, 30, UDim2.new(0, 14, 0.5, -15), 6)
        Text({
            Font = FONT.Bold, Position = UDim2.new(0, 56, 0, 11), Size = UDim2.new(1, -170, 0, 16),
            Text = title, TextColor3 = Theme.TextPrimary, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
        }, card)
        Text({
            Position = UDim2.new(0, 56, 0, 29), Size = UDim2.new(1, -170, 0, 16),
            Text = desc or "", TextColor3 = Theme.TextMuted, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
        }, card)
        local button = new("TextButton", {
            AutoButtonColor = false, BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
            Font = FONT.Mono, Position = UDim2.new(1, -110, 0.5, -12), Size = UDim2.new(0, 96, 0, 24),
            Text = default or "None", TextColor3 = Theme.TextSecondary, TextSize = 10, ZIndex = 7,
        }, card)
        corner(button, RADIUS.chip)
        hairline(button, Theme.StrokeSoft, 1, 0.4)
        local capturing = false
        button.MouseButton1Click:Connect(function()
            capturing = true
            button.Text = "press a key…"
            button.TextColor3 = tab.color
        end)
        local function accept(name)
            capturing = false
            button.Text = tostring(name)
            button.TextColor3 = Theme.TextSecondary
            CONTROLS.spawn("keybind · " .. title, callback, name)
        end
        if UserInput then
            UserInput.InputBegan:Connect(function(input, gameProcessed)
                -- while a rebind is armed the player is still allowed to type in
                -- chat; a keystroke the game already consumed must not bind
                if gameProcessed then return end
                if capturing and input.UserInputType == Enum.UserInputType.Keyboard then
                    accept(input.KeyCode.Name)
                end
            end)
        end
        table.insert(tab.searchIndex, title)
        CONTROLS.register("keybind", title, tab, {
            get = function() return button.Text end,
            commit = function(name) accept(name) end,
        })
        return button
    end

    function tab:AddLabel(text, iconKind)
        local card = new("Frame", {
            BackgroundColor3 = Theme.BgElevated, BackgroundTransparency = 0.35, BorderSizePixel = 0,
            LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 40),
        }, page)
        corner(card, RADIUS.card)
        hairline(card, Theme.StrokeSoft, 1, 0.5)
        iconTile(card, iconKind or "crest", tab.color, 22, UDim2.new(0, 12, 0.5, -11), 6)
        local label = Text({
            Position = UDim2.new(0, 44, 0, 0), Size = UDim2.new(1, -54, 1, 0),
            Text = text, TextColor3 = Theme.TextSecondary, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 6,
        }, card)
        table.insert(tab.searchIndex, text)
        return label
    end

    function tab:AddStatusPanel(title, provider, height)
        local card = new("Frame", {
            BackgroundColor3 = Theme.BgElevated, BorderSizePixel = 0,
            LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, height or 108),
        }, page)
        corner(card, RADIUS.card)
        hairline(card, Theme.StrokeSoft, 1, 0.45)
        iconTile(card, ICON.Guard, tab.color, 26, UDim2.new(0, 14, 0, 12), 6)
        Text({
            Font = FONT.Bold, Position = UDim2.new(0, 50, 0, 13), Size = UDim2.new(1, -140, 0, 16),
            Text = title, TextColor3 = Theme.TextPrimary, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
        }, card)
        local dot = new("Frame", {
            BackgroundColor3 = Theme.Success, BorderSizePixel = 0,
            Position = UDim2.new(1, -74, 0, 18), Size = UDim2.new(0, 6, 0, 6), ZIndex = 6,
        }, card)
        corner(dot, RADIUS.pill)
        Text({
            Font = FONT.Mono, Position = UDim2.new(1, -64, 0, 13), Size = UDim2.new(0, 56, 0, 16),
            Text = "LIVE", TextColor3 = Theme.Success, TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6,
        }, card)

        local box = new("Frame", {
            BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
            Position = UDim2.new(0, 14, 0, 38), Size = UDim2.new(1, -28, 1, -52), ZIndex = 6,
        }, card)
        corner(box, RADIUS.control)
        local body = Text({
            Font = FONT.Mono, Position = UDim2.new(0, 10, 0, 8), Size = UDim2.new(1, -20, 1, -16),
            Text = "", TextColor3 = Theme.TextSecondary, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true, ZIndex = 7,
        }, box)

        task.spawn(function()
            local pulse = true
            while card.Parent do
                CONTROLS.tick("status · " .. title, function()
                    local ok, lines = pcall(provider)
                    if ok then
                        if type(lines) == "table" then
                            -- accept both a plain list of strings and {label, value} rows
                            local out = {}
                            for _, line in ipairs(lines) do
                                if type(line) == "table" then
                                    out[#out + 1] = string.format("%-14s %s", tostring(line.label or ""), tostring(line.value or ""))
                                else
                                    out[#out + 1] = tostring(line)
                                end
                            end
                            body.Text = table.concat(out, "\n")
                        else
                            body.Text = tostring(lines)
                        end
                    end
                    pulse = not pulse
                    dot.BackgroundColor3 = pulse and Theme.Success or tint(Theme.Success, 0.4)
                end)
                task.wait(0.5)
            end
        end)
        table.insert(tab.searchIndex, title)
        return body
    end

    function tab:AddPlayerList(title, provider, actions)
        local card = new("Frame", {
            BackgroundColor3 = Theme.BgElevated, BorderSizePixel = 0,
            LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 130),
        }, page)
        corner(card, RADIUS.card)
        hairline(card, Theme.StrokeSoft, 1, 0.45)
        iconTile(card, ICON.Player, tab.color, 26, UDim2.new(0, 14, 0, 12), 6)
        Text({
            Font = FONT.Bold, Position = UDim2.new(0, 50, 0, 13), Size = UDim2.new(1, -140, 0, 16),
            Text = title, TextColor3 = Theme.TextPrimary, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
        }, card)
        local count = Text({
            Font = FONT.Mono, Position = UDim2.new(1, -140, 0, 13), Size = UDim2.new(0, 126, 0, 16),
            Text = "", TextColor3 = Theme.TextFaint, TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6,
        }, card)

        local list = new("ScrollingFrame", {
            BackgroundColor3 = Theme.BgInset, BackgroundTransparency = 0.4, BorderSizePixel = 0,
            Position = UDim2.new(0, 14, 0, 38), Size = UDim2.new(1, -28, 1, -52),
            ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Stroke, CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 6,
        }, card)
        corner(list, RADIUS.control)
        new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, list)
        new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6) }, list)

        local rows = {}
        task.spawn(function()
            while card.Parent do
                CONTROLS.tick("players · " .. title, function()
                    local ok, data = pcall(provider)
                    if ok and type(data) == "table" then
                        count.Text = tostring(#data) .. " in server"
                        for index, entry in ipairs(data) do
                            local row = rows[index]
                            if not row then
                                row = new("Frame", {
                                    BackgroundColor3 = Theme.BgRaised, BackgroundTransparency = 0.4,
                                    BorderSizePixel = 0, LayoutOrder = index, Size = UDim2.new(1, 0, 0, 30), ZIndex = 7,
                                }, list)
                                corner(row, RADIUS.chip)
                                row.Avatar = new("ImageLabel", {
                                    BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
                                    Position = UDim2.new(0, 5, 0.5, -10), Size = UDim2.new(0, 20, 0, 20), ZIndex = 8,
                                }, row)
                                corner(row.Avatar, RADIUS.pill)
                                row.Lamp = new("Frame", {
                                    BackgroundColor3 = Theme.TextFaint, BorderSizePixel = 0,
                                    Position = UDim2.new(0, 29, 0.5, -3), Size = UDim2.new(0, 6, 0, 6), ZIndex = 8,
                                }, row)
                                corner(row.Lamp, RADIUS.pill)
                                row.Name = Text({
                                    Font = FONT.Bold, Position = UDim2.new(0, 40, 0, 3), Size = UDim2.new(1, -180, 0, 13),
                                    Text = "", TextColor3 = Theme.TextPrimary, TextSize = 10,
                                    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8,
                                }, row)
                                row.Info = Text({
                                    Font = FONT.Mono, Position = UDim2.new(0, 40, 0, 15), Size = UDim2.new(1, -180, 0, 12),
                                    Text = "", TextColor3 = Theme.TextFaint, TextSize = 9,
                                    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8,
                                }, row)
                                row.Buttons = {}
                                for buttonIndex, action in ipairs(actions or {}) do
                                    local actionButton = new("TextButton", {
                                        AutoButtonColor = false, BackgroundColor3 = tint(tab.color, 0.88),
                                        BorderSizePixel = 0, Font = FONT.Bold,
                                        Position = UDim2.new(1, -132 + (buttonIndex - 1) * 30, 0.5, -9),
                                        Size = UDim2.new(0, 26, 0, 18), Text = action.label,
                                        TextColor3 = tab.color, TextSize = 9, ZIndex = 9,
                                    }, row)
                                    corner(actionButton, RADIUS.chip)
                                    actionButton.MouseButton1Click:Connect(function() action.callback(entry.player) end)
                                    table.insert(row.Buttons, actionButton)
                                end
                                rows[index] = row
                            end
                            row.Visible = true
                            row.Name.Text = entry.name
                            row.Info.Text = entry.info or ""
                            row.Lamp.BackgroundColor3 = entry.color or Theme.TextFaint
                            row.Avatar.Image = entry.avatar or ""
                            row.LayoutOrder = index
                            for _, actionButton in ipairs(row.Buttons) do
                                local target = entry.player
                                actionButton.Visible = target ~= nil
                            end
                        end
                        for index = #data + 1, #rows do rows[index].Visible = false end
                end
                end)
                task.wait(1)
            end
        end)
        table.insert(tab.searchIndex, title)
        return list
    end

    Tabs[#Tabs + 1] = tab
    return tab
end

-- ═══════════════════════════════════════════════════════════════════════════
-- (engine, features and tab definitions continue below)
-- ═══════════════════════════════════════════════════════════════════════════



-- ═══════════════════════════════════════════════════════════════════════════
-- SHARED NAMESPACE — the tab layer runs in its own closure (Lua allows 200
-- locals per scope and this file uses nearly all of them), so the symbols it
-- needs are published here. Passing 90 arguments would break the register
-- limit instead; one table is free.
-- ═══════════════════════════════════════════════════════════════════════════
local NS = {}
do
    NS.AUTHOR = META.author
    NS.BUILD = META.build
    NS.Camera = Camera
    NS.getCamera = refreshCamera
    NS.Config = Config
    NS.GAME_NAME = META.game
    NS.ICON = ICON
    NS.Lighting = Lighting
    NS.LocalPlayer = LocalPlayer
    NS.Players = Players
    NS.RADIUS = RADIUS
    NS.SharedEnv = SharedEnv
    NS.Tabs = Tabs
    NS.Theme = Theme
    NS.UserInput = UserInput
    NS.VERSION = META.version
    NS.Workspace = Workspace
    NS.buildWindow = buildWindow
    NS.corner = corner
    NS.getService = getService
    NS.getWindow = getWindow
    NS.makeTab = makeTab
    NS.new = new
    NS.notify = notify
    NS.safeCall = safeCall
    NS.palettes = THEMES
    NS.controls = ControlRegistry
    NS.controlHealth = CONTROLS
end

-- A theme is applied by rebuilding, so the interface has to be able to vanish
-- completely: destroy the ScreenGui, drop every tab and every registry entry,
-- and leave the module in the state it had before buildWindow() first ran.
function NS.resetInterface()
    if Window and Window.Screen then pcall(function() Window.Screen:Destroy() end) end
    for index = #Tabs, 1, -1 do Tabs[index] = nil end
    for index = #ToggleRegistry, 1, -1 do ToggleRegistry[index] = nil end
    for index = #ControlRegistry, 1, -1 do ControlRegistry[index] = nil end
    CONTROLS.open = nil
    Window, Body, Rail, PageHolder, Toast, ActiveTab = nil, nil, nil, nil, nil, nil
    TOAST.holder = nil
    return true
end
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- 6 · STATE AND WORLD — what the farm can see, and what it is allowed to do
--     Everything here is an input layer: pick a mob, walk to it, press the
--     same button a player presses. Damage, drops and quest progress are the
--     server's decision, not ours.
-- ═══════════════════════════════════════════════════════════════════════════
local State = {
    alive        = true,
    beats        = {},
    kills        = 0,
    chests       = 0,
    fruits       = 0,
    drops        = 0,
    quests       = 0,
    hits         = 0,
    steps        = 0,
    studs        = 0,
    lastAttack   = 0,
    lastTravel   = 0,
    lastSkill    = 0,
    lastScan     = 0,
    lastSave     = 0,
    target       = nil,
    status       = "idle",
    hitboxBase   = {},
    skillIndex   = 0,
    startedAt    = os.clock(),
    configDirty  = false,
    attacked     = {},
    pending      = {},
}

local Engine = {}
local Farm = {}
local Store = {}
local World = { mobs = {}, chests = {}, fruits = {}, drops = {}, npcs = {}, quest = nil, players = 0 }

-- every long-lived worker runs its frame through here: one unexpected error
-- is counted and logged, and the worker keeps ticking instead of dying
local function protectLoop(name, body)
    local ok, err = pcall(body)
    if ok then return end
    local log = SharedEnv.__SkillHubErrorLog
    if log and #log < 40 then table.insert(log, tostring(name) .. ": " .. tostring(err)) end
    State.loopErrors = (State.loopErrors or 0) + 1
end

local function getChar()
    return LocalPlayer and LocalPlayer.Character or nil
end

local function getRoot()
    local character = getChar()
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

local function getHumanoid()
    local character = getChar()
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

local function isAlive()
    local humanoid = getHumanoid()
    return humanoid ~= nil and (tonumber(humanoid.Health) or 0) > 0
end

local function myPosition()
    local root = getRoot()
    return root and root.Position or nil
end

local function flatDistance(a, b)
    if not a or not b then return math.huge end
    local dx, dz = a.X - b.X, a.Z - b.Z
    return math.sqrt(dx * dx + dz * dz)
end

local function lower(text)
    return string.lower(tostring(text or ""))
end

local function contains(text, needle)
    return string.find(lower(text), lower(needle), 1, true) ~= nil
end

-- a class search that never walks more than a few hundred instances
local function firstClass(instance, class, depthLimit)
    if not instance then return nil end
    local direct = instance:FindFirstChildWhichIsA(class)
    if direct then return direct end
    if (depthLimit or 3) <= 0 then return nil end
    for _, child in ipairs(instance:GetChildren()) do
        local found = firstClass(child, class, (depthLimit or 3) - 1)
        if found then return found end
    end
    return nil
end

local function promptOf(instance)
    return firstClass(instance, "ProximityPrompt", 3)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 7 · THE SCANNER — cheap, top-level first, no per-frame descent
-- ═══════════════════════════════════════════════════════════════════════════
local PLAYER_CHARS = {}

local function refreshPlayerChars()
    for key in pairs(PLAYER_CHARS) do PLAYER_CHARS[key] = nil end
    local players = Players and Players:GetPlayers() or {}
    for _, player in ipairs(players) do
        local character = player.Character
        if character then PLAYER_CHARS[character] = true end
    end
end

local LOOT_WORDS = { "money", "cash", "coin", "drop", "bounty", "beli", "beri" }
local FRUIT_SKIP = { "dealer", "blox fruit", "fruit spawner", "fruitstand", "fruit stand" }

local function matchesAny(name, words)
    for _, word in ipairs(words) do
        if string.find(lower(name), word, 1, true) then return true end
    end
    return false
end

local function pushUnique(list, value)
    for _, existing in ipairs(list) do
        if existing == value then return false end
    end
    list[#list + 1] = value
    return true
end

local function scanWorld(force)
    local now = os.clock()
    if not force and now - State.lastScan < 0.25 then return World end
    State.lastScan = now
    refreshPlayerChars()

    for index = #World.mobs, 1, -1 do World.mobs[index] = nil end
    for index = #World.chests, 1, -1 do World.chests[index] = nil end
    for index = #World.fruits, 1, -1 do World.fruits[index] = nil end
    for index = #World.drops, 1, -1 do World.drops[index] = nil end
    for index = #World.npcs, 1, -1 do World.npcs[index] = nil end
    World.quest = nil

    local origin = myPosition()
    local range = tonumber(Config.ScanRange) or 250

    local containers = { Workspace }
    for _, folderName in ipairs({ "Enemies", "Mobs", "NPCs", "Chests", "Drops" }) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then containers[#containers + 1] = folder end
    end

    for _, container in ipairs(containers) do
        for _, child in ipairs(container:GetChildren()) do
            local class = child.ClassName
            local name = child.Name
            local root = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
            local position = (root and root.Position) or child.Position or nil

            if class == "Model" and not PLAYER_CHARS[child] then
                local humanoid = child:FindFirstChildOfClass("Humanoid")
                if humanoid and root and (tonumber(humanoid.Health) or 0) > 0 then
                    if not origin or flatDistance(origin, position) <= range then
                        local maxHealth = tonumber(humanoid.MaxHealth) or 100
                        World.mobs[#World.mobs + 1] = {
                            model = child, root = root, humanoid = humanoid,
                            name = name, position = position,
                            health = tonumber(humanoid.Health) or 0,
                            maxHealth = maxHealth,
                            boss = maxHealth >= 300 or contains(name, "boss"),
                        }
                    end
                end
                local prompt = promptOf(child)
                if prompt then
                    local label = lower(prompt.ObjectText or "") .. " " .. lower(prompt.ActionText or "")
                    local isQuest = contains(name, "quest") or contains(label, "quest") or contains(label, "talk")
                    local isChest = contains(name, "chest") or contains(label, "chest")
                    if isQuest and (not origin or flatDistance(origin, position or origin) <= 120) then
                        World.npcs[#World.npcs + 1] = { model = child, prompt = prompt, name = name, position = position }
                        if not World.quest then World.quest = World.npcs[#World.npcs] end
                    elseif isChest and child.Parent ~= nil and not child:GetAttribute("Taken") then
                        if not origin or flatDistance(origin, position or origin) <= range then
                            World.chests[#World.chests + 1] = { model = child, prompt = prompt, position = position or (origin or Vector3.new()), name = name }
                        end
                    end
                elseif contains(name, "chest") and not child:GetAttribute("Taken") then
                    if position and (not origin or flatDistance(origin, position) <= range) then
                        World.chests[#World.chests + 1] = { model = child, prompt = nil, position = position, name = name }
                    end
                end
            elseif class == "Tool" then
                -- Blox Fruits spawns a fruit on the ground as a Tool with a Handle
                local handle = child:FindFirstChild("Handle")
                local fruitPosition = handle and handle.Position or nil
                if fruitPosition and contains(name, "fruit") and not matchesAny(name, FRUIT_SKIP) then
                    if not origin or flatDistance(origin, fruitPosition) <= range then
                        World.fruits[#World.fruits + 1] = { model = child, position = fruitPosition, name = name }
                    end
                end
            elseif class == "Part" or class == "MeshPart" or class == "Model" then
                local targetPosition = position
                if targetPosition and matchesAny(name, LOOT_WORDS) and not contains(name, "spawn") then
                    if not origin or flatDistance(origin, targetPosition) <= range then
                        World.drops[#World.drops + 1] = { model = child, position = targetPosition, name = name }
                    end
                end
            end
        end
    end

    -- a mob we hit that is now gone (or at zero health) is a kill we can count
    for model in pairs(State.attacked) do
        local gone = model.Parent == nil
        local dead = false
        if not gone then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            dead = humanoid == nil or (tonumber(humanoid.Health) or 0) <= 0
        end
        if gone or dead then
            State.kills = State.kills + 1
            State.attacked[model] = nil
        end
    end

    if Players then
        World.players = #Players:GetPlayers()
    end
    return World
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 8 · TARGETING — nearest, quest area, or boss
-- ═══════════════════════════════════════════════════════════════════════════
local function pickMob()
    local origin = myPosition()
    if not origin then return nil end
    local mode = Config.FarmMode
    local best, bestScore = nil, nil
    for _, mob in ipairs(World.mobs) do
        local allowed = true
        if mode == "Boss" then
            allowed = mob.boss == true
        elseif mode == "Quest area" and World.quest and World.quest.position then
            allowed = flatDistance(mob.position, World.quest.position) <= 180
        end
        if allowed then
            local score = flatDistance(origin, mob.position)
            if not bestScore or score < bestScore then best, bestScore = mob, score end
        end
    end
    return best
end

local function pickNearest(list)
    local origin = myPosition()
    if not origin then return nil end
    local best, bestScore = nil, nil
    for _, entry in ipairs(list) do
        if entry.position then
            local score = flatDistance(origin, entry.position)
            if not bestScore or score < bestScore then best, bestScore = entry, score end
        end
    end
    return best
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 9 · TRAVEL — paced steps, never one giant jump
-- ═══════════════════════════════════════════════════════════════════════════
local function travelTo(position, stopDistance)
    if not position then return false end
    local root = getRoot()
    if not root then return false end
    stopDistance = stopDistance or math.max(tonumber(Config.AttackRange) or 16 * 0.7, 4)
    local delta = position - root.Position
    local distance = delta.Magnitude
    if distance <= stopDistance then return true end

    local now = os.clock()
    local delay = math.max(tonumber(Config.TravelDelay) or 0.08, 0.02)
    if now - State.lastTravel < delay then return false end
    State.lastTravel = now

    local ceiling = Config.SafeMode and (tonumber(Config.SpeedCap) or 60)
        or (tonumber(Config.TravelSpeed) or 90)
    local maxStep = math.max(ceiling * delay, 1)
    local step = math.min(distance - stopDistance, tonumber(Config.TravelStep) or 10, maxStep)
    if step <= 0.05 then return true end

    local unit = delta.Unit
    local destination = root.Position + unit * step
    local ok = pcall(function()
        if CFrame.lookAt then
            root.CFrame = CFrame.lookAt(destination, destination + unit)
        else
            root.CFrame = CFrame.new(destination)
        end
    end)
    if ok then
        State.steps = State.steps + 1
        State.studs = State.studs + step
    end
    return ok
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 10 · THE INPUT LAYER — equip, click, press keys
-- ═══════════════════════════════════════════════════════════════════════════
local MELEE_HINTS = { "combat", "melee", "fist", "sword", "katana", "blade", "axe", "club" }

local function scoreTool(tool)
    local score = 0
    local name = lower(tool.Name)
    for index, hint in ipairs(MELEE_HINTS) do
        if string.find(name, hint, 1, true) then score = score + (20 - index) end
    end
    if tool.ToolTip and contains(tool.ToolTip, "melee") then score = score + 30 end
    if tool:FindFirstChild("Handle") == nil then score = score - 1 end
    return score
end

local function equipMelee()
    local character, humanoid = getChar(), getHumanoid()
    if not character or not humanoid then return nil end
    local equipped = character:FindFirstChildOfClass("Tool")
    if equipped then return equipped end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return nil end
    local best, bestScore = nil, -1
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local score = scoreTool(tool)
            if score > bestScore then best, bestScore = tool, score end
        end
    end
    if not best then return nil end
    local ok = pcall(function() humanoid:EquipTool(best) end)
    if not ok then pcall(function() best.Parent = character end) end
    return best
end

local function attackRate()
    local rate = tonumber(Config.AttackRate) or 0.18
    if Config.SafeMode then rate = math.max(rate, 0.22) end
    return math.max(rate, 0.08)
end

local function clickOnce()
    if mouse1click then
        if pcall(mouse1click) then return true end
    end
    if VirtualUser then
        local ok = pcall(function() VirtualUser:ClickButton1(Vector2.new(0, 0)) end)
        if ok then return true end
    end
    return false
end

local function attackOnce()
    local tool = equipMelee()
    State.hits = State.hits + 1
    State.lastAttack = os.clock()
    if tool then pcall(function() tool:Activate() end) end
    if Config.MouseClicks ~= false then clickOnce() end
    return tool ~= nil
end

local function attackTarget(mob)
    if not mob then return false end
    if os.clock() - State.lastAttack < attackRate() then return false end
    State.attacked[mob.model] = true
    return attackOnce()
end

local SKILL_KEYS = { "Z", "X", "C", "V" }

local function pressKey(key)
    if VirtualInputManager then
        local ok = pcall(function()
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end)
        if ok then return true end
    end
    if keypress and keyrelease then
        pcall(keypress, key)
        pcall(keyrelease, key)
        return true
    end
    return false
end

local function skillTick()
    if not Config.AutoSkill then return false end
    local target = State.target
    local origin = myPosition()
    if not target and origin then target = pickMob() end
    if not target or not origin then return false end
    if flatDistance(origin, target.position) > 22 then return false end
    local interval = math.max(tonumber(Config.SkillInterval) or 0.9, Config.SafeMode and 1.1 or 0.3)
    if os.clock() - State.lastSkill < interval then return false end
    State.skillIndex = (State.skillIndex % #SKILL_KEYS) + 1
    pressKey(SKILL_KEYS[State.skillIndex])
    State.lastSkill = os.clock()
    return true
end
do
-- ═══════════════════════════════════════════════════════════════════════════
-- 11 · LOOT — chests, fruit, drops, and the quest NPC
--      Every action is an interaction the game already offers: a proximity
--      prompt, a touch, or its own button. Nothing is granted from here.
-- ═══════════════════════════════════════════════════════════════════════════
local RECENT = {}

-- "recently" is a debounce on the *interaction*, not on the travel: marking a
-- chest while still walking to it would let the farm move one step every four
-- seconds.
local function isRecent(instance, seconds)
    if not instance then return false end
    local at = RECENT[instance]
    return at ~= nil and os.clock() - at < (seconds or 4)
end

local function markRecent(instance)
    if not instance then return end
    RECENT[instance] = os.clock()
    local count = 0
    for key in pairs(RECENT) do
        count = count + 1
        if count > 160 then RECENT[key] = nil end
    end
end

local function firePrompt(prompt)
    if not prompt then return false end
    if type(fireproximityprompt) == "function" then
        if pcall(fireproximityprompt, prompt) then return true end
    end
    local ok = pcall(function()
        prompt:InputHoldBegin()
        prompt:InputHoldEnd()
    end)
    return ok
end

local function touch(position)
    local root = getRoot()
    if not root or not position then return false end
    return pcall(function() root.CFrame = CFrame.new(position) end)
end

local function chestTick()
    if not Config.AutoChest then return false end
    local chest = pickNearest(World.chests)
    if not chest then return false end
    if isRecent(chest.model, 3) then return false end
    local root = getRoot()
    if not root then return false end
    if flatDistance(root.Position, chest.position) > 9 then
        travelTo(chest.position, 6)
        return false
    end
    local prompt = chest.prompt or promptOf(chest.model)
    local fired = firePrompt(prompt)
    if not fired then fired = touch(chest.position) end
    if fired then
        markRecent(chest.model)
        State.chests = State.chests + 1
        State.status = "chest " .. chest.name
    end
    return fired
end

local function collectTick(list, kind, stopDistance)
    local entry = pickNearest(list)
    if not entry then return false end
    if isRecent(entry.model, 2) then return false end
    local root = getRoot()
    if not root then return false end
    if flatDistance(root.Position, entry.position) > (stopDistance or 6) then
        travelTo(entry.position, 4)
        return false
    end
    if touch(entry.position) then
        markRecent(entry.model)
        -- counted only when the game actually removes it, not when we walk on
        State.pending[entry.model] = { kind = kind, at = os.clock() }
        State.status = kind .. " · " .. entry.name
        return true
    end
    return false
end

-- a pickup is a hit only if the server takes the part away
local function resolvePending()
    for model, record in pairs(State.pending) do
        if model.Parent == nil then
            if record.kind == "fruit" then
                State.fruits = State.fruits + 1
            else
                State.drops = State.drops + 1
            end
            State.pending[model] = nil
        elseif os.clock() - record.at > 5 then
            State.pending[model] = nil
        end
    end
end

local function fruitTick()
    if not Config.AutoFruit then return false end
    return collectTick(World.fruits, "fruit", 6)
end

local function dropTick()
    if not Config.AutoDrops then return false end
    return collectTick(World.drops, "drop", 6)
end

local function questTick()
    if not Config.AutoQuest then return false end
    local quest = World.quest
    if not quest then return false end
    if isRecent(quest.model, 5) then return false end
    local root = getRoot()
    if not root or not quest.position then return false end
    if flatDistance(root.Position, quest.position) > 10 then
        travelTo(quest.position, 7)
        return false
    end
    local fired = firePrompt(quest.prompt)
    if not fired then
        -- some builds put the dialog behind a PlayerGui button instead
        local gui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if gui then
            for _, item in ipairs(gui:GetDescendants()) do
                if item:IsA("TextButton") and (contains(item.Text, "quest") or contains(item.Text, "accept")) then
                    pcall(function() item:Activate() end)
                    fired = true
                    break
                end
            end
        end
    end
    if fired then
        markRecent(quest.model)
        State.quests = State.quests + 1
        State.status = "quest accepted"
    end
    return fired
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 12 · MOB CONTROL — bring, hitbox, aura
-- ═══════════════════════════════════════════════════════════════════════════
local function restoreHitbox()
    for model, base in pairs(State.hitboxBase) do
        pcall(function()
            local root = model:FindFirstChild("HumanoidRootPart")
            if root and base.root then root.Size = base.root end
            local head = model:FindFirstChild("Head")
            if head and base.head then head.Size = base.head end
        end)
        State.hitboxBase[model] = nil
    end
end

local function hitboxTick()
    if not Config.MobHitbox then
        if next(State.hitboxBase) ~= nil then restoreHitbox() end
        return false
    end
    local factor = clamp(tonumber(Config.HitboxSize) or 2.2, 1, 4)
    for _, mob in ipairs(World.mobs) do
        local base = State.hitboxBase[mob.model]
        if not base then
            local head = mob.model:FindFirstChild("Head")
            base = { root = mob.root.Size, head = head and head.Size or nil }
            State.hitboxBase[mob.model] = base
        end
        pcall(function()
            if base.root then
                mob.root.Size = Vector3.new(base.root.X * factor, base.root.Y * factor, base.root.Z * factor)
            end
            local head = mob.model:FindFirstChild("Head")
            if head and base.head then
                head.Size = Vector3.new(base.head.X * factor, base.head.Y * factor, base.head.Z * factor)
            end
        end)
    end
    return true
end

local function bringTick()
    if not Config.BringMobs then return false end
    local root = getRoot()
    if not root then return false end
    local radius = tonumber(Config.BringRadius) or 60
    local moved = 0
    for _, mob in ipairs(World.mobs) do
        if moved >= 2 then break end
        local distance = flatDistance(root.Position, mob.position)
        if distance > 6 and distance <= radius then
            local angle = (moved * 2.1 + os.clock()) % (math.pi * 2)
            local offset = Vector3.new(math.cos(angle) * 3, 0, math.sin(angle) * 3)
            local destination = root.Position + offset
            local ok = pcall(function() mob.root.CFrame = CFrame.new(destination) end)
            if ok then
                mob.position = destination
                moved = moved + 1
            end
        end
    end
    return moved > 0
end

local function auraTick()
    if not Config.KillAura then return false end
    local origin = myPosition()
    if not origin then return false end
    local radius = tonumber(Config.AuraRadius) or 14
    for _, mob in ipairs(World.mobs) do
        if flatDistance(origin, mob.position) <= radius then
            State.target = mob
            State.status = "aura · " .. mob.name
            return attackTarget(mob)
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 13 · THE FARM BEAT — one loop, 10 ticks a second, every branch opt-in
-- ═══════════════════════════════════════════════════════════════════════════
local function farmTick()
    scanWorld(false)
    resolvePending()

    if Config.AutoFarm then
        local target = pickMob()
        State.target = target
        if target then
            local root = getRoot()
            local reach = tonumber(Config.AttackRange) or 16
            local distance = root and flatDistance(root.Position, target.position) or math.huge
            if distance > reach then
                State.status = "travelling · " .. target.name
                travelTo(target.position, math.max(reach * 0.6, 4))
            else
                State.status = "attacking · " .. target.name
                attackTarget(target)
            end
        else
            State.status = "no mobs in range"
        end
    elseif Config.AutoAttack then
        local target = State.target or pickMob()
        State.target = target
        if target then
            local root = getRoot()
            local reach = tonumber(Config.AttackRange) or 16
            if root and flatDistance(root.Position, target.position) <= reach then
                attackTarget(target)
            end
        end
    elseif not Config.KillAura then
        State.target = nil
        if State.status ~= "idle" then State.status = "idle" end
    end

    auraTick()
    if Config.AutoChest then chestTick() end
    if Config.AutoFruit then fruitTick() end
    if Config.AutoDrops then dropTick() end
    if Config.AutoQuest then questTick() end
    if Config.BringMobs then bringTick() end
    hitboxTick()
    skillTick()
end

local function movementTick()
    local humanoid = getHumanoid()
    if not humanoid then return end
    if Config.WalkSpeedEnabled then
        local speed = clamp(tonumber(Config.WalkSpeed) or 40, 16, 300)
        if Config.SafeMode then speed = math.min(speed, tonumber(Config.SpeedCap) or 60) end
        if humanoid.WalkSpeed ~= speed then humanoid.WalkSpeed = speed end
    end
    if Config.JumpPowerEnabled then
        local power = clamp(tonumber(Config.JumpPower) or 70, 50, 400)
        pcall(function()
            humanoid.UseJumpPower = true
            humanoid.JumpPower = power
        end)
    end
end

local function chromeTick()
    local window = getWindow and getWindow() or nil
    local chrome = window and window.Chrome
    if not chrome or not chrome.chips then return end
    local chips = chrome.chips
    local on = 0
    for _, key in ipairs({ "AutoFarm", "KillAura", "AutoChest", "AutoFruit", "AutoDrops", "AutoAttack", "BringMobs", "MobHitbox", "AutoSkill", "AutoQuest" }) do
        if Config[key] then on = on + 1 end
    end
    if chips.stateText then
        chips.stateText.Text = on == 0 and "IDLE" or ("ON " .. on)
        chips.stateText.TextColor3 = on == 0 and Theme.TextSecondary or Theme.Success
    end
    if chips.acText then
        chips.acText.Text = tostring(#World.mobs) .. " mob"
        chips.acText.TextColor3 = #World.mobs > 0 and Theme.Accent or Theme.TextSecondary
    end
    if chips.perfText then
        chips.perfText.Text = tostring(State.kills) .. " kill"
        chips.perfText.TextColor3 = State.kills > 0 and Theme.Success or Theme.TextSecondary
    end
    if chrome.strip then
        chrome.strip.Text = clockString() .. " · " .. tostring(State.status)
    end
end

local function startFarmLoop()
    task.spawn(function()
        while State.alive do
            State.beats.farm = os.clock()
            protectLoop("farm", farmTick)
            task.wait(0.1)
        end
    end)
end

local function startMovementLoop()
    task.spawn(function()
        while State.alive do
            State.beats.movement = os.clock()
            protectLoop("movement", movementTick)
            task.wait(0.25)
        end
    end)
end

local function startChromeLoop()
    task.spawn(function()
        while State.alive do
            State.beats.chrome = os.clock()
            protectLoop("chrome", chromeTick)
            task.wait(0.5)
        end
    end)
end

-- the engine's own surface: the tab layer and the tests drive the farm
-- through these, not through a pile of upvalues
Farm.tick = farmTick
Farm.movement = movementTick
Farm.chrome = chromeTick
Farm.chest = chestTick
Farm.fruit = fruitTick
Farm.drops = dropTick
Farm.quest = questTick
Farm.bring = bringTick
Farm.hitbox = hitboxTick
Farm.aura = auraTick
Farm.restoreHitbox = restoreHitbox
Farm.resolvePending = resolvePending
Farm.start = function()
    startFarmLoop()
    startMovementLoop()
    startChromeLoop()
end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 14 · CONFIG ON DISK — save, load, reset, export, import, autosave
--      The file is plain JSON at Config.ConfigPath. Executors without a file
--      API still get export/import through the clipboard; the status panel
--      says which one is in use instead of pretending.
-- ═══════════════════════════════════════════════════════════════════════════
do
    local DEFAULTS = {}
    for key, value in pairs(Config) do DEFAULTS[key] = value end

    -- keys that are safe to restore at boot: they never start an action
    local SAFE_KEYS = {
        Theme = true, UiScale = true, HideUiKey = true, PanicKey = true,
        Autosave = true, Autoload = true, NotifyActions = true,
        SafeMode = true, SpeedCap = true, TravelSpeed = true, TravelStep = true,
        TravelDelay = true, ScanRange = true, AttackRate = true, AttackRange = true,
        AuraRadius = true, BringRadius = true, HitboxSize = true, SkillInterval = true,
        ConfigPath = true, FarmMode = true, WalkSpeed = true, JumpPower = true,
    }

    local function jsonEscape(text)
        return (tostring(text):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t"))
    end

    local function jsonEncode(map)
        local keys = {}
        for key, value in pairs(map) do
            local kind = type(value)
            if kind == "boolean" or kind == "number" or kind == "string" then
                keys[#keys + 1] = key
            end
        end
        table.sort(keys)
        local parts = {}
        for _, key in ipairs(keys) do
            local value = map[key]
            local kind = type(value)
            if kind == "boolean" then
                parts[#parts + 1] = '"' .. key .. '":' .. tostring(value)
            elseif kind == "number" then
                parts[#parts + 1] = '"' .. key .. '":' .. string.format("%.6g", value)
            else
                parts[#parts + 1] = '"' .. key .. '":"' .. jsonEscape(value) .. '"'
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end

    local function jsonDecode(text)
        local position = 1
        local length = #text
        local function skip()
            while position <= length do
                local char = text:sub(position, position)
                if char == " " or char == "\n" or char == "\t" or char == "\r" then
                    position = position + 1
                else
                    break
                end
            end
        end
        local parseValue
        local function parseString()
            position = position + 1
            local out = {}
            while position <= length do
                local char = text:sub(position, position)
                if char == '"' then
                    position = position + 1
                    return table.concat(out)
                elseif char == "\\" then
                    local nextChar = text:sub(position + 1, position + 1)
                    if nextChar == "n" then out[#out + 1] = "\n"
                    elseif nextChar == "t" then out[#out + 1] = "\t"
                    elseif nextChar == "r" then out[#out + 1] = "\r"
                    elseif nextChar == "u" then out[#out + 1] = "?"; position = position + 4
                    else out[#out + 1] = nextChar end
                    position = position + 2
                else
                    out[#out + 1] = char
                    position = position + 1
                end
            end
            error("unterminated string")
        end
        local function parseNumber()
            local start = position
            while position <= length and text:sub(position, position):match("[%-%d%.eE%+]") do
                position = position + 1
            end
            return tonumber(text:sub(start, position - 1))
        end
        function parseValue()
            skip()
            local char = text:sub(position, position)
            if char == "{" then
                position = position + 1
                local map = {}
                skip()
                if text:sub(position, position) == "}" then position = position + 1 return map end
                while position <= length do
                    skip()
                    if text:sub(position, position) ~= '"' then error("expected key") end
                    local key = parseString()
                    skip()
                    if text:sub(position, position) ~= ":" then error("expected colon") end
                    position = position + 1
                    map[key] = parseValue()
                    skip()
                    local char2 = text:sub(position, position)
                    if char2 == "," then position = position + 1
                    elseif char2 == "}" then position = position + 1 return map
                    else error("expected }") end
                end
                error("unterminated object")
            elseif char == '"' then
                return parseString()
            elseif text:sub(position, position + 3) == "true" then
                position = position + 4
                return true
            elseif text:sub(position, position + 4) == "false" then
                position = position + 5
                return false
            elseif text:sub(position, position + 3) == "null" then
                position = position + 4
                return nil
            else
                return parseNumber()
            end
        end
        local value = parseValue()
        return value
    end

    local function snapshot()
        local copy = {}
        for key, value in pairs(Config) do
            local kind = type(value)
            if (kind == "boolean" or kind == "number" or kind == "string") and key ~= "UiVisible" then
                copy[key] = value
            end
        end
        copy.__savedAt = clockString()
        copy.__build = META.version
        return copy
    end

    local function hasFileApi()
        return type(writefile) == "function" and type(readfile) == "function"
    end

    local function apply(data, mode)
        if type(data) ~= "table" then return 0, "not a table" end
        local applied = 0
        for key, value in pairs(data) do
            if DEFAULTS[key] ~= nil then
                local want = type(DEFAULTS[key])
                if type(value) == want and (mode ~= "safe" or SAFE_KEYS[key]) then
                    Config[key] = value
                    applied = applied + 1
                end
            end
        end
        if Theme and THEMES and THEMES[Config.Theme] then applyTheme(Config.Theme) end
        return applied
    end

    local function save(manual)
        local text = jsonEncode(snapshot())
        local wrote = false
        if hasFileApi() then
            local ok = pcall(function()
                if type(makefolder) == "function" then pcall(makefolder, "FreeBloxFruit") end
                writefile(Config.ConfigPath, text)
            end)
            wrote = ok
        end
        State.lastConfig = text
        State.lastSave = os.clock()
        State.savedAt = clockString()
        State.savedPath = wrote and Config.ConfigPath or "clipboard only"
        if manual and Config.NotifyActions then
            notify("Config saved", wrote and Config.ConfigPath or "no file API — use Copy config", 3, Theme.Success, "save")
        end
        return wrote, text
    end

    local function load(manual)
        local text = nil
        if hasFileApi() and type(isfile) == "function" then
            local ok, exists = pcall(isfile, Config.ConfigPath)
            if ok and exists then
                local readOk, content = pcall(readfile, Config.ConfigPath)
                if readOk then text = content end
            end
        end
        if not text and manual and type(getclipboard) == "function" then
            local ok, content = pcall(getclipboard)
            if ok and type(content) == "string" and #content > 0 then text = content end
        end
        if not text then
            if manual then notify("Config", "no saved config yet", 3, Theme.Warning, "folder") end
            return false
        end
        local ok, data = pcall(jsonDecode, text)
        if not ok or type(data) ~= "table" then
            if manual then notify("Config", "saved config is not valid JSON", 4, Theme.Danger, "warning") end
            return false
        end
        local applied = apply(data, manual and "all" or "safe")
        State.lastConfig = text
        if manual then
            notify("Config loaded", tostring(applied) .. " keys · " .. Config.ConfigPath, 3, Theme.Success, "folder")
            if Store.afterChange then pcall(Store.afterChange) end
        end
        return true, applied
    end

    local function reset()
        for key, value in pairs(DEFAULTS) do Config[key] = value end
        applyTheme(Config.Theme)
        State.lastConfig = ""
        if Config.NotifyActions then notify("Config reset", "every switch is back to OFF", 3, Theme.Warning, "reset") end
        if Store.afterChange then pcall(Store.afterChange) end
        return true
    end

    local function export()
        local text = jsonEncode(snapshot())
        local copied = false
        if type(setclipboard) == "function" then
            copied = pcall(setclipboard, text)
        end
        if Config.NotifyActions then
            notify("Config copied", copied and (tostring(#text) .. " bytes on the clipboard") or "clipboard unavailable", 3,
                copied and Theme.Success or Theme.Warning, "save")
        end
        return text, copied
    end

    local function import(text)
        if type(text) ~= "string" or #text == 0 then return false, "empty" end
        local ok, data = pcall(jsonDecode, text)
        if not ok or type(data) ~= "table" then
            notify("Config", "that is not valid JSON", 4, Theme.Danger, "warning")
            return false
        end
        local applied = apply(data, "all")
        notify("Config imported", tostring(applied) .. " keys", 3, Theme.Success, "folder")
        if Store.afterChange then pcall(Store.afterChange) end
        return true, applied
    end

    -- ── named profiles: three slots next to the main config ────────────────
    local function profilePath(slot)
        return "FreeBloxFruit/profile-" .. tostring(slot or Config.ProfileSlot or "1") .. ".json"
    end

    local function saveProfile(slot)
        local path = profilePath(slot)
        local text = jsonEncode(snapshot())
        local wrote = false
        if hasFileApi() then
            wrote = pcall(function()
                if type(makefolder) == "function" then pcall(makefolder, "FreeBloxFruit") end
                writefile(path, text)
            end)
        end
        State.savedAt = clockString()
        if Config.NotifyActions then
            notify("Profile saved", path, 3, wrote and Theme.Success or Theme.Warning, "save")
        end
        return wrote, text, path
    end

    local function loadProfile(slot)
        local path = profilePath(slot)
        if not hasFileApi() or type(readfile) ~= "function" then
            return false, "no file API"
        end
        local readOk, text = pcall(readfile, path)
        if not readOk or type(text) ~= "string" then
            if Config.NotifyActions then notify("Profile", path .. " is empty", 3, Theme.Warning, "folder") end
            return false, "empty"
        end
        local parsed, data = pcall(jsonDecode, text)
        if not parsed or type(data) ~= "table" then return false, "broken file" end
        local applied = apply(data, "all")
        if Config.NotifyActions then
            notify("Profile loaded", tostring(applied) .. " keys · " .. path, 3, Theme.Success, "folder")
        end
        if Store.afterChange then pcall(Store.afterChange) end
        return true, applied, path
    end

    local function autosaveTick()
        if not Config.Autosave then return false end
        local text = jsonEncode(snapshot())
        if text == State.lastConfig then return false end
        return save(false)
    end

    local function startAutosave()
        task.spawn(function()
            while State.alive do
                State.beats.config = os.clock()
                protectLoop("config", autosaveTick)
                task.wait(2)
            end
        end)
    end

    -- Autoload is opt-in *from the saved file itself*: the hub peeks, sees
    -- "Autoload": true, and restores only the interface keys. A file with
    -- "AutoFarm": true and no Autoload never starts anything.
    local function bootAutoload()
        if not hasFileApi() or type(isfile) ~= "function" then return false end
        local ok, exists = pcall(isfile, Config.ConfigPath)
        if not ok or not exists then return false end
        local readOk, text = pcall(readfile, Config.ConfigPath)
        if not readOk or type(text) ~= "string" then return false end
        local parsed, data = pcall(jsonDecode, text)
        if not parsed or type(data) ~= "table" or data.Autoload ~= true then return false end
        apply(data, "safe")
        return true
    end

    Store.saveProfile = saveProfile
    Store.loadProfile = loadProfile
    Store.profilePath = profilePath
    Store.save = save
    Store.load = load
    Store.reset = reset
    Store.export = export
    Store.import = import
    Store.apply = apply
    Store.autosave = autosaveTick
    Store.start = startAutosave
    Store.bootAutoload = bootAutoload
    Store.markCurrent = function() State.lastConfig = jsonEncode(snapshot()) end
    Store.defaults = DEFAULTS
    Store.hasFileApi = hasFileApi
    Store.snapshot = snapshot
    Store.encode = jsonEncode
    Store.decode = jsonDecode
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 15 · INTERFACE — two tabs: Auto Farm and Settings
-- ═══════════════════════════════════════════════════════════════════════════
local FEATURE_KEYS = {
    "AutoFarm", "AutoQuest", "AutoAttack", "KillAura", "BringMobs", "MobHitbox",
    "AutoSkill", "AutoChest", "AutoFruit", "AutoDrops",
    "WalkSpeedEnabled", "JumpPowerEnabled",
}

local function featuresOn()
    local count = 0
    for _, key in ipairs(FEATURE_KEYS) do
        if Config[key] then count = count + 1 end
    end
    return count
end

local rebuilding = false
local buildTabs

local function rebuildInterface(reason)
    if rebuilding then return end
    rebuilding = true
    -- called from inside a control's own callback: let it return first, then
    -- replace the window it lives in
    task.delay(0.05, function()
        protectLoop("rebuild", function()
            NS.resetInterface()
            applyTheme(Config.Theme)
            local screen = NS.buildWindow()
            if not screen then error("the window could not be rebuilt") end
            buildTabs()
            if Config.NotifyActions then
                notify("Theme", tostring(Config.Theme) .. " · " .. tostring(reason or "applied"), 3, Theme.Accent, "palette")
            end
        end)
        rebuilding = false
    end)
end

local function farmStatus()
    local target = State.target
    local origin = myPosition()
    local distance = target and origin and math.floor(flatDistance(origin, target.position)) or 0
    local runtime = math.max(os.clock() - (State.startedAt or os.clock()), 0)
    local minutes = runtime / 60
    local function rate(count)
        if minutes < 0.05 then return "—" end
        return string.format("%.1f/min", count / minutes)
    end
    local function clock(seconds)
        return string.format("%02d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
    end
    return {
        { label = "state",  value = tostring(State.status) },
        { label = "target", value = target and (target.name .. " · " .. distance .. " studs") or "none" },
        { label = "session", value = clock(runtime) .. " · " .. tostring(State.kills) .. " kills · " .. rate(State.kills) },
        { label = "loot",   value = string.format("chest %d · fruit %d · drop %d", State.chests, State.fruits, State.drops) },
        { label = "rates",  value = string.format("attacks %s · loot %s", rate(State.hits), rate(State.chests + State.fruits + State.drops)) },
        { label = "travel", value = string.format("%d steps · %d studs", State.steps, math.floor(State.studs)) },
        { label = "mobs",   value = tostring(#World.mobs) .. " in " .. tostring(Config.ScanRange) .. " studs" },
    }
end

local function configStatus()
    return {
        { label = "file",      value = tostring(Config.ConfigPath) },
        { label = "profile",   value = "slot " .. tostring(Config.ProfileSlot) },
        { label = "saved",     value = tostring(State.savedAt or "never") },
        { label = "autosave",  value = Config.Autosave and "on · every 2 s" or "off" },
        { label = "autoload",  value = Config.Autoload and "on · interface keys only" or "off · nothing starts" },
        { label = "storage",   value = Store.hasFileApi() and "writefile / readfile" or "clipboard only" },
        { label = "window",    value = string.format("%d, %d px", tonumber(Config.UiX) or 0, tonumber(Config.UiY) or 0) },
        { label = "features",  value = tostring(featuresOn()) .. " on" },
    }
end

function buildTabs()
    local function toggle(tab, title, desc, key, icon)
        return tab:AddToggle(title, desc, Config[key] == true, function(state)
            Config[key] = state and true or false
            if key == "MobHitbox" and not state then Farm.restoreHitbox() end
        end, icon)
    end
    local function slider(tab, title, desc, low, high, key, suffix, icon, onChange)
        return tab:AddSlider(title, desc, low, high, Config[key], suffix, function(value)
            Config[key] = value
            if onChange then onChange(value) end
        end, icon)
    end
    local function dropdown(tab, title, desc, options, key, icon, onChange)
        return tab:AddDropdown(title, desc, options, Config[key], function(value)
            Config[key] = value
            if onChange then onChange(value) end
        end, icon)
    end
    local function button(tab, title, desc, callback, icon, danger)
        return tab:AddButton(title, desc, callback, icon, danger)
    end
    local function keybind(tab, title, desc, key, icon)
        return tab:AddKeybind(title, desc, tostring(Config[key]), function(value)
            Config[key] = tostring(value)
        end, icon)
    end

    -- ── Auto Farm ──────────────────────────────────────────────────────────
    local farm = makeTab("Auto Farm", "target, travel, fast attack, loot", "swords", Theme.Clay)
    farm:AddSection("The farm")
    toggle(farm, "Auto farm", "pick a target, travel to it, attack until it dies", "AutoFarm", "swords")
    dropdown(farm, "Farm mode", "which mob the picker prefers", { "Nearest mob", "Quest area", "Boss" }, "FarmMode", "mob")
    toggle(farm, "Auto attack", "fast attack on the current target", "AutoAttack", "spark")
    toggle(farm, "Mouse clicks", "adds a click; the tool is activated either way", "MouseClicks", "spark")
    slider(farm, "Attack rate", "seconds between attacks", 0.08, 0.6, "AttackRate", " s", "speed")
    slider(farm, "Attack range", "reach before the farm travels again", 6, 40, "AttackRange", " studs", "scale")

    farm:AddSection("Targeting")
    toggle(farm, "Kill aura", "attack every mob around you, not just the target", "KillAura", "aura")
    slider(farm, "Aura radius", "studs around the character", 6, 40, "AuraRadius", " studs", "aura")
    toggle(farm, "Bring mobs", "pull nearby mobs to your feet", "BringMobs", "magnet")
    slider(farm, "Bring radius", "how far the pull reaches", 20, 150, "BringRadius", " studs", "magnet")
    toggle(farm, "Mob hitbox", "scale mob hitboxes so melee connects", "MobHitbox", "hitbox")
    slider(farm, "Hitbox size", "multiplier on the mob's own parts", 1, 4, "HitboxSize", "×", "hitbox")
    toggle(farm, "Auto skill", "press Z · X · C · V on a cadence", "AutoSkill", "bolt")
    slider(farm, "Skill interval", "seconds between skills", 0.3, 3, "SkillInterval", " s", "loop")

    farm:AddSection("Loot")
    toggle(farm, "Auto chest", "open chests with their own proximity prompt", "AutoChest", "chest")
    toggle(farm, "Auto fruit", "walk onto a fruit that spawned nearby", "AutoFruit", "fruit")
    toggle(farm, "Auto drops", "collect money and drop parts", "AutoDrops", "coin")
    slider(farm, "Scan range", "how far the scanner looks for loot", 40, 600, "ScanRange", " studs", "eye")
    toggle(farm, "Auto quest", "talk to the quest NPC when it is close", "AutoQuest", "scroll")

    farm:AddSection("Travel")
    toggle(farm, "Paced travel", "move in steps instead of one teleport", "TweenTravel", "arrow")
    slider(farm, "Travel speed", "studs per second outside safe mode", 20, 300, "TravelSpeed", " studs/s", "speed")
    slider(farm, "Travel step", "hard cap on one step", 2, 40, "TravelStep", " studs", "scale")
    slider(farm, "Travel delay", "seconds between steps", 0.02, 0.4, "TravelDelay", " s", "loop")

    farm:AddSection("Live")
    farm:AddStatusPanel("Farm status", farmStatus, 150)

    -- ── Settings ───────────────────────────────────────────────────────────
    local THEME_TITLES = {
        "Porcelain — graphite", "Midnight — deep navy", "Obsidian — sharp amber",
        "Ivory — paper light", "Sakura — warm rose", "Forest — moss dark",
    }
    local THEME_BY_TITLE = {}
    for index, key in ipairs(THEME_ORDER) do THEME_BY_TITLE[THEME_TITLES[index]] = key end
    local settings = makeTab("Settings", "theme, config, keys, safety", "gear", Theme.Steel)
    settings:AddSection("Appearance")
    local palettes = NS.palettes or {}
    local themeEntries = {}
    for index, key in ipairs(THEME_ORDER) do
        local palette = palettes[key] or {}
        themeEntries[index] = {
            key = key,
            label = THEME_TITLES[index],
            short = key,
            bg = palette.BgSurface,
            text = palette.TextPrimary,
            accent = palette.Accent,
            accent2 = palette.Clay,
            accent3 = palette.Sky,
        }
    end
    settings:AddThemePicker("Theme", "six complete palettes — click a swatch, the window rebuilds",
        themeEntries, Config.Theme, function(key)
            Config.Theme = key
            applyTheme(key)
            rebuildInterface("theme")
        end)
    slider(settings, "UI scale", "scales text, icons and hit areas", 0.75, 1.3, "UiScale", "×", "scale", function(value)
        local window = getWindow()
        local screen = window and window.Screen
        if screen then
            for _, child in ipairs(screen:GetChildren()) do
                if child:IsA("UIScale") then child.Scale = value end
            end
        end
    end)

    toggle(settings, "Notifications", "toasts for saves, themes and profile actions", "NotifyActions", "bell")
    button(settings, "Reset window position", "put the window back in the centre", function()
        Config.UiX, Config.UiY = 0, 0
        local window = getWindow()
        if window and window.Root then
            window.Root.Position = UDim2.new(0.5, 0, 0.5, 0)
            if window.Shadow then window.Shadow.Position = UDim2.new(0.5, 6, 0.5, 8) end
        end
        notify("Window", "centred", 2, Theme.Accent, "scale")
    end, "scale")

    settings:AddSection("Config")
    toggle(settings, "Autosave", "write the config two seconds after it changes", "Autosave", "save")
    toggle(settings, "Load on start", "restore interface keys only — never a switch", "Autoload", "loop")
    button(settings, "Save config", "write every value to the config file", function()
        Store.save(true)
    end, "save")
    button(settings, "Load config", "read the file (or the clipboard) and apply it", function()
        Store.load(true)
    end, "folder")
    button(settings, "Reset defaults", "every switch back to OFF", function()
        Store.reset()
    end, "reset", true)
    button(settings, "Copy config", "put the JSON on the clipboard", function()
        Store.export()
    end, "copy", false)
    settings:AddInput("Import config", "paste JSON from another session", "{ ... }", function(text)
        Store.import(text)
    end, "folder")

    settings:AddSection("Profiles")
    dropdown(settings, "Profile slot", "three named slots beside the main config", { "1", "2", "3" }, "ProfileSlot", "book")
    button(settings, "Save profile", "write every value into the chosen slot", function()
        Store.saveProfile(Config.ProfileSlot)
    end, "save")
    button(settings, "Load profile", "read the chosen slot back", function()
        Store.loadProfile(Config.ProfileSlot)
        if Store.afterChange then pcall(Store.afterChange) end
    end, "folder")
    settings:AddStatusPanel("Config status", configStatus, 150)

    settings:AddSection("Keys")
    keybind(settings, "Show / hide window", "toggle the whole interface", "HideUiKey", "eye")
    keybind(settings, "Panic key", "turn every switch off", "PanicKey", "warning")
    button(settings, "Panic — turn everything off", "the same thing the panic key does", function()
        panic()
    end, "stop", true)

    settings:AddSection("Safety")
    toggle(settings, "Safe mode", "caps attack and travel rates", "SafeMode", "shield")
    slider(settings, "Speed cap", "the fastest safe mode will move you", 16, 120, "SpeedCap", " studs/s", "speed")
    toggle(settings, "Walk speed", "override the humanoid speed", "WalkSpeedEnabled", "speed")
    slider(settings, "Walk speed value", "studs per second", 16, 200, "WalkSpeed", " studs/s", "speed")
    toggle(settings, "Jump power", "override the humanoid jump", "JumpPowerEnabled", "arrow")
    slider(settings, "Jump power value", "jump power", 50, 300, "JumpPower", "", "arrow")

    return Tabs
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 16 · PANIC, KEYBINDS, DOCTOR
-- ═══════════════════════════════════════════════════════════════════════════
local function panic()
    for _, key in ipairs(FEATURE_KEYS) do Config[key] = false end
    Config.WalkSpeedEnabled, Config.JumpPowerEnabled = false, false
    pcall(Farm.restoreHitbox)
    for model in pairs(State.pending) do State.pending[model] = nil end
    for _, entry in ipairs(NS.controls) do
        if entry.kind == "toggle" then
            pcall(function() entry.api.set(false, true) end)
        end
    end
    notify("Panic", "everything is off", 4, Theme.Danger, "shield")
    State.status = "panic · idle"
    State.target = nil
    return true
end

local function toggleWindow()
    local window = getWindow()
    if not window or not window.Root then return false end
    local visible = window.Root.Visible ~= false
    window.Root.Visible = not visible
    Config.UiVisible = not visible
    if window.Screen then window.Screen.Enabled = true end
    return true
end

local function startKeys()
    if not UserInput then return false end
    UserInput.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not input or not input.KeyCode then return end
        local key = input.KeyCode.Name
        if key == tostring(Config.HideUiKey) then
            toggleWindow()
        elseif key == tostring(Config.PanicKey) then
            panic()
        end
    end)
    return true
end

local function doctor()
    local lines = {}
    local function row(label, value)
        lines[#lines + 1] = string.format("%-11s %s", label, tostring(value))
        print(string.format("[doctor] %-11s %s", label, tostring(value)))
    end
    row("build", META.version .. " / " .. META.build)
    row("window", (getWindow() and getWindow().Root) and "built" or "missing")
    row("tabs", tostring(#Tabs) .. " · " .. table.concat((function()
        local titles = {}
        for index, tab in ipairs(Tabs) do titles[index] = tab.title end
        return titles
    end)(), " / "))
    row("controls", tostring(#NS.controls) .. " cards / " .. tostring(NS.controlHealth.faults) .. " fault(s)")
    row("theme", tostring(Config.Theme) .. " · scale " .. tostring(Config.UiScale))
    row("farm", tostring(Config.AutoFarm and "ON" or "off") .. " · " .. tostring(State.status))
    row("mobs", tostring(#World.mobs) .. " / " .. tostring(#World.chests) .. " chests / " .. tostring(#World.fruits) .. " fruit")
    row("kills", tostring(State.kills) .. " · " .. tostring(State.hits) .. " attacks")
    row("beats", string.format("farm %s · move %s · config %s",
        tostring(State.beats.farm ~= nil), tostring(State.beats.movement ~= nil), tostring(State.beats.config ~= nil)))
    row("config", tostring(State.savedAt or "never") .. " · " .. (Store.hasFileApi() and "file" or "clipboard"))
    row("errors", tostring(#(SharedEnv.__SkillHubErrorLog or {})))
    return table.concat(lines, "\n")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 17 · BOOT — window, tabs, workers. Nothing is enabled, ever.
-- ═══════════════════════════════════════════════════════════════════════════
local function boot()
    local started = os.clock()
    Store.bootAutoload()           -- interface keys only, and only if asked
    -- a saved file is never overwritten by defaults on the first autosave tick
    Store.markCurrent()
    applyTheme(Config.Theme)
    if not NS.buildWindow() then
        print("[Skill Hub] the window could not be built; the farm still works from the API")
    end
    buildTabs()
    Farm.start()
    Store.start()
    startKeys()

    local names = {}
    for _, tab in ipairs(Tabs) do names[#names + 1] = tab.title end
    print(string.format("[Skill Hub] %s · %s · free build", META.game, META.version))
    print("[Skill Hub] tabs · " .. table.concat(names, " · "))
    print(string.format("[Skill Hub] switches · %d · all off · theme %s", #NS.controls, Config.Theme))
    print(string.format("[Skill Hub] ready in %.0f ms", (os.clock() - started) * 1000))
    if Config.NotifyActions then
        notify("Skill Hub", META.game .. " · " .. META.version .. " · nothing is enabled", 5, Theme.Accent, "crest")
    end
    return true
end

local function selfTest()
    local passed, total = 0, 0
    local function check(label, condition)
        total = total + 1
        if condition then passed = passed + 1 end
        print(string.format("[self-test] %s %-34s %s", condition and "PASS" or "FAIL", label, tostring(condition)))
    end
    check("version", META.version == "v1.1")
    check("two tabs", #Tabs == 2)
    check("farm tab first", Tabs[1] and Tabs[1].title == "Auto Farm")
    check("settings tab second", Tabs[2] and Tabs[2].title == "Settings")
    check("no feature is on", featuresOn() == 0)
    check("window built", getWindow() ~= nil and getWindow().Root ~= nil)
    check("controls registered", #NS.controls >= 25)
    check("theme applied", Theme.BgSurface ~= nil and Config.Theme ~= nil)
    check("theme count", #THEME_ORDER == 6)
    check("config serialises", type(Store.encode(Store.snapshot())) == "string")
    check("config roundtrip", (function()
        local text = Store.encode({ Theme = "Ivory", AutoFarm = false, AttackRate = 0.25 })
        local data = Store.decode(text)
        return data.Theme == "Ivory" and data.AutoFarm == false and math.abs(data.AttackRate - 0.25) < 0.0001
    end)())
    check("world scan runs", type(scanWorld(true)) == "table")
    check("error log empty", #(SharedEnv.__SkillHubErrorLog or {}) == 0)
    return passed, total
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 18 · EXPORT
-- ═══════════════════════════════════════════════════════════════════════════
do
    local ok, err = pcall(boot)
    if not ok then print("[Skill Hub] boot failed · " .. tostring(err)) end
end

local API = {
    version = META.version, build = META.build, game = META.game,
    config = Config, state = State, themes = THEME_ORDER,
    tabs = Tabs, tabTitles = function()
        local out = {}
        for index, tab in ipairs(Tabs) do out[index] = tab.title end
        return out
    end,
    controls = function() return NS.controls end,
    controlFaults = function() return NS.controlHealth.faults, NS.controlHealth.last end,
    window = function() return getWindow() end,
    scan = function(force) return scanWorld(force ~= false) end,
    world = World,
    pick = pickMob,
    travel = travelTo,
    attack = attackTarget,
    farmTick = Farm.tick,
    killAura = Farm.aura,
    bring = Farm.bring,
    hitbox = Farm.hitbox,
    restoreHitbox = Farm.restoreHitbox,
    chest = Farm.chest,
    fruit = Farm.fruit,
    drops = Farm.drops,
    quest = Farm.quest,
    status = function() return State.status end,
    farmStatus = function() return farmStatus() end,
    configStatus = function() return configStatus() end,
    featuresOn = featuresOn,
    save = function() return Store.save(true) end,
    saveProfile = function(slot) return Store.saveProfile(slot or Config.ProfileSlot) end,
    loadProfile = function(slot) return Store.loadProfile(slot or Config.ProfileSlot) end,
    profilePath = function(slot) return Store.profilePath(slot or Config.ProfileSlot) end,
    load = function() return Store.load(true) end,
    reset = function() return Store.reset() end,
    exportConfig = function() return Store.export() end,
    importConfig = function(text) return Store.import(text) end,
    encode = Store.encode, decode = Store.decode, snapshot = Store.snapshot,
    applyTheme = function(name)
        if not THEMES[name] then return false end
        Config.Theme = name
        applyTheme(name)
        rebuildInterface("api")
        return true
    end,
    theme = function() return Config.Theme, Theme.BgSurface end,
    palettes = function() return THEMES end,
    applySafe = function(data) return Store.apply(data, "safe") end,
    encodeConfig = function() return Store.encode(Store.snapshot()) end,
    rebuild = function() rebuildInterface("api") end,
    panic = panic,
    doctor = doctor,
    selfTest = selfTest,
    toggleWindow = toggleWindow,
    character = getChar,
    root = getRoot,
    alive = isAlive,
    destroy = function()
        State.alive = false
        pcall(Farm.restoreHitbox)
        if SharedEnv then SharedEnv.SkillHubFreeBloxFruit = nil end
        NS.resetInterface()
        return true
    end,
}

if SharedEnv then SharedEnv.SkillHubFreeBloxFruit = API end
if _G and _G ~= SharedEnv then _G.SkillHubFreeBloxFruit = API end

if SharedEnv and SharedEnv.__SKILLHUB_SELFTEST then
    selfTest()
end

return API
