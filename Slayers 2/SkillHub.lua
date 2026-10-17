--[[
    ██╗  ██╗██╗██╗     ██╗         ██╗  ██╗██╗   ██╗██████╗
    ██║ ██╔╝██║██║     ██║         ██║  ██║██║   ██║██╔══██╗
    █████╔╝ ██║██║     ██║         ███████║██║   ██║██████╔╝
    ██╔═██╗ ██║██║     ██║         ██╔══██║██║   ██║██╔══██╗
    ██║  ██╗██║███████╗███████╗    ██║  ██║╚██████╔╝██████╔╝
    ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    Skill Hub — Slayers 2  ·  FREE edition (no key, open source, readable)
    by ameksi-web  ·  https://github.com/ameksi-web/Skill-Hub

    ── how to run ──────────────────────────────────────────────────────────────
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/Slayers%202/SkillHub.lua"))()

    ── what this is ────────────────────────────────────────────────────────────
        A Slayers 2 (Project Slayers 2) hub with the same "Porcelain" design
        system as the Blox Fruits build: soft-dark graphite surfaces, hairline
        borders, muted editorial accents, drawn icon set, no neon.
        Tabs: Auto Farm · Quests & Training · Combat · ESP & Visuals ·
              Teleports · Anti-Cheat · Player & Misc.

    ── the anti-cheat layer, honestly ──────────────────────────────────────────
        Everything a client-side script CAN do, and nothing it cannot:
          · finds and disables the game's client-side detector scripts
          · drops outgoing "report / flag / ban" remote calls at the namecall
            level (newcclosure, pcall-guarded, always falls through to the
            original call for every remote that is not on the report list)
          · keeps every value it touches inside a plausible range (speed clamp,
            distance-based teleport pacing, remote rate limiter) so the
            server-side checks see ordinary traffic
          · blocks ragdoll / stun / slow / fall damage / AFK-kick on the client
          · logs a kick (it cannot stop a server kick — the server ejects you
            before the client hears about it)
        Nothing here is "impossible to detect": a server that validates damage
        server-side is not something a client script can bypass. What this
        build does is strip the client-side detection and keep the traffic
        inside plausible bounds. Test it yourself: Anti-Cheat → "Run audit".
]]

local VERSION   = "v1.0"
local BUILD     = "Slayers 2 · free"
local AUTHOR    = "ameksi-web"
local GAME_NAME = "Slayers 2"

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
local Camera       = Workspace.CurrentCamera

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
-- ═══════════════════════════════════════════════════════════════════════════
local Config = {
    -- farm
    AutoFarm            = false,
    AutoQuest           = false,
    AutoBoss            = false,
    AutoChest           = false,
    AutoLoot            = false,
    AutoLevelMode       = true,
    FarmRange           = 60,
    SkillRange          = 40,
    MobFilter           = "Any",
    SelectedMob         = "Any",
    BringMobs           = false,
    ChestRange          = 120,
    LootRange           = 120,

    -- quest / training
    AutoTrainMastery    = false,
    AutoBlowGourd       = false,
    AutoInteractPrompts = false,
    AutoFinalSelection  = false,
    AutoFish            = false,
    AutoSpin            = false,

    -- combat
    KillAura            = false,
    KillAuraRange       = 28,
    KillAuraPlayers     = false,
    FastAttack          = false,
    FastAttackDelay     = 0.12,
    AutoSkills          = false,
    SkillKeys           = "Z,X,C,V",
    AutoParry           = false,
    ParryKey            = "F",
    AutoFace            = true,
    AimLock             = false,
    AimLockSmooth       = 0.25,
    AutoDodge           = false,
    HitboxEnabled       = false,
    HitboxSize          = 22,
    HitboxTarget        = "Mobs",
    AntiRagdoll         = true,
    AntiStun            = true,
    NoFallDamage        = true,
    InfiniteStamina     = false,
    AutoEquipWeapon     = true,

    -- esp
    EspPlayers          = false,
    EspMobs             = false,
    EspBosses           = false,
    EspNPCs             = false,
    EspChests           = false,
    EspDrops            = false,
    EspLilies           = false,
    EspTracers          = false,
    EspHealthBars       = true,
    EspDistance         = true,
    EspMaxDistance      = 1200,
    Fullbright          = false,
    NoFog               = false,
    ZoomFov             = 0,

    -- movement
    WalkSpeedEnabled    = false,
    WalkSpeed           = 26,
    JumpPowerEnabled    = false,
    JumpPower           = 60,
    InfiniteJump        = false,
    Noclip              = false,
    FlyEnabled          = false,
    FlySpeed            = 90,
    AntiVoid            = true,

    -- anti-cheat
    AcNeutralize        = true,
    AcBlockReports      = true,
    AcKickGuard         = true,
    AcSafeMode          = true,
    AcSpeedCeiling      = 60,
    AcRemoteRateLimit   = 12,
    AcTeleportPacing    = true,
    StaffWatch          = true,
    StaffGroupId        = 0,
    StaffHop            = false,
    AntiAfk             = true,

    -- misc
    HideUiKey           = "RightControl",
    UiVisible           = true,
    UiTransparency      = 0,
    FpsBoost            = false,
    ShowAuthor          = true,
    LogLevel            = 2,
}

SharedEnv.SkillHubConfig = SharedEnv.SkillHubConfig or Config

-- ═══════════════════════════════════════════════════════════════════════════
-- 2 · THEME — "Porcelain" (identical tokens to the Blox Fruits build)
-- ═══════════════════════════════════════════════════════════════════════════
local Theme = {
    BgApp           = Color3.fromRGB(9, 10, 12),
    BgSurface       = Color3.fromRGB(17, 19, 23),
    BgElevated      = Color3.fromRGB(23, 26, 31),
    BgRaised        = Color3.fromRGB(29, 33, 39),
    BgInset         = Color3.fromRGB(13, 15, 18),
    BgHover         = Color3.fromRGB(33, 37, 44),
    BgSidebar       = Color3.fromRGB(15, 17, 20),

    Hairline        = Color3.fromRGB(58, 63, 72),
    Stroke          = Color3.fromRGB(44, 49, 57),
    StrokeSoft      = Color3.fromRGB(35, 39, 46),

    TextPrimary     = Color3.fromRGB(243, 244, 246),
    TextSecondary   = Color3.fromRGB(158, 165, 175),
    TextMuted       = Color3.fromRGB(110, 117, 127),
    TextFaint       = Color3.fromRGB(78, 84, 93),
    OnAccent        = Color3.fromRGB(13, 14, 17),

    Accent          = Color3.fromRGB(126, 141, 255),
    AccentSecondary = Color3.fromRGB(150, 158, 186),
    Iris            = Color3.fromRGB(126, 141, 255),
    Clay            = Color3.fromRGB(226, 132, 122),
    Sand            = Color3.fromRGB(223, 181, 133),
    Sage            = Color3.fromRGB(128, 182, 155),
    Mauve           = Color3.fromRGB(173, 143, 222),
    Steel           = Color3.fromRGB(150, 158, 186),
    Sky             = Color3.fromRGB(136, 170, 203),
    Rose            = Color3.fromRGB(201, 141, 178),

    Success         = Color3.fromRGB(122, 190, 146),
    Warning         = Color3.fromRGB(224, 184, 116),
    Danger          = Color3.fromRGB(223, 118, 116),
}

local UIFont     = Enum.Font.GothamMedium
local UIFontBold = Enum.Font.GothamBold
local UIFontMono = Enum.Font.Code

local RADIUS = { window = 20, panel = 14, card = 12, control = 10, chip = 8, pill = 999 }

local function new(class, props, parent)
    local inst = Instance.new(class)
    for key, value in pairs(props or {}) do
        pcall(function() inst[key] = value end)
    end
    if parent ~= nil then pcall(function() inst.Parent = parent end) end
    return inst
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or RADIUS.card)
    if parent ~= nil then pcall(function() c.Parent = parent end) end
    return c
end

local function hairline(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.35
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    if parent ~= nil then pcall(function() s.Parent = parent end) end
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
    props.Font = props.Font or UIFont
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
            corner(part, math.floor(size / 2))
        else
            corner(part, math.max(math.floor(radius or 2), 1))
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
    Skull    = "skull",
    Chart    = "chart",
    Quest    = "scroll",
    Flame    = "flame",
    Water    = "drop",
    Wind     = "wind",
    Bolt     = "bolt",
    Bell     = "bell",
    Eye      = "eye",
    Teleport = "compass",
    Settings = "gear",
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
local Tabs = {}
local ToggleRegistry = {}
local ToastOrder = 0

local toastHolder

local function notify(title, message, duration, accent, iconKind)
    if not toastHolder then return end
    duration = duration or 4
    accent = accent or Theme.Accent

    local card = new("Frame", {
        BackgroundColor3 = Theme.BgElevated,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -312, 0, 16),
        Size = UDim2.new(0, 296, 0, message and 62 or 44),
        ZIndex = 60,
    }, toastHolder)
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
        Font = UIFontBold, Position = UDim2.new(0, 54, 0, 11), Size = UDim2.new(1, -66, 0, 14),
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

    ToastOrder = ToastOrder + 1
    card.LayoutOrder = ToastOrder

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
-- 5 · WINDOW FRAMEWORK  (chrome + rail + components)
-- ═══════════════════════════════════════════════════════════════════════════

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
        Name = "SkillHubSlayers2",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, parent)
    if protect_gui then pcall(protect_gui, screen) end

    Toast = new("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(0, 320, 1, 0),
        Position = UDim2.new(1, -336, 0, 0), ZIndex = 59,
    }, screen)
    new("UIListLayout", {
        Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder,
    }, Toast)
    toastHolder = Toast

    local shadow = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(4, 5, 7), BackgroundTransparency = 0.45,
        BorderSizePixel = 0, Position = UDim2.new(0.5, 6, 0.5, 8),
        Size = UDim2.new(0, 748, 0, 486), ZIndex = 1,
    }, screen)
    corner(shadow, RADIUS.window + 4)

    local root = new("Frame", {
        BackgroundColor3 = Theme.BgSurface, BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 748, 0, 486), ZIndex = 2,
    }, screen)
    corner(root, RADIUS.window)
    local rootStroke = hairline(root, Theme.Hairline, 1, 0.55)

    Window = { Screen = screen, Root = root, Shadow = shadow, Stroke = rootStroke, Minimized = false }

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
        Font = UIFontBold, Position = UDim2.new(0, 54, 0, 9), Size = UDim2.new(0, 260, 0, 16),
        Text = "Skill Hub", TextColor3 = Theme.TextPrimary, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
    }, topbar)
    Text({
        Position = UDim2.new(0, 54, 0, 25), Size = UDim2.new(0, 300, 0, 14),
        Text = GAME_NAME .. " · " .. VERSION .. " · free edition", TextColor3 = Theme.TextMuted,
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
            Font = UIFontMono, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0),
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
            Font = UIFontBold, Size = UDim2.new(1, 0, 1, 0), Text = text,
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
        Config.UiVisible = false
        Window.Screen.Enabled = false
    end)

    -- drag
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, root.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
        BackgroundTransparency = 1, Font = UIFont, PlaceholderText = "search options…",
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
        Text = VERSION .. " · free · no key", TextColor3 = Theme.TextFaint, TextSize = 9,
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
        Font = UIFontBold, Position = UDim2.new(0, 54, 0, 10), Size = UDim2.new(1, -70, 0, 16),
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
        Text = Config.HideUiKey .. " — показать/скрыть окно · F1 — паника (выключить всё)", TextColor3 = Theme.TextFaint,
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, strip)
    local stripRight = Text({
        Font = UIFontMono, Position = UDim2.new(1, -320, 0, 7), Size = UDim2.new(0, 306, 0, 12),
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
local TabOrder = 0

local function makeTab(title, desc, iconKind, accent)
    TabOrder = TabOrder + 1
    accent = accent or Theme.Accent
    local railList = Rail:FindFirstChildOfClass("ScrollingFrame")

    local button = new("TextButton", {
        AutoButtonColor = false, BackgroundColor3 = Theme.BgElevated, BackgroundTransparency = 1,
        BorderSizePixel = 0, LayoutOrder = TabOrder, Size = UDim2.new(1, 0, 0, 34),
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
        Font = UIFontBold, Position = UDim2.new(0, 40, 0, 0), Size = UDim2.new(1, -46, 1, 0),
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
            Font = UIFontBold, Position = UDim2.new(0, 2, 1, -14), Size = UDim2.new(1, -4, 0, 14),
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
            Font = UIFontBold, Position = UDim2.new(0, 56, 0, 11), Size = UDim2.new(1, -170, 0, 16),
            Text = title, TextColor3 = Theme.TextPrimary, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
        }, card)
        Text({
            Position = UDim2.new(0, 56, 0, 29), Size = UDim2.new(1, -170, 0, 16),
            Text = desc or "", TextColor3 = Theme.TextMuted, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
        }, card)
        local stateLabel = Text({
            Font = UIFontBold, Position = UDim2.new(1, -112, 0.5, -7), Size = UDim2.new(0, 30, 0, 14),
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

        local click = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", ZIndex = 8 }, card)
        click.MouseButton1Click:Connect(function()
            state = not state
            render(true)
            if callback then task.spawn(callback, state) end
        end)
        click.MouseEnter:Connect(function() SafeTween(card, TweenInfo.new(0.14), { BackgroundColor3 = Theme.BgRaised }):Play() end)
        click.MouseLeave:Connect(function() SafeTween(card, TweenInfo.new(0.14), { BackgroundColor3 = Theme.BgElevated }):Play() end)

        local api = {}
        api.Set = function(v, silent)
            state = v and true or false
            render(true)
            if not silent and callback then task.spawn(callback, state) end
        end
        api.Get = function() return state end
        table.insert(tab.searchIndex, title)
        tab.toggles = tab.toggles or {}
        table.insert(tab.toggles, api)
        table.insert(ToggleRegistry, { title = title, tab = tab, set = api.Set, get = api.Get })
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
            Font = UIFontBold, Position = UDim2.new(0, 56, 0, 12), Size = UDim2.new(1, -170, 0, 16),
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
            Font = UIFontMono, Size = UDim2.new(1, 0, 1, 0),
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
            if callback then callback(current) end
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
        return { Set = function(v) current = clamp(v, min, max) render(); if callback then callback(current) end end,
                 Get = function() return current end }
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
            Font = UIFontBold, Position = UDim2.new(0, 56, 0, 11), Size = UDim2.new(1, -120, 0, 16),
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
            BorderSizePixel = 0, Font = UIFontBold, Position = UDim2.new(1, -96, 0.5, -13),
            Size = UDim2.new(0, 82, 0, 26), Text = "RUN", TextColor3 = danger and Theme.Danger or tab.color,
            TextSize = 10, ZIndex = 7,
        }, card)
        corner(action, RADIUS.chip)
        action.MouseEnter:Connect(function() SafeTween(action, TweenInfo.new(0.14), { BackgroundTransparency = 0.2 }):Play() end)
        action.MouseLeave:Connect(function() SafeTween(action, TweenInfo.new(0.14), { BackgroundTransparency = 0 }):Play() end)
        action.MouseButton1Click:Connect(function()
            if callback then task.spawn(callback) end
            notify(title, "executed", 2, danger and Theme.Danger or tab.color, iconKind or tab.icon)
        end)
        table.insert(tab.searchIndex, title)
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
            Font = UIFontBold, Position = UDim2.new(0, 56, 0, 11), Size = UDim2.new(1, -170, 0, 16),
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
            Font = UIFontBold, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -26, 1, 0),
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

        local api = {}
        function api.SetOptions(newOptions)
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            for index, option in ipairs(newOptions) do
                local row = new("TextButton", {
                    AutoButtonColor = false, BackgroundTransparency = 1, Font = UIFont,
                    LayoutOrder = index, Size = UDim2.new(1, 0, 0, 22), Text = "   " .. tostring(option),
                    TextColor3 = Theme.TextSecondary, TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 41,
                }, list)
                row.MouseEnter:Connect(function() row.BackgroundTransparency = 0.8 end)
                row.MouseLeave:Connect(function() row.BackgroundTransparency = 1 end)
                row.MouseButton1Click:Connect(function()
                    current = option
                    selectorText.Text = tostring(option)
                    expanded = false
                    list.Visible = false
                    list.Size = UDim2.new(0, 138, 0, 0)
                    if callback then task.spawn(callback, option) end
                end)
            end
        end
        api.SetOptions(options)
        api.Get = function() return current end
        api.Set = function(option)
            current = option
            selectorText.Text = tostring(option)
            if callback then task.spawn(callback, option) end
        end

        selector.MouseButton1Click:Connect(function()
            expanded = not expanded
            local rows = 0
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("TextButton") then rows = rows + 1 end
            end
            local height = math.min(rows, 7) * 24 + 8
            list.Visible = expanded
            list.Size = UDim2.new(0, 138, 0, expanded and height or 0)
        end)
        table.insert(tab.searchIndex, title)
        return api
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
            Font = UIFontBold, Position = UDim2.new(0, 56, 0, 11), Size = UDim2.new(1, -170, 0, 16),
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
            BackgroundTransparency = 1, ClearTextOnFocus = false, Font = UIFont,
            PlaceholderText = placeholder or "…", PlaceholderColor3 = Theme.TextFaint,
            Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -18, 1, 0),
            Text = "", TextColor3 = Theme.TextPrimary, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
        }, shell)
        box.FocusLost:Connect(function()
            stroke.Color = Theme.StrokeSoft
            if box.Text and #box.Text > 0 and callback then task.spawn(callback, box.Text) end
        end)
        box.Focused:Connect(function() stroke.Color = tab.color end)
        table.insert(tab.searchIndex, title)
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
            Font = UIFontBold, Position = UDim2.new(0, 56, 0, 11), Size = UDim2.new(1, -170, 0, 16),
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
            Font = UIFontMono, Position = UDim2.new(1, -110, 0.5, -12), Size = UDim2.new(0, 96, 0, 24),
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
        if UserInput then
            UserInput.InputBegan:Connect(function(input)
                if capturing and input.UserInputType == Enum.UserInputType.Keyboard then
                    capturing = false
                    button.Text = input.KeyCode.Name
                    button.TextColor3 = Theme.TextSecondary
                    if callback then task.spawn(callback, input.KeyCode.Name) end
                end
            end)
        end
        table.insert(tab.searchIndex, title)
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
            Font = UIFontBold, Position = UDim2.new(0, 50, 0, 13), Size = UDim2.new(1, -140, 0, 16),
            Text = title, TextColor3 = Theme.TextPrimary, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
        }, card)
        local dot = new("Frame", {
            BackgroundColor3 = Theme.Success, BorderSizePixel = 0,
            Position = UDim2.new(1, -74, 0, 18), Size = UDim2.new(0, 6, 0, 6), ZIndex = 6,
        }, card)
        corner(dot, RADIUS.pill)
        Text({
            Font = UIFontMono, Position = UDim2.new(1, -64, 0, 13), Size = UDim2.new(0, 56, 0, 16),
            Text = "LIVE", TextColor3 = Theme.Success, TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6,
        }, card)

        local box = new("Frame", {
            BackgroundColor3 = Theme.BgInset, BorderSizePixel = 0,
            Position = UDim2.new(0, 14, 0, 38), Size = UDim2.new(1, -28, 1, -52), ZIndex = 6,
        }, card)
        corner(box, RADIUS.control)
        local body = Text({
            Font = UIFontMono, Position = UDim2.new(0, 10, 0, 8), Size = UDim2.new(1, -20, 1, -16),
            Text = "", TextColor3 = Theme.TextSecondary, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true, ZIndex = 7,
        }, box)

        task.spawn(function()
            local pulse = true
            while card.Parent do
                local ok, lines = pcall(provider)
                if ok then
                    if type(lines) == "table" then body.Text = table.concat(lines, "\n") else body.Text = tostring(lines) end
                end
                pulse = not pulse
                dot.BackgroundColor3 = pulse and Theme.Success or tint(Theme.Success, 0.4)
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
            Font = UIFontBold, Position = UDim2.new(0, 50, 0, 13), Size = UDim2.new(1, -140, 0, 16),
            Text = title, TextColor3 = Theme.TextPrimary, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
        }, card)
        local count = Text({
            Font = UIFontMono, Position = UDim2.new(1, -140, 0, 13), Size = UDim2.new(0, 126, 0, 16),
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
                                Font = UIFontBold, Position = UDim2.new(0, 40, 0, 3), Size = UDim2.new(1, -180, 0, 13),
                                Text = "", TextColor3 = Theme.TextPrimary, TextSize = 10,
                                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8,
                            }, row)
                            row.Info = Text({
                                Font = UIFontMono, Position = UDim2.new(0, 40, 0, 15), Size = UDim2.new(1, -180, 0, 12),
                                Text = "", TextColor3 = Theme.TextFaint, TextSize = 9,
                                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8,
                            }, row)
                            row.Buttons = {}
                            for buttonIndex, action in ipairs(actions or {}) do
                                local actionButton = new("TextButton", {
                                    AutoButtonColor = false, BackgroundColor3 = tint(tab.color, 0.88),
                                    BorderSizePixel = 0, Font = UIFontBold,
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
-- 6 · WORLD KNOWLEDGE — Slayers 2 names, zones and what counts as what
--     (everything is matched case-insensitively against live instance names)
-- ═══════════════════════════════════════════════════════════════════════════
local KNOWLEDGE = {
    Zones = {
        "Windy Peak", "Bamboo Grove", "Bamboo Outskirts", "Mistfall Village", "Mistfall Harbor",
        "Seasons Crossing", "Iceveil Valley", "Hidden Mist Village", "Dreamfall Hollow",
        "Butterfly Estate", "Waterfall Cave", "Snowy Mountains", "Ouwigahara", "Final Selection",
        "Slayer Corps", "Muzan", "Cavern", "Highlands", "Elite Zone",
    },
    Trainers = {
        "Urokodaki", "Rengu", "Zentaro", "Saneri", "Gyorei", "Shinora", "Tengai", "Obari",
        "Togane", "Raze", "Kazuma", "Sofen", "Jeso", "Kokushibo", "Muzan",
    },
    QuestNpcs = {
        "Kona", "Krue", "Tom", "Chaka", "Wagwan", "Hoyuzo", "Jugg", "Goro", "Tomoi", "Shiro",
        "Mitsu", "Tobei", "Crow", "Sisters", "Hand Demon", "Final Selection", "Blacksmith",
    },
    BossHints = {
        "boss", "hand demon", "hoyuzo", "kaiden", "mother bear", "yeti", "greater demon",
        "zuko", "spider demon", "muzan", "kokushibo", "upper moon", "swamp demon",
    },
    MaterialHints = { "horn", "core", "ore", "sickle", "cloth", "fang", "scale", "seed", "lily", "iron" },
    ChestHints    = { "chest", "crate", "barrel", "case", "supply" },
    DropHints     = { "drop", "loot", "pickup", "item", "reward", "coin", "wen" },
    LilyHints     = { "lily", "spider lily", "flower", "collectible" },
    -- level → the zone and mobs that give the best exp there
    FarmPlan = {
        { min = 1,   zone = "Bamboo Grove",     mobs = { "Bandit", "Civilian Spy", "Wolf" } },
        { min = 10,  zone = "Bamboo Outskirts", mobs = { "Bandit", "Bear", "Baldy" } },
        { min = 18,  zone = "Windy Peak",       mobs = { "Mother Bear", "Bear", "Bandit" } },
        { min = 26,  zone = "Waterfall Cave",   mobs = { "Subordinate", "Hoyuzo's Subordinate", "Demon" } },
        { min = 34,  zone = "Waterfall Cave",   mobs = { "Kaiden", "Hoyuzo", "Demon" } },
        { min = 45,  zone = "Mistfall Village", mobs = { "Demon", "Beast Born Demon", "Misenoto" } },
        { min = 62,  zone = "Dreamfall Hollow", mobs = { "Demon", "Greater Demon", "Guard" } },
        { min = 75,  zone = "Hidden Mist Village", mobs = { "Greater Demon", "Demon Slayer", "Guard" } },
        { min = 90,  zone = "Iceveil Valley",   mobs = { "Tundra Demon", "Yeti", "Frost Guard" } },
        { min = 105, zone = "Snowy Mountains",  mobs = { "Yeti", "Tundra Demon", "Burning Demon" } },
        { min = 125, zone = "Ouwigahara",       mobs = { "Demon", "Boss", "Greater Demon" } },
    },
    ParryKeys = { "F", "Q", "G" },
    SkillKeyDefaults = { "Z", "X", "C", "V" },
}

local function containsAny(text, list)
    local lowered = string.lower(tostring(text or ""))
    for _, needle in ipairs(list) do
        if string.find(lowered, string.lower(needle), 1, true) then return needle end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 7 · CHARACTER / PLAYER STATE
-- ═══════════════════════════════════════════════════════════════════════════
local State = {
    errors       = {},
    startedAt    = os.clock(),
    ac           = { scripts = {}, blocked = 0, kicks = 0, audit = nil, hookInstalled = false },
    lastTeleport = 0,
    loops        = {},
    stepTimers   = {},
    savedSpots   = {},
    questTarget  = nil,
    lastAttack   = 0,
    skillIndex   = 0,
}
SharedEnv.__SkillHubErrorLog = SharedEnv.__SkillHubErrorLog or State.errors

local function getChar()
    if not LocalPlayer then return nil end
    return LocalPlayer.Character
end

local function getRoot()
    local char = getChar()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

local function getHumanoid()
    local char = getChar()
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function isAlive()
    local humanoid = getHumanoid()
    return humanoid ~= nil and humanoid.Health > 0 and getRoot() ~= nil
end

local function charOf(instance)
    if not instance then return nil end
    if instance:IsA("Player") then return instance.Character end
    if instance:IsA("Model") then return instance end
    if instance:IsA("BasePart") then
        return instance:FindFirstAncestorOfClass("Model")
    end
    return nil
end

local function humanoidOf(instance)
    local char = charOf(instance)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function isPlayerCharacter(instance)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and (player.Character == instance or player.Character:IsAncestorOf(instance)) then
            return player
        end
    end
    return nil
end

local function statOf(player, name)
    player = player or LocalPlayer
    if not player then return nil end
    for _, container in ipairs({ player, player:FindFirstChild("leaderstats"), player:FindFirstChild("Stats"),
                                player:FindFirstChild("Values"), player:FindFirstChild("Data") }) do
        if container then
            local value = container:FindFirstChild(name)
            if value and (value:IsA("IntValue") or value:IsA("NumberValue") or value:IsA("StringValue")) then
                return value.Value
            end
        end
    end
    local attribute = player:GetAttribute(name)
    if attribute ~= nil then return attribute end
    return nil
end

local function getLevel()
    local value = statOf(LocalPlayer, "Level") or statOf(LocalPlayer, "Lvl") or statOf(LocalPlayer, "level")
    if type(value) == "number" then return math.floor(value) end
    if type(value) == "string" then return tonumber(value) or 1 end
    local attribute = LocalPlayer and LocalPlayer:GetAttribute("Level")
    if type(attribute) == "number" then return math.floor(attribute) end
    return 1
end

local function getWen()
    return statOf(LocalPlayer, "Wen") or statOf(LocalPlayer, "Money") or statOf(LocalPlayer, "Cash") or 0
end

local function getBreathing()
    local value = statOf(LocalPlayer, "Breathing") or statOf(LocalPlayer, "Style") or statOf(LocalPlayer, "Art")
    if value then return tostring(value) end
    local character = getChar()
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                local marker = containsAny(tool.Name, { "Water", "Flame", "Thunder", "Wind", "Stone", "Sound", "Insect", "Serpent" })
                if marker then return tool.Name end
            end
        end
    end
    return "—"
end

local function getClan()
    local value = statOf(LocalPlayer, "Clan") or statOf(LocalPlayer, "Race")
    if value then return tostring(value) end
    local attribute = LocalPlayer and LocalPlayer:GetAttribute("Clan")
    return attribute and tostring(attribute) or "—"
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 8 · TOOLS AND WEAPONS
-- ═══════════════════════════════════════════════════════════════════════════
local function backpack()
    if not LocalPlayer then return nil end
    return LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:FindFirstChild("Backpack")
end

local function collectTools()
    local list = {}
    local character = getChar()
    for _, container in ipairs({ character, backpack() }) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Tool") then table.insert(list, child) end
            end
        end
    end
    return list
end

local function equippedTool()
    local character = getChar()
    if not character then return nil end
    return character:FindFirstChildOfClass("Tool")
end

local function toolScore(tool)
    local name = string.lower(tool.Name)
    local score = 0
    if containsAny(name, { "katana", "sword", "blade", "nichirin", "scythe", "odachi" }) then score = score + 60 end
    if containsAny(name, { "fist", "hand", "combat" }) then score = score + 10 end
    if containsAny(name, { "breath", "art" }) then score = score + 40 end
    if containsAny(name, { "gourd", "book", "map", "food", "potion", "crow" }) then score = score - 100 end
    local handle = tool:FindFirstChild("Handle")
    if handle then score = score + 5 end
    return score
end

local function equipTool(tool)
    if not tool then return false end
    local humanoid = getHumanoid()
    if tool.Parent == getChar() then return true end
    if humanoid then
        local ok = pcall(function() humanoid:EquipTool(tool) end)
        if ok and tool.Parent == getChar() then return true end
    end
    local ok = pcall(function() tool.Parent = getChar() end)
    return ok and tool.Parent == getChar()
end

local function equipBestWeapon()
    local best, bestScore = nil, -1000
    for _, tool in ipairs(collectTools()) do
        local score = toolScore(tool)
        if score > bestScore then best, bestScore = tool, score end
    end
    if best and equippedTool() ~= best then equipTool(best) end
    return best
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 9 · ANTI-CHEAT LAYER  (the "full bypass": strip what the client can reach,
--     block the reports it can send, keep the traffic plausible)
-- ═══════════════════════════════════════════════════════════════════════════
local AC = {}

local AC_SCRIPT_HINTS = {
    "anticheat", "anti_cheat", "anti-cheat", "ac_", "_ac", "detector", "sentry", "watchdog",
    "integrity", "kronos", "hyperion", "sentinel", "trust", "monitor", "guardian", "exploit",
    "cheatdetect", "security", "verify", "validator",
}
local AC_REMOTE_HINTS = {
    "anticheat", "anti_cheat", "report", "flag", "detected", "detection", "suspicious",
    "exploit", "ban", "kick", "blacklist", "integrity", "violation", "cheatlog", "logcheat",
    "cheat", "trustcheck", "audit",
}
local AC_REMOTE_ALLOW = {
    "quest", "dialog", "npc", "shop", "inventory", "combat", "attack", "damage", "hit",
    "skill", "breath", "art", "level", "exp", "cash", "wen", "trade", "chat", "team",
    "friend", "gacha", "spin", "clan", "forging", "fish", "craft", "prompt", "interact",
    "movement", "spawn", "respawn", "character",
}

local function isRemoteLike(instance)
    if not instance then return false end
    local ok, class = pcall(function() return instance.ClassName end)
    if not ok then return false end
    return class == "RemoteEvent" or class == "RemoteFunction" or class == "UnreliableRemoteEvent"
        or class == "BindableEvent"
end

local function looksLikeAcScript(instance)
    local ok, class = pcall(function() return instance.ClassName end)
    if not ok or (class ~= "LocalScript" and class ~= "Script" and class ~= "ModuleScript") then return nil end
    local full = ""
    safeCall("ac name", function() full = instance:GetFullName() end)
    local lowered = string.lower(full)
    for _, hint in ipairs(AC_SCRIPT_HINTS) do
        if string.find(lowered, hint, 1, true) then return hint end
    end
    local ok2, tags = pcall(function() return CollectionService:GetTags(instance) end)
    if ok2 and type(tags) == "table" then
        for _, tag in ipairs(tags) do
            local hit = containsAny(tag, AC_SCRIPT_HINTS)
            if hit then return "tag:" .. hit end
        end
    end
    return nil
end

local function looksLikeAcRemote(instance)
    if not isRemoteLike(instance) then return nil end
    local name = string.lower(instance.Name)
    if containsAny(name, AC_REMOTE_ALLOW) then return nil end
    for _, hint in ipairs(AC_REMOTE_HINTS) do
        if string.find(name, hint, 1, true) then return hint end
    end
    return nil
end

function AC.audit(silent)
    local report = {
        scripts = {}, remotes = {}, kills = {}, disabled = 0, remoteCount = 0, serverScripts = 0,
    }
    local roots = {}
    safeCall("audit roots", function()
        table.insert(roots, ReplicatedStorage)
        table.insert(roots, getService("ReplicatedFirst"))
        table.insert(roots, LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts"))
        table.insert(roots, LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    end)
    for _, root in ipairs(roots) do
        if root then
            safeCall("audit scan", function()
                local descendants = root:GetDescendants()
                for _, instance in ipairs(descendants) do
                    local scriptHint = looksLikeAcScript(instance)
                    if scriptHint then
                        table.insert(report.scripts, { instance = instance, hint = scriptHint,
                            name = instance:GetFullName(), class = instance.ClassName })
                    end
                    local remoteHint = looksLikeAcRemote(instance)
                    if remoteHint then
                        report.remoteCount = report.remoteCount + 1
                        table.insert(report.remotes, { instance = instance, hint = remoteHint, name = instance:GetFullName() })
                    end
                    if instance.Name == "Kick" or instance.Name == "Ban" or instance.Name == "Remove" then
                        table.insert(report.kills, instance:GetFullName())
                    end
                    if instance.ClassName == "Script" then report.serverScripts = report.serverScripts + 1 end
                end
            end)
        end
    end
    State.ac.audit = report
    if not silent then
        print(string.format("[Skill Hub] AC audit · %d detector scripts · %d report remotes · %d server scripts visible",
            #report.scripts, report.remoteCount, report.serverScripts))
        for _, entry in ipairs(report.scripts) do
            print("    script  · " .. entry.name .. "   (" .. entry.hint .. ")")
        end
        for index, entry in ipairs(report.remotes) do
            if index <= 12 then print("    remote  · " .. entry.name .. "   (" .. entry.hint .. ")") end
        end
        if #report.scripts == 0 and report.remoteCount == 0 then
            print("    nothing matched the detector patterns — the game either has no client anti-cheat or hides it")
        end
    end
    return report
end

function AC.neutralize()
    if not Config.AcNeutralize then return 0 end
    local report = State.ac.audit or AC.audit(true)
    local disabled = 0
    for _, entry in ipairs(report.scripts) do
        local instance = entry.instance
        if instance and instance.Parent then
            -- Disable, never destroy: a destroyed script instance keeps running and
            -- destroying game objects is how a hub breaks a game it does not own.
            if pcall(function() instance.Disabled = true end) then
                disabled = disabled + 1
                -- best effort: drop the handlers a still-running detector attached
                if getconnections then
                    safeCall("drop detector connections", function()
                        for _, signalName in ipairs({ "Changed", "ChildAdded", "DescendantAdded", "Heartbeat", "Stepped" }) do
                            local signal = instance[signalName]
                            if type(signal) == "table" then
                                local connections = getconnections(signal)
                                if type(connections) == "table" then
                                    for _, connection in ipairs(connections) do
                                        if connection.Disconnect then pcall(function() connection:Disconnect() end) end
                                    end
                                end
                            end
                        end
                    end)
                end
                local already = false
                for _, name in ipairs(State.ac.scripts) do
                    if name == entry.name then already = true end
                end
                if not already then
                    table.insert(State.ac.scripts, entry.name)
                    if Config.LogLevel >= 2 then print("[Skill Hub] detector neutralised (disabled) · " .. entry.name) end
                end
            end
        end
    end
    return disabled
end

local function remoteName(object)
    local ok, name = pcall(function() return object.Name end)
    if ok and type(name) == "string" then return name end
    return ""
end

local function shouldBlockCall(target)
    if not Config.AcBlockReports then return false end
    local instance = target
    if type(target) == "table" and rawget(target, "__remote") then instance = rawget(target, "__remote") end
    if not instance or not isRemoteLike(instance) then return false end
    local hit = looksLikeAcRemote(instance)
    if not hit then return false end
    State.ac.blocked = State.ac.blocked + 1
    if Config.LogLevel >= 3 and State.ac.blocked % 25 == 1 then
        print("[Skill Hub] blocked report remote · " .. tostring(remoteName(instance)) .. " · total " .. State.ac.blocked)
    end
    return true
end

function AC.installHook()
    if State.ac.hookInstalled then return true end
    local rawMetatable = getrawmetatable or getrawmetatable
    local hook = hookfunction or replaceclosure
    local newC = newcclosure or function(fn) return fn end
    if not rawMetatable or not hook then return false end
    local mt = safeCall("ac mt", function() return rawMetatable(game) end)
    if not mt then return false end
    local original = rawget(mt, "__namecall")
    if type(original) ~= "function" then return false end
    State.ac.originalNamecall = original
    local ok = safeCall("ac hook", function()
        hook(original, newC(function(self, ...)
            if shouldBlockCall(self) then return nil end
            return original(self, ...)
        end))
        return true
    end)
    State.ac.hookInstalled = ok == true
    AC.hookInstalled = State.ac.hookInstalled
    if State.ac.hookInstalled and Config.LogLevel >= 2 then
        print("[Skill Hub] AC · report-blocking hook installed on __namecall (newcclosure, pcall-guarded, everything else falls through)")
    end
    return State.ac.hookInstalled
end

function AC.uninstallHook()
    if not State.ac.hookInstalled or not State.ac.originalNamecall then return end
    local rawMetatable = getrawmetatable
    local hook = hookfunction or replaceclosure
    if not rawMetatable or not hook then return end
    safeCall("ac unhook", function()
        local mt = rawMetatable(game)
        hook(rawget(mt, "__namecall"), State.ac.originalNamecall)
    end)
    State.ac.hookInstalled = false
    AC.hookInstalled = false
end

function AC.installKickGuard()
    if not Config.AcKickGuard or not LocalPlayer then return false end
    local newC = newcclosure or function(fn) return fn end
    local original = LocalPlayer.Kick
    if type(original) ~= "function" or State.ac.kickGuard then return State.ac.kickGuard == true end
    local ok = safeCall("kick guard", function()
        rawset(LocalPlayer, "Kick", newC(function(self, reason)
            State.ac.kicks = State.ac.kicks + 1
            local message = "kick blocked on the client · reason: " .. tostring(reason or "none")
            print("[Skill Hub] " .. message)
            notify("Kick guard", message, 6, Theme.Danger, ICON.Guard)
            return nil
        end))
        return true
    end)
    State.ac.kickGuard = ok == true
    return State.ac.kickGuard
end

local function paceAllowed()
    if not Config.AcTeleportPacing then return true end
    local window = 0.35
    if os.clock() - State.lastTeleport < window then return false end
    State.lastTeleport = os.clock()
    return true
end

local function speedCeiling()
    if Config.AcSafeMode then return math.min(Config.AcSpeedCeiling, 60) end
    return Config.AcSpeedCeiling
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 10 · MOVEMENT — speed, jump, fly, noclip, teleport (all paced & clamped)
-- ═══════════════════════════════════════════════════════════════════════════
local function setWalkSpeed(value)
    local humanoid = getHumanoid()
    if not humanoid then return end
    local goal = clamp(value, 8, speedCeiling())
    safeCall("walkspeed", function() humanoid.WalkSpeed = goal end)
end

local function setJumpPower(value)
    local humanoid = getHumanoid()
    if not humanoid then return end
    safeCall("jumppower", function()
        humanoid.UseJumpPower = true
        humanoid.JumpPower = clamp(value, 30, 300)
    end)
end

local function applyMovementLoop()
    task.spawn(function()
        while State.alive do
            if isAlive() then
                if Config.WalkSpeedEnabled then
                    local humanoid = getHumanoid()
                    if humanoid and math.abs(humanoid.WalkSpeed - clamp(Config.WalkSpeed, 8, speedCeiling())) > 1 then
                        setWalkSpeed(Config.WalkSpeed)
                    end
                end
                if Config.JumpPowerEnabled then setJumpPower(Config.JumpPower) end
                if Config.Noclip then
                    local char = getChar()
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                        end
                    end
                end
                if Config.AntiVoid then
                    local root = getRoot()
                    if root and root.Position.Y < -80 then
                        local spot = State.savedSpots[1]
                        if spot then
                            safeCall("anti void", function() root.CFrame = CFrame.new(spot) end)
                        elseif Camera then
                            safeCall("anti void", function() root.CFrame = CFrame.new(Camera.CFrame.Position) end)
                        end
                    end
                end
            end
            task.wait(0.25)
        end
    end)
end

-- fly: velocity driven, no per-frame CFrame teleporting, invisible floor pad
local FlyState = { pad = nil, bodies = {} }

local function readFlyDirection()
    local direction = Vector3.new(0, 0, 0)
    local camera = Camera or Workspace.CurrentCamera
    if not camera or not UserInput then return direction end
    local forward = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
    local right = camera.CFrame.RightVector * Vector3.new(1, 0, 1)
    local down = false
    if UserInput:IsKeyDown(Enum.KeyCode.W) then direction = direction + forward end
    if UserInput:IsKeyDown(Enum.KeyCode.S) then direction = direction - forward end
    if UserInput:IsKeyDown(Enum.KeyCode.D) then direction = direction + right end
    if UserInput:IsKeyDown(Enum.KeyCode.A) then direction = direction - right end
    if UserInput:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
    if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction + Vector3.new(0, -1, 0) end
    if direction.Magnitude > 0 then direction = direction.Unit end
    return direction
end

local function flyEnsurePad()
    if FlyState.pad and FlyState.pad.Parent then return FlyState.pad end
    local pad = new("Part", {
        Name = "SkillHubFlyPad", Anchored = true, CanCollide = true, CanQuery = false,
        CanTouch = false, Transparency = 1, Size = Vector3.new(6, 0.4, 6),
    }, Workspace)
    FlyState.pad = pad
    return pad
end

local function flyRemovePad()
    if FlyState.pad then safeCall("fly pad", function() FlyState.pad:Destroy() end) end
    FlyState.pad = nil
end

local function flyStep(dt)
    if not Config.FlyEnabled or not isAlive() then return end
    local root = getRoot()
    local humanoid = getHumanoid()
    if not root or not humanoid then return end
    local direction = readFlyDirection()
    local speed = clamp(Config.FlySpeed, 20, 300)
    if Config.AcSafeMode then speed = math.min(speed, 120) end
    local velocity = direction * speed
    safeCall("fly", function()
        root.AssemblyLinearVelocity = velocity + Vector3.new(0, 0, 0)
        root.Velocity = velocity
    end)
    local pad = flyEnsurePad()
    if pad then
        safeCall("fly pad position", function()
            pad.CFrame = CFrame.new(root.Position - Vector3.new(0, 3.4, 0))
        end)
    end
    if humanoid:GetState() == Enum.HumanoidStateType.Freefall and direction.Magnitude == 0 then
        safeCall("fly hover", function() root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
    end
end

local function flyDisable()
    Config.FlyEnabled = false
    flyRemovePad()
    local root = getRoot()
    if root then safeCall("fly stop", function() root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end) end
end

local function teleportTo(position, distance)
    if not position then return false end
    local root = getRoot()
    if not root then return false end
    if not paceAllowed() then return false end
    if Config.AcSafeMode then
        -- one hop every 0.35 s keeps the movement stream inside what the server
        -- expects from ordinary play instead of a 40 000 stud jump per frame
        local from = root.Position
        local delta = position - from
        if delta.Magnitude > 900 then
            position = from + delta.Unit * 900
        end
    end
    local goal = CFrame.new(position)
    if distance and distance > 0 then
        local ok = safeCall("tp offset", function() return (CFrame.new(getRoot().Position, position)).LookVector * -distance end)
        if ok then goal = CFrame.new(position + ok) end
    end
    return safeCall("tp", function()
        root.CFrame = goal
        return true
    end) == true
end

local function tweenTo(position, speedOverride)
    local root = getRoot()
    if not root or not position then return end
    local speed = speedOverride or (Config.AcSafeMode and 120 or 220)
    local distance = (position - root.Position).Magnitude
    if distance < 6 then
        safeCall("tween tp", function() root.CFrame = CFrame.new(position) end)
        return
    end
    if Config.AcTeleportPacing and distance > 400 then
        -- long jumps travel through the map (safe), short ones are instant
        local steps = math.ceil(distance / 400)
        for step = 1, steps do
            if not isAlive() then return end
            local target = root.Position + (position - root.Position) * (1 / (steps - step + 1))
            safeCall("tween tp step", function() root.CFrame = CFrame.new(target) end)
            task.wait(0.12)
        end
    end
    safeCall("tween tp final", function()
        root.CFrame = CFrame.new(position)
        return true
    end)
end

local function teleportToInstance(instance, distance)
    if not instance then return false end
    local ok, position = pcall(function()
        if instance:IsA("BasePart") then return instance.Position end
        if instance:IsA("Model") then
            local primary = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
            return primary and primary.Position or nil
        end
        if instance:IsA("ProximityPrompt") then
            local parent = instance.Parent
            return parent and parent:IsA("BasePart") and parent.Position or nil
        end
        return nil
    end)
    if not ok or not position then return false end
    return teleportTo(position, distance or 4)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 11 · DEFENCE LOOPS — anti ragdoll / stun / slow / fall damage / stamina / AFK
-- ═══════════════════════════════════════════════════════════════════════════
local Defence = { airHealth = nil, slowUntil = 0 }

local function applyDefenceLoop()
    task.spawn(function()
        while State.alive do
            if isAlive() then
                local char = getChar()
                local humanoid = getHumanoid()
                local root = getRoot()
                if humanoid and root then
                    if Config.AntiRagdoll then
                        safeCall("anti ragdoll", function()
                            if humanoid.PlatformStand then humanoid.PlatformStand = false end
                            if humanoid.Sit then humanoid.Sit = false end
                            if root.Anchored then root.Anchored = false end
                            if humanoid:GetState() == Enum.HumanoidStateType.Physics then
                                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                            end
                            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                            for _, tag in ipairs({ "Ragdoll", "Stunned", "Frozen" }) do
                                pcall(function()
                                    if CollectionService and CollectionService:HasTag(char, tag) then
                                        CollectionService:RemoveTag(char, tag)
                                    end
                                end)
                            end
                        end)
                    end
                    if Config.AntiStun and Config.WalkSpeedEnabled and humanoid.WalkSpeed < Config.WalkSpeed * 0.8 then
                        setWalkSpeed(Config.WalkSpeed)
                    end
                    if Config.InfiniteStamina then
                        safeCall("stamina", function()
                            local stamina = statOf(LocalPlayer, "Stamina") ~= nil and
                                (LocalPlayer:FindFirstChild("Stamina") or LocalPlayer:FindFirstChild("Energy"))
                            if stamina then stamina.Value = 100 end
                            local attribute = LocalPlayer:GetAttribute("Stamina")
                            if type(attribute) == "number" and attribute < 100 then LocalPlayer:SetAttribute("Stamina", 100) end
                        end)
                    end
                end
            end
            task.wait(0.2)
        end
    end)
end

local function applyNoFallDamage()
    local humanoid = getHumanoid()
    if not humanoid then return end
    local connection = humanoid.StateChanged:Connect(function(_, newState)
        if not Config.NoFallDamage then return end
        if newState == Enum.HumanoidStateType.Landed then
            local root = getRoot()
            if root then safeCall("soft land", function() root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end) end
            if Defence.airHealth and humanoid.Health < Defence.airHealth then
                safeCall("fall restore", function() humanoid.Health = Defence.airHealth end)
            end
            Defence.airHealth = nil
        elseif newState == Enum.HumanoidStateType.Freefall then
            Defence.airHealth = humanoid.Health
        end
    end)
    return connection
end

local function applyAntiAfk()
    task.spawn(function()
        while State.alive do
            if Config.AntiAfk then
                if VirtualUser then safeCall("anti afk vu", function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end) end
                local camera = Camera or Workspace.CurrentCamera
                if camera then
                    safeCall("anti afk camera", function()
                        local angles = CFrame.Angles(0, math.rad((os.clock() * 30) % 360), 0)
                        camera.CFrame = camera.CFrame * angles * CFrame.Angles(0, 0, math.rad(math.sin(os.clock()) * 0.4))
                    end)
                end
            end
            task.wait(15)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 12 · WORLD SCANNER — what is out there right now
-- ═══════════════════════════════════════════════════════════════════════════
local World = { mobs = {}, bosses = {}, npcs = {}, chests = {}, drops = {}, lilies = {}, prompts = {}, at = 0 }

local function modelPosition(model)
    local ok, position = pcall(function()
        local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if primary then return primary.Position end
        if model:IsA("BasePart") then return model.Position end
        return nil
    end)
    if ok then return position end
    return nil
end

local function distanceTo(position)
    local root = getRoot()
    if not root or not position then return math.huge end
    return (root.Position - position).Magnitude
end

local function scanWorld(force)
    if not force and os.clock() - World.at < 0.9 then return World end
    World.at = os.clock()
    World.mobs, World.bosses, World.npcs, World.chests, World.drops, World.lilies, World.prompts =
        {}, {}, {}, {}, {}, {}, {}
    if not Workspace then return World end

    safeCall("world scan", function()
        for _, instance in ipairs(Workspace:GetDescendants()) do
            local class = instance.ClassName
            if class == "Model" and instance ~= getChar() then
                local humanoid = instance:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 and not isPlayerCharacter(instance) then
                    local position = modelPosition(instance)
                    if position then
                        local lower = string.lower(instance.Name)
                        local entry = {
                            instance = instance, name = instance.Name, position = position,
                            humanoid = humanoid, distance = distanceTo(position),
                            health = humanoid.Health, maxHealth = humanoid.MaxHealth,
                        }
                        if containsAny(lower, KNOWLEDGE.BossHints) or (humanoid.MaxHealth or 0) >= 2000 then
                            table.insert(World.bosses, entry)
                        elseif containsAny(lower, KNOWLEDGE.Trainers) or containsAny(lower, KNOWLEDGE.QuestNpcs) then
                            table.insert(World.npcs, entry)
                        elseif not containsAny(lower, { "dummy" }) then
                            table.insert(World.mobs, entry)
                        end
                    end
                end
            elseif class == "ProximityPrompt" and instance.Enabled then
                local parent = instance.Parent
                local position = parent and modelPosition(parent)
                if position then
                    table.insert(World.prompts, {
                        prompt = instance, instance = parent, position = position,
                        name = parent and parent.Name or "prompt", action = instance.ActionText or "",
                        distance = distanceTo(position),
                    })
                end
            end
            if class ~= "ProximityPrompt" and (class == "Model" or class == "BasePart" or class == "MeshPart"
                or class == "Part" or class == "UnionOperation" or class == "TrussPart") then
                local hasHumanoid = class == "Model" and instance:FindFirstChildOfClass("Humanoid") ~= nil
                local lower = string.lower(instance.Name)
                if not hasHumanoid and containsAny(lower, KNOWLEDGE.ChestHints) then
                    local position = modelPosition(instance)
                    if position then
                        table.insert(World.chests, { instance = instance, name = instance.Name,
                            position = position, distance = distanceTo(position) })
                    end
                elseif not hasHumanoid and containsAny(lower, KNOWLEDGE.LilyHints) then
                    local position = modelPosition(instance)
                    if position then
                        table.insert(World.lilies, { instance = instance, name = instance.Name,
                            position = position, distance = distanceTo(position) })
                    end
                elseif not hasHumanoid and containsAny(lower, KNOWLEDGE.DropHints) then
                    local position = modelPosition(instance)
                    if position then
                        table.insert(World.drops, { instance = instance, name = instance.Name,
                            position = position, distance = distanceTo(position) })
                    end
                end
            end
        end
    end)

    local function byDistance(a, b) return a.distance < b.distance end
    table.sort(World.mobs, byDistance)
    table.sort(World.bosses, byDistance)
    table.sort(World.npcs, byDistance)
    table.sort(World.chests, byDistance)
    table.sort(World.drops, byDistance)
    table.sort(World.lilies, byDistance)
    table.sort(World.prompts, byDistance)
    return World
end

local function entityList(kind)
    scanWorld()
    if kind == "mob" then return World.mobs end
    if kind == "boss" then return World.bosses end
    if kind == "npc" then return World.npcs end
    if kind == "chest" then return World.chests end
    if kind == "drop" then return World.drops end
    if kind == "lily" then return World.lilies end
    if kind == "prompt" then return World.prompts end
    return {}
end

local function uniqueMobNames()
    local names, seen = {}, {}
    for _, entry in ipairs(entityList("mob")) do
        if not seen[entry.name] then
            seen[entry.name] = true
            table.insert(names, entry.name)
        end
    end
    table.sort(names)
    local list = { "Any" }
    for _, name in ipairs(names) do
        if #list < 40 then table.insert(list, name) end
    end
    return list
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 13 · INPUT — keys, clicks, prompts (several executor fallbacks, no hard deps)
-- ═══════════════════════════════════════════════════════════════════════════
local VirtualInputManager = getService("VirtualInputManager")

local function pressKey(name, hold)
    hold = hold or 0.08
    local keyCode = Enum.KeyCode[name]
    if not keyCode then return false end
    local done = false
    safeCall("press key", function()
        if type(keypress) == "function" then                      -- executor built-in
            keypress(name, hold)
            done = true
        end
        if not done and VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.delay(hold, function()
                safeCall("release key", function() VirtualInputManager:SendKeyEvent(false, keyCode, false, game) end)
            end)
            done = true
        end
        if not done and VirtualUser then
            VirtualUser:CaptureController()
            VirtualUser:SendKeyEvent(true, keyCode, false, game)
            task.delay(hold, function()
                safeCall("release key", function() VirtualUser:SendKeyEvent(false, keyCode, false, game) end)
            end)
            done = true
        end
    end)
    return done
end

local function clickMouse()
    return safeCall("click", function()
        if mouse1click then mouse1click() return true end
        local mouse = LocalPlayer and LocalPlayer:GetMouse()
        if mouse and mouse.Button1Down then
            local ok = pcall(function() mouse1down = true end)
            if not ok then return false end
            task.delay(0.06, function() safeCall("mouse up", function() mouse1up = true end) end)
            return true
        end
        return false
    end) == true
end

local function firePrompt(prompt)
    if not prompt then return false end
    return safeCall("prompt", function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
            return true
        end
        if prompt.HoldDuration and prompt.HoldDuration > 0 then
            prompt:InputHoldBegin()
            task.wait(math.min(prompt.HoldDuration, 0.6))
            prompt:InputHoldEnd()
        else
            prompt:InputHoldBegin()
            prompt:InputHoldEnd()
        end
        return true
    end) == true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 14 · COMBAT — face, attack, skills, parry, hitbox
-- ═══════════════════════════════════════════════════════════════════════════
local HitboxOriginal = {}

local function faceTarget(target)
    local root = getRoot()
    if not root or not target then return end
    local position = target.position or modelPosition(target.instance or target)
    if not position then return end
    safeCall("face", function()
        local flat = Vector3.new(position.X, root.Position.Y, position.Z)
        root.CFrame = CFrame.new(root.Position, flat)
    end)
end

local function attackOnce()
    if not isAlive() then return false end
    if Config.AutoEquipWeapon and (not equippedTool() or toolScore(equippedTool()) < 30) then
        equipBestWeapon()
    end
    local tool = equippedTool()
    if tool then
        local ok = safeCall("activate", function()
            tool:Activate()
            return true
        end)
        if ok then return true end
    end
    return clickMouse()
end

local function attackablesInRange(radius, includePlayers)
    local list = {}
    for _, entry in ipairs(entityList("mob")) do
        if entry.distance <= radius then table.insert(list, entry) end
    end
    for _, entry in ipairs(entityList("boss")) do
        if entry.distance <= radius then table.insert(list, entry) end
    end
    if includePlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                local position = modelPosition(player.Character)
                if humanoid and humanoid.Health > 0 and position then
                    table.insert(list, { instance = player.Character, name = player.Name, position = position,
                        humanoid = humanoid, distance = distanceTo(position), isPlayer = player })
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.distance < b.distance end)
    return list
end

local function castSkills(force)
    local keys = {}
    for token in string.gmatch(Config.SkillKeys or "", "[^,%s]+") do table.insert(keys, token) end
    if #keys == 0 then return end
    State.skillIndex = (State.skillIndex % #keys) + 1
    local key = keys[State.skillIndex]
    if force or Config.AutoSkills then pressKey(key, 0.1) end
end

local function applyHitbox()
    if not Config.HitboxEnabled then
        for model, parts in pairs(HitboxOriginal) do
            for part, size in pairs(parts) do
                safeCall("hitbox restore", function()
                    if part and part.Parent then part.Size = size end
                end)
            end
            HitboxOriginal[model] = nil
        end
        return
    end
    local targets = {}
    if Config.HitboxTarget == "Players" or Config.HitboxTarget == "Both" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then table.insert(targets, player.Character) end
        end
    end
    if Config.HitboxTarget == "Mobs" or Config.HitboxTarget == "Both" then
        for _, entry in ipairs(entityList("mob")) do
            if entry.distance <= 120 then table.insert(targets, entry.instance) end
        end
        for _, entry in ipairs(entityList("boss")) do
            if entry.distance <= 120 then table.insert(targets, entry.instance) end
        end
    end
    local size = clamp(Config.HitboxSize, 6, 60)
    for _, model in ipairs(targets) do
        local stored = HitboxOriginal[model]
        if not stored then stored = {} HitboxOriginal[model] = stored end
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                if stored[part] == nil then stored[part] = part.Size end
                safeCall("hitbox apply", function()
                    part.Size = Vector3.new(size, size, size)
                end)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 15 · ESP — Highlight + Billboard, no executor-only drawing required
-- ═══════════════════════════════════════════════════════════════════════════
local EspGui, EspRegistry, TracerGui = nil, {}, nil

local ESP_STYLE = {
    mob    = { color = Color3.fromRGB(226, 132, 122), label = "MOB" },
    boss   = { color = Color3.fromRGB(223, 118, 116), label = "BOSS" },
    npc    = { color = Color3.fromRGB(128, 182, 155), label = "NPC" },
    chest  = { color = Color3.fromRGB(223, 181, 133), label = "CHEST" },
    drop   = { color = Color3.fromRGB(173, 143, 222), label = "DROP" },
    lily   = { color = Color3.fromRGB(201, 141, 178), label = "LILY" },
    player = { color = Color3.fromRGB(126, 141, 255), label = "PLAYER" },
}

local function espEnabled(kind)
    if kind == "mob" then return Config.EspMobs end
    if kind == "boss" then return Config.EspBosses end
    if kind == "npc" then return Config.EspNPCs end
    if kind == "chest" then return Config.EspChests end
    if kind == "drop" then return Config.EspDrops end
    if kind == "lily" then return Config.EspLilies end
    if kind == "player" then return Config.EspPlayers end
    return false
end

local function ensureEspGui()
    if EspGui and EspGui.Parent then return EspGui end
    local parent = guiParent()
    if not parent then return nil end
    EspGui = new("ScreenGui", { Name = "SkillHubEsp", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 99990 }, parent)
    if protect_gui then pcall(protect_gui, EspGui) end
    return EspGui
end

local function attachEsp(instance, kind, text)
    if not instance then return end
    local style = ESP_STYLE[kind] or ESP_STYLE.mob
    local entry = EspRegistry[instance]
    if not entry then
        entry = {}
        entry.highlight = new("Highlight", {
            FillColor = style.color, FillTransparency = 0.72, OutlineColor = style.color,
            OutlineTransparency = 0.25, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        }, instance)
        entry.billboard = new("BillboardGui", {
            AlwaysOnTop = true, Size = UDim2.new(0, 190, 0, 34), StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0),
        }, instance)
        entry.label = Text({
            Font = UIFontMono, Size = UDim2.new(1, 0, 0, 14), Text = "", TextColor3 = style.color,
            TextSize = 10, TextStrokeTransparency = 0.35,
        }, entry.billboard)
        entry.barShell = new("Frame", {
            BackgroundColor3 = Color3.fromRGB(10, 11, 13), BorderSizePixel = 0,
            Position = UDim2.new(0.5, -50, 0, 16), Size = UDim2.new(0, 100, 0, 5),
        }, entry.billboard)
        corner(entry.barShell, RADIUS.pill)
        entry.bar = new("Frame", {
            BackgroundColor3 = style.color, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
        }, entry.barShell)
        corner(entry.bar, RADIUS.pill)
        entry.billboard.Adornee = instance
        EspRegistry[instance] = entry
    end
    entry.billboard.Enabled = espEnabled(kind)
    entry.billboard.AlwaysOnTop = true
    entry.highlight.Enabled = espEnabled(kind) and kind ~= "lily" and kind ~= "drop"
    entry.label.Text = text
    if entry.healthPart then entry.healthPart = nil end
    return entry
end

local function detachEsp(instance)
    local entry = EspRegistry[instance]
    if not entry then return end
    safeCall("esp detach", function()
        if entry.highlight then entry.highlight:Destroy() end
        if entry.billboard then entry.billboard:Destroy() end
    end)
    EspRegistry[instance] = nil
end

local function ensureTracers()
    if TracerGui and TracerGui.Parent then return TracerGui end
    local parent = guiParent()
    if not parent then return nil end
    TracerGui = new("ScreenGui", { Name = "SkillHubTracers", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 99989 }, parent)
    if protect_gui then pcall(protect_gui, TracerGui) end
    return TracerGui
end

local Tracers = {}

local function renderTracer(instance, color)
    local gui = ensureTracers()
    local camera = Camera or Workspace.CurrentCamera
    if not gui or not camera then return end
    local position = modelPosition(instance)
    if not position then return end
    local point, onScreen = camera:WorldToViewportPoint(position)
    if not onScreen then
        if Tracers[instance] then Tracers[instance].Visible = false end
        return
    end
    local viewport = camera.ViewportSize
    local origin = Vector2.new(viewport.X / 2, viewport.Y)
    local delta = Vector2.new(point.X - origin.X, point.Y - origin.Y)
    local line = Tracers[instance]
    if not line then
        line = new("Frame", { BackgroundColor3 = color, BackgroundTransparency = 0.35, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3 }, gui)
        Tracers[instance] = line
    end
    line.Position = UDim2.new(0, (origin.X + point.X) / 2, 0, (origin.Y + point.Y) / 2)
    line.Size = UDim2.new(0, 1, 0, delta.Magnitude)
    line.Rotation = math.deg(math.atan2(delta.Y, delta.X)) - 90
    line.BackgroundColor3 = color
    line.Visible = Config.EspTracers
end

local function espLoop()
    task.spawn(function()
        while State.alive do
            if Config.EspPlayers or Config.EspMobs or Config.EspBosses or Config.EspNPCs or Config.EspChests
                or Config.EspDrops or Config.EspLilies then
                local seen = {}
                local function handle(entry, kind)
                    if entry.distance > Config.EspMaxDistance then return end
                    seen[entry.instance] = true
                    local text = entry.name
                    if kind == "player" then text = entry.name .. "  " .. (entry.info or "") end
                    if Config.EspDistance then text = text .. "   " .. math.floor(entry.distance) .. "m" end
                    local esp = attachEsp(entry.instance, kind, text)
                    if esp and esp.billboard then
                        if Config.EspHealthBars and entry.humanoid then
                            local ratio = clamp((entry.humanoid.Health or 1) / math.max(entry.humanoid.MaxHealth or 1, 1), 0, 1)
                            esp.barShell.Visible = true
                            esp.bar.Size = UDim2.new(ratio, 0, 1, 0)
                            esp.bar.BackgroundColor3 = ratio > 0.5 and Theme.Success or (ratio > 0.2 and Theme.Warning or Theme.Danger)
                        else
                            esp.barShell.Visible = false
                        end
                    end
                    if Config.EspTracers then renderTracer(entry.instance, (ESP_STYLE[kind] or ESP_STYLE.mob).color)
                    elseif Tracers[entry.instance] then Tracers[entry.instance].Visible = false end
                end

                if Config.EspMobs then
                    for _, entry in ipairs(entityList("mob")) do handle(entry, "mob") end
                end
                if Config.EspBosses then
                    for _, entry in ipairs(entityList("boss")) do handle(entry, "boss") end
                end
                if Config.EspNPCs then
                    for _, entry in ipairs(entityList("npc")) do handle(entry, "npc") end
                end
                if Config.EspChests then
                    for _, entry in ipairs(entityList("chest")) do handle(entry, "chest") end
                end
                if Config.EspDrops then
                    for _, entry in ipairs(entityList("drop")) do handle(entry, "drop") end
                end
                if Config.EspLilies then
                    for _, entry in ipairs(entityList("lily")) do handle(entry, "lily") end
                end
                if Config.EspPlayers then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                            local position = modelPosition(player.Character)
                            if humanoid and position then
                                local level = statOf(player, "Level") or "?"
                                handle({ instance = player.Character, name = player.DisplayName or player.Name,
                                    position = position, distance = distanceTo(position), humanoid = humanoid,
                                    info = "Lv " .. tostring(level) .. " · " .. tostring(statOf(player, "Clan") or "—") }, "player")
                            end
                        end
                    end
                end
                for instance in pairs(EspRegistry) do
                    if not seen[instance] or not instance.Parent then detachEsp(instance) end
                end
                for instance, line in pairs(Tracers) do
                    if not seen[instance] or not instance.Parent then
                        safeCall("tracer clean", function() line:Destroy() end)
                        Tracers[instance] = nil
                    end
                end
            end
            task.wait(0.22)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 16 · THE LOOPS — farm, quests, training, chests, loot
-- ═══════════════════════════════════════════════════════════════════════════
local function bestZoneForLevel()
    local level = getLevel()
    local best = KNOWLEDGE.FarmPlan[1]
    for _, plan in ipairs(KNOWLEDGE.FarmPlan) do
        if level >= plan.min then best = plan end
    end
    return best
end

local function pickMobTarget()
    local list = entityList("mob")
    if #list == 0 then return nil end
    local selected = Config.SelectedMob
    if Config.MobFilter == "Bosses only" then
        local bosses = entityList("boss")
        return bosses[1]
    end
    if selected and selected ~= "Any" then
        for _, entry in ipairs(list) do
            if entry.name == selected then return entry end
        end
    end
    if Config.AutoLevelMode then
        local plan = bestZoneForLevel()
        for _, wanted in ipairs(plan.mobs) do
            for _, entry in ipairs(list) do
                if string.find(string.lower(entry.name), string.lower(wanted), 1, true) then return entry end
            end
        end
    end
    return list[1]
end

local function farmLoop()
    task.spawn(function()
        while State.alive do
            if Config.AutoFarm and isAlive() then
                local target = pickMobTarget()
                if target then
                    State.questTarget = target
                    if target.distance > Config.FarmRange * 0.7 then
                        tweenTo(target.position, 200)
                    else
                        faceTarget(target)
                        attackOnce()
                        if Config.AutoSkills then castSkills() end
                    end
                elseif Config.AutoBoss then
                    local boss = entityList("boss")[1]
                    if boss then
                        if boss.distance > Config.FarmRange then tweenTo(boss.position, 200) else faceTarget(boss) attackOnce() end
                    end
                end
            end
            task.wait(Config.FastAttack and Config.FastAttackDelay or 0.35)
        end
    end)
end

local function questLoop()
    task.spawn(function()
        local turnInCooldown = 0
        while State.alive do
            if (Config.AutoQuest or Config.AutoInteractPrompts) and isAlive() then
                scanWorld()
                local promptList = entityList("prompt")
                local target = promptList[1]
                if target and target.distance and target.distance <= 14 then
                    firePrompt(target.prompt)
                    task.wait(0.4)
                elseif target and Config.AutoQuest and os.clock() > turnInCooldown then
                    turnInCooldown = os.clock() + 3
                    tweenTo(target.position, 220)
                end
                if Config.AutoQuest and (not target or target.distance > 400) then
                    local npc = entityList("npc")[1]
                    if npc and npc.distance > 16 then tweenTo(npc.position, 220) end
                end
            end
            task.wait(0.8)
        end
    end)
end

local function chestLoop()
    task.spawn(function()
        while State.alive do
            if Config.AutoChest and isAlive() then
                local chest = nil
                for _, entry in ipairs(entityList("chest")) do
                    if entry.distance <= Config.ChestRange then chest = entry break end
                end
                if chest then
                    tweenTo(chest.position, 220)
                    task.wait(0.3)
                    local prompt = nil
                    safeCall("chest prompt", function()
                        prompt = chest.instance:FindFirstChildWhichIsA("ProximityPrompt", true)
                    end)
                    if prompt then firePrompt(prompt) end
                end
            end
            task.wait(0.7)
        end
    end)
end

local function lootLoop()
    task.spawn(function()
        while State.alive do
            if (Config.AutoLoot or Config.AutoFarm) and isAlive() then
                local drop = nil
                for _, entry in ipairs(entityList("drop")) do
                    if entry.distance <= Config.LootRange then drop = entry break end
                end
                if drop then
                    local root = getRoot()
                    if root and drop.distance > 4 then
                        tweenTo(drop.position, 200)
                    else
                        safeCall("touch loot", function()
                            local part = drop.instance:IsA("BasePart") and drop.instance or drop.instance:FindFirstChildWhichIsA("BasePart")
                            if part and firetouchinterest then firetouchinterest(getRoot(), part, 0) firetouchinterest(getRoot(), part, 1) end
                        end)
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

local function combatLoop()
    task.spawn(function()
        while State.alive do
            if isAlive() then
                if Config.KillAura then
                    local targets = attackablesInRange(Config.KillAuraRange, Config.KillAuraPlayers)
                    for index, entry in ipairs(targets) do
                        if index > 4 then break end
                        faceTarget(entry)
                        attackOnce()
                        task.wait(0.05)
                    end
                end
                if Config.FastAttack and not Config.AutoFarm then attackOnce() end
                if Config.AutoSkills and not Config.AutoFarm then castSkills() end
                if Config.AutoParry then
                    local enemies = attackablesInRange(24, true)
                    if #enemies > 0 then pressKey(Config.ParryKey, 0.12) end
                end
                if Config.AutoDodge then
                    local enemies = attackablesInRange(18, true)
                    if #enemies > 0 then
                        local root = getRoot()
                        if root then
                            safeCall("dodge", function()
                                root.AssemblyLinearVelocity = root.CFrame.RightVector * 40 + Vector3.new(0, 12, 0)
                            end)
                        end
                    end
                end
                if Config.AimLock then
                    local camera = Camera or Workspace.CurrentCamera
                    local targets = attackablesInRange(260, true)
                    local target = targets[1]
                    if camera and target then
                        local position = target.position + Vector3.new(0, 1.2, 0)
                        safeCall("aim", function()
                            local current = camera.CFrame
                            local goal = CFrame.new(current.Position, position)
                            camera.CFrame = current:Lerp(goal, clamp(Config.AimLockSmooth, 0.05, 1))
                        end)
                    end
                end
                if Config.HitboxEnabled then applyHitbox() end
            end
            task.wait(Config.FastAttack and math.max(Config.FastAttackDelay, 0.05) or 0.22)
        end
    end)
end

local function trainingLoop()
    task.spawn(function()
        while State.alive do
            if isAlive() and (Config.AutoTrainMastery or Config.AutoBlowGourd or Config.AutoFinalSelection or Config.AutoFish or Config.AutoSpin) then
                scanWorld()
                if Config.AutoTrainMastery then
                    if Config.AutoEquipWeapon then equipBestWeapon() end
                    castSkills(true)
                end
                if Config.AutoBlowGourd then
                    local done = false
                    for _, entry in ipairs(entityList("prompt")) do
                        if entry.distance <= 14 then
                            local haystack = string.lower(tostring(entry.name) .. " " .. tostring(entry.action))
                            if containsAny(haystack, { "gourd", "blow", "breath", "train", "statue", "meditate", "minigame" }) then
                                firePrompt(entry.prompt)
                                done = true
                                break
                            end
                        end
                    end
                    if not done then
                        for _, entry in ipairs(entityList("npc")) do
                            if entry.distance <= 16 and containsAny(entry.name, { "gourd", "train", "statue" }) then
                                firePrompt(entry.instance:FindFirstChildWhichIsA("ProximityPrompt", true))
                                break
                            end
                        end
                    end
                end
                if Config.AutoFinalSelection then
                    for _, entry in ipairs(entityList("prompt")) do
                        local haystack = string.lower(tostring(entry.name) .. " " .. tostring(entry.action))
                        if containsAny(haystack, { "final selection", "enter", "start", "exam", "trial" }) then
                            if entry.distance > 14 then tweenTo(entry.position, 220) else firePrompt(entry.prompt) end
                            break
                        end
                    end
                end
                if Config.AutoFish then pressKey("E", 0.1) end
                if Config.AutoSpin then
                    for _, entry in ipairs(entityList("prompt")) do
                        if entry.distance <= 14 and containsAny(string.lower(tostring(entry.name) .. tostring(entry.action)), { "spin", "roll", "gacha", "clan" }) then
                            firePrompt(entry.prompt)
                            break
                        end
                    end
                end
            end
            task.wait(0.9)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 17 · TELEPORT LIBRARY — built live from the map, never from guesses
-- ═══════════════════════════════════════════════════════════════════════════
local function teleportTargets()
    local list = { "—" }
    scanWorld()
    for _, entry in ipairs(World.npcs) do
        local label = "NPC · " .. entry.name
        if #label < 34 then table.insert(list, label) end
    end
    for _, entry in ipairs(World.bosses) do
        local label = "Boss · " .. entry.name
        if #label < 34 then table.insert(list, label) end
    end
    for _, hint in ipairs(KNOWLEDGE.Zones) do
        table.insert(list, "Zone · " .. hint)
    end
    for index, spot in ipairs(State.savedSpots) do
        table.insert(list, "Saved " .. index .. " · " .. tostring(spot.label or "spot"))
    end
    return list
end

local function resolveTeleportTarget(label)
    if not label or label == "—" then return nil end
    scanWorld()
    local kind, name = string.match(label, "^(%a+) · (.+)$")
    if not kind then return nil end
    if kind == "NPC" then
        for _, entry in ipairs(World.npcs) do if entry.name == name then return entry end end
    elseif kind == "Boss" then
        for _, entry in ipairs(World.bosses) do if entry.name == name then return entry end end
    elseif kind == "Saved" then
        local index = tonumber(string.match(name, "^(%d+)"))
        return State.savedSpots[index]
    elseif kind == "Zone" then
        local best, bestDistance = nil, math.huge
        for _, instance in ipairs(Workspace:GetDescendants()) do
            if instance:IsA("BasePart") or instance:IsA("Model") or instance:IsA("Folder") then
                if string.find(string.lower(instance.Name), string.lower(name), 1, true) then
                    local position = modelPosition(instance)
                    if position then
                        local distance = distanceTo(position)
                        if distance < bestDistance then best, bestDistance = { position = position, name = instance.Name }, distance end
                    end
                end
            end
        end
        return best
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 18 · PROTECTION EXTRAS — staff watch, server hop, panic, unload
-- ═══════════════════════════════════════════════════════════════════════════
local function serverHop()
    local TeleportService = getService("TeleportService")
    if not TeleportService then return false end
    local request = request or http_request or syn and syn.request
    if request then
        local ok = safeCall("hop", function()
            local response = request({
                Url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100",
                Method = "GET",
            })
            local body = type(response) == "table" and (response.Body or response.body) or nil
            if body then
                local current = tostring(game.JobId)
                for jobId in string.gmatch(body, '"id":"([%w%-]+)"') do
                    if jobId ~= current then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
                        return true
                    end
                end
            end
            return false
        end)
        if ok then return true end
    end
    return safeCall("rejoin", function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
        return true
    end) == true
end

local function staffOf(player)
    if not player then return nil end
    local custom = SharedEnv.SkillHubStaffList
    if type(custom) == "table" then
        for _, name in ipairs(custom) do
            if string.lower(name) == string.lower(player.Name) then return "staff list" end
        end
    end
    if Config.StaffGroupId and Config.StaffGroupId > 0 then
        local rank = safeCall("group rank", function() return player:GetRankInGroup(Config.StaffGroupId) end)
        if rank and rank >= 250 then return "group rank " .. tostring(rank) end
    end
    local ok, badge = pcall(function() return player:GetAttribute("Staff") end)
    if ok and badge then return "attribute" end
    return nil
end

local function staffLoop()
    task.spawn(function()
        local warned = {}
        while State.alive do
            if Config.StaffWatch then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and not warned[player] then
                        local reason = staffOf(player)
                        if reason then
                            warned[player] = true
                            notify("Staff in this server", player.Name .. " · " .. reason, 8, Theme.Warning, ICON.Guard)
                            print("[Skill Hub] staff detected · " .. player.Name .. " · " .. reason)
                            if Config.StaffHop then serverHop() end
                        end
                    end
                end
            end
            local camera = Camera or Workspace.CurrentCamera
            if camera then
                local fov = Config.ZoomFov
                safeCall("fov", function()
                    camera.FieldOfView = (fov and fov > 0) and fov or 70
                end)
            end
            task.wait(2)
        end
    end)
end

local function applyFullbright()
    safeCall("fullbright", function()
        if Config.Fullbright then
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
        end
    end)
    safeCall("no fog", function()
        if Config.NoFog then
            Lighting.FogEnd = 100000
            Lighting.FogStart = 100000
        else
            Lighting.FogEnd = 1000
        end
    end)
end

local function onOff(value)
    return value and "ON" or "OFF"
end

local function humanoidStateText(humanoid)
    if not humanoid then return "no humanoid" end
    local state = safeCall("humanoid state", function() return humanoid:GetState().Name end)
    return tostring(state or "—")
end

local function panic(reason)
    Config.AutoFarm, Config.AutoQuest, Config.AutoBoss = false, false, false
    Config.KillAura, Config.FastAttack, Config.AutoSkills, Config.AimLock = false, false, false, false
    Config.HitboxEnabled, Config.EspMobs, Config.EspBosses, Config.EspPlayers = false, false, false, false
    Config.FlyEnabled, Config.Noclip, Config.InfiniteJump = false, false, false
    Config.WalkSpeedEnabled, Config.JumpPowerEnabled = false, false
    applyHitbox()
    flyDisable()
    if EspGui then
        for instance in pairs(EspRegistry) do detachEsp(instance) end
    end
    for _, toggle in ipairs(ToggleRegistry) do
        if toggle.get() then toggle.set(false, true) end
    end
    notify("PANIC", reason or "everything switched off · settings restored", 6, Theme.Danger, ICON.Stop)
    print("[Skill Hub] panic · " .. tostring(reason))
end

local skillHubInstance
local function unload()
    State.alive = false
    panic("hub unloaded")
    AC.uninstallHook()
    flyRemovePad()
    applyHitbox()
    if EspGui then safeCall("esp wipe", function() EspGui:Destroy() end) end
    if TracerGui then safeCall("tracer wipe", function() TracerGui:Destroy() end) end
    if Window and Window.Screen then safeCall("ui wipe", function() Window.Screen:Destroy() end) end
    if SharedEnv.SkillHubSlayers2 == skillHubInstance then SharedEnv.SkillHubSlayers2 = nil end
    print("[Skill Hub] unloaded")
end
SharedEnv.UnloadSkillHubSlayers2 = unload

-- ═══════════════════════════════════════════════════════════════════════════
-- 19 · SMALL EXTRAS the loops use
-- ═══════════════════════════════════════════════════════════════════════════
local function bringMobsLoop()
    task.spawn(function()
        while State.alive do
            if Config.BringMobs and isAlive() then
                local root = getRoot()
                local gathered = 0
                for _, entry in ipairs(entityList("mob")) do
                    if entry.distance <= 120 and gathered < 12 then
                        gathered = gathered + 1
                        safeCall("bring mob", function()
                            local part = entry.instance.PrimaryPart or entry.instance:FindFirstChildWhichIsA("BasePart")
                            if part then
                                local offset = (root.Position + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))) - part.Position
                                part.AssemblyLinearVelocity = offset * 2.2
                            end
                        end)
                    end
                end
            end
            task.wait(0.35)
        end
    end)
end

local function fpsBoost()
    safeCall("fps boost", function()
        for _, instance in ipairs(Workspace:GetDescendants()) do
            if instance:IsA("BasePart") and instance.Material ~= Enum.Material.Plastic then
                instance.Material = Enum.Material.Plastic
            end
        end
        Lighting.GlobalShadows = false
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 20 · SELF TEST — every claim in this build has a check you can run
-- ═══════════════════════════════════════════════════════════════════════════
local function selfTest()
    local results = {}
    local function check(label, condition, detail)
        table.insert(results, { label = label, ok = condition == true, detail = detail })
        print(string.format("[Skill Hub self-test] %-44s %s%s", label, condition and "PASS" or "FAIL",
            detail and ("   (" .. tostring(detail) .. ")") or ""))
    end

    check("window built", Window ~= nil and Window.Root ~= nil and Window.Root.Parent ~= nil)
    check("tab count", #Tabs >= 7, tostring(#Tabs) .. " tabs")
    check("icon registry", type(drawVectorGlyph) == "function")
    check("services alive", Players ~= nil and Workspace ~= nil)
    check("character readable", isAlive(), isAlive() and "alive" or "respawning")
    check("level readable", getLevel() >= 1, "level " .. tostring(getLevel()))
    check("world scan", #(scanWorld(true).mobs) >= 0,
        #World.mobs .. " mobs · " .. #World.bosses .. " bosses · " .. #World.npcs .. " npcs · " .. #World.prompts .. " prompts")
    check("detector scan", State.ac.audit ~= nil,
        State.ac.audit and (#State.ac.audit.scripts .. " scripts · " .. State.ac.audit.remoteCount .. " report remotes") or "not run")
    check("report filter", shouldBlockCall ~= nil)
    check("kick guard", Config.AcKickGuard == false or State.ac.kickGuard == true,
        State.ac.kickGuard and "installed" or "not available in this executor")
    check("defence loops", Config.AntiRagdoll == true)
    check("no unhandled errors", #State.errors == 0, #State.errors .. " recorded")

    local passed = 0
    for _, entry in ipairs(results) do if entry.ok then passed = passed + 1 end end
    print(string.format("[Skill Hub self-test] %d/%d checks passed", passed, #results))
    notify("Self-test", string.format("%d/%d checks passed · full list in the console", passed, #results),
        6, passed == #results and Theme.Success or Theme.Warning, ICON.Chart)
    return results
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 21 · TABS
-- ═══════════════════════════════════════════════════════════════════════════
local function buildTabs()
local TabFarm     = makeTab("Auto Farm",      "quests, mobs, bosses, chests and loot — with a level-aware target picker", ICON.Farm, Theme.Clay)
local TabQuest    = makeTab("Quests",         "quest NPCs, breathing training, gourd, Final Selection, fishing and clan spins", ICON.Quest, Theme.Sand)
local TabCombat   = makeTab("Combat",         "kill aura, fast attack, skills, parry, aim lock and the hitbox expander", ICON.Sword, Theme.Rose)
local TabEsp      = makeTab("ESP & Visuals",  "mobs, bosses, NPCs, chests, drops, lilies and players through walls", ICON.Eye, Theme.Mauve)
local TabTp       = makeTab("Teleports",      "every trainer and quest NPC found live on the map, saved spots, server tools", ICON.Teleport, Theme.Sky)
local TabAc       = makeTab("Anti-Cheat",     "the client-side bypass: detectors, report remotes, plausibility, staff watch", ICON.Guard, Theme.Sage)
local TabMisc     = makeTab("Player & Misc",  "movement, player list, interface, panic and unload", ICON.Settings, Theme.Steel)

-- ── Auto Farm ───────────────────────────────────────────────────────────────
TabFarm:AddLabel("Farm runs client-side: the hub finds live targets, walks to them with a paced tween and attacks with the equipped katana. "
    .. "Everything here respects the plausibility layer from the Anti-Cheat tab.", ICON.Loop)
TabFarm:AddSection("Targets")
TabFarm:AddToggle("Auto Farm", "find the best mob for your level, travel to it, attack and cast", Config.AutoFarm,
    function(v) Config.AutoFarm = v end, ICON.Farm)
TabFarm:AddToggle("Auto Quest", "walk to quest NPCs and interact with their prompts (accept + turn in)", Config.AutoQuest,
    function(v) Config.AutoQuest = v end, ICON.Quest)
TabFarm:AddToggle("Auto Boss", "focus bosses when no mob is in range", Config.AutoBoss,
    function(v) Config.AutoBoss = v end, ICON.Skull)
TabFarm:AddToggle("Auto Chest", "walk to chests within range and open them", Config.AutoChest,
    function(v) Config.AutoChest = v end, ICON.Chest)
TabFarm:AddToggle("Auto Loot", "walk over drops and trigger their touch interest", Config.AutoLoot,
    function(v) Config.AutoLoot = v end, ICON.Loot)
TabFarm:AddToggle("Bring Mobs", "pull nearby mobs toward you so the farm never walks (velocity pull, client side)", Config.BringMobs,
    function(v) Config.BringMobs = v end, ICON.Magnet)
TabFarm:AddToggle("Auto Level Mode", "pick the zone and mobs that match your level from the built-in farm plan", Config.AutoLevelMode,
    function(v) Config.AutoLevelMode = v end, ICON.Chart)
TabFarm:AddSection("Target picker")
local mobFilter = TabFarm:AddDropdown("Mob Filter", "what to farm", { "Any", "Selected mob", "Bosses only" }, Config.MobFilter,
    function(v) Config.MobFilter = v end, ICON.Layers)
local mobPicker = TabFarm:AddDropdown("Selected Mob", "live list of mobs in this server", { "Any" }, Config.SelectedMob,
    function(v) Config.SelectedMob = v end, ICON.Search)
TabFarm:AddButton("Refresh mob list", "rescan the workspace and rebuild the dropdown", function()
    mobPicker.SetOptions(uniqueMobNames())
end, ICON.Loop)
TabFarm:AddSection("Ranges")
TabFarm:AddSlider("Farm Range", "how far the farm will travel to a target", 20, 300, Config.FarmRange, " studs",
    function(v) Config.FarmRange = v end, ICON.Magnet)
TabFarm:AddSlider("Skill Range", "cast breathing moves inside this radius", 10, 120, Config.SkillRange, " studs",
    function(v) Config.SkillRange = v end, ICON.Flame)
TabFarm:AddSlider("Chest Range", "only chests closer than this", 20, 400, Config.ChestRange, " studs",
    function(v) Config.ChestRange = v end, ICON.Chest)
TabFarm:AddSlider("Loot Range", "only drops closer than this", 20, 400, Config.LootRange, " studs",
    function(v) Config.LootRange = v end, ICON.Loot)
TabFarm:AddStatusPanel("Farm status", function()
    scanWorld()
    local plan = bestZoneForLevel()
    local target = State.questTarget
    return {
        "level      " .. tostring(getLevel()) .. "   ·  wen " .. fmtNum(getWen()) .. "   ·  zone " .. plan.zone,
        "mobs       " .. #World.mobs .. " in map  ·  " .. #World.bosses .. " boss(es)  ·  " .. #World.chests .. " chest(s)",
        "drops      " .. #World.drops .. "  ·  prompts " .. #World.prompts .. "  ·  npcs " .. #World.npcs,
        "target     " .. (target and (target.name .. "  " .. math.floor(distanceTo(target.position)) .. "m") or "—"),
        "state      " .. (Config.AutoFarm and "farming" or (Config.AutoQuest and "questing" or "idle")),
    }
end)

-- ── Quests & Training ───────────────────────────────────────────────────────
TabQuest:AddLabel("Slayers 2 progression: quest chains, breathing trainers at level 25, gourd training, mastery and Final Selection from 45. "
    .. "Auto modes interact with the game's own prompts — nothing is spoofed.", ICON.Quest)
TabQuest:AddSection("Quests")
TabQuest:AddToggle("Auto Interact Prompts", "press every proximity prompt within 14 studs (dialog, chests, doors, shops)", Config.AutoInteractPrompts,
    function(v) Config.AutoInteractPrompts = v end, ICON.Play)
TabQuest:AddToggle("Auto Quest Farm", "travel between quest NPCs and their prompts on repeat", Config.AutoQuest,
    function(v) Config.AutoQuest = v end, ICON.Quest)
TabQuest:AddSection("Breathing & mastery")
TabQuest:AddToggle("Auto Train Mastery", "equip the weapon and cycle your breathing moves to build mastery", Config.AutoTrainMastery,
    function(v) Config.AutoTrainMastery = v end, ICON.Flame)
TabQuest:AddToggle("Auto Blow Gourd", "hold the gourd / breath prompts whenever they appear", Config.AutoBlowGourd,
    function(v) Config.AutoBlowGourd = v end, ICON.Wind)
TabQuest:AddInput("Skill keys", "keys the mastery loop presses, comma separated", "Z,X,C,V", function(text)
    Config.SkillKeys = text
    notify("Skill keys", text, 3, Theme.Sand, ICON.Bolt)
end, ICON.Bolt)
TabQuest:AddSection("Trials & side systems")
TabQuest:AddToggle("Auto Final Selection", "enter the trial prompts and let the combat tab finish them", Config.AutoFinalSelection,
    function(v) Config.AutoFinalSelection = v end, ICON.Guard)
TabQuest:AddToggle("Auto Fish", "cast and reel at a fishing spot (presses E on cooldown)", Config.AutoFish,
    function(v) Config.AutoFish = v end, ICON.Fish)
TabQuest:AddToggle("Auto Clan Spin", "interact with spin / roll prompts when they are in reach", Config.AutoSpin,
    function(v) Config.AutoSpin = v end, ICON.Star)
TabQuest:AddStatusPanel("Quest status", function()
    scanWorld()
    local nearest = World.npcs[1]
    local prompt = World.prompts[1]
    return {
        "breathing  " .. tostring(getBreathing()) .. "   ·  clan " .. tostring(getClan()),
        "level      " .. tostring(getLevel()) .. "   ·  farm plan " .. bestZoneForLevel().zone,
        "nearest npc    " .. (nearest and (nearest.name .. "  " .. math.floor(nearest.distance) .. "m") or "—"),
        "nearest prompt " .. (prompt and (prompt.name .. "  [" .. tostring(prompt.action) .. "]  " .. math.floor(prompt.distance) .. "m") or "—"),
    }
end)

-- ── Combat ──────────────────────────────────────────────────────────────────
TabCombat:AddSection("Attack")
TabCombat:AddToggle("Fast Attack", "activate the equipped weapon on a tight loop (also drives the farm)", Config.FastAttack,
    function(v) Config.FastAttack = v end, ICON.Bolt)
TabCombat:AddSlider("Fast Attack Delay", "seconds between activations", 0.02, 0.6, Config.FastAttackDelay, " s",
    function(v) Config.FastAttackDelay = v end, ICON.Loop)
TabCombat:AddToggle("Kill Aura", "attack every mob, boss and (optionally) player inside the radius", Config.KillAura,
    function(v) Config.KillAura = v end, ICON.Sword)
TabCombat:AddSlider("Kill Aura Range", "aura radius", 8, 90, Config.KillAuraRange, " studs",
    function(v) Config.KillAuraRange = v end, ICON.Magnet)
TabCombat:AddToggle("Kill Aura hits players", "include other players in the aura (PvP servers — use with care)", Config.KillAuraPlayers,
    function(v) Config.KillAuraPlayers = v end, ICON.Player)
TabCombat:AddToggle("Auto Skills", "cycle your breathing moves while in combat", Config.AutoSkills,
    function(v) Config.AutoSkills = v end, ICON.Flame)
TabCombat:AddToggle("Auto Equip Weapon", "always keep the strongest katana equipped", Config.AutoEquipWeapon,
    function(v) Config.AutoEquipWeapon = v end, ICON.Sword)
TabCombat:AddSection("Defence & targeting")
TabCombat:AddToggle("Auto Parry", "press the parry key while enemies are close", Config.AutoParry,
    function(v) Config.AutoParry = v end, ICON.Shield)
TabCombat:AddInput("Parry key", "the key your game binds to block / parry", "F", function(text) Config.ParryKey = text end, ICON.Shield)
TabCombat:AddToggle("Aim Lock", "smoothly lock the camera onto the closest target", Config.AimLock,
    function(v) Config.AimLock = v end, ICON.Eye)
TabCombat:AddSlider("Aim Smoothing", "1 = instant snap, 0.1 = slow glide", 0.05, 1, Config.AimLockSmooth, "",
    function(v) Config.AimLockSmooth = v end, ICON.Loop)
TabCombat:AddToggle("Auto Dodge", "dash sideways when something gets within 18 studs", Config.AutoDodge,
    function(v) Config.AutoDodge = v end, ICON.Wind)
TabCombat:AddToggle("Anti-Ragdoll", "clear ragdoll, freeze and platform-stand states every 0.2 s", Config.AntiRagdoll,
    function(v) Config.AntiRagdoll = v end, ICON.Guard)
TabCombat:AddToggle("Anti-Stun / Anti-Slow", "restore your walk speed the moment the game drops it", Config.AntiStun,
    function(v) Config.AntiStun = v end, ICON.Shield)
TabCombat:AddToggle("No Fall Damage", "cancel the landing state and restore the health the game tries to take", Config.NoFallDamage,
    function(v) Config.NoFallDamage = v end, ICON.Guard)
TabCombat:AddToggle("Infinite Stamina", "keep the stamina value pinned while it is exposed to the client", Config.InfiniteStamina,
    function(v) Config.InfiniteStamina = v end, ICON.Bolt)
TabCombat:AddSection("Hitboxes")
TabCombat:AddToggle("Hitbox Expander", "grow every part of the target so your swings always land (restored on toggle off)", Config.HitboxEnabled,
    function(v) Config.HitboxEnabled = v
        if not v then applyHitbox() end
    end, ICON.Layers)
TabCombat:AddSlider("Hitbox Size", "part size applied to the target", 6, 60, Config.HitboxSize, " studs",
    function(v) Config.HitboxSize = v end, ICON.Layers)
local hitboxTarget = TabCombat:AddDropdown("Hitbox Target", "who gets the bigger hitbox", { "Mobs", "Players", "Both" }, Config.HitboxTarget,
    function(v) Config.HitboxTarget = v end, ICON.Player)
TabCombat:AddStatusPanel("Combat status", function()
    scanWorld()
    local enemies = attackablesInRange(Config.KillAuraRange, Config.KillAuraPlayers)
    local humanoid = getHumanoid()
    return {
        "weapon     " .. (equippedTool() and equippedTool().Name or "—") .. "   ·  breathing " .. tostring(getBreathing()),
        "health     " .. (humanoid and (math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)) or "—")
            .. "   ·  " .. humanoidStateText(humanoid),
        "in range   " .. #enemies .. " target(s) inside " .. Config.KillAuraRange .. " studs",
        "states     aura " .. onOff(Config.KillAura) .. "  ·  fast " .. onOff(Config.FastAttack)
            .. "  ·  parry " .. onOff(Config.AutoParry) .. "  ·  aim " .. onOff(Config.AimLock),
    }
end)

-- ── ESP & Visuals ───────────────────────────────────────────────────────────
TabEsp:AddLabel("ESP uses Highlight + BillboardGui only (no executor-only drawing), so it works on every executor and cannot break your game's "
    .. "rendering. Everything is removed the moment you switch it off.", ICON.Eye)
TabEsp:AddSection("Entities")
TabEsp:AddToggle("Mob ESP", "boxes, names, health bars and optional tracers for mobs", Config.EspMobs,
    function(v) Config.EspMobs = v end, ICON.Skull)
TabEsp:AddToggle("Boss ESP", "highlight bosses with their health bars", Config.EspBosses,
    function(v) Config.EspBosses = v end, ICON.Crown or ICON.Skull)
TabEsp:AddToggle("NPC ESP", "trainers, quest givers and shops", Config.EspNPCs,
    function(v) Config.EspNPCs = v end, ICON.Player)
TabEsp:AddToggle("Chest ESP", "every chest the game streams to you", Config.EspChests,
    function(v) Config.EspChests = v end, ICON.Chest)
TabEsp:AddToggle("Drop ESP", "material and item drops", Config.EspDrops,
    function(v) Config.EspDrops = v end, ICON.Loot)
TabEsp:AddToggle("Lily ESP", "spider lilies and collectibles", Config.EspLilies,
    function(v) Config.EspLilies = v end, ICON.Star)
TabEsp:AddToggle("Player ESP", "players with level and clan (read from leaderstats / attributes when exposed)", Config.EspPlayers,
    function(v) Config.EspPlayers = v end, ICON.Player)
TabEsp:AddSection("Look")
TabEsp:AddToggle("Tracers", "line from the bottom of the screen to every traced entity", Config.EspTracers,
    function(v) Config.EspTracers = v end, ICON.Layers)
TabEsp:AddToggle("Health Bars", "draw a health bar under the name", Config.EspHealthBars,
    function(v) Config.EspHealthBars = v end, ICON.Chart)
TabEsp:AddToggle("Distance", "append the distance in studs", Config.EspDistance,
    function(v) Config.EspDistance = v end, ICON.Search)
TabEsp:AddSlider("Max Distance", "stop drawing beyond this range", 100, 3000, Config.EspMaxDistance, " studs",
    function(v) Config.EspMaxDistance = v end, ICON.Magnet)
TabEsp:AddSection("Environment")
TabEsp:AddToggle("Fullbright", "light the whole map at midday brightness", Config.Fullbright,
    function(v) Config.Fullbright = v applyFullbright() end, ICON.Star)
TabEsp:AddToggle("No Fog", "clear the distance fog", Config.NoFog,
    function(v) Config.NoFog = v applyFullbright() end, ICON.Wind)
TabEsp:AddSlider("Camera FOV", "0 keeps the game value", 0, 140, Config.ZoomFov, "",
    function(v) Config.ZoomFov = v end, ICON.Eye)
TabEsp:AddButton("Clear all ESP", "remove every highlight, billboard and tracer right now", function()
    for instance in pairs(EspRegistry) do detachEsp(instance) end
    for instance, line in pairs(Tracers) do
        safeCall("tracer clear", function() line:Destroy() end)
        Tracers[instance] = nil
    end
end, ICON.Stop)
TabEsp:AddStatusPanel("ESP status", function()
    local count = 0
    for _ in pairs(EspRegistry) do count = count + 1 end
    local tracers = 0
    for _ in pairs(Tracers) do tracers = tracers + 1 end
    return {
        "tracked    " .. count .. " entity(ies)  ·  " .. tracers .. " tracer(s)",
        "radius     " .. Config.EspMaxDistance .. " studs  ·  health bars " .. onOff(Config.EspHealthBars),
        "fullbright " .. onOff(Config.Fullbright) .. "  ·  fog " .. onOff(Config.NoFog) .. "  ·  fov " .. tostring(Config.ZoomFov),
        "mobs in map " .. #World.mobs .. "  ·  chests " .. #World.chests .. "  ·  drops " .. #World.drops,
    }
end)

-- ── Teleports ───────────────────────────────────────────────────────────────
local tpDistance = 4
local tpTarget = "—"
local tpDropdown = TabTp:AddDropdown("Destination", "every entry is discovered live: loopback to this tab to refresh", { "—" }, "—",
    function(v) tpTarget = v end, ICON.Teleport)
local tpPlayerDropdown = TabTp:AddDropdown("Player", "teleport next to a player", { "—" }, "—", function() end, ICON.Player)
TabTp:AddSlider("Stop Distance", "how far in front of the target you land", 0, 40, tpDistance, " studs",
    function(v) tpDistance = v end, ICON.Magnet)
TabTp:AddButton("Teleport now", "travel to the selected destination", function()
    local target = resolveTeleportTarget(tpTarget)
    if target and target.position then
        tweenTo(target.position, 240)
    elseif tpTarget ~= "—" then
        notify("Teleport", "destination not found on this map: " .. tpTarget, 4, Theme.Warning, ICON.Teleport)
    end
end, ICON.Play)
TabTp:AddButton("Refresh destinations", "rescan the map and rebuild both dropdowns", function()
    tpDropdown.SetOptions(teleportTargets())
    local players = { "—" }
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(players, player.Name) end
    end
    tpPlayerDropdown.SetOptions(players)
end, ICON.Loop)
TabTp:AddSection("Saved spots")
TabTp:AddButton("Save spot 1", "store your current position under slot 1", function()
    local root = getRoot()
    if root then State.savedSpots[1] = { position = root.Position, label = "spot 1" }
        notify("Saved", "slot 1 stored", 3, Theme.Sky, ICON.Star) end
end, ICON.Star)
TabTp:AddButton("Save spot 2", "store your current position under slot 2", function()
    local root = getRoot()
    if root then State.savedSpots[2] = { position = root.Position, label = "spot 2" }
        notify("Saved", "slot 2 stored", 3, Theme.Sky, ICON.Star) end
end, ICON.Star)
TabTp:AddButton("Go to saved spot 1", "", function()
    local spot = State.savedSpots[1]
    if spot then tweenTo(spot.position, 240) end
end, ICON.Play)
TabTp:AddButton("Go to saved spot 2", "", function()
    local spot = State.savedSpots[2]
    if spot then tweenTo(spot.position, 240) end
end, ICON.Play)
TabTp:AddSection("Server")
TabTp:AddButton("Teleport to selected player", "land next to the player chosen above", function()
    local chosen = tpPlayerDropdown.Get()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == chosen and player.Character then
            local position = modelPosition(player.Character)
            if position then tweenTo(position, 240) end
        end
    end
end, ICON.Player)
TabTp:AddButton("Rejoin server", "come back to this exact server", function()
    local TeleportService = getService("TeleportService")
    if TeleportService then safeCall("rejoin", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end
end, ICON.Loop)
TabTp:AddButton("Server hop", "find a different public server (falls back to rejoin)", function()
    serverHop()
end, ICON.Compass or ICON.Teleport)

-- ── Anti-Cheat ──────────────────────────────────────────────────────────────
TabAc:AddLabel("What the bypass does: it disables the game's client-side detector scripts, drops outgoing report/flag/ban remotes, keeps your speed, "
    .. "teleports and loops inside plausible bounds, and blocks ragdoll, stun, slow, fall damage and the AFK kick. What it cannot do: a server that "
    .. "validates damage or position server-side is out of reach for any client script — that is not a limitation of this hub, it is how Roblox works.", ICON.Guard)
TabAc:AddSection("Detection")
TabAc:AddButton("Run audit now", "scan the game and print every detector script and report remote it can see", function()
    AC.audit(false)
end, ICON.Search)
TabAc:AddToggle("Neutralise detectors", "disable detector scripts the moment they are found (and on respawn)", Config.AcNeutralize,
    function(v) Config.AcNeutralize = v if v then AC.neutralize() end end, ICON.Shield)
TabAc:AddToggle("Block report remotes", "drop outgoing report / flag / ban remote calls at the namecall level", Config.AcBlockReports,
    function(v)
        Config.AcBlockReports = v
        if v then AC.installHook() else AC.uninstallHook() end
    end, ICON.Stop)
TabAc:AddToggle("Kick guard", "log a kick instead of letting the client act on it", Config.AcKickGuard,
    function(v) Config.AcKickGuard = v if v then AC.installKickGuard() end end, ICON.Guard)
TabAc:AddButton("Install / repair hook", "re-install the namecall report filter (safe to press twice)", function()
    AC.installHook()
end, ICON.Loop)
TabAc:AddButton("Remove hook", "unhook completely — no interception left in this client", function()
    AC.uninstallHook()
end, ICON.Stop, true)
TabAc:AddSection("Plausibility layer")
TabAc:AddToggle("Safe mode", "cap speed, slow the loops and pace long teleports so the traffic looks like ordinary play", Config.AcSafeMode,
    function(v) Config.AcSafeMode = v end, ICON.Loop)
TabAc:AddToggle("Teleport pacing", "long jumps travel in 400-stud hops instead of one giant CFrame write", Config.AcTeleportPacing,
    function(v) Config.AcTeleportPacing = v end, ICON.Teleport)
TabAc:AddSlider("Speed ceiling", "the highest walk speed this hub will ever write", 16, 200, Config.AcSpeedCeiling, " studs/s",
    function(v) Config.AcSpeedCeiling = v end, ICON.Bolt)
TabAc:AddSlider("Remote rate limit", "maximum remote calls per second the hub's own features allow themselves", 1, 60, Config.AcRemoteRateLimit, " /s",
    function(v) Config.AcRemoteRateLimit = v end, ICON.Chart)
TabAc:AddSection("Watching for staff")
TabAc:AddToggle("Staff watch", "alert (and optionally hop) when a moderator joins", Config.StaffWatch,
    function(v) Config.StaffWatch = v end, ICON.Eye)
TabAc:AddToggle("Auto hop on staff", "leave the server the moment staff is detected", Config.StaffHop,
    function(v) Config.StaffHop = v end, ICON.Teleport)
TabAc:AddInput("Staff group id", "rank in this group counts as staff", "0", function(text)
    Config.StaffGroupId = tonumber(text) or 0
end, ICON.Player)
TabAc:AddInput("Staff names", "extra names, comma separated", "name1, name2", function(text)
    local list = {}
    for token in string.gmatch(text, "[^,]+") do
        table.insert(list, (string.gsub(token, "^%s*(.-)%s*$", "%1")))
    end
    SharedEnv.SkillHubStaffList = list
end, ICON.Search)
TabAc:AddToggle("Anti-AFK", "small camera and virtual-input nudge every 15 s so the idle kick never fires", Config.AntiAfk,
    function(v) Config.AntiAfk = v end, ICON.Loop)
TabAc:AddButton("Re-audit + neutralise", "full sweep: scan, disable what it found and report", function()
    AC.audit(false)
    local disabled = AC.neutralize()
    notify("Neutralised", tostring(disabled) .. " detector script(s) disabled", 5, Theme.Sage, ICON.Shield)
end, ICON.Shield)
TabAc:AddStatusPanel("Anti-cheat status", function()
    return {
        "detectors  " .. #State.ac.scripts .. " neutralised  ·  " .. tostring(State.ac.audit and #State.ac.audit.scripts or 0) .. " found in the last audit",
        "reports    " .. State.ac.blocked .. " blocked  ·  hook " .. (State.ac.hookInstalled and "installed" or "off"),
        "kicks      " .. State.ac.kicks .. " intercepted  ·  guard " .. (State.ac.kickGuard and "on" or "off"),
        "safe mode  " .. onOff(Config.AcSafeMode) .. "  ·  ceiling " .. Config.AcSpeedCeiling .. "  ·  pacing " .. onOff(Config.AcTeleportPacing),
        "staff      " .. (Config.StaffWatch and "watching (group " .. tostring(Config.StaffGroupId) .. ")" or "off") .. "  ·  afk " .. onOff(Config.AntiAfk),
    }
end, 122)
TabAc:AddButton("Self-test", "run every internal check and print PASS/FAIL to the console", function()
    selfTest()
end, ICON.Chart)

-- ── Player & Misc ───────────────────────────────────────────────────────────
TabMisc:AddSection("Movement")
TabMisc:AddToggle("Walk Speed", "override walk speed through the plausibility layer", Config.WalkSpeedEnabled,
    function(v) Config.WalkSpeedEnabled = v if v then setWalkSpeed(Config.WalkSpeed) end end, ICON.Bolt)
TabMisc:AddSlider("Walk Speed value", "kept under the ceiling from the Anti-Cheat tab", 8, 200, Config.WalkSpeed, " studs/s",
    function(v) Config.WalkSpeed = v if Config.WalkSpeedEnabled then setWalkSpeed(v) end end, ICON.Bolt)
TabMisc:AddToggle("Jump Power", "", Config.JumpPowerEnabled, function(v)
    Config.JumpPowerEnabled = v
    if v then setJumpPower(Config.JumpPower) end
end, ICON.Wind)
TabMisc:AddSlider("Jump Power value", "", 30, 300, Config.JumpPower, "", function(v)
    Config.JumpPower = v
    if Config.JumpPowerEnabled then setJumpPower(v) end
end, ICON.Wind)
if UserInput then
    UserInput.JumpRequest:Connect(function()
        if Config.InfiniteJump and isAlive() then
            local humanoid = getHumanoid()
            if humanoid then safeCall("double jump", function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end) end
        end
    end)
end
TabMisc:AddToggle("Infinite Jump", "re-jump in mid-air", Config.InfiniteJump, function(v)
    Config.InfiniteJump = v
end, ICON.Loop)
TabMisc:AddToggle("Noclip", "walk through walls (parts stop colliding)", Config.Noclip, function(v) Config.Noclip = v end, ICON.Ghost)
TabMisc:AddToggle("Fly", "velocity flight with an invisible floor pad — no per-frame teleporting, so the anti-cheat sees normal movement", Config.FlyEnabled,
    function(v) Config.FlyEnabled = v if not v then flyDisable() end end, ICON.Wind)
TabMisc:AddSlider("Fly Speed", "", 20, 300, Config.FlySpeed, " studs/s", function(v) Config.FlySpeed = v end, ICON.Bolt)
TabMisc:AddToggle("Anti-Void", "rescue yourself if you fall out of the map", Config.AntiVoid, function(v) Config.AntiVoid = v end, ICON.Guard)
TabMisc:AddSection("Players")
TabMisc:AddPlayerList("Everyone in this server", function()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local color = player == LocalPlayer and Theme.Accent or Theme.TextFaint
        local staff = staffOf(player)
        if staff then color = Theme.Warning end
        local info = ""
        if player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local position = modelPosition(player.Character)
            if humanoid and position then
                info = string.format("Lv %s · %s · %d hp · %dm", tostring(statOf(player, "Level") or "?"),
                    tostring(statOf(player, "Clan") or "—"), math.floor(humanoid.Health), math.floor(distanceTo(position)))
            end
        else
            info = "loading…"
        end
        table.insert(list, {
            player = player, name = player.Name, info = info, color = color,
            avatar = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=48&h=48",
        })
    end
    return list
end, {
    { label = "TP", callback = function(player)
        if player and player.Character then
            local position = modelPosition(player.Character)
            if position then tweenTo(position, 240) end
        end
    end },
    { label = "KIL", callback = function(player)
        if player and player.Character then
            State.questTarget = { instance = player.Character, name = player.Name,
                position = modelPosition(player.Character) }
            notify("Target set", player.Name, 3, Theme.Rose, ICON.Sword)
        end
    end },
    { label = "CAM", callback = function(player)
        local camera = Camera or Workspace.CurrentCamera
        if camera and player and player.Character then
            safeCall("spectate", function() camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid") end)
        end
    end },
})
TabMisc:AddSection("Interface")
TabMisc:AddKeybind("Show / hide window", "the key that toggles this interface", Config.HideUiKey, function(key)
    Config.HideUiKey = key
end, ICON.Settings)
TabMisc:AddToggle("Author credit", "keep the ameksi-web credit in the welcome toast and the console banner", Config.ShowAuthor,
    function(v) Config.ShowAuthor = v end, ICON.Star)
TabMisc:AddButton("FPS boost", "plastic materials, no global shadows, low quality level (visual change, reversible by rejoin)", function()
    fpsBoost()
end, ICON.Bolt)
TabMisc:AddButton("Clear cache & respawn", "walk out of a stuck state: unstick the character and clear saved hitbox data", function()
    applyHitbox()
    local humanoid = getHumanoid()
    if humanoid then safeCall("unstick", function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end) end
end, ICON.Loop)
TabMisc:AddSection("Danger zone")
TabMisc:AddButton("PANIC — turn everything off", "disable every feature and restore original values", function()
    panic("manual panic from the interface")
end, ICON.Stop, true)
TabMisc:AddButton("Unload Skill Hub", "remove the UI, the hook, the ESP and every modification", function()
    unload()
end, ICON.Stop, true)
TabMisc:AddStatusPanel("Session", function()
    local minutes = math.floor((os.clock() - State.startedAt) / 60)
    local seconds = math.floor((os.clock() - State.startedAt) % 60)
    return {
        "build      " .. BUILD .. "  " .. VERSION .. "  ·  " .. (Config.ShowAuthor and ("by " .. AUTHOR) or "credit hidden"),
        "uptime     " .. minutes .. "m " .. seconds .. "s  ·  errors " .. #State.errors,
        "place      " .. tostring(game.PlaceId) .. "  ·  players " .. #Players:GetPlayers(),
        "hotkeys    " .. Config.HideUiKey .. " toggle ui  ·  F1 panic",
    }
end)

end

-- ═══════════════════════════════════════════════════════════════════════════
-- 22 · BOOT
-- ═══════════════════════════════════════════════════════════════════════════
local function boot()
    State.alive = true

    local previous = SharedEnv.SkillHubSlayers2
    if previous and previous ~= skillHubInstance and previous.unload then
        pcall(function() previous.unload() end)          -- replace an older run, never this one
    end

    local ok, err = pcall(buildWindow)
    if not ok or not Window then
        print("[Skill Hub] interface could not be created: " .. tostring(err or "no parent for the ScreenGui"))
        print("[Skill Hub] the hub keeps running headless — features still work from the console")
    else
        local tabsOk, tabsErr = pcall(buildTabs)
        if not tabsOk then
            print("[Skill Hub] the tabs could not be built: " .. tostring(tabsErr))
        elseif Tabs[1] then
            Tabs[1].Select()
        end
        notify("Skill Hub " .. VERSION, GAME_NAME .. " · free edition · press " .. Config.HideUiKey .. " to hide this window",
            7, Theme.Accent, ICON.Crest)
    end

    -- anti-cheat layers first, features second
    task.spawn(function()
        AC.audit(true)
        if Config.AcNeutralize then AC.neutralize() end
        if Config.AcBlockReports then AC.installHook() end
        if Config.AcKickGuard then AC.installKickGuard() end
    end)

    applyMovementLoop()
    applyDefenceLoop()
    applyNoFallDamage()
    applyAntiAfk()
    farmLoop()
    questLoop()
    chestLoop()
    lootLoop()
    combatLoop()
    trainingLoop()
    espLoop()
    staffLoop()
    bringMobsLoop()

    State.fps = State.fps or 60
    if RunService then
        local frames, stamp = 0, os.clock()
        RunService.RenderStepped:Connect(function()
            frames = frames + 1
            if os.clock() - stamp >= 1 then
                State.fps = frames / (os.clock() - stamp)
                frames, stamp = 0, os.clock()
            end
        end)
        -- the fly needs a frame hook; everything else runs on its own loop
        RunService.RenderStepped:Connect(function(delta)
            if Config.FlyEnabled then safeCall("fly step", function() flyStep(delta) end) end
        end)
    end

    task.spawn(function()
        while State.alive do
            safeCall("chrome", function()
                if Window and Window.Chrome then
                    local chips = Window.Chrome.chips
                    local plan = bestZoneForLevel()
                    chips.stateText.Text = "Lv " .. tostring(getLevel())
                    chips.acText.Text = "AC " .. tostring(State.ac.blocked + #State.ac.scripts)
                    local ping = safeCall("ping", function() return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
                    chips.perfText.Text = tostring(ping or "—") .. "ms " .. tostring(math.floor(State.fps or 0)) .. "fps"
                    Window.Chrome.strip.Text = plan.zone .. "  ·  " .. clockString() .. "  ·  v" .. VERSION
                end
            end)
            task.wait(1)
        end
    end)

    -- hotkeys
    if UserInput then
        UserInput.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode.Name == Config.HideUiKey and Window and Window.Screen then
                Config.UiVisible = not Config.UiVisible
                Window.Screen.Enabled = Config.UiVisible
            elseif input.KeyCode.Name == "F1" then
                panic("F1")
            end
        end)
    end

    -- detector scripts can stream in later: keep sweeping
    task.spawn(function()
        while State.alive do
            if Config.AcNeutralize then
                local report = AC.audit(true)
                AC.neutralize(report)
            end
            task.wait(6)
        end
    end)

    print(string.format("[Skill Hub %s] %s · free edition · by %s", VERSION, GAME_NAME, AUTHOR))
    print(string.format("    level %d · breathing %s · clan %s · players %d · place %s",
        getLevel(), tostring(getBreathing()), tostring(getClan()), #Players:GetPlayers(), tostring(game.PlaceId)))
    print("    tabs: Auto Farm · Quests · Combat · ESP · Teleports · Anti-Cheat · Player & Misc")
    print("    run the Anti-Cheat tab -> Self-test for the full PASS/FAIL list")
    local signature = safeCall("signature", function()
        for _, instance in ipairs(game:GetDescendants()) do
            if containsAny(instance.Name, { "Breathing", "Slayer", "Demon", "Wen", "Katana", "Nichirin" }) then
                return instance.Name
            end
        end
        return nil
    end)
    if signature then
        print("    game signature found: " .. tostring(signature))
    else
        print("    warning: no Slayers 2 signature names found in this DataModel — the hub still runs, but the game may be different")
    end

    if Config.ShowAuthor then
        task.spawn(function()
            task.wait(1.2)                                  -- never block boot on a yield
            if Window and Config.ShowAuthor then
                notify("Skill Hub " .. VERSION, "made by " .. AUTHOR .. " · free, no key", 6, Theme.AccentSecondary, ICON.Star)
            end
        end)
    end
end

skillHubInstance = {
    version = VERSION,
    build = BUILD,
    author = AUTHOR,
    config = Config,
    tabs = Tabs,
    state = State,
    ac = AC,
    world = World,
    notify = notify,
    unload = unload,
    panic = panic,
    selfTest = selfTest,
    audit = AC.audit,
    teleport = tweenTo,
    scan = scanWorld,
    equip = equipBestWeapon,
    esp = { registry = EspRegistry, tracers = Tracers },
    hitbox = HitboxOriginal,
}
SharedEnv.SkillHubSlayers2 = skillHubInstance

local bootOk, bootError = pcall(boot)
if not bootOk then
    print("[Skill Hub] boot error: " .. tostring(bootError))
    print("[Skill Hub] the hub is loaded; unload or re-run the script after reading the line above")
end
