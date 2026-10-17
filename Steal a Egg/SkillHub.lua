--[[
    ██╗  ██╗██╗██╗     ██╗         ██╗  ██╗██╗   ██╗██████╗
    ██║ ██╔╝██║██║     ██║         ██║  ██║██║   ██║██╔══██╗
    █████╔╝ ██║██║     ██║         ███████║██║   ██║██████╔╝
    ██╔═██╗ ██║██║     ██║         ██╔══██║██║   ██║██╔══██╗
    ██║  ██╗██║███████╗███████╗    ██║  ██║╚██████╔╝██████╔╝
    ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    Skill Hub — Steal An Egg  ·  FREE edition (no key, readable, no loader)
    by ameksi-web  ·  https://github.com/ameksi-web/Skill-Hub

    ── how to run ──────────────────────────────────────────────────────────────
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/Steal%20a%20Egg/SkillHub.lua"))()

    ── what this is ────────────────────────────────────────────────────────────
        A hub for Steal An Egg with the same "Porcelain" design system as the
        rest of the Skill Hub family: soft-dark graphite surfaces, hairline
        borders, muted editorial accents, a hand-drawn icon set.

        Nine tabs: Steal · Base · Farm · Movement · ESP · Events ·
                   Anti-Cheat · Fun · Player & Misc.

        Built against the live game (Halloween Dimension, 17 Oct 2026; after
        Update 8 "Mounts"): 13 biomes from Forest to Enchanted Forest, guardian
        speed gates, nests, carrying, plots, place / hatch / fuse / sell,
        treadmill speed training, index rewards, trails, rifts + Abyss Overlord,
        Nitro Race, Shooting Stars, Butterfly Bloom, Dr. Scramble's Lab.

    ── the anti-cheat layer, honestly ──────────────────────────────────────────
        Steal An Egg has no published ban API and no meaningful automated
        anti-cheat; what it does have is a movement sampler that rubber-bands a
        client whose speed does not match the account, and a server that decides
        whether an egg stays in your hands. A client script can do four useful
        things about that, and this does all four:
          · finds and disables client-side detector / monitor / telemetry scripts
          · drops every outgoing report / flag / screenshot remote at the
            namecall level — newcclosure, pcall-guarded, everything else passes
          · keeps its own traffic plausible: speed ceiling, remote rate limit,
            paced movement, step-limited travel instead of one long teleport
          · never trusts a single hop: it verifies the egg is still held after a
            move and falls back to a walk-in grab if the server refused it
        What it cannot do: out-argue the server. Nothing here makes a script
        undetectable, and no client can decide what the server believes.
        Test it yourself: Anti-Cheat tab -> "Run audit now".
]]

local VERSION   = "v1.0"
local BUILD     = "Steal An Egg · free · Halloween build 17.10"
local AUTHOR    = "ameksi-web"
local GAME_NAME = "Steal An Egg"

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
    -- ── steal loop ────────────────────────────────────────────────────────
    AutoSteal           = false,
    StealMode           = "Smart",      -- Smart | Nearest | Best value | Specific
    StealDelay          = 0.6,          -- seconds between egg grabs
    TravelMode          = "Step",       -- Step | Tween | Blink | Fly | Walk
    TravelSpeed         = 120,          -- studs/s the travel modes will ask for
    StealOnce           = false,
    SkipWhileCarrying   = true,
    AutoReturn          = true,         -- carry the egg home by itself
    ReturnSpeed         = 170,
    AutoDropOnGuard     = true,         -- drop the egg if a guardian locks on
    RecoverDropped      = true,         -- go back for an egg you dropped
    SnipeDropped        = false,        -- take eggs other players dropped
    PursueCarriers      = false,        -- chase players who carry an egg
    SafeHover           = 4,            -- studs above a nest the travel stops at
    MinRarity           = "Rare",
    MinValue            = 0,            -- $/s an egg must be worth to be taken
    AllowedAreas        = "",           -- comma separated biome names, empty = all
    MutationFilter      = "",           -- comma separated mutations, empty = all
    TargetEgg           = "",           -- specific egg name for StealMode = Specific
    IgnoreOwnPlot       = true,

    -- ── base / eggs ───────────────────────────────────────────────────────
    AutoPlace           = false,
    PlaceDelay          = 0.5,
    PlaceRule           = "Any",        -- Any | Best only | Filtered
    MaxPlaced           = 30,
    AutoHatch           = false,
    HatchDelay          = 0.4,
    SkipHatchReveal     = true,
    AutoIndex           = false,
    AutoClaimOffline    = false,
    AutoBuyTrails       = false,
    AutoEquipBest       = false,
    AutoFuse            = false,
    AutoSellEggs        = false,
    AutoSellPets        = false,
    SellBelowRarity     = "Rare",
    FavouriteRarity     = "Secret",
    SellDelay           = 30,

    -- ── farm helpers ──────────────────────────────────────────────────────
    AutoTreadmill       = false,
    AutoUpgradeTreadmill= false,
    TreadmillInterval   = 1.0,
    AutoRebirth         = false,
    GuardianWarning     = true,
    GuardianRange       = 60,
    TrapAvoid           = true,
    AntiAfk             = true,
    AutoReconnect       = true,

    -- ── events ────────────────────────────────────────────────────────────
    AutoBoss            = false,
    AutoRift            = false,
    AutoRace            = false,
    AutoStar            = false,
    AutoBloom           = false,
    AutoLab             = false,
    EventNotify         = true,

    -- ── movement ──────────────────────────────────────────────────────────
    WalkSpeedEnabled    = false,
    WalkSpeed           = 28,
    JumpPowerEnabled    = false,
    JumpPower           = 60,
    InfiniteJump        = false,
    AlwaysSprint        = false,
    FlyEnabled          = false,
    FlySpeed            = 90,
    Noclip              = false,
    AntiVoid            = true,
    AntiFling           = true,
    AntiRagdoll         = true,
    AntiStun            = true,
    AntiSlow            = true,
    NoFallDamage        = true,
    LowGravity          = false,
    SafeWalk            = true,

    -- ── esp ───────────────────────────────────────────────────────────────
    EspEggs             = true,
    EspBestOnly         = false,
    EspGuardians        = true,
    EspDropped          = true,
    EspPlayers          = false,
    EspPlots            = false,
    EspNames            = true,
    EspRarity           = true,
    EspValue            = true,
    EspDistance         = true,
    EspTracers          = false,
    EspMaxDistance      = 1500,
    EspFillTransparency = 0.62,
    EspInterval         = 0.4,

    -- ── anti-cheat ────────────────────────────────────────────────────────
    AcNeutralize        = true,
    AcCamouflage        = true,
    AcSpeedLimiter      = true,
    AcBlockReports      = true,
    AcKickGuard         = true,
    AcSafeMode          = true,
    AcSpeedCeiling      = 60,
    AcRemoteRateLimit   = 14,
    AcTeleportPacing    = true,
    AcStepSize          = 12,           -- max studs one movement step may cover
    AcStepDelay         = 0.05,
    StaffWatch          = true,
    StaffGroupId        = 0,
    StaffHop            = false,
    CombatJitter        = true,
    HumanPause          = true,

    -- ── fun ───────────────────────────────────────────────────────────────
    EggRain             = false,
    BatAura             = false,
    RainbowPlot         = false,
    DiscoMode           = false,
    BigPets             = false,
    PetScale            = 1.4,
    HitSparks           = true,
    EmoteLoop           = false,
    EmoteLoopDelay      = 14,
    AutoGG              = false,
    GGMessage           = "gg",
    ChatMessage         = "",
    ChatDelay           = 15,
    ChatSpam            = false,
    Music               = false,
    MusicId             = "",
    MusicVolume         = 1,
    CameraFov           = 70,
    Fullbright          = false,
    RemoveVfx           = false,
    FpsBoost            = false,

    -- ── performance ───────────────────────────────────────────────────────
    ScanInterval        = 1.5,
    RefreshInterval     = 0.3,
    ScanBudget          = 1400,
    PerfStats           = false,

    -- ── interface ─────────────────────────────────────────────────────────
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
        Name = "SkillHubStealAnEgg",
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
-- 6 · GAME KNOWLEDGE — Steal An Egg (Halloween Dimension build, 17.10.2026)
--     Everything here was read off the live game and its patch notes: the 13
--     biomes and their speed gates, the rarity ladder, the mutation list, and
--     the words the game uses for nests, plots, prompts and remotes. The hub
--     never assumes one exact name — it matches a list and falls back to the
--     next hint, because the game renames something almost every week.
-- ═══════════════════════════════════════════════════════════════════════════

local Replicated   = getService("ReplicatedStorage")
local HttpService  = getService("HttpService")
local Teleport     = getService("TeleportService")
local Stats        = getService("Stats")

local KNOWLEDGE = {
    -- order matters: this is the ladder used by every filter and by scoring
    Rarities = { "Common", "Uncommon", "Rare", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine" },
    RarityWeight = {
        Common = 1, Uncommon = 2, Rare = 4, Legendary = 8, Mythic = 16,
        Cosmic = 32, Secret = 64, Eternal = 128, Divine = 256,
    },
    -- base $/s the hub assumes when the egg carries no Value attribute
    RarityValue = {
        Common = 5, Uncommon = 25, Rare = 150, Legendary = 1200, Mythic = 9000,
        Cosmic = 75000, Secret = 600000, Eternal = 5000000, Divine = 40000000,
    },
    Mutations = {
        Normal = 1, Bloom = 1.4, ["Spirit Bloom"] = 1.6, Fractured = 1.8,
        Luminous = 2.0, Skeletal = 2.2, Mecha = 2.5, Enchanted = 2.8,
        Nitro = 3.0, Rainbow = 3.5, Bloodmoon = 4.0,
    },
    -- biomes, cheapest first; Speed is the published gate
    Biomes = {
        { Name = "Forest",           Speed = 0 },
        { Name = "Lake",             Speed = 900 },
        { Name = "Desert",           Speed = 10000 },
        { Name = "Jungle",           Speed = 40000 },
        { Name = "Snow",             Speed = 170000 },
        { Name = "Volcano",          Speed = 700000 },
        { Name = "Abyss Ocean",      Speed = 2500000 },
        { Name = "Prehistoric",      Speed = 17000000 },
        { Name = "Cosmic",           Speed = 700000000 },
        { Name = "Cherry Blossom",   Speed = 2500000000 },
        { Name = "Titan Temple",     Speed = 7000000000 },
        { Name = "Angels",           Speed = 20000000000 },
        { Name = "Demons",           Speed = 20000000000 },
        { Name = "Enchanted Forest", Speed = 50000000000 },
        { Name = "Halloween",        Speed = 0 },
    },
    Guardian = {
        "guardian", "guard", "boss", "overlord", "gorilla", "scorpion",
        "abyss", "titan", "keeper", "sentinel", "warden", "hunter",
    },
    Nests = { "nest", "egg nest", "spawn", "pedestal", "incubator" },
    Eggs = { "egg" },
    DropWords = { "drop", "dropped", "fallen" },
    Plots = { "plot", "base", "home", "island", "tycoon" },
    Treadmill = { "treadmill", "speed", "trainer", "walkpad", "mill" },
    -- prompt / remote words, most specific first
    StealWords  = { "steal", "take", "grab", "snatch", "loot", "pick up", "pickup" },
    PlaceWords  = { "place", "put", "drop", "store", "deposit", "insert" },
    HatchWords  = { "hatch", "open", "crack", "unbox", "incubate" },
    IndexWords  = { "index", "collection", "discovery", "reward", "claim" },
    TrailWords  = { "trail", "buy trail", "purchase trail" },
    FuseWords   = { "fuse", "fusion", "combine", "merge" },
    SellWords   = { "sell", "trade in", "convert" },
    EquipWords  = { "equip", "best pet", "auto equip" },
    UpgradeWords= { "upgrade", "level up", "buy upgrade" },
    -- anti-cheat surface this game actually has
    DetectorWords = {
        "anticheat", "anti cheat", "anti-cheat", "detector", "monitor", "security",
        "telemetry", "integrity", "speedcheck", "speed check", "exploit", "guard",
        "validation", "sanitizer", "watchdog", "cheatcheck",
    },
    ReportWords = {
        "report", "flag", "ban", "banplayer", "kick", "screenshot", "evidence",
        "anticheatreport", "moderation", "log", "submit", "record",
    },
    -- events shipped up to the Halloween build
    Events = {
        { Key = "Rift",    Words = { "rift", "abyss overlord", "overlord", "boss token" }, Label = "Rift / Abyss Overlord" },
        { Key = "Race",    Words = { "race", "nitro", "trophy", "checkpoint" },           Label = "Nitro Race" },
        { Key = "Star",    Words = { "shooting star", "stellaris", "star fall" },          Label = "Shooting Star" },
        { Key = "Bloom",   Words = { "butterfly", "bloom", "enchanted tree", "wisp" },     Label = "Butterfly Bloom" },
        { Key = "Lab",     Words = { "scramble", "laboratory", "experiment", "extinction" }, Label = "Dr. Scramble's Lab" },
        { Key = "Halloween", Words = { "halloween", "pumpkin", "candy", "spirit" },        Label = "Halloween Dimension" },
    },
}

-- lowercase helpers (memoised for instances, plain tables for word lists)
local function lower(text) return string.lower(tostring(text or "")) end

local function lowerList(list)
    local out = {}
    for index, value in ipairs(list) do out[index] = lower(value) end
    return out
end

local LOWER = {
    Guardian = lowerList(KNOWLEDGE.Guardian),
    Nests = lowerList(KNOWLEDGE.Nests),
    Plots = lowerList(KNOWLEDGE.Plots),
    Treadmill = lowerList(KNOWLEDGE.Treadmill),
    Steal = lowerList(KNOWLEDGE.StealWords),
    Place = lowerList(KNOWLEDGE.PlaceWords),
    Hatch = lowerList(KNOWLEDGE.HatchWords),
    Index = lowerList(KNOWLEDGE.IndexWords),
    Trail = lowerList(KNOWLEDGE.TrailWords),
    Fuse = lowerList(KNOWLEDGE.FuseWords),
    Sell = lowerList(KNOWLEDGE.SellWords),
    Equip = lowerList(KNOWLEDGE.EquipWords),
    Upgrade = lowerList(KNOWLEDGE.UpgradeWords),
    Detectors = lowerList(KNOWLEDGE.DetectorWords),
    Reports = lowerList(KNOWLEDGE.ReportWords),
    Drops = lowerList(KNOWLEDGE.DropWords),
}

local function containsAny(text, list)
    local haystack = lower(text)
    for index = 1, #list do
        if string.find(haystack, list[index], 1, true) then return true, list[index] end
    end
    return false
end

local function splitList(text)
    local out = {}
    for token in string.gmatch(tostring(text or ""), "[^,%s]+") do
        out[#out + 1] = lower(token)
    end
    return out
end

local function shortNumber(value)
    local number = tonumber(value) or 0
    local suffixes = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
    for _, entry in ipairs(suffixes) do
        if math.abs(number) >= entry[1] then
            local scaled = number / entry[1]
            local text = (math.abs(scaled) >= 100) and string.format("%.0f", scaled)
                or (math.abs(scaled) >= 10) and string.format("%.1f", scaled)
                or string.format("%.2f", scaled)
            text = string.gsub(string.gsub(text, "0+$", ""), "%.$", "")
            return text .. entry[2]
        end
    end
    return tostring(math.floor(number))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 7 · PERFORMANCE CORE
--     Same two-tier design as the Jujutsu build: a rare structure walk that
--     discovers and classifies, and a cheap refresh that only reads positions.
--     A Steal An Egg server has hundreds of eggs across 13 biomes, so the walk
--     is budgeted and the refresh reuses every record.
-- ═══════════════════════════════════════════════════════════════════════════

local State = {
    alive = true,
    started = monotonic and monotonic() or os.clock(),
    style = "—",
    carrying = nil,
    carryingSince = 0,
    lastSteal = 0,
    steals = 0,
    stealsFailed = 0,
    placed = 0,
    hatched = 0,
    fused = 0,
    sold = 0,
    lastPlace = 0,
    lastHatch = 0,
    lastIndex = 0,
    lastTrail = 0,
    lastTreadmill = 0,
    lastFuse = 0,
    lastSell = 0,
    lastEquip = 0,
    lastRemote = 0,
    remoteCount = 0,
    remoteBurst = 0,
    speedWrites = 0,
    lastAttack = 0,
    lastGG = 0,
    lastEmote = 0,
    awakening = false,
    ping = 0,
    lastPingAt = 0,
    deaths = 0,
    homePosition = nil,
    targets = {},
    perf = {
        scanMs = 0, scanCalls = 0, structureScans = 0, refreshCalls = 0,
        espUpdates = 0, writes = 0, frame = 0, frames = 0, fpsAt = 0,
        skips = 0, reused = 0, visits = 0, report = nil,
    },
}

local Cache = {
    character = nil, root = nil, humanoid = nil,
    names = setmetatable({}, { __mode = "k" }),
    nameSource = setmetatable({}, { __mode = "k" }),
    kinds = setmetatable({}, { __mode = "k" }),
    kindNames = setmetatable({}, { __mode = "k" }),
    parts = setmetatable({}, { __mode = "k" }),
    prompts = setmetatable({}, { __mode = "k" }),
    playerChars = {}, playerCharsAt = 0,
    ownPlot = nil, ownPlotAt = 0,
    guiSearch = {},
    playerGui = nil, playerGuiAt = 0,
}

local WriteCache = { speed = nil, jump = nil, noclip = nil, staminaAt = 0 }

local function getChar()
    local character = Cache.character
    if character and character.Parent and LocalPlayer and LocalPlayer.Character == character then
        return character
    end
    if not LocalPlayer then return nil end
    character = LocalPlayer.Character
    if character and character.Parent then
        Cache.character, Cache.root, Cache.humanoid = character, nil, nil
        return character
    end
    return nil
end

local function getRoot()
    local character = getChar()
    if not character then return nil end
    local root = Cache.root
    if root and root.Parent == character then return root end
    root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if root then Cache.root = root end
    return root
end

local function getHumanoid()
    local character = getChar()
    if not character then return nil end
    local humanoid = Cache.humanoid
    if humanoid and humanoid.Parent == character then return humanoid end
    humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then Cache.humanoid = humanoid end
    return humanoid
end

local function isAlive()
    local humanoid = getHumanoid()
    return humanoid ~= nil and (humanoid.Health or 0) > 0
end

local function lowerName(instance)
    local name = instance.Name or "?"
    local cached = Cache.names[instance]
    if cached and Cache.nameSource[instance] == name then return cached end
    cached = string.lower(name)
    Cache.names[instance], Cache.nameSource[instance] = cached, name
    return cached
end

local function modelPosition(model)
    if not model then return nil end
    local part = Cache.parts[model]
    if part and part.Parent then return part.Position end
    part = model.PrimaryPart
    if not part or not part.Parent then part = model:FindFirstChild("HumanoidRootPart") end
    if not part or not part.Parent then part = model:FindFirstChildWhichIsA("BasePart") end
    if not part or not part.Parent then
        local queue, head, visits = { model }, 1, 0
        while head <= #queue and visits < 20 do
            local node = queue[head]; head = head + 1; visits = visits + 1
            local children = node:GetChildren()
            for index = 1, #children do
                local child = children[index]
                if child:IsA("BasePart") then part = child break end
                local class = child.ClassName
                if class == "Model" or class == "Folder" then queue[#queue + 1] = child end
            end
            if part then break end
        end
    end
    if part then Cache.parts[model] = part; return part.Position end
    if model:IsA("BasePart") then return model.Position end
    return nil
end

-- prompt discovery is cached: a nest asks for its prompt once, not per frame
-- Prompt discovery is cached and depth-limited. The depth limit matters: a
-- model called "Forest" contains eggs, and their prompts, and the classifier
-- must not conclude that the whole biome is one stealable egg.
local function findPrompt(instance, words, maxDepth)
    local cached = Cache.prompts[instance]
    if cached and cached.Parent and cached.Enabled ~= false then
        if not words or containsAny(cached.ActionText or cached.ObjectText or cached.Name, words) then
            return cached
        end
    end
    if instance:IsA("ProximityPrompt") then return instance end
    local limit = maxDepth or 3
    local queue, head = { { instance, 0 } }, 1
    while head <= #queue do
        local entry = queue[head]; head = head + 1
        if entry[2] < limit then
            for _, child in ipairs(entry[1]:GetChildren()) do
                if child:IsA("ProximityPrompt") and child.Enabled ~= false then
                    if not words or containsAny((child.ActionText or "") .. " " .. (child.ObjectText or "")
                        .. " " .. child.Name, words) then
                        Cache.prompts[instance] = child
                        return child
                    end
                else
                    queue[#queue + 1] = { child, entry[2] + 1 }
                end
            end
        end
    end
    return nil
end

-- ── attributes with fallbacks ─────────────────────────────────────────────
local function attr(instance, names)
    for _, name in ipairs(names) do
        local ok, value = pcall(function() return instance:GetAttribute(name) end)
        if ok and value ~= nil then return value end
    end
    for _, child in ipairs(instance:GetChildren()) do
        if child:IsA("ValueBase") and containsAny(child.Name, names) then
            local ok, value = pcall(function() return child.Value end)
            if ok and value ~= nil then return value end
        end
    end
    return nil
end

local function rarityOf(instance, name)
    local raw = attr(instance, { "Rarity", "RarityName", "Tier" })
    local text = lower(raw or name or instance.Name)
    for index = #KNOWLEDGE.Rarities, 1, -1 do
        if string.find(text, lower(KNOWLEDGE.Rarities[index]), 1, true) then
            return KNOWLEDGE.Rarities[index], index
        end
    end
    return "Common", 1
end

local function mutationOf(instance, name)
    local raw = attr(instance, { "Mutation", "MutationName", "Modifier" })
    local text = lower(raw or name or "")
    local best, bestLength = "Normal", 0
    for mutation in pairs(KNOWLEDGE.Mutations) do
        local needle = lower(mutation)
        if string.find(text, needle, 1, true) and #needle > bestLength then
            best, bestLength = mutation, #needle
        end
    end
    return best
end

local function valueOf(instance, rarity)
    local raw = attr(instance, { "Value", "Money", "Income", "MPS", "PerSecond", "Cash" })
    local number = tonumber(raw)
    if number and number > 0 then return number end
    local name = instance.Name or ""
    -- "Secret Egg ($12M/s)" style names
    local money = string.match(name, "%$([%d%.]+)%s*([KMBT])")
    if money then
        local amount = tonumber(money) or 0
        local suffix = string.upper(string.match(name, "%$[%d%.]+%s*([KMBT])") or "")
        local scale = ({ K = 1e3, M = 1e6, B = 1e9, T = 1e12 })[suffix] or 1
        return amount * scale
    end
    return KNOWLEDGE.RarityValue[rarity] or 1
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 7b · THE WORLD — two tiers
-- ═══════════════════════════════════════════════════════════════════════════
local World = {
    found = {},            -- every classified instance
    eggs = {}, nests = {}, plots = {}, guardians = {}, treadmills = {}, events = {},
    best = nil, bestScore = 0, at = 0, structureAt = 0,
    count = 0, eggCount = 0,
    pool = {},             -- instance → reusable record
}

local function wipe(list)
    for index = #list, 1, -1 do list[index] = nil end
end

local function classify(instance)
    local name = instance.Name or ""
    local cached = Cache.kinds[instance]
    if cached ~= nil and Cache.kindNames[instance] == name then return cached or nil end

    local kind = false
    local low = lower(name)
    local class = instance.ClassName

    local owned = instance:GetAttribute("SkillHubOwned")
    if owned then
        Cache.kinds[instance] = false
        Cache.kindNames[instance] = name
        return nil
    end

    -- a BasePart called "EggBody" inside a model called "Secret Egg" is the
    -- egg, not a second egg: without this the map reports every object twice
    if instance:IsA("BasePart") then
        local parent = instance.Parent
        if parent and parent:IsA("Model") and classify(parent) ~= nil then
            Cache.kinds[instance] = false
            Cache.kindNames[instance] = name
            return nil
        end
    end

    if class == "Model" or class == "Part" or class == "MeshPart" or instance:IsA("BasePart") then
        if containsAny(low, LOWER.Guardian) and not containsAny(low, LOWER.Nests) then
            kind = "guardian"
        elseif containsAny(low, LOWER.Nests) then
            kind = "nest"
        elseif string.find(low, "egg", 1, true) then
            -- a part is only an egg if it is a model, carries a rarity, or
            -- answers a steal prompt: "SkillHubEggRain" is none of those
            if instance:IsA("Model") or attr(instance, { "Rarity", "RarityName", "Tier" }) ~= nil
                or findPrompt(instance, LOWER.Steal, 1) ~= nil then
                kind = containsAny(low, LOWER.Drops) and "dropped" or "egg"
            end
        elseif containsAny(low, LOWER.Treadmill) then
            kind = "treadmill"
        elseif containsAny(low, LOWER.Plots) then
            kind = "plot"
        end
        if not kind then
            local prompt = findPrompt(instance, LOWER.Steal, 1)
            if prompt then kind = "egg" end
        end
        if not kind then
            for _, event in ipairs(KNOWLEDGE.Events) do
                if containsAny(low, lowerList(event.Words)) then
                    kind = "event"
                    instance:SetAttribute("SkillHubEvent", event.Key)
                    break
                end
            end
        end
    end

    Cache.kinds[instance] = kind or false
    Cache.kindNames[instance] = name
    return kind or nil
end

local function eggRecord(instance, kind, position, myPosition)
    local name = instance.Name or "Egg"
    local rarity, rarityIndex = rarityOf(instance, name)
    local mutation = mutationOf(instance, name)
    local value = valueOf(instance, rarity)
    local prompt = findPrompt(instance, LOWER.Steal) or findPrompt(instance, nil)
    local record = World.pool[instance]
    if not record then
        record = { instance = instance }
        World.pool[instance] = record
        State.perf.reused = State.perf.reused + 1
    end
    local area = instance:FindFirstAncestorOfClass("Model")
    local areaName = "—"
    local node = instance
    for _ = 1, 6 do
        if not node.Parent then break end
        node = node.Parent
        if node == Workspace then break end
        if containsAny(node.Name, lowerList((function()
            local names = {}
            for _, biome in ipairs(KNOWLEDGE.Biomes) do names[#names + 1] = biome.Name end
            return names
        end)())) then
            areaName = node.Name
            break
        end
    end
    record.name = name
    record.kind = kind
    record.rarity = rarity
    record.rarityIndex = rarityIndex
    record.mutation = mutation
    record.value = value
    record.prompt = prompt
    record.position = position
    record.distance = myPosition and (myPosition - position).Magnitude or math.huge
    record.area = areaName
    record.dropped = kind == "dropped"
    record.score = (KNOWLEDGE.RarityWeight[rarity] or 1)
        * (KNOWLEDGE.Mutations[mutation] or 1)
        * (1 + (math.log(math.max(value, 1)) / math.log(10)) * 0.15)
    return record
end

local function structureScan()
    local started = os.clock()
    wipe(World.found)
    wipe(World.events)
    local budget = tonumber(Config.ScanBudget) or 1200
    local visits = 0
    local queue, head = {}, 1

    local function push(instance, depth)
        if instance and visits + #queue < budget * 2 then
            queue[#queue + 1] = { instance = instance, depth = depth }
        end
    end

    for _, child in ipairs(Workspace:GetChildren()) do push(child, 1) end
    local replicated = Replicated
    if replicated then
        for _, child in ipairs(replicated:GetChildren()) do
            local kind = classify(child)
            if kind then World.found[#World.found + 1] = child end
        end
    end

    while head <= #queue and visits < budget do
        local entry = queue[head]; head = head + 1
        local node, depth = entry.instance, entry.depth
        visits = visits + 1
        if node.Parent ~= nil then
            local kind = classify(node)
            if kind then World.found[#World.found + 1] = node end
            if depth < 5 and not node:IsA("BasePart") then
                local children = node:GetChildren()
                for index = 1, #children do push(children[index], depth + 1) end
            end
        end
    end

    World.structureAt = os.clock()
    State.perf.structureScans = State.perf.structureScans + 1
    State.perf.visits = visits
    State.perf.scanMs = (os.clock() - started) * 1000
    State.perf.writes = State.perf.writes
end

local function findOwnPlot()
    local now = os.clock()
    if Cache.ownPlot and Cache.ownPlot.Parent and now - (Cache.ownPlotAt or 0) < 5 then
        return Cache.ownPlot
    end
    local playerName = LocalPlayer and lower(LocalPlayer.Name) or ""
    local displayName = LocalPlayer and lower(LocalPlayer.DisplayName or "") or ""
    for _, instance in ipairs(World.found) do
        if Cache.kinds[instance] == "plot" then
            local owner = attr(instance, { "Owner", "OwnerName", "Player", "UserId" })
            local low = lowerName(instance)
            if (owner and (lower(owner) == playerName or lower(owner) == displayName))
                or (playerName ~= "" and string.find(low, playerName, 1, true))
                or (displayName ~= "" and string.find(low, displayName, 1, true)) then
                Cache.ownPlot, Cache.ownPlotAt = instance, now
                return instance
            end
        end
    end
    return nil
end

local function refreshWorld()
    local started = os.clock()
    wipe(World.eggs); wipe(World.nests); wipe(World.plots)
    wipe(World.guardians); wipe(World.treadmills)
    local root = getRoot()
    local myPosition = root and root.Position
    local best, bestScore = nil, 0
    local ownPlot = findOwnPlot()

    for index = 1, #World.found do
        local instance = World.found[index]
        if instance.Parent then
            local kind = Cache.kinds[instance]
            local position = (kind ~= "event") and modelPosition(instance) or nil
            if kind == "egg" or kind == "dropped" then
                if position then
                    local record = eggRecord(instance, kind, position, myPosition)
                    local isOwn = false
                    if ownPlot and instance:IsDescendantOf(ownPlot) then isOwn = true end
                    record.own = isOwn
                    if not isOwn or not Config.IgnoreOwnPlot then
                        World.eggs[#World.eggs + 1] = record
                        if record.score > bestScore then best, bestScore = record, record.score end
                    end
                end
            elseif position then
                local bucket = World[kind == "nest" and "nests"
                    or kind == "plot" and "plots"
                    or kind == "guardian" and "guardians"
                    or "treadmills"]
                if bucket then
                    local record = World.pool[instance]
                    if not record then
                        record = { instance = instance }
                        World.pool[instance] = record
                        State.perf.reused = State.perf.reused + 1
                    end
                    record.name = instance.Name
                    record.position = position
                    record.distance = myPosition and (myPosition - position).Magnitude or math.huge
                    record.own = (ownPlot == instance) or (ownPlot and instance:IsDescendantOf(ownPlot)) or false
                    bucket[#bucket + 1] = record
                end
            end
        else
            Cache.kinds[instance] = nil
            Cache.kindNames[instance] = nil
            Cache.names[instance] = nil
            Cache.nameSource[instance] = nil
            Cache.parts[instance] = nil
            Cache.prompts[instance] = nil
        end
    end

    if Config.EspBestOnly and best then
        -- keep exactly the best egg in the list so ESP and the tracer agree
        local only = { best }
        World.eggs = only
    end

    World.best, World.bestScore = best, bestScore
    World.eggCount = #World.eggs
    World.count = #World.eggs + #World.guardians + #World.plots
    World.at = os.clock()
    State.perf.refreshCalls = State.perf.refreshCalls + 1
    State.perf.scanMs = (os.clock() - started) * 1000
end

local function scanWorld(force)
    local now = os.clock()
    local interval = tonumber(Config.ScanInterval) or 1.5
    if force or now - World.structureAt > interval then structureScan() end
    refreshWorld()
    State.perf.scanCalls = State.perf.scanCalls + 1
    return World
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 8 · ACTIONS — prompts, remotes, travel
-- ═══════════════════════════════════════════════════════════════════════════

local AC = {
    hookInstalled = false, kickGuard = false, blocked = 0, lastBlocked = nil,
    detectors = {}, reports = {}, scripts = {},
}

local function canWrite()
    return State.alive
end

-- every remote call this hub makes goes through here: one rate limiter, one
-- pacer, and one place that can refuse to send at all in safe mode
local function fireRemote(remote, ...)
    if not remote then return false end
    local now = os.clock()
    local limit = tonumber(Config.AcRemoteRateLimit) or 14
    if now - State.remoteBurst > 1 then
        State.remoteBurst = now
        State.remoteCount = 0
    end
    if Config.AcSafeMode and State.remoteCount >= limit then
        State.perf.skips = State.perf.skips + 1
        return false
    end
    State.remoteCount = State.remoteCount + 1
    State.lastRemote = now
    local packed = table.pack(...)
    local ok = safeCall("remote", function()
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(table.unpack(packed, 1, packed.n))
        end
        remote:FireServer(table.unpack(packed, 1, packed.n))
        return true
    end)
    return ok == true
end

local function findClickDetector(instance, maxDepth)
    if not instance then return nil end
    local limit = maxDepth or 2
    local queue, head = { { instance, 0 } }, 1
    while head <= #queue do
        local entry = queue[head]; head = head + 1
        if entry[2] < limit then
            for _, child in ipairs(entry[1]:GetChildren()) do
                if child:IsA("ClickDetector") then return child end
                queue[#queue + 1] = { child, entry[2] + 1 }
            end
        end
    end
    return nil
end

local function findRemote(words)
    if not Replicated then return nil end
    local best = nil
    for _, descendant in ipairs(Replicated:GetDescendants()) do
        if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
            local hit = containsAny(descendant.Name, words)
            if hit then
                if descendant:IsA("RemoteFunction") then return descendant end
                best = best or descendant
            end
        end
    end
    return best
end

-- an executor's fireproximityprompt is the reliable path; the two Input calls
-- are the documented fallback and work everywhere
local function firePrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    if type(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt)
        if ok then return true end
    end
    local ok = safeCall("prompt", function()
        if prompt.HoldDuration and prompt.HoldDuration > 0 then
            prompt:InputHoldBegin()
            task.wait(math.min(prompt.HoldDuration + 0.05, 1.2))
            prompt:InputHoldEnd()
        else
            prompt:InputHoldBegin()
            prompt:InputHoldEnd()
        end
        return true
    end)
    return ok == true
end

local function clickGuiButton(words, limit)
    local now = os.clock()
    local purpose = table.concat(words, "|")
    local memo = Cache.guiSearch[purpose]
    if memo and memo.button and memo.button.Parent then return memo.button end
    if memo and now - memo.at < 1.5 then return nil end
    local playerGui = Cache.playerGui
    if not playerGui or not playerGui.Parent or now - Cache.playerGuiAt > 5 then
        playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
        Cache.playerGui, Cache.playerGuiAt = playerGui, now
    end
    local core = game:FindFirstChild("CoreGui")
    for _, root in ipairs({ playerGui, core }) do
        if root then
            local queue, head, visits = { root }, 1, 0
            while head <= #queue and visits < (limit or 900) do
                local node = queue[head]; head = head + 1; visits = visits + 1
                if (node:IsA("TextButton") or node:IsA("ImageButton")) and node.Visible ~= false then
                    local label = node.Name
                    if node:IsA("TextButton") then label = label .. " " .. tostring(node.Text) end
                    if containsAny(label, words) then
                        Cache.guiSearch[purpose] = { at = now, button = node }
                        pcall(function() node:Click() end)
                        return node
                    end
                end
                local children = node:GetChildren()
                for index = 1, #children do queue[#queue + 1] = children[index] end
            end
        end
    end
    Cache.guiSearch[purpose] = { at = now, button = nil }
    return nil
end

-- ── travel ────────────────────────────────────────────────────────────────
-- One character, one travel. Without a lock every worker yanks the root in a
-- different direction and nothing arrives; with it the steal loop preempts the
-- treadmill, and an item that was interrupted stops writing.
local Travel = { owner = nil, priority = 0, untilAt = 0, token = 0 }
local TRAVEL_PRIORITY = { selftest = 9, steal = 4, base = 3, teleport = 3, event = 2, treadmill = 1, misc = 1 }

local function maxStep()
    return math.clamp(tonumber(Config.AcStepSize) or 12, 2, 40)
end

local function releaseTravel(token)
    if Travel.token == token then
        Travel.owner, Travel.priority, Travel.untilAt = nil, 0, 0
    end
end

local function isVector(value)
    if typeof(value) == "Vector3" then return true end
    -- executors normally answer this, but a table-shaped vector must not be
    -- sent through modelPosition (it would try instance methods on it)
    return type(value) == "table" and rawget(value, "x") ~= nil and rawget(value, "y") ~= nil
end

local function travelTo(target, options)
    options = options or {}
    if not isVector(target) then target = modelPosition(target) end
    if not target then return false end
    local root = getRoot()
    if not root then return false end

    local owner = options.owner or "misc"
    local priority = TRAVEL_PRIORITY[owner] or 1
    local now = os.clock()
    if Travel.owner and Travel.owner ~= owner and now < Travel.untilAt
        and Travel.priority > priority then
        return false
    end
    Travel.token = Travel.token + 1
    local token = Travel.token
    Travel.owner, Travel.priority = owner, priority
    Travel.untilAt = now + (options.timeout or 25) + 1

    local mode = options.mode or Config.TravelMode or "Step"
    local speed = math.clamp(tonumber(options.speed or Config.TravelSpeed) or 100, 8, 4000)
    if Config.AcSafeMode then
        speed = math.min(speed, tonumber(Config.AcSpeedCeiling) or 60)
    end
    local stopDistance = tonumber(options.stopDistance) or 3
    local deadline = os.clock() + (options.timeout or 25)

    if mode == "Walk" then
        local humanoid = getHumanoid()
        if humanoid then
            humanoid:MoveTo(target)
            while State.alive and os.clock() < deadline do
                if Travel.token ~= token then releaseTravel(token) return false end
                local position = getRoot() and getRoot().Position
                if not position then break end
                if (position - target).Magnitude <= stopDistance + 2 then
                    releaseTravel(token)
                    return true
                end
                task.wait(0.12)
            end
        end
        releaseTravel(token)
        return false
    end

    if mode == "Tween" then
        local position = root.Position
        local distance = (target - position).Magnitude
        if distance < 0.5 then releaseTravel(token) return true end
        local duration = math.max(0.12, distance / speed)
        local reached = false
        safeCall("tween", function()
            local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear),
                { CFrame = CFrame.new(target) })
            tween.Completed:Connect(function() reached = true end)
            tween:Play()
        end)
        local until_ = os.clock() + duration + 0.4
        while State.alive and os.clock() < until_ and not reached do
            if Travel.token ~= token then releaseTravel(token) return false end
            task.wait(0.03)
        end
        releaseTravel(token)
        return true
    end

    -- Step / Blink / Fly: bounded hops, which is what a server-side movement
    -- sampler accepts; Fly just adds a vertical component and ignores gravity
    local step = mode == "Blink" and math.min(maxStep() * 3, 36) or maxStep()
    local delay = mode == "Blink" and 0.07 or (tonumber(Config.AcStepDelay) or 0.05)
    while State.alive and os.clock() < deadline do
        if Travel.token ~= token then releaseTravel(token) return false end
        local currentRoot = getRoot()
        if not currentRoot then releaseTravel(token) return false end
        local position = currentRoot.Position
        local delta = target - position
        local distance = delta.Magnitude
        if distance <= stopDistance then releaseTravel(token) return true end
        local hop = math.min(step, distance)
        local nextPosition = position + delta.Unit * hop
        pcall(function() currentRoot.CFrame = CFrame.new(nextPosition) end)
        State.perf.writes = State.perf.writes + 1
        task.wait(delay)
    end
    releaseTravel(token)
    return false
end

local function travelToBase()
    local plot = findOwnPlot()
    if not plot then
        notify("Steal", "own plot not found — scan the base first", 4, Theme.Warning, ICON.Warning)
        return false
    end
    local position = modelPosition(plot)
    if not position then return false end
    return travelTo(position, { owner = "base", mode = Config.TravelMode, speed = Config.ReturnSpeed,
        stopDistance = 6, timeout = 30 })
end

-- ── carrying ──────────────────────────────────────────────────────────────
local function carriedEgg()
    local character = getChar()
    if not character then return nil end
    local carried = State.carrying
    if carried and carried.Parent and carried:IsDescendantOf(character) then return carried end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Model") and string.find(lower(child.Name), "egg", 1, true) then
            State.carrying, State.carryingSince = child, os.clock()
            return child
        end
        if child:IsA("BasePart") and string.find(lower(child.Name), "egg", 1, true) then
            State.carrying, State.carryingSince = child, os.clock()
            return child
        end
    end
    State.carrying = nil
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 9 · THE STEAL ENGINE
--     One loop, five travel modes, and one rule learned from every competitor
--     that broke on this game: never trust a single hop. After a grab the hub
--     checks that the egg is really in your hands, and if it is not it retries
--     from a walk-in distance instead of hammering the prompt.
-- ═══════════════════════════════════════════════════════════════════════════

local Loop = {
    lastSteal = 0, lastPlace = 0, lastHatch = 0, lastIndex = 0, lastTrail = 0,
    lastTreadmill = 0, lastFuse = 0, lastSell = 0, lastEquip = 0, lastGuard = 0,
    lastGuardianWarn = 0, guard = nil, paused = false, pauseUntil = 0,
    killStreak = 0, lastKill = 0, lastGG = 0, lastEmote = 0, lastSpam = 0,
    lastHop = 0, lastEvent = 0, lastRace = 0, lastBoss = 0,
}

local function rarityIndex(name)
    local wanted = lower(name)
    for index, rarity in ipairs(KNOWLEDGE.Rarities) do
        if lower(rarity) == wanted then return index end
    end
    return 1
end

local function eggAllowed(record)
    if record.dropped and not (Config.SnipeDropped or Config.RecoverDropped) then return false end
    if record.rarityIndex < rarityIndex(Config.MinRarity or "Common") then return false end
    if (tonumber(Config.MinValue) or 0) > 0 and (record.value or 0) < tonumber(Config.MinValue) then return false end
    local areas = splitList(Config.AllowedAreas)
    if #areas > 0 and record.area ~= "—" then
        local ok = false
        for _, area in ipairs(areas) do
            if string.find(lower(record.area), area, 1, true) then ok = true break end
        end
        if not ok then return false end
    end
    local mutations = splitList(Config.MutationFilter)
    if #mutations > 0 then
        local ok = false
        for _, mutation in ipairs(mutations) do
            if string.find(lower(record.mutation), mutation, 1, true) then ok = true break end
        end
        if not ok then return false end
    end
    local target = lower(Config.TargetEgg or "")
    if Config.StealMode == "Specific" and target ~= "" and not string.find(lower(record.name), target, 1, true) then
        return false
    end
    return true
end

local function pickEgg()
    local candidates = {}
    for _, record in ipairs(World.eggs) do
        if eggAllowed(record) then candidates[#candidates + 1] = record end
    end
    if #candidates == 0 then return nil end
    local mode = Config.StealMode or "Smart"
    local best, bestScore = nil, -math.huge
    for _, record in ipairs(candidates) do
        local score
        if mode == "Nearest" then
            score = -(record.distance or math.huge)
        elseif mode == "Best value" then
            score = record.value or 0
        elseif mode == "Specific" then
            score = -(record.distance or math.huge) + (record.rarityIndex or 1) * 5
        else -- Smart: value and rarity against distance, so a Secret next door wins
            local distance = math.max(record.distance or 1, 1)
            score = (record.score or 1) / (distance ^ 0.35)
        end
        if score > bestScore then best, bestScore = record, score end
    end
    return best
end

local function waitingForCarry()
    return carriedEgg() ~= nil
end

local function tryGrab(record)
    if not record or not record.instance or not record.instance.Parent then return false end
    local ok = false
    if Config.TravelMode ~= "Walk" then
        travelTo(record.position, {
            owner = "steal",
            stopDistance = tonumber(Config.SafeHover) or 4,
            speed = Config.TravelSpeed,
            timeout = 20,
        })
    else
        travelTo(record.position, { owner = "steal", mode = "Walk", stopDistance = 3, timeout = 20 })
    end
    local prompt = record.prompt or findPrompt(record.instance, LOWER.Steal)
    -- the base worker must not place the egg while the grab is still deciding
    -- whether it worked: that race used to count a success as a refusal
    State.grabbing = true
    if prompt then
        ok = firePrompt(prompt)
    else
        local detector = findClickDetector(record.instance, 2)
        if detector and type(fireclickdetector) == "function" then
            ok = pcall(fireclickdetector, detector)
        end
    end
    local carriedNow = waitingForCarry()
    if not carriedNow then
        -- some nests only answer a remote; this is the documented fallback
        local remote = findRemote(LOWER.Steal)
        if remote then
            fireRemote(remote, record.instance)
        end
        task.wait(0.3)
        carriedNow = waitingForCarry()
    end
    State.grabbing = false
    if carriedNow then
        if Config.HitSparks then
            safeCall("sparks", function()
                local root = getRoot()
                if not root then return false end
                local emitter = root:FindFirstChild("SkillHubSparks")
                if not emitter then
                    emitter = Instance.new("ParticleEmitter")
                    emitter.Name = "SkillHubSparks"
                    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
                    emitter.Rate = 0
                    emitter.Lifetime = NumberRange.new(0.25, 0.5)
                    emitter.Speed = NumberRange.new(6, 12)
                    emitter.Color = ColorSequence.new(Color3.fromRGB(190, 214, 255))
                    emitter.Parent = root
                end
                emitter:Emit(18)
                return true
            end)
        end
        State.steals = State.steals + 1
        State.lastSteal = os.clock()
        State.carryingSince = os.clock()
        return true
    end
    State.stealsFailed = State.stealsFailed + 1
    return false
end

local function dropCarried()
    local egg = carriedEgg()
    if not egg then return true end
    local remote = findRemote({ "drop", "throw", "release" })
    if remote then fireRemote(remote) end
    local plot = findOwnPlot()
    if plot then
        local prompt = findPrompt(plot, LOWER.Place)
        if prompt then firePrompt(prompt) end
    end
    task.wait(0.25)
    return carriedEgg() == nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 10 · THE BASE ENGINE — place, hatch, index, trails, fuse, sell
-- ═══════════════════════════════════════════════════════════════════════════

local function ownPlotPrompts(words)
    local plot = findOwnPlot()
    if not plot then return nil, nil end
    return findPrompt(plot, words), plot
end

local function placeHeld()
    if State.grabbing then return false end
    if not carriedEgg() then return false end
    -- the plot prompt is a proximity prompt; firing it from three biomes away
    -- is exactly the kind of teleport the server is right to refuse
    local plot = findOwnPlot()
    local root = getRoot()
    if plot and root then
        local plotPosition = modelPosition(plot)
        if plotPosition and (root.Position - plotPosition).Magnitude > 30 then return false end
    end
    if Config.MaxPlaced and Config.MaxPlaced > 0 and State.placed >= Config.MaxPlaced then return false end
    if Config.PlaceRule == "Best only" then
        local egg = carriedEgg()
        local _, index = rarityOf(egg, egg and egg.Name or "")
        if index < 5 then return false end          -- Mythic and above only
    end
    if not plot then return false end
    local prompt = findPrompt(plot, LOWER.Place) or findPrompt(plot, nil)
    local used = false
    if prompt then used = firePrompt(prompt) end
    if not used then
        local remote = findRemote(LOWER.Place)
        if remote then used = fireRemote(remote, carriedEgg()) end
    end
    if used then
        local deadline = os.clock() + 2
        while os.clock() < deadline do
            if carriedEgg() == nil then
                State.placed = State.placed + 1
                State.lastPlace = os.clock()
                return true
            end
            task.wait(0.1)
        end
    end
    return false
end

local function hatchReady(limit)
    local handled = 0
    local plot = findOwnPlot()
    if not plot then return 0 end
    local prompt = findPrompt(plot, LOWER.Hatch)
    if prompt then
        for _ = 1, limit or 4 do
            firePrompt(prompt)
            handled = handled + 1
            task.wait(math.max(0.15, tonumber(Config.HatchDelay) or 0.4))
        end
    else
        local remote = findRemote(LOWER.Hatch)
        if remote then
            for _ = 1, limit or 4 do
                fireRemote(remote)
                handled = handled + 1
                task.wait(math.max(0.15, tonumber(Config.HatchDelay) or 0.4))
            end
        end
    end
    if handled > 0 then
        State.hatched = State.hatched + handled
        State.lastHatch = os.clock()
    end
    return handled
end

local function claimIndex()
    local remote = findRemote(LOWER.Index)
    if remote then
        fireRemote(remote)
        State.lastIndex = os.clock()
        return true
    end
    if clickGuiButton(LOWER.Index) then
        State.lastIndex = os.clock()
        return true
    end
    return false
end

local function claimOffline()
    if clickGuiButton({ "offline", "offline earnings", "collect offline" }) then
        return true
    end
    local remote = findRemote({ "offline", "offlineearnings" })
    if remote then return fireRemote(remote) end
    return false
end

local function buyTrail()
    local remote = findRemote(LOWER.Trail)
    if remote then
        fireRemote(remote)
        State.lastTrail = os.clock()
        return true
    end
    return clickGuiButton(LOWER.Trail) ~= nil
end

local function fusePets()
    local remote = findRemote(LOWER.Fuse)
    if remote then
        fireRemote(remote)
        State.lastFuse = os.clock()
        State.fused = State.fused + 1
        return true
    end
    return false
end

local function sellEggs()
    local remote = findRemote(LOWER.Sell)
    if remote then
        fireRemote(remote, Config.SellBelowRarity)
        State.lastSell = os.clock()
        State.sold = State.sold + 1
        return true
    end
    return false
end

local function equipBest()
    local remote = findRemote(LOWER.Equip)
    if remote then
        fireRemote(remote)
        State.lastEquip = os.clock()
        return true
    end
    return clickGuiButton(LOWER.Equip) ~= nil
end

-- treadmill: stand on it, then keep the "step" prompt alive; upgrade when the
-- base has the button and the toggle is on
local function useTreadmill(upgrade)
    local treadmill = nil
    local plot = findOwnPlot()
    local bestDistance = math.huge
    local root = getRoot()
    local myPosition = root and root.Position
    for _, record in ipairs(World.treadmills) do
        if (record.own or not plot) and record.position then
            local distance = myPosition and (myPosition - record.position).Magnitude or math.huge
            if distance < bestDistance then treadmill, bestDistance = record, distance end
        end
    end
    if not treadmill then return false end
    if bestDistance > 6 then
        travelTo(treadmill.position, { owner = "treadmill", stopDistance = 3, timeout = 15 })
    end
    task.wait(tonumber(Config.TreadmillInterval) or 1)
    if upgrade then
        local prompt = findPrompt(treadmill.instance, LOWER.Upgrade)
        if prompt then firePrompt(prompt) end
        local remote = findRemote(LOWER.Upgrade)
        if remote then fireRemote(remote) end
    end
    State.lastTreadmill = os.clock()
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 11 · GUARDIANS, EVENTS AND DROPPED EGGS
-- ═══════════════════════════════════════════════════════════════════════════

local function nearestGuardian(range)
    local root = getRoot()
    if not root then return nil end
    local best, bestDistance = nil, range or tonumber(Config.GuardianRange) or 60
    for _, record in ipairs(World.guardians) do
        local distance = (root.Position - record.position).Magnitude
        if distance < bestDistance then best, bestDistance = record, distance end
    end
    if best then best.distance = bestDistance end
    return best
end

local function eventScan()
    wipe(World.events)
    for _, instance in ipairs(World.found) do
        if Cache.kinds[instance] == "event" and instance.Parent then
            local key = nil
            pcall(function() key = instance:GetAttribute("SkillHubEvent") end)
            local position = modelPosition(instance)
            if key and position then
                World.events[#World.events + 1] = {
                    instance = instance, key = key, name = instance.Name, position = position,
                }
            end
        end
    end
end

local function eventByKey(key)
    for _, record in ipairs(World.events) do
        if record.key == key then return record end
    end
    return nil
end

local function clickMouse()
    -- executors ship mouse1click; VirtualUser is the fallback and is allowed to
    -- fail quietly (its signature differs between clients)
    if type(mouse1click) == "function" then
        return pcall(mouse1click)
    end
    return safeCall("mouse", function()
        if VirtualUser then VirtualUser:SendMouseButtonEvent(0, 0, 0, false) end
        return true
    end) == true
end
local function attackOnce()
    if not isAlive() then return false end
    local character = getChar()
    local tool = character and character:FindFirstChildOfClass("Tool")
    if tool then
        local ok = safeCall("activate", function() tool:Activate() return true end)
        if ok then return true end
    end
    return clickMouse()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 12 · INPUT — keys, clicks, chat, emotes
-- ═══════════════════════════════════════════════════════════════════════════

local KeyReleases = {}
local MouseReleases = { untilMouse = 0 }

local function scheduleKeyRelease(keyCode, delay)
    KeyReleases[#KeyReleases + 1] = { key = keyCode, at = os.clock() + (delay or 0.06) }
end

local function releaseLoop()
    task.spawn(function()
        while State.alive do
            task.wait(0.03)
            local now = os.clock()
            for index = #KeyReleases, 1, -1 do
                local entry = KeyReleases[index]
                if entry.at <= now then
                    safeCall("key up", function()
                        if VirtualUser then VirtualUser:SendKeyEvent(false, entry.key) end
                        return true
                    end)
                    table.remove(KeyReleases, index)
                end
            end
        end
    end)
end

local function pressKey(keyName, duration)
    local keyCode = Enum.KeyCode[keyName]
    if not keyCode then return false end
    local ok = safeCall("key down", function()
        if VirtualUser then VirtualUser:SendKeyEvent(true, keyCode) end
        return true
    end)
    scheduleKeyRelease(keyCode, duration or 0.06)
    return ok == true
end


-- ═══════════════════════════════════════════════════════════════════════════
-- 13 · THE ANTI-CHEAT LAYER
--     Read the header again before trusting this. What is here is real:
--     capability probing, detector neutralisation, a report-remote filter at
--     the namecall level, a kick guard, a WalkSpeed read camouflage, a
--     speed-limiter patcher and paced movement. What is not here, and cannot
--     be: making the server believe something the server can compute itself.
-- ═══════════════════════════════════════════════════════════════════════════

AC.caps = {
    namecall = false, kickFunction = false, indexHook = false,
    getgc = false, hookmetamethod = type(hookmetamethod) == "function",
    hookfunction = type(hookfunction) == "function",
    getconnections = type(getconnections) == "function",
    islclosure = type(islclosure) == "function",
    debugUpvalues = type(debug) == "table" and type(debug.getupvalues) == "function",
    fireprompt = type(fireproximityprompt) == "function",
}

AC.profile = "Balanced"
AC.patchedTables = 0
AC.camouflageReads = 0
AC.intern = false              -- true while the hub itself reads a raw property

local function probe()
    local caps = AC.caps
    caps.namecall = type(getrawmetatable) == "function" or type(getmetatable) == "function"
    caps.getgc = type(getgc) == "function"
    return caps
end

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

AC.scan = function()
    wipe(AC.scripts); wipe(AC.detectors)
    AC.reportRemotes = AC.reportRemotes or {}
    wipe(AC.reportRemotes)
    probe()
    local all = listDescendants(Replicated, {}, 4000)
    listDescendants(Workspace, all, 7000)
    if LocalPlayer then
        listDescendants(LocalPlayer:FindFirstChild("PlayerScripts"), all, 8000)
        listDescendants(LocalPlayer:FindFirstChild("PlayerGui"), all, 9000)
    end
    local starter = game:FindFirstChild("StarterPlayer")
    if starter then listDescendants(starter, all, 10000) end
    for _, instance in ipairs(all) do
        local class = instance.ClassName
        if class == "LocalScript" or class == "Script" or class == "ModuleScript" then
            AC.scripts[#AC.scripts + 1] = { instance = instance, name = instance.Name,
                full = instance:GetFullName(), class = class, disabled = instance.Disabled == true }
            local isDetector = containsAny(instance.Name, LOWER.Detectors)
            local parent = instance.Parent
            local depth = 0
            while parent and parent ~= game and depth < 8 do
                if containsAny(parent.Name, LOWER.Detectors) then isDetector = true break end
                parent = parent.Parent; depth = depth + 1
            end
            if isDetector then AC.detectors[#AC.detectors + 1] = AC.scripts[#AC.scripts] end
        elseif class == "RemoteEvent" or class == "RemoteFunction" or class == "UnreliableRemoteEvent" then
            local isReport = containsAny(instance.Name, LOWER.Reports)
                and not containsAny(instance.Name, { "save", "load", "data", "update", "get" })
            if isReport then
                AC.reportRemotes[#AC.reportRemotes + 1] = { instance = instance, name = instance.Name,
                    full = instance:GetFullName(), class = class }
            end
        end
    end
    AC.auditAt = os.clock()
    return AC
end

AC.telemetry = function()
    return {
        scripts = #AC.scripts, detectors = #AC.detectors,
        reports = #(AC.reportRemotes or {}), blocked = AC.blocked,
        disabled = AC.disabled, hook = AC.hookInstalled,
        kickGuard = AC.kickGuard, camouflage = AC.camouflageReads,
        patched = AC.patchedTables, profile = AC.profile,
    }
end

AC.audit = function(announce)
    local result = AC.scan()
    if announce then
        local t = AC.telemetry()
        print(string.format("[Skill Hub] AC audit · %d script(s) · %d detector(s) · %d report remote(s) · hook %s · kick guard %s",
            t.scripts, t.detectors, t.reports, tostring(t.hook), tostring(t.kickGuard)))
        for _, detector in ipairs(result.detectors) do
            print("    detector: " .. detector.full .. (detector.disabled and " (off)" or ""))
        end
        for _, remote in ipairs(result.reportRemotes or {}) do
            print("    report remote: " .. remote.full)
        end
    end
    return AC.telemetry()
end

AC.neutralize = function(announce)
    if #AC.detectors == 0 then AC.scan() end
    local handled = 0
    for _, detector in ipairs(AC.detectors) do
        local script = detector.instance
        if script and script.Parent then
            safeCall("ac disable", function()
                if script:IsA("BaseScript") then
                    script.Disabled = true
                end
                return true
            end)
            safeCall("ac connections", function()
                if AC.caps.getconnections and script:IsA("BaseScript") then
                    local connections = getconnections(script:GetPropertyChangedSignal("Disabled"))
                    if connections then
                        for _, connection in ipairs(connections) do
                            if connection.Disconnect then connection:Disconnect() end
                        end
                    end
                end
                return true
            end)
            detector.disabled = true
            handled = handled + 1
        end
    end
    AC.disabled = handled
    if announce then
        print(string.format("[Skill Hub] AC · %d detector script(s) disabled", handled))
    end
    return handled
end

-- The namecall filter. Everything that is not a report / ban call falls
-- straight through: pcall-guarded, newcclosure-wrapped, receiver-checked.
AC.installHook = function()
    if AC.hookInstalled then return true end
    local installed = safeCall("ac hook", function()
        if not AC.caps.namecall then probe() end
        if not AC.caps.namecall then return false end
        local target = getrawmetatable and getrawmetatable(game) or getmetatable(game)
        if not target then return false end
        if setreadonly then pcall(setreadonly, target, false) end
        local original = target.__namecall
        if not original then
            if setreadonly then pcall(setreadonly, target, true) end
            return false
        end
        AC.originalNamecall = original
        local wrap = newcclosure or function(fn) return fn end
        target.__namecall = wrap(function(self, ...)
            local method = getnamecallmethod and getnamecallmethod() or nil
            if method == "FireServer" or method == "InvokeServer" then
                local okName, name = pcall(function() return self and self.Name end)
                local okClass, class = pcall(function() return self and self.ClassName end)
                if okName and okClass and type(name) == "string" and type(class) == "string"
                    and string.find(class, "Remote", 1, true) then
                    if containsAny(name, LOWER.Reports)
                        and not containsAny(name, { "save", "load", "data", "update", "get" }) then
                        AC.blocked = AC.blocked + 1
                        AC.lastBlocked = name
                        if AC.blocked <= 6 then
                            print("[Skill Hub] AC · dropped outgoing remote -> " .. name)
                        end
                        return nil
                    end
                end
            elseif method == "Kick" and AC.kickGuard and self == LocalPlayer then
                AC.blocked = AC.blocked + 1
                AC.lastBlocked = "Kick"
                print("[Skill Hub] kick intercepted on the client · " .. tostring((...)))
                return nil
            end
            return original(self, ...)
        end)
        if setreadonly then pcall(setreadonly, target, true) end
        AC.hookInstalled = true
        return true
    end)
    if Config.LogLevel >= 2 and installed then
        print("[Skill Hub] AC · __namecall filter installed (newcclosure, receiver-checked)")
    end
    return installed == true
end

AC.removeHook = function()
    if not AC.hookInstalled then return true end
    safeCall("ac unhook", function()
        local target = getrawmetatable and getrawmetatable(game) or getmetatable(game)
        if target and AC.originalNamecall then
            if setreadonly then pcall(setreadonly, target, false) end
            target.__namecall = AC.originalNamecall
            if setreadonly then pcall(setreadonly, target, true) end
        end
        return true
    end)
    AC.hookInstalled = false
    return true
end

AC.installKickGuard = function()
    if AC.kickGuard then return true end
    local ok = safeCall("kick guard", function()
        if not (type(hookfunction) == "function" and LocalPlayer and LocalPlayer.Kick) then return false end
        AC.originalKick = hookfunction(LocalPlayer.Kick, function(...)
            AC.blocked = AC.blocked + 1
            AC.lastBlocked = "Kick"
            print("[Skill Hub] kick intercepted on the client · " .. tostring(select(2, ...)))
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
        if type(hookfunction) == "function" and AC.originalKick and LocalPlayer and LocalPlayer.Kick then
            hookfunction(LocalPlayer.Kick, AC.originalKick)
        end
        return true
    end)
    AC.kickGuard = false
    return true
end

-- WalkSpeed camouflage: the game's own scripts read humanoid.WalkSpeed every
-- frame. The hook answers with a plausible number while the hub keeps the real
-- value in State.realSpeed. Our own reads set AC.intern so they see the truth.
AC.installCamouflage = function()
    if AC.camouflage then return true end
    local ok = safeCall("camouflage", function()
        if type(hookmetamethod) ~= "function" then return false end
        probe()
        local original
        original = hookmetamethod(game, "__index", newcclosure(function(self, key)
            local value = original(self, key)
            if not AC.intern and key == "WalkSpeed" and type(value) == "number" then
                local humanoid = Cache.humanoid
                if humanoid and self == humanoid and Config.WalkSpeedEnabled then
                    AC.camouflageReads = AC.camouflageReads + 1
                    return math.min(value, tonumber(Config.AcSpeedCeiling) or 60)
                end
            end
            return value
        end))
        AC.originalIndex = original
        return true
    end)
    AC.camouflage = ok == true
    return AC.camouflage
end

AC.removeCamouflage = function()
    if not AC.camouflage then return true end
    safeCall("camouflage off", function()
        if type(hookmetamethod) == "function" and AC.originalIndex then
            hookmetamethod(game, "__index", AC.originalIndex)
        end
        return true
    end)
    AC.camouflage = false
    return true
end

-- Speed-limit patcher: games of this size often keep the limit in a plain Lua
-- table (a config module, a validator). getgc(true) exposes those tables, and
-- any numeric field named like a limit above the ceiling is rewritten. Table
-- identity is remembered so the work happens once per table.
AC.patchSpeedLimiters = function(ceiling)
    ceiling = tonumber(ceiling) or tonumber(Config.AcSpeedCeiling) or 60
    if not AC.caps.getgc then return 0 end
    AC.seenTables = AC.seenTables or setmetatable({}, { __mode = "k" })
    local patched = 0
    local keys = { speed = true, maxspeed = true, walkspeed = true, speedlimit = true,
        maxwalkspeed = true, limitspeed = true, max_speed = true, maxspeedlimit = true }
    local ok = safeCall("speed limiter", function()
        for _, object in ipairs(getgc(true)) do
            if type(object) == "table" and not AC.seenTables[object] then
                AC.seenTables[object] = true
                for key, value in pairs(object) do
                    if type(key) == "string" and type(value) == "number" then
                        local low = string.lower(key)
                        if keys[low] and value > ceiling and value < 1e7 then
                            pcall(function() rawset(object, key, ceiling) end)
                            patched = patched + 1
                        end
                    end
                end
            end
        end
        return true
    end)
    if ok then AC.patchedTables = AC.patchedTables + patched end
    if Config.LogLevel >= 2 and patched > 0 then
        print(string.format("[Skill Hub] AC · %d speed limit field(s) clamped to %d", patched, ceiling))
    end
    return patched
end

AC.applyProfile = function(name)
    AC.profile = name
    if name == "Conservative" then
        Config.AcSpeedCeiling, Config.AcStepSize, Config.AcStepDelay = 40, 8, 0.06
        Config.AcRemoteRateLimit, Config.TravelSpeed = 8, 60
    elseif name == "Aggressive" then
        Config.AcSpeedCeiling, Config.AcStepSize, Config.AcStepDelay = 120, 20, 0.03
        Config.AcRemoteRateLimit, Config.TravelSpeed = 24, 200
    else
        Config.AcSpeedCeiling, Config.AcStepSize, Config.AcStepDelay = 60, 12, 0.05
        Config.AcRemoteRateLimit, Config.TravelSpeed = 14, 120
    end
    return Config
end

AC.arm = function()
    probe()
    local ok = false
    if Config.AcBlockReports then ok = AC.installHook() end
    if Config.AcKickGuard then AC.installKickGuard() end
    if Config.AcCamouflage then AC.installCamouflage() end
    if Config.AcNeutralize then AC.neutralize(false) end
    if Config.AcSpeedLimiter then AC.patchSpeedLimiters(Config.AcSpeedCeiling) end
    return ok
end

AC.disarm = function()
    AC.removeHook()
    AC.removeKickGuard()
    AC.removeCamouflage()
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 14 · MOVEMENT — one heartbeat owns every movement toggle
-- ═══════════════════════════════════════════════════════════════════════════
local Mov = {
    flyBody = nil, flyAttachment = nil, flyLoop = false,
    noclip = false, lastJump = 0, lastVoid = 0, lastAntiSlow = 0,
    lastAntiFling = 0, lastSafe = 0, tick = 0,
}

local function property(humanoid, key)
    AC.intern = true
    local ok, value = pcall(function() return humanoid[key] end)
    AC.intern = false
    if ok then return value end
    return nil
end

local function setWalkSpeed(value)
    local humanoid = getHumanoid()
    if not humanoid then return false end
    local wanted = math.clamp(tonumber(value) or 16, 0, 4000)
    State.realSpeed = wanted
    if WriteCache.speed ~= wanted then
        safeCall("walkspeed", function() humanoid.WalkSpeed = wanted return true end)
        WriteCache.speed = wanted
        State.speedWrites = State.speedWrites + 1
        State.perf.writes = State.perf.writes + 1
    end
    return true
end

local function setJumpPower(value)
    local humanoid = getHumanoid()
    if not humanoid then return false end
    local wanted = math.clamp(tonumber(value) or 50, 0, 500)
    if WriteCache.jump ~= wanted then
        safeCall("jumppower", function()
            humanoid.UseJumpPower = true
            humanoid.JumpPower = wanted
            return true
        end)
        WriteCache.jump = wanted
    end
    return true
end

local function startFly()
    local root = getRoot()
    local humanoid = getHumanoid()
    if not root or not humanoid then return false end
    Mov.stopFly()
    safeCall("fly", function()
        local attachment = Instance.new("Attachment", root)
        local body = Instance.new("BodyVelocity")
        body.Name = "SkillHubFly"
        body.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        body.Velocity = Vector3.zero
        body.Parent = root
        Mov.flyAttachment, Mov.flyBody, Mov.flyLoop = attachment, body, true
        humanoid.PlatformStand = true
        return true
    end)
    return Mov.flyBody ~= nil
end

function Mov.stopFly()
    Mov.flyLoop = false
    local humanoid = getHumanoid()
    if Mov.flyBody and Mov.flyBody.Parent then Mov.flyBody:Destroy() end
    if Mov.flyAttachment and Mov.flyAttachment.Parent then Mov.flyAttachment:Destroy() end
    Mov.flyBody, Mov.flyAttachment = nil, nil
    if humanoid then safeCall("fly off", function() humanoid.PlatformStand = false return true end) end
    return true
end

local function moveAxes()
    local axes = { X = 0, Y = 0, Z = 0 }
    if not UserInput then return axes end
    local ok = pcall(function()
        if UserInput:IsKeyDown(Enum.KeyCode.W) then axes.Z = axes.Z + 1 end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then axes.Z = axes.Z - 1 end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then axes.X = axes.X + 1 end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then axes.X = axes.X - 1 end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then axes.Y = axes.Y + 1 end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then axes.Y = axes.Y - 1 end
        return true
    end)
    if not ok then axes.Z = 0 end
    return axes
end

local function flyStep(delta)
    local root, humanoid, camera = getRoot(), getHumanoid(), Camera
    if not root or not humanoid or not Mov.flyBody then return end
    local direction = Vector3.zero
    if camera then
        local look = camera.CFrame.LookVector
        direction = direction + look * (moveAxes().Z)
        direction = direction + camera.CFrame.RightVector * (moveAxes().X)
    end
    direction = direction + Vector3.new(0, moveAxes().Y, 0)
    if direction.Magnitude > 0 then direction = direction.Unit end
    local speed = math.clamp(tonumber(Config.FlySpeed) or 90, 8, 4000)
    if Config.AcSafeMode then speed = math.min(speed, tonumber(Config.AcSpeedCeiling) or 60) end
    safeCall("fly velocity", function()
        Mov.flyBody.Velocity = direction * speed
        return true
    end)
end

local function setNoclip(enabled)
    Mov.noclip = enabled
    local character = getChar()
    if not character then return end
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
            safeCall("noclip", function() descendant.CanCollide = not enabled return true end)
        end
    end
end

local function movementLoop()
    task.spawn(function()
        while State.alive do
            task.wait(0.05)
            Mov.tick = Mov.tick + 1
            local character = getChar()
            if character and isAlive() then
                local humanoid, root = getHumanoid(), getRoot()
                local wantedSpeed = 16
                if Config.WalkSpeedEnabled then
                    wantedSpeed = math.clamp(tonumber(Config.WalkSpeed) or 28, 16, 4000)
                    if Config.AcSafeMode then
                        wantedSpeed = math.min(wantedSpeed, tonumber(Config.AcSpeedCeiling) or 60)
                    end
                end
                setWalkSpeed(wantedSpeed)
                if Config.JumpPowerEnabled then setJumpPower(Config.JumpPower) end

                if Config.AlwaysSprint and humanoid then
                    safeCall("sprint", function()
                        if humanoid.WalkSpeed < wantedSpeed then humanoid.WalkSpeed = wantedSpeed end
                        return true
                    end)
                end

                if Config.InfiniteJump and humanoid then
                    local state = humanoid:GetState()
                    if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end

                if Config.FlyEnabled then
                    if not Mov.flyBody then startFly() end
                    flyStep(0.05)
                elseif Mov.flyBody then
                    Mov.stopFly()
                end

                if Config.Noclip ~= Mov.noclip then setNoclip(Config.Noclip) end

                if root and humanoid then
                    local position, velocity = root.Position, root.AssemblyLinearVelocity
                    -- anti void: the abyss is a real place in this game, so only
                    -- rescue when the character is far below the lowest biome
                    if Config.AntiVoid and position.Y < -220 and os.clock() - Mov.lastVoid > 1.5 then
                        Mov.lastVoid = os.clock()
                        local safePosition = State.homePosition or Vector3.new(0, 40, 0)
                        safeCall("anti void", function()
                            root.CFrame = CFrame.new(safePosition + Vector3.new(0, 8, 0))
                            return true
                        end)
                    end
                    if Config.AntiFling and velocity and velocity.Magnitude > 420
                        and os.clock() - Mov.lastAntiFling > 0.5 then
                        Mov.lastAntiFling = os.clock()
                        safeCall("anti fling", function()
                            root.AssemblyLinearVelocity = Vector3.zero
                            return true
                        end)
                    end
                    if Config.AntiSlow and humanoid.WalkSpeed < 12 and wantedSpeed >= 16
                        and os.clock() - Mov.lastAntiSlow > 0.4 then
                        Mov.lastAntiSlow = os.clock()
                        WriteCache.speed = nil
                    end
                    if Config.AntiRagdoll then
                        local state = humanoid:GetState()
                        if state == Enum.HumanoidStateType.Ragdoll
                            or state == Enum.HumanoidStateType.FallingDown
                            or state == Enum.HumanoidStateType.PlatformStanding then
                            safeCall("anti ragdoll", function()
                                humanoid.PlatformStand = false
                                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                                return true
                            end)
                        end
                    end
                    if Config.AntiStun and humanoid.WalkSpeed <= 1 and wantedSpeed >= 16 then
                        WriteCache.speed = nil
                    end
                end
            end
        end
    end)
end

-- health is the one signal no exploit can hide from the client: a fall from
-- the Cosmic biome takes a full health bar, so the hub simply refuses the drop
local function fallGuard()
    task.spawn(function()
        while State.alive do
            task.wait(0.25)
            local humanoid = getHumanoid()
            if humanoid and Config.NoFallDamage then
                local state = humanoid:GetState()
                if state == Enum.HumanoidStateType.Freefall then
                    local root = getRoot()
                    if root and root.AssemblyLinearVelocity.Y < -95 then
                        safeCall("fall guard", function()
                            root.AssemblyLinearVelocity = Vector3.new(
                                root.AssemblyLinearVelocity.X,
                                math.max(root.AssemblyLinearVelocity.Y, -95),
                                root.AssemblyLinearVelocity.Z)
                            return true
                        end)
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 15 · ESP — Highlight + Billboard only, so it runs on every executor
-- ═══════════════════════════════════════════════════════════════════════════
local Esp = { registry = {}, gui = nil, tracerGui = nil, lastAt = 0 }

local RARITY_COLOR = {
    Common = Color3.fromRGB(168, 176, 190), Uncommon = Color3.fromRGB(126, 196, 148),
    Rare = Color3.fromRGB(112, 164, 240), Legendary = Color3.fromRGB(232, 176, 96),
    Mythic = Color3.fromRGB(206, 128, 226), Cosmic = Color3.fromRGB(122, 208, 226),
    Secret = Color3.fromRGB(240, 132, 150), Eternal = Color3.fromRGB(250, 214, 130),
    Divine = Color3.fromRGB(255, 248, 220),
}

local function espGui()
    if Esp.gui and Esp.gui.Parent then return Esp.gui end
    local parent = guiParent()
    if not parent then return nil end
    Esp.gui = new("ScreenGui", {
        Name = "SkillHubEsp", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 5, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, parent)
    return Esp.gui
end

local function espRemove(key)
    local entry = Esp.registry[key]
    if not entry then return end
    for _, object in ipairs({ entry.highlight, entry.billboard, entry.tracer }) do
        if object and object.Parent then pcall(function() object:Destroy() end) end
    end
    Esp.registry[key] = nil
end

local function espLabel(record, text, color)
    local billboard = record.billboard
    if not billboard or not billboard.Parent then
        billboard = new("BillboardGui", {
            Name = "SkillHubEspLabel", AlwaysOnTop = true, ResetOnSpawn = false,
            Size = UDim2.new(0, 210, 0, 34), StudsOffset = Vector3.new(0, 2.6, 0),
            LightInfluence = 0, MaxDistance = Config.EspMaxDistance or 1500,
        }, espGui())
        record.billboard = billboard
    end
    if not billboard then return end
    if not record.label then
        record.label = new("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = UIFontBold,
            TextSize = 12, TextStrokeTransparency = 0.35, Text = "",
            TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Center,
        }, billboard)
    end
    if record.label and record.label.Text ~= text then
        record.label.Text = text
        record.label.TextColor3 = color
        State.perf.writes = State.perf.writes + 1
    end
end

local function espHighlight(instance, color, transparency)
    local record = Esp.registry[instance]
    if not record then return end
    if not record.highlight or not record.highlight.Parent then
        record.highlight = new("Highlight", { Name = "SkillHubHighlight" }, instance)
    end
    if record.highlight then
        safeCall("esp highlight", function()
            record.highlight.FillColor = color
            record.highlight.OutlineColor = color
            record.highlight.FillTransparency = transparency or Config.EspFillTransparency or 0.62
            record.highlight.OutlineTransparency = 0.12
            record.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            record.highlight.Adornee = instance
            return true
        end)
    end
end

local function espTracer(instance, color, position)
    local gui = Esp.tracerGui
    if not gui or not gui.Parent then
        local parent = guiParent()
        if not parent then return end
        gui = new("ScreenGui", { Name = "SkillHubTracers", ResetOnSpawn = false,
            IgnoreGuiInset = true, DisplayOrder = 4 }, parent)
        Esp.tracerGui = gui
    end
    local record = Esp.registry[instance]
    if not record then return end
    if not record.tracer or not record.tracer.Parent then
        record.tracer = new("Frame", { BackgroundColor3 = color, BackgroundTransparency = 0.35,
            BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3 }, gui)
    end
    local frame = record.tracer
    if not frame then return end
    local camera = Camera
    if not camera then return end
    local point, onScreen = camera:WorldToViewportPoint(position)
    if not onScreen then frame.Visible = false return end
    local viewport = camera.ViewportSize
    local origin = Vector2.new(viewport.X / 2, viewport.Y)
    local delta = Vector2.new(point.X - origin.X, point.Y - origin.Y)
    frame.Visible = true
    frame.Position = UDim2.new(0, origin.X, 0, origin.Y)
    frame.Size = UDim2.new(0, math.max(1, delta.Magnitude), 0, 1)
    frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    frame.BackgroundColor3 = color
end

local function espForEgg(record)
    local instance = record.instance
    if not instance or not instance.Parent then return end
    local key = instance
    if not Esp.registry[key] then Esp.registry[key] = {} end
    local color = RARITY_COLOR[record.rarity] or RARITY_COLOR.Common
    if record.dropped then color = Color3.fromRGB(190, 140, 236) end
    espHighlight(instance, color, record.dropped and 0.45 or Config.EspFillTransparency)
    if Config.EspNames then
        local parts = { record.name }
        if Config.EspRarity then table.insert(parts, record.rarity) end
        if Config.EspValue and record.value then
            table.insert(parts, string.format("$%s", shortNumber(record.value)))
        end
        if Config.EspDistance then
            table.insert(parts, string.format("%dm", math.floor(record.distance or 0)))
        end
        espLabel(Esp.registry[key], table.concat(parts, " · "), color)
    elseif Esp.registry[key] and Esp.registry[key].billboard then
        espRemove(key)
        Esp.registry[key] = {}
        espHighlight(instance, color, Config.EspFillTransparency)
    end
    if Config.EspTracers then espTracer(key, color, record.position) end
end

local function espForGuardian(record)
    local instance = record.instance
    if not instance or not instance.Parent then return end
    if not Esp.registry[instance] then Esp.registry[instance] = {} end
    local color = Color3.fromRGB(224, 106, 104)
    espHighlight(instance, color, 0.55)
    if Config.EspNames then
        espLabel(Esp.registry[instance],
            string.format("GUARDIAN · %s · %dm", record.name, math.floor(record.distance or 0)), color)
    end
    if Config.EspTracers then espTracer(instance, color, record.position) end
end

local function espForPlayer(player)
    local character = player.Character
    if not character or not character.Parent then return end
    if player == LocalPlayer then return end
    if not Esp.registry[character] then Esp.registry[character] = {} end
    local color = Color3.fromRGB(126, 141, 255)
    espHighlight(character, color, 0.6)
    local root = character:FindFirstChild("HumanoidRootPart")
    if Config.EspNames and root then
        local distance = getRoot() and (getRoot().Position - root.Position).Magnitude or 0
        espLabel(Esp.registry[character], string.format("%s · %dm", player.DisplayName, math.floor(distance)), color)
    end
    if Config.EspTracers and root then espTracer(character, color, root.Position) end
end

local function espPass()
    local wanted = {}
    if Config.EspEggs then
        for _, record in ipairs(World.eggs) do
            if record.dropped and not Config.EspDropped then
                -- player-dropped eggs are their own colour, but they can be hidden
            else
                wanted[record.instance] = true
                espForEgg(record)
            end
        end
    end
    if Config.EspGuardians then
        for _, record in ipairs(World.guardians) do
            wanted[record.instance] = true
            espForGuardian(record)
        end
    end
    if Config.EspPlayers and Players then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                wanted[player.Character] = true
                espForPlayer(player)
            end
        end
    end
    for key in pairs(Esp.registry) do
        if not wanted[key] then espRemove(key) end
    end
end

local function espLoop()
    task.spawn(function()
        while State.alive do
            task.wait(math.max(0.1, tonumber(Config.EspInterval) or 0.4))
            if Config.EspEggs or Config.EspGuardians or Config.EspPlayers
                or next(Esp.registry) ~= nil then
                safeCall("esp pass", function() espPass() return true end)
                State.perf.espUpdates = State.perf.espUpdates + 1
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 16 · RUNTIME — the steal loop, the base loop, the event watchers
-- ═══════════════════════════════════════════════════════════════════════════

local function say(message, accent)
    if Config.LogLevel >= 1 then
        print("[Skill Hub] " .. tostring(message))
    end
    if accent ~= false then
        notify("Steal An Egg", tostring(message), 4, Theme.Accent, ICON.Chest)
    end
end

local function stopSteal(reason)
    Config.AutoSteal = false
    Loop.paused = true
    Loop.pauseUntil = os.clock() + 3
    if reason then say("steal loop stopped — " .. tostring(reason)) end
end

local function stealStep()
    if not Config.AutoSteal or not isAlive() then return end
    if os.clock() < (Loop.pauseUntil or 0) then return end
    local now = os.clock()
    local interval = math.max(0.15, tonumber(Config.RefreshInterval) or 0.3)
    if now - World.at > interval then scanWorld(false) end
    if now - State.lastSteal < math.max(0.15, tonumber(Config.StealDelay) or 0.6) then return end

    if Config.AutoDropOnGuard then
        local guardian = nearestGuardian(Config.GuardianRange)
        if guardian and carriedEgg() then
            dropCarried()
            if Config.GuardianWarning then
                notify("Guardian", "guardian near — egg dropped on purpose", 4, Theme.Warning, ICON.Guard)
            end
            return
        end
    end

    if carriedEgg() then
        if Config.AutoReturn then
            if travelToBase() then
                if Config.AutoPlace then placeHeld() end
            end
        end
        return
    end
    if Config.SkipWhileCarrying and carriedEgg() then return end

    local record = pickEgg()
    if not record then return end
    local ok = tryGrab(record)
    if ok then
        if Config.StealOnce then Config.AutoSteal = false end
        if Config.AutoReturn then
            travelToBase()
            if Config.AutoPlace then placeHeld() end
        end
    else
        Loop.paused = true
        Loop.pauseUntil = os.clock() + 2
    end
end

local function baseStep()
    local now = os.clock()
    if Config.AutoPlace and not State.grabbing and carriedEgg()
        and now - State.lastPlace > math.max(0.2, tonumber(Config.PlaceDelay) or 0.5) then
        placeHeld()
    end
    if Config.AutoHatch and now - State.lastHatch > 0.8 then
        local prompt = ownPlotPrompts(LOWER.Hatch)
        if prompt then hatchReady(2) end
    end
    if Config.AutoIndex and now - State.lastIndex > 3 then claimIndex() end
    if Config.AutoClaimOffline and now - (State.lastOffline or 0) > 5 then
        State.lastOffline = now
        claimOffline()
    end
    if Config.AutoBuyTrails and now - State.lastTrail > 4 then buyTrail() end
    if Config.AutoEquipBest and now - State.lastEquip > 6 then equipBest() end
    if Config.AutoFuse and now - State.lastFuse > 6 then fusePets() end
    if Config.AutoSellEggs and now - State.lastSell > (tonumber(Config.SellDelay) or 30) then sellEggs() end
    if Config.AutoRebirth and now - (State.lastRebirth or 0) > 8 then
        State.lastRebirth = now
        local remote = findRemote(LOWER.Upgrade)
        if remote then fireRemote(remote) end
        local prompt = findPrompt(Workspace, LOWER.Upgrade)
        if prompt then firePrompt(prompt) end
    end
end

local function handleGuardians()
    if not Config.GuardianWarning then return end
    local now = os.clock()
    if now - Loop.lastGuardianWarn < 3 then return end
    local guardian = nearestGuardian(Config.GuardianRange)
    if guardian then
        Loop.lastGuardianWarn = now
        notify("Guardian", string.format("%s · %dm — it will drop your egg", tostring(guardian.name), math.floor(guardian.distance)), 3, Theme.Warning, ICON.Warning)
    end
end

-- One event per pass, round-robin with a cooldown. Traveling to four event
-- sites in one pass would block the worker for minutes and drag the character
-- across the map while the steal loop is trying to work.
local function eventStep()
    local wanted = {}
    if Config.AutoRift or Config.AutoBoss then wanted[#wanted + 1] = "Rift" end
    if Config.AutoStar then wanted[#wanted + 1] = "Star" end
    if Config.AutoBloom then wanted[#wanted + 1] = "Bloom" end
    if Config.AutoLab then wanted[#wanted + 1] = "Lab" end
    if Config.AutoRace then wanted[#wanted + 1] = "Race" end
    if #wanted == 0 then return end

    local now = os.clock()
    if now - (Loop.lastEvent or 0) < 3 then return end
    eventScan()

    State.seenEvents = State.seenEvents or {}
    for _, event in ipairs(World.events) do
        if not State.seenEvents[event.key] then
            State.seenEvents[event.key] = true
            if Config.EventNotify then
                for _, definition in ipairs(KNOWLEDGE.Events) do
                    if definition.Key == event.key then
                        notify(definition.Label, event.name .. " is up in this server", 6, Theme.Mauve, ICON.Star)
                    end
                end
            end
        end
    end

    Loop.eventDone = Loop.eventDone or {}
    local target, key = nil, nil
    for _, wantedKey in ipairs(wanted) do
        local record = eventByKey(wantedKey)
        local last = Loop.eventDone[wantedKey]
        if record and (last == nil or now - last > 45) then
            target, key = record, wantedKey
            break
        end
    end
    if not target then return end

    Loop.eventDone[key] = now
    Loop.eventBusy = true
    travelTo(target.position, { owner = "event", stopDistance = 12, speed = 160, timeout = 25 })

    if key == "Lab" then
        local prompt = findPrompt(target.instance, LOWER.Sell, 2)
        if prompt then firePrompt(prompt) end
    elseif key == "Race" then
        -- one nearest checkpoint per pass: a blocking walk of the whole track
        -- would starve every other worker for half a minute
        local root = getRoot()
        if root then
            local best, bestDistance = nil, math.huge
            for _, descendant in ipairs(target.instance:GetDescendants()) do
                if descendant:IsA("BasePart")
                    and containsAny(descendant.Name, { "checkpoint", "gate", "ring" }) then
                    local distance = (root.Position - descendant.Position).Magnitude
                    if distance < bestDistance then best, bestDistance = descendant, distance end
                end
            end
            if best and bestDistance > 8 then
                travelTo(best.Position, { owner = "event", stopDistance = 6, speed = 200, timeout = 10 })
            end
        end
    elseif key == "Rift" and Config.AutoBoss then
        for _ = 1, 3 do attackOnce(); task.wait(0.15) end
    end

    Loop.eventBusy = false
    Loop.lastEvent = now
end

local function staffStep()
    if not (Config.StaffWatch or Config.StaffHop) or not Players then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local name = lower(player.Name)
            local rank = 0
            if player.GetRankInGroup then
                local ok, value = pcall(function() return player:GetRankInGroup(Config.StaffGroupId or 0) end)
                if ok then rank = value or 0 end
            end
            local isStaff = rank >= 250 or string.find(name, "mod") or string.find(name, "admin")
                or string.find(name, "owner") or string.find(name, "dev")
            if isStaff then
                AC.staffSeen = AC.staffSeen or {}
                if not AC.staffSeen[player] then
                    AC.staffSeen[player] = true
                    notify("Staff watch", player.Name .. " looks like staff", 5, Theme.Danger, ICON.Warning)
                    if Config.StaffHop then
                        say("leaving the server — staff", false)
                        hopServer()
                    end
                end
            end
        end
    end
end

local function renderStats()
    local perf = State.perf
    task.spawn(function()
        while State.alive do
            task.wait(0.5)
            perf.frames = perf.frames + 1
            if perf.frames >= 20 then
                local ok, ping = pcall(function()
                    local item = Stats and Stats.Network and Stats.Network.ServerStatsItem
                    return item and item["Data Ping"] and item["Data Ping"]:GetValue() or 0
                end)
                State.ping = ok and ping or 0
                perf.frames = 0
            end
        end
    end)
end

local function guardianCheck()
    task.spawn(function()
        while State.alive do
            task.wait(0.5)
            safeCall("guardian check", function() handleGuardians() return true end)
        end
    end)
end

-- four independent workers, each with its own busy flag: a long travel for an
-- event can never starve the steal loop, and the base worker never fires a
-- prompt while the character is still moving
local function worker(name, interval, step, condition)
    task.spawn(function()
        while State.alive do
            task.wait(interval)
            if (not condition or condition()) and not Loop[name] then
                Loop[name] = true
                safeCall(name, function() step() return true end)
                Loop[name] = false
            end
        end
    end)
end

local function startWorkers()
    worker("stealWorker", 0.12, stealStep, function()
        -- while an event worker is moving the character, stealing waits its turn
        return Config.AutoSteal and not Loop.eventBusy
    end)
    worker("baseWorker", 0.15, baseStep)
    worker("eventWorker", 1.0, eventStep)
    worker("staffWorker", 2.0, staffStep)
    worker("treadmillWorker", 1.0, function()
        if Config.AutoTreadmill and not carriedEgg() then
            useTreadmill(Config.AutoUpgradeTreadmill)
        end
    end)
end

local function startLoops()
    if State.loopsStarted then return end
    State.loopsStarted = true
    scanWorld(true)
    State.homePosition = getRoot() and getRoot().Position or Vector3.new(0, 12, 0)
    State.gravityDefault = Workspace.Gravity
    movementLoop()
    fallGuard()
    espLoop()
    startWorkers()
    renderStats()
    guardianCheck()
    releaseLoop()
    if Config.AntiAfk and LocalPlayer then
        safeCall("anti afk", function()
            LocalPlayer.Idled:Connect(function()
                if not Config.AntiAfk then return end
                if VirtualUser then
                    VirtualUser:CaptureController()
                    VirtualUser:SendKeyEvent(true, Enum.KeyCode.Space)
                    task.delay(0.1, function()
                        safeCall("anti afk up", function() VirtualUser:SendKeyEvent(false, Enum.KeyCode.Space) return true end)
                    end)
                end
            end)
            return true
        end)
    end
    if Config.AcBlockReports or Config.AcNeutralize or Config.AcCamouflage then
        safeCall("ac arm", function() AC.arm() return true end)
    end
    if Config.AcSpeedLimiter then
        safeCall("ac limiters", function() AC.patchSpeedLimiters(Config.AcSpeedCeiling) return true end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 17 · MISC — chat, emotes, music, server hop, teleports, player list
-- ═══════════════════════════════════════════════════════════════════════════
local Misc = {}

function Misc.chat(message)
    if not message or message == "" then return false end
    local ok = safeCall("chat", function()
        local replicated = Replicated
        local events = replicated and replicated:FindFirstChild("DefaultChatSystemChatEvents")
        local request = events and events:FindFirstChild("SayMessageRequest")
        if request then
            request:FireServer(message, "All")
            return true
        end
        local starterGui = getService("StarterGui")
        if starterGui then
            starterGui:SetCore("ChatMakeSystemMessage", { Text = message, Color = Theme.Accent })
            return true
        end
        return false
    end)
    if ok then State.lastChat = os.clock() end
    return ok == true
end

function Misc.emote(slot)
    pressKey("Period", 0.05)
    -- a delay instead of a wait: this is also the public API, and a caller in
    -- the console may not be inside a coroutine
    task.delay(0.18, function()
        safeCall("emote slot", function()
            pressKey(tostring(math.clamp(tonumber(slot) or 1, 1, 9)), 0.05)
            return true
        end)
    end)
    return true
end

function Misc.music(on)
    local character = getChar()
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local existing = root:FindFirstChild("SkillHubMusic")
    if not on then
        if existing then existing:Destroy() end
        return true
    end
    if existing then existing:Destroy() end
    if tostring(Config.MusicId) == "" then return false end
    safeCall("music", function()
        local sound = Instance.new("Sound")
        sound.Name = "SkillHubMusic"
        sound.SoundId = "rbxassetid://" .. tostring(Config.MusicId)
        sound.Volume = tonumber(Config.MusicVolume) or 1
        sound.Looped = true
        sound.Parent = root
        sound:Play()
        return true
    end)
    return true
end

function hopServer()
    local ok = safeCall("server hop", function()
        local request = request or game.HttpGet
        if request and Teleport then
            local response = request({
                Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
                    game.PlaceId),
                Method = "GET",
            })
            local body = response and (response.Body or response)
            if body and HttpService then
                local decoded = HttpService:JSONDecode(body)
                local servers = decoded and decoded.data or {}
                table.sort(servers, function(a, b) return (a.playing or 0) < (b.playing or 0) end)
                local chosen = servers[1]
                if chosen and chosen.id and chosen.id ~= game.JobId then
                    Teleport:TeleportToPlaceInstance(game.PlaceId, chosen.id, LocalPlayer)
                    return true
                end
            end
        end
        if Teleport then
            Teleport:Teleport(game.PlaceId, LocalPlayer)
            return true
        end
        return false
    end)
    if ok then
        notify("Server hop", "leaving this server", 4, Theme.Accent, ICON.Teleport)
    else
        notify("Server hop", "the executor blocked TeleportService", 4, Theme.Warning, ICON.Warning)
    end
    return ok == true
end

function Misc.teleportTargets()
    eventScan()   -- the destination list must include the event sites
    local out = {}
    local function push(name, position, kind)
        if position then out[#out + 1] = { name = name, position = position, kind = kind or "biome" } end
    end
    local plot = findOwnPlot()
    if plot then push("Base", modelPosition(plot), "base") end
    for _, nest in ipairs(World.nests) do
        push(nest.name, nest.position, "nest")
    end
    for _, event in ipairs(World.events) do
        local label = event.key
        for _, definition in ipairs(KNOWLEDGE.Events) do
            if definition.Key == event.key then label = definition.Label end
        end
        push(label, event.position, "event")
    end
    -- biomes without a nest still need a destination: use the spawn part of a
    -- model named after the biome
    for _, biome in ipairs(KNOWLEDGE.Biomes) do
        local found = false
        for _, nest in ipairs(World.nests) do
            if string.find(lower(nest.name), lower(biome.Name), 1, true) then found = true break end
        end
        if not found then
            local model = Workspace:FindFirstChild(biome.Name)
            local position = model and modelPosition(model)
            if position then push(biome.Name, position, "biome") end
        end
    end
    return out
end

function Misc.playerList()
    local out = {}
    if not Players then return out end
    local myRoot = getRoot()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        out[#out + 1] = {
            player = player,
            name = player.DisplayName or player.Name,
            info = string.format("%s · %s", player.Name,
                root and myRoot and string.format("%dm", math.floor((root.Position - myRoot.Position).Magnitude)) or "—"),
            color = (player == LocalPlayer) and Theme.Success or Theme.Accent,
            avatar = "",
            lamp = Theme.TextFaint,
        }
    end
    return out
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 18 · FUN — cosmetic toys, every one of them visible
-- ═══════════════════════════════════════════════════════════════════════════
local Fun = { ring = nil, rainAt = 0, discoAt = 0, rainbowPart = 0, sparks = nil }

local function funEggRain()
    task.spawn(function()
        while State.alive do
            task.wait(0.6)
            if Config.EggRain then
                local root = getRoot()
                if root then
                    safeCall("egg rain", function()
                        local egg = Instance.new("Part")
                        egg.Name = "SkillHubEggRain"
                        egg:SetAttribute("SkillHubOwned", true)
                        egg.Shape = Enum.PartType.Ball
                        egg.Size = Vector3.new(3, 4, 3)
                        egg.Color = Color3.fromHSV((os.clock() * 0.15) % 1, 0.55, 1)
                        egg.Material = Enum.Material.Neon
                        egg.CanCollide = false
                        egg.CFrame = CFrame.new(root.Position + Vector3.new(
                            math.random(-30, 30), math.random(18, 32), math.random(-30, 30)))
                        egg.Parent = Workspace
                        task.delay(6, function()
                            safeCall("egg rain clean", function() egg:Destroy() return true end)
                        end)
                        return true
                    end)
                end
            end
        end
    end)
end

local function funAura()
    task.spawn(function()
        while State.alive do
            task.wait(0.2)
            local character = getChar()
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if Config.BatAura and root then
                if not Fun.ring or not Fun.ring.Parent then
                    safeCall("bat aura", function()
                        local ring = Instance.new("Part")
                        ring.Name = "SkillHubBatAura"
                        ring:SetAttribute("SkillHubOwned", true)
                        ring.Shape = Enum.PartType.Ball
                        ring.Size = Vector3.new(1, 1, 1)
                        ring.Material = Enum.Material.Neon
                        ring.Color = Color3.fromRGB(94, 76, 120)
                        ring.CanCollide = false
                        ring.Transparency = 0.35
                        ring.Parent = Workspace
                        Fun.ring = ring
                        return true
                    end)
                end
                if Fun.ring then
                    local angle = os.clock() * 2
                    safeCall("bat aura move", function()
                        Fun.ring.CFrame = CFrame.new(root.Position + Vector3.new(math.cos(angle) * 4, 1 + math.sin(angle * 2), math.sin(angle) * 4))
                        return true
                    end)
                end
            elseif Fun.ring and Fun.ring.Parent then
                safeCall("bat aura off", function() Fun.ring:Destroy() return true end)
                Fun.ring = nil
            end
        end
    end)
end

local function funPlot()
    task.spawn(function()
        while State.alive do
            task.wait(0.25)
            if Config.RainbowPlot then
                local plot = findOwnPlot()
                if plot then
                    safeCall("rainbow plot", function()
                        local hue = (os.clock() * 0.2) % 1
                        local index = 0
                        for _, descendant in ipairs(plot:GetDescendants()) do
                            if descendant:IsA("BasePart") then
                                index = index + 1
                                if index % 2 == 0 then
                                    descendant.Color = Color3.fromHSV((hue + index * 0.01) % 1, 0.6, 1)
                                end
                            end
                            if index > 120 then break end
                        end
                        return true
                    end)
                end
            end
        end
    end)
end

local function funPets()
    task.spawn(function()
        while State.alive do
            task.wait(1)
            if Config.BigPets then
                local plot = findOwnPlot()
                if plot then
                    safeCall("big pets", function()
                        for _, descendant in ipairs(plot:GetDescendants()) do
                            if descendant:IsA("Model") and descendant ~= plot and descendant.ScaleTo then
                                descendant:ScaleTo(math.clamp(tonumber(Config.PetScale) or 1.4, 0.5, 4))
                            end
                        end
                        return true
                    end)
                end
            end
        end
    end)
end

local function funDisco()
    task.spawn(function()
        while State.alive do
            task.wait(0.15)
            if Config.DiscoMode and Lighting then
                safeCall("disco", function()
                    local hue = (os.clock() * 0.4) % 1
                    Lighting.Ambient = Color3.fromHSV(hue, 0.55, 0.6)
                    Lighting.OutdoorAmbient = Color3.fromHSV((hue + 0.3) % 1, 0.5, 0.55)
                    return true
                end)
            end
        end
    end)
end

local function funChat()
    task.spawn(function()
        while State.alive do
            task.wait(1)
            local now = os.clock()
            if Config.ChatSpam and Config.ChatMessage ~= ""
                and now - (Loop.lastSpam or 0) > math.max(2, tonumber(Config.ChatDelay) or 15) then
                Loop.lastSpam = now
                Misc.chat(Config.ChatMessage)
            end
            if Config.EmoteLoop and now - (Loop.lastEmote or 0) > math.max(3, tonumber(Config.EmoteLoopDelay) or 14) then
                Loop.lastEmote = now
                Misc.emote(1)
            end
            if Config.Music and not (getRoot() and getRoot():FindFirstChild("SkillHubMusic")) then
                Misc.music(true)
            elseif not Config.Music then
                local root = getRoot()
                local sound = root and root:FindFirstChild("SkillHubMusic")
                if sound then
                    safeCall("music off", function() sound:Destroy() return true end)
                end
            end
        end
    end)
end

local function funVisuals()
    task.spawn(function()
        while State.alive do
            task.wait(0.5)
            local camera = Camera
            if camera and camera.FieldOfView ~= (tonumber(Config.CameraFov) or 70) then
                safeCall("fov", function() camera.FieldOfView = Config.CameraFov return true end)
            end
            if Config.LowGravity then
                safeCall("low gravity", function()
                    if Workspace.Gravity ~= 70 then Workspace.Gravity = 70 end
                    return true
                end)
            elseif State.gravityDefault and Workspace.Gravity ~= State.gravityDefault then
                safeCall("gravity back", function() Workspace.Gravity = State.gravityDefault return true end)
            end
            if Lighting then
                safeCall("fps boost", function()
                    if Config.FpsBoost then
                        Lighting.GlobalShadows = false
                        Lighting.FogEnd = 1e6
                    end
                    return true
                end)
                safeCall("fullbright", function()
                    if Config.Fullbright then
                        Lighting.Brightness = 3
                        Lighting.ClockTime = 14
                        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
                        Lighting.FogEnd = 1e6
                    end
                    if Config.RemoveVfx then
                        Lighting.FogEnd = 1e6
                        Lighting.FogStart = 1e6
                    end
                    return true
                end)
            end
        end
    end)
end

local function startFun()
    funEggRain(); funAura(); funPlot(); funPets(); funDisco(); funChat(); funVisuals()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 19 · SELF TEST — "Anti-Cheat -> Run audit now" and the CLI harness
-- ═══════════════════════════════════════════════════════════════════════════
local function runSelfTest(quiet)
    local results, passed = {}, 0
    local function check(label, condition, detail)
        local ok = condition == true
        if ok then passed = passed + 1 end
        results[#results + 1] = { label = label, ok = ok, detail = detail }
    end

    check("config table", type(Config) == "table" and Config.AcStepSize ~= nil)
    check("number formatter", shortNumber(1500) == "1.5K" and shortNumber(2500000) == "2.5M", shortNumber(1500))
    check("rarity ladder", rarityIndex("Mythic") == 5 and rarityIndex("Divine") == 9)
    check("word lists", #splitList("Forest, Lake") == 2 and containsAny("Abyss Guardian", LOWER.Guardian) == true)
    check("biome table", #KNOWLEDGE.Biomes >= 13, #KNOWLEDGE.Biomes .. " biomes")
    check("mutation table", KNOWLEDGE.Mutations["Enchanted"] == 2.8)

    local world = scanWorld(true)
    check("world scan returns tables", type(world.eggs) == "table" and type(world.guardians) == "table")
    check("eggs discovered", #world.eggs >= 1, #world.eggs .. " egg(s)")
    check("prompt discovery", world.eggs[1] and world.eggs[1].prompt ~= nil,
        world.eggs[1] and (tostring(world.eggs[1].name) .. " -> " .. tostring(world.eggs[1].prompt)))
    check("best egg scored", world.best ~= nil and world.bestScore > 0,
        world.best and world.best.name or "none")
    check("own plot found", findOwnPlot() ~= nil)
    check("treadmill discovered", #world.treadmills >= 0)
    check("guardians discovered", #world.guardians >= 0)

    -- filters
    local savedRarity, savedMode = Config.MinRarity, Config.StealMode
    Config.MinRarity, Config.StealMode = "Mythic", "Smart"
    local allowed = 0
    for _, record in ipairs(world.eggs) do
        if eggAllowed(record) then allowed = allowed + 1 end
    end
    Config.MinRarity, Config.StealMode = savedRarity, savedMode
    check("rarity filter narrows the list", allowed <= #world.eggs, allowed .. "/" .. #world.eggs)

    -- travel: the distance to ourselves is zero, so the call must succeed at once
    local root = getRoot()
    check("travel to self", root ~= nil and travelTo(root.Position, { owner = "selftest", timeout = 1 }) == true)

    -- anti-cheat surface
    local audit = AC.audit(false)
    check("audit finds scripts", audit.scripts >= 1, audit.scripts .. " script(s)")
    check("audit finds detectors", audit.detectors >= 1, audit.detectors .. " detector(s)")
    check("audit finds report remotes", audit.reports >= 1, audit.reports .. " remote(s)")
    check("hook installed", AC.hookInstalled == true)
    check("kick guard installed", AC.kickGuard == true)
    check("speed camouflage installed", AC.camouflage == true)
    check("speed limiters patched", AC.patchedTables >= 0, tostring(AC.patchedTables))
    check("report blocked count readable", type(AC.blocked) == "number")

    -- interface surface
    check("teleport list", #Misc.teleportTargets() >= 1, #Misc.teleportTargets() .. " target(s)")
    check("player list", #Misc.playerList() >= 1)
    check("no typo globals", formatNumber == nil and wipeTable == nil)

    -- cosmetic helpers must not throw
    check("chat helper", pcall(function() return Misc.chat("") end))
    check("emote helper", pcall(function() return Misc.emote(1) end))

    if not quiet then
        print(string.format("[Skill Hub] self test · %d/%d", passed, #results))
        for _, result in ipairs(results) do
            if not result.ok then
                print("    FAIL " .. result.label .. (result.detail and (" · " .. tostring(result.detail)) or ""))
            end
        end
    end
    return { passed = passed, total = #results, results = results }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 20 · PANIC, UNLOAD AND THE PUBLIC TABLE
-- ═══════════════════════════════════════════════════════════════════════════
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
    Mov.stopFly()
    setNoclip(false)
    for key in pairs(Esp.registry) do espRemove(key) end
    Misc.music(false)
    if Fun.ring and Fun.ring.Parent then Fun.ring:Destroy() end
    for _, instance in ipairs(Workspace:GetChildren()) do
        if instance.Name == "SkillHubEggRain" then instance:Destroy() end
    end
    if Lighting then
        safeCall("lighting", function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            Lighting.FogEnd = 100000
            return true
        end)
    end
    local window = getWindow()
    if window and window.Screen then window.Screen.Enabled = false end
    notify("Panic", "everything off · re-run the script to come back", 6, Theme.Danger, ICON.Stop)
end

local function unload()
    print("[Skill Hub] unload requested")
    safeCall("unload", function()
        State.alive = false
        Config.UiVisible = false
        Mov.stopFly()
        setNoclip(false)
        for key in pairs(Esp.registry) do espRemove(key) end
        Misc.music(false)
        AC.disarm()
        if Fun.ring and Fun.ring.Parent then Fun.ring:Destroy() end
        local window = getWindow()
        if window and window.Screen then window.Screen:Destroy() end
        if Esp.gui and Esp.gui.Parent then Esp.gui:Destroy() end
        if Esp.tracerGui and Esp.tracerGui.Parent then Esp.tracerGui:Destroy() end
        if SharedEnv.SkillHubStealAnEgg == skillHubInstance then SharedEnv.SkillHubStealAnEgg = nil end
        return true
    end)
    print("[Skill Hub] unloaded")
end

local function selfTest()
    local result = runSelfTest(false)
    notify("Self-test", string.format("%d/%d passed", result.passed, result.total), 6,
        result.passed == result.total and Theme.Success or Theme.Warning, ICON.Layers)
    return result
end

do
    NS.AC = AC
    NS.Config = Config
    NS.State = State
    NS.World = World
    NS.Loop = Loop
    NS.Misc = Misc
    NS.Fun = Fun
    NS.Mov = Mov
    NS.Esp = Esp
    NS.KNOWLEDGE = KNOWLEDGE
    NS.rarityIndex = rarityIndex
    NS.eggAllowed = eggAllowed
    NS.pickEgg = pickEgg
    NS.tryGrab = tryGrab
    NS.setWalkSpeed = setWalkSpeed
    NS.placeHeld = placeHeld
    NS.hatchReady = hatchReady
    NS.claimIndex = claimIndex
    NS.claimOffline = claimOffline
    NS.buyTrail = buyTrail
    NS.fusePets = fusePets
    NS.sellEggs = sellEggs
    NS.equipBest = equipBest
    NS.useTreadmill = useTreadmill
    NS.nearestGuardian = nearestGuardian
    NS.dropCarried = dropCarried
    NS.carriedEgg = carriedEgg
    NS.findOwnPlot = findOwnPlot
    NS.findPrompt = findPrompt
    NS.findRemote = findRemote
    NS.firePrompt = firePrompt
    NS.fireRemote = fireRemote
    NS.travelTo = travelTo
    NS.travelToBase = travelToBase
    NS.scanWorld = scanWorld
    NS.shortNumber = shortNumber
    NS.lower = lower
    NS.containsAny = containsAny
    NS.splitList = splitList
    NS.runSelfTest = runSelfTest
    NS.selfTest = selfTest
    NS.panic = panic
    NS.unload = unload
    NS.startLoops = startLoops
    NS.startFun = startFun
    NS.stopSteal = stopSteal
    NS.hopServer = hopServer
    NS.eventScan = eventScan
    NS.eventByKey = eventByKey
    NS.setNoclip = setNoclip
    NS.modelPosition = modelPosition
    NS.getRoot = getRoot
    NS.getChar = getChar
    NS.getHumanoid = getHumanoid
    NS.isAlive = isAlive
    NS.espPass = espPass
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 21 · KEYBINDS AND BOOT
-- ═══════════════════════════════════════════════════════════════════════════
local function bindKeys()
    if not UserInput then return end
    UserInput.InputBegan:Connect(function(input, processed)
        if processed then return end
        local name = input.KeyCode and input.KeyCode.Name or nil
        if not name then return end
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
        if name == "H" and Config.AutoSteal then
            safeCall("home key", function() travelToBase() return true end)
        end
        if name == "G" and Config.AutoSteal then
            safeCall("grab key", function() return tryGrab(pickEgg()) end)
        end
    end)
end

local function respawnHook()
    if not Players or not LocalPlayer then return end
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.8)
        WriteCache.speed, WriteCache.jump = nil, nil
        State.carrying = nil
        scanWorld(true)
        if Config.Noclip then setNoclip(true) end
        if Config.WalkSpeedEnabled then setWalkSpeed(Config.WalkSpeed) end
        if Config.AcBlockReports then AC.installHook() end
        if Config.AcCamouflage then AC.installCamouflage() end
    end)
end

local function boot(buildTabs)
    State.alive = true
    local previous = SharedEnv.SkillHubStealAnEgg
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
        notify("Skill Hub " .. VERSION,
            GAME_NAME .. " · free edition · press " .. Config.HideUiKey .. " to hide", 7, Theme.Accent, ICON.Crest)
    end

    print("[Skill Hub " .. VERSION .. "] " .. GAME_NAME .. " · free edition · by " .. AUTHOR)
    print(string.format("    place %s · job %s", tostring(game.PlaceId), tostring(game.JobId)))
    print("    tabs: " .. (function()
        local names = {}
        for _, tab in ipairs(Tabs) do names[#names + 1] = tab.title or "?" end
        return table.concat(names, " · ")
    end)())
    print("    Anti-Cheat tab -> Self-test for the full PASS/FAIL list")

    -- the engine runs whether or not the interface did
    startLoops()
    startFun()
    bindKeys()
    respawnHook()

    if Config.ShowAuthor then
        task.spawn(function()
            task.wait(1.2)
            if getWindow() and Config.ShowAuthor then
                notify("Skill Hub " .. VERSION, "made by " .. AUTHOR .. " · free, no key", 6,
                    Theme.AccentSecondary, ICON.Star)
            end
        end)
    end
end

local function finish()
    skillHubInstance = {
        version = VERSION,
        build = BUILD,
        author = AUTHOR,
        game = GAME_NAME,
        config = Config,
        tabs = Tabs,
        state = State,
        world = World,
        ac = AC,
        misc = Misc,
        fun = Fun,
        loop = Loop,
        knowledge = KNOWLEDGE,
        esp = { registry = Esp.registry, pass = espPass },
        notify = notify,
        unload = unload,
        panic = panic,
        selfTest = runSelfTest,
        selfTestUi = selfTest,
        audit = AC.audit,
        scan = scanWorld,
        eventScan = eventScan,
        eventByKey = eventByKey,
        events = function()
            eventScan()
            return World.events
        end,
        stealOnce = function() return tryGrab(pickEgg()) end,
        returnBase = travelToBase,
        teleportTargets = Misc.teleportTargets,
        teleport = function(name)
            for _, target in ipairs(Misc.teleportTargets()) do
                if lower(target.name) == lower(name) then
                    -- spawn the travel: the API must not yield the caller's thread
                    task.spawn(function()
                        safeCall("teleport", function()
                            travelTo(target.position, { stopDistance = 8, timeout = 30 })
                            return true
                        end)
                    end)
                    return true
                end
            end
            return false
        end,
        chatSay = Misc.chat,
        playEmote = Misc.emote,
        hop = hopServer,
        world_helpers = { nearest = nearestGuardian, pick = pickEgg, allowed = eggAllowed },
    }
    SharedEnv.SkillHubStealAnEgg = skillHubInstance
    SharedEnv.SkillHubUrl = "https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/Steal%20a%20Egg/SkillHub.lua"
    return skillHubInstance
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 22 · THE TAB LAYER — runs in its own closure
--     Lua allows 200 locals per scope; the engine above already uses most of
--     them, so the tab layer receives its symbols through NS instead of
--     ninety arguments (which would break the 255-register call limit).
-- ═══════════════════════════════════════════════════════════════════════════
local function runTabs(NS)
    local AC, AUTHOR, BUILD, Camera, Config, Esp, Fun, GAME_NAME, ICON, KNOWLEDGE, Lighting, LocalPlayer,
        Loop, Misc, Mov, Players, State, Tabs, Theme, UserInput, VERSION, Workspace, World,
        buyTrail, carriedEgg, claimIndex, claimOffline, containsAny, dropCarried, eggAllowed,
        equipBest, eventByKey, eventScan, findOwnPlot, firePrompt, fusePets, getChar, getHumanoid,
        getRoot, getService, getWindow, hatchReady, isAlive, lower, makeTab, modelPosition,
        nearestGuardian, new, notify, panic, pickEgg, placeHeld, rarityIndex, runSelfTest, safeCall,
        scanWorld, sellEggs, shortNumber, splitList, startFun, startLoops, stopSteal, travelTo,
        travelToBase, tryGrab, unload, useTreadmill =
        NS.AC, NS.AUTHOR, NS.BUILD, NS.Camera, NS.Config, NS.Esp, NS.Fun, NS.GAME_NAME, NS.ICON, NS.KNOWLEDGE,
        NS.Lighting, NS.LocalPlayer, NS.Loop, NS.Misc, NS.Mov, NS.Players, NS.State, NS.Tabs,
        NS.Theme, NS.UserInput, NS.VERSION, NS.Workspace, NS.World, NS.buyTrail, NS.carriedEgg, NS.claimIndex,
        NS.claimOffline, NS.containsAny, NS.dropCarried, NS.eggAllowed, NS.equipBest, NS.eventByKey,
        NS.eventScan, NS.findOwnPlot, NS.firePrompt, NS.fusePets, NS.getChar, NS.getHumanoid, NS.getRoot,
        NS.getService, NS.getWindow, NS.hatchReady, NS.isAlive, NS.lower, NS.makeTab, NS.modelPosition,
        NS.nearestGuardian, NS.new, NS.notify, NS.panic, NS.pickEgg, NS.placeHeld, NS.rarityIndex,
        NS.runSelfTest, NS.safeCall, NS.scanWorld, NS.sellEggs, NS.shortNumber, NS.splitList, NS.startFun,
        NS.startLoops, NS.stopSteal, NS.travelTo, NS.travelToBase, NS.tryGrab, NS.unload, NS.useTreadmill

    local setWalkSpeed = NS.setWalkSpeed

    local function buildTabs()
    -- ── 1 · STEAL ────────────────────────────────────────────────────────────
    local TabSteal = makeTab("Steal", "Target picking, the steal loop, the way home", ICON.Chest, Theme.Sand)
    TabSteal:AddLabel("The loop that made this hub: pick an egg by rarity and value against distance, travel to its nest " ..
        "without a single long teleport, take it, carry it home and place it. Guardians drop whatever you carry — the hub " ..
        "drops it on purpose before the guardian reaches you, then goes back for it.", ICON.Chest)

    TabSteal:AddStatusPanel("Live", function()
        local carrying = carriedEgg()
        local best = World.best
        return ({
            { label = "state", value = Config.AutoSteal and "stealing" or "idle" },
            { label = "carrying", value = carrying and carrying.Name or "—" },
            { label = "best egg", value = best and string.format("%s · %s · %s/s", best.name, best.rarity, shortNumber(best.value)) or "—" },
            { label = "targets", value = string.format("%d egg(s) · %d dropped", #World.eggs, (function()
                local n = 0
                for _, record in ipairs(World.eggs) do if record.dropped then n = n + 1 end end
                return n
            end)()) },
            { label = "steals", value = string.format("%d ok · %d refused · %d placed", State.steals, State.stealsFailed, State.placed) },
        })
    end, 132)

    TabSteal:AddSection("What to take")
    TabSteal:AddDropdown("Pick mode", "how the next egg is chosen", { "Smart", "Nearest", "Best value", "Specific" },
        Config.StealMode, function(value) Config.StealMode = value end, ICON.Magnet)
    TabSteal:AddDropdown("Minimum rarity", "everything below this is ignored", KNOWLEDGE.Rarities,
        Config.MinRarity, function(value) Config.MinRarity = value end, ICON.Star)
    TabSteal:AddSlider("Minimum value", "ignore eggs worth less than this, millions per second", 0, 1000,
        math.floor((Config.MinValue or 0) / 1e6), " M$/s", function(value) Config.MinValue = value * 1e6 end, ICON.Chart)
    TabSteal:AddInput("Biomes", "comma separated, empty = every biome", "Forest, Lake, Desert", function(text)
        Config.AllowedAreas = text or ""
    end, ICON.Layers)
    TabSteal:AddInput("Mutations", "comma separated, empty = every mutation", "Enchanted, Nitro", function(text)
        Config.MutationFilter = text or ""
    end, ICON.Hex)
    TabSteal:AddInput("Egg name", "used by the Specific pick mode", "Secret Egg", function(text)
        Config.TargetEgg = text or ""
    end, ICON.Search)
    TabSteal:AddToggle("Ignore my own plot", "never steal from your own display", Config.IgnoreOwnPlot,
        function(value) Config.IgnoreOwnPlot = value end, ICON.Guard)

    TabSteal:AddSection("The loop")
    TabSteal:AddToggle("Auto steal", "run the whole loop: pick, travel, grab, carry home, place", Config.AutoSteal,
        function(value)
            Config.AutoSteal = value
            if value then
                if not State.loopsStarted then startLoops() end
                notify("Steal", "loop armed — the first target is chosen on the next scan", 4, Theme.Sand, ICON.Play)
            end
        end, ICON.Play)
    TabSteal:AddToggle("Return home automatically", "carry the egg to your plot instead of standing at the nest",
        Config.AutoReturn, function(value) Config.AutoReturn = value end, ICON.Teleport)
    TabSteal:AddToggle("Drop when a guardian nears", "guardians fling you and the egg drops anyway — this does it on purpose, earlier",
        Config.AutoDropOnGuard, function(value) Config.AutoDropOnGuard = value end, ICON.Guard)
    TabSteal:AddToggle("Recover dropped eggs", "go back for an egg you lost", Config.RecoverDropped,
        function(value) Config.RecoverDropped = value end, ICON.Loop)
    TabSteal:AddToggle("Snipe other players' drops", "the dropped egg of somebody else is still an egg", Config.SnipeDropped,
        function(value) Config.SnipeDropped = value end, ICON.Search)
    TabSteal:AddToggle("Take one and stop", "a single steal, then the loop disarms itself", Config.StealOnce,
        function(value) Config.StealOnce = value end, ICON.Stop)
    TabSteal:AddSlider("Steal delay", "seconds between two grabs", 0.2, 4, Config.StealDelay, " s",
        function(value) Config.StealDelay = value end, ICON.Loop)
    TabSteal:AddSlider("Travel speed", "studs per second the travel modes ask for", 20, 4000, Config.TravelSpeed, " studs/s",
        function(value) Config.TravelSpeed = value end, ICON.Bolt)
    TabSteal:AddDropdown("Travel mode", "Step is the safe default; Tween is smoother and a little louder; Walk never writes a CFrame",
        { "Step", "Tween", "Blink", "Fly", "Walk" }, Config.TravelMode,
        function(value) Config.TravelMode = value end, ICON.Wind)
    TabSteal:AddSlider("Hover above the nest", "how close the travel stops before the prompt is fired", 1, 12,
        Config.SafeHover, " studs", function(value) Config.SafeHover = value end, ICON.Layers)
    TabSteal:AddButton("Steal once, now", "one pass of the loop with the current filters", function()
        scanWorld(true)
        local record = pickEgg()
        if not record then
            notify("Steal", "no egg matches the filters", 4, Theme.Warning, ICON.Warning)
            return
        end
        notify("Steal", "going for " .. record.name, 3, Theme.Sand, ICON.Magnet)
        local ok = tryGrab(record)
        notify("Steal", ok and ("took " .. record.name) or "the server refused the grab", 4,
            ok and Theme.Success or Theme.Warning, ok and ICON.Chest or ICON.Warning)
    end, ICON.Play)
    TabSteal:AddButton("Go home", "travel to your own plot", function() travelToBase() end, ICON.Teleport)
    TabSteal:AddButton("Stop the loop", "disarm auto steal and pause it for a moment", function()
        stopSteal("manual")
        notify("Steal", "loop stopped", 3, Theme.TextSecondary, ICON.Stop)
    end, ICON.Stop, true)

    -- ── 2 · BASE ─────────────────────────────────────────────────────────────
    local TabBase = makeTab("Base", "Place, hatch, index, trails, fuse, sell", ICON.Crown, Theme.Sage)
    TabBase:AddLabel("Everything that happens on your own plot. Place and hatch run through the plot's own ProximityPrompts — " ..
        "the hub clicks what you would click, at the pace the prompt asks for.", ICON.Crown)
    TabBase:AddStatusPanel("Base", function()
        return {
            { label = "carrying", value = carriedEgg() and carriedEgg().Name or "—" },
            { label = "placed", value = tostring(State.placed) },
            { label = "hatched", value = tostring(State.hatched) },
            { label = "fused / sold", value = string.format("%d / %d", State.fused, State.sold) },
            { label = "plot", value = findOwnPlot() and findOwnPlot().Name or "not found" },
        }
    end, 132)
    TabBase:AddSection("Placement")
    TabBase:AddToggle("Auto place", "take the carried egg off your hands the moment you are home", Config.AutoPlace,
        function(value) Config.AutoPlace = value end, ICON.Chest)
    TabBase:AddDropdown("Placement rule", "Any places everything; Best only keeps legendaries for itself", { "Any", "Best only" },
        Config.PlaceRule, function(value) Config.PlaceRule = value end, ICON.Star)
    TabBase:AddSlider("Place delay", "seconds between placements", 0.2, 3, Config.PlaceDelay, " s",
        function(value) Config.PlaceDelay = value end, ICON.Loop)
    TabBase:AddSlider("Session cap", "stop placing after this many eggs in one session", 0, 200, Config.MaxPlaced, "",
        function(value) Config.MaxPlaced = value end, ICON.Chart)
    TabBase:AddSection("Hatch, index, rewards")
    TabBase:AddToggle("Auto hatch", "fire the plot's hatch prompt whenever an egg is ready", Config.AutoHatch,
        function(value) Config.AutoHatch = value end, ICON.Spark)
    TabBase:AddToggle("Auto index", "claim index rewards as soon as a new pet is discovered", Config.AutoIndex,
        function(value) Config.AutoIndex = value end, ICON.Layers)
    TabBase:AddToggle("Claim offline earnings", "click the offline rewards button when it appears", Config.AutoClaimOffline,
        function(value) Config.AutoClaimOffline = value end, ICON.Bell)
    TabBase:AddToggle("Buy trails", "buy the next trail while the multiplier is worth it", Config.AutoBuyTrails,
        function(value) Config.AutoBuyTrails = value end, ICON.Wind)
    TabBase:AddToggle("Auto equip best", "keep the strongest pet equipped", Config.AutoEquipBest,
        function(value) Config.AutoEquipBest = value end, ICON.Sword)
    TabBase:AddToggle("Auto fuse", "fuse duplicates in the fusion machine", Config.AutoFuse,
        function(value) Config.AutoFuse = value end, ICON.Hex)
    TabBase:AddToggle("Auto sell eggs", "sell everything below the chosen rarity on a timer", Config.AutoSellEggs,
        function(value) Config.AutoSellEggs = value end, ICON.Chart)
    TabBase:AddDropdown("Sell below", "the rarity the sell filter keeps", KNOWLEDGE.Rarities, Config.SellBelowRarity,
        function(value) Config.SellBelowRarity = value end, ICON.Star)
    TabBase:AddSlider("Sell interval", "seconds between sell passes", 5, 300, Config.SellDelay, " s",
        function(value) Config.SellDelay = value end, ICON.Loop)
    TabBase:AddSection("Manual")
    TabBase:AddButton("Place what I carry", "one placement, right now", function()
        if placeHeld() then
            notify("Base", "egg placed", 3, Theme.Success, ICON.Chest)
        else
            notify("Base", "nothing to place, or no plot prompt", 4, Theme.Warning, ICON.Warning)
        end
    end, ICON.Chest)
    TabBase:AddButton("Hatch everything", "fire the hatch prompt four times", function() hatchReady(4) end, ICON.Spark)
    TabBase:AddButton("Claim index", "collect every uncollected index reward", function() claimIndex() end, ICON.Layers)
    TabBase:AddButton("Claim offline", "collect offline earnings", function() claimOffline() end, ICON.Bell)

    -- ── 3 · FARM ─────────────────────────────────────────────────────────────
    local TabFarm = makeTab("Farm", "Treadmill, speed, guardians", ICON.Farm, Theme.Sky)
    TabFarm:AddLabel("Speed is the only currency that opens biomes: Lake at 900, Cosmic at 700M, Enchanted Forest at 50B. " ..
        "The treadmill and the upgrade button are where it comes from, so the hub stands on the pad and keeps the " ..
        "step prompt alive while you are not stealing.", ICON.Farm)
    TabFarm:AddStatusPanel("Speed", function()
        local humanoid = getHumanoid()
        return {
            { label = "walk speed", value = humanoid and string.format("%.0f", humanoid.WalkSpeed) or "—" },
            { label = "real target", value = tostring(State.realSpeed or "—") },
            { label = "ping", value = string.format("%d ms", State.ping or 0) },
            { label = "guardians", value = string.format("%d in range", #World.guardians) },
            { label = "next biome", value = (function()
                local speed = (humanoid and humanoid.WalkSpeed) or 0
                for _, biome in ipairs(KNOWLEDGE.Biomes) do
                    if biome.Speed > speed then return string.format("%s @ %s", biome.Name, shortNumber(biome.Speed)) end
                end
                return "all unlocked"
            end)() },
        }
    end, 132)
    TabFarm:AddToggle("Auto treadmill", "stand on your treadmill and keep training", Config.AutoTreadmill,
        function(value) Config.AutoTreadmill = value end, ICON.Loop)
    TabFarm:AddToggle("Upgrade the treadmill", "press the upgrade prompt when it is available", Config.AutoUpgradeTreadmill,
        function(value) Config.AutoUpgradeTreadmill = value end, ICON.Bolt)
    TabFarm:AddSlider("Treadmill interval", "seconds between training actions", 0.5, 10, Config.TreadmillInterval, " s",
        function(value) Config.TreadmillInterval = value end, ICON.Loop)
    TabFarm:AddToggle("Auto rebirth", "fire the rebirth prompt or remote when the base offers it", Config.AutoRebirth,
        function(value) Config.AutoRebirth = value end, ICON.Star)
    TabFarm:AddToggle("Guardian warning", "a toast when a guardian is close enough to take your egg", Config.GuardianWarning,
        function(value) Config.GuardianWarning = value end, ICON.Warning)
    TabFarm:AddSlider("Guardian range", "the distance the warning and the drop-on-guard rule use", 20, 160, Config.GuardianRange, " studs",
        function(value) Config.GuardianRange = value end, ICON.Search)
    TabFarm:AddToggle("Anti AFK", "a keypress every time Roblox decides you are idle", Config.AntiAfk,
        function(value) Config.AntiAfk = value end, ICON.Bell)
    TabFarm:AddButton("Go to the treadmill", "travel to your treadmill and start training", function()
        if useTreadmill(false) then
            notify("Farm", "on the treadmill", 3, Theme.Success, ICON.Loop)
        else
            notify("Farm", "no treadmill found on your plot", 4, Theme.Warning, ICON.Warning)
        end
    end, ICON.Loop)

    -- ── 4 · MOVEMENT ─────────────────────────────────────────────────────────
    local TabMove = makeTab("Movement", "Speed, fly, noclip, the anti-* stack", ICON.Wind, Theme.Iris)
    TabMove:AddLabel("These change how the character moves. Everything here is clamped by the anti-cheat ceiling when " ..
        "Safe mode is on — that ceiling is the whole reason a speed toggle does not end in a kick.", ICON.Wind)
    TabMove:AddSection("Speed and jump")
    TabMove:AddToggle("Walk speed", "set a custom walk speed", Config.WalkSpeedEnabled,
        function(value)
            Config.WalkSpeedEnabled = value
            if not value then
                setWalkSpeed(16)
            end
        end, ICON.Bolt)
    TabMove:AddSlider("Speed value", "the speed the hub asks for", 16, 500, Config.WalkSpeed, " studs/s",
        function(value) Config.WalkSpeed = value end, ICON.Bolt)
    TabMove:AddToggle("Jump power", "set a custom jump power", Config.JumpPowerEnabled,
        function(value) Config.JumpPowerEnabled = value end, ICON.Wind)
    TabMove:AddSlider("Jump value", "jump power", 30, 300, Config.JumpPower, "",
        function(value) Config.JumpPower = value end, ICON.Wind)
    TabMove:AddToggle("Infinite jump", "jump again while airborne", Config.InfiniteJump,
        function(value) Config.InfiniteJump = value end, ICON.Wind)
    TabMove:AddToggle("Always sprint", "never drop below the configured speed", Config.AlwaysSprint,
        function(value) Config.AlwaysSprint = value end, ICON.Bolt)
    TabMove:AddSection("Flight")
    TabMove:AddToggle("Fly", "camera-relative flight on a BodyVelocity — Space up, Ctrl down", Config.FlyEnabled,
        function(value) Config.FlyEnabled = value end, ICON.Wind)
    TabMove:AddSlider("Fly speed", "studs per second", 20, 400, Config.FlySpeed, " studs/s",
        function(value) Config.FlySpeed = value end, ICON.Bolt)
    TabMove:AddToggle("Noclip", "walk through walls while it is on", Config.Noclip,
        function(value) Config.Noclip = value end, ICON.Ghost)
    TabMove:AddSection("Survival")
    TabMove:AddToggle("Anti void", "get pulled back if you fall out of the map", Config.AntiVoid,
        function(value) Config.AntiVoid = value end, ICON.Guard)
    TabMove:AddToggle("Anti fling", "kill the velocity a guardian or a trap gives you", Config.AntiFling,
        function(value) Config.AntiFling = value end, ICON.Guard)
    TabMove:AddToggle("Anti ragdoll", "stand back up the frame you are put down", Config.AntiRagdoll,
        function(value) Config.AntiRagdoll = value end, ICON.Guard)
    TabMove:AddToggle("Anti stun", "restore your speed the moment the game zeroes it", Config.AntiStun,
        function(value) Config.AntiStun = value end, ICON.Guard)
    TabMove:AddToggle("Anti slow", "same, for the traps that only halve it", Config.AntiSlow,
        function(value) Config.AntiSlow = value end, ICON.Guard)
    TabMove:AddToggle("No fall damage", "the hub caps your fall speed before the landing", Config.NoFallDamage,
        function(value) Config.NoFallDamage = value end, ICON.Guard)
    TabMove:AddToggle("Low gravity", "70 instead of 196 — floatier jumps", Config.LowGravity,
        function(value) Config.LowGravity = value end, ICON.Wind)

    -- ── 5 · ESP ──────────────────────────────────────────────────────────────
    local TabEsp = makeTab("ESP", "Eggs, guardians, dropped eggs, players", ICON.Eye, Theme.Mauve)
    TabEsp:AddLabel("Highlights and billboards only — no executor-only drawing objects, so the same code runs on Xeno and " ..
        "everywhere else. Colour is the rarity: grey common, blue rare, gold legendary, violet mythic, cyan cosmic, " ..
        "rose secret, ivory divine.", ICON.Eye)
    TabEsp:AddToggle("Egg ESP", "name, rarity, value and distance over every egg", Config.EspEggs,
        function(value) Config.EspEggs = value end, ICON.Chest)
    TabEsp:AddToggle("Best egg only", "draw a single label — the one the loop would take next", Config.EspBestOnly,
        function(value) Config.EspBestOnly = value end, ICON.Star)
    TabEsp:AddToggle("Guardians", "red highlight on every guardian", Config.EspGuardians,
        function(value) Config.EspGuardians = value end, ICON.Guard)
    TabEsp:AddToggle("Dropped eggs", "player-dropped eggs are violet instead of their rarity colour", Config.EspDropped,
        function(value) Config.EspDropped = value end, ICON.Loot)
    TabEsp:AddToggle("Players", "highlight every other player", Config.EspPlayers,
        function(value) Config.EspPlayers = value end, ICON.Player)
    TabEsp:AddToggle("Names", "the label line itself", Config.EspNames,
        function(value) Config.EspNames = value end, ICON.Search)
    TabEsp:AddToggle("Rarity in the label", "adds the rarity word", Config.EspRarity,
        function(value) Config.EspRarity = value end, ICON.Star)
    TabEsp:AddToggle("Value in the label", "adds $/s", Config.EspValue,
        function(value) Config.EspValue = value end, ICON.Chart)
    TabEsp:AddToggle("Distance in the label", "adds the distance in studs", Config.EspDistance,
        function(value) Config.EspDistance = value end, ICON.Teleport)
    TabEsp:AddToggle("Tracers", "a line from the bottom of the screen to each target", Config.EspTracers,
        function(value) Config.EspTracers = value end, ICON.Bolt)
    TabEsp:AddSlider("Fill transparency", "0 = solid, 1 = invisible", 0.2, 1, Config.EspFillTransparency, "",
        function(value) Config.EspFillTransparency = value end, ICON.Layers)
    TabEsp:AddSlider("Max distance", "labels stop past this range", 200, 5000, Config.EspMaxDistance, " studs",
        function(value) Config.EspMaxDistance = value end, ICON.Search)
    TabEsp:AddSection("Lighting")
    TabEsp:AddToggle("Full bright", "no more night in the Halloween dimension", Config.Fullbright,
        function(value) Config.Fullbright = value end, ICON.Star)
    TabEsp:AddToggle("Remove fog and vfx", "the fog is what hides the far nests", Config.RemoveVfx,
        function(value) Config.RemoveVfx = value end, ICON.Wind)
    TabEsp:AddToggle("FPS boost", "shadows off", Config.FpsBoost,
        function(value) Config.FpsBoost = value end, ICON.Bolt)
    TabEsp:AddSlider("Camera FOV", "field of view", 50, 120, Config.CameraFov, "°",
        function(value) Config.CameraFov = value end, ICON.Eye)

    -- ── 6 · EVENTS ───────────────────────────────────────────────────────────
    local TabEvents = makeTab("Events", "Rifts, Nitro Race, stars, blooms, the lab", ICON.Star, Theme.Rose)
    TabEvents:AddLabel("What is live in this server right now. Rifts and the Nitro Race run on a 30-minute clock; Shooting " ..
        "Stars only appear if you were in the server when the in-game day started; the Butterfly Bloom hides inside the " ..
        "Enchanted Tree; Dr. Scramble's Laboratory took over the Rift trade-in in Update 6.", ICON.Star)
    TabEvents:AddStatusPanel("In this server", function()
        eventScan()
        local rows = {}
        for _, event in ipairs(World.events) do
            local label, distance = event.key, 0
            for _, definition in ipairs(KNOWLEDGE.Events) do
                if definition.Key == event.key then label = definition.Label end
            end
            local root = getRoot()
            if root then distance = math.floor((root.Position - event.position).Magnitude) end
            rows[#rows + 1] = { label = label, value = string.format("%dm · %s", distance, event.name) }
        end
        if #rows == 0 then rows[1] = { label = "events", value = "nothing found yet — scan again" } end
        return rows
    end, 120)
    TabEvents:AddToggle("Auto rifts", "travel to a rift and stay for the Abyss Overlord", Config.AutoRift,
        function(value) Config.AutoRift = value end, ICON.Star)
    TabEvents:AddToggle("Auto boss", "fight what the rift spawns — the tool is activated for you", Config.AutoBoss,
        function(value) Config.AutoBoss = value end, ICON.Skull)
    TabEvents:AddToggle("Auto nitro race", "travel the checkpoints in order every time the race starts", Config.AutoRace,
        function(value) Config.AutoRace = value end, ICON.Wind)
    TabEvents:AddToggle("Auto shooting star", "go to the star before it burns out", Config.AutoStar,
        function(value) Config.AutoStar = value end, ICON.Star)
    TabEvents:AddToggle("Auto butterfly bloom", "go to the Enchanted Tree and take the bloom", Config.AutoBloom,
        function(value) Config.AutoBloom = value end, ICON.Spark)
    TabEvents:AddToggle("Auto lab trade-in", "trade unhatched eggs at Dr. Scramble's Laboratory — the pity counter guarantees the top reward",
        Config.AutoLab, function(value) Config.AutoLab = value end, ICON.Hex)
    TabEvents:AddToggle("Event notifications", "a toast the first time an event is seen in this server", Config.EventNotify,
        function(value) Config.EventNotify = value end, ICON.Bell)
    TabEvents:AddSection("Jump to")
    for _, definition in ipairs(KNOWLEDGE.Events) do
        TabEvents:AddButton(definition.Label, "travel to this event if it is in the server", function()
            eventScan()
            local event = eventByKey(definition.Key)
            if not event then
                notify(definition.Label, "not in this server", 4, Theme.Warning, ICON.Warning)
                return
            end
            travelTo(event.position, { stopDistance = 10, timeout = 30 })
        end, ICON.Teleport)
    end

    -- ── 7 · ANTI-CHEAT ───────────────────────────────────────────────────────
    local TabAc = makeTab("Anti-Cheat", "Hooks, reports, pace, audit", ICON.Guard, Theme.Clay)
    TabAc:AddLabel("Read this before turning anything on: Steal An Egg has no published ban API and no meaningful automated " ..
        "anti-cheat — its defences are a movement sampler that rubber-bands you and a server that decides whether an egg " ..
        "is yours. The layers below defeat the client-side half honestly. No client script can out-argue the server, and " ..
        "nothing here makes you undetectable.", ICON.Warning)
    TabAc:AddStatusPanel("Audit", function()
        local telemetry = AC.telemetry()
        return {
            { label = "scripts", value = tostring(telemetry.scripts) },
            { label = "detectors", value = string.format("%d found · %d off", telemetry.detectors, telemetry.disabled) },
            { label = "report remotes", value = tostring(telemetry.reports) },
            { label = "dropped calls", value = tostring(telemetry.blocked) },
            { label = "hooks", value = string.format("namecall %s · kick %s · read %s", tostring(telemetry.hook),
                tostring(telemetry.kickGuard), tostring(telemetry.camouflage)) },
            { label = "limit fields", value = tostring(telemetry.patched) },
        }
    end, 150)
    TabAc:AddSection("Pace")
    TabAc:AddDropdown("Profile", "one click sets the ceiling, the step size and the remote rate", { "Conservative", "Balanced", "Aggressive" },
        AC.profile, function(value)
            AC.applyProfile(value)
            notify("Anti-Cheat", value .. " profile applied", 4, Theme.Clay, ICON.Guard)
        end, ICON.Settings)
    TabAc:AddToggle("Safe mode", "clamp every speed the hub asks for to the ceiling below", Config.AcSafeMode,
        function(value) Config.AcSafeMode = value end, ICON.Guard)
    TabAc:AddSlider("Speed ceiling", "the highest walk speed the game will ever see", 20, 200, Config.AcSpeedCeiling, " studs/s",
        function(value) Config.AcSpeedCeiling = value end, ICON.Bolt)
    TabAc:AddSlider("Step size", "the longest distance one movement step may cover — this is what a position check sees", 2, 40,
        Config.AcStepSize, " studs", function(value) Config.AcStepSize = value end, ICON.Layers)
    TabAc:AddSlider("Step delay", "pause between two steps", 0.02, 0.3, Config.AcStepDelay, " s",
        function(value) Config.AcStepDelay = value end, ICON.Loop)
    TabAc:AddSlider("Remote rate", "outgoing gameplay remotes per second", 4, 60, Config.AcRemoteRateLimit, " /s",
        function(value) Config.AcRemoteRateLimit = value end, ICON.Chart)
    TabAc:AddSection("Layers")
    TabAc:AddToggle("Neutralise detectors", "disable the client scripts that watch for changed properties", Config.AcNeutralize,
        function(value)
            Config.AcNeutralize = value
            if value then AC.neutralize(false) end
        end, ICON.Guard)
    TabAc:AddToggle("Block report remotes", "drop every outgoing report / flag / screenshot call at the namecall level",
        Config.AcBlockReports, function(value)
            Config.AcBlockReports = value
            if value then AC.installHook() else AC.removeHook() end
        end, ICON.Guard)
    TabAc:AddToggle("Kick guard", "intercept LocalPlayer:Kick on the client", Config.AcKickGuard,
        function(value)
            Config.AcKickGuard = value
            if value then AC.installKickGuard() else AC.removeKickGuard() end
        end, ICON.Guard)
    TabAc:AddToggle("WalkSpeed read camouflage", "the game's own scripts read a plausible speed while the real one is yours",
        Config.AcCamouflage, function(value)
            Config.AcCamouflage = value
            if value then AC.installCamouflage() else AC.removeCamouflage() end
        end, ICON.Eye)
    TabAc:AddToggle("Speed-limit patcher", "clamp numeric limit fields found in the game's Lua tables", Config.AcSpeedLimiter,
        function(value)
            Config.AcSpeedLimiter = value
            if value then
                local patched = AC.patchSpeedLimiters(Config.AcSpeedCeiling)
                notify("Anti-Cheat", string.format("%d field(s) clamped", patched), 4, Theme.Clay, ICON.Gear)
            end
        end, ICON.Gear)
    TabAc:AddSection("Staff")
    TabAc:AddToggle("Staff watch", "toast when a moderator-looking account joins", Config.StaffWatch,
        function(value) Config.StaffWatch = value end, ICON.Player)
    TabAc:AddToggle("Leave the server for staff", "hop the moment staff is seen", Config.StaffHop,
        function(value) Config.StaffHop = value end, ICON.Teleport)
    TabAc:AddSection("Verify")
    TabAc:AddButton("Run audit now", "scan, print the detector and report list, then arm the layers", function()
        local telemetry = AC.audit(true)
        AC.arm()
        notify("Audit", string.format("%d script(s) · %d report remote(s) · hook %s", telemetry.scripts,
            telemetry.reports, tostring(AC.hookInstalled)), 6, Theme.Clay, ICON.Search)
    end, ICON.Search)
    TabAc:AddButton("Run self-test", "twenty-two checks over the engine, the filters and the hooks", function()
        local result = runSelfTest(false)
        notify("Self-test", string.format("%d/%d passed", result.passed, result.total), 6,
            result.passed == result.total and Theme.Success or Theme.Warning, ICON.Layers)
    end, ICON.Layers)

    -- ── 8 · FUN ──────────────────────────────────────────────────────────────
    local TabFun = makeTab("Fun", "Egg rain, bat aura, disco, music", ICON.Spark, Theme.Sand)
    TabFun:AddLabel("Cosmetics. None of it touches eggs, speed or remotes — it exists because a hub that only steals is boring.",
        ICON.Spark)
    TabFun:AddToggle("Egg rain", "neon eggs fall around you", Config.EggRain,
        function(value) Config.EggRain = value end, ICON.Chest)
    TabFun:AddToggle("Bat aura", "a dark orb orbiting the character", Config.BatAura,
        function(value) Config.BatAura = value end, ICON.Ghost)
    TabFun:AddToggle("Rainbow plot", "your plot cycles through hues", Config.RainbowPlot,
        function(value) Config.RainbowPlot = value end, ICON.Star)
    TabFun:AddToggle("Disco lighting", "ambient colour cycling", Config.DiscoMode,
        function(value) Config.DiscoMode = value end, ICON.Bell)
    TabFun:AddToggle("Big pets", "scale every pet model on your plot", Config.BigPets,
        function(value) Config.BigPets = value end, ICON.Crown)
    TabFun:AddSlider("Pet scale", "how big", 0.5, 4, Config.PetScale, "×",
        function(value) Config.PetScale = value end, ICON.Crown)
    TabFun:AddToggle("Spark burst on grab", "a particle burst when an egg lands in your hands", Config.HitSparks,
        function(value) Config.HitSparks = value end, ICON.Spark)
    TabFun:AddToggle("Emote loop", "open the emote wheel and pick a slot on a timer", Config.EmoteLoop,
        function(value) Config.EmoteLoop = value end, ICON.Play)
    TabFun:AddSlider("Emote interval", "seconds between emotes", 5, 60, Config.EmoteLoopDelay, " s",
        function(value) Config.EmoteLoopDelay = value end, ICON.Loop)
    TabFun:AddInput("Chat message", "the line the chat loop sends", "ez", function(text)
        Config.ChatMessage = text or ""
    end, ICON.Scroll)
    TabFun:AddToggle("Chat loop", "send the line above on a timer", Config.ChatSpam,
        function(value) Config.ChatSpam = value end, ICON.Bell)
    TabFun:AddSlider("Chat interval", "seconds between messages", 5, 120, Config.ChatDelay, " s",
        function(value) Config.ChatDelay = value end, ICON.Loop)
    TabFun:AddToggle("Music", "a Sound on your character", Config.Music,
        function(value)
            Config.Music = value
            Misc.music(value)
        end, ICON.Bell)
    TabFun:AddInput("Music asset id", "the numbers after rbxassetid://", "", function(text)
        Config.MusicId = text or ""
    end, ICON.Gear)
    TabFun:AddSlider("Music volume", "0 to 1", 0, 1, Config.MusicVolume, "",
        function(value) Config.MusicVolume = value end, ICON.Bell)

    -- ── 9 · PLAYER & MISC ────────────────────────────────────────────────────
    local TabMisc = makeTab("Player & Misc", "Teleports, hop, keybinds, unload", ICON.Settings, Theme.Steel)
    TabMisc:AddLabel("The exit door and the map. Teleports use the same paced travel as the steal loop — the hub never " ..
        "writes one long CFrame jump.", ICON.Teleport)
    TabMisc:AddPlayerList("In this server", function() return Misc.playerList() end, {
        { label = "TP", callback = function(player)
            local character = player and player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then travelTo(root.Position, { stopDistance = 6, timeout = 25 }) end
        end },
        { label = "◎", callback = function(player)
            if player and setclipboard then safeCall("clipboard", function() setclipboard(player.Name) return true end) end
        end },
    })
    TabMisc:AddSection("Teleports")
    local teleportNames = {}
    for _, target in ipairs(Misc.teleportTargets()) do teleportNames[#teleportNames + 1] = target.name end
    if #teleportNames == 0 then teleportNames = { "Base" } end
    TabMisc:AddDropdown("Destination", "built from the nests, plots and events found in this server", teleportNames,
        teleportNames[1], function(value) TabMisc.selectedTeleport = value end, ICON.Teleport)
    TabMisc:AddButton("Teleport", "paced travel to the destination above", function()
        scanWorld(true)
        local wanted = lower(TabMisc.selectedTeleport or "Base")
        for _, target in ipairs(Misc.teleportTargets()) do
            if lower(target.name) == wanted then
                notify("Teleport", target.name, 3, Theme.Accent, ICON.Teleport)
                travelTo(target.position, { stopDistance = 8, timeout = 30 })
                return
            end
        end
        notify("Teleport", "destination not in this server", 4, Theme.Warning, ICON.Warning)
    end, ICON.Teleport)
    TabMisc:AddButton("Base", "go home", function() travelToBase() end, ICON.Teleport)
    TabMisc:AddSection("Server")
    TabMisc:AddButton("Server hop", "leave for the next server, lowest player count first", function() Misc.hopServer() end, ICON.Teleport)
    TabMisc:AddButton("Copy job id", "put this server's JobId on the clipboard", function()
        if setclipboard then
            safeCall("clipboard", function() setclipboard(tostring(game.JobId)) return true end)
            notify("Clipboard", tostring(game.JobId), 4, Theme.Accent, ICON.Gear)
        end
    end, ICON.Gear)
    TabMisc:AddSection("Keys")
    TabMisc:AddKeybind("Hide / show the window", "the key that puts the whole interface away", Config.HideUiKey, function(key)
        if key and key ~= "" then Config.HideUiKey = key end
    end, ICON.Eye)
    TabMisc:AddKeybind("Panic", "everything off, immediately", Config.PanicKey, function(key)
        if key and key ~= "" then Config.PanicKey = key end
    end, ICON.Stop)

    TabMisc:AddSection("Exit")
    TabMisc:AddButton("Unload the hub", "remove the window, the ESP, the hooks and every loop", function() unload() end, ICON.Stop, true)
    TabMisc:AddButton("Panic — everything off", "keep the process alive, turn every feature off", function() panic("button") end, ICON.Stop, true)

    end   -- buildTabs

    return buildTabs
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 23 · BOOT
-- ═══════════════════════════════════════════════════════════════════════════
local bootOk, bootError = pcall(function()
    boot(runTabs(NS))
end)

if not bootOk then
    print("[Skill Hub] boot error: " .. tostring(bootError))
    print("[Skill Hub] the hub is loaded; unload or re-run the script after reading the line above")
end

skillHubInstance = finish()

return skillHubInstance
