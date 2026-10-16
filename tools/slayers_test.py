#!/usr/bin/env python3
"""Boot the Slayers 2 hub for real in a mocked Roblox and drive every feature.

    python3 tools/slayers_test.py

The mock provides a virtual clock, a coroutine scheduler (so the hub's
`while alive do … task.wait() end` loops really tick), one shared instance
metatable with `__namecall` dispatch (so the report-filter hook can be exercised
for real), Vector3/CFrame/Color3 maths, the services the hub touches, the
executor globals it probes, and a fake game containing a detector LocalScript +
a report RemoteEvent so the anti-cheat layer has something to find.

Checked: load · UI · all seven tabs · every toggle on then off · live loops ·
hitbox · ESP · teleport targets · the anti-cheat audit + report blocking ·
the built-in self-test · panic · unload.
"""
import io, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
HUB = os.path.join(HERE, os.pardir, "Slayers 2", "SkillHub.lua")

try:
    from lupa import LuaRuntime
except ImportError:
    print("this test needs lupa and a Lua runtime:")
    print("    python3 -m venv /tmp/venv && /tmp/venv/bin/pip install lupa")
    sys.exit(2)

PRELUDE = r"""
-- Roblox (Lua 5.1) still has math.atan2; Lua 5.5 removed it, so restore it
-- the way an executor does.
math.atan2 = function(y, x) return math.atan(y, x) end

-- ═══ virtual clock + scheduler ═════════════════════════════════════════════
local CLOCK = { now = 0, tasks = {} }
_G.__CLOCK = CLOCK
os.clock = function() return CLOCK.now end
_G.__HARNESS_ERRORS = {}

local function schedule(thread, wake)
    table.insert(CLOCK.tasks, { thread = thread, wake = wake })
end

function task_spawn(fn, ...)
    local thread = coroutine.create(fn)
    local ok, wait = coroutine.resume(thread, ...)
    if not ok then table.insert(_G.__HARNESS_ERRORS, "spawn: " .. tostring(wait)) end
    if coroutine.status(thread) ~= "dead" then schedule(thread, CLOCK.now + (tonumber(wait) or 0)) end
    return thread
end

function task_wait(seconds) return coroutine.yield(seconds or 0.03) end

function pump(step)
    CLOCK.now = CLOCK.now + step
    local pending = CLOCK.tasks
    CLOCK.tasks = {}
    for _, entry in ipairs(pending) do
        if coroutine.status(entry.thread) == "suspended" then
            local ok, wait = coroutine.resume(entry.thread)
            if not ok then table.insert(_G.__HARNESS_ERRORS, "task: " .. tostring(wait)) end
            if coroutine.status(entry.thread) ~= "dead" then
                schedule(entry.thread, CLOCK.now + (tonumber(wait) or 0.03))
            end
        end
    end
    if _G.__STEPPED then _G.__STEPPED(step) end
end

-- ═══ value types ═══════════════════════════════════════════════════════════
local V3 = {}
V3.__index = function(v, key)
    if key == "X" then return v.x end
    if key == "Y" then return v.y end
    if key == "Z" then return v.z end
    if key == "Magnitude" then return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z) end
    if key == "Unit" then
        local m = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
        if m > 0 then return V3.new(v.x / m, v.y / m, v.z / m) end
        return V3.new(0, 0, 0)
    end
    return rawget(V3, key)
end
V3.__add = function(a, b) return V3.new(a.x + b.x, a.y + b.y, a.z + b.z) end
V3.__sub = function(a, b) return V3.new(a.x - b.x, a.y - b.y, a.z - b.z) end
V3.__mul = function(a, b)
    if type(b) == "number" then return V3.new(a.x * b, a.y * b, a.z * b) end
    return V3.new(a.x * b.x, a.y * b.y, a.z * b.z)
end
V3.__eq = function(a, b) return a.x == b.x and a.y == b.y and a.z == b.z end
V3.__tostring = function(v) return string.format("(%.1f, %.1f, %.1f)", v.x, v.y, v.z) end
function V3.new(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, V3) end
_G.Vector3 = { new = V3.new, zero = V3.new(0, 0, 0) }
_G.Vector2 = { new = function(x, y) return { X = x or 0, Y = y or 0 } end }
_G.Color3 = { fromRGB = function(r, g, b)
    local color = { R = r, G = g, B = b }
    function color:Lerp(other, amount)
        return _G.Color3.fromRGB(r + (other.R - r) * amount, g + (other.G - g) * amount, b + (other.B - b) * amount)
    end
    return color
end }
_G.UDim = { new = function(scale, offset) return { Scale = scale, Offset = offset or 0 } end }
_G.UDim2 = { new = function(xs, xo, ys, yo)
    return { X = { Scale = xs, Offset = xo or 0 }, Y = { Scale = ys, Offset = yo or 0 } }
end }
_G.TweenInfo = { new = function(duration, style, direction, repeatCount, reverses, delayTime)
    return { Time = duration or 0.2, EasingStyle = style, EasingDirection = direction,
        RepeatCount = repeatCount or 0, Reverses = reverses or false, DelayTime = delayTime or 0 }
end }
_G.Enum = setmetatable({}, { __index = function(_, group)
    return setmetatable({}, { __index = function(_, item)
        return setmetatable({ Name = item, Value = 0, EnumType = group },
            { __index = function() return item end })
    end })
end })

local CF = {}
CF.__index = CF
CF.__mul = function(a, b)
    if type(b) == "table" and b.x and not b.Position then
        return V3.new(a.Position.x + b.x, a.Position.y + b.y, a.Position.z + b.z)
    end
    return a
end
function CFrame_new(position, lookAt)
    local positionV = position or V3.new(0, 0, 0)
    local look = lookAt and (lookAt - positionV) or V3.new(0, 0, -1)
    if look.Magnitude > 0 then look = look.Unit end
    local cframe = setmetatable({ Position = positionV, LookVector = look,
        RightVector = V3.new(-look.z, 0, look.x), UpVector = V3.new(0, 1, 0),
        X = positionV.x, Y = positionV.y, Z = positionV.z }, CF)
    function cframe:Lerp(other) return other end
    return cframe
end
_G.CFrame = { new = CFrame_new, Angles = function() return CFrame_new() end,
    fromEulerAnglesXYZ = function() return CFrame_new() end }

-- ═══ instances: one shared metatable, namecall-routed methods ══════════════
local INSTANCES = {}
_G.__instances = INSTANCES
local RAW_FALLBACK = function() return nil end
_G.setNamecallFallback = function(fn) RAW_FALLBACK = fn end

local KNOWN_EVENTS = {}
for _, name in ipairs({ "Changed", "AttributeChanged", "ChildAdded", "ChildRemoved", "DescendantAdded",
    "DescendantRemoving", "Died", "CharacterAdded", "CharacterRemoving", "PlayerAdded", "PlayerRemoving",
    "InputBegan", "InputChanged", "InputEnded", "MouseEnter", "MouseLeave", "MouseButton1Click",
    "MouseButton1Down", "MouseButton1Up", "MouseWheel", "TouchTap", "TouchLongPress", "Activated",
    "Triggered", "TriggerEnded", "PromptButtonHoldBegan", "PromptButtonHoldEnded", "PromptTriggered",
    "RenderStepped", "Heartbeat", "Stepped", "PreRender", "PreSimulation", "PostSimulation",
    "JumpRequest", "StateChanged", "Focused", "FocusLost", "Click", "Equipped", "Unequipped",
    "HealthChanged", "Touched", "TouchEnded", "Landed", "Running", "RunningStopped",
}) do KNOWN_EVENTS[name] = true end

local function signalOf(self, key)
    if not KNOWN_EVENTS[key] and not rawget(self, "__signals")[key] then return nil end
    local signals = rawget(self, "__signals")
    if not signals[key] then
        local bucket
        bucket = { handlers = {} }
        function bucket.Connect(_, fn)
            table.insert(bucket.handlers, fn)
            return { Disconnect = function() end, Connected = true }
        end
        bucket.Once = bucket.Connect
        bucket.Wait = function() return nil end
        signals[key] = bucket
    end
    return signals[key]
end

local function findChildOf(self, childName)
    for _, child in ipairs(rawget(self, "__children")) do
        if rawget(child, "__props").Name == childName then return child end
    end
    return nil
end

local CLASS_PARENTS = {
    Part = "BasePart", MeshPart = "BasePart", UnionOperation = "BasePart", TrussPart = "BasePart",
    WedgePart = "BasePart", CornerWedgePart = "BasePart", NegativePart = "BasePart",
    LocalScript = "BaseScript", Script = "BaseScript", ModuleScript = "LuaSourceContainer",
    TextBox = "GuiObject", TextButton = "GuiObject", TextLabel = "GuiObject", ImageLabel = "GuiObject",
    Frame = "GuiObject", ScrollingFrame = "GuiObject", CanvasGroup = "GuiObject",
    UIStroke = "UIComponent", UICorner = "UIComponent", UIPadding = "UIComponent", UIListLayout = "UIComponent",
    UIStroke2 = "UIComponent", ScreenGui = "LayerCollector", BillboardGui = "LayerCollector", SurfaceGui = "LayerCollector",
    RemoteEvent = "BaseRemoteEvent", UnreliableRemoteEvent = "BaseRemoteEvent", RemoteFunction = "BaseRemoteEvent",
    IntValue = "ValueBase", NumberValue = "ValueBase", StringValue = "ValueBase", BoolValue = "ValueBase",
    Highlight = "Instance", Folder = "Instance", Model = "Instance", Humanoid = "Instance",
}

local function isA(self, wanted)
    local class = rawget(self, "__class")
    if class == wanted then return true end
    local parent = CLASS_PARENTS[class]
    while parent do
        if parent == wanted then return true end
        parent = CLASS_PARENTS[parent]
    end
    return false
end

local METHODS = {}
function METHODS.FindFirstChild(self, childName) return findChildOf(self, childName) end
function METHODS.WaitForChild(self, childName) return findChildOf(self, childName) end
function METHODS.FindFirstChildOfClass(self, wanted)
    for _, child in ipairs(rawget(self, "__children")) do
        if rawget(child, "__class") == wanted then return child end
    end
    return nil
end
function METHODS.FindFirstChildWhichIsA(self, wanted, recursive)
    for _, child in ipairs(rawget(self, "__children")) do
        if isA(child, wanted) then return child end
        if recursive then
            local deep = METHODS.FindFirstChildWhichIsA(child, wanted, true)
            if deep then return deep end
        end
    end
    return nil
end
function METHODS.GetChildren(self)
    local copy = {}
    for index, child in ipairs(rawget(self, "__children")) do copy[index] = child end
    return copy
end
function METHODS.GetDescendants(self)
    local out = {}
    for _, child in ipairs(rawget(self, "__children")) do
        table.insert(out, child)
        for _, deep in ipairs(METHODS.GetDescendants(child)) do table.insert(out, deep) end
    end
    return out
end
function METHODS.IsA(self, wanted) return isA(self, wanted) end
function METHODS.IsAncestorOf(self, other)
    local parent = rawget(other, "__parent")
    while parent do
        if parent == self then return true end
        parent = rawget(parent, "__parent")
    end
    return false
end
function METHODS.GetFullName(self)
    local parts, node = {}, self
    while node do
        table.insert(parts, 1, tostring(rawget(node, "__props").Name))
        node = rawget(node, "__parent")
    end
    return table.concat(parts, ".")
end
function METHODS.GetPropertyChangedSignal(self, property) return signalOf(self, property .. "_changed") or signalOf(self, "Changed") end
function METHODS.GetAttribute(self, key) return rawget(self, "__attributes")[key] end
function METHODS.SetAttribute(self, key, value)
    rawget(self, "__attributes")[key] = value
    local bucket = rawget(self, "__signals")[key .. "_changed"]
    if bucket then for _, fn in ipairs(bucket.handlers) do fn() end end
end
function METHODS.GetRankInGroup() return 0 end
function METHODS.Destroy(self)
    local parent = rawget(self, "__parent")
    if parent then
        for index, child in ipairs(rawget(parent, "__children")) do
            if child == self then table.remove(rawget(parent, "__children"), index) break end
        end
    end
    rawget(self, "__props").Parent = nil
    rawset(self, "__parent", nil)
    _G.__HARNESS_DESTROYED = (_G.__HARNESS_DESTROYED or 0) + 1
end
function METHODS.CaptureFocus() end
function METHODS.ReleaseFocus() end
function METHODS.GetMouse() return makeInstance("Mouse") end
function METHODS.EquipTool(self, tool) tool.Parent = self end
function METHODS.ChangeState() end
function METHODS.GetState() return _G.Enum.HumanoidStateType.Running end
function METHODS.SetStateEnabled() end
function METHODS.TakeDamage() end
function METHODS.Activate() _G.__HARNESS_ACTIVATIONS = (_G.__HARNESS_ACTIVATIONS or 0) + 1 end
function METHODS.InputHoldBegin() end
function METHODS.InputHoldEnd() end
function METHODS.FireServer()
    _G.__HARNESS_FIRED = (_G.__HARNESS_FIRED or 0) + 1
    return "fired"
end
function METHODS.InvokeServer() return nil end
function METHODS.WorldToViewportPoint() return V3.new(400, 300, 1), true end
function METHODS.CaptureController() end
function METHODS.SendKeyEvent() end
function METHODS.ClickButton2() end
function METHODS.Teleport() end
function METHODS.TeleportToPlaceInstance() end
function METHODS.GetPlayers() return _G.__HARNESS_PLAYERS or {} end
function METHODS.GetValue() return 1 end
function METHODS.Kick(self, reason)
    _G.__HARNESS_KICKS = (_G.__HARNESS_KICKS or 0) + 1
    return reason
end

local function rawDispatch(self, method, ...)
    local handler = METHODS[method]
    if handler then return handler(self, ...) end
    return RAW_FALLBACK(self, method, ...)
end

function __RAW_NAMECALL(self, method, ...) return rawDispatch(self, method, ...) end

local INSTANCE_MT = {}
INSTANCE_MT.__index = function(self, key)
    local props = rawget(self, "__props")
    if key == "ClassName" then return rawget(self, "__class") end
    if key == "Name" then return props.Name end
    if key == "Parent" then return rawget(self, "__parent") end
    if props[key] ~= nil then return props[key] end
    if METHODS[key] then
        -- every method call is routed through __namecall, exactly like Roblox,
        -- so hooking __namecall once covers the entire DataModel. `obj:Method(a)`
        -- arrives here as (obj, a) because __index handed back a plain function,
        -- so unwrap the instance when it is repeated.
        return function(...)
            local args = table.pack(...)
            local target = self
            if args.n > 0 and type(args[1]) == "table" and rawget(args[1], "__class") ~= nil then
                target = args[1]
                table.remove(args, 1)
                args.n = args.n - 1
            end
            local namecall = rawget(INSTANCE_MT, "__namecall")
            if type(namecall) == "function" then
                return namecall(target, key, table.unpack(args, 1, args.n))
            end
            return METHODS[key](target, table.unpack(args, 1, args.n))
        end
    end
    return signalOf(self, key)
end
INSTANCE_MT.__newindex = function(self, key, value)
    if key == "Parent" then
        local oldParent = rawget(self, "__parent")
        if oldParent then
            for index, child in ipairs(rawget(oldParent, "__children")) do
                if child == self then table.remove(rawget(oldParent, "__children"), index) break end
            end
        end
        rawset(self, "__parent", value)
        if value then table.insert(rawget(value, "__children"), self) end
        return
    end
    rawget(self, "__props")[key] = value
    local bucket = rawget(self, "__signals")[key .. "_changed"]
    if bucket then for _, fn in ipairs(bucket.handlers) do fn() end end
end
INSTANCE_MT.__tostring = function(self)
    return rawget(self, "__class") .. ":" .. tostring(rawget(self, "__props").Name)
end
INSTANCE_MT.__namecall = __RAW_NAMECALL

function makeInstance(class, name)
    local instance = setmetatable({
        __class = class, __props = { Name = name or class }, __children = {},
        __signals = {}, __attributes = {},
    }, INSTANCE_MT)
    table.insert(INSTANCES, instance)
    return instance
end

_G.Instance = { new = function(class, parent)
    local instance = makeInstance(class)
    if parent then instance.Parent = parent end
    return instance
end }

-- ═══ the engine surface ════════════════════════════════════════════════════
_G.game = makeInstance("DataModel", "Game")
local dataModel = _G.game
_G.workspace = makeInstance("Workspace", "Workspace")

local function humanoidModel(name, health, position, isBoss)
    local model = makeInstance("Model", name)
    local root = makeInstance("Part", "HumanoidRootPart")
    root.Position = position
    root.CFrame = CFrame_new(position)
    root.Size = V3.new(2, 2, 1)
    root.Parent = model
    local humanoid = makeInstance("Humanoid", "Humanoid")
    humanoid.Health = health
    humanoid.MaxHealth = isBoss and (health * 3) or health
    humanoid.WalkSpeed = 16
    humanoid.Parent = model
    -- every real Roblox character also carries a Head + Torso, which is what the
    -- hitbox expander actually scales
    for _, partName in ipairs({ "Head", "Torso" }) do
        local limb = makeInstance("Part", partName)
        limb.Size = V3.new(2, 2, 1)
        limb.Position = position + V3.new(0, 1, 0)
        limb.CFrame = CFrame_new(limb.Position)
        limb.Parent = model
    end
    model.PrimaryPart = root
    return model, humanoid
end

local function makePart(name, position, parent)
    local piece = makeInstance("Part", name)
    piece.Size = V3.new(4, 4, 4)
    piece.Position = position
    piece.CFrame = CFrame_new(position)
    piece.Parent = parent or _G.workspace
    return piece
end

local mobs = makeInstance("Folder", "Mobs")
mobs.Parent = _G.workspace
for index = 1, 4 do
    local mob = humanoidModel("Bandit" .. index, 100, V3.new(20 * index, 3, 15), false)
    mob.Parent = mobs
end
do
    local boss = humanoidModel("Hoyuzo", 5000, V3.new(120, 3, 40), true)
    boss.Parent = mobs
end
do
    local trainer = humanoidModel("Urokodaki", 100, V3.new(-30, 3, 25), false)
    trainer.Parent = _G.workspace
end
do
    local dummy = humanoidModel("TrainingDummy", 1000, V3.new(6, 3, 6), false)
    dummy.Parent = _G.workspace
end
do
    local chest = makeInstance("Model", "CommonChest")
    makePart("ChestPart", V3.new(40, 3, 10), chest)
    chest.Parent = _G.workspace
    local prompt = makeInstance("ProximityPrompt", "OpenChestPrompt")
    prompt.ActionText = "Open"
    prompt.HoldDuration = 0
    prompt.Enabled = true
    prompt.Parent = chest
end
do
    local questNpc = makeInstance("Model", "Krue")
    local prompt = makeInstance("ProximityPrompt", "TalkToKrue")
    prompt.ActionText = "Talk"
    prompt.Enabled = true
    prompt.Parent = questNpc
    questNpc.Parent = _G.workspace
    makePart("Torso", V3.new(10, 3, 12), questNpc)
    questNpc.PrimaryPart = questNpc.Torso
end
makePart("ItemDrop", V3.new(15, 3, 5), _G.workspace)
makePart("SpiderLily", V3.new(60, 3, 5), _G.workspace)
do
    local zone = makeInstance("Folder", "Bamboo Grove")
    makePart("GroveFloor", V3.new(0, 0, 0), zone)
    zone.Parent = _G.workspace
end

local replicated = makeInstance("ReplicatedStorage", "ReplicatedStorage")
local detector = makeInstance("LocalScript", "AntiCheatClient")
detector.Disabled = false
detector.Parent = replicated
local reportRemote = makeInstance("RemoteEvent", "AntiCheatReport")
reportRemote.Parent = replicated
local safeRemote = makeInstance("RemoteEvent", "QuestAccept")
safeRemote.Parent = replicated

local players = makeInstance("Players", "Players")
local localPlayer = makeInstance("Player", "TestPlayer")
localPlayer.UserId = 1
localPlayer.DisplayName = "TestPlayer"
local character = humanoidModel("TestCharacter", 100, V3.new(0, 3, 0), false)
character.Parent = _G.workspace
localPlayer.Character = character
local backpack = makeInstance("Backpack", "Backpack")
backpack.Parent = localPlayer
do
    local katana = makeInstance("Tool", "Nichirin Katana")
    katana.Parent = backpack
end
do
    local other = makeInstance("Player", "SomeoneElse")
    other.UserId = 2
    other.DisplayName = "SomeoneElse"
    local otherCharacter = humanoidModel("OtherCharacter", 100, V3.new(30, 3, 30), false)
    otherCharacter.Parent = _G.workspace
    other.Character = otherCharacter
    _G.__HARNESS_PLAYERS = { localPlayer, other }
end
local playerGui = makeInstance("PlayerGui", "PlayerGui")
playerGui.Parent = localPlayer
local playerScripts = makeInstance("PlayerScripts", "PlayerScripts")
playerScripts.Parent = localPlayer
players.LocalPlayer = localPlayer
players.GetPlayers = function() return _G.__HARNESS_PLAYERS end

local camera = makeInstance("Camera", "Camera")
camera.ViewportSize = { X = 800, Y = 600 }
camera.CFrame = CFrame_new()
_G.workspace.CurrentCamera = camera

local services = {
    Players = players, Workspace = _G.workspace, Lighting = makeInstance("Lighting", "Lighting"),
    CoreGui = makeInstance("CoreGui", "CoreGui"), ReplicatedStorage = replicated,
    ReplicatedFirst = makeInstance("ReplicatedFirst", "ReplicatedFirst"),
    TweenService = makeInstance("TweenService", "TweenService"),
    RunService = makeInstance("RunService", "RunService"),
    UserInputService = makeInstance("UserInputService", "UserInputService"),
    CollectionService = makeInstance("CollectionService", "CollectionService"),
    VirtualUser = makeInstance("VirtualUser", "VirtualUser"),
    VirtualInputManager = makeInstance("VirtualInputManager", "VirtualInputManager"),
    TeleportService = makeInstance("TeleportService", "TeleportService"),
    Stats = makeInstance("Stats", "Stats"),
};
services.Stats.Network = makeInstance("Network", "Network")
services.Stats.Network.ServerStatsItem = { ["Data Ping"] = { GetValue = function() return 42 end } }
services.TweenService.Create = function(_, instance, info, goal)
    return {
        Play = function()
            for key, value in pairs(goal) do pcall(function() instance[key] = value end) end
        end,
        Cancel = function() end,
    }
end
services.UserInputService.IsKeyDown = function() return false end
services.CollectionService.GetTags = function() return {} end
services.CollectionService.HasTag = function() return false end

dataModel.GetService = function(_, name) return services[name] or makeInstance(name, name) end
dataModel.PlaceId = 9900000001
dataModel.JobId = "job-test"
dataModel.HttpGet = function() return "" end

function _G.__STEPPED(step)
    local function fire(bucket)
        if not bucket then return end
        for _, fn in ipairs(bucket.handlers) do
            local ok, err = pcall(fn, step)
            if not ok then table.insert(_G.__HARNESS_ERRORS, "frame: " .. tostring(err)) end
        end
    end
    fire(rawget(services.RunService, "__signals").RenderStepped)
    fire(rawget(services.RunService, "__signals").Heartbeat)
end

-- ═══ executor globals the hub probes ═══════════════════════════════════════
function _G.getgenv() return _G end
function _G.gethui() return _G.__HUI end
function _G.protect_gui(gui) _G.__PROTECTED = (_G.__PROTECTED or 0) + 1 return gui end
_G.__HUI = makeInstance("Folder", "Hui")
function _G.getrawmetatable(object) return getmetatable(object) end
function _G.hookfunction(original, replacement)
    rawset(getmetatable(dataModel), "__namecall", replacement)
    return original
end
function _G.newcclosure(fn) return fn end
function _G.getconnections() return {} end
function _G.fireproximityprompt() _G.__HARNESS_PROMPTS = (_G.__HARNESS_PROMPTS or 0) + 1 end
function _G.keypress() _G.__HARNESS_KEYS = (_G.__HARNESS_KEYS or 0) + 1 end
function _G.mouse1click() end
function _G.request() return { Body = '{"data":[{"id":"other-job-1"}]}' } end
function _G.settings() return { Rendering = { QualityLevel = 0 } } end

_G.task = {
    spawn = function(fn, ...) return task_spawn(fn, ...) end,
    defer = function(fn, ...) return task_spawn(fn, ...) end,
    delay = function(seconds, fn, ...)
        local args = table.pack(...)
        return task_spawn(function()
            task_wait(seconds)
            return fn(table.unpack(args, 1, args.n))
        end)
    end,
    wait = function(seconds) return task_wait(seconds) end,
    cancel = function() end,
}
_G.wait = function(seconds) return task_wait(seconds) end
"""

CHECKS_BOOT = r"""
_G.__RESULTS = {}
local hub = _G.SkillHubSlayers2
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end

check("hub exported to getgenv", hub ~= nil)
check("version", hub and hub.version == "v1.0", hub and tostring(hub.version))

local gui = nil
for _, child in ipairs(_G.gethui():GetChildren()) do
    if child.Name == "SkillHubSlayers2" then gui = child end
end
check("window created in the hidden gui", gui ~= nil)
check("window chrome built", gui ~= nil and #gui:GetDescendants() > 60,
    gui and (#gui:GetDescendants() .. " instances"))

check("seven tabs", hub and #hub.tabs == 7, hub and tostring(#hub.tabs))
local switched, content = 0, 0
for _, tab in ipairs(hub.tabs) do
    local ok = pcall(tab.Select)
    if ok then switched = switched + 1 end
    if #tab.page:GetChildren() > 1 then content = content + 1 end
end
check("every tab selects", switched == 7, switched .. "/7")
check("every tab has components", content == 7, content .. "/7")

local toggles = 0
for _, tab in ipairs(hub.tabs) do
    for _, api in ipairs(tab.toggles or {}) do
        toggles = toggles + 1
        api.Set(true, false)                 -- with the callback, like a real click
    end
end
check("toggles built and switched on", toggles >= 35, toggles .. " toggles")
"""

CHECKS_RUN = r"""
-- 22 virtual seconds: farm, combat, ESP, defence, chrome and the scheduler run
for index = 1, 88 do pump(0.25) end
"""

CHECKS_AFTER = r"""
local hub = _G.SkillHubSlayers2
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end
local function errors()
    return table.concat(_G.__SkillHubErrorLog, " | ")
end

check("no errors while every feature ran", #_G.__SkillHubErrorLog == 0, errors():sub(1, 300))
check("weapon activations happened", (_G.__HARNESS_ACTIVATIONS or 0) > 0,
    tostring(_G.__HARNESS_ACTIVATIONS or 0) .. " activations")
check("skill keys pulsed", (_G.__HARNESS_KEYS or 0) > 0, tostring(_G.__HARNESS_KEYS or 0) .. " key presses")
check("proximity prompts fired", (_G.__HARNESS_PROMPTS or 0) > 0, tostring(_G.__HARNESS_PROMPTS or 0) .. " prompts")

local esp = 0
for _ in pairs(hub.esp.registry) do esp = esp + 1 end
check("ESP attached to live targets", esp > 0, esp .. " entity(ies)")
check("hitbox expander changed parts", (function()
    local count = 0
    for _, parts in pairs(hub.hitbox) do
        for _ in pairs(parts) do count = count + 1 end
    end
    return count > 0
end)())

local audit = hub.audit(true)
check("audit found the detector script", #audit.scripts >= 1, #audit.scripts .. " script(s)")
check("audit found the report remote", audit.remoteCount >= 1, audit.remoteCount .. " remote(s)")
check("detector was neutralised", #hub.state.ac.scripts >= 1, tostring(#hub.state.ac.scripts))
check("detector is disabled, not destroyed", (function()
    for _, instance in ipairs(_G.__instances) do
        if instance.Name == "AntiCheatClient" then return instance.Disabled == true end
    end
    return false
end)())
check("report hook installed", hub.ac.hookInstalled == true)

local blockedBefore = hub.state.ac.blocked
local safeBefore = _G.__HARNESS_FIRED or 0
local acRemote, questRemote
for _, instance in ipairs(_G.__instances) do
    if instance.Name == "AntiCheatReport" then acRemote = instance end
    if instance.Name == "QuestAccept" then questRemote = instance end
end
if acRemote then acRemote:FireServer("suspicious") end
check("report remote call blocked", hub.state.ac.blocked > blockedBefore,
    "blocked " .. tostring(hub.state.ac.blocked - blockedBefore))
if questRemote then questRemote:FireServer(1) end
check("gameplay remotes still pass through", (_G.__HARNESS_FIRED or 0) > safeBefore,
    tostring((_G.__HARNESS_FIRED or 0) - safeBefore) .. " allowed")

check("kick guard installed", hub.state.ac.kickGuard == true)
if hub.state.ac.kickGuard then
    local kickOk = pcall(function() _G.game:GetService("Players").LocalPlayer:Kick("test") end)
    check("a kick no longer reaches the client", kickOk and (_G.__HARNESS_KICKS or 0) == 0)
end
check("teleport target list built", (function()
    local targets = hub.scan(true)
    return #targets.mobs > 0 and #targets.prompts > 0
end)(), "mobs + prompts discovered")

local selfResults = hub.selfTest()
local passed = 0
for _, entry in ipairs(selfResults) do if entry.ok then passed = passed + 1 end end
check("hub self-test", passed == #selfResults, passed .. "/" .. #selfResults)

hub.panic("harness")
check("panic switched every toggle off", (function()
    for _, tab in ipairs(hub.tabs) do
        for _, api in ipairs(tab.toggles or {}) do
            if api.Get() then return false end
        end
    end
    return true
end)())
hub.unload()
local leftovers = false
for _, child in ipairs(_G.gethui():GetChildren()) do
    if child.Name == "SkillHubSlayers2" or child.Name == "SkillHubEsp" or child.Name == "SkillHubTracers" then
        leftovers = true
    end
end
check("unload removed the interface", not leftovers)
check("unload removed the hook", hub.ac.hookInstalled == false)
check("no errors for the whole session", #_G.__SkillHubErrorLog == 0, errors():sub(1, 300))
"""


def run(runtime, code):
    runtime.execute(code)


def main() -> int:
    if not os.path.exists(HUB):
        print("hub not found at %s" % HUB)
        return 1
    source = io.open(HUB, encoding="utf-8").read()

    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.execute(PRELUDE)

    ok = True
    try:
        # Roblox runs a script on a thread, so task.wait is legal anywhere in it
        start = runtime.eval("function(src) return task_spawn(function() return load(src, 'SkillHub.lua')() end) end")
        start(source)
    except Exception as exc:
        ok = False
        print("=== LOAD ERROR ===")
        print(str(exc)[:1600])

    if ok:
        print("LOAD OK — the whole hub executes in a mocked Roblox\n")

    run(runtime, CHECKS_BOOT)
    run(runtime, CHECKS_RUN)
    run(runtime, CHECKS_AFTER)

    results = runtime.eval("_G.__RESULTS")
    harness_errors = runtime.eval("_G.__HARNESS_ERRORS")

    failures = []
    for index in range(1, len(results) + 1):
        entry = results[index]
        label = str(entry["label"])
        passed = bool(entry["ok"])
        detail = entry["detail"]
        detail = str(detail) if detail is not None else ""
        print("%s %s%s" % ("PASS" if passed else "FAIL", label, ("  — " + detail) if detail else ""))
        if not passed:
            failures.append(label)

    if harness_errors and len(harness_errors) > 0:
        print("\nscheduler errors:")
        for index in range(1, len(harness_errors) + 1):
            print("   " + str(harness_errors[index]))

    print("\n%d/%d checks passed" % (len(results) - len(failures), len(results)))
    if failures:
        print("FAILED: " + ", ".join(failures))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
