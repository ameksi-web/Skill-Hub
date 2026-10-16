#!/usr/bin/env python3
"""Boot the Jujutsu Shenanigans hub for real in a mocked Roblox and drive it.

    /tmp/venv/bin/python tools/jjs_test.py

The mock gives the hub a virtual clock, a coroutine scheduler (so its
`while alive do … task.wait() end` loops really tick), one shared instance
metatable whose `__namecall` dispatch emulates Roblox (including
`getnamecallmethod`, so a namecall filter can be exercised for real), real
Vector3/CFrame/Color3 maths, the services the hub touches, the executor globals
it probes, and a fake Jujutsu Shenanigans server: a cafe, a training dummy, an
enemy player, a moderator, drops, a domain, an anti-cheat LocalScript and
report remotes.

Checked: load · the nine tab pages · every toggle on then off · the live loops ·
Black Flash · block/parry · ESP · hitbox · teleports · the anti-cheat audit and
the report-remote filter · the built-in self-test · panic · unload.
"""
import io, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
HUB = os.path.join(HERE, os.pardir, "Jujutsu Shenanigans", "SkillHub.lua")

try:
    from lupa import LuaRuntime
except ImportError:
    print("this test needs lupa and a Lua runtime:")
    print("    python3 -m venv /tmp/venv && /tmp/venv/bin/pip install lupa")
    sys.exit(2)

PRELUDE = r"""
-- ═══ the bits Lua 5.5 dropped but every executor still has ═════════════════
math.atan2 = function(y, x) return math.atan(y, x) end

-- ═══ virtual clock + scheduler ═════════════════════════════════════════════
local CLOCK = { now = 0, tasks = {} }
_G.__CLOCK = CLOCK
os.clock = function() return CLOCK.now end
_G.__HARNESS_ERRORS = {}
_G.__SkillHubErrorLog = {}

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
V3.Lerp = function(a, b, t)
    return V3.new(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t)
end
V3.Dot = function(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end
_G.Vector3 = { new = V3.new, zero = V3.new(0, 0, 0) }
_G.Vector2 = { new = function(x, y)
    return setmetatable({ X = x or 0, Y = y or 0 }, { __index = function(t, k)
        if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y) end end })
end }
_G.Color3 = {
    fromRGB = function(r, g, b)
        local color = { R = r, G = g, B = b }
        function color:Lerp(other, amount)
            return _G.Color3.fromRGB(r + (other.R - r) * amount, g + (other.G - g) * amount, b + (other.B - b) * amount)
        end
        return color
    end,
    fromHSV = function(h, s, v) return _G.Color3.fromRGB(h * 255, s * 255, v * 255) end,
}
_G.NumberRange = { new = function(a, b) return { Min = a, Max = b or a } end }
_G.NumberSequence = { new = function(a, b) return { First = a, Last = b or a } end }
_G.ColorSequence = { new = function(a) return { First = a } end }
_G.UDim = { new = function(scale, offset) return { Scale = scale, Offset = offset or 0 } end }
_G.UDim2 = { new = function(xs, xo, ys, yo)
    return { X = { Scale = xs, Offset = xo or 0 }, Y = { Scale = ys, Offset = yo or 0 } }
end }
_G.TweenInfo = { new = function(duration, style, direction, repeatCount, reverses, delayTime)
    return { Time = duration or 0.2, EasingStyle = style, EasingDirection = direction,
        RepeatCount = repeatCount or 0, Reverses = reverses or false, DelayTime = delayTime or 0 }
end }

local CF = {}
CF.__index = function(self, key)
    if key == "Position" then return rawget(self, "__position") end
    if key == "LookVector" then return rawget(self, "__look") end
    if key == "RightVector" then return V3.new(1, 0, 0) end
    if key == "UpVector" then return V3.new(0, 1, 0) end
    return rawget(CF, key)
end
CF.__mul = function(a, b)
    if type(b) == "table" and b.x and not rawget(b, "__position") then
        return V3.new(a.Position.x + b.x, a.Position.y + b.y, a.Position.z + b.z)
    end
    return a
end
CF.Lerp = function(self, other, amount)
    local frame = CFrame_new(self.Position:Lerp(other.Position, amount))
    local look = rawget(other, "__look")
    if look then rawset(frame, "__look", look) end
    return frame
end
CF.Angles = function(x, y, z)
    local frame = CFrame_new(V3.new(0, 0, 0))
    frame.__angles = { x, y, z }
    return frame
end
function CFrame_new(position, lookAt, z)
    if type(position) == "number" then
        position = V3.new(position, lookAt or 0, z or 0)
        lookAt = nil
    end
    local positionV = position or V3.new(0, 0, 0)
    local look = V3.new(0, 0, -1)
    if lookAt then
        local delta = lookAt - positionV
        if delta.Magnitude > 0 then look = delta.Unit end
    end
    local frame = setmetatable({}, CF)
    rawset(frame, "__position", positionV)
    rawset(frame, "__look", look)
    return frame
end
_G.CFrame = { new = CFrame_new, Angles = CF.Angles, identity = CFrame_new(), lookAt = CFrame_new }
_G.Vec3 = _G.Vector3

_G.Enum = setmetatable({}, { __index = function(_, group)
    return setmetatable({}, { __index = function(_, item)
        return setmetatable({ Name = item, Value = 0, EnumType = group },
            { __index = function() return item end })
    end })
end })

-- ═══ instances ═════════════════════════════════════════════════════════════
local INSTANCES = {}
_G.__instances = INSTANCES
local RAW_FALLBACK
local METHODS = {}
local NAMECALL_METHOD = nil
_G.getnamecallmethod = function() return NAMECALL_METHOD end

local CLASS_PARENTS = {
    Part = "BasePart", MeshPart = "BasePart", UnionOperation = "BasePart", TrussPart = "BasePart",
    WedgePart = "BasePart", CornerWedgePart = "BasePart", NegativePart = "BasePart",
    LocalScript = "BaseScript", Script = "BaseScript", ModuleScript = "LuaSourceContainer",
    TextBox = "GuiObject", TextButton = "GuiObject", TextLabel = "GuiObject", ImageLabel = "GuiObject",
    Frame = "GuiObject", ScrollingFrame = "GuiObject", CanvasGroup = "GuiObject", ImageButton = "GuiObject",
    UIStroke = "UIComponent", UICorner = "UIComponent", UIPadding = "UIComponent", UIListLayout = "UIComponent",
    ScreenGui = "LayerCollector", BillboardGui = "LayerCollector", SurfaceGui = "LayerCollector",
    RemoteEvent = "BaseRemoteEvent", UnreliableRemoteEvent = "BaseRemoteEvent", RemoteFunction = "BaseRemoteEvent",
    IntValue = "ValueBase", NumberValue = "ValueBase", StringValue = "ValueBase", BoolValue = "ValueBase",
    ObjectValue = "ValueBase", Highlight = "Instance", Folder = "Instance", Model = "Instance",
    Humanoid = "Instance", Player = "Instance", Camera = "Instance", Sound = "Instance",
    ParticleEmitter = "Instance", Attachment = "Instance", LinearVelocity = "Instance",
    SpawnLocation = "BasePart", Tool = "BackpackItem", PlayerGui = "Instance", Backpack = "Instance",
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

-- Roblox returns nil for an unknown property; only real events yield a signal.
-- Without this whitelist `model.PrimaryPart` would come back as a signal table.
local KNOWN_EVENTS = {}
for _, name in ipairs({ "Changed", "AttributeChanged", "ChildAdded", "ChildRemoved", "DescendantAdded",
    "DescendantRemoving", "Died", "CharacterAdded", "CharacterRemoving", "PlayerAdded", "PlayerRemoving",
    "InputBegan", "InputChanged", "InputEnded", "MouseEnter", "MouseLeave", "MouseButton1Click",
    "MouseButton1Down", "MouseButton1Up", "MouseWheel", "TouchTap", "Activated", "Triggered",
    "PromptButtonHoldBegan", "PromptButtonHoldEnded", "PromptTriggered", "RenderStepped", "Heartbeat",
    "Stepped", "PreRender", "PreSimulation", "PostSimulation", "JumpRequest", "StateChanged",
    "Focused", "FocusLost", "Click", "Equipped", "Unequipped", "HealthChanged", "Touched",
    "TouchEnded", "Landed", "Running", "RunningStopped", "Seated", "Climbing",
}) do KNOWN_EVENTS[name] = true end

local function signalOf(self, key, force)
    if not force and not KNOWN_EVENTS[key] and rawget(self, "__signals")[key] == nil then return nil end
    local signals = rawget(self, "__signals")
    if not signals[key] then
        local bucket = { handlers = {} }
        function bucket.Connect(_, fn)
            table.insert(bucket.handlers, fn)
            return { Disconnect = function() end, Connected = true }
        end
        bucket.Once = bucket.Connect
        bucket.Wait = function() return nil end
        bucket.Fire = function(_, ...)
            for _, fn in ipairs(bucket.handlers) do fn(...) end
        end
        signals[key] = bucket
    end
    return signals[key]
end

local function findChildOf(self, childName)
    for _, child in ipairs(rawget(self, "__children")) do
        local name = rawget(child, "__props").Name
        if name == childName then return child end
    end
    return nil
end

function METHODS.FindFirstChild(self, childName) return findChildOf(self, childName) end
function METHODS.WaitForChild(self, childName) return findChildOf(self, childName) end
function METHODS.FindFirstChildOfClass(self, wanted)
    for _, child in ipairs(rawget(self, "__children")) do
        if rawget(child, "__class") == wanted then return child end
    end
    return nil
end
function METHODS.FindFirstChildWhichIsA(self, wanted)
    for _, child in ipairs(rawget(self, "__children")) do
        if isA(child, wanted) then return child end
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
function METHODS.GetPropertyChangedSignal(self, property)
    return signalOf(self, tostring(property) .. "_changed", true)
end
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
function METHODS.GetMouse() return _G.__MOUSE end
function METHODS.EquipTool(self, tool) tool.Parent = rawget(self, "__parent") or self end
function METHODS.ChangeState(self, state) _G.__HARNESS_STATES = (_G.__HARNESS_STATES or 0) + 1 end
function METHODS.GetState() return _G.Enum.HumanoidStateType.Running end
function METHODS.SetStateEnabled() end
function METHODS.TakeDamage() end
function METHODS.Activate()
    _G.__HARNESS_ACTIVATIONS = (_G.__HARNESS_ACTIVATIONS or 0) + 1
    -- a real M1 lands on whatever is in front of the player
    if _G.__HARNESS_DAMAGE then _G.__HARNESS_DAMAGE(18) end
end
function METHODS.InputHoldBegin() end
function METHODS.InputHoldEnd() end
function METHODS.FireServer(self)
    _G.__HARNESS_FIRED = (_G.__HARNESS_FIRED or 0) + 1
    _G.__HARNESS_LAST_FIRE = rawget(self, "__props").Name
    return "fired"
end
function METHODS.InvokeServer() return nil end
function METHODS.WorldToViewportPoint(self, position)
    local origin = rawget(self, "ViewportSize") or { X = 800, Y = 600 }
    return V3.new(origin.X / 2, origin.Y / 2 - 40, 1), true
end
function METHODS.CaptureController() end
function METHODS.SendKeyEvent(_, pressed, keyCode)
    _G.__HARNESS_KEYS = (_G.__HARNESS_KEYS or 0) + 1
    local name = keyCode and (keyCode.Name or tostring(keyCode)) or "?"
    _G.__HARNESS_LAST_KEY = name
    if name == "F" then
        _G.__HARNESS_BLOCKS = (_G.__HARNESS_BLOCKS or 0) + 1
        _G.__HARNESS_BLOCK_HELD = pressed == true
    end
    if name == "Period" then _G.__HARNESS_EMOTES = (_G.__HARNESS_EMOTES or 0) + 1 end
    if pressed == true then
        _G.__KEYS_DOWN = (_G.__KEYS_DOWN or {})
        _G.__KEYS_DOWN[name] = (_G.__KEYS_DOWN[name] or 0) + 1
    end
end
function METHODS.ClickButton2() end
function METHODS.Teleport(_, placeId) _G.__HARNESS_TELEPORTS = (_G.__HARNESS_TELEPORTS or 0) + 1 end
function METHODS.TeleportToPlaceInstance() _G.__HARNESS_TELEPORTS = (_G.__HARNESS_TELEPORTS or 0) + 1 end
function METHODS.GetPlayers() return _G.__HARNESS_PLAYERS or {} end
function METHODS.GetValue() return 42 end
function METHODS.Play() end
function METHODS.Stop() end
function METHODS.ScaleTo() _G.__HARNESS_SCALED = (_G.__HARNESS_SCALED or 0) + 1 end
function METHODS.PivotTo() end
function METHODS.Emit() end
function METHODS.Kick(self, reason)
    _G.__HARNESS_KICKS = (_G.__HARNESS_KICKS or 0) + 1
    _G.__HARNESS_KICK_REASON = reason
    return reason
end
function METHODS.Button1Down(_, position)
    _G.__HARNESS_CLICKS = (_G.__HARNESS_CLICKS or 0) + 1
    if _G.__HARNESS_DAMAGE then _G.__HARNESS_DAMAGE(12) end
end
function METHODS.Button1Up() end

local function rawDispatch(self, method, ...)
    local handler = METHODS[method]
    if handler then return handler(self, ...) end
    if RAW_FALLBACK then return RAW_FALLBACK(self, method, ...) end
    return nil
end

function __RAW_NAMECALL(self, method, ...)
    local results = table.pack(rawDispatch(self, method, ...))
    return table.unpack(results, 1, results.n)
end

-- one dispatcher per method name, memoised, so `hookfunction(obj.Method, …)`
-- has a stable identity to replace — exactly how the real VM behaves
local DISPATCH = {}
local function dispatcherFor(key)
    local existing = DISPATCH[key]
    if existing then return existing end
    local dispatcher
    dispatcher = function(...)
        local args = table.pack(...)
        local target = args[1]
        if args.n > 0 and type(args[1]) == "table" and rawget(args[1], "__class") ~= nil then
            table.remove(args, 1)
            args.n = args.n - 1
        end
        NAMECALL_METHOD = key
        local namecall = rawget(INSTANCE_MT, "__namecall")
        local results
        if type(namecall) == "function" then
            results = table.pack(namecall(target, key, table.unpack(args, 1, args.n)))
        else
            results = table.pack(rawDispatch(target, key, table.unpack(args, 1, args.n)))
        end
        NAMECALL_METHOD = nil
        return table.unpack(results, 1, results.n)
    end
    DISPATCH[key] = dispatcher
    return dispatcher
end

INSTANCE_MT = {}
INSTANCE_MT.__index = function(self, key)
    local props = rawget(self, "__props")
    if key == "ClassName" then return rawget(self, "__class") end
    if key == "Name" then return props.Name end
    if key == "Parent" then return rawget(self, "__parent") end
    if props[key] ~= nil then return props[key] end
    if METHODS[key] then return dispatcherFor(key) end
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
    return tostring(rawget(self, "__class")) .. ":" .. tostring(rawget(self, "__props").Name)
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
_G.makeInstance = makeInstance

_G.Instance = { new = function(class, parent)
    local instance = makeInstance(class)
    if parent then instance.Parent = parent end
    return instance
end }

-- ═══ executor globals ══════════════════════════════════════════════════════
function _G.getgenv() return _G end
function _G.gethui() return _G.__HUI end
_G.__HUI = makeInstance("Folder", "Hui")
function _G.getrawmetatable(object) return getmetatable(object) end
function _G.setreadonly(metatable, readonly)
    _G.__READONLY = (metatable == getmetatable(_G.game))
    return true
end
function _G.newcclosure(fn) return fn end
function _G.protect_gui(gui) _G.__PROTECTED = (_G.__PROTECTED or 0) + 1 return gui end
-- a faithful hookfunction: find the method table entry that is `original` and
-- route future calls to the replacement, exactly like the real executor does
function _G.hookfunction(original, replacement)
    for name, fn in pairs(DISPATCH) do
        if fn == original then
            DISPATCH[name] = replacement
            return fn
        end
    end
    return original
end
function _G.getconnections() return {} end
function _G.keypress() _G.__HARNESS_KEYS = (_G.__HARNESS_KEYS or 0) + 1 end
function _G.mouse1click() _G.__HARNESS_CLICKS = (_G.__HARNESS_CLICKS or 0) + 1 end
function _G.fireproximityprompt() _G.__HARNESS_PROMPTS = (_G.__HARNESS_PROMPTS or 0) + 1 end
function _G.firesignal(signal)
    if type(signal) == "table" and signal.handlers then
        for _, fn in ipairs(signal.handlers) do pcall(fn) end
        return true
    end
    return false
end
function _G.setclipboard(text) _G.__CLIPBOARD = text return true end
function _G.identifyexecutor() return "Xeno", "1.0" end
function _G.queue_on_teleport() _G.__QUEUED = true end
function _G.request(options)
    _G.__LAST_REQUEST = options and options.Url or nil
    return { Body = '{"data":[{"id":"other-job-1","playing":4},{"id":"other-job-2","playing":9}]}' }
end
function _G.settings() return { Rendering = { QualityLevel = 0 } } end
function _G.writefile() return true end
function _G.readfile() return nil end

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

-- ═══ the engine surface ════════════════════════════════════════════════════
_G.game = makeInstance("DataModel", "Game")
local dataModel = _G.game
_G.workspace = makeInstance("Workspace", "Workspace")

local function humanoidModel(name, health, position, options)
    local model = makeInstance("Model", name)
    local root = makeInstance("Part", "HumanoidRootPart")
    root.Position = position
    root.CFrame = CFrame_new(position)
    root.Size = V3.new(2, 2, 1)
    root.Parent = model
    local humanoid = makeInstance("Humanoid", "Humanoid")
    humanoid.Health = health
    humanoid.MaxHealth = (options and options.maxHealth) or health
    humanoid.WalkSpeed = 16
    humanoid.Parent = model
    for _, partName in ipairs({ "Head", "Torso" }) do
        local part = makeInstance("Part", partName)
        part.Size = V3.new(2, 2, 1)
        part.Position = position + V3.new(0, 1, 0)
        part.CFrame = CFrame_new(part.Position)
        part.Parent = model
    end
    model.PrimaryPart = root
    if options and options.style then
        local style = makeInstance("StringValue", options.style)
        style.Value = options.style
        style.Parent = model
    end
    return model, humanoid
end

local function makePart(name, position, parent, class)
    local piece = makeInstance(class or "Part", name)
    piece.Size = V3.new(4, 4, 4)
    piece.Position = position
    piece.CFrame = CFrame_new(position)
    piece.Parent = parent or _G.workspace
    return piece
end

-- the map
do
    local cafe = makeInstance("Model", "Cafe")
    makePart("Floor", V3.new(0, 0, 0), cafe)
    cafe.Parent = _G.workspace
    local grounds = makeInstance("Model", "Training Grounds")
    local dummy, dummyHumanoid = humanoidModel("PracticeDummy", 100, V3.new(8, 3, 8), { maxHealth = 100 })
    dummy.Parent = grounds
    local guard, _ = humanoidModel("GuardDummy", 250, V3.new(-14, 3, 6), { maxHealth = 250 })
    guard.Parent = grounds
    grounds.Parent = _G.workspace
    local city = makeInstance("Model", "City")
    makePart("Road", V3.new(120, 0, 0), city)
    city.Parent = _G.workspace
    local shrine = makeInstance("Model", "Shrine")
    makePart("Gate", V3.new(-140, 0, 40), shrine)
    shrine.Parent = _G.workspace
    local domain = makeInstance("Model", "Unlimited Void")
    makePart("Barrier", V3.new(60, 10, 60), domain)
    domain.Parent = _G.workspace
    makePart("CashDrop", V3.new(18, 3, 6), _G.workspace)
    makePart("RewardCase", V3.new(24, 3, 10), _G.workspace)
end

local replicated = makeInstance("ReplicatedStorage", "ReplicatedStorage")
local antiCheatFolder = makeInstance("Folder", "AntiCheatClient")
antiCheatFolder.Parent = replicated
do
    local detector = makeInstance("LocalScript", "AntiCheatClient")
    detector.Disabled = false
    detector.Parent = replicated
    local monitor = makeInstance("LocalScript", "PositionMonitor")
    monitor.Disabled = false
    monitor.Parent = antiCheatFolder
    local module = makeInstance("ModuleScript", "IntegrityChecker")
    module.Parent = antiCheatFolder
end
do
    local report = makeInstance("RemoteEvent", "AntiCheatReport")
    report.Parent = replicated
    local reportPlayer = makeInstance("RemoteFunction", "ReportPlayer")
    reportPlayer.Parent = replicated
    local ban = makeInstance("RemoteEvent", "BanPlayer")
    ban.Parent = replicated
    for _, name in ipairs({ "M1", "SkillUse", "Block", "Dash", "Roulette", "Emote" }) do
        local safe = makeInstance("RemoteEvent", name)
        safe.Parent = replicated
    end
end
do
    local chat = makeInstance("Folder", "DefaultChatSystemChatEvents")
    chat.Parent = replicated
    local say = makeInstance("RemoteEvent", "SayMessageRequest")
    say.Parent = chat
    say.FireServer = function(_, message) _G.__HARNESS_CHAT = (_G.__HARNESS_CHAT or 0) + 1
        _G.__HARNESS_CHAT_LAST = message end
end

local players = makeInstance("Players", "Players")
local localPlayer = makeInstance("Player", "TestPlayer")
localPlayer.UserId = 1
localPlayer.DisplayName = "TestPlayer"
local character, localHumanoid = humanoidModel("TestCharacter", 100, V3.new(0, 3, 0), { style = "Vessel" })
character.Parent = _G.workspace
local awakeningFlag = makeInstance("BoolValue", "Awakening")
awakeningFlag.Value = false
awakeningFlag.Parent = character
localPlayer.Character = character
local backpack = makeInstance("Backpack", "Backpack")
backpack.Parent = localPlayer
do
    local fists = makeInstance("Tool", "Cursed Fists")
    local handle = makeInstance("Part", "Handle")
    handle.Parent = fists
    fists.Parent = backpack
    local katana = makeInstance("Tool", "Slaughter Demon")
    makeInstance("Part", "Handle").Parent = katana
    katana.Parent = backpack
end
do
    local enemy = makeInstance("Player", "SomeoneElse")
    enemy.UserId = 2
    enemy.DisplayName = "SomeoneElse"
    local enemyCharacter = humanoidModel("SomeoneElseCharacter", 100, V3.new(22, 3, 18), { style = "Honored One" })
    enemyCharacter.Parent = _G.workspace
    enemy.Character = enemyCharacter
    local moderator = makeInstance("Player", "Mod_Tze")
    moderator.UserId = 3
    moderator.DisplayName = "Mod Tze"
    local modCharacter = humanoidModel("ModTzeCharacter", 100, V3.new(60, 3, 60), {})
    modCharacter.Parent = _G.workspace
    moderator.Character = modCharacter
    _G.__HARNESS_PLAYERS = { localPlayer, enemy, moderator }
end
local playerGui = makeInstance("PlayerGui", "PlayerGui")
playerGui.Parent = localPlayer
do
    local respawn = makeInstance("TextButton", "RespawnButton")
    respawn.Visible = true
    respawn.Text = "Respawn"
    respawn.Parent = playerGui
    respawn.MouseButton1Click:Connect(function()
        _G.__HARNESS_RESPAWNS = (_G.__HARNESS_RESPAWNS or 0) + 1
    end)
    local queue = makeInstance("TextButton", "QueueButton")
    queue.Visible = true
    queue.Text = "Queue"
    queue.Parent = playerGui
    queue.MouseButton1Click:Connect(function()
        _G.__HARNESS_QUEUED = (_G.__HARNESS_QUEUED or 0) + 1
    end)
    local lobby = makeInstance("Frame", "Lobby")
    lobby.Parent = playerGui
    local matchButton = makeInstance("TextButton", "PlayButton")
    matchButton.Visible = true
    matchButton.Text = "Join match"
    matchButton.Parent = lobby
end
local playerScripts = makeInstance("PlayerScripts", "PlayerScripts")
playerScripts.Parent = localPlayer
players.LocalPlayer = localPlayer
players.GetPlayers = function() return _G.__HARNESS_PLAYERS end
players.CharacterAdded = signalOf(players, "CharacterAdded")

local camera = makeInstance("Camera", "Camera")
camera.ViewportSize = { X = 800, Y = 600 }
camera.CFrame = CFrame_new(V3.new(0, 8, -14))
camera.FieldOfView = 70
_G.workspace.CurrentCamera = camera
_G.__CAMERA_START = camera.CFrame

local mouse = makeInstance("Mouse", "Mouse")
mouse.Hit = CFrame_new(V3.new(6, 3, 6))
_G.__MOUSE = mouse
localPlayer.GetMouse = mouse

-- a landed hit takes health off the closest other character; when it drops to
-- zero the hub's kill counter, auto-GG and kill emote all have something to see
_G.__HARNESS_DAMAGE = function(amount)
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local best, bestDistance = nil, math.huge
    for _, other in ipairs(_G.__HARNESS_PLAYERS) do
        if other ~= localPlayer and other.Character then
            local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = other.Character:FindFirstChildOfClass("Humanoid")
            if otherRoot and humanoid and (humanoid.Health or 0) > 0 then
                local distance = (root.Position - otherRoot.Position).Magnitude
                if distance < bestDistance then best, bestDistance = other.Character, distance end
            end
        end
    end
    for _, dummy in ipairs(_G.__instances) do
        if dummy.ClassName == "Model" and dummy.Name == "PracticeDummy" then
            local humanoid = dummy:FindFirstChildOfClass("Humanoid")
            local dummyRoot = dummy:FindFirstChild("HumanoidRootPart")
            if humanoid and dummyRoot and (humanoid.Health or 0) > 0 then
                local distance = (root.Position - dummyRoot.Position).Magnitude
                if distance < bestDistance then best, bestDistance = dummy, distance end
            end
        end
    end
    if best then
        local humanoid = best:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = math.max(0, (humanoid.Health or 0) - amount)
            _G.__HARNESS_DAMAGE_DEALT = (_G.__HARNESS_DAMAGE_DEALT or 0) + amount
        end
    end
end

local services = {
    Players = players, Workspace = _G.workspace, Lighting = makeInstance("Lighting", "Lighting"),
    CoreGui = makeInstance("CoreGui", "CoreGui"), ReplicatedStorage = replicated,
    ReplicatedFirst = makeInstance("ReplicatedFirst", "ReplicatedFirst"),
    TweenService = makeInstance("TweenService", "TweenService"),
    RunService = makeInstance("RunService", "RunService"),
    UserInputService = makeInstance("UserInputService", "UserInputService"),
    CollectionService = makeInstance("CollectionService", "CollectionService"),
    SoundService = makeInstance("SoundService", "SoundService"),
    VirtualUser = makeInstance("VirtualUser", "VirtualUser"),
    VirtualInputManager = makeInstance("VirtualInputManager", "VirtualInputManager"),
    TeleportService = makeInstance("TeleportService", "TeleportService"),
    Stats = makeInstance("Stats", "Stats"),
}
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

_G.__STEPPED = function(step)
    local function fire(bucket)
        if not bucket then return end
        for _, fn in ipairs(bucket.handlers) do
            local ok, err = pcall(fn, step)
            if not ok then table.insert(_G.__HARNESS_ERRORS, "frame: " .. tostring(err)) end
        end
    end
    fire(rawget(services.RunService, "__signals").RenderStepped)
    fire(rawget(services.RunService, "__signals").Heartbeat)
    fire(rawget(services.RunService, "__signals").PreRender)
end

dataModel.GetService = function(_, name) return services[name] or makeInstance(name, name) end
dataModel.PlaceId = 5300000000
dataModel.JobId = "jjs-job-test"
dataModel.HttpGet = function() return '{"data":[]}' end
dataModel.CoreGui = services.CoreGui

-- fire the frame signals once so connected loops are registered before the run
for index = 1, 3 do pump(0.03) end
"""

CHECKS_BOOT = r"""
_G.__RESULTS = {}
local hub = _G.SkillHubJujutsu
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end

check("hub exported to getgenv", hub ~= nil)
check("version", hub ~= nil and hub.version == "v1.0", hub and tostring(hub.version))

local gui = nil
for _, child in ipairs(_G.gethui():GetChildren()) do
    if child.Name == "SkillHubJujutsu" then gui = child end
end
check("window created in the hidden gui", gui ~= nil)
check("window chrome built", gui ~= nil and #gui:GetDescendants() > 60,
    gui and (#gui:GetDescendants() .. " instances"))

check("nine tabs", hub ~= nil and #hub.tabs == 9, hub and tostring(#hub.tabs))
local switched, content = 0, 0
for _, tab in ipairs(hub.tabs) do
    if pcall(tab.Select) then switched = switched + 1 end
    if #tab.page:GetChildren() > 1 then content = content + 1 end
end
check("every tab selects", switched == 9, switched .. "/9")
check("every tab has components", content == 9, content .. "/9")

local toggles = 0
for _, tab in ipairs(hub.tabs) do
    for _, api in ipairs(tab.toggles or {}) do
        toggles = toggles + 1
        api.Set(true, false)                 -- with the callback, exactly like a click
    end
end
check("toggles built and switched on", toggles >= 80, toggles .. " toggles")
"""

CHECKS_RUN = r"""
-- 22 virtual seconds: the loops tick, the UI paints, the anti-cheat layer runs
for index = 1, 88 do pump(0.25) end
"""

CHECKS_AFTER = r"""
local hub = _G.SkillHubJujutsu
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end
local function errors()
    return table.concat(_G.__SkillHubErrorLog, " | ")
end

check("no errors while every feature ran", #_G.__SkillHubErrorLog == 0, errors():sub(1, 400))
check("tool activations happened", (_G.__HARNESS_ACTIVATIONS or 0) > 0,
    tostring(_G.__HARNESS_ACTIVATIONS or 0) .. " activations")
check("skill keys pulsed", (_G.__HARNESS_KEYS or 0) > 0, tostring(_G.__HARNESS_KEYS or 0) .. " key events")
check("block key was used", (_G.__HARNESS_BLOCKS or 0) > 0, tostring(_G.__HARNESS_BLOCKS or 0) .. " F events")
check("black flash attempts fired", hub.state.blackFlashes > 0, tostring(hub.state.blackFlashes) .. " attempts")
check("emote wheel was opened", (_G.__HARNESS_EMOTES or 0) > 0, tostring(_G.__HARNESS_EMOTES or 0) .. " emote keys")
check("chat message was sent", (_G.__HARNESS_CHAT or 0) > 0, tostring(_G.__HARNESS_CHAT_LAST))
check("auto queue clicked the game's button", (_G.__HARNESS_QUEUED or 0) > 0,
    tostring(_G.__HARNESS_QUEUED or 0) .. " click(s)")
check("every configured key was pressed", (function()
    local wanted = { ["One"] = true, ["Two"] = true, ["Three"] = true, ["Four"] = true, ["R"] = true, ["Q"] = true, ["G"] = true }
    for name in pairs(wanted) do
        if not (_G.__KEYS_DOWN and _G.__KEYS_DOWN[name]) then return false, name end
    end
    return true
end)())

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
check("lock-on turned the camera onto a target", (function()
    local camera = _G.workspace.CurrentCamera
    local look = rawget(camera.CFrame, "__look")
    if not look then return false end
    local target = _G.SkillHubJujutsu.world_helpers.nearest(90)
    if not target then return false end
    local root = game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local toTarget = (target.position - root.Position).Unit
    return look:Dot(toTarget) > 0.5
end)())
check("target scan sees the server", (function()
    local world = hub.scan(true)
    return #world.players >= 2 and #world.dummies >= 2 and #world.zones >= 3
end)(), "players + dummies + zones")

check("the style was read from the character", hub.state.style == "Vessel", tostring(hub.state.style))

-- a user would press these two buttons, so the suite presses them too
hub.playEmote(2)
hub.chatSay("gg")
for index = 1, 4 do pump(0.25) end
check("emote wheel opened through the hub", (_G.__HARNESS_EMOTES or 0) > 0, tostring(_G.__HARNESS_EMOTES or 0) .. " emote keys")
check("chat line went out", (_G.__HARNESS_CHAT or 0) > 0, tostring(_G.__HARNESS_CHAT_LAST))

local teleportTargets = hub.teleportTargets()
check("teleport target list built", #teleportTargets >= 4, #teleportTargets .. " destinations")

local audit = hub.audit(true)
check("audit found the detector scripts", audit.scripts >= 3, tostring(audit.scripts) .. " script(s)")
check("audit found the report remotes", audit.reports >= 3, tostring(audit.reports) .. " report remote(s)")
check("detector was neutralised", audit.detectors >= 2 and audit.disabled > 0,
    audit.detectors .. " detector(s), " .. audit.disabled .. " disabled")
check("detectors are disabled, not destroyed", (function()
    for _, instance in ipairs(_G.__instances) do
        if instance.Name == "AntiCheatClient" and instance.ClassName == "LocalScript" then
            return instance.Disabled == true and instance.Parent ~= nil
        end
    end
    return false
end)())
check("report hook installed", hub.ac.hookInstalled == true)

local blockedBefore = hub.ac.blocked
local safeBefore = _G.__HARNESS_FIRED or 0
local reportRemote, reportFunction, banRemote, safeRemote
for _, instance in ipairs(_G.__instances) do
    if instance.Name == "AntiCheatReport" then reportRemote = instance end
    if instance.Name == "ReportPlayer" then reportFunction = instance end
    if instance.Name == "BanPlayer" then banRemote = instance end
    if instance.Name == "M1" then safeRemote = instance end
end
if reportRemote then reportRemote:FireServer("suspicious") end
if banRemote then banRemote:FireServer(LocalPlayer) end
check("report and ban remotes were blocked", hub.ac.blocked - blockedBefore >= 2,
    tostring(hub.ac.blocked - blockedBefore) .. " call(s) dropped")
check("the blocked remotefunction never ran", (function()
    if reportFunction then reportFunction:InvokeServer("evidence") end
    return hub.ac.blocked - blockedBefore >= 3
end)())
if safeRemote then safeRemote:FireServer(1) end
check("gameplay remotes still pass through", (_G.__HARNESS_FIRED or 0) > safeBefore,
    tostring((_G.__HARNESS_FIRED or 0) - safeBefore) .. " allowed")

check("kick guard installed", hub.ac.kickGuard == true)
local kickOk, kickError = pcall(function() game:GetService("Players").LocalPlayer:Kick("test") end)
check("a kick never reaches the client", kickOk and (_G.__HARNESS_KICKS or 0) == 0,
    tostring(_G.__HARNESS_KICKS or 0) .. " kicks · " .. tostring(kickError))
check("staff watch spotted the moderator", hub.ac.staffWarned ~= nil and
    (function()
        for _ in pairs(hub.ac.staffWarned) do return true end
        return false
    end)())
check("safe mode clamped the speed writes", (function()
    if not hub.config.AcSafeMode then return true end
    return hub.config.WalkSpeed <= hub.config.AcSpeedCeiling
end)())

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
    if child.Name == "SkillHubJujutsu" or child.Name == "SkillHubEsp" or child.Name == "SkillHubTracers" then
        leftovers = true
    end
end
check("unload removed the interface", not leftovers)
check("unload removed the hook", hub.ac.hookInstalled == false)
check("no errors for the whole session", #_G.__SkillHubErrorLog == 0, errors():sub(1, 400))
"""


def main() -> int:
    if not os.path.exists(HUB):
        print("hub not found at %s" % HUB)
        return 1
    source = io.open(HUB, encoding="utf-8").read()

    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.execute(PRELUDE)

    loader = runtime.eval("function(src) return task_spawn(function() return load(src, 'SkillHub.lua')() end) end")
    loader(source)

    runtime.execute(CHECKS_BOOT)
    runtime.execute(CHECKS_RUN)
    runtime.execute(CHECKS_AFTER)

    results = runtime.eval("_G.__RESULTS")
    scheduler_errors = [str(x) for x in runtime.eval("_G.__HARNESS_ERRORS").values()]
    failures = []
    for entry in results.values():
        label = str(entry["label"])
        ok = entry["ok"] is True or entry["ok"] == True
        detail = entry["detail"]
        detail = "" if detail is None else "  — " + str(detail)
        print(("PASS " if ok else "FAIL ") + label + detail)
        if not ok:
            failures.append(label)

    print()
    if scheduler_errors:
        print("scheduler errors:")
        for line in scheduler_errors[:12]:
            print("   " + line)
        print()
    total = len(list(results.values()))
    print("%d/%d checks passed" % (total - len(failures), total))
    if failures:
        print("FAILED: " + ", ".join(failures))
        return 1
    print("LOAD OK — the whole hub runs in a mocked Roblox")
    return 0


if __name__ == "__main__":
    sys.exit(main())
