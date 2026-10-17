--[[
    ██╗  ██╗██╗██╗     ██╗         ██╗  ██╗██╗   ██╗██████╗
    ██║ ██╔╝██║██║     ██║         ██║  ██║██║   ██║██╔══██╗
    █████╔╝ ██║██║     ██║         ███████║██║   ██║██████╔╝
    ██╔═██╗ ██║██║     ██║         ██╔══██║██║   ██║██╔══██╗
    ██║  ██╗██║███████╗███████╗    ██║  ██║╚██████╔╝██████╔╝
    ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    Skill Hub — RIVALS  ·  FREE edition (no key, readable, no loader)
    by ameksi-web  ·  https://github.com/ameksi-web/Skill-Hub

    ── how to run ──────────────────────────────────────────────────────────────
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/RIVALS/SkillHub.lua"))()

    ── what this is ────────────────────────────────────────────────────────────
        A hub for RIVALS (Nosniy Games) with the same "Porcelain" design system as
        the rest of the Skill Hub family: soft-dark graphite surfaces, hairline
        borders, muted editorial accents, a hand-drawn icon set.

        Nine tabs: Combat · Trigger · ESP · Weapons · Movement · Utility ·
                   Anti-Cheat · Fun · Player & Misc

        Built against the live game (Update 23, 26 September 2026): 54 weapons
        in the game, 39 catalogued here with slot and price, the Ranked rules
        (third person off, aim assist capped at 50%, auto shoot locked to
        Dynamic, two loadout swaps, map and weapon bans), the Gate map, and the
        Wildcat numbers from the Update 23 buff.

    ── READ THIS BEFORE TURNING ANYTHING ON ────────────────────────────────────
        RIVALS is one of the most hostile places on Roblox to run a script.
        Nosniy Games publish one line about it — "Cheaters will be permanently
        banned with no second chances" — and the community reports are specific:
        the anti-cheat flags an unexpected object appearing under LocalPlayer,
        flags impossible aim and fire cadence, then bans in waves later, not
        instantly. Roblox's own Hyperion sits under all of that and is what
        actually catches injectors. Nothing in this file changes those odds in
        any way you can rely on.

        What the Anti-Cheat tab does is reduce the client-side signals this hub
        is responsible for: detector scripts are disabled, report / flag /
        screenshot remotes are dropped at the namecall level, LocalPlayer:Kick
        is intercepted, WalkSpeed reads are camouflaged, numeric limit fields
        found in the game's Lua tables are clamped, movement is paced in small
        steps, fire rate is capped and jittered, aim steps are limited, and the
        ESP lives under the hidden GUI instead of the player.
        What it cannot do: make you undetectable, unhide the fact that an
        executor is injected, or out-argue a server that saw the shot.

        If you use this, use an account you can lose. That is not a disclaimer
        bolted on the end — it is the honest summary of what a client script can
        do in a game that bans for it.
]]

local META = {
    version = "v1.3",
    build   = "RIVALS · free · Update 23 build 17.10 · match aim + teardown",
    author  = "ameksi-web",
    game    = "RIVALS",
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
local Camera       = Workspace.CurrentCamera

-- RIVALS replaces CurrentCamera when a match finishes loading and can hand a
-- new one back after a respawn. Everything downstream reads this function, so
-- aim keeps writing to the camera the game is actually rendering instead of a
-- dead instance captured at load time.
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
-- ═══════════════════════════════════════════════════════════════════════════
local Config = {
    -- ── aim ───────────────────────────────────────────────────────────────
    AimEnabled          = false,
    AimKey              = "E",
    AimToggle           = true,        -- false = hold the key
    AimMethod           = "Hybrid",    -- Hybrid (mouse first) | Camera | Mouse | Silent
    AimPart             = "Head",      -- Head | Torso | Nearest | Random
    AimFov              = 140,
    AimSmooth           = 0.55,        -- 0 = snap, 1 = very slow
    AimMouseSensitivity = 0.35,        -- degrees of view per pixel of mouse travel
    AimRange            = 600,
    AimPrediction       = true,
    AimPredictionFactor = 0.12,
    AimVisibleOnly      = false,       -- aim through cover; ESP still shows what is hidden
    AimTeamCheck        = true,
    AimPriority         = "Closest to crosshair",
    AimHumanize         = true,
    AimStepLimit        = 9,           -- max degrees the camera may turn per frame
    AimWallCheck        = true,

    -- ── trigger & automation ──────────────────────────────────────────────
    TriggerBot          = false,
    TriggerMode         = "Crosshair",
    TriggerFov          = 7,
    TriggerDelay        = 0.06,
    TriggerVisibleOnly  = true,
    TriggerTeamCheck    = true,
    AutoReload          = false,
    AutoSwitch          = false,
    AutoKnife           = false,
    AutoKnifeRange      = 9,
    AutoScope           = false,
    NoRecoil            = false,
    NoSpread            = false,
    HitSound            = false,
    HitSoundId          = 9118823102,
    KillSound           = false,
    KillSoundId         = 9118823102,
    FireRateCap         = 14,          -- shots per second the hub will ever send
    HumanizeFire        = true,
    AutoFire            = false,

    -- ── esp ───────────────────────────────────────────────────────────────
    EspPlayers          = true,
    EspTeam             = false,
    EspNames            = true,
    EspHealth           = true,
    EspDistance         = true,
    EspWeapon           = true,
    EspTracers          = false,
    EspChams            = true,
    EspBox              = false,
    EspVisibleOnly      = false,
    EspMaxDistance      = 900,
    EspFillTransparency = 0.55,
    EspInterval         = 0.25,
    EspTeamColor        = true,
    FovCircle           = true,

    -- ── weapons ───────────────────────────────────────────────────────────
    LoadoutPreset       = "Assault Rifle",
    AutoEquipOnSpawn    = true,

    -- ── movement ──────────────────────────────────────────────────────────
    WalkSpeedEnabled    = false,
    WalkSpeed           = 26,
    JumpPowerEnabled    = false,
    JumpPower           = 60,
    InfiniteJump        = false,
    BunnyHop            = false,
    AlwaysSprint        = false,
    FlyEnabled          = false,
    FlySpeed            = 80,
    Noclip              = false,
    AntiVoid            = true,
    AntiFling           = true,
    AntiRagdoll         = true,
    AntiStun            = true,
    NoFallDamage        = true,
    LowGravity          = false,

    -- ── utility ───────────────────────────────────────────────────────────
    AutoQueue           = false,
    AutoGG              = false,
    GGMessage           = "gg",
    AntiFlash           = false,
    NoSmoke             = false,
    RemoveVfx           = false,
    FpsBoost            = false,
    Fullbright          = false,
    CameraFov           = 0,           -- 0 = leave the game's FOV alone
    CameraDistance      = 0,           -- 0 = leave the game's zoom limit alone
    ChatMessage         = "",
    ChatDelay           = 15,
    ChatSpam            = false,
    EmoteLoop           = false,
    EmoteLoopDelay      = 14,

    -- ── anti-cheat ────────────────────────────────────────────────────────
    AcNeutralize        = true,
    AcBlockReports      = true,
    AcKickGuard         = true,
    AcCamouflage        = false,       -- hooks __index for every instance read; costs frames
    AcSpeedLimiter      = true,
    AcSafeMode          = true,
    AcSpeedCeiling      = 60,
    AcStepSize          = 12,
    AcStepDelay         = 0.05,
    AcRemoteRateLimit   = 20,
    AcShotRateLimit     = 10,
    AcAimRateLimit      = true,
    AcProfile           = "Balanced",
    AltOnlyMode         = true,        -- disables the loudest toys
    StaffWatch          = true,
    StaffGroupId        = 0,
    StaffHop            = false,
    HumanPause          = true,

    -- ── fun ───────────────────────────────────────────────────────────────
    HitSparks           = true,
    KillEffect          = false,
    Trail               = false,
    RainbowChar         = false,
    DiscoMode           = false,
    Music               = false,
    MusicId             = "",
    MusicVolume         = 0.5,

    -- ── performance ───────────────────────────────────────────────────────
    ScanInterval        = 0.6,
    ScanBudget          = 400,
    PerfStats           = false,

    -- ── interface ─────────────────────────────────────────────────────────
    HideUiKey           = "RightControl",
    PanicKey            = "F1",
    UiVisible           = true,
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

local FONT = { UI = Enum.Font.GothamMedium, Bold = Enum.Font.GothamBold, Mono = Enum.Font.Code }

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
        Name = "SkillHubRIVALS",
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
    TOAST.holder = Toast

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
        Text = Config.HideUiKey .. " — показать/скрыть окно · F1 — паника (выключить всё)", TextColor3 = Theme.TextFaint,
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
        if UserInput then
            UserInput.InputBegan:Connect(function(input, gameProcessed)
                -- while a rebind is armed the player is still allowed to type in
                -- chat; a keystroke the game already consumed must not bind
                if gameProcessed then return end
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
end
-- ═══════════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════
-- 6 · GAME KNOWLEDGE — RIVALS (Update 23, 26.09.2026)
--     The roster, the slots, the Ranked rules and the words the game uses for
--     its remotes. Weapon stats below are the published Update 23 numbers where
--     a value is used at all; the hub only displays them, the server owns the
--     real ones.
-- ═══════════════════════════════════════════════════════════════════════════

local SVC = {
    Http = getService("HttpService"), Teleport = getService("TeleportService"),
    Sound = getService("SoundService"),
}

local KNOWLEDGE = {
    -- 54 weapons on the roster as of Update 22/23; nickname matching is what
    -- the equip helpers actually use, so the list is deliberately generous
    Weapons = {
        { Name = "Assault Rifle", Slot = "Primary",   Cost = 0,    Dps = 150 },
        { Name = "Burst Rifle",   Slot = "Primary",   Cost = 0,    Dps = 140 },
        { Name = "Shotgun",       Slot = "Primary",   Cost = 0,    Dps = 180 },
        { Name = "Sniper",        Slot = "Primary",   Cost = 0,    Dps = 120 },
        { Name = "Uzi",           Slot = "Primary",   Cost = 0,    Dps = 130 },
        { Name = "SMG",           Slot = "Primary",   Cost = 0,    Dps = 135 },
        { Name = "Wildcat",       Slot = "Primary",   Cost = 35,   Dps = 167 },
        { Name = "Minigun",       Slot = "Primary",   Cost = 250,  Dps = 200 },
        { Name = "Crossbow",      Slot = "Primary",   Cost = 120,  Dps = 90 },
        { Name = "Bow",           Slot = "Primary",   Cost = 90,   Dps = 95 },
        { Name = "Energy Rifle",  Slot = "Primary",   Cost = 200,  Dps = 145 },
        { Name = "Distortion",    Slot = "Primary",   Cost = 220,  Dps = 155 },
        { Name = "Paintball Gun", Slot = "Primary",   Cost = 60,   Dps = 80 },
        { Name = "Exogun",        Slot = "Primary",   Cost = 300,  Dps = 170 },
        { Name = "Flamethrower",  Slot = "Primary",   Cost = 400,  Dps = 160 },
        { Name = "Light Fifty",   Slot = "Primary",   Cost = 500,  Dps = 150 },
        { Name = "Handgun",       Slot = "Secondary", Cost = 0,    Dps = 90 },
        { Name = "Revolver",      Slot = "Secondary", Cost = 80,   Dps = 110 },
        { Name = "Dual Pistols",  Slot = "Secondary", Cost = 150,  Dps = 120 },
        { Name = "Shorty",        Slot = "Secondary", Cost = 90,   Dps = 100 },
        { Name = "Slingshot",     Slot = "Secondary", Cost = 40,   Dps = 70 },
        { Name = "Uzi Pistol",    Slot = "Secondary", Cost = 60,   Dps = 95 },
        { Name = "Knife",         Slot = "Melee",     Cost = 0,    Dps = 60 },
        { Name = "Fists",         Slot = "Melee",     Cost = 0,    Dps = 45 },
        { Name = "Katana",        Slot = "Melee",     Cost = 120,  Dps = 75 },
        { Name = "Hammer",        Slot = "Melee",     Cost = 140,  Dps = 85 },
        { Name = "Maul",          Slot = "Melee",     Cost = 180,  Dps = 95 },
        { Name = "Daggers",       Slot = "Melee",     Cost = 100,  Dps = 70 },
        { Name = "Scythe",        Slot = "Melee",     Cost = 200,  Dps = 90 },
        { Name = "Grenade",       Slot = "Utility",   Cost = 0,    Dps = 0 },
        { Name = "Flashbang",     Slot = "Utility",   Cost = 40,   Dps = 0 },
        { Name = "Smoke Grenade", Slot = "Utility",   Cost = 40,   Dps = 0 },
        { Name = "Molotov",       Slot = "Utility",   Cost = 60,   Dps = 0 },
        { Name = "Freeze Ray",    Slot = "Utility",   Cost = 90,   Dps = 0 },
        { Name = "Grappler",      Slot = "Utility",   Cost = 80,   Dps = 0 },
        { Name = "Jump Pad",      Slot = "Utility",   Cost = 50,   Dps = 0 },
        { Name = "Warpstone",     Slot = "Utility",   Cost = 70,   Dps = 0 },
        { Name = "Subspace Tripmine", Slot = "Utility", Cost = 110, Dps = 0 },
        { Name = "Riot Shield",   Slot = "Utility",   Cost = 130,  Dps = 0 },
    },
    Slots = { "Primary", "Secondary", "Melee", "Utility" },
    Ranks = { "Unranked", "Bronze", "Silver", "Gold", "Platinum", "Diamond", "Champion", "Grand Champion" },
    Maps = { "Onyx", "Gate", "Museum", "Dust", "Hangar", "Plaza" },
    Modes = { "Casual 1v1", "Casual 2v2", "Ranked 1v1", "Ranked 2v2", "Arcade", "Gun Game", "RIVALS RNG" },
    -- Update 23 notes, kept here so the Weapons tab can say where a number came from
    PatchNotes = {
        Wildcat = "Update 23: damage 10 (dropoff 40→100), crit 13, 30/120 ammo, 0.06 s cooldown, 3.0° spread, 0.9° aim spread, +10 move speed",
        Sniper = "Update 22: automatic → semi-automatic, headshot hitbox +17%",
        RiotShield = "Update 21: max health infinite → 500",
        SubspaceTripmine = "Update 23: no longer usable in Arcade servers",
    },
    -- prompt / remote words, most specific first
    Shoot = { "shoot", "fire", "shot", "bullet", "fireweapon", "attack" },
    Reload = { "reload", "ammo", "magazine" },
    Equip = { "equip", "loadout", "weapon" },
    Queue = { "queue", "join", "match", "play", "start" },
    Leave = { "leave", "forfeit", "surrender", "quit" },
    DetectorWords = {
        "anticheat", "anti cheat", "anti-cheat", "detector", "monitor", "integrity",
        "telemetry", "exploit", "validation", "watchdog", "sanction", "sentry",
        "checker", "enforcer",
    },
    -- deliberately narrow: a missing report remote costs nothing, a blocked
    -- gameplay remote breaks the match. "kick" and "ban" alone are not here
    -- because they also match words like Kickoff; the Kick *method* is guarded
    -- separately in the namecall layer.
    ReportWords = {
        "report", "flag", "screenshot", "evidence", "moderation", "sanction",
        "banplayer",
    },
    SafeReportExceptions = { "reputation", "reportcard" },
    -- what a match looks like, used by the utility tab
    MatchGui = { "play", "queue", "join", "find match", "start", "duel" },
    LeaveGui = { "leave", "forfeit", "surrender", "quit", "back to lobby" },
}

local function lower(text) return string.lower(tostring(text or "")) end

local function lowerList(list)
    local out = {}
    for index, value in ipairs(list) do out[index] = lower(value) end
    return out
end

local LOWER = {
    Shoot = lowerList(KNOWLEDGE.Shoot),
    Reload = lowerList(KNOWLEDGE.Reload),
    Equip = lowerList(KNOWLEDGE.Equip),
    Queue = lowerList(KNOWLEDGE.Queue),
    Leave = lowerList(KNOWLEDGE.Leave),
    Detectors = lowerList(KNOWLEDGE.DetectorWords),
    Reports = lowerList(KNOWLEDGE.ReportWords),
    MatchGui = lowerList(KNOWLEDGE.MatchGui),
    LeaveGui = lowerList(KNOWLEDGE.LeaveGui),
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

-- weapon lookup: exact first, then the longest nickname contained in the name
local function weaponInfo(name)
    local wanted = lower(name)
    if wanted == "" then return nil end
    local best, bestLength = nil, 0
    for _, weapon in ipairs(KNOWLEDGE.Weapons) do
        local needle = lower(weapon.Name)
        if (wanted == needle or string.find(wanted, needle, 1, true)) and #needle > bestLength then
            best, bestLength = weapon, #needle
        end
    end
    return best
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 7 · PERFORMANCE CORE
--     RIVALS has at most sixteen players, so the expensive part is not finding
--     them — it is not touching them every frame. A slow structural pass reads
--     what a player looks like (team, tool, rank), a cheap pass refreshes only
--     position, health and visibility, and both are budgeted and measured.
-- ═══════════════════════════════════════════════════════════════════════════

local State = {
    alive = true,
    beats = {},
    lastTargets = {},
    started = os.clock(),
    lastAim = -100,
    lastTrigger = -100,
    lastShot = -100,
    lastReload = -100,
    lastSwitch = -100,
    lastKnife = -100,
    lastQueue = -100,
    lastHop = -100,
    lastChat = -100,
    lastEmote = -100,
    lastGG = -100,
    lastSound = -100,
    shots = 0,
    shotsBlocked = 0,
    hits = 0,
    kills = 0,
    deaths = 0,
    streak = 0,
    target = nil,
    lastTargetName = nil,
    inMatch = false,
    matchSince = 0,
    ping = 0,
    realSpeed = 16,
    gravityDefault = nil,
    perf = {
        scanMs = 0, structureScans = 0, refreshCalls = 0, espUpdates = 0,
        writes = 0, skips = 0, reused = 0, visits = 0, frames = 0, fpsAt = 0,
    },
}

local Cache = {
    character = nil, root = nil, humanoid = nil,
    names = setmetatable({}, { __mode = "k" }),
    nameSource = setmetatable({}, { __mode = "k" }),
    playerRecords = {},
    playerRecordsAt = 0,
    guiButtons = {},
    playerGui = nil, playerGuiAt = 0,
    antiFlashGuis = {},
    soundCache = {},
}

local WriteCache = { speed = nil, jump = nil, noclip = nil }

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

-- assigned in section 15; the combat loop calls it the moment the local
-- character is replaced (match start, respawn) so no cached reference survives
local onCharacterChanged

local function lowerName(instance)
    local name = instance.Name or "?"
    local cached = Cache.names[instance]
    if cached and Cache.nameSource[instance] == name then return cached end
    cached = string.lower(name)
    Cache.names[instance], Cache.nameSource[instance] = cached, name
    return cached
end

local function partPosition(instance)
    if not instance then return nil end
    if instance:IsA("BasePart") then return instance.Position end
    local part = instance:FindFirstChild("HumanoidRootPart")
        or instance:FindFirstChild("UpperTorso") or instance:FindFirstChild("Torso")
        or instance:FindFirstChild("Head") or instance:FindFirstChildWhichIsA("BasePart")
    return part and part.Position or nil
end

local function modelPosition(model)
    if not model then return nil end
    return partPosition(model)
end

local function attr(instance, names)
    if not instance then return nil end
    for _, name in ipairs(names) do
        local ok, value = pcall(function() return instance:GetAttribute(name) end)
        if ok and value ~= nil then return value end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 8 · THE WORLD — players, teams, weapons, visibility
-- ═══════════════════════════════════════════════════════════════════════════
local World = {
    players = {}, count = 0, visibleCount = 0,
    at = 0, structureAt = -10, best = nil, bestScore = 0,
    localTeam = nil, rank = nil,
}

local RAY = { api = RaycastParams, params = nil, character = nil }

local function visibilityParams()
    local character = getChar()
    local camera = refreshCamera()
    -- a respawn gives a brand-new model: a cached filter would keep ignoring the
    -- *old* body and let every ray hit the player's own arms instead
    if RAY.params and RAY.character == character then return RAY.params end
    local ok, params = pcall(function()
        local created = RAY.api.new()
        created.FilterType = Enum.RaycastFilterType.Exclude
        local ignore = {}
        if character then ignore[#ignore + 1] = character end
        if camera then ignore[#ignore + 1] = camera end
        created.FilterDescendantsInstances = ignore
        return created
    end)
    if ok then
        RAY.params, RAY.character = params, character
    end
    return RAY.params
end

local function isVisible(character, position)
    local root = getRoot()
    if not root or not character or not position then return false end
    local camera = refreshCamera()
    local origin = camera and camera.CFrame.Position or root.Position
    local delta = position - origin
    -- an executor without RaycastParams still gets a straight-line answer
    if not RAY.api then return true end
    local params = visibilityParams()
    if not params then return true end
    local ok, result = pcall(function() return Workspace:Raycast(origin, delta, params) end)
    if not ok then return true end
    if not result then return true end
    local instance = result.Instance
    if not instance then return true end
    -- third person puts the camera inside the wall behind the player; a hit
    -- this close is the camera's own geometry, not cover in front of the target
    if (tonumber(result.Distance) or 0) < 2.5 then return true end
    return instance:IsDescendantOf(character) or instance:IsDescendantOf(camera or Workspace)
end

local function teamOf(character, player)
    if not character then return nil end
    local team = attr(character, { "Team", "TeamName", "Side" })
    if team ~= nil then return tostring(team) end
    local ok, plrTeam = pcall(function() return player and player.Team end)
    if ok and plrTeam then
        local okName, name = pcall(function() return plrTeam.Name end)
        if okName and name then return tostring(name) end
    end
    return nil
end

local function weaponOf(character)
    if not character then return nil, nil end
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then return tool, weaponInfo(tool.Name) end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then return child, weaponInfo(child.Name) end
    end
    return nil, nil
end

local function ammoOf(tool)
    if not tool then return nil, nil end
    local candidates = { "Ammo", "Magazine", "Clip", "AmmoCount", "CurrentAmmo" }
    for _, name in ipairs(candidates) do
        local value = tool:FindFirstChild(name)
        if value and value:IsA("ValueBase") then return tonumber(value.Value), name end
    end
    local value = attr(tool, { "Ammo", "Magazine", "Clip" })
    if value ~= nil then return tonumber(value), "attribute" end
    return nil, nil
end

local function playerRecord(player)
    if not player or player == LocalPlayer then return nil end
    local character = player.Character
    if not character or not character.Parent then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or (humanoid.Health or 0) <= 0 then return nil end
    local root = character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        or character.PrimaryPart
    if not root then return nil end
    local head = character:FindFirstChild("Head")
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local myRoot = getRoot()
    local position = root.Position
    local distance = myRoot and (myRoot.Position - position).Magnitude or math.huge
    local record = Cache.playerRecords[player]
    if not record then
        record = { player = player }
        Cache.playerRecords[player] = record
    end
    -- the cheap half: everything that changes while a player moves or bleeds
    record.character = character
    record.humanoid = humanoid
    record.root = root
    record.head = head
    record.torso = torso
    record.position = position
    record.health = humanoid.Health
    record.maxHealth = humanoid.MaxHealth
    record.distance = distance
    record.name = player.DisplayName or player.Name
    record.userId = player.UserId
    -- the expensive half (tool children, team attributes) is true for many
    -- frames at a time, so it is read twice a second instead of fifty times
    if os.clock() - (record.structureAt or -100) > 0.5 then
        local tool, info = weaponOf(character)
        local team = teamOf(character, player)
        record.tool = tool
        record.weapon = info
        record.weaponName = tool and tool.Name or "—"
        record.team = team
        record.structureAt = os.clock()
        State.perf.structureScans = State.perf.structureScans + 1
    end
    -- derived, not cached: a match start reassigns teams, and a dead local
    -- character briefly reports no team at all. Either way the comparison has
    -- to be re-made every pass or a teammate becomes a target for half a second
    record.friendly = World.localTeam ~= nil and record.team ~= nil
        and record.team == World.localTeam
    return record
end

local function structureScan()
    local started = os.clock()
    refreshCamera()
    local character = getChar()
    local team = teamOf(character, LocalPlayer)
    -- between death and respawn there is no local character, and wiping the
    -- team there would make every teammate a valid target for a second
    if team ~= nil then World.localTeam = team end
    World.rank = attr(character, { "Rank", "Elo", "MMR" }) or attr(LocalPlayer, { "Rank", "Elo", "MMR" })
    local tool = weaponOf(character)
    World.localWeapon = tool and tool.Name or nil
    State.perf.structureScans = State.perf.structureScans + 1
    State.perf.visits = 0
    World.structureAt = os.clock()
    State.perf.scanMs = (os.clock() - started) * 1000
end

local VisAt = -10

local function refreshWorld()
    local started = os.clock()
    local doVisibility = (os.clock() - VisAt) > 0.15
    if doVisibility then VisAt = os.clock() end
    local players = Players and Players:GetPlayers() or {}
    local list, best, bestScore = {}, nil, 0
    local visibleCount = 0
    local seen = {}
    for _, player in ipairs(players) do
        if player ~= LocalPlayer then
            seen[player] = true
            local record = playerRecord(player)
            if record then
                if doVisibility then
                    record.visible = isVisible(record.character, record.position)
                elseif record.visible == nil then
                    record.visible = false
                end
                if record.visible then visibleCount = visibleCount + 1 end
                list[#list + 1] = record
                -- priority score for the aim bot: closer, healthier and visible wins
                local score = 1 / math.max(record.distance, 1)
                if record.visible then score = score * 2 end
                if record.health and record.maxHealth and record.maxHealth > 0 then
                    score = score * (1.6 - 0.6 * (record.health / record.maxHealth))
                end
                if record.friendly then score = -1 end
                if score > bestScore then best, bestScore = record, score end
            end
        end
    end
    for player in pairs(Cache.playerRecords) do
        if not seen[player] then Cache.playerRecords[player] = nil end
    end
    World.players = list
    World.count = #list
    World.visibleCount = visibleCount
    World.best, World.bestScore = best, bestScore
    World.at = os.clock()
    local inMatch = #list > 0
    if inMatch ~= State.inMatch then
        if inMatch then
            -- a match just started: teams, ranks and every character were
            -- reassigned in the same tick. Drop the cached structures so the
            -- next pass reads the arena instead of the lobby.
            World.structureAt = -100
            VisAt = -100
            Cache.playerRecords = {}
            State.target = nil
        end
        State.matchSince = inMatch and os.clock() or 0
    end
    State.inMatch = inMatch
    State.perf.refreshCalls = State.perf.refreshCalls + 1
    State.perf.scanMs = (os.clock() - started) * 1000
    return World
end

local function scanWorld(force)
    local now = os.clock()
    if force or now - World.structureAt > (tonumber(Config.ScanInterval) or 0.6) then
        structureScan()
    end
    return refreshWorld()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 9 · COMBAT
--     RIVALS resolves hits on the server, so everything here is a client-side
--     input: rotate the camera, move the mouse, press the button. This hub has
--     no way to make a shot land, and it does not pretend otherwise.
-- ═══════════════════════════════════════════════════════════════════════════

-- forward declarations: assigned in sections 11-15, but the combat code below
-- calls them, so they have to exist as upvalues before this point
local AC, findRemote, fireRemote, playSound, killEffect, hitSpark, patchWeaponStats

local Aim = {
    shotTimes = {},
    active = false, aimPosition = nil, recoil = nil,
    renderBound = false, lastMethod = nil,
}

-- Every long-lived worker runs its frame through here. A single unexpected
-- error used to end the coroutine silently — aim would work in the lobby and
-- then stop dead the first time a match replaced the character or the camera.
local function protectLoop(name, body)
    local ok, err = pcall(body)
    if ok then return end
    State.perf.loopErrors = (State.perf.loopErrors or 0) + 1
    local log = SharedEnv.__SkillHubErrorLog
    if log and #log < 40 then
        table.insert(log, tostring(name) .. ": " .. tostring(err))
    end
end

local function viewport()
    local camera = refreshCamera()
    local size = camera and camera.ViewportSize or Vector2.new(1280, 720)
    return size
end

local function screenOf(position)
    local camera = refreshCamera()
    if not camera or not position then return nil, false, 0 end
    local ok, point, onScreen = pcall(function()
        local view, visible = camera:WorldToViewportPoint(position)
        return view, visible
    end)
    if not ok or not point then return nil, false, 0 end
    return Vector2.new(point.X, point.Y), onScreen, point.Z
end

local function crosshairDistance(position)
    local point, onScreen, depth = screenOf(position)
    if not point or depth <= 0 then return math.huge, false end
    local size = viewport()
    local center = Vector2.new(size.X / 2, size.Y / 2)
    return (point - center).Magnitude, onScreen
end

local function aimPartOf(record)
    if not record then return nil end
    local part = Config.AimPart or "Head"
    if part == "Head" then
        return record.head or record.root
    elseif part == "Torso" then
        return record.torso or record.root
    elseif part == "Random" then
        local options = { record.head, record.torso, record.root }
        local pool = {}
        for _, option in ipairs(options) do if option then pool[#pool + 1] = option end end
        return pool[math.random(1, math.max(#pool, 1))]
    end
    -- Nearest: whichever of head and torso is closer to the screen centre
    local headDistance = record.head and crosshairDistance(record.head.Position) or math.huge
    local torsoDistance = record.torso and crosshairDistance(record.torso.Position) or math.huge
    if torsoDistance < headDistance then return record.torso or record.root end
    return record.head or record.root
end

local function aimPositionOf(record)
    local part = aimPartOf(record)
    if not part then return nil end
    local position = part.Position
    if Config.AimPrediction and record.root then
        local ok, velocity = pcall(function() return record.root.AssemblyLinearVelocity end)
        if ok and velocity then
            position = position + velocity * (tonumber(Config.AimPredictionFactor) or 0.12)
        end
    end
    return position
end

local function targetAllowed(record)
    if not record or not record.root or not record.root.Parent then return false end
    if Config.AimTeamCheck and record.friendly then return false end
    if (record.distance or math.huge) > (tonumber(Config.AimRange) or 600) then return false end
    if Config.AimVisibleOnly and not record.visible then return false end
    return true
end

-- the aim cone, in degrees either side of the crosshair. Without this the
-- "closest to crosshair" score happily picks someone standing behind you, and
-- in a full match the camera spends the round spinning instead of aiming.
local function aimCone()
    return math.clamp(tonumber(Config.AimFov) or 140, 10, 360) * 0.5
end

local function angleTo(position)
    local camera = refreshCamera()
    if not camera or not position then return 180 end
    local origin = camera.CFrame.Position
    local delta = position - origin
    if delta.Magnitude < 0.01 then return 0 end
    local look = camera.CFrame.LookVector
    return math.deg(math.acos(math.clamp(look:Dot(delta.Unit), -1, 1)))
end

-- the same score the picker uses, exposed so the hysteresis below can compare
local function scoreFor(record, mode)
    if mode == "Closest" then return record.distance end
    if mode == "Lowest health" then return record.health or math.huge end
    local pixels = crosshairDistance(record.position)
    if not record.visible then pixels = pixels + 400 end
    return pixels
end

local function pickTarget()
    local best, bestScore = nil, math.huge
    local mode = Config.AimPriority or "Closest to crosshair"
    local cone = aimCone()
    for _, record in ipairs(World.players) do
        if targetAllowed(record) and angleTo(record.position) <= cone then
            local score = scoreFor(record, mode)
            if score < bestScore then best, bestScore = record, score end
        end
    end
    -- hysteresis: two neighbours a few pixels apart would swap every frame, and
    -- a camera that flickers between them is worse than either one alone
    local previous = State.target
    if best and previous and previous ~= best and targetAllowed(previous)
        and angleTo(previous.position) <= cone then
        local previousScore = scoreFor(previous, mode)
        if previousScore <= bestScore * 1.25 then
            return previous, previousScore
        end
    end
    return best, bestScore
end

-- one frame of aim, with the rate limit applied in degrees per step
-- Roblox headings: yaw 0 looks down -Z, turning right decreases yaw, pitch is
-- positive upwards. math.atan2 is gone in Lua 5.4+, so the two-argument atan is
-- the portable form; Luau keeps atan2, which is picked first.
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

local function headingOf(direction)
    local yaw = math.deg(atan2(-direction.X, -direction.Z))
    local pitch = math.deg(math.asin(math.clamp(direction.Y, -1, 1)))
    return yaw, pitch
end

local function wrapDegrees(angle)
    angle = angle % 360
    if angle > 180 then angle = angle - 360 end
    return angle
end

-- The mouse only rotates the camera while the game has the cursor locked. In a
-- menu the same call just drags the visible pointer across the screen, so the
-- camera path is used there instead.
local function mouseLocked()
    if not UserInput then return true end
    local behavior = UserInput.MouseBehavior
    if behavior == nil then return true end
    return behavior ~= Enum.MouseBehavior.Default
end

-- One frame of aim.
--
-- Camera writes survive only until the game's own camera script recomputes the
-- view — in RIVALS that happens every frame, which is why a CFrame-only aim bot
-- looks dead in a match while working fine in the lobby. Moving the *mouse*
-- feeds the game's controller instead, so its internal yaw/pitch follow. Hybrid
-- does that, measures how far the view actually turned, and falls back to a
-- direct CFrame write the moment the cursor is not controlling the camera.
local function stepAim(record, delta)
    local camera = refreshCamera()
    if not camera or not camera.Parent or not record then return false end
    local goalPosition = aimPositionOf(record)
    if not goalPosition then return false end
    Aim.aimPosition = goalPosition

    local current = camera.CFrame
    local origin = current.Position
    local to = goalPosition - origin
    if to.Magnitude < 0.05 then return false end
    local want = to.Unit
    local look = current.LookVector
    local total = math.deg(math.acos(math.clamp(look:Dot(want), -1, 1)))

    local smooth = math.clamp(tonumber(Config.AimSmooth) or 0.35, 0, 0.95)
    local alpha = 1 - smooth
    if Config.AimHumanize then alpha = alpha * (0.88 + math.random() * 0.24) end
    local limit = math.max(1, tonumber(Config.AimStepLimit) or 9)
    -- the "Aim rate limit" switch is the one that owns this ceiling; with it off
    -- the step is still smoothed, it just is not clamped to N degrees a frame
    if Config.AcAimRateLimit == false then limit = math.huge end
    local step = total > 0.01 and math.min(total * alpha, limit) or 0

    if Aim.mouseWorks == false and os.clock() >= (Aim.mouseRetry or 0) then
        Aim.mouseWorks = nil   -- retry: the player may have entered a match
        Aim.perPixel = nil
    end
    local method = Config.AimMethod or "Hybrid"
    local wantMouse = (method == "Hybrid" or method == "Mouse")
    local mouseReady = type(mousemoverel) == "function"
        and Aim.mouseWorks ~= false and mouseLocked()

    if wantMouse and mouseReady and step > 0 then
        local yaw, pitch = headingOf(look)
        local wantYaw, wantPitch = headingOf(want)
        local dYaw = wrapDegrees(wantYaw - yaw)
        local dPitch = wantPitch - pitch
        local scale = step / math.max(total, 0.0001)
        -- one pixel of mouse travel turns the view by `perPixel` degrees; the
        -- number is measured back from the camera after every move, so an
        -- unusual in-game sensitivity is learned instead of guessed
        local perPixel = math.clamp(tonumber(Aim.perPixel) or tonumber(Config.AimMouseSensitivity)
            or 0.35, 0.03, 3)
        local px = -dYaw * scale / perPixel
        local py = -dPitch * scale / perPixel
        if Config.AimHumanize then
            px = px + (math.random() - 0.5) * 1.4
            py = py + (math.random() - 0.5) * 1.4
        end
        if math.abs(px) >= 0.01 or math.abs(py) >= 0.01 then
            local ok = pcall(mousemoverel, px, py)
            if ok then
                Aim.lastMethod = "mouse"
                Aim.lastPixels = { x = px, y = py }
                Aim.pending = { from = look, degrees = step, at = os.clock() }
                State.perf.writes = (State.perf.writes or 0) + 1
                return true
            end
        end
        if method == "Mouse" then return false end
    end

    if step <= 0 then return false end
    local goal = CFrame.lookAt(origin, goalPosition)
    local writeAlpha = math.clamp(step / math.max(total, 0.0001), 0, 1)
    local blended = current:Lerp(goal, writeAlpha)
    pcall(function() camera.CFrame = blended end)
    -- a little downward pull cancels the upward kick a real weapon applies
    Aim.lastMethod = "camera"
    State.perf.writes = (State.perf.writes or 0) + 1
    return true
end

-- Measured on the frame after a mouse move: how much of the requested rotation
-- the camera actually performed. Three misses in a row mean the cursor is not
-- driving the view (menu, Scriptable camera, third person without right click),
-- and the CFrame path takes over until the mouse is worth trying again.
local function noteMouseResult()
    local pending = Aim.pending
    if not pending then return end
    Aim.pending = nil
    if os.clock() - pending.at > 0.5 or pending.degrees < 0.6 then return end
    local camera = refreshCamera()
    if not camera then return end
    local moved = math.deg(math.acos(math.clamp(pending.from:Dot(camera.CFrame.LookVector), -1, 1)))
    local ratio = moved / pending.degrees
    if ratio < 0.25 then
        Aim.mouseFails = (Aim.mouseFails or 0) + 1
        if Aim.mouseFails >= 3 then
            Aim.mouseWorks = false
            Aim.mouseRetry = os.clock() + 1.5
            Aim.mouseFails = 0
            State.perf.aimFallbacks = (State.perf.aimFallbacks or 0) + 1
        end
        return
    end
    Aim.mouseFails = 0
    Aim.mouseWorks = true
    if ratio > 0.5 and ratio < 4 then
        Aim.perPixel = math.clamp((Aim.perPixel or tonumber(Config.AimMouseSensitivity) or 0.35) * ratio, 0.03, 3)
    end
end

local function silentAimPosition()
    if Config.AimMethod ~= "Silent" or not Config.AimEnabled then return nil end
    local record = State.target
    if not targetAllowed(record) then return nil end
    return aimPositionOf(record)
end

-- ── weapon automation ─────────────────────────────────────────────────────
local function pressKey(name, duration)
    local keyCode = Enum.KeyCode[name]
    if not keyCode then return false end
    if VirtualUser then
        pcall(function() VirtualUser:SendKeyEvent(true, keyCode) end)
        task.delay(duration or 0.06, function()
            safeCall("key up", function() VirtualUser:SendKeyEvent(false, keyCode) return true end)
        end)
        return true
    end
    if type(keypress) == "function" then return pcall(keypress, tonumber(keyCode.Value) or 0) end
    return false
end

local function clickMouse()
    if type(mouse1click) == "function" then return pcall(mouse1click) end
    if VirtualUser then
        return safeCall("mouse", function()
            VirtualUser:SendMouseButtonEvent(0, 0, 0, false)
            return true
        end) == true
    end
    return false
end

local function reloadNow()
    local tool = weaponOf(getChar())
    if not tool then return false end
    local ammo, source = ammoOf(tool)
    if ammo == nil then return false end
    if ammo > 0 then return false end
    if os.clock() - (State.lastReload or 0) < 0.8 then return false end
    State.lastReload = os.clock()
    local remote = findRemote(LOWER.Reload)
    if remote then
        fireRemote(remote, tool)
        return true
    end
    return pressKey("R")
end

local function switchWeapon()
    if os.clock() - (State.lastSwitch or 0) < 1.2 then return false end
    State.lastSwitch = os.clock()
    local tool = weaponOf(getChar())
    local info = tool and weaponInfo(tool.Name)
    if info and info.Slot == "Primary" then
        return pressKey("2")      -- out of primary ammo: try the secondary
    end
    return pressKey("1")
end

local function meleeNow()
    local best = nil
    for _, record in ipairs(World.players) do
        if targetAllowed(record) and record.distance <= (tonumber(Config.AutoKnifeRange) or 9) then
            if not best or record.distance < best.distance then best = record end
        end
    end
    if not best then return false end
    local tool = weaponOf(getChar())
    local info = tool and weaponInfo(tool.Name)
    if info and info.Slot == "Melee" then return clickMouse() end
    if os.clock() - (State.lastKnife or 0) < 1.5 then return false end
    State.lastKnife = os.clock()
    return pressKey("3")
end

local function scope(on)
    on = on and true or false
    -- the combat loop asks for this fifty times a second; pressing the button
    -- fifty times a second is not the same thing as holding it
    if Aim.scoped == on then return false end
    Aim.scoped = on
    if on then
        if type(mouse2press) == "function" then return pcall(mouse2press) end
        return false
    end
    if type(mouse2release) == "function" then return pcall(mouse2release) end
    if type(mouse2click) == "function" then return pcall(mouse2click) end
    return false
end

-- ── fire cadence ──────────────────────────────────────────────────────────

local function canShoot()
    local now = os.clock()
    local keep = {}
    for _, time in ipairs(Aim.shotTimes) do
        if now - time < 1 then keep[#keep + 1] = time end
    end
    Aim.shotTimes = keep
    local cap = math.min(tonumber(Config.FireRateCap) or 14, tonumber(Config.AcShotRateLimit) or 10)
    if Config.AcSafeMode then cap = math.min(cap, 8) end
    if #Aim.shotTimes >= cap then
        State.shotsBlocked = State.shotsBlocked + 1
        State.perf.skips = State.perf.skips + 1
        return false
    end
    return true
end

local function markShot()
    Aim.shotTimes[#Aim.shotTimes + 1] = os.clock()
    State.shots = State.shots + 1
    State.lastShot = os.clock()
end

local function fire()
    if not isAlive() then return false end
    if not canShoot() then return false end
    if Config.HumanizeFire then
        if math.random() < 0.04 then return false end     -- an occasional missed beat
    end
    -- sampled before the click: this is the orientation the kick is measured
    -- against, because the recoil is applied by the game after the shot lands
    local liveCamera = refreshCamera()
    local preShot = liveCamera and liveCamera.CFrame or nil
    local ok = clickMouse()
    if ok then
        markShot()
        if Config.HitSparks then hitSpark(Aim.aimPosition) end
        if Config.HitSound then playSound(Config.HitSoundId, 0.35) end
        State.lastTargetName = State.target and State.target.name or State.lastTargetName
        if Config.NoRecoil and preShot then Aim.recoil = preShot end
    end
    return ok
end

-- ── recoil and spread ─────────────────────────────────────────────────────
-- ── frame-rate aim ─────────────────────────────────────────────────────────
-- The combat loop picks the target at 50 Hz; the rotation itself belongs on the
-- render step, after the game's own camera update, or the game overwrites it.
local function startRenderAim()
    if Aim.renderBound then return true end
    if not RunService then return false end
    local function frame(delta)
        Aim.renderSteps = (Aim.renderSteps or 0) + 1
        noteMouseResult()
        if not State.alive or not Config.AimEnabled then return end
        local record = State.target
        if not record or not record.root or not record.root.Parent then return end
        if not isAlive() then return end
        State.beats.aim = os.clock()
        stepAim(record, math.clamp(delta or 0.016, 0.001, 0.05))
    end
    local ok, bound = pcall(function()
        if type(RunService.BindToRenderStep) == "function" then
            RunService:BindToRenderStep("SkillHubAim", 201, frame)
            return true
        end
        if RunService.RenderStepped and type(RunService.RenderStepped.Connect) == "function" then
            RunService.RenderStepped:Connect(frame)
            return true
        end
        return false
    end)
    Aim.renderBound = ok == true and bound == true
    if Aim.renderBound and Config.LogLevel >= 1 then
        print("[Skill Hub] aim · render-step driver bound")
    end
    return Aim.renderBound
end

local function recoilLoop()
    task.spawn(function()
        while State.alive do
            task.wait(0.02)
            State.beats.recoil = os.clock()
            protectLoop("recoil", function()
                local camera = refreshCamera()
                if Config.NoRecoil and Aim.recoil and camera then
                    local now = os.clock()
                    if now - (State.lastShot or 0) < 0.18 then
                        local current = camera.CFrame
                        local storedLook = Aim.recoil.LookVector
                        -- the position is kept from *now* (the player may have moved
                        -- or turned) and only the pre-shot orientation eased back in
                        if storedLook and storedLook.Magnitude > 0 then
                            local goal = CFrame.lookAt(current.Position, current.Position + storedLook)
                            pcall(function() camera.CFrame = current:Lerp(goal, 0.55) end)
                        end
                    else
                        Aim.recoil = nil
                    end
                end
            end)
        end
    end)
end

local Patch = { tables = 0, fields = 0, seen = setmetatable({}, { __mode = "k" }) }

function patchWeaponStats()
    if not (Config.NoRecoil or Config.NoSpread) then return 0 end
    if type(getgc) ~= "function" then return 0 end
    local patched = 0
    local ok = safeCall("weapon patch", function()
        for _, object in ipairs(getgc(true)) do
            if type(object) == "table" and not Patch.seen[object] then
                Patch.seen[object] = true
                for key, value in pairs(object) do
                    if type(key) == "string" and type(value) == "number" then
                        local low = string.lower(key)
                        local isRecoil = Config.NoRecoil and string.find(low, "recoil", 1, true)
                        local isSpread = Config.NoSpread and string.find(low, "spread", 1, true)
                        if (isRecoil or isSpread) and value > 0 and value < 100 then
                            if pcall(function() rawset(object, key, 0) end) then
                                patched = patched + 1
                            end
                        end
                    end
                end
            end
        end
        return true
    end)
    if ok then
        Patch.fields = Patch.fields + patched
        if patched > 0 then
            Patch.tables = Patch.tables + 1
            if Config.LogLevel >= 2 then
                print(string.format("[Skill Hub] weapon stats · %d field(s) zeroed", patched))
            end
        end
    end
    return patched
end

-- ── kill tracking ─────────────────────────────────────────────────────────

local function trackKills()
    local alive = {}
    for _, record in ipairs(World.players) do alive[record.userId] = record.name end
    for userId, name in pairs(State.lastTargets) do
        if not alive[userId] then
            State.lastTargets[userId] = nil
            if os.clock() - (State.lastShot or 0) < 4 then
                State.kills = State.kills + 1
                State.streak = (State.streak or 0) + 1
                if Config.KillSound then playSound(Config.KillSoundId, 0.6) end
                if Config.KillEffect then killEffect() end
            end
        end
    end
    for _, record in ipairs(World.players) do
        State.lastTargets[record.userId] = record.name
    end
end

local function combatLoop()
    task.spawn(function()
        while State.alive do
            task.wait(0.02)
            if not State.alive then break end
            State.beats.combat = os.clock()
            -- RIVALS hands out a new character when a match loads and after every
            -- death. Rebind here, once, so the aim, the movement write cache and
            -- the visibility filter all point at the body that is alive now.
            local character = getChar()
            if character and character ~= State.boundCharacter then
                if onCharacterChanged then pcall(onCharacterChanged, character)
                else State.boundCharacter = character end
            end
            protectLoop("combat loop", function()
                -- idle frames cost nothing: with aim, trigger and every
                -- automation switch off there is no reason to scan fifteen
                -- players fifty times a second. The ESP loop keeps the world
                -- fresh at its own pace.
                local active = Config.AimEnabled or Config.TriggerBot or Config.AutoFire
                    or Config.AutoReload or Config.AutoSwitch or Config.AutoKnife
                if Config.NoRecoil or Config.NoSpread then
                    if os.clock() - (State.lastWeaponPatch or -100) > 5 then
                        State.lastWeaponPatch = os.clock()
                        patchWeaponStats()
                    end
                end
                if not active then
                    State.target = nil
                else
                    scanWorld(false)
                    local record = pickTarget()
                    State.target = record
                    trackKills()
                    -- while dead the game hands the camera to a spectate target;
                    -- dragging it around then is both useless and loud
                    if Config.AimEnabled and record and isAlive() then
                        -- the cone and the ray were already checked when the
                        -- target was picked; this flag only exists for people who
                        -- want the camera to stop at cover
                        local keep = true
                        if Config.AimWallCheck and not record.visible and Config.AimVisibleOnly then keep = false end
                        -- human pause: a few frames are skipped on purpose so the
                        -- camera does not track like a machine for minutes on end
                        local pause = Config.HumanPause and math.random() < 0.02
                        -- with the render-step driver bound the camera is moved
                        -- at frame rate; stepping here too would double the speed
                        if keep and not pause and not Aim.renderBound then
                            noteMouseResult()
                            State.beats.aim = os.clock()
                            stepAim(record, 0.02)
                        end
                        if Config.AutoScope then scope(true) else scope(false) end
                    else
                        -- not just "AutoScope was switched off": the target may
                        -- simply be gone, and the button must not stay held
                        scope(false)
                    end
                    if Config.TriggerBot and record then
                        local trigger = false
                        if Config.TriggerMode == "FOV" then
                            local pixels = crosshairDistance(record.position)
                            trigger = pixels <= (tonumber(Config.TriggerFov) or 7)
                        else
                            local pixels, onScreen = crosshairDistance(record.position)
                            trigger = onScreen and pixels <= math.max(2, (tonumber(Config.TriggerFov) or 7) * 0.5)
                        end
                        if trigger and (not Config.TriggerVisibleOnly or record.visible)
                            and (not Config.TriggerTeamCheck or not record.friendly) then
                            if os.clock() - (State.lastTrigger or 0) >= math.max(0.01, tonumber(Config.TriggerDelay) or 0.06) then
                                State.lastTrigger = os.clock()
                                fire()
                            end
                        end
                    end
                    if Config.AutoFire and record and record.visible then
                        if os.clock() - (State.lastShot or 0) >= 1 / math.max(1, tonumber(Config.FireRateCap) or 14) then
                            fire()
                        end
                    end
                    if Config.AutoReload then
                        local ammo = ammoOf(weaponOf(getChar()))
                        if ammo == 0 then reloadNow() end
                    end
                    if Config.AutoSwitch then
                        local ammo = ammoOf(weaponOf(getChar()))
                        if ammo == 0 and os.clock() - (State.lastReload or 0) > 1.4 then switchWeapon() end
                    end
                    if Config.AutoKnife then meleeNow() end
                end
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 10 · MOVEMENT — one heartbeat owns every movement toggle
-- ═══════════════════════════════════════════════════════════════════════════
local Mov = { flyBody = nil, flyLoop = false, noclip = false, lastJump = 0, lastVoid = 0, lastFling = 0 }

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
        State.perf.writes = State.perf.writes + 1
        return true
    end
    return false
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

function Mov.stopFly()
    Mov.flyLoop = false
    if Mov.flyBody and Mov.flyBody.Parent then Mov.flyBody:Destroy() end
    Mov.flyBody = nil
    local humanoid = getHumanoid()
    if humanoid then safeCall("fly off", function() humanoid.PlatformStand = false return true end) end
    return true
end

local function startFly()
    local root, humanoid = getRoot(), getHumanoid()
    if not root or not humanoid then return false end
    Mov.stopFly()
    safeCall("fly", function()
        local body = Instance.new("BodyVelocity")
        -- deliberately the default name: a script that looks for "SkillHubFly"
        -- under the character finds nothing
        body.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        body.Velocity = Vector3.zero
        body.Parent = root
        Mov.flyBody, Mov.flyLoop = body, true
        humanoid.PlatformStand = true
        return true
    end)
    return Mov.flyBody ~= nil
end

local function moveAxes()
    local axes = { X = 0, Y = 0, Z = 0 }
    if not UserInput then return axes end
    pcall(function()
        if UserInput:IsKeyDown(Enum.KeyCode.W) then axes.Z = axes.Z + 1 end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then axes.Z = axes.Z - 1 end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then axes.X = axes.X + 1 end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then axes.X = axes.X - 1 end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then axes.Y = axes.Y + 1 end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then axes.Y = axes.Y - 1 end
        return true
    end)
    return axes
end

local function flyStep()
    local root, camera = getRoot(), Camera
    if not root or not Mov.flyBody then return end
    local direction = Vector3.zero
    if camera then
        local axes = moveAxes()
        direction = camera.CFrame.LookVector * axes.Z + camera.CFrame.RightVector * axes.X
        direction = direction + Vector3.new(0, axes.Y, 0)
    end
    if direction.Magnitude > 0 then direction = direction.Unit end
    local speed = math.clamp(tonumber(Config.FlySpeed) or 80, 8, 4000)
    if Config.AcSafeMode then speed = math.min(speed, tonumber(Config.AcSpeedCeiling) or 60) end
    pcall(function() Mov.flyBody.Velocity = direction * speed end)
end

local function setNoclip(enabled)
    Mov.noclip = enabled
    local character = getChar()
    if not character then return end
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
            pcall(function() descendant.CanCollide = not enabled end)
        end
    end
end

local function movementLoop()
    task.spawn(function()
        while State.alive do
            task.wait(0.05)
            State.beats.movement = os.clock()
            protectLoop("movement", function()
            local character = getChar()
            if character and isAlive() then
                local humanoid, root = getHumanoid(), getRoot()
                local wanted = 16
                if Config.WalkSpeedEnabled then
                    wanted = math.clamp(tonumber(Config.WalkSpeed) or 26, 16, 4000)
                    if Config.AcSafeMode then wanted = math.min(wanted, tonumber(Config.AcSpeedCeiling) or 60) end
                    setWalkSpeed(wanted)
                elseif WriteCache.speed and WriteCache.speed ~= 16 then
                    -- just switched off: hand 16 back once, then stop writing. A
                    -- hub that keeps pinning WalkSpeed to 16 fights the game's own
                    -- speed modifiers (paintball, heavy weapons) every tick.
                    setWalkSpeed(16)
                end
                if Config.JumpPowerEnabled then
                    setJumpPower(Config.JumpPower)
                elseif WriteCache.jump and WriteCache.jump ~= 50 then
                    setJumpPower(50)
                end
                if Config.AlwaysSprint and humanoid and humanoid.WalkSpeed < wanted then
                    pcall(function() humanoid.WalkSpeed = wanted end)
                end
                if Config.InfiniteJump and humanoid then
                    local state = humanoid:GetState()
                    if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
                        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
                    end
                end
                if Config.BunnyHop and humanoid and root then
                    if humanoid:GetState() == Enum.HumanoidStateType.Landed
                        or humanoid:GetState() == Enum.HumanoidStateType.Running then
                        if os.clock() - Mov.lastJump > 0.25 then
                            Mov.lastJump = os.clock()
                            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
                        end
                    end
                end
                if Config.FlyEnabled then
                    if not Mov.flyBody then startFly() end
                    flyStep()
                elseif Mov.flyBody then
                    Mov.stopFly()
                end
                if Config.Noclip ~= Mov.noclip then setNoclip(Config.Noclip) end
                if root and humanoid then
                    local position = root.Position
                    if Config.AntiVoid and position.Y < -180 and os.clock() - Mov.lastVoid > 1.5 then
                        Mov.lastVoid = os.clock()
                        pcall(function() root.CFrame = CFrame.new(0, 30, 0) end)
                    end
                    local ok, velocity = pcall(function() return root.AssemblyLinearVelocity end)
                    if ok and velocity and Config.AntiFling and velocity.Magnitude > 420
                        and os.clock() - Mov.lastFling > 0.5 then
                        Mov.lastFling = os.clock()
                        pcall(function() root.AssemblyLinearVelocity = Vector3.zero end)
                    end
                    if Config.AntiRagdoll then
                        local state = humanoid:GetState()
                        if state == Enum.HumanoidStateType.Ragdoll
                            or state == Enum.HumanoidStateType.FallingDown
                            or state == Enum.HumanoidStateType.PlatformStanding then
                            pcall(function()
                                humanoid.PlatformStand = false
                                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                            end)
                        end
                    end
                    if Config.AntiStun and humanoid.WalkSpeed <= 1 and wanted >= 16 then
                        WriteCache.speed = nil
                    end
                end
            end
            end)
        end
    end)
end

local function fallGuard()
    task.spawn(function()
        while State.alive do
            task.wait(0.25)
            State.beats.fall = os.clock()
            protectLoop("fall guard", function()
            local humanoid, root = getHumanoid(), getRoot()
            if humanoid and root and Config.NoFallDamage and isAlive() then
                if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                    local ok, velocity = pcall(function() return root.AssemblyLinearVelocity end)
                    if ok and velocity and velocity.Y < -95 then
                        pcall(function()
                            root.AssemblyLinearVelocity = Vector3.new(velocity.X, math.max(velocity.Y, -95), velocity.Z)
                        end)
                    end
                end
            end
            end)
        end
    end)
end
-- ═══════════════════════════════════════════════════════════════════════════
-- 11 · REMOTES — one index, one rate limiter, no guessing every frame
-- ═══════════════════════════════════════════════════════════════════════════
-- Lua 5.5 dropped the global `unpack`; Luau kept it. Bind whichever exists.
local unpack = table.unpack or unpack

local Remotes = { list = {}, at = -100, byName = {}, fired = {}, blocked = 0 }

local function collectRemotes()
    local started = os.clock()
    local list, byName = {}, {}
    local roots = { ReplicatedStorage, getService("ReplicatedFirst") }
    for _, root in ipairs(roots) do
        if root then
            for _, descendant in ipairs(root:GetDescendants()) do
                if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
                    list[#list + 1] = descendant
                    local key = lower(descendant.Name)
                    byName[key] = byName[key] or descendant
                end
            end
        end
    end
    Remotes.list, Remotes.byName, Remotes.at = list, byName, os.clock()
    if Config.PerfStats then
        print(string.format("[Skill Hub] remotes · %d indexed in %.1f ms", #list, (os.clock() - started) * 1000))
    end
    return list
end

local function remoteIndex()
    if os.clock() - (Remotes.at or -100) > 15 then collectRemotes() end
    return Remotes.byName
end

function findRemote(words, kind)
    if type(words) == "string" then words = { words } end
    if #words == 0 then return nil, nil end
    local index = remoteIndex()
    -- word order is priority: "queue" must win over the "match" in LeaveMatch,
    -- so the first word with a hit decides, and only then the shortest name
    for _, word in ipairs(words) do
        local best, bestName = nil, nil
        for key, remote in pairs(index) do
            if (not kind or remote:IsA(kind)) and string.find(key, word, 1, true) then
                if not bestName or #key < #bestName then best, bestName = remote, key end
            end
        end
        if best then return best, bestName end
    end
    return nil, nil
end

-- pacing: a remote that the hub spams is one of the clearest client-side
-- fingerprints there is, so every call goes through one token bucket
local function remoteAllowed(key)
    local now = os.clock()
    local record = Remotes.fired[key]
    if not record then
        record = { times = {} }
        Remotes.fired[key] = record
    end
    local keep = {}
    for _, time in ipairs(record.times) do
        if now - time < 1 then keep[#keep + 1] = time end
    end
    record.times = keep
    local limit = math.max(2, tonumber(Config.AcRemoteRateLimit) or 20)
    if #keep >= limit then
        Remotes.blocked = Remotes.blocked + 1
        return false
    end
    keep[#keep + 1] = now
    return true
end

function fireRemote(remote, ...)
    if not remote then return false end
    if not remoteAllowed(lower(remote.Name)) then return false end
    local args = { ... }
    local ok = safeCall("remote " .. tostring(remote.Name), function()
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(unpack(args))
        end
        remote:FireServer(unpack(args))
        return true
    end)
    return ok ~= nil
end

local function callRemote(remote, ...)
    if not remote then return nil end
    local args = { ... }
    return safeCall("invoke " .. tostring(remote.Name), function()
        return remote:InvokeServer(unpack(args))
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 12 · ANTI-CHEAT LAYERS
--     Six independent layers. Each arms separately and reports whether it
--     actually installed anything, so the tab can show the truth instead of
--     a row of green ticks. `AC.armed` is also what the self-test reads.
-- ═══════════════════════════════════════════════════════════════════════════
AC = {
    armed = {},
    originalNamecall = nil,
    namecallInstalled = false,
    intern = false,
    blocked = 0,
    allowed = 0,
    kicks = 0,
    detectorCount = 0,
    patchedFields = 0,
    camoReads = 0,
    lastLimitScan = -100,
    lastDetectorScan = -100,
    hookedIndex = false,
    rateLimited = 0,
}

local function disableDetectors()
    if not Config.AcNeutralize then AC.armed.detectors = false return false end
    if os.clock() - (AC.lastDetectorScan or 0) < 4 then return AC.armed.detectors == true end
    AC.lastDetectorScan = os.clock()
    local disabled = 0
    local scanned = 0
    local roots = { ReplicatedStorage, getService("ReplicatedFirst"), Players and Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerScripts") }
    for _, root in ipairs(roots) do
        if root then
            for _, descendant in ipairs(root:GetDescendants()) do
                scanned = scanned + 1
                if scanned > math.max(200, tonumber(Config.ScanBudget) or 400) then break end
                if descendant:IsA("Script") or descendant:IsA("LocalScript") then
                    local matched = containsAny(descendant.Name, LOWER.Detectors)
                    if matched then
                        local ok = pcall(function()
                            descendant.Disabled = true
                            return true
                        end)
                        if ok then disabled = disabled + 1 end
                    end
                end
            end
        end
    end
    AC.detectorCount = disabled
    AC.armed.detectors = true
    if Config.LogLevel >= 2 and disabled > 0 then
        print(string.format("[Skill Hub] ac · %d detector script(s) disabled", disabled))
    end
    return true
end

local function namecallFilter(self, ...)
    -- NOTE: this function runs inside the __namecall hook, so it must never
    -- call a method on `self` — `self:IsA()` would re-enter this hook and
    -- recurse. ClassName and Name are property reads, which are safe.
    local method
    if type(getnamecallmethod) == "function" then
        method = getnamecallmethod()
    end
    -- only outgoing calls are filtered: blocking IsA / GetAttribute on a remote
    -- named "…Report…" would break the game's own code and this hub's index.
    -- ClassName and Name are plain property reads, which cannot re-enter the
    -- __namecall hook, and the hot path (every other method call in the game)
    -- leaves after two string comparisons without allocating anything.
    local outgoing = method == "FireServer" or method == "InvokeServer"
    local class
    if outgoing then class = self.ClassName end
    if outgoing
        and (class == "RemoteEvent" or class == "UnreliableRemoteEvent" or class == "RemoteFunction") then
        local name = self.Name
        if name then
            local low = lower(name)
            if Config.AcBlockReports then
                local matched = containsAny(low, LOWER.Reports)
                if matched then
                    local exempt = false
                    for _, safeWord in ipairs(KNOWLEDGE.SafeReportExceptions) do
                        if string.find(low, safeWord, 1, true) then exempt = true break end
                    end
                    if not exempt then
                        AC.blocked = AC.blocked + 1
                        return nil
                    end
                end
            end
        end
    end
    -- silent aim: only the shoot remote, only a CFrame or a unit Vector3
    -- argument. RIVALS usually lets the server read the camera, in which case
    -- there is nothing to rewrite and this does nothing at all.
    if outgoing and Config.AimEnabled and Config.AimMethod == "Silent" and class ~= "RemoteFunction" then
        local cachedShoot = Remotes.shoot
        if cachedShoot == nil then
            cachedShoot = findRemote(LOWER.Shoot) or false
            Remotes.shoot = cachedShoot
        end
        if cachedShoot and self == cachedShoot then
            local goal = silentAimPosition()
            local camera = refreshCamera()
            if goal and camera then
                local origin = camera.CFrame.Position
                local direction = goal - origin
                if direction.Magnitude > 0.1 then
                    local args = table.pack(...)
                    local rewritten = false
                    for index = 2, args.n do
                        local value = args[index]
                        if type(value) == "table" then
                            if value.LookVector ~= nil and value.Position ~= nil then
                                args[index] = CFrame.lookAt(value.Position, goal)
                                rewritten = true
                            elseif value.Magnitude ~= nil and value.Magnitude <= 1.5 then
                                args[index] = direction.Unit
                                rewritten = true
                            end
                        end
                    end
                    if rewritten then
                        local packed = table.pack(AC.originalNamecall(self, unpack(args, 1, args.n)))
                        return unpack(packed, 1, packed.n)
                    end
                end
            end
        end
    end
    if method == "Kick" and self == LocalPlayer and Config.AcKickGuard then
        AC.kicks = AC.kicks + 1
        -- swallowing the kick keeps the client in the server it is already in;
        -- it does not undo the ban that follows later
        return nil
    end
    AC.allowed = AC.allowed + 1
    return AC.originalNamecall(self, ...)
end

local function installNamecall()
    if AC.namecallInstalled then AC.armed.namecall = true return true end
    if not Config.AcBlockReports then AC.armed.namecall = false return false end
    local original, installed = nil, false
    -- preferred: the executor's own helper, which knows about the VM's
    -- namecall optimisations
    if type(hookmetamethod) == "function" then
        installed = safeCall("hookmetamethod", function()
            local hook = function(self, ...)
                return namecallFilter(self, ...)
            end
            AC.originalNamecall = hookmetamethod(game, "__namecall", hook)
            return AC.originalNamecall ~= nil
        end)
    end
    if not installed and type(getrawmetatable) == "function" then
        installed = safeCall("raw metatable", function()
            local mt = getrawmetatable(game)
            if not mt then return false end
            local old = mt.__namecall
            if type(setreadonly) == "function" then setreadonly(mt, false) end
            AC.originalNamecall = old
            mt.__namecall = function(self, ...)
                return namecallFilter(self, ...)
            end
            if type(setreadonly) == "function" then setreadonly(mt, true) end
            return true
        end)
    end
    if not installed or not AC.originalNamecall then
        AC.armed.namecall = false
        return false
    end
    AC.namecallInstalled = true
    AC.armed.namecall = true
    return true
end

local function installCamouflage()
    if AC.hookedIndex then AC.armed.camouflage = true return true end
    if not Config.AcCamouflage then AC.armed.camouflage = false return false end
    if type(hookmetamethod) ~= "function" then AC.armed.camouflage = false return false end
    local ok = safeCall("camouflage", function()
        local previous
        previous = hookmetamethod(game, "__index", function(self, key)
            if not AC.intern and Config.AcCamouflage and (key == "WalkSpeed" or key == "JumpPower") then
                -- ClassName, not IsA: no namecall, no pcall, nothing this hook
                -- could re-enter on a real client
                if self.ClassName == "Humanoid" then
                    AC.camoReads = AC.camoReads + 1
                    if key == "WalkSpeed" then return math.min(State.realSpeed or 16, 16) end
                    return 50
                end
            end
            return previous(self, key)
        end)
        return previous ~= nil
    end)
    AC.hookedIndex = ok == true
    AC.armed.camouflage = AC.hookedIndex
    return AC.hookedIndex
end

local function clampLimits()
    if not Config.AcSpeedLimiter then AC.armed.limits = false return false end
    if os.clock() - (AC.lastLimitScan or 0) < 6 then
        AC.armed.limits = AC.armed.limits ~= false
        return AC.armed.limits == true
    end
    AC.lastLimitScan = os.clock()
    if type(getgc) ~= "function" then AC.armed.limits = false return false end
    local ceiling = tonumber(Config.AcSpeedCeiling) or 60
    local patched = 0
    safeCall("limit scan", function()
        local scanned = 0
        for _, object in ipairs(getgc(true)) do
            scanned = scanned + 1
            if scanned > math.max(400, tonumber(Config.ScanBudget) or 400) * 2 then break end
            if type(object) == "table" then
                for key, value in pairs(object) do
                    if type(key) == "string" and type(value) == "number" then
                        local low = string.lower(key)
                        if string.find(low, "maxspeed", 1, true)
                            or string.find(low, "speedlimit", 1, true)
                            or string.find(low, "maxwalkspeed", 1, true) then
                            if value > ceiling then
                                if pcall(function() rawset(object, key, ceiling) end) then patched = patched + 1 end
                            end
                        end
                    end
                end
            end
        end
        return true
    end)
    AC.patchedFields = AC.patchedFields + patched
    AC.armed.limits = true
    return true
end

local function kickWatcher()
    -- the namecall layer swallows Kick on LocalPlayer; this loop catches the
    -- other route — a kick that arrives as a TeleportService / Players exit
    task.spawn(function()
        while State.alive do
            task.wait(1)
            State.beats.kick = os.clock()
            protectLoop("kick watcher", function()
                if Config.AcKickGuard and LocalPlayer then
                    local ok, parent = pcall(function() return LocalPlayer.Parent end)
                    if ok and not parent then
                        AC.kicks = AC.kicks + 1
                        if Config.LogLevel >= 1 then
                            print("[Skill Hub] ac · local player was removed from Players")
                        end
                    end
                end
            end)
        end
    end)
end

local function armAntiCheat()
    AC.armed = {}
    AC.namecallFilter = namecallFilter
    AC.lastArm = os.clock()
    AC.lastDetectorScan, AC.lastLimitScan = -100, -100
    disableDetectors()
    installNamecall()
    installCamouflage()
    clampLimits()
    AC.armed.pacing = Config.AcSpeedLimiter == true
    AC.armed.rate = (tonumber(Config.AcRemoteRateLimit) or 20) > 0
    return AC.armed
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 13 · ESP — highlights, labels, tracers, and a hard cap on all three
-- ═══════════════════════════════════════════════════════════════════════════
local Esp = {
    folder = nil,
    labels = {},
    tracers = {},
    boxes = {},
    count = 0,
    updatedAt = 0,
    fov = nil,
    drawing = nil,
}

local function guiRoot()
    local ok, hidden = pcall(function() return gethui and gethui() end)
    if ok and hidden then return hidden end
    return CoreGui or game:GetService("CoreGui")
end

local function espFolder()
    if Esp.folder and Esp.folder.Parent then return Esp.folder end
    local ok, folder = pcall(function()
        local created = Instance.new("Folder")
        created.Name = "Graphics"
        created.Parent = guiRoot()
        return created
    end)
    if ok then Esp.folder = folder end
    return Esp.folder
end

local function canDraw()
    if Esp.drawing == nil then
        Esp.drawing = type(Drawing) == "table" and type(Drawing.new) == "function"
    end
    return Esp.drawing
end

local function labelFor(userId, folder)
    local label = Esp.labels[userId]
    if label and label.Holder and label.Holder.Parent then return label end
    local ok, created = pcall(function()
        local holder = Instance.new("BillboardGui")
        holder.Name = "Tag"
        -- Adornee, not Parent: a tag under the character would be one more
        -- unexpected child for a detector to find
        holder.Adornee = nil
        holder.AlwaysOnTop = true
        holder.LightInfluence = 0
        holder.ResetOnSpawn = false
        holder.Size = UDim2.new(0, 150, 0, 44)
        holder.StudsOffset = Vector3.new(0, 2.6, 0)
        local line = Instance.new("TextLabel")
        line.Name = "TagText"
        line.BackgroundTransparency = 1
        line.Size = UDim2.new(1, 0, 1, 0)
        line.Font = Enum.Font.Code
        line.TextSize = 11
        line.TextStrokeTransparency = 0.4
        line.TextColor3 = Color3.fromRGB(235, 238, 242)
        line.Text = ""
        line.Parent = holder
        holder.Parent = folder
        return { Holder = holder, Text = line }
    end)
    if ok and created then
        Esp.labels[userId] = created
        return created
    end
    return nil
end

local function tracerFor(userId)
    if not canDraw() then return nil end
    local tracer = Esp.tracers[userId]
    if tracer then return tracer end
    local ok, line = pcall(function()
        local created = Drawing.new("Line")
        created.Thickness = 1
        created.Transparency = 0.75
        created.Color = Color3.fromRGB(210, 214, 220)
        created.Visible = false
        return created
    end)
    if ok and line then
        Esp.tracers[userId] = line
        return line
    end
    return nil
end

local function espColor(record)
    if record.friendly then
        return Color3.fromRGB(120, 170, 210)
    end
    if Config.EspTeamColor then
        local ratio = 1
        if record.maxHealth and record.maxHealth > 0 then ratio = record.health / record.maxHealth end
        ratio = math.clamp(ratio, 0, 1)
        return Color3.fromRGB(255 * (1 - ratio) + 40 * ratio, 90 + 90 * (1 - ratio), 80)
    end
    return Color3.fromRGB(225, 228, 233)
end

local function clearEsp()
    for userId, label in pairs(Esp.labels) do
        if label.Holder then pcall(function() label.Holder:Destroy() end) end
        Esp.labels[userId] = nil
    end
    for userId, tracer in pairs(Esp.tracers) do
        pcall(function() tracer.Visible = false end)
    end
    for userId, box in pairs(Esp.boxes) do
        pcall(function() box.Visible = false end)
    end
    if Esp.folder then pcall(function() Esp.folder:ClearAllChildren() end) end
    Esp.count = 0
end

local function fovCircle()
    if not Config.FovCircle or not canDraw() then
        if Esp.fov then pcall(function() Esp.fov.Visible = false end) end
        return
    end
    if not Esp.fov then
        local ok, circle = pcall(function()
            local created = Drawing.new("Circle")
            created.Thickness = 1
            created.Transparency = 0.55
            created.Color = Color3.fromRGB(205, 210, 218)
            created.Filled = false
            return created
        end)
        if ok then Esp.fov = circle end
    end
    if not Esp.fov then return end
    local size = viewport()
    pcall(function()
        Esp.fov.Position = Vector2.new(size.X / 2, size.Y / 2)
        -- a cone in degrees is not a radius in pixels: project the half-angle
        -- through the camera's own field of view so the ring shows exactly the
        -- area the aim picker will accept
        local camera = refreshCamera()
        local halfAngle = math.rad(aimCone())
        local cameraFov = math.rad(tonumber(camera and camera.FieldOfView) or 70)
        local radius = math.tan(halfAngle) / math.tan(cameraFov / 2) * (size.Y / 2)
        Esp.fov.Radius = math.clamp(radius, 8, 2000)
        Esp.fov.Visible = Config.AimEnabled
    end)
end

local function boxFor(userId)
    if not canDraw() then return nil end
    local box = Esp.boxes[userId]
    if box then return box end
    local ok, created = pcall(function()
        local square = Drawing.new("Square")
        square.Thickness = 1
        square.Filled = false
        square.Transparency = 0.7
        square.Visible = false
        return square
    end)
    if ok and created then
        Esp.boxes[userId] = created
        return created
    end
    return nil
end

local function drawBox(record, color)
    local box = boxFor(record.userId)
    if not box then return end
    local headPoint, headOn = screenOf(record.head and record.head.Position or record.position)
    local footPoint, footOn = screenOf(record.root and record.root.Position or record.position)
    if not headPoint or not footPoint or not headOn then
        pcall(function() box.Visible = false end)
        return
    end
    local height = math.abs(footPoint.Y - headPoint.Y) * 1.35
    if height < 6 then height = 6 end
    local width = height * 0.42
    local top = math.min(headPoint.Y, footPoint.Y) - height * 0.18
    local left = (headPoint.X + footPoint.X) / 2 - width / 2
    pcall(function()
        box.Size = Vector2.new(width, height)
        box.Position = Vector2.new(left, top)
        box.Color = color
        box.Visible = true
    end)
end

local function espUpdate()
    local folder = espFolder()
    if not folder then return 0 end
    local shown = 0
    local seen = {}
    local maxDistance = tonumber(Config.EspMaxDistance) or 900
    for _, record in ipairs(World.players) do
        local show = Config.EspPlayers and not record.friendly
        if Config.EspTeam and record.friendly then show = Config.EspPlayers end
        if show and record.distance > maxDistance then show = false end
        if show then
            seen[record.userId] = true
            shown = shown + 1
            if shown > 250 then break end
            local color = espColor(record)
            if Config.EspChams and record.character then
                -- the highlight lives on the record, not on the character: an
                -- earlier build looked it up under the character, never found
                -- it there, and piled up one new highlight per pass
                local highlight = record.highlight
                if highlight and highlight.Parent ~= folder then highlight, record.highlight = nil, nil end
                if not highlight then
                    pcall(function()
                        local created = Instance.new("Highlight")
                        created.Name = "SkillHubCham"
                        created.Adornee = record.character
                        created.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        created.Parent = folder
                        highlight = created
                    end)
                    record.highlight = highlight
                end
                if highlight then
                    pcall(function()
                        highlight.FillColor = color
                        highlight.OutlineColor = color
                        highlight.FillTransparency = math.clamp(tonumber(Config.EspFillTransparency) or 0.55, 0, 0.95)
                        highlight.Enabled = true
                    end)
                end
            end
            if Config.EspNames or Config.EspHealth or Config.EspDistance or Config.EspWeapon then
                local label = labelFor(record.userId, folder)
                if label then
                    local head = record.head or record.root
                    if label.Head ~= head then
                        label.Head = head
                        pcall(function() label.Holder.Adornee = head end)
                    end
                    local parts = {}
                    if Config.EspNames then parts[#parts + 1] = record.name end
                    if Config.EspHealth then
                        parts[#parts + 1] = string.format("%d/%d", math.floor(record.health or 0), math.floor(record.maxHealth or 100))
                    end
                    if Config.EspDistance then parts[#parts + 1] = string.format("%dm", math.floor(record.distance or 0)) end
                    if Config.EspWeapon and record.weaponName and record.weaponName ~= "—" then
                        parts[#parts + 1] = record.weaponName
                    end
                    label.Text.Text = table.concat(parts, "  ·  ")
                    label.Text.TextColor3 = color
                    label.Text.Visible = true
                    if not label.Holder.Adornee and head then
                        label.Head = head
                        pcall(function() label.Holder.Adornee = head end)
                    end
                    label.Holder.Enabled = record.visible or not Config.EspVisibleOnly
                end
            end
            if Config.EspBox then drawBox(record, color) end
            if Config.EspTracers then
                local tracer = tracerFor(record.userId)
                if tracer then
                    local point, onScreen = screenOf(record.position)
                    local size = viewport()
                    pcall(function()
                        if point and onScreen then
                            tracer.From = Vector2.new(size.X / 2, size.Y)
                            tracer.To = point
                            tracer.Color = color
                            tracer.Visible = true
                        else
                            tracer.Visible = false
                        end
                    end)
                end
            end
        end
    end
    for userId, label in pairs(Esp.labels) do
        if not seen[userId] then
            if label.Holder then pcall(function() label.Holder:Destroy() end) end
            Esp.labels[userId] = nil
        end
    end
    for userId, tracer in pairs(Esp.tracers) do
        if not seen[userId] then pcall(function() tracer.Visible = false end) end
    end
    for userId, drawing in pairs(Esp.boxes) do
        if not seen[userId] then pcall(function() drawing.Visible = false end) end
    end
    -- highlights are parented to the folder, not to the character, so the
    -- character never grows a child that a detector could count
    for _, highlight in ipairs(folder:GetChildren()) do
        if highlight:IsA("Highlight") then
            local adornee = highlight.Adornee
            local keep = false
            if adornee then
                for _, record in ipairs(World.players) do
                    if record.character == adornee and seen[record.userId] then keep = true break end
                end
            end
            if not keep then pcall(function() highlight:Destroy() end) end
        end
    end
    Esp.count = shown
    Esp.updatedAt = os.clock()
    State.perf.espUpdates = State.perf.espUpdates + 1
    return shown
end

local function espLoop()
    task.spawn(function()
        while State.alive do
            local interval = math.clamp(tonumber(Config.EspInterval) or 0.25, 0.05, 1)
            task.wait(interval)
            if not State.alive then break end
            State.beats.esp = os.clock()
            if Config.EspPlayers or Config.EspChams or Config.EspTracers or Config.FovCircle then
                protectLoop("esp", function()
                    scanWorld(false)
                    espUpdate()
                    fovCircle()
                    return true
                end)
            else
                if Esp.count > 0 then clearEsp() end
                fovCircle()
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 14 · UTILITY — chat, queue, teleports, visuals, server hop
-- ═══════════════════════════════════════════════════════════════════════════
local Visuals = { fullbrightSaved = nil, fpsApplied = false, trail = nil, originalGravity = nil, music = nil }

local function sayChat(text)
    text = tostring(text or "")
    if text == "" then return false end
    if os.clock() - (State.lastChat or 0) < 1.2 then return false end
    State.lastChat = os.clock()
    local TextChatService = getService("TextChatService")
    if TextChatService then
        local channels = TextChatService:FindFirstChild("TextChannels")
        local general = channels and channels:FindFirstChild("RBXGeneral")
        if general and type(general.SendAsync) == "function" then
            return safeCall("chat", function() general:SendAsync(text) return true end) == true
        end
    end
    local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local sayRequest = chatEvents and chatEvents:FindFirstChild("SayMessageRequest")
    if sayRequest then
        return fireRemote(sayRequest, text, "All")
    end
    return false
end

local function guiButtonsMatching(words)
    local found = {}
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return found end
    local visited = 0
    for _, descendant in ipairs(playerGui:GetDescendants()) do
        visited = visited + 1
        if visited > 4000 then break end
        if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
            local text = lower(descendant.Name) .. " " .. lower(descendant.Text or "")
            if containsAny(text, words) then found[#found + 1] = descendant end
        end
    end
    return found
end

local function clickGuiButton(button)
    if not button then return false end
    return safeCall("gui click", function()
        local fire = getconnections and getconnections(button.MouseButton1Click)
        if fire and #fire > 0 then
            fire[1]:Fire()
            return true
        end
        return false
    end) == true
end

local function leaveMatch()
    local buttons = guiButtonsMatching(LOWER.LeaveGui)
    if #buttons > 0 and clickGuiButton(buttons[1]) then return true end
    local remote = findRemote(LOWER.Leave)
    if remote then return fireRemote(remote) end
    return false
end

local function joinQueue()
    -- deliberately not gated on State.inMatch: "another player is nearby" is
    -- not the same thing as "this client is in a duel"
    if os.clock() - (State.lastQueue or 0) < 6 then return false end
    State.lastQueue = os.clock()
    local buttons = guiButtonsMatching(LOWER.MatchGui)
    if #buttons > 0 and clickGuiButton(buttons[1]) then return true end
    local remote = findRemote(LOWER.Queue)
    if remote then return fireRemote(remote) end
    return false
end

-- paced teleport: six-to-twelve studs at a time, with a wait between steps.
-- A single CFrame jump is the first thing any server-side sanity check looks
-- at, and RIVALS is not a game that shrugs at it.
local function travelTo(position, steps)
    if not position then return false end
    local root = getRoot()
    if not root then return false end
    local total = math.max(1, math.floor(steps or 18))
    local stepSize = math.clamp(tonumber(Config.AcStepSize) or 12, 1, 60)
    local delay = math.clamp(tonumber(Config.AcStepDelay) or 0.05, 0.01, 1)
    task.spawn(function()
        local start = root.Position
        local delta = position - start
        local distance = delta.Magnitude
        local stride = math.min(stepSize, distance / total)
        local count = math.max(1, math.ceil(distance / math.max(stride, 0.1)))
        for index = 1, count do
            if not State.alive or not root.Parent then break end
            local target = start + delta * (index / count)
            local camera = refreshCamera()
            pcall(function()
                if camera then
                    root.CFrame = CFrame.new(target, target + camera.CFrame.LookVector)
                else
                    root.CFrame = CFrame.new(target)
                end
            end)
            task.wait(delay)
        end
        safeCall("teleport landed", function() root.CFrame = CFrame.new(position) return true end)
    end)
    return true
end

local function teleportToPlayer(player)
    if not player or not player.Character then return false end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local target = root.Position + root.CFrame.LookVector * 4
    return travelTo(target, 22)
end

local function serverHop()
    if os.clock() - (State.lastHop or 0) < 20 then return false end
    State.lastHop = os.clock()
    if type(game.HttpGet) ~= "function" then
        notify("Server hop", "executor has no HttpGet", 3, Theme.Warning)
        return false
    end
    local placeId = game.PlaceId
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=50", placeId)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if not ok or not body then
        notify("Server hop", "server list refused", 3, Theme.Warning)
        return false
    end
    local decoded = safeCall("hop json", function() return SVC.Http:JSONDecode(body) end)
    local data = decoded and decoded.data
    if type(data) ~= "table" then return false end
    local chosen = nil
    for _, entry in ipairs(data) do
        if entry.id and entry.playing and entry.maxPlayers and entry.playing < entry.maxPlayers then
            chosen = entry
            break
        end
    end
    if not chosen then
        notify("Server hop", "no open server found", 3, Theme.Warning)
        return false
    end
    notify("Server hop", "travelling to " .. tostring(chosen.playing) .. "/" .. tostring(chosen.maxPlayers), 3, Theme.Success)
    pcall(function() SVC.Teleport:TeleportToPlaceInstance(placeId, chosen.id, LocalPlayer) end)
    return true
end

local function applyFullbright()
    if not Visuals.fullbrightSaved then
        Visuals.fullbrightSaved = {
            Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
            Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
            FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
        }
    end
    if Config.Fullbright then
        pcall(function()
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.Ambient = Color3.fromRGB(170, 170, 170)
            Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
            Lighting.FogEnd = 1e6
            Lighting.GlobalShadows = false
        end)
    elseif Visuals.fullbrightSaved then
        local saved = Visuals.fullbrightSaved
        pcall(function()
            Lighting.Brightness = saved.Brightness
            Lighting.ClockTime = saved.ClockTime
            Lighting.Ambient = saved.Ambient
            Lighting.OutdoorAmbient = saved.OutdoorAmbient
            Lighting.FogEnd = saved.FogEnd
            Lighting.GlobalShadows = saved.GlobalShadows
        end)
    end
end

local function stripEffects()
    local removed = 0
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
            pcall(function() descendant.Enabled = false end)
            removed = removed + 1
            if removed > 400 then break end
        end
    end
    return removed
end

local function antiFlash()
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return false end
    local acted = false
    for _, descendant in ipairs(playerGui:GetDescendants()) do
        if descendant:IsA("Frame") or descendant:IsA("ImageLabel") or descendant:IsA("TextLabel") then
            local name = lower(descendant.Name)
            if string.find(name, "flash", 1, true) or string.find(name, "blind", 1, true)
                or string.find(name, "whiten", 1, true) then
                pcall(function()
                    descendant.Visible = false
                    descendant.BackgroundTransparency = 1
                end)
                acted = true
            end
        end
    end
    return acted
end

local function clearSmoke()
    local count = 0
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local name = lower(descendant.Name)
            if string.find(name, "smoke", 1, true) or string.find(name, "fog", 1, true) then
                pcall(function()
                    descendant.Transparency = 1
                    descendant.CanCollide = false
                end)
                count = count + 1
            end
        end
        if count > 120 then break end
    end
    return count
end

local function setGravity(enabled)
    if not Visuals.originalGravity then Visuals.originalGravity = Workspace.Gravity end
    local gravity = enabled and 80 or (Visuals.originalGravity or 196.2)
    pcall(function() Workspace.Gravity = gravity end)
end

local function utilityLoop()
    task.spawn(function()
        while State.alive do
            task.wait(0.4)
            State.beats.utility = os.clock()
            protectLoop("utility", function()
            if Config.AutoQueue then safeCall("queue", function() joinQueue() return true end) end
            if Config.AutoGG then
                if State.wasInMatch and not State.inMatch and os.clock() - (State.lastGG or 0) > 12 then
                    State.lastGG = os.clock()
                    sayChat(Config.GGMessage or "gg")
                end
            end
            State.wasInMatch = State.inMatch
            if Config.AntiFlash then safeCall("flash", function() antiFlash() return true end) end
            if Config.NoSmoke then safeCall("smoke", function() clearSmoke() return true end) end
            if Config.FpsBoost and not Visuals.fpsApplied then
                Visuals.fpsApplied = true
                safeCall("fps", function() return stripEffects() > 0 end)
            end
            if not Config.FpsBoost then Visuals.fpsApplied = false end
            if Config.RemoveVfx and not Visuals.vfxApplied then
                Visuals.vfxApplied = true
                safeCall("vfx", function() return stripEffects() > 0 end)
            end
            if not Config.RemoveVfx then Visuals.vfxApplied = false end
            local wantFov = tonumber(Config.CameraFov) or 0
            if wantFov > 0 then
                local camera = refreshCamera()
                if camera then
                    if not Visuals.baseFov then Visuals.baseFov = camera.FieldOfView end
                    pcall(function() camera.FieldOfView = math.clamp(wantFov, 40, 120) end)
                end
            elseif Visuals.baseFov then
                -- the override was turned off: put the game's own FOV back once
                local camera = refreshCamera()
                if camera then pcall(function() camera.FieldOfView = Visuals.baseFov end) end
                Visuals.baseFov = nil
            end
            local distance = tonumber(Config.CameraDistance) or 0
            if distance > 0 and LocalPlayer then
                pcall(function()
                    if LocalPlayer.CameraMaxZoomDistance ~= distance then
                        LocalPlayer.CameraMaxZoomDistance = math.clamp(distance, 0.5, 128)
                    end
                end)
            end
            if Config.ChatSpam and os.clock() - (State.lastChat or 0) >= math.max(3, tonumber(Config.ChatDelay) or 15) then
                safeCall("chat spam", function() sayChat(Config.ChatMessage or "") return true end)
            end
            if Config.EmoteLoop and os.clock() - (State.lastEmote or 0) > (tonumber(Config.EmoteLoopDelay) or 14) then
                State.lastEmote = os.clock()
                local emoteRemote = findRemote({ "emote", "dance" })
                if emoteRemote then fireRemote(emoteRemote, "dance") end
            end
            end)
        end
    end)
end

local function staffWatchLoop()
    task.spawn(function()
        while State.alive do
            task.wait(2.5)
            State.beats.staff = os.clock()
            protectLoop("staff watch", function()
            if Config.StaffWatch and #World.players > 0 then
                for _, record in ipairs(World.players) do
                    local player = record.player
                    local isStaff = false
                    local groupId = tonumber(Config.StaffGroupId) or 0
                    if groupId > 0 then
                        local ok, rank = pcall(function() return player:GetRankInGroup(groupId) end)
                        if ok and rank and rank >= 200 then isStaff = true end
                    end
                    local name = lower(record.name)
                    if string.find(name, "owner", 1, true) or string.find(name, "admin", 1, true) then
                        isStaff = true
                    end
                    if isStaff then
                        notify("Watch", "staff / owner online: " .. record.name, 4, Theme.Warning)
                        if Config.StaffHop then serverHop() end
                        break
                    end
                end
            end
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 15 · FUN — cosmetics that never touch the server
-- ═══════════════════════════════════════════════════════════════════════════
function playSound(id, volume)
    local numeric = tonumber(id)
    if not numeric or numeric <= 0 then return false end
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(numeric)
    sound.Volume = math.clamp(tonumber(volume) or 0.5, 0, 3)
    local ok = pcall(function()
        SVC.Sound:PlayLocalSound(sound)
        return true
    end)
    task.delay(3, function() pcall(function() sound:Destroy() end) end)
    return ok == true
end

function killEffect()
    local record = State.target
    local position = record and record.position or (getRoot() and getRoot().Position)
    if not position then return false end
    local ok = pcall(function()
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Size = Vector3.new(1, 1, 1)
        part.CFrame = CFrame.new(position)
        part.Parent = Workspace
        local emitter = Instance.new("ParticleEmitter")
        emitter.Color = ColorSequence.new(Color3.fromRGB(235, 238, 242))
        emitter.Lifetime = NumberRange.new(0.25, 0.5)
        emitter.Rate = 0
        emitter.Speed = NumberRange.new(6, 12)
        emitter.SpreadAngle = Vector2.new(180, 180)
        emitter.Parent = part
        emitter:Emit(18)
        task.delay(1.2, function() pcall(function() part:Destroy() end) end)
        return true
    end)
    return ok
end

function hitSpark(position)
    if not Config.HitSparks or not position then return end
    if os.clock() - (State.lastSpark or 0) < 0.12 then return end
    State.lastSpark = os.clock()
    pcall(function()
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.CFrame = CFrame.new(position)
        part.Parent = Workspace
        local emitter = Instance.new("ParticleEmitter")
        emitter.Color = ColorSequence.new(Color3.fromRGB(255, 226, 170))
        emitter.Lifetime = NumberRange.new(0.1, 0.2)
        emitter.Rate = 0
        emitter.Speed = NumberRange.new(4, 8)
        emitter.Parent = part
        emitter:Emit(6)
        task.delay(0.6, function() pcall(function() part:Destroy() end) end)
    end)
end

local function updateTrail()
    local character = getChar()
    if not character then return end
    if Config.Trail then
        if Visuals.trail and Visuals.trail.Parent then return end
        local root = getRoot()
        if not root then return end
        local ok, trail = pcall(function()
            local attachment0 = Instance.new("Attachment")
            attachment0.Name = "TrailA"
            attachment0.Parent = root
            local attachment1 = Instance.new("Attachment")
            attachment1.Name = "TrailB"
            attachment1.Position = Vector3.new(0, 1.6, 0)
            attachment1.Parent = root
            local created = Instance.new("Trail")
            created.Attachment0 = attachment0
            created.Attachment1 = attachment1
            created.Lifetime = 0.45
            created.Transparency = NumberSequence.new(0.35, 1)
            created.Parent = root
            return created
        end)
        if ok then Visuals.trail = trail end
    elseif Visuals.trail and Visuals.trail.Parent then
        pcall(function()
            if Visuals.trail.Attachment0 then Visuals.trail.Attachment0:Destroy() end
            if Visuals.trail.Attachment1 then Visuals.trail.Attachment1:Destroy() end
            Visuals.trail:Destroy()
        end)
        Visuals.trail = nil
    end
end

local function funLoop()
    task.spawn(function()
        local hue = 0
        local rainbowChar, rainbowParts = nil, nil
        while State.alive do
            task.wait(0.1)
            State.beats.fun = os.clock()
            protectLoop("fun", function()
            hue = (hue + 0.006) % 1
            if Config.RainbowChar then
                local character = getChar()
                -- the parts are collected once per life, not every tenth of a
                -- second: GetDescendants on a character is the expensive half
                if character ~= rainbowChar then
                    rainbowChar, rainbowParts = character, {}
                    if character then
                        for _, descendant in ipairs(character:GetDescendants()) do
                            if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
                                rainbowParts[#rainbowParts + 1] = descendant
                            end
                        end
                    end
                end
                if rainbowParts then
                    for _, part in ipairs(rainbowParts) do
                        pcall(function() part.Color = Color3.fromHSV(hue, 0.55, 0.95) end)
                    end
                end
            elseif rainbowChar then
                rainbowChar, rainbowParts = nil, nil
            end
            if Config.DiscoMode then
                pcall(function()
                    Lighting.Ambient = Color3.fromHSV(hue, 0.6, 0.6)
                    Lighting.OutdoorAmbient = Color3.fromHSV((hue + 0.4) % 1, 0.5, 0.5)
                end)
            end
            updateTrail()
            if Config.Music then
                if not Visuals.music then
                    local music = Instance.new("Sound")
                    music.SoundId = "rbxassetid://" .. tostring(Config.MusicId or "")
                    music.Looped = true
                    music.Volume = math.clamp(tonumber(Config.MusicVolume) or 0.5, 0, 1)
                    pcall(function() music:Play() end)
                    Visuals.music = music
                end
                if Visuals.music and not Visuals.music.IsPlaying then
                    pcall(function() Visuals.music:Play() end)
                end
            elseif Visuals.music then
                pcall(function() Visuals.music:Stop() Visuals.music:Destroy() end)
                Visuals.music = nil
            end
            end)
        end
    end)
end


-- ═══════════════════════════════════════════════════════════════════════════
-- MATCH / RESPAWN REBIND — RIVALS swaps the local character when a duel or a
-- match loads and after every death. Everything cached about the old body has
-- to go with it, or the first match silently disables aim and movement.
-- ═══════════════════════════════════════════════════════════════════════════
function onCharacterChanged(character)
    State.boundCharacter = character
    Cache.character, Cache.root, Cache.humanoid = nil, nil, nil
    Cache.playerRecords = {}
    Cache.playerGui = nil
    World.structureAt = -100
    VisAt = -100
    Aim.recoil, Aim.aimPosition = nil, nil
    State.target, State.lastTargetName = nil, nil
    -- WriteCache is how movement knows a value was already written; the new
    -- humanoid has fresh defaults, so forget the old writes and re-apply
    WriteCache.speed, WriteCache.jump, WriteCache.noclip = nil, nil, nil
    Mov.noclip, Mov.flyLoop, Mov.flyBody = false, false, nil
    Mov.lastVoid, Mov.lastFling, Mov.lastJump = 0, 0, 0
    refreshCamera()
    if character then
        task.spawn(function()
            task.wait(0.2)
            if not State.alive then return end
            pcall(function() scanWorld(true) end)
            if Config.NoRecoil or Config.NoSpread then pcall(patchWeaponStats) end
        end)
    end
end

-- instant reaction on executors that expose the Player signal; the combat loop
-- polls for the same change every 20 ms, so the hook is a shortcut, not a
-- requirement
do
    local ok = pcall(function()
        LocalPlayer.CharacterAdded:Connect(function(character)
            task.spawn(function()
                task.wait(0.1)
                pcall(onCharacterChanged, character)
            end)
        end)
        return true
    end)
    AC.characterHook = ok == true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 16 · INTERFACE — nine tabs, built from the same Porcelain components
-- ═══════════════════════════════════════════════════════════════════════════
local Switches = {}

local function toggleSwitch(tab, title, desc, key, icon, onChange, loud)
    local api
    local function apply(state)
        if state and loud and Config.AltOnlyMode then
            Config[key] = false
            notify("Alt-only mode", "«" .. title .. "» is off while AltOnly is on", 4, Theme.Warning, "shield")
            if api then pcall(function() api.Set(false, true) end) end
            return false
        end
        Config[key] = state and true or false
        if onChange then onChange(state) end
        return true
    end
    api = tab:AddToggle(title, desc, Config[key] == true, apply, icon)
    Switches[#Switches + 1] = { key = key, api = api }
    return api
end

local function equipWeapon(name)
    if not name or name == "" then return false end
    local buttons = guiButtonsMatching({ lower(name) })
    if #buttons > 0 and clickGuiButton(buttons[1]) then return true end
    local remote = findRemote(LOWER.Equip)
    if remote then return fireRemote(remote, name) end
    return false
end

local selfTest, panic, doctor

local function buildTabs()
    local Sliders = {}
    local function slider(tab, title, desc, low, high, key, suffix, icon, onChange)
        local api = tab:AddSlider(title, desc, low, high, Config[key], suffix, function(value)
            Config[key] = value
            if onChange then onChange(value) end
        end, icon)
        Sliders[key] = api
        return api
    end
    -- a preset has to move the slider too, or the panel claims one value while
    -- the aim runs on another
    local function setSlider(key, value)
        local api = Sliders[key]
        if api and api.Set then api.Set(value) else Config[key] = value end
    end
    local function dropdown(tab, title, desc, options, key, icon, onChange)
        local names = {}
        for index, option in ipairs(options) do names[index] = option end
        return tab:AddDropdown(title, desc, names, Config[key], function(value)
            Config[key] = value
            if onChange then onChange(value) end
        end, icon)
    end
    local function button(tab, title, desc, callback, icon, danger)
        return tab:AddButton(title, desc, callback, icon, danger)
    end
    local function input(tab, title, desc, key, icon)
        return tab:AddInput(title, desc, tostring(Config[key] or ""), function(value)
            Config[key] = value
        end, icon)
    end
    local function keybind(tab, title, desc, key, icon, onChange)
        return tab:AddKeybind(title, desc, tostring(Config[key] or ""), function(value)
            Config[key] = value
            if onChange then onChange(value) end
        end, icon)
    end

    -- ── combat ──────────────────────────────────────────────────────────────
    local combat = makeTab("Combat", "aim assist, prediction, humanised stepping", "swords", Theme.Clay)
    combat:AddSection("Aim")
    toggleSwitch(combat, "Aim assist", "rotate the camera onto the chosen part", "AimEnabled", "swords")
    keybind(combat, "Aim key", "toggle, or hold when Aim toggle is off", "AimKey", "bolt")
    toggleSwitch(combat, "Aim toggle", "on = press once · off = hold the key", "AimToggle", "loop")
    dropdown(combat, "Method", "hybrid moves the game's own mouse; silent rewrites the remote", { "Hybrid", "Camera", "Mouse", "Silent" }, "AimMethod", "eye")
    dropdown(combat, "Hit part", "where the camera looks", { "Head", "Torso", "Nearest", "Random" }, "AimPart", "spark")
    dropdown(combat, "Priority", "how the next target is chosen", { "Closest to crosshair", "Closest", "Lowest health" }, "AimPriority", "search")
    slider(combat, "Field of view", "degrees around the crosshair", 20, 360, "AimFov", "°", "eye")
    slider(combat, "Smoothing", "0 = snap · 1 = slow and deliberate", 0, 1, "AimSmooth", "", "wind")
    slider(combat, "Mouse sensitivity", "degrees the view turns per pixel · the hub learns it anyway", 0.05, 2, "AimMouseSensitivity", "°/px", "bolt")
    slider(combat, "Max range", "studs", 50, 1500, "AimRange", "s", "compass")
    slider(combat, "Step limit", "hard ceiling on degrees turned per frame", 1, 45, "AimStepLimit", "°", "shield")
    toggleSwitch(combat, "Prediction", "lead the target by its velocity", "AimPrediction", "bolt")
    slider(combat, "Prediction factor", "fraction of velocity added", 0, 0.4, "AimPredictionFactor", "s", "wind")
    toggleSwitch(combat, "Visible only", "never aim through a wall", "AimVisibleOnly", "eye")
    toggleSwitch(combat, "Team check", "skip teammates", "AimTeamCheck", "shield")
    toggleSwitch(combat, "Wall check", "re-test the ray every time the target changes", "AimWallCheck", "layers")
    toggleSwitch(combat, "Humanise", "jitter the step by a few tenths of a degree", "AimHumanize", "user")

    combat:AddSection("Presets")
    button(combat, "Duel · 1v1", "tight cone, calm smoothing, quick single click", function()
        setSlider("AimFov", 90)
        setSlider("AimSmooth", 0.5)
        setSlider("AimStepLimit", 9)
        setSlider("TriggerFov", 6)
        setSlider("TriggerDelay", 0.05)
        setSlider("AimRange", 400)
        Config.AimVisibleOnly = false
        notify("Duel preset", "90° cone · 0.50 smoothing · 9°/frame", "swords")
    end, "swords")
    button(combat, "Match · 2v2 and casual", "wider cone, team check on, faster trigger", function()
        setSlider("AimFov", 140)
        setSlider("AimSmooth", 0.45)
        setSlider("AimStepLimit", 12)
        setSlider("TriggerFov", 8)
        setSlider("TriggerDelay", 0.04)
        setSlider("AimRange", 600)
        Config.AimTeamCheck = true
        notify("Match preset", "140° cone · team check on", "users")
    end, "users")
    button(combat, "Close range", "shotgun and melee spacing: wide cone, fast step", function()
        setSlider("AimFov", 200)
        setSlider("AimSmooth", 0.4)
        setSlider("AimStepLimit", 18)
        setSlider("TriggerFov", 12)
        setSlider("TriggerDelay", 0.03)
        notify("Close range", "200° cone · 18°/frame", "flame")
    end, "flame")

    combat:AddSection("Recoil and fire")
    toggleSwitch(combat, "No recoil", "restores the camera rotation after each shot", "NoRecoil", "wind")
    toggleSwitch(combat, "No spread", "clamps numeric spread fields found in Lua tables", "NoSpread", "spark")
    toggleSwitch(combat, "Auto scope", "right-click while aiming", "AutoScope", "eye")
    toggleSwitch(combat, "Auto fire", "fires whenever a visible target is inside the FOV", "AutoFire", "flame", nil, true)
    slider(combat, "Fire rate cap", "shots per second this hub will ever send", 2, 20, "FireRateCap", "/s", "chart")
    toggleSwitch(combat, "Humanised cadence", "drops roughly one shot in twenty-five", "HumanizeFire", "user")

    -- ── trigger ─────────────────────────────────────────────────────────────
    local trigger = makeTab("Trigger", "automatic clicking, reloads and swaps", "spark", Theme.Sand)
    trigger:AddSection("Triggerbot")
    toggleSwitch(trigger, "Triggerbot", "click when a target crosses the crosshair", "TriggerBot", "spark")
    dropdown(trigger, "Mode", "crosshair is a hard gate; FOV is a radius", { "Crosshair", "FOV" }, "TriggerMode", "search")
    slider(trigger, "Trigger FOV", "pixels from the centre; crosshair mode halves it", 1, 60, "TriggerFov", "px", "eye")
    slider(trigger, "Trigger delay", "seconds between clicks", 0, 0.5, "TriggerDelay", "s", "loop")
    toggleSwitch(trigger, "Require visibility", "no clicks through geometry", "TriggerVisibleOnly", "eye")
    toggleSwitch(trigger, "Team check", "never click a teammate", "TriggerTeamCheck", "shield")
    trigger:AddSection("Automation")
    toggleSwitch(trigger, "Auto reload", "when the magazine reads zero", "AutoReload", "loop")
    toggleSwitch(trigger, "Auto switch", "primary out of ammo → secondary", "AutoSwitch", "layers")
    toggleSwitch(trigger, "Auto melee", "swap to melee inside knife range", "AutoKnife", "katana", nil, true)
    slider(trigger, "Melee range", "studs", 3, 20, "AutoKnifeRange", "s", "katana")
    trigger:AddSection("Audio")
    toggleSwitch(trigger, "Hit sound", "local only — the server tells a client nothing", "HitSound", "bell")
    toggleSwitch(trigger, "Kill sound", "plays when a tracked enemy disappears", "KillSound", "bell")
    trigger:AddLabel("RIVALS resolves damage on the server. Nothing here can make a shot land — it only decides when this client sends one.", "warning")

    -- ── esp ─────────────────────────────────────────────────────────────────
    local esp = makeTab("ESP", "highlights, tags, tracers, FOV ring", "eye", Theme.Sky)
    esp:AddSection("Players")
    toggleSwitch(esp, "Player ESP", "master switch for every drawing below", "EspPlayers", "eye")
    toggleSwitch(esp, "Chams", "highlight through walls", "EspChams", "layers")
    toggleSwitch(esp, "Box", "screen-space box", "EspBox", "layers")
    toggleSwitch(esp, "Team", "draw teammates too", "EspTeam", "shield")
    toggleSwitch(esp, "Team colour", "health gradient for enemies, blue for allies", "EspTeamColor", "drop")
    esp:AddSection("Tags")
    toggleSwitch(esp, "Names", "display name above the head", "EspNames", "user")
    toggleSwitch(esp, "Health", "current / max", "EspHealth", "chart")
    toggleSwitch(esp, "Distance", "studs from your root", "EspDistance", "compass")
    toggleSwitch(esp, "Weapon", "equipped tool", "EspWeapon", "katana")
    toggleSwitch(esp, "Tracers", "line from the bottom of the screen", "EspTracers", "bolt")
    toggleSwitch(esp, "Visible only", "hide tags behind geometry", "EspVisibleOnly", "eye")
    esp:AddSection("Limits")
    slider(esp, "Max distance", "hard cut-off in studs", 100, 2000, "EspMaxDistance", "s", "compass")
    slider(esp, "Fill transparency", "0 = solid · 0.9 = nearly invisible", 0, 0.9, "EspFillTransparency", "", "drop")
    slider(esp, "Refresh", "seconds between ESP passes", 0.05, 1, "EspInterval", "s", "loop")
    toggleSwitch(esp, "FOV circle", "draws the aim radius in pixels", "FovCircle", "eye")

    -- ── weapons ─────────────────────────────────────────────────────────────
    local weapons = makeTab("Weapons", "loadout, ammo, the Update 23 numbers", "katana", Theme.Sage)
    weapons:AddSection("Loadout")
    local presetNames = {}
    for _, weapon in ipairs(KNOWLEDGE.Weapons) do presetNames[#presetNames + 1] = weapon.Name end
    dropdown(weapons, "Preset", "the weapon this hub tries to equip", presetNames, "LoadoutPreset", "katana", function(value)
        local info = weaponInfo(value)
        notify("Loadout", value .. (info and (" · " .. info.Slot) or ""), 4, Theme.Sage, "katana")
    end)
    toggleSwitch(weapons, "Equip on spawn", "one attempt per life, never in a loop", "AutoEquipOnSpawn", "loop")
    button(weapons, "Equip now", "clicks the loadout button, then the equip remote", function()
        local ok = equipWeapon(Config.LoadoutPreset)
        notify("Loadout", ok and ("equipped " .. tostring(Config.LoadoutPreset)) or "no loadout button or remote answered", 4,
            ok and Theme.Success or Theme.Warning, ok and "katana" or "warning")
    end, "katana")
    button(weapons, "Reload now", "manual reload through the remote, then the R key", function()
        local ok = reloadNow()
        notify("Reload", ok and "sent" or "nothing to reload", 3, ok and Theme.Success or Theme.Warning, "loop")
    end, "loop")
    weapons:AddSection("Update 23 reference")
    weapons:AddLabel(KNOWLEDGE.PatchNotes.Wildcat, "chart")
    weapons:AddLabel(KNOWLEDGE.PatchNotes.Sniper, "chart")
    weapons:AddLabel(KNOWLEDGE.PatchNotes.RiotShield, "chart")
    weapons:AddLabel("54 weapons in the game · 39 catalogued here with slot and price · 8 codes (BACK2BACK, NOSNIYGAMESONTOP)", "scroll")

    -- ── movement ────────────────────────────────────────────────────────────
    local movement = makeTab("Movement", "speed, jump, fly, noclip, anti-void", "wind", Theme.Sage)
    movement:AddSection("Speed")
    toggleSwitch(movement, "Walk speed", "capped by the anti-cheat ceiling while Safe mode is on", "WalkSpeedEnabled", "bolt")
    slider(movement, "Speed value", "16 = default RIVALS pace", 16, 100, "WalkSpeed", "", "wind")
    toggleSwitch(movement, "Jump power", "sets UseJumpPower and the value", "JumpPowerEnabled", "wind")
    slider(movement, "Jump value", "50 = default", 50, 200, "JumpPower", "", "wind")
    toggleSwitch(movement, "Always sprint", "keeps re-applying the speed value", "AlwaysSprint", "loop")
    toggleSwitch(movement, "Infinite jump", "re-enters the jumping state in the air", "InfiniteJump", "wind")
    toggleSwitch(movement, "Bunny hop", "re-jumps on landing", "BunnyHop", "loop")
    movement:AddSection("Flight")
    toggleSwitch(movement, "Fly", "BodyVelocity with a default name, not a branded one", "FlyEnabled", "wind", function(state)
        if not state then Mov.stopFly() end
    end, true)
    slider(movement, "Fly speed", "clamped by the ceiling in Safe mode", 8, 200, "FlySpeed", "", "bolt")
    toggleSwitch(movement, "Noclip", "parts stop colliding while on", "Noclip", "ghost", function(state)
        setNoclip(state)
    end, true)
    movement:AddSection("Survival")
    toggleSwitch(movement, "Anti void", "teleports back above the map below -180", "AntiVoid", "shield")
    toggleSwitch(movement, "Anti fling", "zeroes absurd velocity", "AntiFling", "shield")
    toggleSwitch(movement, "Anti ragdoll", "gets up from ragdoll states", "AntiRagdoll", "shield")
    toggleSwitch(movement, "Anti stun", "clears the cached speed so it is re-applied", "AntiStun", "shield")
    toggleSwitch(movement, "No fall damage", "caps downward velocity", "NoFallDamage", "shield")
    toggleSwitch(movement, "Low gravity", "80 studs/s² — client-side only, cosmetic", "LowGravity", "drop", function(state)
        setGravity(state)
    end)

    -- ── utility ─────────────────────────────────────────────────────────────
    local utility = makeTab("Utility", "queue, chat, visuals, server hop", "layers", Theme.Steel)
    utility:AddSection("Match")
    toggleSwitch(utility, "Auto queue", "clicks Play, then the queue remote", "AutoQueue", "play")
    button(utility, "Leave match", "Leave button first, forfeit remote second", function()
        local ok = leaveMatch()
        notify("Match", ok and "leave sent" or "no leave button or remote", 3, ok and Theme.Success or Theme.Warning, "stop")
    end, "stop")
    toggleSwitch(utility, "Auto GG", "once per match, twelve-second cooldown", "AutoGG", "bell")
    input(utility, "GG message", "what gets typed", "GGMessage", "scroll")
    utility:AddSection("Vision")
    toggleSwitch(utility, "Anti flash", "hides flash / blind frames", "AntiFlash", "eye")
    toggleSwitch(utility, "No smoke", "makes smoke parts invisible", "NoSmoke", "wind")
    toggleSwitch(utility, "Remove VFX", "disables particles, beams and trails once", "RemoveVfx", "layers")
    toggleSwitch(utility, "FPS boost", "the same pass, plus lighting cost cut", "FpsBoost", "chart")
    toggleSwitch(utility, "Fullbright", "restores every value when turned off", "Fullbright", "star", function()
        applyFullbright()
    end)
    slider(utility, "Camera FOV", "0 leaves the game's own FOV (and its scopes) alone", 0, 120, "CameraFov", "°", "eye")
    slider(utility, "Camera distance", "0 leaves the game's zoom limit alone; Ranked may override it", 0, 64, "CameraDistance", "", "compass")
    utility:AddSection("Chat and server")
    toggleSwitch(utility, "Chat spam", "one message every 1.2 s", "ChatSpam", "scroll", nil, true)
    input(utility, "Chat message", "text to send", "ChatMessage", "scroll")
    toggleSwitch(utility, "Emote loop", "re-fires the dance emote", "EmoteLoop", "loop")
    slider(utility, "Emote delay", "seconds between emotes", 4, 60, "EmoteLoopDelay", "s", "loop")
    button(utility, "Server hop", "public server list, lowest population first", function()
        if not serverHop() then
            notify("Server hop", "did not move — check the console line", 3, Theme.Warning, "warning")
        end
    end, "compass")

    -- ── anti-cheat ──────────────────────────────────────────────────────────
    local acTab = makeTab("Anti-Cheat", "six layers, each reports whether it armed", "shield", Theme.Mauve)
    acTab:AddSection("Profile")
    dropdown(acTab, "Profile", "Safe keeps every number inside human range", { "Safe", "Balanced", "Aggressive" }, "AcProfile", "shield", function(value)
        if value == "Safe" then
            Config.AcSafeMode, Config.AcSpeedCeiling = true, 40
            Config.AcShotRateLimit, Config.AcStepSize = 7, 8
        elseif value == "Balanced" then
            Config.AcSafeMode, Config.AcSpeedCeiling = true, 60
            Config.AcShotRateLimit, Config.AcStepSize = 10, 12
        else
            Config.AcSafeMode, Config.AcSpeedCeiling = false, 120
            Config.AcShotRateLimit, Config.AcStepSize = 16, 24
        end
        notify("Profile", value .. " · ceiling " .. tostring(Config.AcSpeedCeiling), 4, Theme.Mauve, "shield")
    end)
    toggleSwitch(acTab, "Safe mode", "clamps speed, fire rate and aim step together", "AcSafeMode", "shield")
    toggleSwitch(acTab, "Alt-only mode", "refuses the loudest toys outright", "AltOnlyMode", "ghost")
    acTab:AddSection("Layers")
    toggleSwitch(acTab, "Detector neutralisation", "disables scripts whose names say anti-cheat", "AcNeutralize", "skull", function()
        AC.lastDetectorScan = 0
    end)
    toggleSwitch(acTab, "Report filter", "drops report / flag / screenshot remotes at namecall", "AcBlockReports", "shield")
    toggleSwitch(acTab, "Kick guard", "swallows LocalPlayer:Kick and watches for removal", "AcKickGuard", "ghost")
    toggleSwitch(acTab, "Read camouflage", "WalkSpeed and JumpPower read as 16 / 50", "AcCamouflage", "eye")
    toggleSwitch(acTab, "Limit clamp", "numeric maxspeed / speedlimit fields clamped", "AcSpeedLimiter", "layers")
    toggleSwitch(acTab, "Aim rate limit", "no more than AimStepLimit degrees per frame", "AcAimRateLimit", "compass")
    acTab:AddSection("Numbers")
    slider(acTab, "Speed ceiling", "studs/s the hub will write while Safe is on", 20, 200, "AcSpeedCeiling", "", "wind")
    slider(acTab, "Teleport step", "studs per hop", 2, 40, "AcStepSize", "s", "compass")
    slider(acTab, "Teleport delay", "seconds between hops", 0.01, 0.3, "AcStepDelay", "s", "loop")
    slider(acTab, "Remote rate", "calls per second per remote", 2, 60, "AcRemoteRateLimit", "/s", "bolt")
    slider(acTab, "Shot rate", "hard ceiling for outgoing clicks", 2, 30, "AcShotRateLimit", "/s", "spark")
    slider(acTab, "Scan interval", "seconds between structural passes", 0.3, 4, "ScanInterval", "s", "search")
    acTab:AddSection("Watch")
    toggleSwitch(acTab, "Staff watch", "notifies when a group member or owner joins", "StaffWatch", "user")
    input(acTab, "Staff group id", "0 disables the group lookup", "StaffGroupId", "search")
    toggleSwitch(acTab, "Hop on staff", "leave the server instead of playing", "StaffHop", "compass")
    toggleSwitch(acTab, "Human pause", "occasionally skips an aim frame on purpose", "HumanPause", "user")
    button(acTab, "Re-arm every layer", "runs the arming pass again and prints what installed", function()
        local armed = armAntiCheat()
        local lines = {}
        for name, state in pairs(armed) do lines[#lines + 1] = tostring(name) .. "=" .. tostring(state) end
        table.sort(lines)
        print("[Skill Hub] anti-cheat · " .. table.concat(lines, " "))
        notify("Anti-cheat", "re-armed · " .. tostring(#lines) .. " layers", 4, Theme.Mauve, "shield")
    end, "shield")
    acTab:AddStatusPanel("Layer state", function()
        return {
            { label = "detectors", value = tostring(AC.armed.detectors) .. " · " .. tostring(AC.detectorCount) },
            { label = "namecall", value = tostring(AC.armed.namecall) .. " · " .. tostring(AC.blocked) .. " dropped" },
            { label = "camouflage", value = tostring(AC.armed.camouflage) .. " · " .. tostring(AC.camoReads) },
            { label = "limits", value = tostring(AC.armed.limits) .. " · " .. tostring(AC.patchedFields) },
            { label = "kicks", value = tostring(AC.kicks) },
            { label = "rate", value = tostring(Remotes.blocked) .. " remote(s) held" },
        }
    end, 128)
    acTab:AddLabel("This tab lowers the signals this file is responsible for. It cannot hide an injected executor, and it cannot retract a shot the server already resolved.", "warning")

    -- ── fun ─────────────────────────────────────────────────────────────────
    local fun = makeTab("Fun", "cosmetics that never touch the server", "flame", Theme.Clay)
    fun:AddSection("Effects")
    toggleSwitch(fun, "Hit sparks", "a small local particle burst where you aimed", "HitSparks", "spark")
    toggleSwitch(fun, "Kill effect", "burst when a tracked enemy disappears", "KillEffect", "flame")
    button(fun, "Test kill effect", "plays it at your position", function() killEffect() end, "spark")
    toggleSwitch(fun, "Trail", "attachment trail on the root part", "Trail", "wind")
    toggleSwitch(fun, "Rainbow character", "client-side colour only", "RainbowChar", "star", nil, true)
    toggleSwitch(fun, "Disco lighting", "rotates ambient hue", "DiscoMode", "flame", nil, true)
    fun:AddSection("Audio")
    toggleSwitch(fun, "Music", "local SoundService track", "Music", "bell", nil, true)
    input(fun, "Music asset id", "digits only", "MusicId", "bell")
    slider(fun, "Music volume", "0 to 1", 0, 1, "MusicVolume", "", "bell")

    -- ── player and misc ─────────────────────────────────────────────────────
    local misc = makeTab("Player & Misc", "players, teleports, keys, diagnostics", "user", Theme.Rose)
    misc:AddSection("Teleport")
    misc:AddPlayerList("Players", function()
        local entries = {}
        for _, record in ipairs(World.players) do
            entries[#entries + 1] = {
                player = record.player,
                name = record.name,
                info = string.format("%s · %d studs · %s", tostring(record.team or "—"), math.floor(record.distance or 0), tostring(record.weaponName)),
                color = record.friendly and Theme.Sky or Theme.Clay,
            }
        end
        return entries
    end, {
        { label = "TP", callback = function(player) teleportToPlayer(player) end },
    })
    button(misc, "Teleport to nearest enemy", "paced, twelve studs at a time", function()
        local best = nil
        for _, record in ipairs(World.players) do
            if not record.friendly and (not best or record.distance < best.distance) then best = record end
        end
        if best then
            teleportToPlayer(best.player)
            notify("Teleport", best.name .. " · " .. math.floor(best.distance) .. " studs", 3, Theme.Rose, "compass")
        else
            notify("Teleport", "no enemy in the server", 3, Theme.Warning, "warning")
        end
    end, "compass")
    misc:AddSection("Keys")
    keybind(misc, "Show / hide window", "right control by default", "HideUiKey", "eye")
    keybind(misc, "Panic", "turns every switch off", "PanicKey", "stop")
    misc:AddSection("Diagnostics")
    toggleSwitch(misc, "Performance printout", "scan time, remote count, ESP passes", "PerfStats", "chart")
    misc:AddStatusPanel("Runtime", function()
        local target = State.target
        return {
            { label = "build", value = META.build },
            { label = "players", value = tostring(#World.players) .. " · " .. tostring(World.visibleCount) .. " visible" },
            { label = "target", value = target and (target.name .. " · " .. math.floor(target.distance or 0) .. "s") or "none" },
            { label = "shots", value = tostring(State.shots) .. " · " .. tostring(State.shotsBlocked) .. " held by cadence" },
            { label = "scan", value = string.format("%.2f ms · %d structural", State.perf.scanMs, State.perf.structureScans) },
            { label = "remotes", value = tostring(#Remotes.list) },
        }
    end, 128)
    button(misc, "Diagnostics", "prints window, loops, camera and remotes to the console (F9)", function()
        doctor()
        notify("Diagnostics", "written to the console · F9", 5, Theme.Sky, "search")
    end, "search")
    button(misc, "Run self-test", "thirty-nine checks against the live environment", function()
        local passed, total = selfTest()
        notify("Self-test", string.format("%d/%d passed — details in the console", passed, total), 6,
            passed == total and Theme.Success or Theme.Warning, "shield")
    end, "shield")
    button(misc, "Panic — disable everything", "same as the panic key", function() panic() end, "stop", true)
    misc:AddLabel("RIVALS bans for injected scripts in waves, days after the flag. Use an account you can lose. The hub cannot change that.", "warning")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 17 · PANIC, SELF-TEST, BOOT
-- ═══════════════════════════════════════════════════════════════════════════
function panic()
    for _, entry in ipairs(Switches) do
        -- not silent: a few switches undo something when they turn off (gravity,
        -- FOV, fullbright), and panic has to run those callbacks or the effect
        -- outlives the panic
        pcall(function() entry.api.Set(false, false) end)
        Config[entry.key] = false
    end
    Config.AimEnabled, Config.TriggerBot, Config.AutoFire = false, false, false
    State.target = nil
    scope(false)
    Mov.stopFly()
    setNoclip(false)
    clearEsp()
    notify("Panic", "every switch is off · fly, noclip and ESP cleared", 5, Theme.Success, "shield")
    return true
end

function selfTest()
    local passed, total = 0, 0
    local function check(name, ok, detail)
        total = total + 1
        if ok then passed = passed + 1 end
        print(string.format("[self-test] %s  %-38s %s", ok and "PASS" or "FAIL", name, detail or ""))
        return ok
    end

    local weapons = KNOWLEDGE.Weapons
    check("knowledge · weapon roster", #weapons >= 35, tostring(#weapons) .. " entries")
    local wildcat = weaponInfo("Wildcat")
    check("knowledge · wildcat row", wildcat ~= nil and wildcat.Slot == "Primary", wildcat and tostring(wildcat.Cost) or "nil")
    check("knowledge · nickname match", weaponInfo("Prime Assault Rifle") ~= nil, "contains-match")
    check("knowledge · empty name", weaponInfo("") == nil, "nil")
    check("helpers · lower list", #LOWER.Shoot > 0, tostring(#LOWER.Shoot) .. " words")
    check("helpers · split list", #splitList("Head, Torso") == 2, "2 tokens")
    check("helpers · short number", shortNumber(1500) == "1.5K", shortNumber(1500))

    local character = getChar()
    local humanoid = getHumanoid()
    check("world · character", character ~= nil, character and character.Name or "nil")
    check("world · humanoid alive", humanoid ~= nil and isAlive(), humanoid and tostring(math.floor(humanoid.Health)) or "nil")
    local snapshot = scanWorld(true)
    check("world · scan finds players", #snapshot.players >= 1, tostring(#snapshot.players) .. " others")
    local team = World.localTeam
    check("world · local team", team ~= nil or #snapshot.players == 0, tostring(team))

    -- point the camera at the nearest enemy for the picker checks: the cone is
    -- part of the aim now, so a camera left facing a wall is not a fair test
    local aimProbe, hasEnemy = nil, false
    for _, record in ipairs(snapshot.players) do
        if not record.friendly then
            hasEnemy = true
            if (record.distance or 0) < 600 then aimProbe = record end
        end
    end
    -- the team filter is asserted below, so it has to be on for the assertion
    -- to mean anything, whatever the switches were left at
    local savedTeamCheck = Config.AimTeamCheck
    if hasEnemy then Config.AimTeamCheck = true end
    local probeCamera = refreshCamera()
    local savedCFrame = probeCamera and probeCamera.CFrame or nil
    if probeCamera and aimProbe then
        pcall(function() probeCamera.CFrame = CFrame.lookAt(probeCamera.CFrame.Position, aimProbe.position) end)
    end
    local target = pickTarget()
    check("aim · picks a target", target ~= nil, target and target.name or "nil")
    check("aim · target is inside the cone", target == nil
        or angleTo(target.position) <= aimCone(), target and string.format("%.0f°", angleTo(target.position)) or "nil")
    if target then
        check("aim · team filter respected", not (Config.AimTeamCheck and target.friendly), tostring(target.friendly))
        check("aim · head resolves", aimPartOf(target) ~= nil, aimPartOf(target) and aimPartOf(target).Name or "nil")
        local position = aimPositionOf(target)
        check("aim · position is a vector", position ~= nil and position.Magnitude ~= nil, position and tostring(math.floor(position.Magnitude)) or "nil")
        check("aim · step runs", stepAim(target, 0.016) == true, "camera write")
        check("aim · angle limit", (tonumber(Config.AimStepLimit) or 0) > 0, tostring(Config.AimStepLimit) .. "°/frame")
    else
        check("aim · team filter respected", true, "no players")
        check("aim · head resolves", true, "no players")
        check("aim · position is a vector", true, "no players")
        check("aim · step runs", true, "no players")
        check("aim · angle limit", true, "no players")
        check("aim · target is inside the cone", true, "no players")
    end
    if probeCamera and savedCFrame then
        pcall(function() probeCamera.CFrame = savedCFrame end)
    end
    Config.AimTeamCheck = savedTeamCheck

    local shootRemote, shootName = findRemote(LOWER.Shoot)
    check("remotes · shoot indexed", shootRemote ~= nil, tostring(shootName))
    local reloadRemote = findRemote(LOWER.Reload)
    check("remotes · reload indexed", reloadRemote ~= nil, reloadRemote and reloadRemote.Name or "nil")
    check("remotes · rate limiter", (tonumber(Config.AcRemoteRateLimit) or 0) > 0, tostring(Config.AcRemoteRateLimit) .. "/s")

    local savedLayers = {
        AcNeutralize = Config.AcNeutralize, AcBlockReports = Config.AcBlockReports,
        AcCamouflage = Config.AcCamouflage, AcSpeedLimiter = Config.AcSpeedLimiter,
    }
    Config.AcNeutralize, Config.AcBlockReports = true, true
    Config.AcCamouflage, Config.AcSpeedLimiter = true, true
    AC.hookedIndex = AC.hookedIndex and true or false
    local armed = armAntiCheat()
    local layerCount = 0
    for _ in pairs(armed or {}) do layerCount = layerCount + 1 end
    check("ac · six layer table", layerCount >= 4, layerCount .. " layers")
    check("ac · detector pass", AC.armed.detectors == true, tostring(AC.detectorCount) .. " disabled")
    check("ac · namecall installed", AC.armed.namecall == true, tostring(AC.armed.namecall))
    check("ac · kick guard configured", type(Config.AcKickGuard) == "boolean", tostring(Config.AcKickGuard))
    check("ac · camouflage state", type(AC.armed.camouflage) == "boolean", tostring(AC.armed.camouflage))
    check("ac · limits state", type(AC.armed.limits) == "boolean", tostring(AC.patchedFields) .. " fields")
    check("ac · filter callable", type(AC.namecallFilter) == "function", "exposed")

    local before = Esp.count
    local shown = espUpdate()
    check("esp · pass attaches", shown >= 0, tostring(shown) .. " drawn")
    check("esp · cap respected", Esp.count <= 250, tostring(Esp.count))
    check("esp · refresh interval", (tonumber(Config.EspInterval) or 0) > 0, tostring(Config.EspInterval) .. " s")
    check("esp · folder created", Esp.folder ~= nil or shown == 0, Esp.folder and "yes" or "no CoreGui")

    setWalkSpeed(26)
    check("movement · speed write", humanoid == nil or math.abs((property(humanoid, "WalkSpeed") or 0) - 26) < 0.01,
        humanoid and tostring(property(humanoid, "WalkSpeed")) or "nil")
    check("movement · intern read is truthful", humanoid == nil or math.abs((property(humanoid, "WalkSpeed") or 0) - 26) < 0.01,
        humanoid and tostring(property(humanoid, "WalkSpeed")) or "nil")
    setWalkSpeed(16)

    local shotBefore = State.shots
    local fired = fire()
    check("trigger · click path", fired == true or State.shots == shotBefore, tostring(State.shots) .. " shots")
    check("trigger · cadence guard", canShoot() or State.shotsBlocked > 0, tostring(State.shotsBlocked) .. " held")

    local log = SharedEnv.__SkillHubErrorLog
    check("runtime · error log", type(log) ~= "table" or #log == 0, type(log) == "table" and tostring(#log) or "none")

    Config.AcNeutralize = savedLayers.AcNeutralize
    Config.AcBlockReports = savedLayers.AcBlockReports
    Config.AcCamouflage = savedLayers.AcCamouflage
    Config.AcSpeedLimiter = savedLayers.AcSpeedLimiter
    check("panic · available", type(panic) == "function", "callable")
    Config.AimEnabled = false

    local win = getWindow and getWindow() or nil
    local okBoot = win ~= nil and win.Root ~= nil
    check("ui · window exists", okBoot, okBoot and win.Root.Name or "no")
    check("ui · switches built", #Switches >= 60, tostring(#Switches) .. " switches")

    print(string.format("[self-test] %d/%d checks passed", passed, total))
    return passed, total
end

local function destroy()
    State.alive = false
    pcall(function() clearEsp() end)
    pcall(function() Mov.stopFly() end)
    pcall(function()
        local win = getWindow and getWindow()
        if win and win.Screen then win.Screen:Destroy()
        elseif win and win.Root then win.Root:Destroy() end
    end)
    pcall(function()
        if Esp.fov then Esp.fov:Remove() end
    end)
    if SharedEnv.SkillHubRivals then SharedEnv.SkillHubRivals = nil end
    if _G.SkillHubRivals then _G.SkillHubRivals = nil end
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SAFE MODE — if the full interface cannot be built, this panel still gives
-- access to the switches that matter. A window that fails to build must never
-- mean "nothing works".
-- ═══════════════════════════════════════════════════════════════════════════
local function buildFallback(reason)
    local parent = guiRoot()
    if not parent then return nil end
    local screen = new("ScreenGui", {
        Name = "SkillHubRIVALS", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999999,
    }, parent)
    local panel = new("Frame", {
        Name = "SafeMode", Active = true,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 330, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.BgApp, BorderSizePixel = 0,
    }, screen)
    corner(panel, RADIUS.window)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
        PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
    }, panel)
    Text({ Font = UIFontBold, Text = "Skill Hub · safe mode", TextSize = 14,
        TextColor3 = Theme.TextPrimary, TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1 }, panel)
    Text({ Text = tostring(reason or ""), TextSize = 10, TextColor3 = Theme.TextMuted,
        TextWrapped = true, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 2 }, panel)

    local rows = {
        { "Aim assist", "AimEnabled" }, { "Triggerbot", "TriggerBot" },
        { "ESP players", "EspPlayers" }, { "Chams", "EspChams" },
        { "Speed", "WalkSpeedEnabled" }, { "Fly", "FlyEnabled" },
        { "No recoil", "NoRecoil" }, { "Report filter", "AcBlockReports" },
    }
    local order = 10
    for _, row in ipairs(rows) do
        local label, key = row[1], row[2]
        local item = new("TextButton", {
            Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.BgElevated,
            BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = order,
            TextSize = 11, Font = UIFontBold, TextColor3 = Theme.TextPrimary,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
        }, panel)
        order = order + 1
        corner(item, RADIUS.control)
        local pad = new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, item)
        pad.Name = "Pad"
        local function paint()
            item.Text = label .. (Config[key] and "    ON" or "    off")
            item.TextColor3 = Config[key] and Theme.Success or Theme.TextSecondary
        end
        item.MouseButton1Click:Connect(function()
            Config[key] = not Config[key]
            paint()
        end)
        paint()
    end
    local close = new("TextButton", {
        Text = "Close", AutoButtonColor = false, BackgroundColor3 = Theme.BgInset,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = order,
        TextSize = 11, Font = UIFontBold, TextColor3 = Theme.TextSecondary,
    }, panel)
    corner(close, RADIUS.control)
    close.MouseButton1Click:Connect(function()
        State.alive = false
        pcall(function() screen:Destroy() end)
    end)
    print("[Skill Hub] safe-mode panel built: " .. tostring(reason))
    return screen
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DOCTOR — one call that says what is alive. Used by the Diagnostics button and
-- by anyone who has to report "it does not work": paste its output.
-- ═══════════════════════════════════════════════════════════════════════════
function doctor()
    local function since(value)
        if not value or value <= 0 then return "never" end
        return string.format("%.1fs", os.clock() - value)
    end
    local lines = {}
    local function row(label, value)
        lines[#lines + 1] = string.format("%-11s %s", label, tostring(value))
        print(string.format("[doctor] %-11s %s", label, tostring(value)))
    end
    local okBuild, win = pcall(getWindow)
    row("build", META.version .. " / " .. META.build)
    row("executor", string.format("hookmetamethod=%s getgc=%s mousemove=%s mouse1=%s gethui=%s drawing=%s",
        tostring(type(hookmetamethod) == "function"), tostring(type(getgc) == "function"),
        tostring(type(mousemoverel) == "function"), tostring(type(mouse1click) == "function"),
        tostring(type(gethui) == "function"), tostring(type(Drawing) == "table")))
    row("window", (okBuild and win and win.Root and win.Root.Parent) and "built" or "missing")
    row("tabs", tostring(#Tabs) .. " tabs / " .. tostring(#Switches) .. " switches")
    row("render aim", tostring(Aim.renderBound == true) .. " · " .. tostring(Aim.renderSteps or 0) .. " frames")
    row("aim method", tostring(Aim.lastMethod or "—") .. " · " .. string.format("%.2f°/px", tonumber(Aim.perPixel) or tonumber(Config.AimMouseSensitivity) or 0.35)
        .. " · fallbacks " .. tostring(State.perf.aimFallbacks or 0))
    row("beats", string.format("combat %s esp %s move %s util %s",
        since(State.beats.combat), since(State.beats.esp),
        since(State.beats.movement), since(State.beats.utility)))
    row("camera", (function()
        local camera = refreshCamera()
        return (camera and camera.Parent) and "ok" or "missing"
    end)())
    row("players", tostring(#World.players) .. " / target " .. tostring(State.target and State.target.name or "none"))
    row("remotes", tostring(#Remotes.list) .. " indexed")
    row("shots", tostring(State.shots) .. " fired / " .. tostring(State.shotsBlocked) .. " blocked")
    row("method", tostring(Config.AimMethod) .. " / last " .. tostring(Aim.lastMethod or "none"))
    row("ac", string.format("detectors=%s namecall=%s camo=%s limits=%s",
        tostring(AC.armed and AC.armed.detectors), tostring(AC.armed and AC.armed.namecall),
        tostring(AC.armed and AC.armed.camouflage), tostring(AC.armed and AC.armed.limits)))
    local errors = SharedEnv and SharedEnv.__SkillHubErrorLog or {}
    row("errors", tostring(#errors))
    if #errors > 0 then
        for index = 1, math.min(#errors, 5) do row("error " .. index, errors[index]) end
    end
    return table.concat(lines, "\n")
end

local function boot()
    local started = os.clock()

    -- exactly one instance: a second execution unloads the first, or two aim
    -- loops end up writing to the same camera and the user sees "it broke"
    local previous = SharedEnv and SharedEnv.SkillHubRivals
    if previous and type(previous.destroy) == "function" then
        pcall(previous.destroy)
        print("[Skill Hub] previous instance unloaded")
    end
    if SharedEnv then SharedEnv.SkillHubRivals = nil end
    if _G ~= SharedEnv then _G.SkillHubRivals = nil end

    -- every subsystem in its own pcall: a failure in the anti-cheat layer must
    -- not take the aim down with it, and a failure in the interface must not
    -- stop the keybinds. Each line of the boot report is one step.
    local steps = {
        { "window", function() buildWindow() end },
        { "tabs", function() buildTabs() end },
        { "anti-cheat", function() armAntiCheat() end },
        { "aim driver", function() startRenderAim() end },
        { "combat", combatLoop },
        { "movement", movementLoop },
        { "fall guard", fallGuard },
        { "esp", espLoop },
        { "utility", utilityLoop },
        { "fun", funLoop },
        { "staff watch", staffWatchLoop },
        { "kick watch", kickWatcher },
        { "recoil", recoilLoop },
    }
    local report = {}
    for _, step in ipairs(steps) do
        local ok, err = pcall(step[2])
        if ok then
            report[#report + 1] = step[1]
        else
            report[#report + 1] = step[1] .. "!"
            print("[Skill Hub] step failed · " .. step[1] .. " · " .. tostring(err))
        end
    end
    if not getWindow() or #Tabs == 0 then
        local okFallback = pcall(buildFallback, "the full interface did not build — this panel still works")
        if okFallback then report[#report + 1] = "safe mode" end
    end

    -- keys: show/hide, panic, aim. `gameProcessed` is the difference between a
    -- key press and someone typing the same letter into chat.
    local function syncSwitch(key, value)
        for _, entry in ipairs(Switches) do
            if entry.key == key then
                pcall(function() entry.api.Set(value, true) end)
                return
            end
        end
    end
    if UserInput then
        UserInput.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local key = input.KeyCode and input.KeyCode.Name or ""
            if key == Config.HideUiKey then
                local win = getWindow()
                if win and win.Root then
                    if win.Screen then pcall(function() win.Screen.Enabled = true end) end
                    win.Root.Visible = not win.Root.Visible
                    Config.UiVisible = win.Root.Visible
                end
            elseif key == Config.PanicKey then
                panic()
            elseif key == Config.AimKey then
                if Config.AimToggle then
                    local nextState = not Config.AimEnabled
                    syncSwitch("AimEnabled", nextState)
                    Config.AimEnabled = nextState
                    if nextState then
                        notify("Aim", "on · " .. tostring(Config.AimMethod), 2, Theme.Clay, "swords")
                    end
                else
                    syncSwitch("AimEnabled", true)
                    Config.AimEnabled = true
                end
            end
        end)
        UserInput.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard
                and not Config.AimToggle and (input.KeyCode and input.KeyCode.Name) == Config.AimKey then
                syncSwitch("AimEnabled", false)
                Config.AimEnabled = false
            end
        end)
    end

    do
        local win = getWindow()
        if win and win.Root and Config.UiVisible == false then win.Root.Visible = false end
    end

    -- loadout attempt per life
    local lastCharacter = nil
    task.spawn(function()
        while State.alive do
            task.wait(1.5)
            if Config.AutoEquipOnSpawn then
                local character = getChar()
                if character and character ~= lastCharacter then
                    lastCharacter = character
                    task.wait(1)
                    protectLoop("equip", function() equipWeapon(Config.LoadoutPreset) end)
                end
            end
        end
    end)

    -- optional periodic performance print
    task.spawn(function()
        while State.alive do
            task.wait(10)
            if Config.PerfStats then
                protectLoop("perf print", function()
                    print(string.format("[Skill Hub] perf · scan %.2f ms · esp %d · remotes %d · shots %d/%d",
                        State.perf.scanMs, Esp.count, #Remotes.list, State.shots, State.shotsBlocked))
                end)
            end
        end
    end)

    local title = string.format("[Skill Hub] %s · %s · free build", META.game, META.version)
    print(title)
    print("[Skill Hub] boot · " .. table.concat(report, " · "))
    local names = {}
    for _, tab in ipairs(Tabs) do names[#names + 1] = tab.title end
    print("[Skill Hub] tabs · " .. table.concat(names, " · "))
    print(string.format("[Skill Hub] switches · %d · anti-cheat · detectors=%s namecall=%s camouflage=%s limits=%s",
        #Switches, tostring(AC.armed.detectors), tostring(AC.armed.namecall),
        tostring(AC.armed.camouflage), tostring(AC.armed.limits)))
    print(string.format("[Skill Hub] ready in %.0f ms", (os.clock() - started) * 1000))
    return true
end


-- the chunk must survive a boot failure: if something at the top of boot dies,
-- the export and the doctor still exist and a second run can clean up
do
    local ok, err = pcall(boot)
    if not ok then print("[Skill Hub] boot failed · " .. tostring(err)) end
end

local API = {
    version = META.version, build = META.build, game = META.game,
    config = Config, state = State, knowledge = KNOWLEDGE,
    world = function() return scanWorld(true) end,
    players = function() return World.players end,
    pickTarget = pickTarget, aimPart = aimPartOf, aimPosition = aimPositionOf,
    targetAllowed = targetAllowed, stepAim = stepAim,
    fire = fire, canShoot = canShoot, reload = reloadNow, equip = equipWeapon,
    clickMouse = clickMouse, pressKey = pressKey, melee = meleeNow,
    setSpeed = setWalkSpeed, setJump = setJumpPower, noclip = setNoclip,
    silentPosition = silentAimPosition, namecall = namecallFilter,
    bright = applyFullbright, antiFlash = antiFlash, smoke = clearSmoke, strip = stripEffects,
    gravity = setGravity, protect = protectLoop,
    say = sayChat, hop = serverHop, teleportTo = teleportToPlayer,
    playSound = playSound, killEffect = killEffect, patchWeapons = patchWeaponStats,
    flying = function() return Mov.flyBody ~= nil end,
    espFolder = espFolder, worldData = World,
    espUpdate = espUpdate, espClear = clearEsp, espCount = function() return Esp.count end,
    clearEsp = clearEsp, fovCircle = fovCircle,
    ac = AC, acArm = armAntiCheat, acFilter = namecallFilter,
    findRemote = findRemote, fireRemote = fireRemote,
    travel = travelTo, queue = joinQueue, leave = leaveMatch, say = sayChat,
    selfTest = selfTest, panic = panic, destroy = destroy, doctor = doctor,
    renderBound = function() return Aim.renderBound == true end,
    renderSteps = function() return Aim.renderSteps or 0 end,
    lastAimPixels = function()
        local p = Aim.lastPixels
        return p and p.x or 0, p and p.y or 0
    end,
    aimPoint = function() return Aim.aimPosition end,
    fallbacks = function() return State.perf.aimFallbacks or 0 end,
    character = function() return getChar() end,
    fallback = buildFallback,
    alive = function() return isAlive() end,
    window = function() return getWindow() end,
    method = function() return Aim.lastMethod end,
    tabs = Tabs,
    switchCount = function() return #Switches end,
    scan = function(force) return scanWorld(force == true) end,
    tabTitles = function()
        local out = {}
        for index, tab in ipairs(Tabs) do out[index] = tab.title end
        return out
    end,
}

if SharedEnv then SharedEnv.SkillHubRivals = API end
if _G and _G ~= SharedEnv then _G.SkillHubRivals = API end

if SharedEnv and SharedEnv.__SKILLHUB_SELFTEST then
    selfTest()
end

return API

