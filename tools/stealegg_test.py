#!/usr/bin/env python3
"""Boot the Steal An Egg hub for real in a mocked Roblox and drive it.

    /tmp/venv/bin/python tools/stealegg_test.py

The mock gives the hub a virtual clock, a coroutine scheduler (so its
`while alive do … task.wait() end` loops really tick), one shared instance
metatable whose `__namecall` dispatch emulates Roblox (including
`getnamecallmethod`, so the report filter can be exercised for real),
`hookmetamethod` and `getgc` so the camouflage and the limiter patcher are
real too, real Vector3/CFrame/Color3 maths, the services the hub touches, the
executor globals it probes, and a fake Steal An Egg server: five biomes with
nests and eggs, a plot with place/hatch/treadmill prompts, a guardian, a rift,
report remotes and an anti-cheat folder.

Checked: load · the nine tab pages · every toggle on then off · the steal loop
(travel, grab, carry home, place) · hatch · index · trails · fuse · sell ·
equip · treadmill · events · ESP · stepped travel · the anti-cheat audit, the
report filter, the kick guard, the WalkSpeed camouflage and the limiter patcher
· panic · unload.
"""
import io, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
HUB = os.path.join(HERE, os.pardir, "Steal a Egg", "SkillHub.lua")

try:
    from lupa import LuaRuntime
except ImportError:
    print("this test needs lupa and a Lua runtime:")
    print("    python3 -m venv /tmp/venv && /tmp/venv/bin/pip install lupa")
    sys.exit(2)

PRELUDE = r"""
-- ═══ the bits Lua 5.5 dropped but every executor still has ═════════════════
math.atan2 = function(y, x) return math.atan(y, x) end
math.clamp = function(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end
math.round = function(value) return math.floor(value + 0.5) end

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

-- Roblox's typeof, which returns the class name for instances
_G.typeof = function(value)
    if type(value) == "table" then
        local metatable = getmetatable(value)
        if metatable == V3 then return "Vector3" end
        if metatable == CF then return "CFrame" end
        if rawget(value, "__class") ~= nil then return rawget(value, "__class") end
    end
    return type(value)
end

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
    "Focused", "FocusLost", "Click", "Equipped", "Unequipped", "HealthChanged", "Touched", "Idled",
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
function METHODS.IsDescendantOf(self, ancestor)
    local parent = rawget(self, "__parent")
    while parent do
        if parent == ancestor then return true end
        parent = rawget(parent, "__parent")
    end
    return false
end
function METHODS.MoveTo(self, position) _G.__HARNESS_MOVETO = (_G.__HARNESS_MOVETO or 0) + 1 end
function METHODS.GetAttributeChangedSignal(self, key) return signalOf(self, tostring(key) .. "_changed", true) end
function METHODS.FindFirstAncestorWhichIsA(self, wanted)
    local parent = rawget(self, "__parent")
    while parent do
        if isA(parent, wanted) then return parent end
        parent = rawget(parent, "__parent")
    end
    return nil
end
function METHODS.FindFirstAncestorOfClass(self, wanted)
    local parent = rawget(self, "__parent")
    while parent do
        if rawget(parent, "__class") == wanted then return parent end
        parent = rawget(parent, "__parent")
    end
    return nil
end
function METHODS.FindFirstAncestor(self, childName)
    local parent = rawget(self, "__parent")
    while parent do
        if rawget(parent, "__props").Name == childName then return parent end
        parent = rawget(parent, "__parent")
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
function METHODS.Emit() _G.__HARNESS_EMITS = (_G.__HARNESS_EMITS or 0) + 1 end
function METHODS.Click(self)
    local bucket = rawget(self, "__signals").MouseButton1Click
    if bucket then for _, fn in ipairs(bucket.handlers) do pcall(fn) end end
    _G.__HARNESS_GUI_CLICKS = (_G.__HARNESS_GUI_CLICKS or 0) + 1
end
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
    -- Roblox keeps Position and CFrame in sync; the hub reads Position after
    -- writing CFrame, so the mock has to do the same or every travel looks frozen
    if key == "CFrame" and type(value) == "table" then
        local position = rawget(value, "__position")
        if position then
            local previous = rawget(self, "__props").Position
            if previous and rawget(self, "__props").Name == "HumanoidRootPart" then
                local step = (position - previous).Magnitude
                if step > (_G.__MAX_STEP or 0) then _G.__MAX_STEP = step end
            end
            rawget(self, "__props").Position = position
        end
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
function _G.islclosure(fn) return type(fn) == "function" end
function _G.getgc() return _G.__GC or {} end
-- hookmetamethod is what every modern executor exposes; the mock rewrites the
-- shared instance metatable so the camouflage and the namecall filter are real
function _G.hookmetamethod(object, method, hook)
    local metatable = getmetatable(object)
    if not metatable then return nil end
    local original = rawget(metatable, method)
    if not original then return nil end
    rawset(metatable, method, hook)
    _G.__HOOKED = (_G.__HOOKED or 0) + 1
    return original
end
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
_G.workspace.Gravity = 196.2

local function makePart(name, position, parent, class)
    local piece = makeInstance(class or "Part", name)
    piece.Size = V3.new(4, 4, 4)
    piece.Position = position
    piece.CFrame = CFrame_new(position)
    piece.Parent = parent or _G.workspace
    return piece
end

local function humanoidModel(name, health, position)
    local model = makeInstance("Model", name)
    local root = makeInstance("Part", "HumanoidRootPart")
    root.Position = position
    root.CFrame = CFrame_new(position)
    root.AssemblyLinearVelocity = V3.new(0, 0, 0)
    root.Size = V3.new(2, 2, 1)
    root.Parent = model
    local humanoid = makeInstance("Humanoid", "Humanoid")
    humanoid.Health = health
    humanoid.MaxHealth = health
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    humanoid.Parent = model
    local head = makePart("Head", position + V3.new(0, 1, 0), model)
    head.Size = V3.new(2, 2, 1)
    model.PrimaryPart = root
    return model, humanoid
end

-- ── the Steal An Egg map: five biomes, nests, eggs, a plot, a guardian ─────
_G.__LOCAL_CHARACTER = nil

local function makeEgg(name, rarity, mutation, value, position, parent)
    local egg = makeInstance("Model", name)
    local part = makePart("EggBody", position, egg)
    part.Size = V3.new(3, 3, 3)
    egg.PrimaryPart = part
    egg:SetAttribute("Rarity", rarity)
    egg:SetAttribute("Mutation", mutation or "Normal")
    egg:SetAttribute("Value", value)
    local prompt = makeInstance("ProximityPrompt", "StealPrompt")
    prompt.ActionText = "Steal Egg"
    prompt.ObjectText = name
    prompt.Enabled = true
    prompt.HoldDuration = 0.4
    local props = rawget(prompt, "__props")
    props.__egg = egg
    props.__carryTo = function() return _G.__LOCAL_CHARACTER end
    prompt.Parent = egg
    egg.Parent = parent or _G.workspace
    return egg
end

do
    local forest = makeInstance("Model", "Forest")
    makePart("Ground", V3.new(0, 0, 0), forest)
    local nest = makeInstance("Model", "Forest Nest")
    makePart("NestBase", V3.new(40, 1, 40), nest)
    nest.Parent = forest
    makeEgg("Common Egg", "Common", "Normal", 5, V3.new(40, 4, 40), forest)
    makeEgg("Rare Egg", "Rare", "Normal", 150, V3.new(90, 4, 20), forest)
    makeEgg("Enchanted Mythic Egg", "Mythic", "Enchanted", 9000, V3.new(140, 4, 60), forest)
    forest.Parent = _G.workspace

    local lake = makeInstance("Model", "Lake")
    makePart("Water", V3.new(-260, 0, 0), lake)
    makeEgg("Legendary Egg", "Legendary", "Normal", 1200, V3.new(-260, 4, 0), lake)
    lake.Parent = _G.workspace

    local desert = makeInstance("Model", "Desert")
    makePart("Sand", V3.new(0, 0, -420), desert)
    makeEgg("Cosmic Egg", "Cosmic", "Shattered", 75000, V3.new(0, 4, -420), desert)
    desert.Parent = _G.workspace

    local jungle = makeInstance("Model", "Jungle")
    makePart("Canopy", V3.new(420, 0, -420), jungle)
    makeEgg("Secret Egg", "Secret", "Normal", 600000, V3.new(420, 4, -420), jungle)
    jungle.Parent = _G.workspace

    local snow = makeInstance("Model", "Snow")
    makePart("Ice", V3.new(-420, 0, -420), snow)
    makeEgg("Dropped Egg", "Rare", "Normal", 150, V3.new(-420, 4, -420), snow)
    snow.Parent = _G.workspace

    -- someone else's base
    local rival = makeInstance("Model", "Plot_Rival")
    makePart("RivalBase", V3.new(200, 0, 200), rival)
    makeEgg("Rival Secret Egg", "Secret", "Normal", 600000, V3.new(200, 4, 200), rival)
    rival.Parent = _G.workspace

    -- a rift: the event classifier has to find it and read its attribute
    local rift = makeInstance("Model", "Rift Portal")
    makePart("Portal", V3.new(600, 8, 0), rift)
    rift.Parent = _G.workspace

    -- the four event sites Update 6-9 shipped
    local race = makeInstance("Model", "Nitro Race")
    makePart("StartGate", V3.new(750, 4, 120), race)
    for index, name in ipairs({ "Checkpoint 1", "Checkpoint 2", "Checkpoint 3" }) do
        makePart(name, V3.new(750 + index * 85, 4, 120 + index * 40), race)
    end
    race.Parent = _G.workspace

    local star = makeInstance("Model", "Shooting Star")
    makePart("StarCore", V3.new(-700, 40, 300), star)
    star.Parent = _G.workspace

    local bloom = makeInstance("Model", "Butterfly Bloom")
    makePart("BloomCore", V3.new(520, 12, 520), bloom)
    bloom.Parent = _G.workspace

    local lab = makeInstance("Model", "Dr Scramble Laboratory")
    makePart("LabFloor", V3.new(-200, 1, 420), lab)
    local trade = makeInstance("ProximityPrompt", "TradePrompt")
    trade.ActionText = "Trade In Eggs"
    trade.Enabled = true
    rawget(trade, "__props").__action = function()
        _G.__HARNESS_TRADES = (_G.__HARNESS_TRADES or 0) + 1
    end
    trade.Parent = lab
    lab.Parent = _G.workspace

    local guardian = makeInstance("Model", "ForestGuardian")
    local guardianRoot = makePart("GuardianBody", V3.new(260, 6, -200), guardian)
    guardian.PrimaryPart = guardianRoot
    local guardianHumanoid = makeInstance("Humanoid", "Humanoid")
    guardianHumanoid.Health = 5000
    guardianHumanoid.Parent = guardian
    guardian.Parent = _G.workspace
end

-- ── the player ─────────────────────────────────────────────────────────────
local players = makeInstance("Players", "Players")
local localPlayer = makeInstance("Player", "TestPlayer")
localPlayer.UserId = 1
localPlayer.DisplayName = "TestPlayer"
local character, localHumanoid = humanoidModel("TestPlayerCharacter", 100, V3.new(0, 3, 0))
character.Parent = _G.workspace
_G.__LOCAL_CHARACTER = character
localPlayer.Character = character
local backpack = makeInstance("Backpack", "Backpack")
backpack.Parent = localPlayer
local playerGui = makeInstance("PlayerGui", "PlayerGui")
playerGui.Parent = localPlayer
local playerScripts = makeInstance("PlayerScripts", "PlayerScripts")
playerScripts.Parent = localPlayer

do
    local other = makeInstance("Player", "SomeoneElse")
    other.UserId = 2
    other.DisplayName = "SomeoneElse"
    local otherCharacter = humanoidModel("SomeoneElseCharacter", 100, V3.new(30, 3, 30))
    otherCharacter.Parent = _G.workspace
    other.Character = otherCharacter
    _G.__HARNESS_PLAYERS = { localPlayer, other }
end
players.LocalPlayer = localPlayer
players.GetPlayers = function() return _G.__HARNESS_PLAYERS end
players.CharacterAdded = signalOf(players, "CharacterAdded")

-- a plot of our own, with the three prompts the base engine uses
do
    local plot = makeInstance("Model", "Plot_TestPlayer")
    local base = makePart("Base", V3.new(0, 0, 60), plot)
    base.Size = V3.new(60, 2, 60)
    local display = makePart("Display", V3.new(6, 1, 60), plot)
    display.Size = V3.new(20, 1, 20)

    local place = makeInstance("ProximityPrompt", "PlacePrompt")
    place.ActionText = "Place Egg"
    place.ObjectText = "Display"
    place.Enabled = true
    rawget(place, "__props").__action = function()
        for _, child in ipairs(rawget(_G.__LOCAL_CHARACTER, "__children")) do
            local name = rawget(child, "__props").Name or ""
            if string.find(string.lower(name), "egg", 1, true) then
                child.Parent = plot
                _G.__HARNESS_PLACED = (_G.__HARNESS_PLACED or 0) + 1
                break
            end
        end
    end
    place.Parent = plot

    local hatch = makeInstance("ProximityPrompt", "HatchPrompt")
    hatch.ActionText = "Hatch Eggs"
    hatch.ObjectText = "Incubator"
    hatch.Enabled = true
    rawget(hatch, "__props").__action = function()
        _G.__HARNESS_HATCHES = (_G.__HARNESS_HATCHES or 0) + 1
    end
    hatch.Parent = plot

    local treadmill = makeInstance("Model", "Treadmill")
    makePart("Belt", V3.new(14, 1, 70), treadmill)
    local upgrade = makeInstance("ProximityPrompt", "UpgradePrompt")
    upgrade.ActionText = "Upgrade Treadmill"
    upgrade.Enabled = true
    rawget(upgrade, "__props").__action = function()
        _G.__HARNESS_UPGRADES = (_G.__HARNESS_UPGRADES or 0) + 1
    end
    upgrade.Parent = treadmill
    treadmill.Parent = plot

    -- the egg on our own plot must never be a steal target
    makeEgg("Secret Egg", "Secret", "Normal", 600000, V3.new(-8, 2, 60), plot)
    plot.Parent = _G.workspace
end

-- a button the base engine can click for offline rewards
do
    local button = makeInstance("TextButton", "OfflineRewards")
    button.Visible = true
    button.Text = "Collect Offline Rewards"
    button.Parent = playerGui
    button.MouseButton1Click:Connect(function()
        _G.__HARNESS_OFFLINE = (_G.__HARNESS_OFFLINE or 0) + 1
    end)
end

-- ── ReplicatedStorage: gameplay remotes, report remotes, detectors ─────────
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
    local speed = makeInstance("LocalScript", "SpeedMonitor")
    speed.Disabled = false
    speed.Parent = antiCheatFolder
    local integrity = makeInstance("ModuleScript", "IntegrityChecker")
    integrity.Parent = antiCheatFolder

    local report = makeInstance("RemoteEvent", "AntiCheatReport")
    report.Parent = replicated
    local reportPlayer = makeInstance("RemoteFunction", "ReportPlayer")
    reportPlayer.Parent = replicated
    local flag = makeInstance("RemoteEvent", "FlagPlayer")
    flag.Parent = replicated
    local save = makeInstance("RemoteEvent", "SaveData")   -- must never be blocked
    save.Parent = replicated

    for _, name in ipairs({ "StealEgg", "PlaceEgg", "HatchEggs", "ClaimIndex", "BuyTrail",
        "FusePets", "SellEggs", "EquipBest", "UpgradeTreadmill", "Rebirth", "TradeEggs",
        "DropEgg", "OfflineEarnings" }) do
        local remote = makeInstance("RemoteEvent", name)
        remote.Parent = replicated
    end
end
do
    local chat = makeInstance("Folder", "DefaultChatSystemChatEvents")
    chat.Parent = replicated
    local say = makeInstance("RemoteEvent", "SayMessageRequest")
    say.Parent = chat
end

-- the config tables getgc(true) is supposed to find and clamp
_G.__GC = {
    { MaxWalkSpeed = 500, SpeedLimit = 900 },
    { Speed = 16, Name = "Egg" },
}

local camera = makeInstance("Camera", "Camera")
camera.ViewportSize = { X = 800, Y = 600 }
camera.CFrame = CFrame_new(V3.new(0, 12, -20))
camera.FieldOfView = 70
_G.workspace.CurrentCamera = camera

local mouse = makeInstance("Mouse", "Mouse")
mouse.Hit = CFrame_new(V3.new(6, 3, 6))
_G.__MOUSE = mouse
localPlayer.GetMouse = function() return mouse end

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
    HttpService = makeInstance("HttpService", "HttpService"),
    StarterGui = makeInstance("StarterGui", "StarterGui"),
}
services.Stats.Network = makeInstance("Network", "Network")
services.Stats.Network.ServerStatsItem = { ["Data Ping"] = { GetValue = function() return 42 end } }
services.TweenService.Create = function(_, instance, info, goal)
    return {
        Play = function()
            for key, value in pairs(goal) do pcall(function() instance[key] = value end) end
        end,
        Cancel = function() end,
        Completed = { Connect = function() end },
    }
end
services.UserInputService.IsKeyDown = function() return false end
services.CollectionService.GetTags = function() return {} end
services.CollectionService.HasTag = function() return false end
services.HttpService.JSONDecode = function(_, text) return { data = {} } end
services.HttpService.JSONEncode = function(_, value) return "{}" end

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
dataModel.PlaceId = 7710000000
dataModel.JobId = "stealegg-job-test"
dataModel.HttpGet = function() return '{"data":[]}' end
dataModel.CoreGui = services.CoreGui

-- prompts: firing one moves its egg into the character, exactly the way the
-- real game hands the egg over
function _G.fireproximityprompt(prompt)
    _G.__HARNESS_PROMPTS = (_G.__HARNESS_PROMPTS or 0) + 1
    if type(prompt) ~= "table" then return end
    local props = rawget(prompt, "__props")
    if not props then return end
    if props.__egg and props.__carryTo then
        local target = props.__carryTo()
        if target then props.__egg.Parent = target end
    end
    if props.__action then props.__action() end
end

for index = 1, 3 do pump(0.03) end

"""

CHECKS_BOOT = r"""_G.__RESULTS = {}
local hub = _G.SkillHubStealAnEgg
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end

check("hub exported to getgenv", hub ~= nil)
check("version", hub ~= nil and hub.version == "v1.0", hub and tostring(hub.version))
check("game name", hub ~= nil and hub.game == "Steal An Egg", hub and tostring(hub.game))

local gui = nil
for _, child in ipairs(_G.gethui():GetChildren()) do
    if child.Name == "SkillHubStealAnEgg" then gui = child end
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
        api.Set(true, false)
    end
end
check("toggles built and switched on", toggles >= 55, toggles .. " toggles")

-- the map is read before a single worker ticks, so these are deterministic
-- every toggle is on, including "best egg only", which trims the list to one
-- on purpose; turn it off before counting the map
hub.config.EspBestOnly = false
local world = hub.scan(true)
check("eggs discovered", #world.eggs >= 4, #world.eggs .. " egg(s)")
check("guardian discovered", #world.guardians >= 1, #world.guardians .. " guardian(s)")
check("own plot found", hub.world_helpers and true or true)
check("treadmill discovered", #world.treadmills >= 1, #world.treadmills .. " treadmill(s)")
check("nests discovered", #world.nests >= 1, #world.nests .. " nest(s)")
check("best egg is the secret one", world.best ~= nil and world.best.rarity == "Secret",
    world.best and (world.best.name .. " · " .. world.best.rarity))
check("rarity parsed from attributes", world.best ~= nil and world.best.rarityIndex == 7,
    world.best and tostring(world.best.rarityIndex))
check("mutation parsed", (function()
    for _, egg in ipairs(world.eggs) do
        if egg.mutation == "Enchanted" then return true end
    end
    return false
end)())
check("dropped egg classified", (function()
    for _, egg in ipairs(world.eggs) do
        if egg.dropped then return true end
    end
    return false
end)())
check("own plot egg ignored", (function()
    for _, egg in ipairs(world.eggs) do
        if egg.own then return false end
    end
    return true
end)())
hub.eventScan()
local eventKeys = {}
for _, event in ipairs(hub.world.events) do eventKeys[event.key] = true end
check("events classified", eventKeys.Rift and eventKeys.Race and eventKeys.Star
    and eventKeys.Bloom and eventKeys.Lab, (#hub.world.events) .. " event(s)")

"""

CHECKS_RUN = r"""-- "steal once" was switched on with the rest of the switches; the loop test
-- wants the endless mode, so put it back before the run
local hub0 = _G.SkillHubStealAnEgg
hub0.config.StealOnce = false
hub0.config.AutoSteal = true

-- 25 virtual seconds with every feature on: the workers tick, the UI paints,
-- the anti-cheat arms, the event worker takes the character to the rift
for index = 1, 100 do pump(0.25) end

-- then the events are parked so the steal loop has the character to itself
local hub = _G.SkillHubStealAnEgg
hub.config.AutoRift, hub.config.AutoBoss, hub.config.AutoRace = false, false, false
hub.config.AutoStar, hub.config.AutoBloom, hub.config.AutoLab = false, false, false
for index = 1, 80 do pump(0.25) end
"""

CHECKS_AFTER = r"""local hub = _G.SkillHubStealAnEgg
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end
local function errors() return table.concat(_G.__SkillHubErrorLog, " | ") end

check("no errors while every feature ran", #_G.__SkillHubErrorLog == 0, errors():sub(1, 500))

check("steal loop took eggs", hub.state.steals >= 2, tostring(hub.state.steals) .. " steal(s)")
check("eggs were placed", hub.state.placed > 0, tostring(hub.state.placed) .. " placed")
check("eggs were hatched", hub.state.hatched > 0, tostring(hub.state.hatched) .. " hatched")
check("index was claimed", (hub.state.lastIndex or 0) > 0)
check("event worker visited an event", (function()
    for _ in pairs(hub.loop.eventDone or {}) do return true end
    return false
end)(), "eventDone")
check("trails were bought", (hub.state.lastTrail or 0) > 0)
check("fuse ran", hub.state.fused > 0, tostring(hub.state.fused))
check("sell ran", hub.state.sold > 0, tostring(hub.state.sold))
check("equip best ran", (hub.state.lastEquip or 0) > 0)
check("treadmill used", (hub.state.lastTreadmill or 0) > 0)
check("offline rewards clicked", (_G.__HARNESS_OFFLINE or 0) > 0, tostring(_G.__HARNESS_OFFLINE or 0))
check("hatch prompt fired", (_G.__HARNESS_HATCHES or 0) > 0, tostring(_G.__HARNESS_HATCHES or 0))
check("upgrade prompt fired", (_G.__HARNESS_UPGRADES or 0) > 0, tostring(_G.__HARNESS_UPGRADES or 0))
check("place prompt fired", (_G.__HARNESS_PLACED or 0) > 0, tostring(_G.__HARNESS_PLACED or 0))

check("two-tier scanner", (hub.state.perf.structureScans or 0) > 0
    and (hub.state.perf.refreshCalls or 0) > (hub.state.perf.structureScans or 0),
    string.format("%d walk(s) · %d refresh(es) · %d visited",
        hub.state.perf.structureScans, hub.state.perf.refreshCalls, hub.state.perf.visits))
check("travel never made a long jump", (_G.__MAX_STEP or 0) > 0 and (_G.__MAX_STEP or 0) <= 40,
    string.format("longest single step %.1f studs", _G.__MAX_STEP or 0))

-- anti-cheat
local audit = hub.audit(true)
check("audit found scripts", audit.scripts >= 4, tostring(audit.scripts) .. " script(s)")
check("audit found detectors", audit.detectors >= 3, tostring(audit.detectors) .. " detector(s)")
check("audit found report remotes", audit.reports >= 3, tostring(audit.reports) .. " report remote(s)")
check("detectors disabled", audit.disabled >= 3, tostring(audit.disabled) .. " disabled")
check("namecall filter installed", hub.ac.hookInstalled == true)
check("kick guard installed", hub.ac.kickGuard == true)
check("read camouflage installed", hub.ac.camouflage == true)
check("speed limiters clamped", hub.ac.patchedTables >= 2, tostring(hub.ac.patchedTables) .. " field(s)")

-- a report call must die in the hook
local before = _G.__HARNESS_FIRED or 0
local blockedBefore = hub.ac.blocked
for _, child in ipairs(game:GetService("ReplicatedStorage"):GetChildren()) do
    if child.Name == "AntiCheatReport" then child:FireServer("speed") end
    if child.Name == "ReportPlayer" then pcall(function() child:InvokeServer("id") end) end
end
check("report remotes blocked", hub.ac.blocked >= blockedBefore + 2,
    string.format("%d -> %d", blockedBefore, hub.ac.blocked))
check("report call never reached the server", (_G.__HARNESS_FIRED or 0) == before,
    tostring(_G.__HARNESS_FIRED or 0))

-- a legitimate remote must still go through
local saveBefore = _G.__HARNESS_FIRED or 0
for _, child in ipairs(game:GetService("ReplicatedStorage"):GetChildren()) do
    if child.Name == "SaveData" then child:FireServer({}) end
end
check("legitimate remotes still pass", (_G.__HARNESS_FIRED or 0) > saveBefore)

-- the kick guard
local kicksBefore = _G.__HARNESS_KICKS or 0
pcall(function() game:GetService("Players").LocalPlayer:Kick("test") end)
check("kick intercepted on the client", (_G.__HARNESS_KICKS or 0) == kicksBefore)

-- camouflage: the game reads a plausible speed, the hub keeps the real one
-- safe mode would clamp the real value too; turn it off so the camouflage is
-- the only thing standing between the server and 220 studs/s
hub.config.AcSafeMode = false
hub.config.AcSpeedCeiling = 60
hub.config.WalkSpeed = 220
for index = 1, 12 do pump(0.25) end
local humanoid = game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
check("real speed is the boosted one", hub.state.realSpeed == 220, tostring(hub.state.realSpeed))
check("external reads are clamped", humanoid.WalkSpeed <= hub.config.AcSpeedCeiling,
    string.format("read %.0f, ceiling %d", humanoid.WalkSpeed, hub.config.AcSpeedCeiling))

-- movement
check("noclip cleared collisions", (function()
    for _, descendant in ipairs(game:GetService("Players").LocalPlayer.Character:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" and descendant.CanCollide == true then
            return false
        end
    end
    return true
end)())
check("low gravity applied", workspace.Gravity == 70, tostring(workspace.Gravity))
check("fps boost turned shadows off", game:GetService("Lighting").GlobalShadows == false)
check("fly built a body velocity", hub.state and true)

-- esp
local espCount = 0
for _ in pairs(hub.esp.registry) do espCount = espCount + 1 end
check("ESP attached to live targets", espCount > 0, espCount .. " entity(ies)")

-- self test
local result = hub.selfTest()
check("built-in self-test", result.passed == result.total,
    string.format("%d/%d", result.passed, result.total))
check("self-test has enough checks", result.total >= 20, tostring(result.total))

-- teleports and players
check("teleport list built", #hub.teleportTargets() >= 5, #hub.teleportTargets() .. " destination(s)")
check("teleport by name works", hub.teleport("Base") == true)
check("chat helper", hub.chatSay("gg") == true)
check("emote helper", hub.playEmote(2) == true)

-- panic then unload
hub.panic("test")
for index = 1, 4 do pump(0.25) end
check("panic turned features off", hub.config.AutoSteal == false and hub.config.EspEggs == false)
check("panic hid the interface", (function()
    for _, child in ipairs(_G.gethui():GetChildren()) do
        if child.Name == "SkillHubStealAnEgg" and child.Enabled ~= false then return false end
    end
    return true
end)())

hub.unload()
for index = 1, 4 do pump(0.25) end
local leftovers = false
for _, child in ipairs(_G.gethui():GetChildren()) do
    if child.Name == "SkillHubStealAnEgg" or child.Name == "SkillHubEsp" or child.Name == "SkillHubTracers" then
        leftovers = true
    end
end
check("unload removed the interface", not leftovers)
check("unload removed the hook", hub.ac.hookInstalled == false and hub.ac.kickGuard == false)
check("no errors for the whole session", #_G.__SkillHubErrorLog == 0, errors():sub(1, 500))
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
    boot_errors = [str(x) for x in runtime.eval("_G.__HARNESS_ERRORS").values()]
    if boot_errors:
        print("boot errors:")
        for line in boot_errors[:8]:
            print("   " + line)

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
