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
        The Skill Hub farm for Blox Fruits, rebuilt around the outlined menu
        look: a glowing rim, group boxes with a hairline frame and an accent
        tick, checkbox rows whose state sits on the right, sliders with a live
        readout, and a bottom tab bar with the icon over the label. Two pages in
        two columns. Six complete themes, hand-drawn vector icons throughout.

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
        are paced on purpose and safe travel steps the character instead of
        teleporting; the "Unlock unsafe rates" switch removes those caps.

        Use an account you can afford to lose. That is not a disclaimer bolted
        on the end — it is the honest summary of what a client script can do.
]]

local META = {
    version = "v1.2",
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
    Theme               = "Aurora",
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
-- 2 · THEMES — six complete palettes
--     A theme is not a tint: surfaces, text, accents, hairline strength, the
--     glow around the window, and the corner radii all change. "Aurora" is the
--     default look (violet, outlined cards); "Verdant" is the green one;
--     "Obsidian" is nearly square and amber; three more for taste.
-- ═══════════════════════════════════════════════════════════════════════════
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local THEMES = {
    Aurora = {
        label = "Aurora · violet",
        BgApp = rgb(7, 5, 13), BgSurface = rgb(13, 9, 24), BgElevated = rgb(18, 13, 33),
        BgRaised = rgb(24, 18, 43), BgInset = rgb(9, 6, 18), BgHover = rgb(30, 23, 52),
        BgSidebar = rgb(11, 8, 21),
        Hairline = rgb(74, 56, 118), Stroke = rgb(52, 39, 84), StrokeSoft = rgb(38, 29, 62),
        TextPrimary = rgb(237, 233, 250), TextSecondary = rgb(168, 158, 198),
        TextMuted = rgb(122, 114, 152), TextFaint = rgb(86, 80, 112),
        OnAccent = rgb(12, 8, 22), Shadow = rgb(4, 2, 10),
        Glow = rgb(124, 82, 220),
        Accent = rgb(168, 123, 255), AccentSecondary = rgb(126, 208, 255),
        Iris = rgb(168, 123, 255), Clay = rgb(255, 138, 168), Sand = rgb(255, 196, 122),
        Sage = rgb(126, 224, 186), Mauve = rgb(198, 152, 255), Steel = rgb(150, 160, 200),
        Sky = rgb(126, 208, 255), Rose = rgb(232, 148, 196),
        Success = rgb(126, 224, 186), Warning = rgb(255, 196, 122), Danger = rgb(255, 120, 140),
        radius = { window = 16, panel = 12, card = 10, control = 8, chip = 6, pill = 999 },
    },
    Verdant = {
        label = "Verdant · green",
        BgApp = rgb(6, 11, 8), BgSurface = rgb(10, 17, 13), BgElevated = rgb(14, 23, 18),
        BgRaised = rgb(19, 31, 24), BgInset = rgb(7, 13, 10), BgHover = rgb(24, 38, 29),
        BgSidebar = rgb(8, 14, 11),
        Hairline = rgb(52, 96, 70), Stroke = rgb(36, 70, 50), StrokeSoft = rgb(26, 52, 38),
        TextPrimary = rgb(224, 238, 228), TextSecondary = rgb(148, 176, 156),
        TextMuted = rgb(104, 132, 112), TextFaint = rgb(74, 98, 82),
        OnAccent = rgb(5, 12, 8), Shadow = rgb(2, 5, 3),
        Glow = rgb(47, 224, 138),
        Accent = rgb(47, 224, 138), AccentSecondary = rgb(150, 230, 190),
        Iris = rgb(47, 224, 138), Clay = rgb(120, 220, 150), Sand = rgb(196, 226, 130),
        Sage = rgb(47, 224, 138), Mauve = rgb(150, 210, 190), Steel = rgb(130, 160, 142),
        Sky = rgb(110, 210, 180), Rose = rgb(170, 220, 190),
        Success = rgb(47, 224, 138), Warning = rgb(214, 214, 118), Danger = rgb(236, 110, 110),
        radius = { window = 12, panel = 10, card = 8, control = 6, chip = 5, pill = 999 },
    },
    Obsidian = {
        label = "Obsidian · amber",
        BgApp = rgb(5, 5, 5), BgSurface = rgb(11, 11, 11), BgElevated = rgb(17, 17, 17),
        BgRaised = rgb(24, 23, 21), BgInset = rgb(7, 7, 7), BgHover = rgb(30, 29, 26),
        BgSidebar = rgb(9, 9, 9),
        Hairline = rgb(80, 74, 58), Stroke = rgb(52, 48, 38), StrokeSoft = rgb(34, 32, 26),
        TextPrimary = rgb(245, 242, 234), TextSecondary = rgb(174, 166, 148),
        TextMuted = rgb(126, 119, 104), TextFaint = rgb(88, 83, 72),
        OnAccent = rgb(10, 9, 6), Shadow = rgb(0, 0, 0),
        Glow = rgb(232, 176, 88),
        Accent = rgb(232, 176, 88), AccentSecondary = rgb(180, 168, 142),
        Iris = rgb(232, 176, 88), Clay = rgb(220, 132, 96), Sand = rgb(232, 176, 88),
        Sage = rgb(164, 190, 122), Mauve = rgb(190, 150, 120), Steel = rgb(160, 156, 146),
        Sky = rgb(150, 176, 186), Rose = rgb(206, 142, 116),
        Success = rgb(150, 196, 116), Warning = rgb(232, 176, 88), Danger = rgb(214, 92, 84),
        radius = { window = 4, panel = 3, card = 2, control = 2, chip = 2, pill = 2 },
    },
    Ivory = {
        label = "Ivory · paper",
        BgApp = rgb(226, 224, 218), BgSurface = rgb(249, 247, 242), BgElevated = rgb(255, 255, 252),
        BgRaised = rgb(250, 248, 243), BgInset = rgb(236, 234, 228), BgHover = rgb(240, 238, 232),
        BgSidebar = rgb(241, 239, 233),
        Hairline = rgb(196, 192, 183), Stroke = rgb(214, 210, 201), StrokeSoft = rgb(226, 223, 215),
        TextPrimary = rgb(34, 34, 38), TextSecondary = rgb(88, 88, 96),
        TextMuted = rgb(122, 122, 130), TextFaint = rgb(160, 158, 152),
        OnAccent = rgb(252, 251, 248), Shadow = rgb(140, 136, 128),
        Glow = rgb(150, 148, 140),
        Accent = rgb(74, 84, 168), AccentSecondary = rgb(108, 112, 130),
        Iris = rgb(74, 84, 168), Clay = rgb(176, 92, 78), Sand = rgb(170, 130, 66),
        Sage = rgb(80, 132, 104), Mauve = rgb(122, 92, 160), Steel = rgb(96, 106, 120),
        Sky = rgb(66, 118, 156), Rose = rgb(158, 92, 128),
        Success = rgb(58, 138, 92), Warning = rgb(168, 124, 44), Danger = rgb(178, 70, 66),
        radius = { window = 14, panel = 10, card = 8, control = 6, chip = 5, pill = 999 },
    },
    Sakura = {
        label = "Sakura · rose",
        BgApp = rgb(238, 226, 228), BgSurface = rgb(252, 244, 245), BgElevated = rgb(255, 250, 250),
        BgRaised = rgb(250, 240, 242), BgInset = rgb(243, 231, 234), BgHover = rgb(248, 236, 238),
        BgSidebar = rgb(247, 236, 238),
        Hairline = rgb(214, 186, 192), Stroke = rgb(228, 204, 209), StrokeSoft = rgb(238, 218, 222),
        TextPrimary = rgb(48, 34, 38), TextSecondary = rgb(112, 84, 92),
        TextMuted = rgb(140, 110, 118), TextFaint = rgb(176, 148, 154),
        OnAccent = rgb(255, 250, 250), Shadow = rgb(150, 122, 128),
        Glow = rgb(226, 168, 184),
        Accent = rgb(168, 82, 112), AccentSecondary = rgb(150, 118, 128),
        Iris = rgb(168, 82, 112), Clay = rgb(188, 96, 96), Sand = rgb(186, 140, 96),
        Sage = rgb(96, 138, 110), Mauve = rgb(148, 96, 156), Steel = rgb(130, 112, 124),
        Sky = rgb(96, 128, 158), Rose = rgb(188, 92, 128),
        Success = rgb(72, 138, 100), Warning = rgb(172, 124, 60), Danger = rgb(184, 72, 84),
        radius = { window = 18, panel = 14, card = 12, control = 10, chip = 8, pill = 999 },
    },
    Midnight = {
        label = "Midnight · navy",
        BgApp = rgb(4, 7, 14), BgSurface = rgb(9, 14, 25), BgElevated = rgb(13, 20, 35),
        BgRaised = rgb(18, 27, 46), BgInset = rgb(6, 10, 19), BgHover = rgb(23, 34, 57),
        BgSidebar = rgb(7, 11, 21),
        Hairline = rgb(44, 61, 92), Stroke = rgb(33, 47, 71), StrokeSoft = rgb(24, 35, 54),
        TextPrimary = rgb(232, 241, 255), TextSecondary = rgb(139, 160, 194),
        TextMuted = rgb(96, 116, 148), TextFaint = rgb(66, 83, 110),
        OnAccent = rgb(4, 8, 16), Shadow = rgb(1, 2, 5),
        Glow = rgb(96, 176, 255),
        Accent = rgb(96, 176, 255), AccentSecondary = rgb(140, 168, 210),
        Iris = rgb(96, 176, 255), Clay = rgb(120, 190, 255), Sand = rgb(150, 206, 255),
        Sage = rgb(96, 214, 196), Mauve = rgb(166, 156, 255), Steel = rgb(132, 162, 200),
        Sky = rgb(96, 176, 255), Rose = rgb(190, 158, 240),
        Success = rgb(86, 210, 168), Warning = rgb(230, 190, 120), Danger = rgb(240, 120, 130),
        radius = { window = 14, panel = 10, card = 8, control = 6, chip = 5, pill = 999 },
    },
}

local THEME_ORDER = { "Aurora", "Verdant", "Obsidian", "Ivory", "Sakura", "Midnight" }

local Theme = {}
local RADIUS = {}
local function applyTheme(name)
    local palette = THEMES[name] or THEMES.Aurora
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

local function iconTile(parent, kind, accent, sizePx, position, zIndex, bare)
    local holder = new("Frame", {
        BackgroundColor3 = tint(accent, 0.86),
        BackgroundTransparency = bare and 1 or 0,
        BorderSizePixel = 0,
        Position = position,
        Size = UDim2.new(0, sizePx, 0, sizePx),
        ZIndex = zIndex or 5,
    }, parent)
    corner(holder, math.floor(sizePx * 0.3))
    if not bare then hairline(holder, tint(accent, 0.5), 1, 0.5) end
    drawVectorGlyph(holder, kind, accent, sizePx * 0.54, (zIndex or 5) + 1)
    return holder
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 4 · TOASTS  (top-right stack, draining progress hairline)
-- ═══════════════════════════════════════════════════════════════════════════-- ═══════════════════════════════════════════════════════════════════════════
-- 4 · TOASTS  (top-right stack, accent edge, draining hairline)
-- ═══════════════════════════════════════════════════════════════════════════
local Window, Body, PageHolder, Toast, ActiveTab
local TOAST = { order = 0, holder = nil }
local Tabs = {}
local ToggleRegistry = {}

local function notify(title, message, duration, accent, iconKind)
    if not TOAST.holder then return end
    duration = duration or 4
    accent = accent or Theme.Accent

    local card = new("Frame", {
        BackgroundColor3 = Theme.BgElevated, BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -318, 0, 16),
        Size = UDim2.new(0, 302, 0, message and 64 or 46),
        ZIndex = 60,
    }, TOAST.holder)
    corner(card, RADIUS.card)
    hairline(card, accent, 1, 0.55)

    local bar = new("Frame", {
        BackgroundColor3 = accent, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 10), Size = UDim2.new(0, 3, 0, message and 44 or 26),
        ZIndex = 61,
    }, card)
    corner(bar, RADIUS.pill)

    iconTile(card, iconKind or "crest", accent, 22, UDim2.new(0, 16, 0, 12), 61)

    Text({
        Font = FONT.Bold, Position = UDim2.new(0, 48, 0, 11), Size = UDim2.new(1, -60, 0, 14),
        Text = tostring(title), TextColor3 = Theme.TextPrimary, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 61,
    }, card)
    if message then
        Text({
            Position = UDim2.new(0, 48, 0, 28), Size = UDim2.new(1, -60, 0, 28),
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
            SafeTween(drain, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
        end)
        task.wait(duration)
        safeCall("toast remove", function()
            SafeTween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
            task.wait(0.2)
            card:Destroy()
        end)
    end)
    return card
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 4b · CONTROL HEALTH — every row reports in, every callback is guarded
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
-- 5 · WINDOW FRAMEWORK
--     Layout: a title bar on top, the content in the middle, and the tabs in a
--     bottom bar with an icon over a label (the two tabs are the only pages).
--     The default palette draws every group as an outlined panel with rows.
-- ═══════════════════════════════════════════════════════════════════════════
local WINDOW_W, WINDOW_H = 840, 600
local TOPBAR_H, NAVBAR_H = 54, 58

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
    new("UIScale", { Scale = clamp(tonumber(Config.UiScale) or 1, 0.75, 1.3) }, screen)

    Toast = new("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(0, 326, 1, 0),
        Position = UDim2.new(1, -342, 0, 0), ZIndex = 59,
    }, screen)
    new("UIListLayout", {
        Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder,
    }, Toast)
    TOAST.holder = Toast

    -- the halo: an accent frame a few pixels larger than the window, almost
    -- transparent, which is what gives the outlined look its glow
    local glowFrame = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Glow,
        BackgroundTransparency = 0.9, BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, WINDOW_W + 14, 0, WINDOW_H + 14), ZIndex = 1,
    }, screen)
    corner(glowFrame, RADIUS.window + 8)

    local shadow = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Shadow,
        BackgroundTransparency = 0.35, BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 5),
        Size = UDim2.new(0, WINDOW_W + 2, 0, WINDOW_H + 2), ZIndex = 2,
    }, screen)
    corner(shadow, RADIUS.window + 2)

    local root = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.BgSurface, BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H), ZIndex = 3,
    }, screen)
    corner(root, RADIUS.window)
    local rootStroke = hairline(root, Theme.Hairline, 1, 0.35)

    Window = { Screen = screen, Root = root, Shadow = shadow, Glow = glowFrame, Stroke = rootStroke, Minimized = false }

    -- where the player dragged the window last time (0, 0 = centred)
    local savedX = tonumber(Config.UiX) or 0
    local savedY = tonumber(Config.UiY) or 0
    if savedX ~= 0 or savedY ~= 0 then
        root.Position = UDim2.new(0.5, savedX, 0.5, savedY)
        shadow.Position = UDim2.new(root.Position.X.Scale, root.Position.X.Offset + 0,
            root.Position.Y.Scale, root.Position.Y.Offset + 5)
        glowFrame.Position = root.Position
    end

    -- ── title bar ────────────────────────────────────────────────────────────
    local topbar = new("Frame", {
        BackgroundColor3 = Theme.BgElevated, BackgroundTransparency = 0.15, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, TOPBAR_H), ZIndex = 4,
    }, root)
    corner(topbar, RADIUS.window)
    new("Frame", {
        BackgroundColor3 = Theme.BgSurface, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -12), Size = UDim2.new(1, 0, 0, 12), ZIndex = 4,
    }, topbar)
    new("Frame", {
        BackgroundColor3 = Theme.StrokeSoft, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), ZIndex = 5,
    }, topbar)
    new("Frame", {
        BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.25, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 2), ZIndex = 6,
    }, topbar)

    local crest = iconTile(topbar, ICON.Crest, Theme.Accent, 26, UDim2.new(0, 14, 0.5, -13), 7)
    Window.HeaderIcon = crest
    Text({
        Font = FONT.Bold, Position = UDim2.new(0, 50, 0, 11), Size = UDim2.new(0, 220, 0, 16),
        Text = "Skill Hub", TextColor3 = Theme.TextPrimary, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, topbar)
    local headerTitle = Text({
        Position = UDim2.new(0, 50, 0, 29), Size = UDim2.new(0, 240, 0, 14),
        Text = META.game .. " · " .. META.version, TextColor3 = Theme.TextMuted,
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, topbar)
    local headerDesc = headerTitle

    -- search
    local searchShell = new("Frame", {
        BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
        Position = UDim2.new(1, -246, 0.5, -12), Size = UDim2.new(0, 132, 0, 24), ZIndex = 6,
    }, topbar)
    corner(searchShell, RADIUS.chip)
    hairline(searchShell, Theme.StrokeSoft, 1, 0.4)
    iconTile(searchShell, ICON.Search, Theme.TextMuted, 13, UDim2.new(0, 6, 0.5, -6.5), 7, true)
    local searchBox = new("TextBox", {
        BackgroundTransparency = 1, Font = FONT.UI, PlaceholderText = "search…",
        PlaceholderColor3 = Theme.TextFaint, Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -30, 1, 0),
        Text = "", TextColor3 = Theme.TextPrimary, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 7,
    }, searchShell)

    -- chips
    local chips = {}
    local chipHolder = new("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -400, 0.5, -10),
        Size = UDim2.new(0, 150, 0, 20), ZIndex = 6,
    }, topbar)
    new("UIListLayout", {
        Padding = UDim.new(0, 4), FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center,
    }, chipHolder)
    local function makeChip(label, width)
        local chip = new("Frame", {
            BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
            Size = UDim2.new(0, width or 40, 0, 18), ZIndex = 6,
        }, chipHolder)
        corner(chip, RADIUS.chip)
        hairline(chip, Theme.StrokeSoft, 1, 0.4)
        local text = Text({
            Font = FONT.Mono, Size = UDim2.new(1, 0, 1, 0), Text = label,
            TextColor3 = Theme.TextSecondary, TextSize = 8, ZIndex = 7,
        }, chip)
        return chip, text
    end
    chips.state, chips.stateText = makeChip("IDLE", 38)
    chips.ac, chips.acText = makeChip("0", 52)
    chips.perf, chips.perfText = makeChip("0", 52)

    local function ghostButton(name, x, glyph, callback)
        local button = new("TextButton", {
            Name = name, AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.new(1, x, 0.5, -10), Size = UDim2.new(0, 20, 0, 20), Text = "", ZIndex = 8,
        }, topbar)
        local bars = {}
        local function bar(width, height, px, py, rotation)
            local piece = new("Frame", {
                BackgroundColor3 = Theme.TextMuted, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, px, 0.5, py),
                Size = UDim2.new(0, width, 0, height), Rotation = rotation or 0, ZIndex = 9,
            }, button)
            corner(piece, 1)
            bars[#bars + 1] = piece
            return piece
        end
        glyph(bar)
        button.MouseEnter:Connect(function()
            for _, piece in ipairs(bars) do piece.BackgroundColor3 = Theme.TextPrimary end
        end)
        button.MouseLeave:Connect(function()
            for _, piece in ipairs(bars) do piece.BackgroundColor3 = Theme.TextMuted end
        end)
        button.MouseButton1Click:Connect(callback)
        return button
    end

    ghostButton("Minimise", -52, function(bar)
        bar(10, 1.5)
    end, function()
        Window.Minimized = not Window.Minimized
        local goal = Window.Minimized and TOPBAR_H or WINDOW_H
        safeCall("minimize", function()
            SafeTween(root, TweenInfo.new(0.18, Enum.EasingStyle.Quart), { Size = UDim2.new(0, WINDOW_W, 0, goal) }):Play()
            SafeTween(shadow, TweenInfo.new(0.18, Enum.EasingStyle.Quart), { Size = UDim2.new(0, WINDOW_W + 2, 0, goal + 2) }):Play()
            SafeTween(glowFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quart), { Size = UDim2.new(0, WINDOW_W + 14, 0, goal + 14) }):Play()
        end)
        Body.Visible = not Window.Minimized
    end)
    ghostButton("Close", -28, function(bar)
        bar(10, 1.5, 0, 0, 45)
        bar(10, 1.5, 0, 0, -45)
    end, function()
        Config.UiVisible = false
        root.Visible = false
        glowFrame.Visible = false
        shadow.Visible = false
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
                glowFrame.Position = root.Position
                shadow.Position = UDim2.new(root.Position.X.Scale, root.Position.X.Offset,
                    root.Position.Y.Scale, root.Position.Y.Offset + 5)
            end
        end)
    end

    -- ── body: pages ─────────────────────────────────────────────────────────
    Body = new("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, TOPBAR_H),
        Size = UDim2.new(1, 0, 1, -(TOPBAR_H + NAVBAR_H)), ZIndex = 4,
    }, root)

    PageHolder = new("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 4,
    }, Body)

    -- ── bottom navigation: an icon over a label, accent underline when active ─
    local nav = new("Frame", {
        BackgroundColor3 = Theme.BgElevated, BackgroundTransparency = 0.1, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -NAVBAR_H), Size = UDim2.new(1, 0, 0, NAVBAR_H), ZIndex = 5,
    }, root)
    corner(nav, RADIUS.window)
    new("Frame", {
        BackgroundColor3 = Theme.BgSurface, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 10), ZIndex = 5,
    }, nav)
    new("Frame", {
        BackgroundColor3 = Theme.StrokeSoft, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 1), ZIndex = 6,
    }, nav)

    local navList = new("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 6, 0, 0),
        Size = UDim2.new(1, -240, 1, 0), ZIndex = 6,
    }, nav)
    new("UIListLayout", {
        Padding = UDim.new(0, 4), FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
    }, navList)

    local navRight = Text({
        Font = FONT.Mono, Position = UDim2.new(1, -230, 0, 12), Size = UDim2.new(0, 218, 0, 12),
        Text = "", TextColor3 = Theme.TextMuted, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7,
    }, nav)
    local navHint = Text({
        Font = FONT.Mono, Position = UDim2.new(1, -230, 0, 30), Size = UDim2.new(0, 218, 0, 12),
        Text = Config.HideUiKey .. " hide · " .. Config.PanicKey .. " panic",
        TextColor3 = Theme.TextFaint, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7,
    }, nav)

    if searchBox then
        -- the search box filters rows, not tabs: a panel hides when none of
        -- its rows match, and a row hides when its title and description do
        -- not contain the query. Empty box = everything back.
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            CONTROLS.tick("search", function()
                local query = string.lower(searchBox.Text or "")
                for _, tab in ipairs(Tabs) do
                    local tabMatches = 0
                    for _, panel in ipairs(tab.panels) do
                        local panelMatches = 0
                        local titleHit = #query > 0 and string.find(panel.title, query, 1, true) ~= nil
                        for _, entry in ipairs(panel.index) do
                            local hit = #query == 0 or titleHit or string.find(entry.text, query, 1, true) ~= nil
                            entry.frame.Visible = hit
                            if hit then panelMatches = panelMatches + 1 end
                        end
                        -- a panel with no indexed row (the swatches) lives or dies by its title
                        if #panel.index == 0 then
                            panel.frame.Visible = #query == 0 or titleHit
                        else
                            panel.frame.Visible = panelMatches > 0
                        end
                        if panel.frame.Visible then tabMatches = tabMatches + 1 end
                    end
                    tab.matches = tabMatches
                end
                if #query > 0 and ActiveTab and (ActiveTab.matches or 0) == 0 then
                    for _, tab in ipairs(Tabs) do
                        if (tab.matches or 0) > 0 then tab.Select() break end
                    end
                end
            end)
        end)
    end

    Window.HeaderTitle = headerTitle
    Window.HeaderDesc = headerDesc
    Window.Topbar = topbar
    Window.Nav = nav
    Window.NavList = navList
    Window.Chrome = { chips = chips, strip = navRight, hint = navHint, header = headerTitle }
    return screen
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 6 · TABS — a bottom-bar item, a page with two columns, and the row widgets
-- ═══════════════════════════════════════════════════════════════════════════
local function makeTab(title, desc, iconKind, accent)
    Window.tabOrder = (Window.tabOrder or 0) + 1
    accent = accent or Theme.Accent

    local button = new("TextButton", {
        AutoButtonColor = false, BackgroundColor3 = Theme.BgRaised, BackgroundTransparency = 1,
        BorderSizePixel = 0, LayoutOrder = Window.tabOrder,
        Size = UDim2.new(0, 132, 0, 48), Text = "", ZIndex = 7,
    }, Window.NavList)
    corner(button, RADIUS.chip)

    local underline = new("Frame", {
        BackgroundColor3 = accent, BorderSizePixel = 0,
        Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(1, -36, 0, 2), ZIndex = 8,
    }, button)
    corner(underline, RADIUS.pill)
    underline.Visible = false

    local tile = iconTile(button, iconKind, accent, 18, UDim2.new(0.5, -9, 0, 8), 8, true)
    local label = Text({
        Font = FONT.Bold, Position = UDim2.new(0, 0, 0, 31), Size = UDim2.new(1, 0, 0, 12),
        Text = title, TextColor3 = Theme.TextMuted, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 9,
    }, button)

    -- a page is two columns of panels; the second column is used when the tab
    -- has more controls than fit comfortably in one
    local page = new("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, ZIndex = 5,
    }, PageHolder)

    local columns = {}
    for index = 1, 2 do
        local column = new("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.new((index - 1) * 0.5, 0, 0, 0),
            Size = UDim2.new(0.5, 0, 1, 0),
            ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Stroke,
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 5,
        }, page)
        new("UIListLayout", {
            Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
        }, column)
        local leftPad = index == 1 and 12 or 5
        local rightPad = index == 1 and 5 or 12
        new("UIPadding", {
            PaddingLeft = UDim.new(0, leftPad), PaddingRight = UDim.new(0, rightPad),
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 14),
        }, column)
        columns[index] = column
    end

    local tab = {
        title = title, desc = desc, color = accent, icon = iconKind,
        page = page, button = button, label = label, pill = underline, tile = tile,
        columns = columns, column = 1,
        order = 0, searchIndex = {}, toggles = {}, panels = {},
    }

    local function select()
        if ActiveTab == tab then return end
        for _, other in ipairs(Tabs) do
            other.page.Visible = false
            other.pill.Visible = false
            other.label.TextColor3 = Theme.TextMuted
            other.button.BackgroundTransparency = 1
        end
        ActiveTab = tab
        tab.page.Visible = true
        tab.pill.Visible = true
        tab.label.TextColor3 = tab.color
        tab.button.BackgroundTransparency = 0.82
        tab.button.BackgroundColor3 = tint(tab.color, 0.86)
        Window.HeaderTitle.Text = META.game .. " · " .. META.version .. " · " .. tab.title
        safeCall("header icon", function()
            local holder = Window.HeaderIcon
            if not holder then return end
            for _, child in ipairs(holder:GetChildren()) do
                if child.ClassName ~= "UICorner" and child.ClassName ~= "UIStroke" then child:Destroy() end
            end
            holder.BackgroundColor3 = tint(tab.color, 0.86)
            drawVectorGlyph(holder, tab.icon, tab.color, 26 * 0.54, 8)
        end)
    end

    button.MouseEnter:Connect(function()
        if ActiveTab ~= tab then button.BackgroundTransparency = 0.75 end
    end)
    button.MouseLeave:Connect(function()
        if ActiveTab ~= tab then button.BackgroundTransparency = 1 end
    end)
    button.MouseButton1Click:Connect(select)
    tab.Select = select

    local function nextOrder()
        tab.order = tab.order + 1
        return tab.order
    end

    -- which column the next panel goes into
    function tab:UseColumn(index)
        tab.column = (index == 2) and 2 or 1
        return tab
    end

    -- ── panels ───────────────────────────────────────────────────────────────
    function tab:AddPanel(title, columnIndex)
        local column = tab.columns[(columnIndex == 2) and 2 or (columnIndex or tab.column)]
        local panel = new("Frame", {
            BackgroundColor3 = Theme.BgElevated, BackgroundTransparency = 0.12, BorderSizePixel = 0,
            LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 6,
        }, column)
        corner(panel, RADIUS.panel)
        hairline(panel, Theme.StrokeSoft, 1, 0.35)
        new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
        new("UIPadding", {
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9),
        }, panel)

        local head = new("Frame", {
            BackgroundTransparency = 1, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 22), ZIndex = 7,
        }, panel)
        new("Frame", {
            BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 4), Size = UDim2.new(0, 3, 0, 12), ZIndex = 8,
        }, head)
        Text({
            Font = FONT.Bold, Position = UDim2.new(0, 10, 0, 1), Size = UDim2.new(1, -10, 0, 16),
            Text = string.upper(title), TextColor3 = Theme.TextSecondary, TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
        }, head)
        new("Frame", {
            BackgroundColor3 = Theme.StrokeSoft, BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), ZIndex = 7,
        }, head)

        local rowOrder = 0
        local panelApi = { frame = panel, title = title, rows = {}, index = {} }
        local function nextRow()
            rowOrder = rowOrder + 1
            return rowOrder
        end
        local function addRow(height, key)
            local row = new("Frame", {
                BackgroundColor3 = Theme.BgRaised, BackgroundTransparency = 1, BorderSizePixel = 0,
                LayoutOrder = nextRow(), Size = UDim2.new(1, 0, 0, height), ZIndex = 7,
            }, panel)
            corner(row, RADIUS.chip)
            new("Frame", {
                BackgroundColor3 = Theme.StrokeSoft, BackgroundTransparency = 0.4, BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), ZIndex = 7,
            }, row)
            table.insert(panelApi.rows, row)
            if key then
                table.insert(panelApi.index, { frame = row, text = string.lower(key) })
            end
            return row
        end

        function panelApi:AddCheckbox(rowTitle, rowDesc, value, callback)
            local row = addRow(30, rowTitle .. " " .. (rowDesc or ""))
            local state = value and true or false
            local box = new("Frame", {
                BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
                Position = UDim2.new(0, 2, 0.5, -7), Size = UDim2.new(0, 14, 0, 14), ZIndex = 8,
            }, row)
            corner(box, 3)
            local boxStroke = hairline(box, Theme.Stroke, 1, 0.25)
            local checkA = new("Frame", {
                BackgroundColor3 = Theme.OnAccent, BorderSizePixel = 0,
                Position = UDim2.new(0.5, -5, 0.5, -1), Size = UDim2.new(0, 6, 0, 2), Rotation = 45, ZIndex = 9,
            }, box)
            local checkB = new("Frame", {
                BackgroundColor3 = Theme.OnAccent, BorderSizePixel = 0,
                Position = UDim2.new(0.5, 1, 0.5, 0), Size = UDim2.new(0, 4, 0, 2), Rotation = -45, ZIndex = 9,
            }, box)
            local text = Text({
                Font = FONT.UI, Position = UDim2.new(0, 26, 0, 0), Size = UDim2.new(1, -86, 1, 0),
                Text = rowTitle, TextColor3 = Theme.TextSecondary, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8,
            }, row)
            local valueLabel = Text({
                Font = FONT.Mono, Position = UDim2.new(1, -62, 0, 0), Size = UDim2.new(0, 60, 1, 0),
                Text = "OFF", TextColor3 = Theme.TextFaint, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 8,
            }, row)
            local click = new("TextButton", {
                BackgroundTransparency = 1, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0), Text = "", ZIndex = 9,
            }, row)

            local api = {}
            local function render()
                box.BackgroundColor3 = state and Theme.Accent or Theme.BgInset
                boxStroke.Color = state and Theme.Accent or Theme.Stroke
                checkA.Visible = state
                checkB.Visible = state
                text.TextColor3 = state and Theme.TextPrimary or Theme.TextSecondary
                valueLabel.Text = state and "ON" or "OFF"
                valueLabel.TextColor3 = state and Theme.Accent or Theme.TextFaint
            end
            local function commit(target)
                state = target
                render()
                CONTROLS.spawnWith("toggle · " .. rowTitle, callback, function()
                    state = not target
                    render()
                    CONTROLS.run("toggle · " .. rowTitle .. " (revert)", callback, not target)
                end, target)
            end
            click.MouseButton1Click:Connect(function() commit(not state) end)
            click.MouseEnter:Connect(function() row.BackgroundTransparency = 0.72 end)
            click.MouseLeave:Connect(function() row.BackgroundTransparency = 1 end)

            function api.Set(v, silent)
                local target = v and true or false
                if silent then
                    state = target
                    render()
                else
                    commit(target)
                end
            end
            function api.Get() return state end
            render()

            table.insert(tab.searchIndex, rowTitle)
            tab.toggles = tab.toggles or {}
            table.insert(tab.toggles, api)
            table.insert(ToggleRegistry, { title = rowTitle, tab = tab, set = api.Set, get = api.Get })
            CONTROLS.register("toggle", rowTitle, tab, { set = api.Set, get = api.Get })
            return api
        end

        function panelApi:AddSlider(rowTitle, low, high, value, suffix, callback, formatText)
            local row = addRow(44, rowTitle)
            local current = clamp(tonumber(value) or low, low, high)
            local function fmt(v)
                if formatText then return formatText(v) end
                return tostring(round(v, 2)) .. (suffix or "")
            end
            Text({
                Font = FONT.UI, Position = UDim2.new(0, 2, 0, 2), Size = UDim2.new(1, -80, 0, 16),
                Text = rowTitle, TextColor3 = Theme.TextSecondary, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
            }, row)
            local readout = Text({
                Font = FONT.Mono, Position = UDim2.new(1, -72, 0, 1), Size = UDim2.new(0, 70, 0, 16),
                Text = fmt(current), TextColor3 = Theme.Accent, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 8,
            }, row)
            local track = new("Frame", {
                BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
                Position = UDim2.new(0, 2, 0, 27), Size = UDim2.new(1, -4, 0, 4), ZIndex = 8,
            }, row)
            corner(track, 2)
            local fill = new("Frame", {
                BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
                Size = UDim2.new(0, 0, 1, 0), ZIndex = 9,
            }, track)
            corner(fill, 2)
            local knob = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.TextPrimary,
                BorderSizePixel = 0, Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 9, 0, 9), ZIndex = 10,
            }, track)
            corner(knob, 2)
            local hit = new("TextButton", {
                BackgroundTransparency = 1, BorderSizePixel = 0, Text = "",
                Position = UDim2.new(0, -4, 0, -8), Size = UDim2.new(1, 8, 0, 26), ZIndex = 10,
            }, row)

            local function render()
                local alpha = (current - low) / math.max(high - low, 0.0001)
                fill.Size = UDim2.new(alpha, 0, 1, 0)
                knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                readout.Text = fmt(current)
            end
            local function setFromX(x)
                local origin = tonumber(track.AbsolutePosition and track.AbsolutePosition.X) or 0
                local width = tonumber(track.AbsoluteSize and track.AbsoluteSize.X) or 0
                if width <= 0 then return end
                local rel = clamp((x - origin) / width, 0, 1)
                current = low + (high - low) * rel
                if high - low > 40 then current = math.floor(current + 0.5) else current = round(current, 2) end
                render()
                CONTROLS.run("slider · " .. rowTitle, callback, current)
            end
            local dragging = false
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
            render()

            local api = {
                Set = function(v)
                    current = clamp(tonumber(v) or low, low, high)
                    render()
                    CONTROLS.run("slider · " .. rowTitle, callback, current)
                end,
                Get = function() return current end,
            }
            table.insert(tab.searchIndex, rowTitle)
            CONTROLS.register("slider", rowTitle, tab, { set = api.Set, get = api.Get })
            return api
        end

        function panelApi:AddDropdown(rowTitle, options, value, callback)
            local row = addRow(30, rowTitle)
            Text({
                Font = FONT.UI, Position = UDim2.new(0, 2, 0, 0), Size = UDim2.new(1, -140, 1, 0),
                Text = rowTitle, TextColor3 = Theme.TextSecondary, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
            }, row)
            local current = value or options[1]
            local selector = new("TextButton", {
                AutoButtonColor = false, BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
                Position = UDim2.new(1, -124, 0.5, -10), Size = UDim2.new(0, 122, 0, 20), Text = "", ZIndex = 9,
            }, row)
            corner(selector, RADIUS.chip)
            hairline(selector, Theme.StrokeSoft, 1, 0.35)
            local selectorText = Text({
                Font = FONT.Mono, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -26, 1, 0),
                Text = tostring(current), TextColor3 = Theme.TextSecondary, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 10,
            }, selector)
            for index = 1, 2 do
                local bar = new("Frame", {
                    BackgroundColor3 = Theme.TextFaint, BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(1, -15 + (index - 1) * 4, 0.5, 0),
                    Size = UDim2.new(0, 5, 0, 1.5), Rotation = index == 1 and 45 or -45, ZIndex = 10,
                }, selector)
                corner(bar, 1)
            end

            -- the list is a sibling right after the row so the panel grows
            local list = new("Frame", {
                BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0, Visible = false,
                LayoutOrder = rowOrder + 1, Size = UDim2.new(1, 0, 0, 0), ZIndex = 20,
            }, panel)
            corner(list, RADIUS.chip)
            new("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }, list)
            new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, list)
            nextRow()  -- the list owns this slot

            local expanded = false
            local function close()
                expanded = false
                list.Visible = false
                list.Size = UDim2.new(1, 0, 0, 0)
                if CONTROLS.open == close then CONTROLS.open = nil end
            end
            local api = {}
            local function addRows()
                for _, child in ipairs(list:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for index, option in ipairs(options) do
                    local item = new("TextButton", {
                        AutoButtonColor = false, BackgroundTransparency = 1, Font = FONT.UI,
                        LayoutOrder = index, Size = UDim2.new(1, 0, 0, 20),
                        Text = "  " .. tostring(option), TextColor3 = Theme.TextSecondary, TextSize = 10,
                        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21,
                    }, list)
                    item.MouseEnter:Connect(function() item.BackgroundTransparency = 0.8 end)
                    item.MouseLeave:Connect(function() item.BackgroundTransparency = 1 end)
                    item.MouseButton1Click:Connect(function()
                        current = option
                        selectorText.Text = tostring(option)
                        close()
                        CONTROLS.spawn("dropdown · " .. rowTitle, callback, option)
                    end)
                end
            end
            function api.SetOptions(newOptions, keep)
                options = newOptions
                addRows()
                if not keep and newOptions[1] then current = newOptions[1] end
            end
            api.SetOptions(options, true)
            api.Get = function() return current end
            api.Set = function(option)
                current = option
                selectorText.Text = tostring(option)
                close()
                CONTROLS.spawn("dropdown · " .. rowTitle, callback, option)
            end
            selector.MouseButton1Click:Connect(function()
                if CONTROLS.open and CONTROLS.open ~= close then CONTROLS.open() end
                expanded = not expanded
                if not expanded then close() return end
                CONTROLS.open = close
                list.Visible = true
                list.Size = UDim2.new(1, 0, 0, math.min(#options, 6) * 21 + 8)
            end)

            table.insert(tab.searchIndex, rowTitle)
            CONTROLS.register("dropdown", rowTitle, tab, { set = api.Set, get = api.Get, options = options })
            return api
        end

        function panelApi:AddButton(rowTitle, callback, danger)
            local row = addRow(30, rowTitle)
            local button = new("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = danger and tint(Theme.Danger, 0.82) or tint(Theme.Accent, 0.84),
                BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 2),
                Size = UDim2.new(1, 0, 0, 26), Text = rowTitle,
                Font = FONT.Bold, TextColor3 = danger and Theme.Danger or Theme.Accent, TextSize = 10,
                ZIndex = 8,
            }, row)
            corner(button, RADIUS.chip)
            button.MouseEnter:Connect(function() button.BackgroundTransparency = 0.15 end)
            button.MouseLeave:Connect(function() button.BackgroundTransparency = 0 end)
            button.MouseButton1Click:Connect(function()
                CONTROLS.spawn("button · " .. rowTitle, callback)
                notify(rowTitle, "executed", 2, danger and Theme.Danger or Theme.Accent, "spark")
            end)
            table.insert(tab.searchIndex, rowTitle)
            CONTROLS.register("button", rowTitle, tab, {
                press = function() CONTROLS.spawn("button · " .. rowTitle, callback) end,
            })
            return button
        end

        function panelApi:AddInput(rowTitle, placeholder, callback)
            local row = addRow(30, rowTitle)
            Text({
                Font = FONT.UI, Position = UDim2.new(0, 2, 0, 0), Size = UDim2.new(1, -160, 1, 0),
                Text = rowTitle, TextColor3 = Theme.TextSecondary, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
            }, row)
            local shell = new("Frame", {
                BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
                Position = UDim2.new(1, -146, 0.5, -10), Size = UDim2.new(0, 144, 0, 20), ZIndex = 9,
            }, row)
            corner(shell, RADIUS.chip)
            local stroke = hairline(shell, Theme.StrokeSoft, 1, 0.35)
            local box = new("TextBox", {
                BackgroundTransparency = 1, ClearTextOnFocus = false, Font = FONT.Mono,
                PlaceholderText = placeholder or "…", PlaceholderColor3 = Theme.TextFaint,
                Position = UDim2.new(0, 7, 0, 0), Size = UDim2.new(1, -12, 1, 0),
                Text = "", TextColor3 = Theme.TextPrimary, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10,
            }, shell)
            local function commit()
                if box.Text and #box.Text > 0 then CONTROLS.spawn("input · " .. rowTitle, callback, box.Text) end
            end
            box.FocusLost:Connect(function()
                stroke.Color = Theme.StrokeSoft
                commit()
            end)
            box.Focused:Connect(function() stroke.Color = Theme.Accent end)

            table.insert(tab.searchIndex, rowTitle)
            CONTROLS.register("input", rowTitle, tab, {
                get = function() return box.Text end,
                commit = function(text)
                    if text ~= nil then box.Text = tostring(text) end
                    commit()
                end,
            })
            return box
        end

        function panelApi:AddKeybind(rowTitle, value, callback)
            local row = addRow(30, rowTitle)
            Text({
                Font = FONT.UI, Position = UDim2.new(0, 2, 0, 0), Size = UDim2.new(1, -100, 1, 0),
                Text = rowTitle, TextColor3 = Theme.TextSecondary, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
            }, row)
            local button = new("TextButton", {
                AutoButtonColor = false, BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
                Font = FONT.Mono, Position = UDim2.new(1, -84, 0.5, -10), Size = UDim2.new(0, 82, 0, 20),
                Text = tostring(value or "None"), TextColor3 = Theme.TextSecondary, TextSize = 9, ZIndex = 9,
            }, row)
            corner(button, RADIUS.chip)
            hairline(button, Theme.StrokeSoft, 1, 0.35)
            local capturing = false
            local function accept(name)
                capturing = false
                button.Text = tostring(name)
                button.TextColor3 = Theme.TextSecondary
                CONTROLS.spawn("keybind · " .. rowTitle, callback, name)
            end
            button.MouseButton1Click:Connect(function()
                capturing = true
                button.Text = "press a key…"
                button.TextColor3 = Theme.Accent
            end)
            if UserInput then
                UserInput.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if capturing and input.UserInputType == Enum.UserInputType.Keyboard then
                        accept(input.KeyCode.Name)
                    end
                end)
            end
            table.insert(tab.searchIndex, rowTitle)
            CONTROLS.register("keybind", rowTitle, tab, {
                get = function() return button.Text end,
                commit = function(name) accept(name) end,
            })
            return button
        end

        function panelApi:AddStatus(height, provider, key)
            local block = new("Frame", {
                BackgroundColor3 = Theme.BgInset, BackgroundTransparency = 0.1, BorderSizePixel = 0,
                LayoutOrder = nextRow(), Size = UDim2.new(1, 0, 0, height or 110), ZIndex = 7,
            }, panel)
            corner(block, RADIUS.chip)
            hairline(block, Theme.StrokeSoft, 1, 0.4)
            local body = Text({
                Font = FONT.Mono, Position = UDim2.new(0, 8, 0, 6), Size = UDim2.new(1, -16, 1, -12),
                Text = "", TextColor3 = Theme.TextSecondary, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true, ZIndex = 8,
            }, block)
            task.spawn(function()
                while block.Parent do
                    CONTROLS.tick("status · " .. tostring(title), function()
                        local ok, lines = pcall(provider)
                        if ok then
                            if type(lines) == "table" then
                                local out = {}
                                for _, line in ipairs(lines) do
                                    if type(line) == "table" then
                                        out[#out + 1] = string.format("%-9s %s", tostring(line.label or ""), tostring(line.value or ""))
                                    else
                                        out[#out + 1] = tostring(line)
                                    end
                                end
                                body.Text = table.concat(out, "\n")
                            else
                                body.Text = tostring(lines)
                            end
                        end
                    end)
                    task.wait(0.5)
                end
            end)
            table.insert(panelApi.index, { frame = block, text = string.lower(tostring(key or title)) })
            table.insert(tab.searchIndex, tostring(title))
            return body
        end

        table.insert(tab.searchIndex, title)
        table.insert(tab.panels, { frame = panel, title = string.lower(title), index = panelApi.index })
        return panelApi
    end

    -- ── theme swatches: six chips painted in their own palette ───────────────
    function tab:AddSwatches(rowTitle, entries, currentKey, callback)
        local panel = tab:AddPanel(rowTitle, tab.column)
        table.insert(panel.index, { frame = panel.frame, text = string.lower(rowTitle) })
        local holder = new("Frame", {
            BackgroundTransparency = 1, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 48), ZIndex = 8,
        }, panel.frame)
        local count = #entries
        local gap = 4
        local swatches, byLabel, order = {}, {}, {}
        local selected = currentKey
        local function paint()
            for key, swatch in pairs(swatches) do
                local active = key == selected
                swatch.Stroke.Color = active and Theme.Accent or Theme.StrokeSoft
                swatch.Stroke.Thickness = active and 2 or 1
                swatch.Stroke.Transparency = active and 0.1 or 0.5
            end
        end
        local choose
        choose = function(key, silent)
            if not swatches[key] then return false end
            selected = key
            paint()
            if not silent and callback then CONTROLS.spawn("theme · " .. rowTitle, callback, key) end
            return true
        end
        for index, entry in ipairs(entries) do
            local button = new("TextButton", {
                AutoButtonColor = false, BackgroundColor3 = entry.bg, BorderSizePixel = 0,
                Position = UDim2.new((index - 1) / count, (index - 1) * gap, 0, 0),
                Size = UDim2.new(1 / count, -gap * (count - 1) / count, 0, 44),
                Text = "", ZIndex = 9,
            }, holder)
            corner(button, math.min(RADIUS.chip, 8))
            local stroke = new("UIStroke", {
                Color = Theme.StrokeSoft, Thickness = 1, Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }, button)
            Text({
                Font = FONT.Mono, Position = UDim2.new(0, 5, 0, 5), Size = UDim2.new(1, -10, 0, 12),
                Text = entry.key, TextColor3 = entry.text, TextSize = 8,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10,
            }, button)
            local dots = { entry.accent, entry.accent2, entry.accent3 }
            for dotIndex = 1, 3 do
                local dot = new("Frame", {
                    BackgroundColor3 = dots[dotIndex] or entry.accent, BorderSizePixel = 0,
                    Position = UDim2.new(0, 5 + (dotIndex - 1) * 9, 0, 27),
                    Size = UDim2.new(0, 6, 0, 6), ZIndex = 10,
                }, button)
                corner(dot, RADIUS.pill)
            end
            button.MouseEnter:Connect(function() stroke.Transparency = 0.15 end)
            button.MouseLeave:Connect(function()
                if selected ~= entry.key then stroke.Transparency = 0.5 end
            end)
            button.MouseButton1Click:Connect(function() choose(entry.key, false) end)
            swatches[entry.key] = { Frame = button, Stroke = stroke }
            order[index] = entry.key
            byLabel[entry.label or entry.key] = entry.key
            byLabel[entry.key] = entry.key
        end
        paint()
        CONTROLS.register("theme", rowTitle, tab, {
            set = function(value) choose(byLabel[value] or value, false) end,
            get = function() return selected end,
            options = order,
        })
        table.insert(tab.searchIndex, rowTitle)
        return { Set = function(value) choose(byLabel[value] or value, true) end, Get = function() return selected end }
    end

    Tabs[#Tabs + 1] = tab
    return tab
end

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
    Window, Body, PageHolder, Toast, ActiveTab = nil, nil, nil, nil, nil
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
        -- Metadata only; never a clock value, or the autosave comparison would
        -- think the file changed on every tick and rewrite it after boot.
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
--      The layout follows the reference: group panels with a header, checkbox
--      rows with the state on the right, sliders with a live readout, and a
--      bottom bar with an icon over each tab label.
-- ═══════════════════════════════════════════════════════════════════════════
local FEATURE_KEYS = {
    "AutoFarm", "AutoQuest", "AutoAttack", "KillAura", "BringMobs", "MobHitbox",
    "AutoSkill", "AutoChest", "AutoFruit", "AutoDrops",
    "WalkSpeedEnabled", "JumpPowerEnabled", "MouseClicks",
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

local function fmtRate(count, minutes)
    if minutes < 0.05 then return "—" end
    return string.format("%.1f/min", count / minutes)
end

local function farmStatus()
    local target = State.target
    local origin = myPosition()
    local distance = target and origin and math.floor(flatDistance(origin, target.position)) or 0
    local runtime = math.max(os.clock() - (State.startedAt or os.clock()), 0)
    local minutes = runtime / 60
    local function clock(seconds)
        return string.format("%02d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
    end
    return {
        { label = "state",  value = tostring(State.status) },
        { label = "target", value = target and (target.name .. " · " .. distance .. " studs") or "none" },
        { label = "session", value = clock(runtime) .. " · " .. tostring(State.kills) .. " kills · " .. fmtRate(State.kills, minutes) },
        { label = "loot",   value = string.format("chest %d · fruit %d · drop %d", State.chests, State.fruits, State.drops) },
        { label = "rates",  value = string.format("hits %s · loot %s", fmtRate(State.hits, minutes), fmtRate(State.chests + State.fruits + State.drops, minutes)) },
        { label = "travel", value = string.format("%d steps · %d studs", State.steps, math.floor(State.studs)) },
        { label = "mobs",   value = tostring(#World.mobs) .. " in " .. tostring(Config.ScanRange) .. " studs" },
    }
end

local function configStatus()
    return {
        { label = "file",     value = tostring(Config.ConfigPath) },
        { label = "profile",  value = "slot " .. tostring(Config.ProfileSlot) },
        { label = "saved",    value = tostring(State.savedAt or "never") },
        { label = "autosave", value = Config.Autosave and "on · 2 s" or "off" },
        { label = "autoload", value = Config.Autoload and "on · interface only" or "off" },
        { label = "storage",  value = Store.hasFileApi() and "writefile / readfile" or "clipboard only" },
        { label = "window",   value = string.format("%d, %d px", tonumber(Config.UiX) or 0, tonumber(Config.UiY) or 0) },
        { label = "features", value = tostring(featuresOn()) .. " on" },
    }
end

function buildTabs()
    -- ── Auto Farm ──────────────────────────────────────────────────────────
    local farm = makeTab("Auto Farm", "target, travel, fast attack, loot", "swords", Theme.Clay)

    farm:UseColumn(1)
    local core = farm:AddPanel("Farm", 1)
    core:AddCheckbox("Auto farm", "pick a target, travel to it, attack until it dies", Config.AutoFarm == true, function(state)
        Config.AutoFarm = state and true or false
    end)
    core:AddDropdown("Farm mode", { "Nearest mob", "Quest area", "Boss" }, Config.FarmMode, function(value)
        Config.FarmMode = value
    end)
    core:AddCheckbox("Auto attack", "fast attack on the current target", Config.AutoAttack == true, function(state)
        Config.AutoAttack = state and true or false
    end)
    core:AddCheckbox("Mouse clicks", "adds a click; the tool is activated either way", Config.MouseClicks == true, function(state)
        Config.MouseClicks = state and true or false
    end)
    core:AddSlider("Attack rate", 0.08, 0.6, Config.AttackRate, " s", function(value)
        Config.AttackRate = value
    end)
    core:AddSlider("Attack range", 6, 40, Config.AttackRange, " st", function(value)
        Config.AttackRange = math.floor(value + 0.5)
    end, function(value) return tostring(math.floor(value + 0.5)) .. " studs" end)

    local targeting = farm:AddPanel("Targeting", 1)
    targeting:AddCheckbox("Kill aura", "attack every mob around you, not just the target", Config.KillAura == true, function(state)
        Config.KillAura = state and true or false
    end)
    targeting:AddSlider("Aura radius", 6, 40, Config.AuraRadius, " st", function(value)
        Config.AuraRadius = math.floor(value + 0.5)
    end, function(value) return tostring(math.floor(value + 0.5)) .. " studs" end)
    targeting:AddCheckbox("Bring mobs", "pull nearby mobs to your feet", Config.BringMobs == true, function(state)
        Config.BringMobs = state and true or false
    end)
    targeting:AddSlider("Bring radius", 20, 150, Config.BringRadius, " st", function(value)
        Config.BringRadius = math.floor(value + 0.5)
    end, function(value) return tostring(math.floor(value + 0.5)) .. " studs" end)
    targeting:AddCheckbox("Mob hitbox", "scale mob hitboxes so melee connects", Config.MobHitbox == true, function(state)
        Config.MobHitbox = state and true or false
        if not state then Farm.restoreHitbox() end
    end)
    targeting:AddSlider("Hitbox size", 1, 4, Config.HitboxSize, "×", function(value)
        Config.HitboxSize = round(value, 2)
    end)
    targeting:AddCheckbox("Auto skill", "press Z · X · C · V on a cadence", Config.AutoSkill == true, function(state)
        Config.AutoSkill = state and true or false
    end)
    targeting:AddSlider("Skill interval", 0.3, 3, Config.SkillInterval, " s", function(value)
        Config.SkillInterval = round(value, 2)
    end)

    farm:UseColumn(2)
    local loot = farm:AddPanel("Loot", 2)
    loot:AddCheckbox("Auto chest", "open chests with their own proximity prompt", Config.AutoChest == true, function(state)
        Config.AutoChest = state and true or false
    end)
    loot:AddCheckbox("Auto fruit", "walk onto a fruit that spawned nearby", Config.AutoFruit == true, function(state)
        Config.AutoFruit = state and true or false
    end)
    loot:AddCheckbox("Auto drops", "collect money and drop parts", Config.AutoDrops == true, function(state)
        Config.AutoDrops = state and true or false
    end)
    loot:AddCheckbox("Auto quest", "talk to the quest NPC when it is close", Config.AutoQuest == true, function(state)
        Config.AutoQuest = state and true or false
    end)
    loot:AddSlider("Scan range", 40, 600, Config.ScanRange, " st", function(value)
        Config.ScanRange = math.floor(value + 0.5)
    end, function(value) return tostring(math.floor(value + 0.5)) .. " studs" end)

    local travel = farm:AddPanel("Travel", 2)
    travel:AddCheckbox("Instant travel", "skip the step pacing (riskier)", Config.TweenTravel == false, function(state)
        Config.TweenTravel = not state
    end)
    travel:AddSlider("Travel speed", 20, 300, Config.TravelSpeed, " st/s", function(value)
        Config.TravelSpeed = math.floor(value + 0.5)
    end, function(value) return tostring(math.floor(value + 0.5)) .. " st/s" end)
    travel:AddSlider("Travel step", 2, 40, Config.TravelStep, " st", function(value)
        Config.TravelStep = math.floor(value + 0.5)
    end, function(value) return tostring(math.floor(value + 0.5)) .. " studs" end)
    travel:AddSlider("Travel delay", 0.02, 0.4, Config.TravelDelay, " s", function(value)
        Config.TravelDelay = round(value, 2)
    end)

    local live = farm:AddPanel("Live", 2)
    live:AddStatus(120, farmStatus)

    -- ── Settings ───────────────────────────────────────────────────────────
    local settings = makeTab("Settings", "theme, config, keys, safety", "gear", Theme.Steel)

    settings:UseColumn(1)
    local palettes = NS.palettes or {}
    local themeEntries = {}
    for index, key in ipairs(THEME_ORDER) do
        local palette = palettes[key] or {}
        themeEntries[index] = {
            key = key,
            bg = palette.BgSurface,
            text = palette.TextPrimary,
            accent = palette.Accent,
            accent2 = palette.Clay,
            accent3 = palette.Sky,
        }
    end
    settings:AddSwatches("Theme", themeEntries, Config.Theme, function(key)
        Config.Theme = key
        applyTheme(key)
        rebuildInterface("theme")
    end)

    local look = settings:AddPanel("Appearance", 1)
    look:AddSlider("UI scale", 0.75, 1.3, Config.UiScale, "×", function(value)
        Config.UiScale = round(value, 2)
        local window = getWindow()
        local screen = window and window.Screen
        if screen then
            for _, child in ipairs(screen:GetChildren()) do
                if child:IsA("UIScale") then child.Scale = value end
            end
        end
    end, function(value) return string.format("%.2f×", value) end)
    look:AddCheckbox("Notifications", "toasts for saves, themes and profile actions", Config.NotifyActions == true, function(state)
        Config.NotifyActions = state and true or false
    end)
    look:AddButton("Reset window position", function()
        Config.UiX, Config.UiY = 0, 0
        local window = getWindow()
        if window and window.Root then
            window.Root.Position = UDim2.new(0.5, 0, 0.5, 0)
            if window.Shadow then window.Shadow.Position = UDim2.new(0.5, 0, 0.5, 5) end
            if window.Glow then window.Glow.Position = window.Root.Position end
        end
        notify("Window", "centred", 2, Theme.Accent, "scale")
    end)

    local keys = settings:AddPanel("Keys", 1)
    keys:AddKeybind("Show / hide window", Config.HideUiKey, function(value)
        Config.HideUiKey = tostring(value)
    end)
    keys:AddKeybind("Panic key", Config.PanicKey, function(value)
        Config.PanicKey = tostring(value)
    end)
    keys:AddButton("Panic — turn everything off", function()
        panic()
    end, true)

    local safety = settings:AddPanel("Safety", 1)
    safety:AddCheckbox("Unlock unsafe rates", "remove the attack and travel caps", Config.SafeMode == false, function(state)
        Config.SafeMode = not state
    end)
    safety:AddSlider("Speed cap", 16, 120, Config.SpeedCap, " st/s", function(value)
        Config.SpeedCap = math.floor(value + 0.5)
    end, function(value) return tostring(math.floor(value + 0.5)) .. " st/s" end)
    safety:AddCheckbox("Walk speed", "override the humanoid speed", Config.WalkSpeedEnabled == true, function(state)
        Config.WalkSpeedEnabled = state and true or false
    end)
    safety:AddSlider("Walk speed value", 16, 200, Config.WalkSpeed, " st/s", function(value)
        Config.WalkSpeed = math.floor(value + 0.5)
    end, function(value) return tostring(math.floor(value + 0.5)) .. " st/s" end)
    safety:AddCheckbox("Jump power", "override the humanoid jump", Config.JumpPowerEnabled == true, function(state)
        Config.JumpPowerEnabled = state and true or false
    end)
    safety:AddSlider("Jump power value", 50, 300, Config.JumpPower, "", function(value)
        Config.JumpPower = math.floor(value + 0.5)
    end, function(value) return tostring(math.floor(value + 0.5)) end)

    settings:UseColumn(2)
    local config = settings:AddPanel("Config", 2)
    config:AddCheckbox("Autosave", "write the config two seconds after it changes", Config.Autosave == true, function(state)
        Config.Autosave = state and true or false
    end)
    config:AddCheckbox("Load on start", "restore interface keys only — never a switch", Config.Autoload == true, function(state)
        Config.Autoload = state and true or false
    end)
    config:AddButton("Save config", function() Store.save(true) end)
    config:AddButton("Load config", function() Store.load(true) end)
    config:AddButton("Copy config", function() Store.export() end)
    config:AddInput("Import config", "{ ... }", function(text) Store.import(text) end)
    config:AddButton("Reset defaults", function() Store.reset() end, true)

    local profiles = settings:AddPanel("Profiles", 2)
    profiles:AddDropdown("Profile slot", { "1", "2", "3" }, Config.ProfileSlot, function(value)
        Config.ProfileSlot = tostring(value)
    end)
    profiles:AddButton("Save profile", function() Store.saveProfile(Config.ProfileSlot) end)
    profiles:AddButton("Load profile", function()
        Store.loadProfile(Config.ProfileSlot)
        if Store.afterChange then pcall(Store.afterChange) end
    end)

    local configLive = settings:AddPanel("Status", 2)
    configLive:AddStatus(132, configStatus, "status config file profile autosave autoload storage window features")

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
    if window.Glow then window.Glow.Visible = not visible end
    if window.Shadow then window.Shadow.Visible = not visible end
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
    local titles = {}
    for index, tab in ipairs(Tabs) do titles[index] = tab.title end
    row("build", META.version .. " / " .. META.build)
    row("window", (getWindow() and getWindow().Root) and "built" or "missing")
    row("tabs", tostring(#Tabs) .. " · " .. table.concat(titles, " / "))
    row("controls", tostring(#NS.controls) .. " rows / " .. tostring(NS.controlHealth.faults) .. " fault(s)")
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
    print(string.format("[Skill Hub] rows · %d · all off · theme %s", #NS.controls, Config.Theme))
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
    check("version", META.version == "v1.2")
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
    load = function() return Store.load(true) end,
    reset = function() return Store.reset() end,
    exportConfig = function() return Store.export() end,
    importConfig = function(text) return Store.import(text) end,
    saveProfile = function(slot) return Store.saveProfile(slot or Config.ProfileSlot) end,
    loadProfile = function(slot) return Store.loadProfile(slot or Config.ProfileSlot) end,
    profilePath = function(slot) return Store.profilePath(slot or Config.ProfileSlot) end,
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
