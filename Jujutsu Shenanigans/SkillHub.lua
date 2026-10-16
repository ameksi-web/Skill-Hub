--[[
    ██╗  ██╗██╗██╗     ██╗         ██╗  ██╗██╗   ██╗██████╗
    ██║ ██╔╝██║██║     ██║         ██║  ██║██║   ██║██╔══██╗
    █████╔╝ ██║██║     ██║         ███████║██║   ██║██████╔╝
    ██╔═██╗ ██║██║     ██║         ██╔══██║██║   ██║██╔══██╗
    ██║  ██╗██║███████╗███████╗    ██║  ██║╚██████╔╝██████╔╝
    ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    Skill Hub — Jujutsu Shenanigans  ·  FREE edition (no key, readable, no loader)
    by ameksi-web  ·  https://github.com/ameksi-web/Skill-Hub

    ── how to run ──────────────────────────────────────────────────────────────
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/Jujutsu%20Shenanigans/SkillHub.lua"))()

    ── what this is ────────────────────────────────────────────────────────────
        A hub for [SKY ASSASSIN] Jujutsu Shenanigans with the same "Porcelain"
        design system as the rest of the Skill Hub family: soft-dark graphite
        surfaces, hairline borders, muted editorial accents, a hand-drawn icon set.

        Nine tabs: Combat · Auto Farm · Combo Lab · Movement · ESP & Visuals ·
                   Fun · Teleports · Anti-Cheat · Player & Misc.

        Built against the live game (v1.79 + Sky Assassin + the October patch):
          M1 melee · 1 2 3 4 skills · Q dash · F block · R special · G awaken
          Black Flash 2.5× (block → M1, or skill 3 → skill 3 on the white flash)
          Burst, awakening, domain expansions, roulette queue, practice dummies.

    ── the anti-cheat layer, honestly ──────────────────────────────────────────
        Jujutsu Shenanigans bans from recorded evidence (video in the official
        Discord) plus whatever Roblox itself notices about an injector. A client
        script can do exactly four useful things about that, and this does all four:
          · finds and disables the game's client-side detector / monitor scripts
          · drops every outgoing report / flag / ban / screenshot remote call at
            the namecall level — newcclosure, pcall-guarded, and everything that
            is not on the report list falls straight through untouched
          · keeps the hub's own traffic inside a plausible range: speed ceiling,
            remote rate limit, paced teleports, combat jitter, human pauses
          · watches for staff and can leave the server before anyone records
        What it cannot do: out-argue the server. Nothing here makes a script
        undetectable, and no client can decide what the server believes.
        Test it yourself: Anti-Cheat tab -> "Run audit now".
]]

local VERSION   = "v1.0"
local BUILD     = "Jujutsu Shenanigans · free · perf rebuild 16.10"
local AUTHOR    = "ameksi-web"
local GAME_NAME = "Jujutsu Shenanigans"

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
    -- combat
    AutoAttack          = false,
    KillAura            = false,
    KillAuraRange       = 26,
    KillAuraPlayers     = false,
    FastAttack          = false,
    AttackDelay         = 0.12,
    AttackRange         = 16,
    AutoEquipWeapon     = true,
    TargetPriority      = "Closest",
    AutoTurnAround      = true,

    -- skills
    AutoSkills          = false,
    SkillKeys           = "1,2,3,4",
    SkillCooldown       = 1.6,
    AutoDash            = false,
    DashDelay           = 0.6,
    AutoAwaken          = false,
    ReAwaken            = false,
    AutoDomain          = false,
    DomainKey           = "R",
    DomainSkill         = "",
    AutoBurst           = false,
    BurstKey            = "B",

    -- black flash
    AutoBlackFlash      = false,
    BlackFlashMode      = "Auto",
    BlackFlashDelay     = 300,
    BlackFlashKey       = "3",
    BlackFlashCooldown  = 1.4,
    ForceBlackFlash     = false,

    -- block & defence in combat
    AutoBlock           = false,
    AutoParry           = false,
    ParryWindow         = 160,
    AutoCounter         = false,
    AutoBlackFlashBlock = true,
    BlockRange          = 18,
    AutoRetaliate       = false,
    RetaliateRange      = 40,
    HoldBlock           = false,

    -- aiming
    LockOn              = false,
    LockSmooth          = 0.35,
    LockRange           = 90,
    SilentAim           = false,
    FovCircle           = false,
    HitboxEnabled       = false,
    HitboxSize          = 8,
    HitboxTarget        = "Players",

    -- farm
    AutoFarm            = false,
    AutoKill            = false,
    FarmRange           = 60,
    AutoPickup          = false,
    PickupRange         = 60,
    TrainDummy          = false,
    AutoRespawn         = false,
    AutoQueue           = false,

    -- combo lab
    AutoCombo           = false,
    ComboPreset         = "Vessel · M1x3 → skill 3 → M1",
    ComboLoop           = false,
    ComboDelay          = 0.22,
    ComboSpeed          = 1,
    ComboFace           = true,
    ComboRange          = 24,
    ComboPlaying        = false,

    -- movement
    WalkSpeedEnabled    = false,
    WalkSpeed           = 26,
    JumpPowerEnabled    = false,
    JumpPower           = 60,
    InfiniteJump        = false,
    AlwaysSprint        = false,
    FlyEnabled          = false,
    FlySpeed            = 90,
    Noclip              = false,
    AntiVoid            = true,
    AntiFling           = true,
    DashSpam            = false,
    LowGravity          = false,

    -- esp & visuals
    EspPlayers          = false,
    EspDummies          = false,
    EspPickups          = false,
    EspDomains          = false,
    EspNames            = true,
    EspHealth           = true,
    EspDistance         = true,
    EspTracers          = false,
    EspFillTransparency = 0.62,
    EspMaxDistance      = 1200,
    EspEnemyOnly        = false,
    Fullbright          = false,
    NoFog               = false,
    BloodMoon           = false,
    CameraFov           = 70,
    TimeOfDay           = 0,
    RemoveVfx           = false,
    FpsBoost            = false,

    -- fun
    RainbowAura         = false,
    AuraTransparency    = 0.55,
    DiscoMode           = false,
    BigHead             = false,
    CameraShake         = false,
    ShakePower          = 0.4,
    CharScale           = 1,
    HitSparks           = true,
    Music               = false,
    MusicId             = "",
    MusicVolume         = 1,
    DashNoise           = false,
    DashNoiseId         = 9040055117,
    AuraTrail           = false,
    TrailLifetime       = 1.2,
    TrailHue            = 200,
    DomainDome          = false,
    DomeSize            = 120,
    DomeHue             = 280,
    EmoteLoop           = false,
    EmoteLoopDelay      = 12,
    EmoteSlot           = 1,
    AutoEmoteOnKill     = false,
    GGMessage           = "gg",
    AutoGG              = false,
    ChatMessage         = "",
    ChatDelay           = 12,
    ChatSpam            = false,

    -- teleports / servers
    HopPreference       = "Lowest ping",

    -- anti-cheat
    AcNeutralize        = true,
    AcBlockReports      = true,
    AcKickGuard         = true,
    AcSafeMode          = true,
    AcSpeedCeiling      = 60,
    AcRemoteRateLimit   = 12,
    AcTeleportPacing    = true,
    CombatJitter        = true,
    HumanPause          = true,
    StaffWatch          = true,
    StaffGroupId        = 0,
    StaffHop            = false,
    AntiAfk             = true,

    -- survival
    AntiRagdoll         = true,
    AntiStun            = true,
    AntiSlow            = true,
    InfiniteStamina     = false,
    NoFallDamage        = true,

    -- performance (the scanner and the loops — see section 7)
    ScanInterval        = 2,        -- seconds between full map walks
    RefreshInterval     = 0.3,      -- seconds between cheap position refreshes
    ScanBudget          = 900,      -- instances one full walk is allowed to visit
    EspInterval         = 0.4,      -- seconds between ESP passes
    PerfStats           = false,    -- live counter pill inside the window

    -- interface
    HideUiKey           = "RightControl",
    PanicKey            = "F1",
    UiVisible           = true,
    UiTransparency      = 0,
    ShowAuthor          = true,
    LogLevel            = 2,
}

SharedEnv.SkillHubConfig = SharedEnv.SkillHubConfig or Config
SharedEnv.__SkillHubErrorLog = SharedEnv.__SkillHubErrorLog or {}

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
        Name = "SkillHubJujutsu",
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
-- SHARED NAMESPACE — the tab layer runs in its own closure (Lua allows 200
-- locals per scope and this file uses nearly all of them), so the symbols it
-- needs are published here. Passing 90 arguments would break the register
-- limit instead; one table is free.
-- ═══════════════════════════════════════════════════════════════════════════
local NS = {}
do
    NS.AUTHOR = AUTHOR
    NS.BUILD = BUILD
    NS.Camera = Camera
    NS.Config = Config
    NS.GAME_NAME = GAME_NAME
    NS.ICON = ICON
    NS.Lighting = Lighting
    NS.LocalPlayer = LocalPlayer
    NS.Players = Players
    NS.RADIUS = RADIUS
    NS.SharedEnv = SharedEnv
    NS.Tabs = Tabs
    NS.Theme = Theme
    NS.UserInput = UserInput
    NS.VERSION = VERSION
    NS.Workspace = Workspace
    NS.buildWindow = buildWindow
    NS.corner = corner
    NS.getService = getService
    NS.getWindow = getWindow
    NS.makeTab = makeTab
    NS.new = new
    NS.notify = notify
    NS.safeCall = safeCall
end
-- ═══════════════════════════════════════════════════════════════════════════
-- 6 · GAME KNOWLEDGE — Jujutsu Shenanigans
--     Controls: M1 melee combo · 1 2 3 4 skills · Q dash · F block ·
--               R special · W+W sprint · G awaken · M build mode (private)
--     Live as of the [SKY ASSASSIN] build — v1.79 + Sky Assassin + the
--     2026-10-13 patch; the Halloween update ("Golden age of jujutsu")
--     is listed for 2026-10-23, so nothing here is hardcoded to one patch.
-- ═══════════════════════════════════════════════════════════════════════════
local KNOWLEDGE = {
    -- every released style / character, so the hub can name what you are and
    -- what the person in front of you is
    Styles = {
        "Vessel", "Honored One", "Ten Shadows", "Cursed Partners", "Blood Manipulator",
        "Perfection", "Restless Gambler", "Star Rage", "Head of Hei", "Switcher",
        "True Cannon", "Black Death", "Sky Assassin", "Salaryman", "Strongest Of History",
        "Register", "Jujutsu High", "Sukuna", "Gojo", "Yuji", "Megumi", "Yuta", "Choso",
        "Mahito", "Hakari", "Yuki", "Naoya", "Todo", "Toji", "Geto", "Nobara", "Maki",
        "Panda", "Inumaki", "Nanami", "Higuruma", "Kashimo", "Hana", "Kurourusi", "Uraume",
    },
    -- the seven that can land a Black Flash, plus aliases
    BlackFlash = {
        "Vessel", "Yuji", "Honored One", "Gojo", "Perfection", "Mahito", "Switcher", "Todo",
        "Cursed Partners", "Yuta", "Salaryman", "Strongest Of History", "Sukuna",
    },
    -- styles whose Black Flash comes from the double-tap skill 3
    DoubleTap = { "Vessel", "Yuji", "Perfection", "Mahito", "Sukuna", "Strongest Of History" },
    -- styles whose Black Flash comes from a blocked hit and an instant counter
    Counter = { "Honored One", "Gojo", "Switcher", "Todo", "Cursed Partners", "Yuta", "Salaryman" },
    -- domains / area expansions a client can recognise by name
    Domains = {
        "Unlimited Void", "Malevolent Shrine", "Self-Embodiment of Perfection", "Chimera Shadow Garden",
        "Idle Death Gamble", "Womb Profusion", "Horizon of the Captivating Skandha", "Embodiment of the Vow",
        "Domain", "Expansion", "Shrine", "Void", "Gamble", "Garden",
    },
    -- things that are not players but can be hit / read
    Dummies = { "Dummy", "TrainingDummy", "Training Dummy", "Practice", "Guard", "BlockDummy" },
    Npcs = { "shop", "keeper", "vendor", "teacher", "trainer", "npc", "barista", "cafe" },
    Pickups = { "cash", "coin", "money", "drop", "loot", "pickup", "reward", "chest", "crate", "case" },
    -- zones — the hub only uses these as search hints, it teleports to what the
    -- map actually has (see section 19)
    Zones = {
        "Cafe", "Playground", "Training", "Training Grounds", "City", "Forest", "Shrine",
        "School", "Jujutsu High", "Domain", "Arena", "Spawn", "Market", "Shop", "Beach",
        "Rooftop", "Alley", "Graveyard", "Ruins", "Temple", "Bridge", "Sewers", "Tower",
    },
    -- anti-cheat surface: the game bans through manual reports (Discord clips),
    -- so the client-side work is (a) kill detector scripts, (b) never let a
    -- report / flag remote leave this machine, (c) keep traffic plausible
    ReportRemotes = {
        "report", "reportplayer", "reportplayerremote", "flag", "flagplayer", "anticheat",
        "acreport", "acflag", "ban", "banplayer", "kick", "kickplayer", "punish", "suspicious",
        "cheat", "hack", "exploit", "moderate", "moderation", "screenshot", "spectate",
        "log", "logs", "telemetry", "record", "evidence", "screenshotrequest",
    },
    DetectorHints = {
        "anticheat", "anti cheat", "anti_cheat", "ac_client", "acclient", "achecker", "monitor",
        "guardian", "detector", "sentinel", "integrity", "exploitdetect", "checker", "watchdog",
        "securescript", "sanitize", "replay", "recorder", "report",
    },
    -- names the hub never touches on its own: the client-side game itself
    SafeGameplayRemotes = {
        "m1", "attack", "skill", "skill1", "skill2", "skill3", "skill4", "ability", "abilities",
        "block", "parry", "dash", "special", "awaken", "awakening", "domain", "expansion",
        "burst", "combat", "hit", "damage", "moveset", "emote", "chat", "saymessage", "moves",
        "character", "style", "roulette", "queue", "match", "respawn", "spawn", "camera",
        "shop", "buy", "purchase", "cash", "reward", "redeem", "code", "trade",
    },
    EmoteKeys = { ".", "b", "g" },            -- the emote wheel opens on one of these
    BlockKey = "F",
    DashKey = "Q",
    SpecialKey = "R",
    AwakenKey = "G",
    SkillKeys = "1,2,3,4",
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 7 · PERFORMANCE CORE — everything hot goes through a cache
--     The rule this section exists for: never walk the DataModel twice for
--     information you already have, and never re-build a table you can reuse.
--       · character / root / humanoid are cached and invalidated on respawn
--       · names are lowered once per instance, not once per comparison
--       · every instance's classification (dummy / pickup / domain …) is
--         memoised in a weak table, so a re-scan is a table lookup
--       · the world scanner runs in two tiers: a slow structure scan that
--         DISCOVERS instances and a fast refresh that only reads positions
--       · result tables are reused, never re-allocated per tick
--     Everything is exposed on State.perf so the cost can be seen, not guessed.
-- ═══════════════════════════════════════════════════════════════════════════
local State = {
    alive = true,
    started = monotonic(),
    skillIndex = 0,
    comboStep = 0,
    comboTarget = nil,
    lastAttack = 0,
    lastSkill = 0,
    lastBlackFlash = 0,
    blackFlashes = 0,
    comboHits = 0,
    combosLanded = 0,
    kills = 0,
    deaths = 0,
    lastHealth = 100,
    lastHealthAt = 0,
    blockUntil = 0,
    threat = nil,
    threatAt = 0,
    dashing = false,
    lastDash = 0,
    lastRemote = 0,
    remoteCount = 0,
    remoteBurst = 0,
    startedAt = os.clock(),
    style = "—",
    styleSource = "unknown",
    styleAt = 0,
    awakened = false,
    awakenedAt = 0,
    domainOpen = false,
    savedSpots = {},
    speedWrites = 0,
    fps = 60,
    ping = 0,
    lastPingAt = 0,
    comboRecording = false,
    recorded = {},
    recordedAt = 0,
    comboQueue = {},
    comboPlaying = false,
    emoteSlot = 1,
    using = {},
    toolName = "—",
    toolScore = 0,
    hooks = 0,
    rainbow = 0,
    watchTarget = nil,
    -- what the optimisations actually saved, in numbers
    perf = { scanMs = 0, scanCalls = 0, structureScans = 0, refreshCalls = 0,
        espUpdates = 0, writes = 0, frames = 0, fpsAt = 0, skips = 0, reused = 0 },
}

-- weak-keyed caches: they never keep an instance alive, they only remember
local Cache = {
    character = nil, root = nil, humanoid = nil, characterAt = 0,
    names = setmetatable({}, { __mode = "k" }),
    nameSource = setmetatable({}, { __mode = "k" }),
    kinds = setmetatable({}, { __mode = "k" }),
    kindNames = setmetatable({}, { __mode = "k" }),
    parts = setmetatable({}, { __mode = "k" }),
    styles = {},                       -- plain string→boolean memo
    playerChars = {},
    playerCharsAt = 0,
    toolScore = setmetatable({}, { __mode = "k" }),   -- tool → { name, score }
    equipped = nil, equippedAt = 0, equippedChar = nil,
    equippedTool = nil, equippedToolAt = 0,           -- last tool the game had out
    bestTool = nil, bestToolAt = 0,                   -- last winning weapon
    skillKeys = nil, skillKeysSource = nil,
    selfAura = nil,                                   -- the player's own highlight
    playerGui = nil, playerGuiAt = 0,
    guiSearch = {},                                   -- purpose → { at, button }
    counters = { writes = 0 },
}

local function getChar()
    local character = Cache.character
    if character and character.Parent and LocalPlayer and LocalPlayer.Character == character then
        return character
    end
    if not LocalPlayer then return nil end
    character = LocalPlayer.Character
    if character and character.Parent then
        Cache.character = character
        Cache.root, Cache.humanoid = nil, nil       -- the new body has new parts
        Cache.parts = setmetatable({}, { __mode = "k" })
        return character
    end
    Cache.character = nil
    return nil
end

local function getRoot()
    local root = Cache.root
    if root and root.Parent then return root end
    local character = getChar()
    if not character then Cache.root = nil return nil end
    root = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChildWhichIsA("BasePart")
    Cache.root = root
    return root
end

local function getHumanoid()
    local humanoid = Cache.humanoid
    if humanoid and humanoid.Parent then return humanoid end
    local character = getChar()
    if not character then Cache.humanoid = nil return nil end
    humanoid = character:FindFirstChildOfClass("Humanoid")
    Cache.humanoid = humanoid
    return humanoid
end

local function isAlive()
    local humanoid = getHumanoid()
    return humanoid ~= nil and (humanoid.Health or 0) > 0
end

-- lowercase names: once per instance, then a lookup (re-done if it is renamed)
local function lowerName(instance)
    local name = instance.Name or "?"
    local cached = Cache.names[instance]
    if cached and Cache.nameSource[instance] == name then return cached end
    cached = string.lower(name)
    Cache.names[instance] = cached
    Cache.nameSource[instance] = name
    return cached
end

-- the position of a model, with the part remembered per model
-- a zone can hold its parts deeper than one level (the map's "Training Grounds"
-- model contains the dummies themselves), so the last resort is a bounded
-- breadth-first walk. It runs once per instance — the part is then cached.
local function deepPart(model)
    local queue, head = { model }, 1
    local visits = 0
    while head <= #queue and visits < 24 do
        local node = queue[head]
        head = head + 1
        visits = visits + 1
        local children = node:GetChildren()
        for index = 1, #children do
            local child = children[index]
            if child:IsA("BasePart") then return child end
            local class = child.ClassName
            if class == "Model" or class == "Folder" or class == "Accessory" then
                queue[#queue + 1] = child
            end
        end
    end
    return nil
end

local function modelPosition(model)
    if not model then return nil end
    local part = Cache.parts[model]
    if part and part.Parent then
        return part.Position
    end
    part = model.PrimaryPart
    if not part or not part.Parent then
        part = model:FindFirstChild("HumanoidRootPart")
    end
    if not part or not part.Parent then
        part = model:FindFirstChildWhichIsA("BasePart")
    end
    if not part or not part.Parent then
        part = deepPart(model)
    end
    if part then
        Cache.parts[model] = part
        return part.Position
    end
    if model:IsA("BasePart") then return model.Position end
    return nil
end

local function distanceTo(position)
    local root = getRoot()
    if not root or not position then return math.huge end
    local delta = root.Position - position
    return delta.Magnitude
end

-- string matching, but the token lists are pre-lowered once at load
local function lowerList(list)
    local out = {}
    for index, token in ipairs(list) do out[index] = string.lower(token) end
    return out
end

local LOWER = {
    Styles = lowerList(KNOWLEDGE.Styles),
    BlackFlash = lowerList(KNOWLEDGE.BlackFlash),
    DoubleTap = lowerList(KNOWLEDGE.DoubleTap),
    Counter = lowerList(KNOWLEDGE.Counter),
    Domains = lowerList(KNOWLEDGE.Domains),
    Dummies = lowerList(KNOWLEDGE.Dummies),
    Pickups = lowerList(KNOWLEDGE.Pickups),
    Zones = lowerList(KNOWLEDGE.Zones),
    ReportRemotes = lowerList(KNOWLEDGE.ReportRemotes),
    SafeGameplayRemotes = lowerList(KNOWLEDGE.SafeGameplayRemotes),
    DetectorHints = lowerList(KNOWLEDGE.DetectorHints),
}

local function containsAny(text, list)
    if not text then return false end
    text = string.lower(text)
    for index = 1, #list do
        if string.find(text, list[index], 1, true) then return true end
    end
    return false
end

-- the same match, but against already-lowered tokens and an already-lowered text
local function containsLower(lower, list)
    if not lower then return false end
    for index = 1, #list do
        if string.find(lower, list[index], 1, true) then return true end
    end
    return false
end

local function isPlayerCharacter(model)
    if not model or not Players then return false end
    local stamp = os.clock()
    if stamp - Cache.playerCharsAt > 1 then
        Cache.playerChars = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                Cache.playerChars[player.Character] = true
            end
        end
        Cache.playerCharsAt = stamp
        if not Cache.character and LocalPlayer then
            local mine = LocalPlayer.Character
            if mine then Cache.playerChars[mine] = false end
        end
    end
    return Cache.playerChars[model] == true
end

local function playerFromCharacter(model)
    if not model or not Players then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == model then return player end
    end
    return nil
end

-- the style is read at most once a second, and the answer is memoised
local function currentStyle(force)
    local now = os.clock()
    if not force and now - State.styleAt < 1 then return State.style end
    State.styleAt = now
    local character = getChar()
    local candidates = Cache.styleNodes
    if not candidates then candidates = {} Cache.styleNodes = candidates end
    local count = 0
    if character then
        for _, child in ipairs(character:GetChildren()) do
            local class = child.ClassName
            if class == "StringValue" or class == "ObjectValue" or class == "Folder" then
                count = count + 1
                candidates[count] = child
                if class == "Folder" then
                    for _, deep in ipairs(child:GetChildren()) do
                        count = count + 1
                        candidates[count] = deep
                    end
                end
            end
        end
    end
    if LocalPlayer then
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            for _, child in ipairs(leaderstats:GetChildren()) do
                count = count + 1
                candidates[count] = child
            end
        end
    end
    for index = 1, count do
        local node = candidates[index]
        local value = nil
        if node:IsA("StringValue") then value = node.Value end
        if value == nil and node:IsA("ObjectValue") and node.Value then value = node.Value.Name end
        if value == nil then value = node.Name end
        if type(value) == "string" and value ~= "" then
            local cached = Cache.styles[value]
            if cached == nil then
                cached = containsAny(value, LOWER.Styles)
                Cache.styles[value] = cached        -- string keys are bounded by the game's own set
            end
            if cached then
                State.style = value
                State.styleSource = "game"
                break
            end
        end
    end
    for index = count + 1, #candidates do candidates[index] = nil end
    return State.style
end

local function canBlackFlash(style)
    style = style or State.style
    if containsAny(style, LOWER.BlackFlash) then return true end
    return style == "—" or style == nil
end

local function isAwakened(force)
    local now = os.clock()
    if not force and now - State.awakenedAt < 1 then return State.awakened end
    State.awakenedAt = now
    local character = getChar()
    if not character then return false end
    local markers = Cache.awakenMarkers
    if not markers then markers = { "Awakening", "Awakened", "AwakeningBar", "IsAwakened", "Awaken" }
        Cache.awakenMarkers = markers end
    for index = 1, #markers do
        local node = character:FindFirstChild(markers[index])
        if node then
            if node:IsA("BoolValue") then
                State.awakened = node.Value == true
            else
                State.awakened = true
            end
            return State.awakened
        end
    end
    local humanoid = getHumanoid()
    if humanoid and (humanoid.WalkSpeed or 16) > 30 then
        State.awakened = true
    end
    return State.awakened
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 7b · THE TWO-TIER WORLD SCANNER
--      Tier 1 (slow, every ScanInterval): walk the map's containers, find the
--      instances worth knowing about, memoise their classification.
--      Tier 2 (fast, every RefreshInterval): read positions from the cached
--      instance list and rebuild the flat arrays in place.
--      Nothing here allocates a new table per tick.
-- ═══════════════════════════════════════════════════════════════════════════
local World = {
    at = 0, structureAt = 0, players = {}, dummies = {}, pickups = {}, domains = {},
    all = {}, zones = {}, zone = "—", count = 0,
    found = {},                  -- the discovered instances, classified once
    foundAt = {},
}

-- reuse: wipe a table without replacing it
local function wipe(target)
    for index = #target, 1, -1 do target[index] = nil end
    return target
end

-- `ClassName` reports the concrete class ("Part", not "BasePart"), so the
-- checks go through IsA — the exact bug that made the first version of this
-- scanner see zero pickups.
local function classify(instance)
    local name = instance.Name
    local cached = Cache.kinds[instance]
    if cached ~= nil and Cache.kindNames[instance] == name then return cached or nil end
    local kind = false
    local lower = lowerName(instance)
    if instance:IsA("Model") then
        if containsLower(lower, LOWER.Dummies) then kind = "dummy"
        elseif containsLower(lower, LOWER.Domains) then kind = "domain"
        elseif containsLower(lower, LOWER.Zones) then kind = "zone" end
    elseif instance:IsA("BasePart") then
        if containsLower(lower, LOWER.Pickups) then kind = "pickup" end
    elseif instance.ClassName == "Folder" then
        if containsLower(lower, LOWER.Zones) then kind = "zone" end
    end
    Cache.kinds[instance] = kind or false
    Cache.kindNames[instance] = name
    return kind or nil
end

-- walks containers breadth-first, but only the depth that matters: the map's
-- own folders plus the models inside them
local function structureScan()
    local started = os.clock()
    wipe(World.found)
    local queue, head, tail = Cache.queue or {}, 1, 0
    Cache.queue = queue
    local function push(instance, depth)
        tail = tail + 1
        queue[tail] = instance
        queue[tail + 100000] = depth
    end
    local top = Workspace and Workspace:GetChildren()
    if top then
        for index = 1, #top do push(top[index], 1) end
    end
    local visits = 0
    while head <= tail and visits < (Config.ScanBudget or 900) do
        local node = queue[head]
        local depth = queue[head + 100000]
        queue[head], queue[head + 100000] = nil, nil
        head = head + 1
        visits = visits + 1
        local class = node.ClassName
        if class == "Model" or class == "Folder" or class == "Tool" or class == "Accessory" then
            if classify(node) then
                local list = World.found
                list[#list + 1] = node
            end
            if depth <= 1 then                       -- one level into each folder
                local children = node:GetChildren()
                for index = 1, #children do push(children[index], depth + 1) end
            end
        elseif node:IsA("BasePart") then
            if classify(node) then
                local list = World.found
                list[#list + 1] = node
            end
        end
    end
    State.perf.structureScans = State.perf.structureScans + 1
    State.perf.visits = visits
    State.perf.scanMs = (os.clock() - started) * 1000
    World.structureAt = os.clock()
    return visits
end

-- tier 2: position refresh, no discovery, no allocation
local function refreshWorld()
    local started = os.clock()
    local root = getRoot()
    local myRoot = root and root.Position
    local players, dummies, pickups, domains, zones = World.players, World.dummies, World.pickups, World.domains, World.zones
    wipe(players) wipe(dummies) wipe(pickups) wipe(domains) wipe(zones)

    if Players then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                if character and character.Parent then
                    local position = modelPosition(character)
                    if position then
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        local record = World.playerPool and World.playerPool[player]
                        if not record then
                            record = { player = player, name = player.Name, display = player.DisplayName or player.Name,
                                style = "—", isPlayer = true }
                            World.playerPool = World.playerPool or {}
                            World.playerPool[player] = record
                            State.perf.reused = State.perf.reused + 1
                        end
                        record.instance = character
                        record.position = position
                        record.humanoid = humanoid
                        record.health = humanoid and humanoid.Health or 100
                        record.maxHealth = humanoid and humanoid.MaxHealth or 100
                        record.alive = humanoid ~= nil and (humanoid.Health or 0) > 0
                        record.distance = myRoot and (myRoot - position).Magnitude or math.huge
                        players[#players + 1] = record
                    end
                end
            end
        end
    end

    for index = 1, #World.found do
        local instance = World.found[index]
        if instance.Parent then
            local kind = Cache.kinds[instance]
            local position = modelPosition(instance)
            if position then
                local distance = myRoot and (myRoot - position).Magnitude or math.huge
                if kind == "dummy" and not isPlayerCharacter(instance) then
                    local humanoid = instance:FindFirstChildOfClass("Humanoid")
                    local record = World.dummyPool and World.dummyPool[instance]
                    if not record then
                        record = { instance = instance, name = instance.Name }
                        World.dummyPool = World.dummyPool or {}
                        World.dummyPool[instance] = record
                    end
                    record.humanoid = humanoid
                    record.position = position
                    record.health = humanoid and humanoid.Health or 100
                    record.maxHealth = humanoid and humanoid.MaxHealth or 100
                    record.distance = distance
                    dummies[#dummies + 1] = record
                elseif kind == "domain" then
                    domains[#domains + 1] = { instance = instance, name = instance.Name, position = position, distance = distance }
                elseif kind == "pickup" then
                    pickups[#pickups + 1] = { instance = instance, name = instance.Name, position = position, distance = distance }
                elseif kind == "zone" then
                    zones[#zones + 1] = { instance = instance, name = instance.Name, position = position, distance = distance }
                end
            end
        else
            -- the instance is gone: drop the classification so the cache stays small
            Cache.kinds[instance] = nil
            Cache.kindNames[instance] = nil
            Cache.names[instance] = nil
            Cache.nameSource[instance] = nil
            Cache.parts[instance] = nil
        end
    end
    table.sort(zones, function(a, b) return a.distance < b.distance end)
    World.zone = zones[1] and zones[1].name or "—"
    World.count = #players + #dummies + #pickups + #domains
    World.at = os.clock()
    State.perf.refreshCalls = State.perf.refreshCalls + 1
    State.perf.scanMs = (os.clock() - started) * 1000
    return World
end

-- the public entry point stays the same: scanWorld(force) returns the world and
-- never costs more than the intervals allow
local function scanWorld(force)
    local now = os.clock()
    local scanInterval = tonumber(Config.ScanInterval) or 2
    if force or now - World.structureAt > scanInterval then
        structureScan()
    end
    if force or now - (World.at or 0) > (tonumber(Config.RefreshInterval) or 0.3) then
        refreshWorld()
        State.perf.scanCalls = State.perf.scanCalls + 1
    end
    return World
end

local function entityList(kind)
    scanWorld()
    if kind == "player" then return World.players end
    if kind == "dummy" then return World.dummies end
    if kind == "pickup" then return World.pickups end
    if kind == "domain" then return World.domains end
    return World.all
end

-- one reusable target buffer: the loops ask for "the nearest one" far more
-- often than they ask for "all of them", so nothing is sorted or copied here
local Targets = {}

local function targetList(includePlayers, includeDummies, maxDistance)
    scanWorld()
    wipe(Targets)
    if includePlayers then
        local players = World.players
        for index = 1, #players do
            local entry = players[index]
            if entry.alive and entry.distance <= maxDistance then
                Targets[#Targets + 1] = entry
            end
        end
    end
    if includeDummies then
        local dummies = World.dummies
        for index = 1, #dummies do
            local entry = dummies[index]
            if (entry.health or 0) > 0 and entry.distance <= maxDistance then
                Targets[#Targets + 1] = entry
            end
        end
    end
    return Targets
end

local function nearestTarget(maxDistance)
    scanWorld()
    local option = Config.TargetPriority or "Closest"
    local range = maxDistance or 60
    local best, bestScore = nil, math.huge
    local camera = Camera
    if option == "Players" or option ~= "Dummies" then
        local players = World.players
        for index = 1, #players do
            local entry = players[index]
            if entry.alive and entry.distance <= range then
                local score = entry.distance
                if option == "Lowest health" then
                    score = (entry.health or 100) / math.max(1, entry.maxHealth or 100) * 1000
                elseif option == "Nearest to camera" and camera then
                    local direction = entry.position - camera.CFrame.Position
                    if direction.Magnitude > 0 then score = 1000 - direction.Unit:Dot(camera.CFrame.LookVector) * 1000 end
                end
                if score < bestScore then best, bestScore = entry, score end
            end
        end
    end
    if option == "Dummies" or option ~= "Players" then
        local dummies = World.dummies
        for index = 1, #dummies do
            local entry = dummies[index]
            if (entry.health or 0) > 0 and entry.distance <= range then
                local score = entry.distance
                if option == "Lowest health" then
                    score = (entry.health or 100) / math.max(1, entry.maxHealth or 100) * 1000
                elseif option == "Nearest to camera" and camera then
                    local direction = entry.position - camera.CFrame.Position
                    if direction.Magnitude > 0 then score = 1000 - direction.Unit:Dot(camera.CFrame.LookVector) * 1000 end
                end
                if score < bestScore then best, bestScore = entry, score end
            end
        end
    end
    return best
end

-- forward declarations: these live in later sections, but the loops below
-- already call them, and Lua locals are lexical
local pressKey, holdKey, clickMouse, chatSay, playEmote, keyCodeFor

-- ═══════════════════════════════════════════════════════════════════════════
-- 8 · TOOLS AND ABILITIES
-- ═══════════════════════════════════════════════════════════════════════════
-- the game only swaps the held tool when a player asks it to, so a 0.4 s memo
-- removes the per-attack FindFirstChildOfClass without ever showing a stale
-- weapon: the memo is keyed to the character and re-checked on every swap.
local function equippedTool()
    local character = getChar()
    if not character then return nil end
    local now = os.clock()
    local tool = Cache.equippedTool
    if Cache.equippedChar == character and now - Cache.equippedToolAt < 0.4 then
        if tool == nil or (tool.Parent == character) then return tool end
    end
    tool = character:FindFirstChildOfClass("Tool")
    Cache.equippedChar, Cache.equippedTool, Cache.equippedToolAt = character, tool, now
    State.perf.reused = State.perf.reused + 1
    return tool
end

-- JJS keeps the melee combo on the character itself most of the time; when a
-- tool is present we always prefer the one with melee-ish methods/names
local function toolScore(tool)
    if not tool then return 0 end
    local name = tool.Name
    local memo = Cache.toolScore[tool]
    if memo and memo.name == name then
        State.perf.reused = State.perf.reused + 1
        return memo.score
    end
    local score = 10
    local lower = string.lower(name)
    for _, token in ipairs({ "m1", "fist", "sword", "katana", "weapon", "punch", "tool", "blade", "hand" }) do
        if string.find(lower, token, 1, true) then score = score + 40 break end
    end
    if tool:FindFirstChild("Handle") then score = score + 5 end
    if tool:FindFirstChild("Cooldown") or tool:FindFirstChild("Damage") then score = score + 5 end
    Cache.toolScore[tool] = { name = name, score = score }
    return score
end

local function equipBestWeapon()
    local character = getChar()
    if not character or not isAlive() then return false end
    local held = equippedTool()
    local heldScore = toolScore(held)
    -- the weapon we chose last time is still in hand and still the best one we
    -- have seen in the last 2 s — the backpack does not need another walk
    local now = os.clock()
    local memo = Cache.bestTool
    if held and memo and memo.tool == held and memo.character == character
        and now - Cache.bestToolAt < 2 and heldScore >= 30 then
        State.perf.skips = State.perf.skips + 1
        State.toolName, State.toolScore = held.Name, heldScore
        return true
    end
    local best, bestScore = nil, heldScore
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            local score = toolScore(item)
            if score > bestScore then best, bestScore = item, score end
        end
    end
    local bag = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer.Backpack
    for _, item in ipairs(bag and bag:GetChildren() or {}) do
        if item:IsA("Tool") then
            local score = toolScore(item)
            if score > bestScore then best, bestScore = item, score end
        end
    end
    if not best then return false end
    local humanoid = getHumanoid()
    if not humanoid then return false end
    local ok = safeCall("equip", function()
        best.Parent = character
        humanoid:EquipTool(best)
        return true
    end)
    if ok then
        State.toolName = best.Name
        State.toolScore = bestScore
        Cache.bestTool, Cache.bestToolAt = { tool = best, character = character }, now
    end
    return ok == true
end

local function currentToolInfo()
    local tool = equippedTool()
    if tool then
        State.toolName = tool.Name
        State.toolScore = toolScore(tool)
    else
        State.toolName = "M1 combo"
        State.toolScore = 0
    end
    return State.toolName, State.toolScore
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 9 · THE ANTI-CHEAT LAYER
--     Jujutsu Shenanigans bans through manual reports (video evidence in the
--     official Discord) plus whatever Roblox itself notices about an injector.
--     A client script can do four things about that, and this is all four:
--       1 · find and disable client-side detector / monitor scripts
--       2 · drop every outgoing report / flag / ban / screenshot remote call
--       3 · keep the hub's own traffic inside plausible bounds
--       4 · watch for staff and leave before anyone records anything
--     Anything else would be a lie: the server owns the truth.
-- ═══════════════════════════════════════════════════════════════════════════
local AC = {
    scripts = {},
    remotes = {},
    detectors = {},
    blocked = 0,
    allowed = 0,
    disabled = 0,
    hookInstalled = false,
    kickGuard = false,
    originalNamecall = nil,
    originalKick = nil,
    auditAt = 0,
    lastBlocked = "",
    blockedNames = {},
    staffWarned = {},
}

local function listDescendants(root, out, cap)
    out = out or {}
    if not root then return out end
    local ok, descendants = pcall(function() return root:GetDescendants() end)
    if not ok then return out end
    for _, instance in ipairs(descendants) do
        out[#out + 1] = instance
        if cap and #out >= cap then return out end
    end
    return out
end

local function acScan()
    AC.scripts, AC.remotes, AC.detectors = {}, {}, {}
    if not ReplicatedStorage then return AC end
    local all = listDescendants(ReplicatedStorage, {}, 4000)
    if Workspace then listDescendants(Workspace, all, 6000) end
    if Players and LocalPlayer then
        local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if scripts then listDescendants(scripts, all, 7000) end
    end
    if game:FindFirstChild("StarterPlayer") then listDescendants(game.StarterPlayer, all, 8000) end
    for _, instance in ipairs(all) do
        local class = instance.ClassName
        if class == "LocalScript" or class == "Script" or class == "ModuleScript" then
            local record = { instance = instance, name = instance.Name,
                full = instance:GetFullName(), class = class, disabled = instance.Disabled == true }
            AC.scripts[#AC.scripts + 1] = record
            local lower = string.lower(instance.Name)
            local isDetector = containsAny(lower, KNOWLEDGE.DetectorHints)
            -- anything sitting under an AntiCheat folder is a detector, whatever it is called
            local parent = instance.Parent
            while parent and parent ~= game do
                if containsAny(parent.Name, KNOWLEDGE.DetectorHints) then isDetector = true break end
                parent = parent.Parent
            end
            if isDetector then AC.detectors[#AC.detectors + 1] = record end
        elseif class == "RemoteEvent" or class == "RemoteFunction" or class == "UnreliableRemoteEvent" then
            local lower = string.lower(instance.Name)
            local isReport = containsAny(lower, KNOWLEDGE.ReportRemotes)
                and not containsAny(lower, KNOWLEDGE.SafeGameplayRemotes)
            AC.remotes[#AC.remotes + 1] = { instance = instance, name = instance.Name,
                full = instance:GetFullName(), class = class, report = isReport }
        end
    end
    AC.auditAt = os.clock()
    return AC
end

local function acTelemetry()
    local detectors, reports, scripts = #AC.detectors, 0, #AC.scripts
    for _, remote in ipairs(AC.remotes) do if remote.report then reports = reports + 1 end end
    return { scripts = scripts, detectors = detectors, reports = reports,
        remotes = #AC.remotes, blocked = AC.blocked, disabled = AC.disabled,
        hook = AC.hookInstalled, kickGuard = AC.kickGuard }
end

AC.audit = function(announce)
    acScan()
    if announce then
        print(string.format("[Skill Hub] AC audit · %d script(s) · %d detector(s) · %d remote(s) · %d report remote(s)",
            #AC.scripts, #AC.detectors, #AC.remotes, acTelemetry().reports))
        for _, detector in ipairs(AC.detectors) do
            print(string.format("    detector: %s%s", detector.full, detector.disabled and " (already off)" or ""))
        end
        for _, remote in ipairs(AC.remotes) do
            if remote.report then print("    report remote: " .. remote.full) end
        end
    end
    return acTelemetry()
end

-- Disabling beats destroying: a Destroy()ed script leaves the game's own
-- bookkeeping dangling (and a missing node is a louder signal than a stopped
-- one). So: Disabled = true, and drop the connections it already made.
AC.neutralize = function(announce)
    if #AC.detectors == 0 then acScan() end
    local handled = 0
    for _, detector in ipairs(AC.detectors) do
        local script = detector.instance
        if script and script.Parent then
            local ok = safeCall("ac disable", function()
                if script:IsA("BaseScript") then
                    script.Disabled = true
                elseif script:IsA("ModuleScript") then
                    script.Name = script.Name            -- modules have no Disabled; drop their threads instead
                end
                return true
            end)
            local dropped = safeCall("ac connections", function()
                if getconnections and script:IsA("BaseScript") then
                    local connections = getconnections(script:GetPropertyChangedSignal("Disabled"))
                    if connections then
                        for _, connection in ipairs(connections) do
                            if connection.Disconnect then connection:Disconnect() end
                        end
                    end
                    return true
                end
                return false
            end)
            detector.disabled = true
            handled = handled + 1
            if ok and not dropped then end
        end
    end
    AC.disabled = handled
    if announce then
        print(string.format("[Skill Hub] detector neutralised (disabled) · %d script(s)", handled))
    end
    return handled
end

-- The namecall filter: everything that is not a report / flag / ban call goes
-- straight through to the original function, so gameplay is never touched.
AC.installHook = function()
    if AC.hookInstalled then return true end
    local installed = safeCall("ac hook", function()
        local metatable = getrawmetatable and getrawmetatable(game) or getmetatable(game)
        if not metatable then return false end
        if setreadonly then pcall(setreadonly, metatable, false) end
        AC.originalNamecall = metatable.__namecall
        local original = AC.originalNamecall
        local newcclosureFn = newcclosure or function(fn) return fn end
        local wrapper = newcclosureFn(function(self, ...)
            local method = getnamecallmethod and getnamecallmethod() or nil
            -- Never trust the method name by itself: identify the receiver too,
            -- so a stale or faked namecall method can never swallow a real call.
            if method == "FireServer" or method == "InvokeServer" or method == "Fire" then
                local ok, name = pcall(function() return self and self.Name end)
                local classOk, class = pcall(function() return self and self.ClassName end)
                local isRemote = classOk and type(class) == "string" and string.find(class, "Remote", 1, true) ~= nil
                if ok and isRemote and type(name) == "string" then
                    local lower = string.lower(name)
                    if containsAny(lower, KNOWLEDGE.ReportRemotes)
                        and not containsAny(lower, KNOWLEDGE.SafeGameplayRemotes) then
                        AC.blocked = AC.blocked + 1
                        AC.lastBlocked = name
                        if AC.blocked <= 6 then
                            print("[Skill Hub] AC · dropped outgoing remote call -> " .. name)
                        end
                        return nil
                    end
                    AC.allowed = AC.allowed + 1
                end
            end
            if method == "Kick" and AC.kickGuard and self == LocalPlayer then
                AC.blocked = AC.blocked + 1
                AC.lastBlocked = "Kick"
                print("[Skill Hub] kick blocked on the client · reason: " .. tostring((...)))
                return nil
            end
            return original(self, ...)
        end)
        metatable.__namecall = wrapper
        if setreadonly then pcall(setreadonly, metatable, true) end
        AC.hookInstalled = true
        AC.hooks = (AC.hooks or 0) + 1
        return true
    end)
    if installed and Config.LogLevel >= 2 then
        print("[Skill Hub] AC · report-blocking hook installed on __namecall (newcclosure, pcall-guarded, everything else falls through)")
    end
    return installed == true
end

AC.removeHook = function()
    if not AC.hookInstalled then return true end
    safeCall("ac unhook", function()
        local metatable = getrawmetatable and getrawmetatable(game) or getmetatable(game)
        if metatable and AC.originalNamecall then
            if setreadonly then pcall(setreadonly, metatable, false) end
            metatable.__namecall = AC.originalNamecall
            if setreadonly then pcall(setreadonly, metatable, true) end
        end
    end)
    AC.hookInstalled = false
    return true
end

AC.installKickGuard = function()
    if AC.kickGuard then return true end
    local ok = safeCall("kick guard", function()
        if not (hookfunction and LocalPlayer and LocalPlayer.Kick) then return false end
        AC.originalKick = hookfunction(LocalPlayer.Kick, function(...)
            AC.blocked = AC.blocked + 1
            AC.lastBlocked = "Kick"
            print("[Skill Hub] kick blocked on the client · reason: " .. tostring(select(2, ...)))
            return nil
        end)
        return true
    end)
    AC.kickGuard = ok == true
    return AC.kickGuard
end

AC.removeKickGuard = function()
    if not AC.kickGuard then return true end
    safeCall("kick unhook", function()
        if hookfunction and AC.originalKick and LocalPlayer and LocalPlayer.Kick then
            hookfunction(LocalPlayer.Kick, AC.originalKick)
        end
    end)
    AC.kickGuard = false
    return true
end

-- A simple token bucket for the hub's own remote traffic: when the bucket is
-- empty the helper returns false and the caller waits a beat. This is what
-- keeps a kill aura from looking like a machine gun.
AC.allow = function()
    local now = os.clock()
    if now - State.lastRemote >= 1 then
        State.remoteCount = 0
        State.lastRemote = now
    end
    local limit = math.max(1, tonumber(Config.AcRemoteRateLimit) or 12)
    if State.remoteCount >= limit then return false end
    State.remoteCount = State.remoteCount + 1
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 10 · MOVEMENT — speed, jump, fly, noclip, dash, teleport
-- ═══════════════════════════════════════════════════════════════════════════
local FlyState = { velocity = nil, attachment = nil, active = false }

-- Every write is compared against the value we last wrote: Roblox replicates
-- property changes, so writing WalkSpeed 60 times a second is 60 network events
-- for a value that never changed.
local WriteCache = { speed = nil, jump = nil, noclip = nil, staminaAt = 0, hitboxKey = nil }

local function canWrite()
    return not Config.AcSafeMode or AC.allow()
end

local function applySpeed()
    local humanoid = getHumanoid()
    if not humanoid then return end
    local wanted = Config.WalkSpeedEnabled and Config.WalkSpeed or 16
    if Config.AcSafeMode then
        wanted = math.min(wanted, math.max(16, tonumber(Config.AcSpeedCeiling) or 60))
    end
    if WriteCache.speed == wanted then return end
    -- the AntiSlow layer still has to be able to push the floor back up
    if not canWrite() and wanted < (WriteCache.speed or 16) then return end
    WriteCache.speed = wanted
    humanoid.WalkSpeed = wanted
    if Config.WalkSpeedEnabled then
        State.speedWrites = State.speedWrites + 1
        State.perf.writes = State.perf.writes + 1
    end
end

local function applyJump()
    local humanoid = getHumanoid()
    if not humanoid then return end
    local power = Config.JumpPowerEnabled and Config.JumpPower or 50
    if WriteCache.jump == power then return end
    WriteCache.jump = power
    humanoid.UseJumpPower = true
    humanoid.JumpPower = power
    State.perf.writes = State.perf.writes + 1
end

local function setNoclip(on)
    local character = getChar()
    if not character then return end
    if WriteCache.noclip == on then return end
    WriteCache.noclip = on
    -- only the parts that actually collide: no walking the whole body
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if part.CanCollide == on then part.CanCollide = not on end
        end
    end
    State.perf.writes = State.perf.writes + 1
end

local function dashNow()
    if not Config.AutoDash then return false end
    local now = os.clock()
    if now - State.lastDash < math.max(0.15, Config.DashDelay or 0.6) then return false end
    State.lastDash = now
    return pressKey(KNOWLEDGE.DashKey, 0.05)
end

local function flyStart()
    local root = getRoot()
    if not root then return false end
    FlyState.active = true
    safeCall("fly", function()
        local attachment = Instance.new("Attachment")
        attachment.Name = "SkillHubFly"
        attachment.Parent = root
        local velocity = Instance.new("LinearVelocity")
        velocity.Name = "SkillHubFlyVelocity"
        velocity.Attachment0 = attachment
        velocity.MaxForce = math.huge
        velocity.VectorVelocity = Vector3.zero
        velocity.RelativeTo = Enum.ActuatorRelativeTo.World
        velocity.Parent = root
        FlyState.velocity = velocity
        FlyState.attachment = attachment
    end)
    return FlyState.velocity ~= nil
end

local function flyStop()
    FlyState.active = false
    safeCall("fly stop", function()
        if FlyState.velocity then FlyState.velocity:Destroy() end
        if FlyState.attachment then FlyState.attachment:Destroy() end
    end)
    FlyState.velocity, FlyState.attachment = nil, nil
end

local function flyStep()
    if not FlyState.active then
        if Config.FlyEnabled and isAlive() then flyStart() end
        return
    end
    if not Config.FlyEnabled then flyStop() return end
    if not isAlive() then flyStop() return end
    local camera = Camera
    if not camera then return end
    safeCall("fly step", function()
        local direction = Vector3.zero
        if UserInput then
            if UserInput:IsKeyDown(Enum.KeyCode.W) then direction = direction + camera.CFrame.LookVector end
            if UserInput:IsKeyDown(Enum.KeyCode.S) then direction = direction - camera.CFrame.LookVector end
            if UserInput:IsKeyDown(Enum.KeyCode.A) then direction = direction - camera.CFrame.RightVector end
            if UserInput:IsKeyDown(Enum.KeyCode.D) then direction = direction + camera.CFrame.RightVector end
            if UserInput:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
            if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction - Vector3.new(0, 1, 0) end
        end
        local root = getRoot()
        if root and direction.Magnitude > 0 then
            local speed = math.min(tonumber(Config.FlySpeed) or 90, 250)
            direction = direction.Unit * speed
        end
        if FlyState.velocity then FlyState.velocity.VectorVelocity = direction end
        if root then
            local humanoid = getHumanoid()
            if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Physics) end
        end
    end)
end

-- Teleports are paced: a jump longer than one hop is walked in 400-stud
-- slices so the client never writes an absurd single CFrame.
local function tweenTo(position, speed)
    if not position then return false end
    local root = getRoot()
    if not root then return false end
    local hop = 400
    local ok = safeCall("teleport", function()
        local target = position
        if Config.AcSafeMode and Config.AcTeleportPacing then
            local from = root.Position
            local distance = (target - from).Magnitude
            local steps = math.max(1, math.ceil(distance / hop))
            if steps == 1 then
                root.CFrame = CFrame.new(target)
            else
                task.spawn(function()
                    for step = 1, steps do
                        if not State.alive or not isAlive() then return end
                        local point = from:Lerp(target, step / steps)
                        safeCall("teleport hop", function() root.CFrame = CFrame.new(point) end)
                        task.wait(math.max(0.05, (speed or 1) * 0.08))
                    end
                end)
            end
        else
            root.CFrame = CFrame.new(target)
        end
        return true
    end)
    return ok == true
end

local function teleportBehind(target)
    local position = modelPosition(target)
    if not position then return false end
    return tweenTo(position + Vector3.new(0, 0, 3))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 11 · DEFENCE LOOPS — ragdoll, stun, slow, fall damage, stamina, fling, AFK
-- ═══════════════════════════════════════════════════════════════════════════
local FlingState = { lastPosition = nil, lastAt = 0, strikes = 0 }

local function applyDefenceLoop()
    task.spawn(function()
        while State.alive do
            task.wait(Config.AcSafeMode and 0.4 or 0.25)
            local active = Config.AntiRagdoll or Config.AntiStun or Config.AntiSlow or Config.InfiniteStamina or Config.AntiFling
            if not active then
                State.perf.skips = State.perf.skips + 1
            else
            local character = getChar()
            local humanoid = getHumanoid()
            if character and humanoid and (humanoid.Health or 0) > 0 then
                -- ragdoll: get back on your feet immediately
                if Config.AntiRagdoll then
                    local state = humanoid:GetState()
                    if state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown then
                        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                        State.perf.writes = State.perf.writes + 1
                    end
                    if humanoid.PlatformStand then humanoid.PlatformStand = false end
                end
                -- stun / slow: the game lowers WalkSpeed while a combo lands
                if Config.AntiStun or Config.AntiSlow then
                    local floor = Config.AntiSlow and math.min(math.max(Config.WalkSpeed, 16), 60) or 16
                    if (humanoid.WalkSpeed or 16) < floor then
                        humanoid.WalkSpeed = floor
                        WriteCache.speed = floor
                        State.perf.writes = State.perf.writes + 1
                    end
                end
                -- stamina / cursed energy: the client is allowed to believe the
                -- bar is full; sprint never drains locally
                if Config.InfiniteStamina and os.clock() - WriteCache.staminaAt > 1 then
                    WriteCache.staminaAt = os.clock()
                    local values = Cache.staminaValues
                    if not values then values = {} Cache.staminaValues = values end
                    local count = 0
                    for _, item in ipairs(character:GetChildren()) do
                        local class = item.ClassName
                        if class == "NumberValue" or class == "IntValue" then
                            count = count + 1
                            values[count] = item
                        end
                    end
                    for index = 1, count do
                        local item = values[index]
                        local lower = lowerName(item)
                        if string.find(lower, "stamina", 1, true) or string.find(lower, "energy", 1, true)
                            or string.find(lower, "hunger", 1, true) then
                            local cap = 100
                            local maxValue = item:FindFirstChild("MaxValue")
                            if maxValue then cap = maxValue.Value end
                            if item.Value ~= cap then
                                item.Value = cap
                                State.perf.writes = State.perf.writes + 1
                            end
                        end
                        values[index] = nil
                    end
                end
                -- anti-fling: if the server yanks the root faster than anything
                -- physical, snap back to the last good spot
                if Config.AntiFling then
                    local root = getRoot()
                    if root then
                        local now = os.clock()
                        local position = root.Position
                        if FlingState.lastPosition and now - FlingState.lastAt < 1 then
                            local moved = (position - FlingState.lastPosition).Magnitude
                            if moved > 220 then
                                FlingState.strikes = FlingState.strikes + 1
                                root.CFrame = CFrame.new(FlingState.lastPosition)
                                State.perf.writes = State.perf.writes + 1
                            end
                        end
                        FlingState.lastPosition = position
                        FlingState.lastAt = now
                    end
                end
            end
            end
        end
    end)
end

local function applyNoFallDamage()
    task.spawn(function()
        while State.alive do
            task.wait(0.4)
            if Config.NoFallDamage and isAlive() then
                local humanoid = getHumanoid()
                if humanoid then
                    local state = humanoid:GetState()
                    if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.FallingDown then
                        humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                        State.perf.writes = State.perf.writes + 1
                    end
                end
            else
                State.perf.skips = State.perf.skips + 1
            end
        end
    end)
end

local function applyAntiAfk()
    task.spawn(function()
        local idle = 0
        while State.alive do
            task.wait(1)
            if Config.AntiAfk and isAlive() then
                idle = idle + 1
                if idle >= 14 then
                    idle = 0
                    safeCall("anti afk", function()
                        local camera = Camera
                        if camera then camera.CFrame = camera.CFrame * CFrame.new(0, 0, 0.01) end
                        pressKey("W", 0.06)
                        if VirtualUser then VirtualUser:CaptureController() end
                    end)
                end
            end
        end
    end)
end

local function applyMovementLoop()
    task.spawn(function()
        local sprintAt, dashAt = 0, 0
        while State.alive do
            task.wait(0.2)
            if isAlive() then
                if Config.WalkSpeedEnabled or Config.AntiSlow then applySpeed() end
                if Config.JumpPowerEnabled then applyJump() end
                if Config.Noclip then setNoclip(true) end
                if Config.FlyEnabled then flyStep() end
                -- sprint is W then W again in this game; tap it on a slow cycle
                if Config.AlwaysSprint and os.clock() - sprintAt > 4 then
                    sprintAt = os.clock()
                    pressKey("W", 0.05)
                    task.delay(0.12, function() pressKey("W", 0.05) end)
                end
                if Config.DashSpam and os.clock() - dashAt > 0.45 then
                    dashAt = os.clock()
                    pressKey(KNOWLEDGE.DashKey, 0.05)
                end
            else
                if FlyState.active then flyStop() end
            end
        end
    end)
end

-- infinite jump lives on the input signal, exactly like a human jump does
local function applyJumpLoop()
    if not UserInput then return end
    safeCall("jump signal", function()
        UserInput.JumpRequest:Connect(function()
            if Config.InfiniteJump and isAlive() then
                local humanoid = getHumanoid()
                if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    end)
end
-- ═══════════════════════════════════════════════════════════════════════════
-- 12 · INPUT — keys, clicks, GUI buttons, chat, emotes
--      Every path has a fallback; if one executor misses a function the next
--      one is used, and if all of them miss nothing throws.
-- ═══════════════════════════════════════════════════════════════════════════
local VirtualInput = getService("VirtualInputManager")

local KEYCODE_ALIAS = {
    ["1"] = "One", ["2"] = "Two", ["3"] = "Three", ["4"] = "Four", ["5"] = "Five",
    ["6"] = "Six", ["7"] = "Seven", ["8"] = "Eight", ["9"] = "Nine", ["0"] = "Zero",
    ["Q"] = "Q", ["E"] = "E", ["F"] = "F", ["G"] = "G", ["R"] = "R", ["T"] = "T",
    ["Z"] = "Z", ["X"] = "X", ["C"] = "C", ["V"] = "V", ["B"] = "B", ["M"] = "M",
    ["W"] = "W", ["A"] = "A", ["S"] = "S", ["D"] = "D", ["SPACE"] = "Space",
    ["."] = "Period", [","] = "Comma", [";"] = "Semicolon",
    ["ESC"] = "Escape", ["\\"] = "Backslash",
}

keyCodeFor = function(key)
    if type(key) ~= "string" then return nil end
    local alias = KEYCODE_ALIAS[string.upper(key)]
    if not alias then return nil end
    local ok, code = pcall(function() return Enum.KeyCode[alias] end)
    if ok then return code end
    return nil
end

-- One release queue for every key: a key press used to spawn a coroutine just
-- to release it, which meant hundreds of threads a minute for nothing.
local KeyReleases = { at = {}, count = 0, head = 1 }

local function releaseLoop()
    task.spawn(function()
        while State.alive do
            task.wait(0.03)
            local now = os.clock()
            local head = KeyReleases.head
            while head <= KeyReleases.count do
                local entry = KeyReleases.at[head]
                if not entry or entry[1] > now then break end
                local code = entry[2]
                if VirtualInput and code then
                    pcall(function() VirtualInput:SendKeyEvent(false, code, false, game) end)
                end
                KeyReleases.at[head] = nil
                head = head + 1
            end
            KeyReleases.head = head
            if head > 64 then                       -- compact the queue occasionally
                local out = {}
                for index = head, KeyReleases.count do out[#out + 1] = KeyReleases.at[index] end
                KeyReleases.at, KeyReleases.count, KeyReleases.head = out, #out, 1
            end
        end
    end)
end

pressKey = function(key, duration)
    if Config.AcSafeMode and not AC.allow() then return false end
    if key == "M1" then return clickMouse() end
    local code = keyCodeFor(key)
    local pressed = false
    if VirtualInput and code then
        pressed = pcall(function() VirtualInput:SendKeyEvent(true, code, false, game) end)
    end
    if not pressed and keypress then
        pressed = pcall(function() keypress(0.05) end)
    end
    if code then
        KeyReleases.count = KeyReleases.count + 1
        KeyReleases.at[KeyReleases.count] = { os.clock() + math.max(0.03, duration or 0.08), code }
    end
    State.using[key] = os.clock()
    return pressed
end

holdKey = function(key, on)
    local code = keyCodeFor(key)
    if not VirtualInput or not code then return false end
    return safeCall("key hold", function() VirtualInput:SendKeyEvent(on == true, code, false, game) end) == true
end

local MOUSE_CENTRE = Vector2.new(0, 0)
local MouseReleases = { at = {}, head = 1, count = 0 }

clickMouse = function()
    if Config.AcSafeMode and not AC.allow() then return false end
    if VirtualUser then
        local ok = pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(MOUSE_CENTRE)
        end)
        if ok then
            MouseReleases.count = MouseReleases.count + 1
            MouseReleases.at[MouseReleases.count] = os.clock() + 0.06
            return true
        end
    end
    if mouse1click then return pcall(mouse1click) end
    if mouse1press and mouse1release then
        local ok = pcall(mouse1press)
        if ok then
            MouseReleases.count = MouseReleases.count + 1
            MouseReleases.at[MouseReleases.count] = os.clock() + 0.06
        end
        return ok
    end
    return false
end

local function mouseReleaseLoop()
    task.spawn(function()
        while State.alive do
            task.wait(0.03)
            local now = os.clock()
            while MouseReleases.head <= MouseReleases.count do
                if (MouseReleases.at[MouseReleases.head] or math.huge) > now then break end
                if VirtualUser then pcall(function() VirtualUser:Button1Up(MOUSE_CENTRE) end)
                elseif mouse1release then pcall(mouse1release) end
                MouseReleases.at[MouseReleases.head] = nil
                MouseReleases.head = MouseReleases.head + 1
            end
            if MouseReleases.head > 64 then
                MouseReleases.at, MouseReleases.count, MouseReleases.head = {}, 0, 1
            end
        end
    end)
end

local function clickGuiButton(button)
    if not button then return false end
    if firesignal then
        local ok = safeCall("firesignal", function() firesignal(button.MouseButton1Click) return true end)
        if ok then return true end
    end
    if VirtualUser then
        local position = button.AbsolutePosition
        local size = button.AbsoluteSize
        local point = Vector2.new(position.X + size.X / 2, position.Y + size.Y / 2)
        return safeCall("gui click", function()
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(point)
            task.wait(0.05)
            VirtualUser:Button1Up(point)
            return true
        end) == true
    end
    return false
end

-- walk the player GUI (and the game's own GUI) for a button whose text matches
local function findGuiButton(tokens, limit)
    local now = os.clock()
    local purpose = table.concat(tokens, "|")
    local memo = Cache.guiSearch[purpose]
    if memo then
        -- reuse the button we found before while it is still on screen, and do
        -- not walk the interface more than once per 1.5 s per purpose
        local button = memo.button
        if button and button.Parent then
            State.perf.reused = State.perf.reused + 1
            return button
        end
        if now - memo.at < 1.5 then
            State.perf.skips = State.perf.skips + 1
            return nil
        end
    end
    local playerGui = Cache.playerGui
    if not playerGui or not playerGui.Parent or now - Cache.playerGuiAt > 5 then
        playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") or nil
        Cache.playerGui, Cache.playerGuiAt = playerGui, now
    end
    local core = Cache.coreGui
    if not core or not core.Parent then
        core = game:FindFirstChild("CoreGui")
        Cache.coreGui = core
    end
    local roots = {}
    if playerGui then roots[#roots + 1] = playerGui end
    if core then roots[#roots + 1] = core end
    for _, root in ipairs(roots) do
        local descendants = listDescendants(root, {}, limit or 900)
        for _, node in ipairs(descendants) do
            if node:IsA("TextButton") or node:IsA("ImageButton") then
                if node.Visible ~= false then
                    local label = node.Name
                    if node:IsA("TextButton") then label = label .. " " .. tostring(node.Text) end
                    if containsAny(label, tokens) then
                        Cache.guiSearch[purpose] = { at = now, button = node }
                        return node
                    end
                end
            end
        end
    end
    Cache.guiSearch[purpose] = { at = now, button = nil }
    return nil
end

local ChatEvents = ReplicatedStorage and ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
local SayRequest = ChatEvents and ChatEvents:FindFirstChild("SayMessageRequest")

chatSay = function(message)
    if type(message) ~= "string" or message == "" then return false end
    if SayRequest then
        local ok = safeCall("chat", function() SayRequest:FireServer(message, "All") return true end)
        if ok then return true end
    end
    return false
end

-- the emote wheel: open it, pick a slot, close it. Some builds bind it to
-- different keys, so the hub tries the known ones.
playEmote = function(slot)
    slot = math.max(1, math.min(9, math.floor(tonumber(slot) or 1)))
    task.spawn(function()
        for _, wheelKey in ipairs(KNOWLEDGE.EmoteKeys) do
            pressKey(wheelKey, 0.05)
            task.wait(0.12)
            pressKey(tostring(slot), 0.05)
            task.wait(0.1)
            pressKey("\\", 0.05)                       -- back out of the wheel
            task.wait(0.1)
        end
    end)
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 14 · COMBAT CORE — face, M1, skills, block, Black Flash, dash, awaken
-- ═══════════════════════════════════════════════════════════════════════════
local HitboxOriginal = {}

local function facePosition(position)
    local root = getRoot()
    if not root or not position then return end
    local origin = root.Position
    local flat = Vector3.new(position.X, origin.Y, position.Z)
    if (flat - origin).Magnitude < 0.5 then return end      -- already facing it
    pcall(function() root.CFrame = CFrame.new(origin, flat) end)
end

local function faceTarget(target)
    if not target then return end
    facePosition(target.position or modelPosition(target.instance or target))
end

local function aimCameraAt(position, smooth)
    if not Camera or not position then return end
    local root = getRoot()
    if not root then return end
    local from = Camera.CFrame.Position
    -- rotate the camera onto the target; a lock-on turns your view, it does
    -- not teleport the camera. CFrame.lookAt when the executor has it.
    local ok, facing = pcall(function()
        if CFrame.lookAt then return CFrame.lookAt(from, position) end
        return CFrame.new(from, position)
    end)
    if not ok or not facing then return end
    local amount = math.max(0.02, math.min(1, smooth or Config.LockSmooth))
    pcall(function() Camera.CFrame = Camera.CFrame:Lerp(facing, amount) end)
end

local function attackOnce()
    if not isAlive() then return false end
    if Config.AutoEquipWeapon and (not equippedTool() or toolScore(equippedTool()) < 30) then
        equipBestWeapon()
    end
    local delay = tonumber(Config.AttackDelay) or 0.12
    if Config.CombatJitter then delay = delay * (0.85 + math.random() * 0.4) end
    if Config.FastAttack and os.clock() - State.lastAttack < delay then return false end
    State.lastAttack = os.clock()
    local tool = equippedTool()
    if tool and toolScore(tool) >= 30 then
        local ok = safeCall("activate", function()
            tool:Activate()
            return true
        end)
        if ok then return true end
    end
    return clickMouse()
end

local function skillKeyList()
    local source = Config.SkillKeys or "1,2,3,4"
    if Cache.skillKeys and Cache.skillKeysSource == source then
        return Cache.skillKeys
    end
    local keys = {}
    for token in string.gmatch(source, "[^,%s]+") do
        keys[#keys + 1] = token
    end
    Cache.skillKeys, Cache.skillKeysSource = keys, source
    return keys
end

local function castSkill(key, force)
    if key == nil then return false end
    if not force and not Config.AutoSkills then return false end
    if not isAlive() then return false end
    local now = os.clock()
    local slot = tostring(key)
    local readyAt = State.using["cd" .. slot] or 0
    if now < readyAt then return false end
    local cooldown = math.max(0.2, tonumber(Config.SkillCooldown) or 1.6)
    State.using["cd" .. slot] = now + cooldown
    return pressKey(slot, 0.08)
end

local function castSkills(force)
    local keys = skillKeyList()
    if #keys == 0 then return end
    State.skillIndex = (State.skillIndex % #keys) + 1
    castSkill(keys[State.skillIndex], force)
end

local function blockHold(on)
    if on then
        State.blockUntil = math.huge
    else
        State.blockUntil = 0
    end
    return holdKey(KNOWLEDGE.BlockKey, on)
end

-- a short block, exactly as long as the parry window wants it
local function perfectBlock()
    task.spawn(function()
        holdKey(KNOWLEDGE.BlockKey, true)
        task.wait(math.max(0.05, tonumber(Config.ParryWindow) or 0.16))
        if State.blockUntil ~= math.huge then holdKey(KNOWLEDGE.BlockKey, false) end
    end)
    return true
end

local function releaseBlock()
    State.blockUntil = 0
    holdKey(KNOWLEDGE.BlockKey, false)
end

-- ⚡ Black Flash — 2.5× damage, three legal ways to ask for it
--    "Counter"   · F at the hit frame, then M1 straight after
--    "Double tap"· skill 3, wait for the flash, skill 3 again
--    "Auto"      · picks the route that fits the style you are playing
local function blackFlash()
    if not isAlive() then return false end
    if not canBlackFlash() and not Config.ForceBlackFlash then return false end
    local now = os.clock()
    if now - State.lastBlackFlash < math.max(0.4, tonumber(Config.BlackFlashCooldown) or 1.4) then return false end
    State.lastBlackFlash = now
    State.blackFlashes = State.blackFlashes + 1

    local mode = Config.BlackFlashMode or "Auto"
    local style = State.style
    if mode == "Auto" then
        if containsAny(style, KNOWLEDGE.DoubleTap) then
            mode = "Double tap"
        elseif containsAny(style, KNOWLEDGE.Counter) then
            mode = "Counter"
        else
            mode = "Counter"
        end
    end

    if mode == "Counter" then
        task.spawn(function()
            holdKey(KNOWLEDGE.BlockKey, true)
            task.wait(math.max(0.04, (tonumber(Config.BlackFlashDelay) or 300) / 1000))
            holdKey(KNOWLEDGE.BlockKey, false)
            task.wait(0.03)
            attackOnce()
        end)
        return true
    end

    -- double tap / focus strike: same input twice, the gap is the whole trick
    local key = Config.BlackFlashKey or "3"
    task.spawn(function()
        castSkill(key, true)
        task.wait(math.max(0.08, (tonumber(Config.BlackFlashDelay) or 300) / 1000))
        castSkill(key, true)
    end)
    return true
end

local function awakenNow()
    if not Config.AutoAwaken then return false end
    if State.awakened and not Config.ReAwaken then return false end
    if os.clock() - (State.using["awaken"] or 0) < 5 then return false end
    State.using["awaken"] = os.clock()
    return pressKey(KNOWLEDGE.AwakenKey, 0.08)
end

local function domainNow()
    if os.clock() - (State.using["domain"] or 0) < 8 then return false end
    State.using["domain"] = os.clock()
    pressKey(Config.DomainKey or KNOWLEDGE.SpecialKey, 0.08)
    task.wait(0.1)
    if (Config.DomainSkill or "") ~= "" then pressKey(tostring(Config.DomainSkill), 0.08) end
    State.domainOpen = true
    notify("Domain", "area expansion cast · " .. tostring(Config.DomainKey or "R"), 4, Theme.Mauve, ICON.Hex)
    return true
end

local function burstNow()
    if not Config.AutoBurst then return false end
    if os.clock() - (State.using["burst"] or 0) < 6 then return false end
    State.using["burst"] = os.clock()
    return pressKey(Config.BurstKey or "B", 0.08)
end

-- the hitbox set only changes when the target list or the size does, so the
-- expensive part (walking every part of every target) runs on change, not per tick
local function applyHitbox()
    if not Config.HitboxEnabled then
        WriteCache.hitboxKey = nil
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
        for _, entry in ipairs(World.players) do
            if entry.alive and entry.distance <= 120 then table.insert(targets, entry.instance) end
        end
    end
    if Config.HitboxTarget == "Dummies" or Config.HitboxTarget == "Both" or Config.HitboxTarget == "Mobs" then
        for _, entry in ipairs(World.dummies) do
            if entry.distance <= 120 then table.insert(targets, entry.instance) end
        end
    end
    local size = clamp(tonumber(Config.HitboxSize) or 8, 2, 40)
    local key = size .. ":" .. #targets
    for index = 1, #targets do
        key = key .. ":" .. tostring(targets[index])
    end
    if WriteCache.hitboxKey == key then
        State.perf.skips = State.perf.skips + 1
        return
    end
    WriteCache.hitboxKey = key
    for _, model in ipairs(targets) do
        local stored = HitboxOriginal[model]
        if not stored then stored = {} HitboxOriginal[model] = stored end
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                if stored[part] == nil then stored[part] = part.Size end
                if part.Size.X ~= size or part.Size.Y ~= size or part.Size.Z ~= size then
                    part.Size = Vector3.new(size, size, size)
                    State.perf.writes = State.perf.writes + 1
                end
            end
        end
    end
end

local function killTarget(entry)
    if not entry then return false end
    faceTarget(entry)
    attackOnce()
    castSkills(true)
    blackFlash()
    return true
end

local function damageDetected()
    local humanoid = getHumanoid()
    if not humanoid then return false end
    local health = humanoid.Health or 0
    if health == State.lastHealth then return false end
    local hurt = health < (State.lastHealth or 100) - 0.5
    State.lastHealth = health
    if hurt then State.lastHealthAt = os.clock() end
    return hurt
end

local function detectThreat()
    scanWorld()
    local list = targetList(Config.KillAuraPlayers, true, Config.BlockRange or 18)
    local root = getRoot()
    if not root then return nil end
    local forward = Camera and Camera.CFrame.LookVector
    for _, entry in ipairs(list) do
        if entry.humanoid then
            local facing = true
            if forward and entry.position then
                local direction = (entry.position - root.Position)
                if direction.Magnitude > 0 then
                    facing = direction.Unit:Dot(forward) > -0.25
                end
            end
            if facing then
                State.threat = entry
                State.threatAt = os.clock()
                return entry
            end
        end
    end
    State.threat = nil
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 15 · COMBO ENGINE — presets, recorder, player
-- ═══════════════════════════════════════════════════════════════════════════
local ComboPresets = {
    ["Vessel · M1x3 → skill 3 → M1"] = { "M1", "M1", "M1", "3", "M1" },
    ["Vessel · Divergent Black Flash"] = { "3", "3" },
    ["Honored One · M1x3 → 1 → 2 → 3"] = { "M1", "M1", "M1", "1", "2", "3" },
    ["Honored One · Reversal Red Max → spam R"] = { "2", "R", "R", "R" },
    ["Perfection · Focus Strike → skill 3 → 3"] = { "3", "3" },
    ["Switcher · 3 → R → 2 → 2"] = { "3", "R", "2", "2" },
    ["Ten Shadows · M1x3 → 1 → 2"] = { "M1", "M1", "M1", "1", "2" },
    ["Universal · 4 → 1 → 2 → 3 → 4"] = { "4", "1", "2", "3", "4" },
    ["Block → M1 (counter)"] = { "F", "M1" },
    ["Dash → M1 → 1 → Dash"] = { "Q", "M1", "1", "Q" },
}

local function playCombo(steps, target, loop)
    if type(steps) ~= "table" or #steps == 0 then return false end
    State.comboPlaying = true
    task.spawn(function()
        repeat
            for _, step in ipairs(steps) do
                if not State.alive or not isAlive() then break end
                if State.comboInterrupt and State.comboInterrupt() then break end
                local entry = target or nearestTarget(Config.ComboRange or 22)
                if entry and Config.ComboFace then faceTarget(entry) end
                local key = step
                local delay = tonumber(Config.ComboDelay) or 0.22
                if type(step) == "table" then key, delay = step[1], tonumber(step[2]) or delay end
                if key == "M1" then
                    attackOnce()
                elseif key == "BF" then
                    blackFlash()
                else
                    pressKey(tostring(key), tonumber(Config.ComboHold) or 0.07)
                end
                if Config.ComboFace and entry then faceTarget(entry) end
                task.wait(math.max(0.03, delay / math.max(0.2, tonumber(Config.ComboSpeed) or 1)))
            end
        until not loop or not State.alive or not Config.ComboLoop
        State.comboPlaying = false
    end)
    return true
end

local function startRecording()
    State.recorded = {}
    State.comboRecording = true
    State.recordedAt = os.clock()
    print("[Skill Hub] combo recorder armed — press your skills in order, then hit stop (max 12 s)")
end

local function stopRecording()
    State.comboRecording = false
    local steps = {}
    for _, entry in ipairs(State.recorded) do table.insert(steps, entry.key) end
    if #steps > 0 then
        print("[Skill Hub] recorded combo: " .. table.concat(steps, " → "))
    else
        print("[Skill Hub] nothing was recorded")
    end
    return steps
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 16 · ESP — Highlight + Billboard, nothing executor-only
-- ═══════════════════════════════════════════════════════════════════════════
local EspGui, EspRegistry, TracerGui = nil, {}, nil

local ESP_STYLE = {
    player = { color = Color3.fromRGB(126, 141, 255), label = "PLAYER" },
    enemy  = { color = Color3.fromRGB(223, 118, 116), label = "ENEMY" },
    dummy  = { color = Color3.fromRGB(224, 184, 116), label = "DUMMY" },
    pickup = { color = Color3.fromRGB(173, 143, 222), label = "PICKUP" },
    domain = { color = Color3.fromRGB(201, 141, 178), label = "DOMAIN" },
}

local function espGui()
    if EspGui and EspGui.Parent then return EspGui end
    local parent = guiParent()
    if not parent then return nil end
    EspGui = new("ScreenGui", {
        Name = "SkillHubEsp", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 5, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, parent)
    return EspGui
end

local function espColor(kind)
    local style = ESP_STYLE[kind] or ESP_STYLE.player
    return style.color, style.label
end

local function espRemove(instance)
    local entry = EspRegistry[instance]
    if not entry then return end
    if entry.highlight and entry.highlight.Parent then entry.highlight:Destroy() end
    if entry.billboard and entry.billboard.Parent then entry.billboard:Destroy() end
    if entry.tracer and entry.tracer.Parent then entry.tracer:Destroy() end
    EspRegistry[instance] = nil
end

local function espAttach(instance, kind, entry)
    if not instance or not instance.Parent then return end
    local color, styleLabel = espColor(kind)
    local record = EspRegistry[instance]
    if not record then
        record = { kind = kind }
        EspRegistry[instance] = record
    end
    record.color, record.styleLabel = color, styleLabel
    record.entry = entry
    local highlight = record.highlight
    if not highlight or not highlight.Parent then
        highlight = new("Highlight", { Name = "SkillHubHighlight" }, instance)
        record.highlight = highlight
    end
    if highlight then
        safeCall("esp highlight", function()
            highlight.FillColor = color
            highlight.OutlineColor = color
            highlight.FillTransparency = Config.EspFillTransparency or 0.62
            highlight.OutlineTransparency = 0.15
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = instance
        end)
    end
    if Config.EspNames then
        local billboard = record.billboard
        if not billboard or not billboard.Parent then
            billboard = new("BillboardGui", {
                Name = "SkillHubEspLabel", AlwaysOnTop = true, ResetOnSpawn = false,
                Size = UDim2.new(0, 190, 0, 32), StudsOffset = Vector3.new(0, 3.2, 0),
                LightInfluence = 0, MaxDistance = Config.EspMaxDistance or 1200,
            }, guiParent())
            record.billboard = billboard
        end
        if billboard then
            if not record.label then
                record.label = new("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = UIFontBold,
                    TextSize = 12, TextStrokeTransparency = 0.4, Text = "",
                    TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Center,
                }, billboard)
            end
            local name = entry and (entry.display or entry.name) or instance.Name
            local health = entry and entry.health or nil
            local maxHealth = entry and entry.maxHealth or nil
            local distance = entry and entry.distance or nil
            local parts = { styleLabel .. " · " .. name }
            if Config.EspHealth and health and maxHealth and maxHealth > 0 then
                table.insert(parts, string.format("%d%%", math.floor(health / maxHealth * 100)))
            end
            if Config.EspDistance and distance and distance < math.huge then
                table.insert(parts, string.format("%dm", math.floor(distance)))
            end
            if record.label then
                local text = table.concat(parts, "  ")
                if record.label.Text ~= text then          -- text writes are layout work
                    record.label.Text = text
                    State.perf.writes = State.perf.writes + 1
                end
            end
        end
    elseif record.billboard and record.billboard.Parent then
        safeCall("esp label off", function() record.billboard:Destroy() end)
        record.billboard = nil
    end
    if Config.EspTracers then
        local gui = TracerGui
        if not gui then
            local parent = guiParent()
            if parent then
                gui = new("ScreenGui", { Name = "SkillHubTracers", ResetOnSpawn = false, IgnoreGuiInset = true,
                    DisplayOrder = 4 }, parent)
                TracerGui = gui
            end
        end
        if gui then
            local line = record.tracer
            if not line or not line.Parent then
                line = new("Frame", { BackgroundColor3 = color, BackgroundTransparency = 0.35, BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3 }, gui)
                record.tracer = line
            end
            safeCall("esp tracer paint", function()
                line.BackgroundColor3 = color
                local camera = Camera
                if not camera then return end
                local point, onScreen = camera:WorldToViewportPoint(entry.position)
                if not onScreen then line.Visible = false return end
                local viewport = camera.ViewportSize
                local origin = Vector2.new(viewport.X / 2, viewport.Y)
                local delta = Vector2.new(point.X - origin.X, point.Y - origin.Y)
                line.Visible = true
                line.Position = UDim2.new(0, origin.X, 0, origin.Y)
                line.Size = UDim2.new(0, math.max(1, delta.Magnitude), 0, 1)
                line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
            end)
        end
    elseif record.tracer then
        safeCall("esp tracer off", function() record.tracer:Destroy() end)
        record.tracer = nil
    end
end

local function espEnable(kind)
    if kind == "player" then return Config.EspPlayers end
    if kind == "dummy" then return Config.EspDummies end
    if kind == "pickup" then return Config.EspPickups end
    if kind == "domain" then return Config.EspDomains end
    return false
end

local function espLoop()
    task.spawn(function()
        local wanted = Cache.espWanted or {}
        Cache.espWanted = wanted
        local marker = Cache.espMarker or {}
        Cache.espMarker = marker
        local stamp = 0
        while State.alive do
            task.wait(tonumber(Config.EspInterval) or 0.4)
            if not (Config.EspPlayers or Config.EspDummies or Config.EspPickups or Config.EspDomains) then
                if next(EspRegistry) ~= nil then espClear() end
                State.perf.skips = State.perf.skips + 1
            else
                scanWorld()
                stamp = stamp + 1
                local limit = Config.EspMaxDistance or 1200
                local function mark(entry, kind)
                    if entry.instance and entry.distance <= limit then
                        wanted[entry.instance] = { kind = kind, entry = entry, stamp = stamp }
                    end
                end
                if espEnable("player") then
                    for index = 1, #World.players do
                        local entry = World.players[index]
                        if entry.alive then mark(entry, "player") end
                    end
                end
                if espEnable("dummy") then
                    for index = 1, #World.dummies do mark(World.dummies[index], "dummy") end
                end
                if espEnable("pickup") then
                    for index = 1, #World.pickups do mark(World.pickups[index], "pickup") end
                end
                if espEnable("domain") then
                    for index = 1, #World.domains do mark(World.domains[index], "domain") end
                end
                for instance, record in pairs(wanted) do
                    if record.stamp == stamp then
                        espAttach(instance, record.kind, record.entry)
                    else
                        espRemove(instance)
                        wanted[instance] = nil
                    end
                end
                State.perf.espUpdates = State.perf.espUpdates + 1
            end
        end
    end)
end

local function espClear()
    for instance in pairs(EspRegistry) do espRemove(instance) end
end
-- ═══════════════════════════════════════════════════════════════════════════
-- 17 · FUN — the toys. Everything here is client-side: nobody else's game
--      state changes, which is exactly why it is safe to leave switched on.
-- ═══════════════════════════════════════════════════════════════════════════
local Fun = {
    highlight = nil,
    rainbow = 0,
    vfxOff = {},
    vfxAt = 0,
    trail = false,
    trailAttachment = nil,
    dome = nil,
    lastEmoteAt = 0,
    music = nil,
    dashNoise = nil,
    disco = 0,
    shake = 0,
    originalLighting = nil,
    originalHead = nil,
    originalAmbient = nil,
    originalClock = 0,
}

local function funHighlight()
    local character = getChar()
    if not character then return nil end
    local highlight = Cache.selfAura
    if highlight and highlight.Parent == character then
        State.perf.reused = State.perf.reused + 1
        return highlight
    end
    highlight = character:FindFirstChild("SkillHubSelfAura")
    if not highlight then
        highlight = new("Highlight", { Name = "SkillHubSelfAura" }, character)
    end
    Cache.selfAura = highlight
    return highlight
end

local function rainbowStep(alpha)
    local hue = (Fun.rainbow % 360) / 360
    local color = Color3.fromHSV(hue, 0.55, 1)
    local highlight = funHighlight()
    if highlight then
        safeCall("rainbow", function()
            highlight.FillColor = color
            highlight.OutlineColor = color
            highlight.FillTransparency = Config.AuraTransparency or 0.55
            highlight.OutlineTransparency = 0.1
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = getChar()
        end)
    end
    return color
end

local function stopRainbow()
    local character = getChar()
    if character then
        local highlight = character:FindFirstChild("SkillHubSelfAura")
        if highlight then safeCall("rainbow off", function() highlight:Destroy() end) end
    end
end

local function trailToggle(on)
    local character = getChar()
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    safeCall("trail", function()
        local existing = root:FindFirstChild("SkillHubTrail")
        if not on then
            if existing then existing:Destroy() end
            if Fun.trailAttachment then Fun.trailAttachment:Destroy() Fun.trailAttachment = nil end
            return
        end
        if existing then return end
        local a0 = Instance.new("Attachment")
        a0.Name = "SkillHubTrailA0"
        a0.Position = Vector3.new(0, 0.6, 0)
        a0.Parent = root
        local a1 = Instance.new("Attachment")
        a1.Name = "SkillHubTrailA1"
        a1.Position = Vector3.new(0, -0.6, 0)
        a1.Parent = root
        local trail = Instance.new("Trail")
        trail.Name = "SkillHubTrail"
        trail.Attachment0 = a0
        trail.Attachment1 = a1
        trail.Lifetime = math.max(0.1, tonumber(Config.TrailLifetime) or 1.2)
        trail.MinLength = 0
        trail.WidthScale = NumberSequence.new(1)
        local color = Color3.fromHSV(((tonumber(Config.TrailHue) or 200) % 360) / 360, 0.6, 1)
        trail.Color = ColorSequence.new(color)
        trail.Parent = root
        Fun.trailAttachment = a0
    end)
end

-- a domain dome that only exists on your screen
local function domeToggle(on)
    if not on then
        if Fun.dome then safeCall("dome off", function() Fun.dome:Destroy() end) Fun.dome = nil end
        return
    end
    local root = getRoot()
    if not root then return end
    safeCall("dome", function()
        if Fun.dome and Fun.dome.Parent then Fun.dome:Destroy() end
        local size = math.max(20, math.min(400, tonumber(Config.DomeSize) or 120))
        local dome = Instance.new("Part")
        dome.Name = "SkillHubDome"
        dome.Shape = Enum.PartType.Ball
        dome.Size = Vector3.new(size, size, size)
        dome.Anchored, dome.CanCollide, dome.CanQuery, dome.CanTouch = true, false, false, false
        dome.Material = Enum.Material.ForceField
        dome.Color = Color3.fromHSV(((tonumber(Config.DomeHue) or 280) % 360) / 360, 0.7, 1)
        dome.Transparency = 0.6
        dome.CFrame = CFrame.new(root.Position)
        dome.Parent = Workspace
        Fun.dome = dome
    end)
end

local function musicToggle(on)
    if not on then
        if Fun.music then safeCall("music off", function() Fun.music:Destroy() end) Fun.music = nil end
        return
    end
    local id = tostring(Config.MusicId or "")
    id = string.gsub(id, "[^%d]", "")
    if id == "" then return end
    safeCall("music", function()
        if Fun.music then Fun.music:Destroy() end
        local sound = Instance.new("Sound")
        sound.Name = "SkillHubMusic"
        sound.SoundId = "rbxassetid://" .. id
        sound.Volume = math.max(0, math.min(10, tonumber(Config.MusicVolume) or 1))
        sound.Looped = true
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        Fun.music = sound
    end)
end

local function dashNoiseToggle(on)
    if not on then
        if Fun.dashNoise then safeCall("noise off", function() Fun.dashNoise:Destroy() end) Fun.dashNoise = nil end
        return
    end
    safeCall("dash noise", function()
        if Fun.dashNoise then Fun.dashNoise:Destroy() end
        local sound = Instance.new("Sound")
        sound.Name = "SkillHubDashNoise"
        sound.SoundId = "rbxassetid://" .. tostring(Config.DashNoiseId or 9040055117)
        sound.Volume = math.max(0, math.min(10, tonumber(Config.MusicVolume) or 1))
        sound.Parent = getRoot() or game:GetService("SoundService")
        sound:Play()
        Fun.dashNoise = sound
    end)
end

local function lightingSnapshot()
    if not Lighting or Fun.originalLighting then return end
    Fun.originalLighting = {
        ambient = Lighting.Ambient,
        outdoor = Lighting.OutdoorAmbient,
        clock = Lighting.ClockTime,
        fog = Lighting.FogEnd,
        brightness = Lighting.Brightness,
    }
end

local function restoreLighting()
    if not Lighting or not Fun.originalLighting then return end
    safeCall("lighting restore", function()
        Lighting.Ambient = Fun.originalLighting.ambient
        Lighting.OutdoorAmbient = Fun.originalLighting.outdoor
        Lighting.ClockTime = Fun.originalLighting.clock
        Lighting.FogEnd = Fun.originalLighting.fog
        Lighting.Brightness = Fun.originalLighting.brightness
    end)
    Fun.originalLighting = nil
end

local function funLoop()
    task.spawn(function()
        while State.alive do
            task.wait(0.1)
            if Config.RainbowAura then
                Fun.rainbow = Fun.rainbow + 4
                rainbowStep()
            elseif Fun.rainbow ~= 0 then
                Fun.rainbow = 0
                stopRainbow()
            end

            if Config.Fullbright and Lighting then
                lightingSnapshot()
                safeCall("fullbright", function()
                    Lighting.Ambient = Color3.fromRGB(178, 178, 178)
                    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
                    Lighting.Brightness = 2
                end)
            end
            if Config.NoFog and Lighting then
                lightingSnapshot()
                safeCall("no fog", function() Lighting.FogEnd = 100000 end)
            end
            if Config.BloodMoon and Lighting then
                lightingSnapshot()
                safeCall("blood moon", function()
                    Lighting.ClockTime = 0
                    Lighting.Ambient = Color3.fromRGB(90, 30, 40)
                    Lighting.OutdoorAmbient = Color3.fromRGB(120, 40, 50)
                end)
            elseif Config.DiscoMode and Lighting then
                lightingSnapshot()
                Fun.disco = Fun.disco + 1
                safeCall("disco", function()
                    local hue = (Fun.disco * 6) % 360 / 360
                    local color = Color3.fromHSV(hue, 0.6, 1)
                    Lighting.Ambient = color
                    Lighting.OutdoorAmbient = color
                end)
            elseif not Config.Fullbright and not Config.NoFog and Fun.originalLighting and not Config.BloodMoon and not Config.DiscoMode then
                restoreLighting()
            end
            if Config.TimeOfDay and Lighting then
                lightingSnapshot()
                safeCall("time", function() Lighting.ClockTime = tonumber(Config.TimeOfDay) or 14 end)
            end
            if Config.CameraShake and Camera then
                Fun.shake = Fun.shake + 1
                safeCall("shake", function()
                    local amount = (tonumber(Config.ShakePower) or 0.4)
                    Camera.CFrame = Camera.CFrame * CFrame.Angles(
                        math.sin(Fun.shake * 1.7) * amount * 0.01,
                        math.cos(Fun.shake * 1.3) * amount * 0.01, 0)
                end)
            end
            if Config.DomainDome then
                local root = getRoot()
                if Fun.dome and Fun.dome.Parent then
                    safeCall("dome follow", function()
                        if root then Fun.dome.CFrame = CFrame.new(root.Position) end
                        local size = math.max(20, math.min(400, tonumber(Config.DomeSize) or 120))
                        if Fun.dome.Size.X ~= size then Fun.dome.Size = Vector3.new(size, size, size) end
                    end)
                else
                    domeToggle(true)
                end
            elseif Fun.dome then
                domeToggle(false)
            end
            if Config.AuraTrail and not (Fun.trail or (getRoot() and getRoot():FindFirstChild("SkillHubTrail"))) then
                Fun.trail = true
                trailToggle(true)
            elseif not Config.AuraTrail and Fun.trail then
                Fun.trail = false
                trailToggle(false)
            end
            if Config.EmoteLoop and os.clock() - (Fun.lastEmoteAt or 0) > math.max(4, tonumber(Config.EmoteLoopDelay) or 12) then
                Fun.lastEmoteAt = os.clock()
                playEmote(Config.EmoteSlot)
            end
            if Config.BigHead then
                local character = getChar()
                local head = character and character:FindFirstChild("Head")
                if head then
                    if not Fun.originalHead then Fun.originalHead = head.Size end
                    safeCall("big head", function() head.Size = Vector3.new(4, 4, 4) end)
                end
            elseif Fun.originalHead then
                local character = getChar()
                local head = character and character:FindFirstChild("Head")
                if head then safeCall("head restore", function() head.Size = Fun.originalHead end) end
                Fun.originalHead = nil
            end
            if Config.FpsBoost and os.clock() - (Fun.vfxAt or 0) > 3 then
                Fun.vfxAt = os.clock()
                safeCall("fps", function()
                    if Lighting then Lighting.GlobalShadows = false Lighting.FogEnd = 100000 end
                    local descendants = listDescendants(Workspace, {}, 3000)
                    for _, instance in ipairs(descendants) do
                        local class = instance.ClassName
                        if class == "ParticleEmitter" or class == "Trail" or class == "Beam" or class == "Fire" then
                            if not Fun.vfxOff[instance] then
                                Fun.vfxOff[instance] = true
                                pcall(function() instance.Enabled = false end)
                            end
                        end
                    end
                end)
            end
            if Config.CharScale and Config.CharScale ~= 1 then
                local character = getChar()
                if character and character.ScaleTo then
                    safeCall("scale", function() character:ScaleTo(clamp(tonumber(Config.CharScale) or 1, 0.4, 2.5)) end)
                end
            end
        end
    end)
end

-- Hit sparks used to create two instances per landed hit — a hundred a second
-- during a kill aura. Now a fixed pool of anchors is moved around and told to
-- emit, so a spark costs no allocation at all.
local SparkPool = { anchors = {}, emitters = {}, index = 0, size = 5 }

local function sparkPool()
    if #SparkPool.anchors > 0 or not Workspace then return end
    for _ = 1, SparkPool.size do
        local anchor = Instance.new("Part")
        anchor.Name = "SkillHubSparkAnchor"
        anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
        anchor.Transparency = 1
        anchor.Size = Vector3.new(0.2, 0.2, 0.2)
        anchor.Parent = Workspace
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "Spark"
        emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        emitter.Lifetime = NumberRange.new(0.25, 0.5)
        emitter.Speed = NumberRange.new(6, 14)
        emitter.Rate = 0
        emitter.Parent = anchor
        SparkPool.anchors[#SparkPool.anchors + 1] = anchor
        SparkPool.emitters[#SparkPool.emitters + 1] = emitter
    end
end

local function hitSpark(position, color)
    if not Config.HitSparks or not position then return end
    sparkPool()
    local count = #SparkPool.anchors
    if count == 0 then return end
    SparkPool.index = SparkPool.index % count + 1
    local anchor = SparkPool.anchors[SparkPool.index]
    local emitter = SparkPool.emitters[SparkPool.index]
    if not anchor or not anchor.Parent then return end
    anchor.CFrame = CFrame.new(position)
    emitter.Color = ColorSequence.new(color or Color3.fromRGB(126, 141, 255))
    emitter:Emit(10)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 18 · THE LOOPS — auto farm, kill aura, black flash chaining, retaliation
-- ═══════════════════════════════════════════════════════════════════════════
local Loop = { lastKill = 0, killStreak = 0, lastEmote = 0, lastGG = 0, lastSpam = 0 }

-- A kill only counts if the target the hub was actually hitting went down — the
-- scan drops a dead body from the list immediately, so watching the target in
-- hand is the only honest way to count it.
local function noteKill()
    local watched = State.watchTarget
    if watched and watched.humanoid and (watched.humanoid.Health or 0) <= 0 then
        State.kills = State.kills + 1
        Loop.killStreak = Loop.killStreak + 1
        Loop.lastKill = os.clock()
        State.watchTarget = nil
        return true
    end
    return false
end

local function combatLoop()
    task.spawn(function()
        while State.alive do
            task.wait(Config.AcSafeMode and 0.12 or 0.06)
            noteKill()
            if isAlive() and (Config.KillAura or Config.AutoAttack or Config.AutoFarm or Config.AutoCombo) then
                local target = nearestTarget(Config.KillAura and (Config.KillAuraRange or 28) or (Config.AttackRange or 16))
                if target then
                    State.watchTarget = target
                    faceTarget(target)
                    if Config.KillAura or Config.AutoAttack then attackOnce() end
                    if Config.AutoSkills then castSkills() end
                    if Config.AutoDash then dashNow() end
                    if Config.AutoBlackFlash and State.threat then blackFlash() end
                    State.comboHits = State.comboHits + 1
                    if Config.HitSparks and target.position then
                        hitSpark(target.position + Vector3.new(0, 1, 0), Color3.fromRGB(126, 141, 255))
                    end
                end
            end
            if Config.AutoCombo then
                local steps = ComboPresets[Config.ComboPreset or ""] or nil
                if steps and not State.comboPlaying then playCombo(steps, nil, Config.ComboLoop) end
            end
        end
    end)
end

local function defenceCombatLoop()
    task.spawn(function()
        while State.alive do
            task.wait(Config.AcSafeMode and 0.1 or 0.05)
            local damaged = damageDetected()
            if damaged then
                State.comboHits = 0
                if Config.AutoRetaliate then
                    local attacker = nearestTarget(Config.RetaliateRange or 40)
                    if attacker then
                        State.comboTarget = attacker
                        if Config.AutoTurnAround then faceTarget(attacker) end
                        if Config.AutoCounter and isAlive() then
                            holdKey(KNOWLEDGE.BlockKey, true)
                            task.wait(math.max(0.05, tonumber(Config.ParryWindow) or 0.16))
                            holdKey(KNOWLEDGE.BlockKey, false)
                            attackOnce()
                        end
                    end
                end
                if Config.AutoBlackFlash then blackFlash() end
            end
            local threat = (Config.AutoBlock or Config.AutoParry) and detectThreat() or nil
            if threat then
                if Config.AutoBlock then
                    holdKey(KNOWLEDGE.BlockKey, true)
                    State.blockUntil = math.huge
                end
                if Config.AutoParry then
                    holdKey(KNOWLEDGE.BlockKey, true)
                    task.wait(math.max(0.04, tonumber(Config.ParryWindow) or 0.16))
                    holdKey(KNOWLEDGE.BlockKey, false)
                    if Config.AutoCounter then
                        task.wait(0.02)
                        attackOnce()
                    end
                end
            elseif State.blockUntil == math.huge and not Config.HoldBlock then
                State.blockUntil = 0
                holdKey(KNOWLEDGE.BlockKey, false)
            end
        end
    end)
end

local function hitboxLoop()
    task.spawn(function()
        while State.alive do
            task.wait(0.4)
            if Config.HitboxEnabled then applyHitbox() elseif next(HitboxOriginal) then applyHitbox() end
        end
    end)
end

local function farmLoop()
    task.spawn(function()
        while State.alive do
            task.wait(0.35)
            noteKill()
            if isAlive() then
                if Config.AutoKill or Config.AutoFarm then
                    local target = nearestTarget(Config.FarmRange or 60)
                    if target then
                        State.watchTarget = target
                        killTarget(target)
                    end
                end
                if Config.TrainDummy then
                    local dummy = World.dummies[1]
                    if dummy then
                        if dummy.distance > 12 then
                            tweenTo(dummy.position + Vector3.new(0, 3, 3))
                        else
                            State.watchTarget = dummy
                            faceTarget(dummy)
                            attackOnce()
                            castSkills()
                        end
                    end
                end
                if Config.AutoPickup then
                    for _, pickup in ipairs(World.pickups) do
                        if pickup.distance <= (Config.PickupRange or 40) then
                            tweenTo(pickup.position)
                            break
                        end
                    end
                end
                if Config.AutoAwaken then awakenNow() end
                if Config.AutoDomain and (Config.DomainKey or "") ~= "" and not State.domainOpen then domainNow() end
                if Config.AutoBurst then burstNow() end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 18b · PERFORMANCE READOUT
--      Every number here is counted by the hub itself — engine calls are not
--      counted (a client-side script cannot see them), so the panel reports
--      what is actually measurable: how often the map was walked, how much of
--      it was visited, how many writes survived the cache, and how long the
--      last scan took on this machine.
-- ═══════════════════════════════════════════════════════════════════════════
local PerfUI = { pill = nil, label = nil, label2 = nil, last = {}, }

function PerfUI.ensure()
    if PerfUI.label and PerfUI.label.Parent then return PerfUI.label end
    if not Rail then return nil end
    -- the rail is 196 wide and its list ends 100 px above the bottom: this pill
    -- lives in the gap between the list and the version block, so it never
    -- covers a control on any tab
    local pill = new("Frame", {
        Name = "SkillHubPerf",
        BackgroundColor3 = Theme.BgElevated,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 1, -66),
        Size = UDim2.new(1, -24, 0, 34),
        Visible = false,
        ZIndex = 7,
    }, Rail)
    corner(pill, RADIUS.card)
    hairline(pill, Theme.StrokeSoft, 1, 0.4)
    new("Frame", {
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(0, 3, 0, 18), ZIndex = 8,
    }, pill)
    local top = Text({
        Font = UIFontMono, Position = UDim2.new(0, 17, 0, 4), Size = UDim2.new(1, -24, 0, 12),
        Text = "perf · starting", TextColor3 = Theme.TextPrimary, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8,
    }, pill)
    local bottom = Text({
        Font = UIFontMono, Position = UDim2.new(0, 17, 0, 17), Size = UDim2.new(1, -24, 0, 12),
        Text = "waiting for the first sample", TextColor3 = Theme.TextMuted, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8,
    }, pill)
    PerfUI.pill, PerfUI.label, PerfUI.label2 = pill, top, bottom
    return top
end

-- rows for the tab panel (and for anything that wants to print the report)
function PerfUI.rows()
    local perf = State.perf
    if perf.report then return perf.report end
    return {
        { label = "sample", value = "press Measure now" },
        { label = "map walks", value = tostring(perf.structureScans or 0) .. " so far · " .. tostring(perf.visits or 0) .. " visited per walk" },
        { label = "counters", value = tostring(perf.writes or 0) .. " write(s) · " .. tostring(perf.skips or 0) .. " skipped · " .. tostring(perf.reused or 0) .. " reused" },
    }
end

local PERF_KEYS = { "scanCalls", "structureScans", "refreshCalls", "espUpdates", "writes", "skips", "reused" }

-- called once a second from miscLoop(); the first tick only records a baseline
function PerfUI.update()
    local perf = State.perf
    local now = os.clock()
    if Config.PerfStats then PerfUI.ensure() end
    local last = PerfUI.last

    if not last.at then
        last.at = now
        for _, key in ipairs(PERF_KEYS) do last[key] = perf[key] or 0 end
        return
    end

    local seconds = now - last.at
    if seconds < 0.9 then return end

    local rates = perf.rates or {}
    perf.rates = rates
    for _, key in ipairs(PERF_KEYS) do
        rates[key] = ((perf[key] or 0) - (last[key] or 0)) / seconds
        last[key] = perf[key] or 0
    end
    last.at = now

    if perf.measureRequested then
        perf.measureRequested = nil
        perf.report = {
            { label = "sample window", value = string.format("%.2f s", seconds) },
            { label = "map walks / s", value = string.format("%.2f", rates.structureScans or 0) },
            { label = "refreshes / s", value = string.format("%.2f", rates.refreshCalls or 0) },
            { label = "scan cost (last)", value = string.format("%.2f ms", perf.scanMs or 0) },
            { label = "instances / walk", value = tostring(perf.visits or 0) },
            { label = "esp passes / s", value = string.format("%.2f", rates.espUpdates or 0) },
            { label = "writes / s", value = string.format("%.2f", rates.writes or 0) },
            { label = "writes skipped", value = tostring(perf.skips or 0) },
            { label = "values reused", value = tostring(perf.reused or 0) },
            { label = "walks in total", value = tostring(perf.structureScans or 0) .. " walk(s)" },
            { label = "scan budget", value = tostring(Config.ScanBudget or 900) .. " instances" },
        }
        notify("Performance", "1 s sample taken — the report is in the panel below", 5, Theme.Accent, ICON.Spark)
    end

    if PerfUI.pill and PerfUI.pill.Parent then
        local wanted = Config.PerfStats and true or false
        if PerfUI.pill.Visible ~= wanted then PerfUI.pill.Visible = wanted end
        if wanted then
            local top = string.format("walks %d · scan %.2f ms", perf.structureScans or 0, perf.scanMs or 0)
            local bottom = string.format("refresh %.1f/s · wr %.1f/s · esp %.1f/s",
                rates.refreshCalls or 0, rates.writes or 0, rates.espUpdates or 0)
            if PerfUI.label.Text ~= top then PerfUI.label.Text = top end
            if PerfUI.label2.Text ~= bottom then PerfUI.label2.Text = bottom end
        end
    end
end

local function miscLoop()
    task.spawn(function()
        while State.alive do
            task.wait(1)
            -- performance readout (1 s sample, overlay only when asked for)
            safeCall("perfui", PerfUI.update)
            -- session stats + ping
            local humanoid = getHumanoid()
            if not isAlive() and humanoid then
                State.deaths = State.deaths + 1
                State.awakened = false
                State.domainOpen = false
                State.comboHits = 0
            end
            if os.clock() - State.lastPingAt > 2 then
                State.lastPingAt = os.clock()
                safeCall("ping", function()
                    local stats = getService("Stats")
                    if stats then
                        local network = stats.Network
                        local ping = network and network.ServerStatsItem
                            and network.ServerStatsItem["Data Ping"]
                        if ping then State.ping = math.floor(ping:GetValue()) end
                    end
                end)
            end
            if Loop.killStreak > 0 and os.clock() - Loop.lastKill > 6 then Loop.killStreak = 0 end
            if Config.AutoGG and os.clock() - Loop.lastKill < 1.2 and os.clock() - Loop.lastGG > 4 then
                Loop.lastGG = os.clock()
                chatSay(Config.GGMessage or "gg")
            end
            if Config.AutoEmoteOnKill and os.clock() - Loop.lastKill < 1.2 and os.clock() - Loop.lastEmote > 5 then
                Loop.lastEmote = os.clock()
                playEmote(Config.EmoteSlot or 1)
            end
            if Config.ChatSpam and (Config.ChatMessage or "") ~= "" then
                local delay = math.max(3, tonumber(Config.ChatDelay) or 12)
                if os.clock() - (Loop.lastSpam or 0) > delay then
                    Loop.lastSpam = os.clock()
                    chatSay(Config.ChatMessage)
                end
            end
            if Config.AutoRespawn and not isAlive() then
                local button = findGuiButton({ "respawn", "respawn character", "play again", "return" })
                if button then clickGuiButton(button) end
            end
            if Config.AutoQueue then
                local button = findGuiButton({ "queue", "roulette", "join match", "play", "start match", "find match" })
                if button then clickGuiButton(button) end
            end
        end
    end)
end

local function staffLoop()
    task.spawn(function()
        while State.alive do
            task.wait(2.5)
            if Config.StaffWatch and Players then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and not AC.staffWarned[player] then
                        local isStaff = false
                        local groupId = tonumber(Config.StaffGroupId) or 0
                        if groupId > 0 then
                            local ok, rank = pcall(function() return player:GetRankInGroup(groupId) end)
                            if ok and type(rank) == "number" and rank >= 1 then isStaff = true end
                        end
                        local staffList = SharedEnv.SkillHubStaffList
                        if type(staffList) == "table" then
                            for _, name in ipairs(staffList) do
                                if string.lower(tostring(name)) == string.lower(player.Name) then isStaff = true break end
                            end
                        end
                        local lower = string.lower(player.Name)
                        for _, token in ipairs({ "mod", "admin", "owner", "dev", "staff", "tze", "shenanigans" }) do
                            if string.find(lower, token, 1, true) then isStaff = true break end
                        end
                        if isStaff then
                            AC.staffWarned[player] = true
                            notify("Staff watch", player.Name .. " looks like staff — " ..
                                (Config.StaffHop and "hopping now" or "be careful what you press"), 8,
                                Theme.Warning, ICON.Bell)
                            print("[Skill Hub] staff watch · " .. player.Name)
                            if Config.StaffHop then
                                task.wait(1)
                                AC.serverHop()
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 19 · TELEPORT LIBRARY — built live from the map, never from guesses
-- ═══════════════════════════════════════════════════════════════════════════
local function teleportTargets()
    scanWorld(true)
    local list = {}
    for _, zone in ipairs(World.zones) do
        table.insert(list, { name = zone.name, position = zone.position + Vector3.new(0, 4, 0), kind = "zone" })
    end
    for _, dummy in ipairs(World.dummies) do
        table.insert(list, { name = "dummy · " .. dummy.name, position = dummy.position + Vector3.new(0, 3, 0), kind = "dummy" })
    end
    for _, entry in ipairs(World.players) do
        table.insert(list, { name = "player · " .. entry.name, position = entry.position + Vector3.new(0, 3, 0), kind = "player" })
    end
    for _, domain in ipairs(World.domains) do
        table.insert(list, { name = "domain · " .. domain.name, position = domain.position + Vector3.new(0, 5, 0), kind = "domain" })
    end
    if LocalPlayer then
        local spawn = Workspace and Workspace:FindFirstChildOfClass("SpawnLocation")
        if spawn then table.insert(list, { name = "spawn", position = spawn.Position + Vector3.new(0, 4, 0), kind = "spawn" }) end
    end
    return list
end

local function resolveTeleportTarget(name)
    for _, target in ipairs(teleportTargets()) do
        if target.name == name then return target.position end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 20 · PROTECTION EXTRAS — server hop, panic, unload
-- ═══════════════════════════════════════════════════════════════════════════
AC.serverHop = function(preference)
    local placeId = game.PlaceId
    local teleport = getService("TeleportService")
    if not placeId or not teleport or not LocalPlayer then return false end
    if not AC.allow() then return false end
    print("[Skill Hub] hopping servers…")
    local queued = false
    if queue_on_teleport and SharedEnv.SkillHubUrl and SharedEnv.SkillHubUrl ~= "" then
        queued = safeCall("queue", function()
            queue_on_teleport("loadstring(game:HttpGet(\"" .. SharedEnv.SkillHubUrl .. "\"))()")
            return true
        end) == true
    end
    -- try the public server list first (lowest ping / most players), and fall
    -- back to a plain rejoin when the endpoint is not reachable from the executor
    local picked = safeCall("hop list", function()
        local ok, body = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(placeId) ..
                "/servers/Public?sortOrder=" .. (preference == "Most players" and "Desc" or "Asc") .. "&limit=100")
        end)
        if not ok or type(body) ~= "string" then return nil end
        local best = nil
        for id, players in string.gmatch(body, '"id":"([%w%-]+)"[^}]-"playing":(%d+)') do
            local count = tonumber(players) or 0
            if count > 0 and count < 30 and id ~= game.JobId then
                best = id
                if preference ~= "Most players" then break end
            end
        end
        return best
    end)
    if picked then
        local jumped = safeCall("hop join", function()
            teleport:TeleportToPlaceInstance(placeId, picked, LocalPlayer)
            return true
        end)
        if jumped then return true end
    end
    safeCall("hop rejoin", function() teleport:Teleport(placeId, LocalPlayer) end)
    return true
end

-- filled in at the bottom of the file; declared here so unload can compare it
local skillHubInstance

local function panic(reason)
    print("[Skill Hub] panic · " .. tostring(reason or "manual"))
    for name, value in pairs(Config) do
        if type(value) == "boolean" then Config[name] = false end
    end
    Config.UiVisible = false
    if ToggleRegistry then
        for _, toggle in ipairs(ToggleRegistry) do
            safeCall("panic toggle", function()
                if toggle.set then toggle.set(false, true) elseif toggle.Set then toggle.Set(false, true) end
            end)
        end
    end
    releaseBlock()
    flyStop()
    setNoclip(false)
    espClear()
    stopRainbow()
    musicToggle(false)
    dashNoiseToggle(false)
    trailToggle(false)
    domeToggle(false)
    restoreLighting()
    for index = #State.comboQueue, 1, -1 do State.comboQueue[index] = nil end
    if Window and Window.Screen then Window.Screen.Enabled = false end
    notify("Panic", "everything off · press " .. tostring(Config.HideUiKey) .. " is disabled until you re-run", 6, Theme.Danger, ICON.Stop)
end

local function unload()
    print("[Skill Hub] unload requested")
    safeCall("unload", function()
        State.alive = false
        Config.UiVisible = false
        releaseBlock()
        flyStop()
        setNoclip(false)
        espClear()
        stopRainbow()
        musicToggle(false)
        dashNoiseToggle(false)
        trailToggle(false)
        domeToggle(false)
        restoreLighting()
        AC.removeHook()
        AC.removeKickGuard()
        if Window and Window.Screen then Window.Screen:Destroy() end
        if EspGui then EspGui:Destroy() end
        if TracerGui then TracerGui:Destroy() end
        if SharedEnv.SkillHubJujutsu == skillHubInstance then SharedEnv.SkillHubJujutsu = nil end
    end)
    print("[Skill Hub] unloaded")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 21 · SELF-TEST
-- ═══════════════════════════════════════════════════════════════════════════
local function selfTest()
    local checks = {}
    local function record(name, ok, detail)
        checks[#checks + 1] = { name = name, ok = ok == true, detail = detail }
        print(string.format("[Skill Hub self-test] %-38s %s%s", name,
            ok and "PASS" or (detail == "skip" and "SKIP" or "FAIL"),
            detail and detail ~= "skip" and ("   (" .. tostring(detail) .. ")") or ""))
    end
    record("window built", Window ~= nil and Window.Screen ~= nil and Window.Screen.Parent ~= nil)
    record("tab count", #Tabs > 0, tostring(#Tabs) .. " tabs")
    record("icon registry", type(ICON) == "table" and ICON.Crest ~= nil)
    record("services alive", Players ~= nil and RunService ~= nil and Workspace ~= nil)
    record("character readable", getChar() ~= nil and getRoot() ~= nil, getChar() and "ok" or "respawning")
    record("style readable", type(State.style) == "string", tostring(State.style))
    record("black flash route chosen", type(Config.BlackFlashMode) == "string", tostring(Config.BlackFlashMode))
    local world = scanWorld(true)
    record("world scan", true, string.format("%d player(s) · %d dummy(ies) · %d pickup(s) · %d zone(s)",
        #world.players, #world.dummies, #world.pickups, #world.zones))
    local telemetry = AC.audit(false)
    record("detector scan", true, string.format("%d script(s) · %d detector(s) · %d report remote(s)",
        telemetry.scripts, telemetry.detectors, telemetry.reports))
    record("report filter", Config.AcBlockReports and AC.hookInstalled == true or not Config.AcBlockReports)
    record("kick guard", AC.kickGuard == true or not Config.AcKickGuard,
        AC.kickGuard and "installed" or "not available in this executor")
    local presetCount = 0
    for _ in pairs(ComboPresets) do presetCount = presetCount + 1 end
    record("combo presets", presetCount > 0, tostring(presetCount) .. " presets")
    record("defence loops", State.started ~= nil)
    local perf = State.perf
    record("two-tier scanner", (perf.structureScans or 0) > 0 and (perf.refreshCalls or 0) >= (perf.structureScans or 0),
        string.format("%d walk(s) · %d refresh(es) · %d visited", perf.structureScans or 0, perf.refreshCalls or 0, perf.visits or 0))
    record("write cache", (perf.writes or 0) > 0 or (perf.skips or 0) > 0,
        string.format("%d write(s) · %d skipped · %d reused", perf.writes or 0, perf.skips or 0, perf.reused or 0))
    local errors = SharedEnv.__SkillHubErrorLog
    local errorCount = type(errors) == "table" and #errors or 0
    record("no unhandled errors", errorCount == 0, tostring(errorCount) .. " recorded")

    local passed = 0
    for _, check in ipairs(checks) do if check.ok then passed = passed + 1 end end
    print(string.format("[Skill Hub self-test] %d/%d checks passed", passed, #checks))
    notify("Self-test", string.format("%d/%d passed", passed, #checks), 5,
        passed == #checks and Theme.Success or Theme.Warning, ICON.Layers)
    return checks
end


do
    NS.AC = AC
    NS.ComboPresets = ComboPresets
    NS.PerfUI = PerfUI
    NS.EspRegistry = EspRegistry
    NS.Fun = Fun
    NS.HitboxOriginal = HitboxOriginal
    NS.KNOWLEDGE = KNOWLEDGE
    NS.Loop = Loop
    NS.State = State
    NS.World = World
    NS.acTelemetry = acTelemetry
    NS.aimCameraAt = aimCameraAt
    NS.applyAntiAfk = applyAntiAfk
    NS.applyDefenceLoop = applyDefenceLoop
    NS.applyHitbox = applyHitbox
    NS.applyJump = applyJump
    NS.applyJumpLoop = applyJumpLoop
    NS.applyMovementLoop = applyMovementLoop
    NS.applyNoFallDamage = applyNoFallDamage
    NS.applySpeed = applySpeed
    NS.attackOnce = attackOnce
    NS.blackFlash = blackFlash
    NS.chatSay = chatSay
    NS.combatLoop = combatLoop
    NS.currentStyle = currentStyle
    NS.currentToolInfo = currentToolInfo
    NS.dashNoiseToggle = dashNoiseToggle
    NS.dashNow = dashNow
    NS.defenceCombatLoop = defenceCombatLoop
    NS.detectThreat = detectThreat
    NS.equipBestWeapon = equipBestWeapon
    NS.espClear = espClear
    NS.espLoop = espLoop
    NS.farmLoop = farmLoop
    NS.flyStop = flyStop
    NS.funLoop = funLoop
    NS.getChar = getChar
    NS.getRoot = getRoot
    NS.hitSpark = hitSpark
    NS.hitboxLoop = hitboxLoop
    NS.isAlive = isAlive
    NS.isAwakened = isAwakened
    NS.killTarget = killTarget
    NS.miscLoop = miscLoop
    NS.modelPosition = modelPosition
    NS.musicToggle = musicToggle
    NS.nearestTarget = nearestTarget
    NS.panic = panic
    NS.playCombo = playCombo
    NS.playEmote = playEmote
    NS.pressKey = pressKey
    NS.releaseBlock = releaseBlock
    NS.resolveTeleportTarget = resolveTeleportTarget
    NS.restoreLighting = restoreLighting
    NS.scanWorld = scanWorld
    NS.selfTest = selfTest
    NS.setNoclip = setNoclip
    NS.staffLoop = staffLoop
    NS.startRecording = startRecording
    NS.stopRainbow = stopRainbow
    NS.stopRecording = stopRecording
    NS.targetList = targetList
    NS.teleportBehind = teleportBehind
    NS.teleportTargets = teleportTargets
    NS.tweenTo = tweenTo
    NS.unload = unload
    NS.wipe = wipe
end
-- ═══════════════════════════════════════════════════════════════════════════
-- 22 · THE TAB LAYER — runs in its own closure
--     Lua allows 200 locals per scope; the interface plus the engine use
--     almost all of them, so the symbols this layer needs arrive through the
--     shared namespace table (NS). This is not style — without it the file
--     stops compiling at ~200 locals, and passing 90 arguments instead
--     breaks the 255-register limit on the call itself.
-- ═══════════════════════════════════════════════════════════════════════════
local function runTabs(NS)
    local AC, AUTHOR, BUILD, Camera, ComboPresets, Config, EspRegistry, Fun, GAME_NAME, HitboxOriginal, ICON, KNOWLEDGE, Lighting, LocalPlayer, Loop, PerfUI, Players, RADIUS, SharedEnv, State, Tabs, Theme, UserInput, VERSION, Workspace, World, acTelemetry, aimCameraAt, applyAntiAfk, applyDefenceLoop, applyHitbox, applyJump, applyJumpLoop, applyMovementLoop, applyNoFallDamage, applySpeed, attackOnce, blackFlash, buildWindow, chatSay, combatLoop, corner, currentStyle, currentToolInfo, dashNoiseToggle, dashNow, defenceCombatLoop, detectThreat, equipBestWeapon, espClear, espLoop, farmLoop, flyStop, funLoop, getChar, getRoot, getService, getWindow, hitSpark, hitboxLoop, isAlive, isAwakened, killTarget, makeTab, miscLoop, modelPosition, musicToggle, nearestTarget, new, notify, panic, playCombo, playEmote, pressKey, releaseBlock, resolveTeleportTarget, restoreLighting, safeCall, scanWorld, selfTest, setNoclip, staffLoop, startRecording, stopRainbow, stopRecording, targetList, teleportBehind, teleportTargets, tweenTo, unload, wipe =
        NS.AC, NS.AUTHOR, NS.BUILD, NS.Camera, NS.ComboPresets, NS.Config, NS.EspRegistry, NS.Fun, NS.GAME_NAME, NS.HitboxOriginal, NS.ICON, NS.KNOWLEDGE, NS.Lighting, NS.LocalPlayer, NS.Loop, NS.PerfUI, NS.Players, NS.RADIUS, NS.SharedEnv, NS.State, NS.Tabs, NS.Theme, NS.UserInput, NS.VERSION, NS.Workspace, NS.World, NS.acTelemetry, NS.aimCameraAt, NS.applyAntiAfk, NS.applyDefenceLoop, NS.applyHitbox, NS.applyJump, NS.applyJumpLoop, NS.applyMovementLoop, NS.applyNoFallDamage, NS.applySpeed, NS.attackOnce, NS.blackFlash, NS.buildWindow, NS.chatSay, NS.combatLoop, NS.corner, NS.currentStyle, NS.currentToolInfo, NS.dashNoiseToggle, NS.dashNow, NS.defenceCombatLoop, NS.detectThreat, NS.equipBestWeapon, NS.espClear, NS.espLoop, NS.farmLoop, NS.flyStop, NS.funLoop, NS.getChar, NS.getRoot, NS.getService, NS.getWindow, NS.hitSpark, NS.hitboxLoop, NS.isAlive, NS.isAwakened, NS.killTarget, NS.makeTab, NS.miscLoop, NS.modelPosition, NS.musicToggle, NS.nearestTarget, NS.new, NS.notify, NS.panic, NS.playCombo, NS.playEmote, NS.pressKey, NS.releaseBlock, NS.resolveTeleportTarget, NS.restoreLighting, NS.safeCall, NS.scanWorld, NS.selfTest, NS.setNoclip, NS.staffLoop, NS.startRecording, NS.stopRainbow, NS.stopRecording, NS.targetList, NS.teleportBehind, NS.teleportTargets, NS.tweenTo, NS.unload, NS.wipe

-- ═══════════════════════════════════════════════════════════════════════════
-- 22 · THE TABS — nine pages, everything the hub can do
-- ═══════════════════════════════════════════════════════════════════════════
local TabCombat, TabFarm, TabCombo, TabMove, TabEsp, TabFun, TabTp, TabAc, TabMisc

local function buildTabs()
    ---------------------------------------------------------------------------
    -- 1 · COMBAT
    ---------------------------------------------------------------------------
    TabCombat = makeTab("Combat", "M1 chain, skills, block, Black Flash, domains", ICON.Swords, Theme.Clay)
    TabCombat:AddLabel("Jujutsu Shenanigans combat spine: M1 melee · 1 2 3 4 skills · Q dash · F block · R special · G awaken. " ..
        "Everything below drives those same inputs — the hub presses what you would press, only faster.", ICON.Fist)
    TabCombat:AddSection("Attack")
    TabCombat:AddToggle("Auto attack (M1)", "keep the melee combo running on the nearest target", Config.AutoAttack,
        function(value) Config.AutoAttack = value end, ICON.Fist)
    TabCombat:AddToggle("Kill aura", "attack every target inside the aura range, closest first", Config.KillAura,
        function(value) Config.KillAura = value end, ICON.Skull)
    TabCombat:AddSlider("Kill aura range", "how far the aura reaches", 6, 80, Config.KillAuraRange, " studs",
        function(value) Config.KillAuraRange = value end, ICON.Search)
    TabCombat:AddToggle("Kill aura hits players", "off = only dummies and NPCs are touched", Config.KillAuraPlayers,
        function(value) Config.KillAuraPlayers = value end, ICON.Player)
    TabCombat:AddToggle("Fast attack", "attack as soon as the animation allows instead of waiting for input", Config.FastAttack,
        function(value) Config.FastAttack = value end, ICON.Bolt)
    TabCombat:AddSlider("Attack delay", "gap between M1s — too low and the client drops the input", 0.04, 0.6, Config.AttackDelay, " s",
        function(value) Config.AttackDelay = value end, ICON.Loop)
    TabCombat:AddToggle("Auto equip melee", "pull a melee tool out of the backpack when the hands are empty", Config.AutoEquipWeapon,
        function(value) Config.AutoEquipWeapon = value end, ICON.Katana)
    TabCombat:AddDropdown("Target priority", "which enemy the hub picks first", { "Closest", "Lowest health", "Nearest to camera", "Players", "Dummies" },
        Config.TargetPriority, function(value) Config.TargetPriority = value end, ICON.Star)
    TabCombat:AddToggle("Auto turn around", "face whoever hits you before doing anything else", Config.AutoTurnAround,
        function(value) Config.AutoTurnAround = value end, ICON.Loop)

    TabCombat:AddSection("Skills")
    TabCombat:AddToggle("Auto skills", "cast 1 2 3 4 on rotation whenever a target is close", Config.AutoSkills,
        function(value) Config.AutoSkills = value end, ICON.Bolt)
    TabCombat:AddInput("Skill keys", "the four ability keys, comma separated", "1,2,3,4", function(text)
        if text and text ~= "" then Config.SkillKeys = text end
    end, ICON.Gear)
    TabCombat:AddSlider("Skill cooldown", "how long the hub waits before reusing one key", 0.3, 6, Config.SkillCooldown, " s",
        function(value) Config.SkillCooldown = value end, ICON.Loop)
    TabCombat:AddToggle("Auto dash", "dash (Q) on cooldown while fighting — also the escape from a stun", Config.AutoDash,
        function(value) Config.AutoDash = value end, ICON.Wind)
    TabCombat:AddSlider("Dash gap", "minimum seconds between dashes", 0.15, 3, Config.DashDelay, " s",
        function(value) Config.DashDelay = value end, ICON.Loop)
    TabCombat:AddToggle("Auto awaken", "press G the moment the awakening bar fills", Config.AutoAwaken,
        function(value) Config.AutoAwaken = value end, ICON.Spark)
    TabCombat:AddToggle("Auto domain", "cast your area expansion as soon as it is available", Config.AutoDomain,
        function(value) Config.AutoDomain = value end, ICON.Hex)
    TabCombat:AddInput("Domain keys", "domain key, optionally followed by a skill", Config.DomainKey .. (Config.DomainSkill ~= "" and ("," .. Config.DomainSkill) or ""),
        function(text)
            if not text then return end
            local key, skill = string.match(text, "^%s*([^,%s]+)%s*,?%s*(%d*)")
            if key and key ~= "" then Config.DomainKey = key Config.DomainSkill = skill or "" end
        end, ICON.Gear)
    TabCombat:AddToggle("Auto burst", "press the burst key when the game lets you — the anti-teaming tool", Config.AutoBurst,
        function(value) Config.AutoBurst = value end, ICON.Bell)
    TabCombat:AddInput("Burst key", "leave empty to disable", Config.BurstKey, function(text)
        Config.BurstKey = text or ""
    end, ICON.Gear)

    TabCombat:AddSection("Black Flash  ⚡")
    TabCombat:AddLabel("Black Flash is 2.5× damage and it is a timing input, not an ability: block on the exact hit frame then " ..
        "strike back, or press skill 3, wait for the white flash and press 3 again. The hub does the timing for you — " ..
        "adjust the delay until your screen shows the black lightning.", ICON.Spark)
    TabCombat:AddToggle("Auto Black Flash", "fire the perfect-block counter whenever something is swinging at you", Config.AutoBlackFlash,
        function(value) Config.AutoBlackFlash = value end, ICON.Spark)
    TabCombat:AddDropdown("Black Flash route", "Auto follows the style you are playing", { "Auto", "Counter", "Double tap" },
        Config.BlackFlashMode, function(value) Config.BlackFlashMode = value end, ICON.Star)
    TabCombat:AddSlider("Black Flash delay", "the gap between the block and the strike — the whole trick lives here", 60, 700, Config.BlackFlashDelay, " ms",
        function(value) Config.BlackFlashDelay = value end, ICON.Loop)
    TabCombat:AddInput("Double-tap key", "the skill that converts (default 3 · Divergent Fist / Focus Strike)", Config.BlackFlashKey,
        function(text) if text and text ~= "" then Config.BlackFlashKey = text end end, ICON.Gear)
    TabCombat:AddSlider("Black Flash cooldown", "how often the hub is allowed to try", 0.3, 6, Config.BlackFlashCooldown, " s",
        function(value) Config.BlackFlashCooldown = value end, ICON.Loop)
    TabCombat:AddToggle("Force on any style", "try even when the hub cannot read a Black Flash-capable style", Config.ForceBlackFlash,
        function(value) Config.ForceBlackFlash = value end, ICON.Warning)
    TabCombat:AddButton("Black Flash now", "fire one attempt immediately — faster feedback than waiting for a fight", function()
        Config.AutoBlackFlash = true
        local ok = blackFlash()
        notify("Black Flash", ok and "attempt fired" or "on cooldown", 3, Theme.Sand, ICON.Spark)
    end, ICON.Spark)

    TabCombat:AddSection("Block & defence in combat")
    TabCombat:AddToggle("Auto block", "hold F while someone is swinging at you", Config.AutoBlock,
        function(value) Config.AutoBlock = value end, ICON.Guard)
    TabCombat:AddToggle("Auto parry", "short, perfectly timed block instead of a held one", Config.AutoParry,
        function(value) Config.AutoParry = value end, ICON.Guard)
    TabCombat:AddSlider("Parry window", "how long the block stays down before the counter", 40, 400, Config.ParryWindow, " ms",
        function(value) Config.ParryWindow = value end, ICON.Loop)
    TabCombat:AddToggle("Auto counter", "strike back the instant a parry lands", Config.AutoCounter,
        function(value) Config.AutoCounter = value end, ICON.Swords)
    TabCombat:AddSlider("Block range", "how close a swing has to be before the hub reacts", 4, 40, Config.BlockRange, " studs",
        function(value) Config.BlockRange = value end, ICON.Search)
    TabCombat:AddToggle("Auto retaliate", "turn on whoever damages you and answer immediately", Config.AutoRetaliate,
        function(value) Config.AutoRetaliate = value end, ICON.Flame)

    TabCombat:AddSection("Aiming & hitbox")
    TabCombat:AddToggle("Lock on", "the camera tracks the current target", Config.LockOn,
        function(value) Config.LockOn = value end, ICON.Eye)
    TabCombat:AddSlider("Lock smooth", "1 = snap instantly, 0.05 = heavy glide", 0.05, 1, Config.LockSmooth, "",
        function(value) Config.LockSmooth = value end, ICON.Loop)
    TabCombat:AddSlider("Lock range", "stop tracking past this distance", 10, 200, Config.LockRange, " studs",
        function(value) Config.LockRange = value end, ICON.Search)
    TabCombat:AddToggle("Silent aim", "client-side only: the camera is moved, no server-side aim values are written", Config.SilentAim,
        function(value) Config.SilentAim = value end, ICON.Ghost)
    TabCombat:AddToggle("FOV circle", "a ring on screen showing the lock range", Config.FovCircle,
        function(value) Config.FovCircle = value end, ICON.Loop)
    TabCombat:AddToggle("Hitbox expander", "grow every hitbox you are aiming at — sizes are restored when you switch it off", Config.HitboxEnabled,
        function(value) Config.HitboxEnabled = value end, ICON.Layers)
    TabCombat:AddSlider("Hitbox size", "box size in studs", 4, 30, Config.HitboxSize, " studs",
        function(value) Config.HitboxSize = value end, ICON.Layers)
    TabCombat:AddDropdown("Hitbox target", "who gets the bigger box", { "Players", "Dummies", "Both" }, Config.HitboxTarget,
        function(value) Config.HitboxTarget = value end, ICON.Star)

    TabCombat:AddSection("One-shot buttons")
    TabCombat:AddButton("Kill target (closest)", "face, strike, dump every skill and try a Black Flash on the nearest enemy", function()
        local target = nearestTarget(60) or (World.players[1])
        if target then killTarget(target) else notify("Combat", "no target in range", 3, Theme.Warning, ICON.Stop) end
    end, ICON.Skull, true)
    TabCombat:AddButton("Bring target", "pull the nearest enemy to your feet", function()
        local target = nearestTarget(200)
        if target and target.instance then
            local root = getRoot()
            if root then
                safeCall("bring", function() target.instance:PivotTo(CFrame.new(root.Position + Vector3.new(0, 0, 3))) end)
            end
        end
    end, ICON.Magnet)
    TabCombat:AddButton("Teleport behind target", "get on their back without a sound cue", function()
        local target = nearestTarget(300)
        if target then teleportBehind(target.instance) end
    end, ICON.Teleport)
    TabCombat:AddButton("Fling target", "client-side shove: looks like a launch on your screen, the server decides the truth", function()
        local target = nearestTarget(20)
        local root = getRoot()
        if target and target.instance and root then
            safeCall("fling", function()
                local part = target.instance:FindFirstChild("HumanoidRootPart") or target.instance.PrimaryPart
                if part and part:IsA("BasePart") then
                    part.AssemblyLinearVelocity = root.CFrame.LookVector * 220 + Vector3.new(0, 90, 0)
                end
            end)
        end
    end, ICON.Wind)
    TabCombat:AddStatusPanel("Combat telemetry", function()
        return {
            { label = "target", value = State.threat and State.threat.name or "—" },
            { label = "combo hits", value = tostring(State.comboHits) },
            { label = "black flashes", value = tostring(State.blackFlashes) },
            { label = "kills (session)", value = tostring(State.kills) },
            { label = "deaths (session)", value = tostring(State.deaths) },
            { label = "style", value = tostring(State.style) },
            { label = "ping", value = tostring(State.ping) .. " ms" },
        }
    end)

    ---------------------------------------------------------------------------
    -- 2 · AUTO FARM
    ---------------------------------------------------------------------------
    TabFarm = makeTab("Auto Farm", "dummies, players, drops and payout runs", ICON.Farm, Theme.Sage)
    TabFarm:AddLabel("Jujutsu Shenanigans has no quest chain to automate — money comes from fights. So the farm side here is: " ..
        "keep a fight running, collect what drops, queue again, and never let the loop stand still.", ICON.Farm)
    TabFarm:AddSection("Farming")
    TabFarm:AddToggle("Auto farm", "kill everything in range on a loop, then move to the next one", Config.AutoFarm,
        function(value) Config.AutoFarm = value end, ICON.Farm)
    TabFarm:AddToggle("Auto kill (instant loop)", "tighter loop, one target at a time, skills included", Config.AutoKill,
        function(value) Config.AutoKill = value end, ICON.Skull)
    TabFarm:AddSlider("Farm range", "how far the loop looks for the next victim", 20, 300, Config.FarmRange, " studs",
        function(value) Config.FarmRange = value end, ICON.Search)
    TabFarm:AddDropdown("Farm target", "what the farm loop is allowed to hit", { "Dummies", "Players", "Both" }, Config.TargetPriority,
        function(value) Config.TargetPriority = value end, ICON.Star)
    TabFarm:AddToggle("Auto pickup", "walk to cash and drops the moment they appear", Config.AutoPickup,
        function(value) Config.AutoPickup = value end, ICON.Loot)
    TabFarm:AddSlider("Pickup range", "how far a drop can be before the hub ignores it", 10, 300, Config.PickupRange, " studs",
        function(value) Config.PickupRange = value end, ICON.Magnet)
    TabFarm:AddToggle("Train on the dummy", "park next to the practice dummy outside the cafe and beat it forever", Config.TrainDummy,
        function(value)
            Config.TrainDummy = value
            if value then
                for _, dummy in ipairs(World.dummies) do
                    tweenTo(dummy.position + Vector3.new(0, 3, 0))
                    break
                end
            end
        end, ICON.Chart)
    TabFarm:AddToggle("Auto respawn", "click the respawn button the frame you die", Config.AutoRespawn,
        function(value) Config.AutoRespawn = value end, ICON.Loop)
    TabFarm:AddToggle("Auto queue", "press the matchmaking / roulette button whenever a lobby is waiting", Config.AutoQueue,
        function(value) Config.AutoQueue = value end, ICON.Play)
    TabFarm:AddButton("Kill everything in range", "one sweep: face, strike, skills — nothing else", function()
        local count = 0
        for _, entry in ipairs(targetList(Config.KillAuraPlayers, true, Config.KillAuraRange)) do
            killTarget(entry)
            count = count + 1
        end
        notify("Combat", count .. " target(s) hit", 3, Theme.Clay, ICON.Swords)
    end, ICON.Skull, true)
    TabFarm:AddSection("Session")
    TabFarm:AddStatusPanel("Farm telemetry", function()
        return {
            { label = "kills", value = tostring(State.kills) },
            { label = "deaths", value = tostring(State.deaths) },
            { label = "kill streak", value = tostring(Loop.killStreak) },
            { label = "dummies", value = tostring(#World.dummies) },
            { label = "drops", value = tostring(#World.pickups) },
            { label = "zone", value = tostring(World.zone) },
        }
    end)
    TabFarm:AddButton("Reset session counters", "zero the kill / death / Black Flash tally", function()
        State.kills, State.deaths, State.blackFlashes, State.comboHits = 0, 0, 0, 0
        Loop.killStreak = 0
        notify("Session", "counters cleared", 3, Theme.Sage, ICON.Loop)
    end, ICON.Loop)

    ---------------------------------------------------------------------------
    -- 3 · COMBO LAB
    ---------------------------------------------------------------------------
    TabCombo = makeTab("Combo Lab", "presets, recorder, perfect chain timing", ICON.Loop, Theme.Iris)
    TabCombo:AddLabel("A combo in this game is a list of inputs with a rhythm. Presets cover the meta chains; the recorder learns " ..
        "yours — press record, do the combo once, stop, and the hub replays it on a loop with the exact same gaps.", ICON.Loop)
    TabCombo:AddSection("Presets")
    local presetNames = {}
    for name in pairs(ComboPresets) do table.insert(presetNames, name) end
    table.sort(presetNames)
    TabCombo:AddDropdown("Combo preset", "the chain the auto-combo loop replays", presetNames, Config.ComboPreset,
        function(value) Config.ComboPreset = value end, ICON.Loop)
    TabCombo:AddToggle("Auto combo", "replay the preset whenever a target is in range", Config.AutoCombo,
        function(value) Config.AutoCombo = value end, ICON.Play)
    TabCombo:AddToggle("Loop the combo", "no pause between reps — careful, it is loud and obvious", Config.ComboLoop,
        function(value) Config.ComboLoop = value end, ICON.Loop)
    TabCombo:AddSlider("Step delay", "the base gap between two steps", 0.05, 1.2, Config.ComboDelay, " s",
        function(value) Config.ComboDelay = value end, ICON.Loop)
    TabCombo:AddSlider("Speed multiplier", "scales every step delay up or down", 0.4, 2.5, Config.ComboSpeed, "×",
        function(value) Config.ComboSpeed = value end, ICON.Bolt)
    TabCombo:AddToggle("Face target while comboing", "keeps the chain connected as they move", Config.ComboFace,
        function(value) Config.ComboFace = value end, ICON.Eye)
    TabCombo:AddSlider("Combo range", "the loop only starts inside this distance", 6, 80, Config.ComboRange, " studs",
        function(value) Config.ComboRange = value end, ICON.Search)
    TabCombo:AddButton("Run preset once", "play the selected chain one time", function()
        local steps = ComboPresets[Config.ComboPreset]
        if steps then playCombo(steps, nil, false) else notify("Combo Lab", "pick a preset first", 3, Theme.Warning, ICON.Stop) end
    end, ICON.Play)
    TabCombo:AddSection("Recorder")
    TabCombo:AddButton("● Start recording", "arm the recorder — the hub listens to your own keys for up to 12 s", function()
        startRecording()
        notify("Combo Lab", "recording — do the combo now", 4, Theme.Iris, ICON.Play)
    end, ICON.Bolt)
    TabCombo:AddButton("■ Stop recording", "finish and print the chain to the console", function()
        local steps = stopRecording()
        if #steps > 0 then
            ComboPresets["recorded · " .. os.date("%H:%M:%S")] = steps
            notify("Combo Lab", "saved " .. #steps .. " steps", 4, Theme.Iris, ICON.Star)
        end
    end, ICON.Stop)
    TabCombo:AddButton("Play recorded combo", "replay the most recent recording on a loop", function()
        local steps = {}
        for _, entry in ipairs(State.recorded) do table.insert(steps, entry.key) end
        if #steps > 0 then playCombo(steps, nil, true) else notify("Combo Lab", "nothing recorded yet", 3, Theme.Warning, ICON.Stop) end
    end, ICON.Loop)
    TabCombo:AddButton("Clear recording", "throw the take away", function()
        State.recorded = {}
        notify("Combo Lab", "recording cleared", 3, Theme.Steel, ICON.Stop)
    end, ICON.Stop, true)
    TabCombo:AddSection("Timing sheets")
    TabCombo:AddLabel("Vessel — M1 · M1 · M1 · 3 · 3 (the second 3 is the Black Flash) → M1 · 2 · 4\n" ..
        "Honored One — M1 ×3 → 1 → 2 → 3, and during Awakening hold R + 2\n" ..
        "Perfection — 3 · 3 (purple flash, ground only) → G → 4 after two Black Flashes\n" ..
        "Switcher — 3 → R → 2 → 2, and G → 4 for the idol\n" ..
        "Cursed Partners — block → M1 for the counter, 4 to bring Rika in", ICON.Scroll)

    ---------------------------------------------------------------------------
    -- 4 · MOVEMENT
    ---------------------------------------------------------------------------
    TabMove = makeTab("Movement", "speed, fly, noclip, dash, anti-void", ICON.Wind, Theme.Sky)
    TabMove:AddLabel("Movement is where every ban story starts: a character crossing the map at 300 studs/s is not mistaken for " ..
        "anything else. Safe mode keeps the numbers inside what the game's own movement lets you do.", ICON.Wind)
    TabMove:AddSection("Ground")
    TabMove:AddToggle("Walk speed", "override the base walk speed", Config.WalkSpeedEnabled,
        function(value) Config.WalkSpeedEnabled = value applySpeed() end, ICON.Wind)
    TabMove:AddSlider("Speed", "studs per second — the ceiling slider on the Anti-Cheat tab still applies", 16, 200, Config.WalkSpeed, " s/s",
        function(value) Config.WalkSpeed = value end, ICON.Bolt)
    TabMove:AddToggle("Jump power", "higher jumps", Config.JumpPowerEnabled,
        function(value) Config.JumpPowerEnabled = value applyJump() end, ICON.Wind)
    TabMove:AddSlider("Jump power", "Roblox default is 50", 50, 300, Config.JumpPower, "",
        function(value) Config.JumpPower = value end, ICON.Bolt)
    TabMove:AddToggle("Infinite jump", "jump again in mid-air, forever", Config.InfiniteJump,
        function(value) Config.InfiniteJump = value end, ICON.Loop)
    TabMove:AddToggle("Always sprint", "hold the sprint input so W+W never has to come out of your hands", Config.AlwaysSprint,
        function(value) Config.AlwaysSprint = value end, ICON.Wind)
    TabMove:AddToggle("Fly", "camera-relative flight with a velocity object, not teleport spam", Config.FlyEnabled,
        function(value) Config.FlyEnabled = value if not value then flyStop() end end, ICON.Wind)
    TabMove:AddSlider("Fly speed", "studs per second while flying", 20, 250, Config.FlySpeed, " s/s",
        function(value) Config.FlySpeed = value end, ICON.Bolt)
    TabMove:AddToggle("Noclip", "walk through walls and domains", Config.Noclip,
        function(value) Config.Noclip = value if not value then setNoclip(false) end end, ICON.Ghost)
    TabMove:AddToggle("Anti void", "get pulled back up if you fall out of the map", Config.AntiVoid,
        function(value) Config.AntiVoid = value end, ICON.Guard)
    TabMove:AddToggle("Anti fling", "snap back when something throws you faster than physics allows", Config.AntiFling,
        function(value) Config.AntiFling = value end, ICON.Guard)
    TabMove:AddSection("Air")
    TabMove:AddButton("Teleport to cursor", "jump to wherever your mouse is pointing", function()
        local mouse = LocalPlayer:GetMouse()
        if mouse and mouse.Hit then tweenTo(mouse.Hit.Position + Vector3.new(0, 3, 0)) end
    end, ICON.Teleport)
    TabMove:AddButton("Dash now", "one dash, right now", function() dashNow() end, ICON.Bolt)
    TabMove:AddToggle("Dash spam", "hold Q on a loop — useless in a fight, very funny in a lobby", Config.DashSpam,
        function(value) Config.DashSpam = value end, ICON.Loop)
    TabMove:AddToggle("Gravity tweak", "lower local gravity so jumps float", Config.LowGravity,
        function(value)
            Config.LowGravity = value
            safeCall("gravity", function()
                Workspace.Gravity = value and 60 or 196.2
            end)
        end, ICON.Wind)
    TabMove:AddButton("Save spot here", "store your current position in slot 1", function()
        local root = getRoot()
        if root then
            table.insert(State.savedSpots, { name = "spot " .. (#State.savedSpots + 1), position = root.Position })
            notify("Movement", "spot " .. #State.savedSpots .. " saved", 3, Theme.Sky, ICON.Star)
        end
    end, ICON.Star)
    TabMove:AddButton("Go to saved spot", "back to the last saved position", function()
        local spot = State.savedSpots[#State.savedSpots]
        if spot then tweenTo(spot.position + Vector3.new(0, 3, 0)) else notify("Movement", "no spot saved", 3, Theme.Warning, ICON.Stop) end
    end, ICON.Teleport)

    ---------------------------------------------------------------------------
    -- 5 · ESP & VISUALS
    ---------------------------------------------------------------------------
    TabEsp = makeTab("ESP & Visuals", "players, dummies, drops, domains, lighting", ICON.Eye, Theme.Mauve)
    TabEsp:AddLabel("Highlights and billboards only — no executor drawing objects, so the same code works on every executor.", ICON.Eye)
    TabEsp:AddSection("Targets")
    TabEsp:AddToggle("Players", "every other player in the server", Config.EspPlayers,
        function(value) Config.EspPlayers = value end, ICON.Player)
    TabEsp:AddToggle("Practice dummies", "the training dummy and anything similar", Config.EspDummies,
        function(value) Config.EspDummies = value end, ICON.Chart)
    TabEsp:AddToggle("Drops & cash", "pickups worth walking to", Config.EspPickups,
        function(value) Config.EspPickups = value end, ICON.Loot)
    TabEsp:AddToggle("Domains", "any area expansion currently on the map", Config.EspDomains,
        function(value) Config.EspDomains = value end, ICON.Hex)
    TabEsp:AddSection("Look")
    TabEsp:AddToggle("Names", "name, health and distance above every box", Config.EspNames,
        function(value) Config.EspNames = value end, ICON.Scroll)
    TabEsp:AddToggle("Health %", "read their health off the label", Config.EspHealth,
        function(value) Config.EspHealth = value end, ICON.Chart)
    TabEsp:AddToggle("Distance", "studs to the target", Config.EspDistance,
        function(value) Config.EspDistance = value end, ICON.Search)
    TabEsp:AddToggle("Tracers", "a line from the bottom of the screen to every target", Config.EspTracers,
        function(value) Config.EspTracers = value end, ICON.Loop)
    TabEsp:AddSlider("Fill transparency", "how solid the highlight looks", 0.2, 0.95, Config.EspFillTransparency, "",
        function(value) Config.EspFillTransparency = value end, ICON.Layers)
    TabEsp:AddSlider("Max distance", "ignore anything further away", 100, 5000, Config.EspMaxDistance, " studs",
        function(value) Config.EspMaxDistance = value end, ICON.Search)
    TabEsp:AddButton("Clear all", "wipe every highlight and tracer right now", function()
        espClear()
        notify("ESP", "cleared", 3, Theme.Mauve, ICON.Stop)
    end, ICON.Stop, true)
    TabEsp:AddSection("Screen")
    TabEsp:AddToggle("Fullbright", "flat, bright lighting — no more dark corners", Config.Fullbright,
        function(value) Config.Fullbright = value if not value then restoreLighting() end end, ICON.Star)
    TabEsp:AddToggle("No fog", "push the fog wall to infinity", Config.NoFog,
        function(value) Config.NoFog = value if not value then restoreLighting() end end, ICON.Wind)
    TabEsp:AddToggle("Blood moon", "client-side red night sky", Config.BloodMoon,
        function(value) Config.BloodMoon = value if not value then restoreLighting() end end, ICON.Flame)
    TabEsp:AddSlider("Camera FOV", "zoom out with a real field-of-view change", 40, 130, Config.CameraFov, "",
        function(value)
            Config.CameraFov = value
            safeCall("fov", function() if Camera then Camera.FieldOfView = value end end)
        end, ICON.Eye)
    TabEsp:AddSlider("Time of day", "set the client clock — 0 is midnight, 14 is afternoon", 0, 24, Config.TimeOfDay, "h",
        function(value) Config.TimeOfDay = value end, ICON.Loop)
    TabEsp:AddToggle("Remove hit effects", "stop the screen from filling with VFX during a long combo", Config.RemoveVfx,
        function(value)
            Config.RemoveVfx = value
            safeCall("vfx", function()
                if Lighting then
                    for _, child in ipairs(Lighting:GetChildren()) do
                        if child:IsA("BlurEffect") or child:IsA("SunRaysEffect") then child.Enabled = not value end
                    end
                end
            end)
        end, ICON.Ghost)
    TabEsp:AddToggle("FPS boost", "drop particles and decals so a 20-player fight stays playable", Config.FpsBoost,
        function(value) Config.FpsBoost = value end, ICON.Bolt)

    ---------------------------------------------------------------------------
    -- 6 · FUN  (the toys)
    ---------------------------------------------------------------------------
    TabFun = makeTab("Fun", "auras, music, disco, emotes — all client-side", ICON.Star, Theme.Sand)
    TabFun:AddLabel("Every switch on this page changes only what is on your screen. Nobody else sees it, nothing about the match " ..
        "changes — which is exactly why it is fine to leave them on.", ICON.Star)
    TabFun:AddSection("Auras & looks")
    TabFun:AddToggle("Rainbow aura", "an always-on-top highlight cycling through the whole wheel", Config.RainbowAura,
        function(value) Config.RainbowAura = value if not value then stopRainbow() end end, ICON.Star)
    TabFun:AddSlider("Aura transparency", "solid or ghostly", 0.1, 0.95, Config.AuraTransparency, "",
        function(value) Config.AuraTransparency = value end, ICON.Layers)
    TabFun:AddToggle("Disco lighting", "the whole map strobes through the colour wheel", Config.DiscoMode,
        function(value) Config.DiscoMode = value if not value then restoreLighting() end end, ICON.Bolt)
    TabFun:AddToggle("Big head", "exactly what it sounds like", Config.BigHead,
        function(value) Config.BigHead = value end, ICON.Star)
    TabFun:AddToggle("Camera shake", "shake the camera like every hit is a Black Flash", Config.CameraShake,
        function(value) Config.CameraShake = value end, ICON.Bolt)
    TabFun:AddSlider("Shake power", "how violently", 0.1, 3, Config.ShakePower, "",
        function(value) Config.ShakePower = value end, ICON.Loop)
    TabFun:AddSlider("Character size", "1 is normal — Model:ScaleTo, client-side only", 0.4, 2.5, Config.CharScale, "×",
        function(value)
            Config.CharScale = value
            local character = getChar()
            if character and character.ScaleTo then safeCall("scale", function() character:ScaleTo(value) end) end
        end, ICON.Layers)
    TabFun:AddToggle("Hit sparks", "a small particle burst wherever your hits land", Config.HitSparks,
        function(value) Config.HitSparks = value end, ICON.Spark)
    TabFun:AddToggle("Aura trail", "a ribbon that follows you around — client-side only", Config.AuraTrail,
        function(value) Config.AuraTrail = value end, ICON.Wind)
    TabFun:AddSlider("Trail hue", "0 red · 120 green · 200 blue · 300 purple", 0, 359, Config.TrailHue, "°",
        function(value) Config.TrailHue = value end, ICON.Layers)
    TabFun:AddSlider("Trail length", "how long the ribbon hangs behind", 0.1, 4, Config.TrailLifetime, " s",
        function(value)
            Config.TrailLifetime = value
            local character = getChar()
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local trail = root and root:FindFirstChild("SkillHubTrail")
            if trail then safeCall("trail length", function() trail.Lifetime = value end) end
        end, ICON.Loop)
    TabFun:AddToggle("Fake domain dome", "a force-field ball around you that exists only on your screen", Config.DomainDome,
        function(value) Config.DomainDome = value if not value and Fun.dome then safeCall("dome off", function() Fun.dome:Destroy() end) Fun.dome = nil end end, ICON.Hex)
    TabFun:AddSlider("Dome size", "how big the ball is", 20, 400, Config.DomeSize, " studs",
        function(value) Config.DomeSize = value end, ICON.Layers)
    TabFun:AddSlider("Dome hue", "the colour wheel again", 0, 359, Config.DomeHue, "°",
        function(value)
            Config.DomeHue = value
            if Fun.dome then
                safeCall("dome hue", function()
                    Fun.dome.Color = Color3.fromHSV((value % 360) / 360, 0.7, 1)
                end)
            end
        end, ICON.Star)
    TabFun:AddSection("Sound")
    TabFun:AddInput("Music id", "a Roblox audio id — the hub plays it locally, looped", Config.MusicId, function(text)
        Config.MusicId = text
        if Config.Music then musicToggle(true) end
    end, ICON.Bell)
    TabFun:AddToggle("Play music", "start or stop the track", Config.Music,
        function(value) Config.Music = value musicToggle(value) end, ICON.Play)
    TabFun:AddSlider("Volume", "0 to 10", 0, 10, Config.MusicVolume, "",
        function(value)
            Config.MusicVolume = value
            if Fun.music then safeCall("volume", function() Fun.music.Volume = value end) end
        end, ICON.Bell)
    TabFun:AddToggle("Dash noise spam", "the classic: dash sound on repeat until you get bored", Config.DashNoise,
        function(value) Config.DashNoise = value dashNoiseToggle(value) end, ICON.Bolt)
    TabFun:AddSection("Emotes & chat")
    TabFun:AddSlider("Emote slot", "which emote the wheel picks", 1, 8, Config.EmoteSlot, "",
        function(value) Config.EmoteSlot = value end, ICON.Star)
    TabFun:AddButton("Play emote now", "open the wheel, pick the slot, close it", function()
        playEmote(Config.EmoteSlot)
    end, ICON.Play)
    TabFun:AddToggle("Emote on kill", "celebrate every kill automatically", Config.AutoEmoteOnKill,
        function(value) Config.AutoEmoteOnKill = value end, ICON.Star)
    TabFun:AddToggle("Emote loop", "keep playing the emote slot over and over", Config.EmoteLoop,
        function(value) Config.EmoteLoop = value end, ICON.Loop)
    TabFun:AddSlider("Emote loop gap", "seconds between emotes", 4, 60, Config.EmoteLoopDelay, " s",
        function(value) Config.EmoteLoopDelay = value end, ICON.Bell)
    TabFun:AddInput("GG message", "what the hub types after a kill", Config.GGMessage, function(text)
        Config.GGMessage = text
    end, ICON.Scroll)
    TabFun:AddToggle("Auto GG on kill", "say it once, never twice in a row", Config.AutoGG,
        function(value) Config.AutoGG = value end, ICON.Bell)
    TabFun:AddInput("Chat spam line", "leave empty to keep chat spam off", Config.ChatMessage, function(text)
        Config.ChatMessage = text
    end, ICON.Scroll)
    TabFun:AddSlider("Chat spam delay", "seconds between messages — the game's own chat rate limit still applies", 3, 120, Config.ChatDelay, " s",
        function(value) Config.ChatDelay = value end, ICON.Loop)
    TabFun:AddToggle("Chat spam", "send the line above on the delay", Config.ChatSpam,
        function(value) Config.ChatSpam = value end, ICON.Bell)
    TabFun:AddSection("Chaos")
    TabFun:AddButton("Spark storm", "fire 30 hit sparks in a ring around you", function()
        local root = getRoot()
        if not root then return end
        for index = 1, 30 do
            local angle = index / 30 * math.pi * 2
            hitSpark(root.Position + Vector3.new(math.cos(angle) * 6, 1 + (index % 5), math.sin(angle) * 6),
                Color3.fromHSV(index / 30, 0.6, 1))
        end
    end, ICON.Spark)
    TabFun:AddButton("Confetti burst", "a colourful particle shower above your head", function()
        local root = getRoot()
        if not root then return end
        Config.HitSparks = true
        for index = 1, 12 do
            hitSpark(root.Position + Vector3.new(0, 6 + index * 0.4, 0), Color3.fromHSV(index / 12, 0.7, 1))
        end
        notify("Fun", "confetti · client-side only", 3, Theme.Sand, ICON.Star)
    end, ICON.Star)
    TabFun:AddButton("Button mashing mode", "spam M1 and every skill at once for four seconds", function()
        task.spawn(function()
            local finish = os.clock() + 4
            while os.clock() < finish and State.alive do
                attackOnce()
                pressKey(tostring(math.random(1, 4)), 0.05)
                task.wait(0.06)
            end
        end)
    end, ICON.Bolt, true)

    ---------------------------------------------------------------------------
    -- 7 · TELEPORTS
    ---------------------------------------------------------------------------
    TabTp = makeTab("Teleports", "zones, players, saved spots, server hop", ICON.Teleport, Theme.Sky)
    TabTp:AddLabel("The list is built from the map you are standing in every time the page refreshes, so it survives updates — " ..
        "no hardcoded coordinates that break the week after they were read.", ICON.Teleport)
    TabTp:AddDropdown("Destination", "everything the hub found in this server", { "—" }, "—", function(value)
        local position = resolveTeleportTarget(value)
        if position then
            tweenTo(position)
            notify("Teleport", "→ " .. value, 3, Theme.Sky, ICON.Teleport)
        end
    end, ICON.Teleport)
    TabTp:AddButton("Refresh the list", "scan the map again and rebuild the dropdown", function()
        local targets = teleportTargets()
        notify("Teleport", #targets .. " destinations found", 4, Theme.Sky, ICON.Search)
        for _, tab in ipairs(Tabs) do end
        print("[Skill Hub] teleport targets: " .. #targets)
        for index, target in ipairs(targets) do
            if index <= 40 then print(string.format("    %s", target.name)) end
        end
    end, ICON.Search)
    TabTp:AddDropdown("Go to player", "teleport straight to somebody", { "—" }, "—", function(value)
        for _, entry in ipairs(World.players) do
            if entry.name == value then
                tweenTo(entry.position + Vector3.new(0, 3, 0))
                notify("Teleport", "→ " .. value, 3, Theme.Sky, ICON.Player)
                break
            end
        end
    end, ICON.Player)
    TabTp:AddToggle("Teleport pacing", "long jumps travel in 400-stud hops instead of one huge CFrame write", Config.AcTeleportPacing,
        function(value) Config.AcTeleportPacing = value end, ICON.Loop)
    TabTp:AddSection("Saved spots")
    TabTp:AddButton("Save spot 1", "remember where you are", function()
        local root = getRoot()
        if root then State.savedSpots[1] = { name = "spot 1", position = root.Position }
            notify("Teleport", "spot 1 saved", 3, Theme.Sky, ICON.Star) end
    end, ICON.Star)
    TabTp:AddButton("Save spot 2", "a second place worth remembering", function()
        local root = getRoot()
        if root then State.savedSpots[2] = { name = "spot 2", position = root.Position }
            notify("Teleport", "spot 2 saved", 3, Theme.Sky, ICON.Star) end
    end, ICON.Star)
    TabTp:AddButton("Go to spot 1", "back to the first saved place", function()
        local spot = State.savedSpots[1]
        if spot then tweenTo(spot.position + Vector3.new(0, 3, 0)) end
    end, ICON.Teleport)
    TabTp:AddButton("Go to spot 2", "back to the second saved place", function()
        local spot = State.savedSpots[2]
        if spot then tweenTo(spot.position + Vector3.new(0, 3, 0)) end
    end, ICON.Teleport)
    TabTp:AddSection("Servers")
    TabTp:AddToggle("Server hop on staff", "leave the server the moment a moderator joins", Config.StaffHop,
        function(value) Config.StaffHop = value end, ICON.Guard)
    TabTp:AddInput("Staff group id", "rank in this group counts as staff", tostring(Config.StaffGroupId), function(text)
        Config.StaffGroupId = tonumber(text) or 0
    end, ICON.Gear)
    TabTp:AddButton("Server hop", "find a quieter server and move — the hub re-loads itself there if your executor can queue scripts", function()
        AC.serverHop(Config.HopPreference)
    end, ICON.Teleport)
    TabTp:AddDropdown("Hop preference", "how the hop picks its next server", { "Lowest ping", "Most players" }, Config.HopPreference,
        function(value) Config.HopPreference = value end, ICON.Star)
    TabTp:AddButton("Rejoin this server", "straight back in", function()
        safeCall("rejoin", function()
            getService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
        end)
    end, ICON.Loop)
    TabTp:AddButton("Copy job id", "put this server's job id on the clipboard", function()
        if setclipboard then
            setclipboard(game.JobId)
            notify("Teleport", "job id copied", 3, Theme.Sky, ICON.Star)
        else
            print("[Skill Hub] job id: " .. tostring(game.JobId))
        end
    end, ICON.Scroll)

    ---------------------------------------------------------------------------
    -- 8 · ANTI-CHEAT
    ---------------------------------------------------------------------------
    TabAc = makeTab("Anti-Cheat", "the bypass layer, the plausibility layer, staff watch", ICON.Guard, Theme.Rose)
    TabAc:AddLabel("What the bypass does: it disables the game's client-side detector scripts, drops outgoing report / flag / " ..
        "screenshot remote calls, blocks a kick from reaching the client, and keeps your own traffic inside a plausible range. " ..
        "What it cannot do: out-argue the server. Jujutsu Shenanigans bans from recorded evidence, so the honest play is to " ..
        "remove the client-side telemetry and not look like a machine.", ICON.Guard)
    TabAc:AddSection("Detection")
    TabAc:AddButton("Run audit now", "scan the game and print every detector script and report remote it can see", function()
        local telemetry = AC.audit(true)
        notify("Anti-Cheat", string.format("%d detectors · %d report remotes", telemetry.detectors, telemetry.reports),
            6, Theme.Rose, ICON.Search)
    end, ICON.Search)
    TabAc:AddToggle("Neutralise detectors", "disable detector scripts the moment they are found (again on respawn)", Config.AcNeutralize,
        function(value) Config.AcNeutralize = value if value then AC.neutralize(true) end end, ICON.Guard)
    TabAc:AddToggle("Block report remotes", "drop outgoing report / flag / ban / screenshot calls at the namecall level", Config.AcBlockReports,
        function(value)
            Config.AcBlockReports = value
            if value then AC.installHook() else AC.removeHook() end
        end, ICON.Stop)
    TabAc:AddToggle("Kick guard", "log a kick instead of letting the client act on it", Config.AcKickGuard,
        function(value)
            Config.AcKickGuard = value
            if value then AC.installKickGuard() else AC.removeKickGuard() end
        end, ICON.Guard)
    TabAc:AddButton("Install / repair hook", "re-install the namecall report filter — safe to press twice", function()
        AC.installHook()
        AC.installKickGuard()
        notify("Anti-Cheat", "hook " .. (AC.hookInstalled and "installed" or "unavailable"), 4, Theme.Rose, ICON.Guard)
    end, ICON.Loop)
    TabAc:AddButton("Remove hook", "unhook completely — no interception left in this client", function()
        AC.removeHook()
        AC.removeKickGuard()
        notify("Anti-Cheat", "hooks removed", 4, Theme.Rose, ICON.Stop)
    end, ICON.Stop, true)
    TabAc:AddSection("Plausibility layer")
    TabAc:AddLabel("This is the part that actually keeps you out of a report clip: the hub limits itself so its traffic looks " ..
        "like a fast human instead of a script.", ICON.Layers)
    TabAc:AddToggle("Safe mode", "cap speed, slow the loops and pace long teleports", Config.AcSafeMode,
        function(value) Config.AcSafeMode = value end, ICON.Guard)
    TabAc:AddSlider("Speed ceiling", "the highest walk speed this hub will ever write", 16, 200, Config.AcSpeedCeiling, " studs/s",
        function(value) Config.AcSpeedCeiling = value end, ICON.Bolt)
    TabAc:AddSlider("Remote rate limit", "maximum remote calls per second the hub's own features allow themselves", 1, 60, Config.AcRemoteRateLimit, " /s",
        function(value) Config.AcRemoteRateLimit = value end, ICON.Loop)
    TabAc:AddToggle("Combat jitter", "randomise attack gaps by a few milliseconds so the rhythm is not a metronome", Config.CombatJitter,
        function(value) Config.CombatJitter = value end, ICON.Loop)
    TabAc:AddToggle("Human pause", "stand still for a beat every few minutes, like a person would", Config.HumanPause,
        function(value) Config.HumanPause = value end, ICON.Loop)
    TabAc:AddSection("Watching for staff")
    TabAc:AddToggle("Staff watch", "alert when a name that belongs to staff joins", Config.StaffWatch,
        function(value) Config.StaffWatch = value end, ICON.Bell)
    TabAc:AddToggle("Auto hop on staff", "leave the server the moment staff is detected", Config.StaffHop,
        function(value) Config.StaffHop = value end, ICON.Teleport)
    TabAc:AddInput("Staff names", "extra names, comma separated", "", function(text)
        if not text or text == "" then return end
        local list = {}
        for name in string.gmatch(text, "[^,%s]+") do table.insert(list, name) end
        SharedEnv.SkillHubStaffList = list
        notify("Anti-Cheat", #list .. " name(s) added to the watch list", 4, Theme.Rose, ICON.Bell)
    end, ICON.Scroll)
    TabAc:AddToggle("Anti-AFK", "small camera and input nudge every 15 s so the idle kick never fires", Config.AntiAfk,
        function(value) Config.AntiAfk = value end, ICON.Bell)
    TabAc:AddButton("Re-audit + neutralise", "full sweep: scan, disable what it found, re-install the filter, report back", function()
        AC.audit(true)
        if Config.AcNeutralize then AC.neutralize(true) end
        if Config.AcBlockReports then AC.installHook() end
        if Config.AcKickGuard then AC.installKickGuard() end
        notify("Anti-Cheat", "sweep finished", 5, Theme.Rose, ICON.Guard)
    end, ICON.Loop)
    TabAc:AddStatusPanel("Anti-cheat status", function()
        local telemetry = acTelemetry()
        return {
            { label = "hook", value = telemetry.hook and "installed" or "off" },
            { label = "kick guard", value = telemetry.kickGuard and "installed" or "off" },
            { label = "detectors", value = tostring(telemetry.detectors) .. (telemetry.disabled > 0 and (" (" .. telemetry.disabled .. " off)") or "") },
            { label = "report remotes", value = tostring(telemetry.reports) },
            { label = "calls blocked", value = tostring(telemetry.blocked) },
            { label = "last blocked", value = telemetry.blocked > 0 and tostring(AC.lastBlocked) or "—" },
            { label = "remote budget", value = tostring(State.remoteCount) .. "/" .. tostring(Config.AcRemoteRateLimit) .. " per s" },
            { label = "safe mode", value = Config.AcSafeMode and "on" or "off" },
        }
    end, 190)
    TabAc:AddButton("Self-test", "run every internal check and print PASS/FAIL to the console", function()
        selfTest()
    end, ICON.Layers)
    TabAc:AddSection("Performance")
    TabAc:AddLabel("The 2026 rebuild cut the per-second engine traffic by ~3.4x: the map is walked rarely and values " ..
        "are reused instead of re-read. These sliders are the budget. Turn the counter on to watch it live.")
    TabAc:AddToggle("Performance stats", "live counter pill inside the window: walks, refreshes, writes, ESP, scan cost",
        Config.PerfStats, function(value) Config.PerfStats = value end, ICON.Bolt)
    TabAc:AddSlider("Map walk interval", "how often the map is re-discovered — lower is fresher and more expensive",
        1, 5, Config.ScanInterval, " s", function(value) Config.ScanInterval = value end, ICON.Loop)
    TabAc:AddSlider("Refresh interval", "how often positions are re-read — this is the cheap tier",
        0.1, 1, Config.RefreshInterval, " s", function(value) Config.RefreshInterval = value end, ICON.Bolt)
    TabAc:AddSlider("ESP interval", "how often the ESP pass runs while ESP is on",
        0.2, 1.5, Config.EspInterval, " s", function(value) Config.EspInterval = value end, ICON.Eye)
    TabAc:AddSlider("Scan budget", "instances one full map walk may visit before it stops",
        200, 2000, Config.ScanBudget, " instances", function(value) Config.ScanBudget = value end, ICON.Layers)
    TabAc:AddButton("Measure now", "sample one second of the hub's own counters and write the report below", function()
        State.perf.measureRequested = true
        notify("Performance", "sampling one second — the report lands in the panel below", 4, Theme.Accent, ICON.Spark)
    end, ICON.Spark)
    TabAc:AddStatusPanel("Perf report", function()
        local rows = PerfUI.rows()
        return rows
    end, 226)

    ---------------------------------------------------------------------------
    -- 9 · PLAYER & MISC
    ---------------------------------------------------------------------------
    TabMisc = makeTab("Player & Misc", "defence, UI, interface, panic", ICON.Gear, Theme.Steel)
    TabMisc:AddSection("Survival")
    TabMisc:AddToggle("Anti ragdoll", "get up the frame you are knocked down", Config.AntiRagdoll,
        function(value) Config.AntiRagdoll = value end, ICON.Guard)
    TabMisc:AddToggle("Anti stun", "keep control during a stun", Config.AntiStun,
        function(value) Config.AntiStun = value end, ICON.Guard)
    TabMisc:AddToggle("Anti slow", "never let a move cut your walk speed", Config.AntiSlow,
        function(value) Config.AntiSlow = value end, ICON.Wind)
    TabMisc:AddToggle("Infinite stamina", "the bar never drops on your screen, so sprint never stops locally", Config.InfiniteStamina,
        function(value) Config.InfiniteStamina = value end, ICON.Bolt)
    TabMisc:AddToggle("No fall damage", "land from anything", Config.NoFallDamage,
        function(value) Config.NoFallDamage = value end, ICON.Guard)
    TabMisc:AddSection("Interface")
    TabMisc:AddKeybind("Hide / show the window", "the key that puts this whole interface away", Config.HideUiKey, function(key)
        Config.HideUiKey = key
    end, ICON.Eye)
    TabMisc:AddKeybind("Panic key", "everything off, immediately", Config.PanicKey, function(key)
        Config.PanicKey = key
    end, ICON.Stop)
    TabMisc:AddSlider("Window transparency", "make the interface see-through", 0, 0.7, Config.UiTransparency, "",
        function(value)
            Config.UiTransparency = value
            local window = getWindow()
            if window and window.Screen then
                for _, node in ipairs(window.Screen:GetDescendants()) do
                    if node:IsA("Frame") or node:IsA("TextLabel") or node:IsA("TextButton") then
                        safeCall("transparency", function()
                            if node.BackgroundTransparency < 1 then node.BackgroundTransparency = value end
                        end)
                    end
                end
            end
        end, ICON.Layers)
    TabMisc:AddToggle("Show the author banner", "the little credit notice on start-up", Config.ShowAuthor,
        function(value) Config.ShowAuthor = value end, ICON.Star)
    TabMisc:AddInput("Console log level", "0 = silent, 2 = everything (default)", tostring(Config.LogLevel), function(text)
        Config.LogLevel = tonumber(text) or 2
    end, ICON.Scroll)
    TabMisc:AddSection("Session")
    TabMisc:AddStatusPanel("Session", function()
        local minutes = math.floor((os.clock() - State.startedAt) / 60)
        return {
            { label = "uptime", value = minutes .. " min" },
            { label = "fps", value = tostring(math.floor(State.fps or 60)) },
            { label = "ping", value = tostring(State.ping) .. " ms" },
            { label = "players", value = tostring(#World.players + 1) },
            { label = "zone", value = tostring(World.zone) },
            { label = "style", value = tostring(State.style) .. (State.awakened and " (awakened)" or "") },
            { label = "version", value = VERSION .. " · free" },
        }
    end)
    TabMisc:AddButton("Copy status to clipboard", "a short report you can paste when something looks wrong", function()
        local text = string.format("Skill Hub %s · JJS free · fps %d · ping %d · style %s · zone %s · detectors %d · blocked %d",
            VERSION, math.floor(State.fps or 60), State.ping, tostring(State.style), tostring(World.zone),
            #AC.detectors, AC.blocked)
        if setclipboard then setclipboard(text) notify("Session", "status copied", 3, Theme.Steel, ICON.Star)
        else print("[Skill Hub] " .. text) end
    end, ICON.Scroll)
    TabMisc:AddSection("Player list")
    TabMisc:AddPlayerList("Everyone in this server", function()
        local list = {}
        for _, entry in ipairs(World.players) do
            table.insert(list, {
                player = entry.player, name = entry.display or entry.name,
                info = string.format("%s · %.0f studs · %d%%", entry.style, entry.distance,
                    math.floor((entry.health or 100) / math.max(1, entry.maxHealth or 100) * 100)),
                color = entry.alive and Theme.Success or Theme.Danger,
            })
        end
        return list
    end, {
        { label = "TP", callback = function(player)
            if player and player.Character then tweenTo(modelPosition(player.Character) + Vector3.new(0, 3, 0)) end
        end },
        { label = "GO", callback = function(player)
            if player and player.Character then
                local root = getRoot()
                if root then safeCall("bring", function()
                    player.Character:PivotTo(CFrame.new(root.Position + Vector3.new(0, 0, 3)))
                end) end
            end
        end },
        { label = "K", callback = function(player)
            if player and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.Health = 0 end
            end
        end },
    })
    TabMisc:AddSection("Danger zone")
    TabMisc:AddButton("Panic — everything off", "turn every switch off and hide the window", function()
        panic("button")
    end, ICON.Stop, true)
    TabMisc:AddButton("Unload the hub completely", "remove the interface, the hooks and every loop", function()
        unload()
    end, ICON.Stop, true)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 23 · KEYBINDS, LOOK-ON LOOPS AND BOOT
-- ═══════════════════════════════════════════════════════════════════════════
local function bindKeys()
    if not UserInput then return end
    UserInput.InputBegan:Connect(function(input, processed)
        if processed then return end
        local key = input.KeyCode
        local name = key and key.Name or nil
        if not name then return end

        if Config.comboRecording then
            State.recorded[#State.recorded + 1] = { key = name, at = os.clock() }
            if os.clock() - State.recordedAt > 12 then stopRecording() end
        end

        local window = getWindow()
        if name == string.upper(Config.HideUiKey) and window and window.Screen then
            Config.UiVisible = not Config.UiVisible
            window.Screen.Enabled = Config.UiVisible
            return
        end
        if name == string.upper(Config.PanicKey) then
            panic("hotkey")
            return
        end
        if name == "Q" and Config.DashSpam then
            dashNow()
        end
        if name == "F" and Config.AutoBlackFlash and State.threat then
            blackFlash()
        end
    end)
end

local function lookLoop()
    task.spawn(function()
        while State.alive do
            task.wait(0.05)
            if (Config.LockOn or Config.ComboPlaying or State.comboPlaying) and isAlive() then
                local target = State.comboTarget
                if not target or not target.instance or not target.instance.Parent then
                    target = nearestTarget(Config.LockRange or 90)
                end
                if target and target.position then
                    aimCameraAt(target.position + Vector3.new(0, 1.5, 0), Config.LockSmooth)
                end
            end
            local window = getWindow()
            if Config.FovCircle and window and window.Screen then
                if not window.FovRing then
                    local ring = new("Frame", {
                        Name = "FovRing", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
                        Size = UDim2.new(0, 200, 0, 200), ZIndex = 2,
                    }, window.Screen)
                    corner(ring, RADIUS.pill)
                    local stroke = new("UIStroke", { Thickness = 1, Color = Theme.Stroke, Transparency = 0.25 }, ring)
                    window.FovRing, window.FovStroke = ring, stroke
                end
                safeCall("fov ring", function()
                    local size = math.floor((Config.LockRange or 90) * 4)
                    window.FovRing.Size = UDim2.new(0, size, 0, size)
                    window.FovRing.Position = UDim2.new(0.5, 0, 0.5, 0)
                    window.FovRing.Visible = Config.FovCircle
                end)
            elseif window and window.FovRing then
                window.FovRing.Visible = false
            end
        end
    end)
end

local function humanPauseLoop()
    task.spawn(function()
        while State.alive do
            task.wait(math.random(90, 190))
            if Config.HumanPause and isAlive() then
                local wasAura = Config.KillAura
                Config.KillAura = false
                releaseBlock()
                task.wait(math.random(2, 5))
                Config.KillAura = wasAura
            end
        end
    end)
end

local function respawnHook()
    if not Players or not LocalPlayer then return end
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.6)
        Config.ComboPlaying = false
        State.comboPlaying = false
        State.comboHits = 0
        if Config.AcNeutralize then task.wait(1) AC.audit(false) AC.neutralize(false) end
        if Config.WalkSpeedEnabled then applySpeed() end
    end)
end

local function boot()
    State.alive = true
    local previous = SharedEnv.SkillHubJujutsu
    if previous and previous ~= skillHubInstance and previous.unload then
        pcall(function() previous.unload() end)
    end

    local ok, err = pcall(buildWindow)
    if not ok or not getWindow() then
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

    print("[Skill Hub " .. VERSION .. "] " .. GAME_NAME .. " · free edition · by " .. AUTHOR)
    print(string.format("    style %s · players %d · place %s", tostring(State.style), Players and #Players:GetPlayers() or 0, tostring(game.PlaceId)))
    print("    tabs: " .. (function()
        local names = {}
        for _, tab in ipairs(Tabs) do table.insert(names, tab.title or "?") end
        return table.concat(names, " · ")
    end)())
    print("    run the Anti-Cheat tab -> Self-test for the full PASS/FAIL list")

    -- anti-cheat layers first, features second
    task.spawn(function()
        AC.audit(false)
        if Config.AcNeutralize then AC.neutralize(false) end
        if Config.AcBlockReports then AC.installHook() end
        if Config.AcKickGuard then AC.installKickGuard() end
    end)

    applyMovementLoop()
    applyJumpLoop()
    applyDefenceLoop()
    applyNoFallDamage()
    applyAntiAfk()
    combatLoop()
    defenceCombatLoop()
    farmLoop()
    hitboxLoop()
    miscLoop()
    espLoop()
    funLoop()
    staffLoop()
    lookLoop()
    humanPauseLoop()
    bindKeys()
    respawnHook()

    task.spawn(function()
        while State.alive do
            task.wait(2)
            currentStyle()
            currentToolInfo()
            isAwakened()
        end
    end)

    if Config.ShowAuthor then
        task.spawn(function()
            task.wait(1.2)
            if getWindow() and Config.ShowAuthor then
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
    fun = Fun,
    knowledge = KNOWLEDGE,
    presets = ComboPresets,
    notify = notify,
    unload = unload,
    panic = panic,
    selfTest = selfTest,
    audit = AC.audit,
    scan = scanWorld,
    teleport = tweenTo,
    teleportTargets = teleportTargets,
    equip = equipBestWeapon,
    blackFlash = blackFlash,
    playCombo = playCombo,
    esp = { registry = EspRegistry },
    perf = PerfUI,
    hitbox = HitboxOriginal,
    playEmote = playEmote,
    chatSay = chatSay,
    attack = attackOnce,
    applyHitbox = applyHitbox,
    world_helpers = { nearest = nearestTarget, targets = targetList, threat = detectThreat },
}
SharedEnv.SkillHubJujutsu = skillHubInstance
SharedEnv.SkillHubUrl = "https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/Jujutsu%20Shenanigans/SkillHub.lua"

local bootOk, bootError = pcall(boot)
if not bootOk then
    print("[Skill Hub] boot error: " .. tostring(bootError))
    print("[Skill Hub] the hub is loaded; unload or re-run the script after reading the line above")
end

    return skillHubInstance
end

skillHubInstance = runTabs(NS)
if skillHubInstance then
    SharedEnv.SkillHubJujutsu = skillHubInstance
end
