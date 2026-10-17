#!/usr/bin/env python3
"""Boot the RIVALS hub for real in a mocked Roblox and drive it.

    /tmp/venv/bin/python tools/rivals_test.py

The mock gives the hub a virtual clock, a coroutine scheduler (so its
`while alive do … task.wait() end` loops really tick), one shared instance
metatable whose `__namecall` dispatch emulates Roblox (including
`getnamecallmethod`, so the report filter is exercised for real),
`hookmetamethod` and `getgc` so the camouflage and the limiter patcher are real
too, real Vector3/CFrame/Color3 maths with a perspective camera projection,
a `Drawing` table, the services the hub touches, the executor globals it
probes, and a fake RIVALS server: a duel arena with a wall, two enemies and a
teammate, a rifle with an ammo value, gameplay and queue remotes, the report
remotes, four detector scripts and the chat service.

Checked: load · clicking the nine rail buttons, a toggle, a dropdown option, a
preset and the aim key in the real ScreenGui · every switch on then off · the aim picker
(visibility, team filter, crosshair priority, the FOV cone, hysteresis) · the
per-frame step limit · mouse and silent paths · ESP highlights, tags, tracers,
boxes and the FOV ring · fire cadence, reload, movement, fly, noclip, anti-void
· chat, queue, leave, server hop, fullbright, anti-flash, smoke, VFX · paced
teleports · a camera swapped mid-run by the game, a respawn into a brand-new
character, aim re-engaging after both, worker health · all six anti-cheat
layers (detectors, namecall filter, kick guard, camouflage, limit clamp, rate
limits) · panic · the built-in 40-check self-test · unload.
"""
import io, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
HUB = os.path.join(HERE, os.pardir, "RIVALS", "SkillHub.lua")

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

-- Run the task body under xpcall *inside* the coroutine: a traceback taken from
-- outside a dead coroutine only shows the resume site, which is useless when a
-- background loop dies. Wrapping the body keeps yield working (Lua 5.2+).
_G.__TASK_SOURCE = {}
local function wrap_task(fn, ...)
    local args = table.pack(...)
    local thread
    thread = coroutine.create(function()
        local function handler(err)
            return tostring(err) .. "\n" .. debug.traceback("", 1)
        end
        return xpcall(function() return fn(table.unpack(args, 1, args.n)) end, handler)
    end)
    local info = debug.getinfo(fn, "Sl")
    _G.__TASK_SOURCE[thread] = info and string.format("%s:%s", tostring(info.short_src), tostring(info.linedefined)) or "?"
    return thread
end

local function step_thread(thread, label)
    local ok, first, second = coroutine.resume(thread)
    local where = _G.__TASK_SOURCE and _G.__TASK_SOURCE[thread] or "?"
    if not ok then
        table.insert(_G.__HARNESS_ERRORS, label .. " (" .. where .. "): " .. tostring(first))
        return nil
    end
    if first == false then
        -- xpcall caught it; the traceback came back as the second return value
        table.insert(_G.__HARNESS_ERRORS, label .. " (" .. where .. "): " .. tostring(second))
        return nil
    end
    return first
end

function task_spawn(fn, ...)
    local thread = wrap_task(fn, ...)
    local wait = step_thread(thread, "spawn")
    if wait and coroutine.status(thread) ~= "dead" then schedule(thread, CLOCK.now + (tonumber(wait) or 0)) end
    return thread
end

function task_wait(seconds) return coroutine.yield(seconds or 0.03) end

function pump(step)
    CLOCK.now = CLOCK.now + step
    local pending = CLOCK.tasks
    CLOCK.tasks = {}
    for _, entry in ipairs(pending) do
        if coroutine.status(entry.thread) == "suspended" then
            local wait = step_thread(entry.thread, "task")
            if wait and coroutine.status(entry.thread) ~= "dead" then
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
    return setmetatable({ X = x or 0, Y = y or 0 }, {
        __index = function(t, k)
            if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y) end
            if k == "Unit" then
                local m = math.sqrt(t.X * t.X + t.Y * t.Y)
                if m > 0 then return _G.Vector2.new(t.X / m, t.Y / m) end
                return _G.Vector2.new(0, 0)
            end
        end,
        __sub = function(a, b) return _G.Vector2.new(a.X - b.X, a.Y - b.Y) end,
        __add = function(a, b) return _G.Vector2.new(a.X + b.X, a.Y + b.Y) end,
    })
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
    local from = rawget(self, "__look")
    local to = rawget(other, "__look")
    if to then
        local blended = V3.new(
            from.x + (to.x - from.x) * amount,
            from.y + (to.y - from.y) * amount,
            from.z + (to.z - from.z) * amount)
        if blended.Magnitude > 0 then blended = blended.Unit end
        rawset(frame, "__look", blended)
    end
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

_G.Enum = setmetatable({}, { __index = function(self, group)
    -- Roblox hands out the same EnumItem every time it is read. A fresh table
    -- per access makes `input.UserInputType ~= Enum.UserInputType.Keyboard`
    -- true no matter what the hub compares against, so the group and the item
    -- are cached here.
    local items = {}
    local groupTable = setmetatable(items, { __index = function(store, item)
        local value = setmetatable({ Name = item, Value = 0, EnumType = group },
            { __index = function() return item end })
        store[item] = value
        return value
    end })
    self[group] = groupTable
    return groupTable
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
function METHODS.FireServer(self, ...)
    _G.__HARNESS_FIRED = (_G.__HARNESS_FIRED or 0) + 1
    _G.__HARNESS_LAST_FIRE = rawget(self, "__props").Name
    _G.__HARNESS_LAST_ARGS = table.pack(...)
    return "fired"
end
function METHODS.InvokeServer() return nil end
function METHODS.WorldToViewportPoint(self, position)
    local camera = _G.workspace and _G.workspace.CurrentCamera
    local size = (camera and rawget(camera, "__props").ViewportSize) or rawget(self, "ViewportSize") or { X = 800, Y = 600 }
    local origin = camera and camera.CFrame.Position or V3.new(0, 0, 0)
    local look = camera and camera.CFrame.LookVector or V3.new(0, 0, -1)
    local delta = position - origin
    local depth = delta:Dot(look)
    if depth <= 0.05 then return V3.new(0, 0, depth), false end
    local fov = (camera and camera.FieldOfView) or 70
    local scale = (size.Y / 2) / math.tan(math.rad(fov / 2))
    local right = V3.new(1, 0, 0)
    local up = V3.new(0, 1, 0)
    local px = size.X / 2 + (delta:Dot(right) / depth) * scale
    local py = size.Y / 2 - (delta:Dot(up) / depth) * scale
    return V3.new(px, py, depth), true
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
    humanoid.UseJumpPower = false
    humanoid.Parent = model
    local head = makePart("Head", position + V3.new(0, 1, 0), model)
    head.Size = V3.new(2, 2, 1)
    local torso = makePart("UpperTorso", position + V3.new(0, 0.2, 0), model)
    model.PrimaryPart = root
    return model, humanoid
end

-- ── camera: at eye level, looking down -Z, exactly like a player at spawn ───
local camera = makeInstance("Camera", "Camera")
camera.ViewportSize = { X = 800, Y = 600 }
camera.CFrame = CFrame_new(V3.new(0, 10, 0), V3.new(0, 10, -100))
camera.FieldOfView = 70
camera.Parent = _G.workspace
_G.workspace.CurrentCamera = camera

_G.RaycastParams = { new = function() return { FilterType = nil, FilterDescendantsInstances = {} } end }

-- ── the duel arena: one wall, three other players ──────────────────────────
_G.__WALL = makePart("ArenaWall", V3.new(0, 10, -55))
_G.__WALL.Size = V3.new(120, 60, 4)

local players = makeInstance("Players", "Players")
local localPlayer = makeInstance("Player", "TestPlayer")
_G.__LOCAL_PLAYER = localPlayer

-- Player.CharacterAdded: the hub hooks it, and the respawn checks fire it
local characterAdded = { listeners = {} }
function characterAdded:Connect(fn)
    table.insert(self.listeners, fn)
    return { Disconnect = function() end }
end
function characterAdded:Fire(character)
    for _, fn in ipairs(self.listeners) do pcall(fn, character) end
end
localPlayer.CharacterAdded = characterAdded
localPlayer.UserId = 1
localPlayer.DisplayName = "TestPlayer"
local character, localHumanoid = humanoidModel("TestPlayerCharacter", 100, V3.new(0, 3, 0))
character:SetAttribute("Team", "Blue")
character.Parent = _G.workspace
localPlayer.Character = character
localPlayer.Team = { Name = "Blue" }

local tool = makeInstance("Tool", "Assault Rifle")
tool.Parent = character
local ammo = makeInstance("IntValue", "Ammo")
ammo.Value = 30
ammo.Parent = tool

local backpack = makeInstance("Backpack", "Backpack")
backpack.Parent = localPlayer
local playerGui = makeInstance("PlayerGui", "PlayerGui")
playerGui.Parent = localPlayer
local playerScripts = makeInstance("PlayerScripts", "PlayerScripts")
playerScripts.Parent = localPlayer

-- a local detector script inside PlayerScripts, the usual place for one
do
    local speed = makeInstance("LocalScript", "SpeedEnforcer")
    speed.Disabled = false
    speed.Parent = playerScripts
end

-- ── the three other players ────────────────────────────────────────────────
-- EnemyOne is visible and 40 studs away, EnemyTwo hides behind the wall and
-- sits almost exactly on the crosshair, Teammate is on our side.
local enemyOne = makeInstance("Player", "EnemyOne")
enemyOne.UserId = 2
enemyOne.DisplayName = "EnemyOne"
local enemyOneChar = humanoidModel("EnemyOneCharacter", 100, V3.new(12, 3, -40))
enemyOneChar:SetAttribute("Team", "Red")
enemyOneChar.Parent = _G.workspace
enemyOne.Character = enemyOneChar

local enemyTwo = makeInstance("Player", "EnemyTwo")
enemyTwo.UserId = 3
enemyTwo.DisplayName = "EnemyTwo"
local enemyTwoChar = humanoidModel("EnemyTwoCharacter", 55, V3.new(-2, 3, -70))
enemyTwoChar:SetAttribute("Team", "Red")
enemyTwoChar.Parent = _G.workspace
enemyTwo.Character = enemyTwoChar
local enemyTwoTool = makeInstance("Tool", "Sniper")
enemyTwoTool.Parent = enemyTwoChar

local teammate = makeInstance("Player", "Teammate")
teammate.UserId = 4
teammate.DisplayName = "Teammate"
local teammateChar = humanoidModel("TeammateCharacter", 100, V3.new(4, 3, -30))
teammateChar:SetAttribute("Team", "Blue")
teammateChar.Parent = _G.workspace
teammate.Character = teammateChar

_G.__HARNESS_PLAYERS = { localPlayer, enemyOne, enemyTwo, teammate }
_G.__LOCAL_PLAYER = localPlayer
localPlayer.Parent = players
players.LocalPlayer = localPlayer
players.GetPlayers = function() return _G.__HARNESS_PLAYERS end
players.CharacterAdded = signalOf(players, "CharacterAdded")

-- ── the range check: a ray from the camera hits the wall or nothing ────────
function METHODS.Raycast(self, origin, direction, params)
    local wall = _G.__WALL
    if not wall then return nil end
    local wallZ = rawget(wall, "__props").Position.z
    local oz, dz = origin.z, direction.z
    if dz >= -0.0001 or oz <= wallZ then return nil end
    local t = (wallZ - oz) / dz
    if t < 0 or t > 1 then return nil end
    local x = origin.x + direction.x * t
    local y = origin.y + direction.y * t
    if x > -60 and x < 60 and y > -20 and y < 40 then
        return {
            Instance = wall,
            Position = V3.new(x, y, wallZ),
            Normal = V3.new(0, 0, 1),
            Distance = math.abs(origin.z - wallZ),
        }
    end
    return nil
end

-- ── ReplicatedStorage: gameplay, report and detector objects ───────────────
local replicated = makeInstance("ReplicatedStorage", "ReplicatedStorage")
local antiCheatFolder = makeInstance("Folder", "AntiCheatClient")
antiCheatFolder.Parent = replicated
do
    local detector = makeInstance("LocalScript", "AntiCheatClient")
    detector.Disabled = false
    detector.Parent = replicated
    local monitor = makeInstance("LocalScript", "PlayerMonitor")
    monitor.Disabled = false
    monitor.Parent = antiCheatFolder
    local integrity = makeInstance("LocalScript", "IntegrityChecker")
    integrity.Disabled = false
    integrity.Parent = antiCheatFolder

    for _, name in ipairs({ "Shoot", "FireWeapon", "Reload", "EquipWeapon", "QueueMatch",
        "LeaveMatch", "Emote", "ForceField", "SaveData", "CommitStats" }) do
        local remote = makeInstance("RemoteEvent", name)
        remote.Parent = replicated
        if name == "SaveData" then _G.__SAFE_REMOTE = remote end
    end
    local equipFunction = makeInstance("RemoteFunction", "GetLoadout")
    equipFunction.Parent = replicated

    local report = makeInstance("RemoteEvent", "AntiCheatReport")
    report.Parent = replicated
    local reportPlayer = makeInstance("RemoteFunction", "ReportPlayer")
    reportPlayer.Parent = replicated
    local flag = makeInstance("RemoteEvent", "FlagPlayer")
    flag.Parent = replicated
    local shot = makeInstance("RemoteEvent", "ScreenshotUpload")
    shot.Parent = replicated
    _G.__REPORT_REMOTE = report
end

-- ── TextChatService, the modern chat path ─────────────────────────────────
local textChat = makeInstance("TextChatService", "TextChatService")
local channels = makeInstance("Folder", "TextChannels")
channels.Parent = textChat
local general = makeInstance("TextChannel", "RBXGeneral")
general.Parent = channels
function METHODS.SendAsync(self, text)
    _G.__HARNESS_CHAT = (_G.__HARNESS_CHAT or 0) + 1
    _G.__HARNESS_LAST_CHAT = text
    return true
end

-- ── the Lua config tables getgc(true) is supposed to find and clamp ───────
_G.__GC = {
    { Recoil = 0.8, Spread = 1.2 },
    { MaxWalkSpeed = 500, SpeedLimit = 900 },
    { Damage = 10, Ammo = 30 },
}

local mouse = makeInstance("Mouse", "Mouse")
mouse.Hit = CFrame_new(V3.new(0, 10, -40))
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
    TextChatService = textChat,
}
services.Lighting.Brightness = 1
services.Lighting.ClockTime = 14
services.Lighting.GlobalShadows = true
services.Lighting.FogEnd = 1000
services.Lighting.Ambient = _G.Color3.fromRGB(70, 70, 70)
services.Lighting.OutdoorAmbient = _G.Color3.fromRGB(80, 80, 80)
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
services.UserInputService.InputBegan = signalOf(services.UserInputService, "InputBegan")
services.UserInputService.InputChanged = signalOf(services.UserInputService, "InputChanged")
services.UserInputService.InputEnded = signalOf(services.UserInputService, "InputEnded")
services.CollectionService.GetTags = function() return {} end
services.CollectionService.HasTag = function() return false end
services.HttpService.JSONDecode = function(_, text)
    return { data = { { id = "other-job-1", playing = 3, maxPlayers = 10 } } }
end
services.HttpService.JSONEncode = function() return "{}" end
services.SoundService.PlayLocalSound = function(_, sound)
    _G.__HARNESS_SOUNDS = (_G.__HARNESS_SOUNDS or 0) + 1
end

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
dataModel.JobId = "rivals-job-test"
dataModel.HttpGet = function() return '{"data":[]}' end
dataModel.CoreGui = services.CoreGui

-- ── Drawing, so the tracer, box and FOV paths are real ────────────────────
_G.__DRAWINGS = {}
_G.Drawing = {
    new = function(class)
        local drawing = {
            Class = class, Visible = false, Transparency = 1, Thickness = 1,
            Filled = false, Color = nil, Radius = 0,
            Position = V3.new(0, 0, 0), Size = V3.new(0, 0, 0),
            From = V3.new(0, 0, 0), To = V3.new(0, 0, 0),
        }
        function drawing:Remove() self.Removed = true end
        _G.__DRAWINGS[#_G.__DRAWINGS + 1] = drawing
        return drawing
    end,
}

-- ── the two GUI buttons the game puts in front of a player ────────────────
do
    local play = makeInstance("TextButton", "PlayButton")
    play.Text = "Play"
    play.Visible = true
    play.Parent = playerGui
    local leave = makeInstance("TextButton", "LeaveButton")
    leave.Text = "Leave Match"
    leave.Visible = true
    leave.Parent = playerGui
    local flash = makeInstance("Frame", "FlashOverlay")
    flash.Visible = true
    flash.BackgroundTransparency = 0
    flash.Parent = playerGui
end

-- a smoke part and a particle, for the vision toggles
do
    local smoke = makePart("SmokeCloud", V3.new(6, 4, -20))
    smoke.Transparency = 0.2
    local fx = makePart("MuzzleFlash", V3.new(0, 12, 12))
    local emitter = makeInstance("ParticleEmitter", "Sparks")
    emitter.Enabled = true
    emitter.Parent = fx
end

_G.__SCOPE_PRESS, _G.__SCOPE_RELEASE = 0, 0
function _G.mouse2press() _G.__SCOPE_PRESS = _G.__SCOPE_PRESS + 1 end
function _G.mouse2release() _G.__SCOPE_RELEASE = _G.__SCOPE_RELEASE + 1 end
function _G.mouse2click() _G.__SCOPE_PRESS = _G.__SCOPE_PRESS + 1 _G.__SCOPE_RELEASE = _G.__SCOPE_RELEASE + 1 end

function _G.mousemoverel(dx, dy)
    _G.__HARNESS_MOUSE_MOVES = (_G.__HARNESS_MOUSE_MOVES or 0) + 1
    _G.__HARNESS_LAST_MOVE = { dx, dy }
end

for index = 1, 3 do pump(0.03) end

-- build a fresh local character exactly the way a match does: new model, new
-- humanoid, parented into the world, then Player.Character and CharacterAdded
function _G.__SPAWN_CHARACTER(player, name, position)
    local character, humanoid = humanoidModel(name, 100, position)
    character:SetAttribute("Team", "Blue")
    character.Parent = _G.workspace
    player.Character = character
    if player.CharacterAdded and player.CharacterAdded.Fire then
        player.CharacterAdded:Fire(character)
    end
    return character, humanoid
end

"""

CHECKS_BOOT = r"""_G.__RESULTS = {}
local hub = _G.SkillHubRivals
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end

check("hub exported to getgenv", hub ~= nil)
if hub then
check("version", hub.version == "v1.3", tostring(hub.version))
check("game name", hub.game == "RIVALS", tostring(hub.game))
check("build tag", string.find(tostring(hub.build), "Update 23", 1, true) ~= nil, tostring(hub.build))

local gui = nil
for _, child in ipairs(_G.gethui():GetChildren()) do
    if child.Name == "SkillHubRIVALS" then gui = child end
end
check("window in the hidden gui", gui ~= nil)
check("window chrome built", gui ~= nil and #gui:GetDescendants() > 200,
    gui and (#gui:GetDescendants() .. " instances"))
check("nine tabs", #hub.tabs == 9, tostring(#hub.tabs))

local selected, withContent = 0, 0
for _, tab in ipairs(hub.tabs) do
    if pcall(tab.Select) then selected = selected + 1 end
    if #tab.page:GetChildren() > 1 then withContent = withContent + 1 end
end
check("every tab selects", selected == 9, selected .. "/9")
check("every tab has components", withContent == 9, withContent .. "/9")
check("switch count", hub.switchCount() >= 60, tostring(hub.switchCount()) .. " switches")

hub.config.AimVisibleOnly, hub.config.AimTeamCheck = true, true
local world = hub.scan(true)
check("three other players found", #world.players == 3, tostring(#world.players))
check("local team read", hub.worldData.localTeam == "Blue", tostring(hub.worldData.localTeam))
local friendlyCount = 0
for _, record in ipairs(world.players) do if record.friendly then friendlyCount = friendlyCount + 1 end end
check("teammate marked friendly", friendlyCount == 1, tostring(friendlyCount))

local target = hub.pickTarget()
check("target is the visible enemy", target ~= nil and target.name == "EnemyOne", target and target.name or "nil")
if target then
    local part = hub.aimPart(target)
    check("aim part resolves to the head", part ~= nil and part.Name == "Head", part and part.Name or "nil")
    local position = hub.aimPosition(target)
    check("aim position is a vector", position ~= nil and position.Magnitude ~= nil,
        position and string.format("%.1f", position.Magnitude) or "nil")
    hub.config.AimMethod = "Camera"
    local before = _G.workspace.CurrentCamera.CFrame.LookVector
    hub.stepAim(target, 0.016)
    local after = _G.workspace.CurrentCamera.CFrame.LookVector
    local turned = math.deg(math.acos(math.clamp(before:Dot(after), -1, 1)))
    check("camera turns toward the target", turned > 0.5, string.format("%.2f deg", turned))
    check("step limit respected", turned <= hub.config.AimStepLimit + 0.5,
        string.format("%.2f <= %s", turned, tostring(hub.config.AimStepLimit)))
    hub.config.AimMethod = "Hybrid"
end

-- put the camera back on its starting heading: the step test above turned it
_G.workspace.CurrentCamera.CFrame = _G.CFrame.lookAt(_G.Vector3.new(0, 10, 0), _G.Vector3.new(0, 10, -100))
-- take the wall away so both enemies are visible, then the one nearest the
-- crosshair must win even though it is further away
local wall = _G.__WALL
_G.__WALL = nil
for index = 1, 5 do pump(0.05) end
hub.config.AimVisibleOnly = true
hub.scan(true)
local centred = hub.pickTarget()
check("crosshair priority prefers the centred enemy", centred ~= nil and centred.name == "EnemyTwo",
    centred and centred.name or "nil")
_G.__WALL = wall
hub.config.AimVisibleOnly = true
hub.scan(true)

local movesBefore = _G.__HARNESS_MOUSE_MOVES or 0
hub.config.AimMethod = "Mouse"
hub.stepAim(target or hub.pickTarget(), 0.016)
check("mouse method moves the cursor", (_G.__HARNESS_MOUSE_MOVES or 0) > movesBefore,
    tostring((_G.__HARNESS_MOUSE_MOVES or 0) - movesBefore) .. " move(s)")
hub.config.AimMethod = "Silent"
hub.config.AimEnabled = true
hub.state.target = hub.pickTarget()
local silent = hub.silentPosition()
check("silent aim resolves the target part", silent ~= nil, silent and string.format("%.1f", silent.Magnitude) or "nil")
hub.config.AimMethod = "Camera"
hub.config.AimEnabled = false

hub.config.EspPlayers, hub.config.EspChams, hub.config.EspTeam = true, true, false
local drawn = hub.espUpdate()
check("esp draws both enemies", drawn == 2, tostring(drawn))
local folder = hub.espFolder()
local highlights = 0
if folder then
    for _, child in ipairs(folder:GetChildren()) do if child:IsA("Highlight") then highlights = highlights + 1 end end
end
check("chams live in the folder, not the character", highlights == 2, tostring(highlights))
local enemyOneChar = _G.__HARNESS_PLAYERS[2].Character
check("character has no injected child", enemyOneChar:FindFirstChild("SkillHubCham") == nil)
local tagsUnderCharacter = 0
for _, child in ipairs(enemyOneChar:GetDescendants()) do
    if child:IsA("BillboardGui") then tagsUnderCharacter = tagsUnderCharacter + 1 end
end
check("tags follow via Adornee, not parenthood", tagsUnderCharacter == 0, tostring(tagsUnderCharacter))
hub.config.EspMaxDistance = 50
local capped = hub.espUpdate()
check("distance cap trims the list", capped == 1, tostring(capped))
hub.config.EspMaxDistance = 900
hub.config.EspTeam = true
local withTeam = hub.espUpdate()
check("team esp shows the teammate", withTeam == 3, tostring(withTeam))
hub.config.EspTeam = false

hub.config.EspTracers, hub.config.EspBox = true, true
hub.espUpdate()
local lines, boxes = 0, 0
for _, drawing in ipairs(_G.__DRAWINGS) do
    if drawing.Class == "Line" and drawing.Visible then lines = lines + 1 end
    if drawing.Class == "Square" and drawing.Visible then boxes = boxes + 1 end
end
check("tracers drawn with e.g. a Drawing line", lines >= 2, tostring(lines))
check("boxes drawn", boxes >= 2, tostring(boxes))
hub.config.EspTracers, hub.config.EspBox = false, false

hub.config.FovCircle, hub.config.AimEnabled = true, true
hub.fovCircle()
local circles = 0
for _, drawing in ipairs(_G.__DRAWINGS) do
    if drawing.Class == "Circle" and drawing.Visible then circles = circles + 1 end
end
check("fov circle drawn", circles >= 1, tostring(circles))
hub.config.AimEnabled = false
hub.fovCircle()

check("shoot remote indexed", hub.findRemote({ "shoot" }) ~= nil, "Shoot")
check("reload remote indexed", hub.findRemote({ "reload" }) ~= nil, "Reload")
check("report remote indexed", hub.findRemote({ "report" }) ~= nil, "AntiCheatReport")
check("roster size", #hub.knowledge.Weapons >= 35, tostring(#hub.knowledge.Weapons) .. " catalogued")
check("wildcat numbers", (function()
    for _, entry in ipairs(hub.knowledge.Weapons) do
        if entry.Name == "Wildcat" then return entry.Cost == 35 and entry.Slot == "Primary" end
    end
    return false
end)(), "35 keys · Primary")
end
"""

CHECKS_GUI = r"""-- Clicking the real GUI: every rail button, a toggle, a dropdown and a preset.
-- The other chunks call the hub's API; this one drives the ScreenGui the way a
-- player does, so "the tabs do not work" fails here and not in a match.
local hub = _G.SkillHubRivals
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end

local win = hub.window()
local root = win and win.Root
check("gui · the window root exists", root ~= nil)

local function findLabel(text)
    for _, item in ipairs(root:GetDescendants()) do
        if item.ClassName == "TextLabel" and item.Text == text then return item end
    end
    return nil
end

-- rail buttons: a TextButton that carries the tab title as a TextLabel
local switched, correct = 0, 0
for _, tab in ipairs(hub.tabs) do
    local label = findLabel(tab.title)
    local button = label and label.Parent
    if button and button.ClassName == "TextButton" then
        button.MouseButton1Click:Fire()
        switched = switched + 1
        local visible = 0
        for _, other in ipairs(hub.tabs) do
            if other.page.Visible then visible = visible + 1 end
        end
        if tab.page.Visible and visible == 1 then correct = correct + 1 end
    end
end
check("gui · every rail button opens its page", switched == #hub.tabs and correct == #hub.tabs,
    switched .. "/" .. #hub.tabs .. " clicked · " .. correct .. " correct")

-- a toggle card: title label + one full-size TextButton that takes the click
local aimLabel = findLabel("Aim assist")
local aimCard = aimLabel and aimLabel.Parent
local aimClick = nil
if aimCard then
    for _, child in ipairs(aimCard:GetChildren()) do
        if child.ClassName == "TextButton" and child.Text == "" then aimClick = child break end
    end
end
hub.config.AimEnabled = false
if aimClick then
    aimClick.MouseButton1Click:Fire()
    local turnedOn = hub.config.AimEnabled == true
    aimClick.MouseButton1Click:Fire()
    local turnedOff = hub.config.AimEnabled == false
    check("gui · clicking the Aim assist toggle flips the config", turnedOn and turnedOff,
        tostring(turnedOn) .. "/" .. tostring(turnedOff))
else
    check("gui · clicking the Aim assist toggle flips the config", false, "no click target")
end

-- a dropdown: the selector opens the list, an option writes the config
local methodLabel = findLabel("Method")
local methodCard = methodLabel and methodLabel.Parent
local selector, optionList = nil, nil
if methodCard then
    for _, child in ipairs(methodCard:GetChildren()) do
        if child.ClassName == "TextButton" then
            selector = child
        elseif child.ClassName == "Frame" then
            for _, option in ipairs(child:GetChildren()) do
                if option.ClassName == "TextButton" and option.Text == "   Camera" then optionList = child end
            end
        end
    end
end
if selector and optionList then
    hub.config.AimMethod = "Hybrid"
    selector.MouseButton1Click:Fire()
    local opened = optionList.Visible == true
    local cameraOption = nil
    for _, option in ipairs(optionList:GetChildren()) do
        if option.ClassName == "TextButton" and option.Text == "   Camera" then cameraOption = option end
    end
    cameraOption.MouseButton1Click:Fire()
    check("gui · the Method dropdown sets the config",
        opened and hub.config.AimMethod == "Camera" and optionList.Visible == false,
        tostring(opened) .. " · " .. tostring(hub.config.AimMethod))
    hub.config.AimMethod = "Hybrid"
else
    check("gui · the Method dropdown sets the config", false, "no dropdown")
end

-- a preset button inside the Combat tab
local duelLabel = findLabel("Duel · 1v1")
local duelCard = duelLabel and duelLabel.Parent
local duelButton = nil
if duelCard then
    for _, child in ipairs(duelCard:GetChildren()) do
        if child.ClassName == "TextButton" and child.Text == "RUN" then duelButton = child break end
    end
end
if duelButton then
    duelButton.MouseButton1Click:Fire()
    check("gui · a preset button moves the sliders",
        tonumber(hub.config.AimFov) == 90 and math.abs(tonumber(hub.config.AimSmooth) - 0.5) < 0.001,
        tostring(hub.config.AimFov) .. "° · " .. tostring(hub.config.AimSmooth))
    hub.config.AimFov, hub.config.AimSmooth = 140, 0.55
else
    check("gui · a preset button moves the sliders", false, "no preset button")
end

-- the aim key: E toggles aim, the switch follows, and a keystroke that the
-- game already handled (typing in chat) is ignored
local userInput = _G.game:GetService("UserInputService")
local function pressKey(name, processed)
    userInput.InputBegan:Fire({
        UserInputType = Enum.UserInputType.Keyboard,
        KeyCode = { Name = name },
    }, processed == true)
end
hub.config.AimToggle = true
hub.config.AimEnabled = false
pressKey("E")
local onByKey = hub.config.AimEnabled == true
pressKey("E")
local offByKey = hub.config.AimEnabled == false
pressKey("E")                      -- leave aim on
if aimClick then aimClick.MouseButton1Click:Fire() end   -- the switch must agree
local synced = hub.config.AimEnabled == false
check("gui · the aim key toggles aim and syncs the switch", onByKey and offByKey and synced,
    tostring(onByKey) .. "/" .. tostring(offByKey) .. "/" .. tostring(synced))
local beforeProcessed = hub.config.AimEnabled
pressKey("E", true)                -- gameProcessed == true, e.g. typing in chat
check("gui · keystrokes the game handled are ignored", hub.config.AimEnabled == beforeProcessed,
    tostring(hub.config.AimEnabled))
hub.config.AimEnabled = false

-- the keybind widget: click it, press a key, the config follows
local bindLabel = findLabel("Aim key")
local bindCard = bindLabel and bindLabel.Parent
local bindButton = nil
if bindCard then
    for _, child in ipairs(bindCard:GetChildren()) do
        if child.ClassName == "TextButton" then bindButton = child break end
    end
end
if bindButton then
    hub.config.AimKey = "E"
    hub.config.AimEnabled = false
    bindButton.MouseButton1Click:Fire()
    local armed = bindButton.Text == "press a key…"
    pressKey("Q")
    check("gui · the keybind widget rebinds the aim key",
        armed and hub.config.AimKey == "Q" and bindButton.Text == "Q",
        tostring(armed) .. " · " .. tostring(hub.config.AimKey) .. " · " .. tostring(bindButton.Text))
    -- the same keystroke now matches the new binding, so it also toggled aim
    hub.config.AimKey = "E"
    hub.config.AimEnabled = false
else
    check("gui · the keybind widget rebinds the aim key", false, "no keybind button")
end

-- the search box filters the rail, clearing it brings every tab back
local searchBox = nil
for _, item in ipairs(root:GetDescendants()) do
    if item.ClassName == "TextBox" then searchBox = item break end
end
if searchBox then
    searchBox.Text = "chams"
    local visible, espVisible, combatVisible = 0, false, false
    for _, tab in ipairs(hub.tabs) do
        if tab.button.Visible then visible = visible + 1 end
        if tab.title == "ESP" and tab.button.Visible then espVisible = true end
        if tab.title == "Combat" and tab.button.Visible then combatVisible = true end
    end
    check("gui · the search box filters the rail", visible == 1 and espVisible and not combatVisible,
        visible .. " visible · esp=" .. tostring(espVisible) .. " · combat=" .. tostring(combatVisible))
    searchBox.Text = ""
    local allBack = true
    for _, tab in ipairs(hub.tabs) do
        if tab.button.Visible == false then allBack = false end
    end
    check("gui · clearing the search restores the rail", allBack)
else
    check("gui · the search box filters the rail", false, "no search box")
    check("gui · clearing the search restores the rail", false, "no search box")
end

-- the window chrome: minimise collapses the body, close hides the window and
-- the hide key brings it back instead of leaving an unreachable ScreenGui
local function findChrome(text)
    for _, item in ipairs(root:GetDescendants()) do
        if item.ClassName == "TextLabel" and item.Text == text
            and item.Parent and item.Parent.ClassName == "TextButton" then
            return item.Parent
        end
    end
    return nil
end
local minimiseButton = findChrome("—")
local closeButton = findChrome("×")
if minimiseButton and closeButton and win.Screen then
    local beforeHidden = {}
    for _, child in ipairs(win.Screen:GetChildren()) do beforeHidden[child] = child.Visible end
    minimiseButton.MouseButton1Click:Fire()
    local collapsed = win.Minimized == true
    for child, was in pairs(beforeHidden) do
        if was ~= false and child.Visible == false then collapsed = true end
    end
    minimiseButton.MouseButton1Click:Fire()
    local restored = win.Root.Visible ~= false and win.Minimized == false
    closeButton.MouseButton1Click:Fire()
    local hidden = win.Root.Visible == false and win.Screen.Enabled == true and hub.config.UiVisible == false
    pressKey("RightControl")                        -- the hide key
    local reopened = win.Root.Visible == true and hub.config.UiVisible == true
    check("gui · minimise collapses and restores the body", collapsed and restored,
        tostring(collapsed) .. "/" .. tostring(restored))
    check("gui · close hides, the hide key reopens", hidden and reopened,
        tostring(hidden) .. "/" .. tostring(reopened))
else
    check("gui · minimise collapses and restores the body", false, "no chrome")
    check("gui · close hides, the hide key reopens", false, "no chrome")
end

-- back to the first tab so the rest of the run starts where a player would
pcall(function() hub.tabs[1].Select() end)
"""

CHECKS_RUN = r"""local hub = _G.SkillHubRivals
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end

local character = _G.__LOCAL_PLAYER.Character
local humanoid = character:FindFirstChildOfClass("Humanoid")
local root = character:FindFirstChild("HumanoidRootPart")
local props = rawget(humanoid, "__props")

-- let the shot window empty and the workers settle
for index = 1, 14 do pump(0.1) end

-- ── fire cadence ─────────────────────────────────────────────────────────────
hub.config.FireRateCap, hub.config.AcShotRateLimit = 5, 10
hub.config.AcSafeMode, hub.config.HumanizeFire = true, false
local shotsBefore, blockedBefore = hub.state.shots, hub.state.shotsBlocked
local clicks = 0
for index = 1, 12 do
    if hub.fire() then clicks = clicks + 1 end
end
check("fire cadence caps the burst", clicks <= 5, clicks .. " clicks in one second")
check("cadence counted the refusals", hub.state.shotsBlocked > blockedBefore,
    tostring(hub.state.shotsBlocked - blockedBefore) .. " held")
check("shots counted exactly", hub.state.shots - shotsBefore == clicks, tostring(hub.state.shots - shotsBefore))

-- ── reload ───────────────────────────────────────────────────────────────────
local ammo = character:FindFirstChild("Assault Rifle"):FindFirstChild("Ammo")
ammo.Value = 0
hub.state.lastReload = 0
local reloaded = hub.reload()
check("empty magazine reaches the reload remote", reloaded == true and _G.__HARNESS_LAST_FIRE == "Reload",
    tostring(_G.__HARNESS_LAST_FIRE))
ammo.Value = 30

-- ── movement ─────────────────────────────────────────────────────────────────
hub.config.WalkSpeedEnabled, hub.config.WalkSpeed = true, 200
hub.config.AcCamouflage = true
hub.acArm()
hub.config.AcSafeMode, hub.config.AcSpeedCeiling = true, 60
for index = 1, 8 do pump(0.05) end
local rawSpeed = rawget(props, "WalkSpeed")
check("safe mode clamps the speed write", rawSpeed == 60, tostring(rawSpeed))
check("camouflage hides the real value", humanoid.WalkSpeed == 16, tostring(humanoid.WalkSpeed))

hub.config.FlyEnabled = true
for index = 1, 8 do pump(0.05) end
local body = root:FindFirstChild("BodyVelocity")
check("fly attaches a body velocity", hub.flying() == true and body ~= nil)
check("body has no branded name", body ~= nil and body.Name == "BodyVelocity")
hub.config.FlyEnabled = false
for index = 1, 8 do pump(0.05) end
check("fly detaches cleanly", hub.flying() == false and root:FindFirstChild("BodyVelocity") == nil)

local head = character:FindFirstChild("Head")
hub.config.Noclip = true
for index = 1, 6 do pump(0.05) end
check("noclip disables collisions", head.CanCollide == false)
hub.config.Noclip = false
for index = 1, 6 do pump(0.05) end
check("noclip restores collisions", head.CanCollide == true)

root.CFrame = _G.CFrame.new(_G.Vector3.new(0, -300, 0))
for index = 1, 8 do pump(0.05) end
check("anti void rescues the character", root.Position.Y > -180, string.format("%.1f", root.Position.Y))

-- ── chat, queue, leave, hop ──────────────────────────────────────────────────
hub.state.lastChat = 0
check("chat reaches TextChatService", hub.say("gg") == true and _G.__HARNESS_LAST_CHAT == "gg",
    tostring(_G.__HARNESS_LAST_CHAT))
hub.state.inMatch, hub.state.lastQueue = false, -100
check("queue reaches the queue remote", hub.queue() == true and _G.__HARNESS_LAST_FIRE == "QueueMatch",
    tostring(_G.__HARNESS_LAST_FIRE))
check("leave reaches the leave remote", hub.leave() == true, tostring(_G.__HARNESS_LAST_FIRE))
hub.state.lastHop = -100
local hopsBefore = _G.__HARNESS_TELEPORTS or 0
check("server hop asks TeleportService to move", hub.hop() == true)
check("teleport counted", (_G.__HARNESS_TELEPORTS or 0) > hopsBefore)

-- ── vision toggles ───────────────────────────────────────────────────────────
local lighting = _G.game:GetService("Lighting")
hub.config.Fullbright = true
hub.bright()
check("fullbright raises the brightness", lighting.Brightness == 3, tostring(lighting.Brightness))
hub.config.Fullbright = false
hub.bright()
check("fullbright restores the brightness", lighting.Brightness == 1, tostring(lighting.Brightness))

local flash = _G.__LOCAL_PLAYER:FindFirstChild("PlayerGui"):FindFirstChild("FlashOverlay")
hub.antiFlash()
check("anti flash hides the overlay", flash.Visible == false)
local smoke = _G.workspace:FindFirstChild("SmokeCloud")
hub.smoke()
check("smoke is made invisible", smoke.Transparency == 1, tostring(smoke.Transparency))
local emitter = _G.workspace:FindFirstChild("MuzzleFlash"):FindFirstChild("Sparks")
hub.strip()
check("vfx pass disables emitters", emitter.Enabled == false)

hub.config.CameraDistance = 40
for index = 1, 4 do pump(0.05) end
check("camera zoom limit is written", _G.__LOCAL_PLAYER.CameraMaxZoomDistance == 40,
    tostring(_G.__LOCAL_PLAYER.CameraMaxZoomDistance))
hub.config.CameraDistance = 0

-- ── paced travel ─────────────────────────────────────────────────────────────
hub.config.AcStepSize, hub.config.AcStepDelay = 12, 0.02
root.CFrame = _G.CFrame.new(_G.Vector3.new(0, 3, 0))
_G.__MAX_STEP = 0
hub.teleportTo(_G.__HARNESS_PLAYERS[2])
for index = 1, 80 do pump(0.03) end
check("teleport is paced, never a single jump", (_G.__MAX_STEP or 0) <= 24,
    string.format("%.1f studs max step", _G.__MAX_STEP or 0))

hub.travel(_G.Vector3.new(200, 3, 0), 20)
for index = 1, 120 do pump(0.03) end
local arrived = (root.Position - _G.Vector3.new(200, 3, 0)).Magnitude
check("paced travel arrives", arrived < 4, string.format("%.1f studs off", arrived))
"""

CHECKS_MATCH = r"""-- The part the lobby harness never reached: RIVALS replaces the camera when a
-- duel finishes loading and hands out a new character on every spawn.
local hub = _G.SkillHubRivals
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end
local function turnedDegrees(a, b)
    return math.deg(math.acos(math.clamp(a:Dot(b), -1, 1)))
end

local camera = _G.workspace.CurrentCamera
camera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(0, 10, -100))
hub.config.AimEnabled = true
hub.config.AimMethod = "Camera"
hub.config.AimVisibleOnly = false
hub.config.AimTeamCheck = true
hub.config.AimSmooth = 0.45

-- ── the cone ───────────────────────────────────────────────────────────────
local forward = camera.CFrame
camera.CFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + Vector3.new(0, 0, 1))
local behind = hub.pickTarget()
check("aim cone refuses a target behind the camera", behind == nil, behind and behind.name or "nil")
camera.CFrame = forward
local ahead = hub.pickTarget()
check("aim cone accepts the enemy in front", ahead ~= nil, ahead and ahead.name or "nil")

-- ── the game swaps CurrentCamera on match load ─────────────────────────────
local oldCamera = camera
local oldLook = oldCamera.CFrame.LookVector
local matchCamera = Instance.new("Camera")
matchCamera.Name = "MatchCamera"
matchCamera.ViewportSize = oldCamera.ViewportSize
matchCamera.FieldOfView = oldCamera.FieldOfView
matchCamera.CFrame = oldCamera.CFrame
matchCamera.Parent = _G.workspace
_G.workspace.CurrentCamera = matchCamera

local target = hub.pickTarget()
check("a target is still picked after the swap", target ~= nil, target and target.name or "nil")
local before = matchCamera.CFrame.LookVector
hub.stepAim(target, 0.016)
local stepTurn = turnedDegrees(before, matchCamera.CFrame.LookVector)
check("aim turns the camera the game is rendering", stepTurn > 0.5, string.format("%.2f deg", stepTurn))
check("the replaced camera is left untouched",
    oldCamera.CFrame.LookVector:Dot(oldLook) > 0.99999,
    string.format("%.6f", oldCamera.CFrame.LookVector:Dot(oldLook)))

-- and the worker does it on its own, without a manual call: the camera starts
-- a few degrees off the enemy, inside the cone, and the loop has to close it
local loopStart = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(10, 16, -40))
matchCamera.CFrame = loopStart
local loopBefore = matchCamera.CFrame.LookVector
for _ = 1, 14 do pump(0.05) end
local loopTurn = turnedDegrees(loopBefore, matchCamera.CFrame.LookVector)
check("the combat loop aims through the swapped camera", loopTurn > 3,
    string.format("%.1f deg in 0.7 s", loopTurn))

-- ── a respawn: health zero, old model gone, new model from CharacterAdded ──
local player = _G.__LOCAL_PLAYER
local oldCharacter = player.Character
local oldHumanoid = oldCharacter:FindFirstChildOfClass("Humanoid")
local savedCamo = hub.config.AcCamouflage
hub.config.AcCamouflage = false
hub.config.WalkSpeedEnabled = true
hub.config.WalkSpeed = 30
hub.config.AcSafeMode = true
hub.config.AcSpeedCeiling = 60
if oldHumanoid then oldHumanoid.Health = 0 end
oldCharacter.Parent = nil
local newCharacter, newHumanoid = _G.__SPAWN_CHARACTER(player, "MatchCharacter", Vector3.new(0, 3, 0))
for _ = 1, 10 do pump(0.05) end

check("the hub rebinds to the new body", hub.state.boundCharacter == newCharacter,
    tostring(hub.state.boundCharacter and hub.state.boundCharacter.Name))
check("movement writes reach the new humanoid", newHumanoid and newHumanoid.WalkSpeed == 30,
    newHumanoid and tostring(newHumanoid.WalkSpeed) or "no humanoid")
matchCamera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(12, 8, -40))
hub.config.AimVisibleOnly = true
hub.scan(true)
local seenAfterRespawn = hub.pickTarget()
hub.config.AimVisibleOnly = false
check("a visible target is still found after the respawn", seenAfterRespawn ~= nil,
    seenAfterRespawn and seenAfterRespawn.name or "nil")
check("the character hook fired", hub.ac.characterHook == true, tostring(hub.ac.characterHook))

matchCamera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(0, 10, -100))
local respawnBefore = matchCamera.CFrame.LookVector
for _ = 1, 14 do pump(0.05) end
local respawnTurn = turnedDegrees(respawnBefore, matchCamera.CFrame.LookVector)
check("aim re-engages after the respawn", respawnTurn > 1,
    string.format("%.1f deg in 0.7 s", respawnTurn))
check("no worker needed rescuing", (hub.state.perf.loopErrors or 0) == 0,
    tostring(hub.state.perf.loopErrors or 0) .. " recovered error(s)")
check("the error log is still empty", #(_G.__SkillHubErrorLog or {}) == 0,
    table.concat(_G.__SkillHubErrorLog or {}, " | "):sub(1, 240))

hub.config.AcCamouflage = savedCamo
"""

CHECKS_AFTER = r"""local hub = _G.SkillHubRivals
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end

local AC = hub.ac

-- ── anti-cheat layers ────────────────────────────────────────────────────────
check("six layers report armed",
    AC.armed.detectors == true and AC.armed.namecall == true
    and AC.armed.camouflage == true and AC.armed.limits == true
    and AC.armed.pacing == true and AC.armed.rate == true,
    tostring(AC.armed.detectors) .. "/" .. tostring(AC.armed.namecall) .. "/"
    .. tostring(AC.armed.camouflage) .. "/" .. tostring(AC.armed.limits))
check("detector scripts disabled", AC.detectorCount >= 3, tostring(AC.detectorCount) .. " scripts")

-- silent aim must actually rewrite a direction argument on the shoot remote
local shootRemote = hub.findRemote({ "shoot" })
hub.config.AimMethod, hub.config.AimEnabled = "Silent", true
hub.state.target = hub.pickTarget()
local targetNow = hub.state.target
if shootRemote and targetNow then
    local wrong = _G.CFrame.lookAt(_G.Vector3.new(0, 10, 0), _G.Vector3.new(0, 10, 100))
    shootRemote:FireServer(wrong)
    local passedArgs = _G.__HARNESS_LAST_ARGS
    local rewritten = passedArgs and passedArgs[1]
    local wanted = (targetNow.position - _G.Vector3.new(0, 10, 0)).Unit
    check("silent aim rewrites the direction argument",
        rewritten ~= nil and rewritten.LookVector ~= nil
        and rewritten.LookVector:Dot(wanted) > 0.99,
        rewritten and rewritten.LookVector and string.format("%.3f", rewritten.LookVector:Dot(wanted)) or "nil")
else
    check("silent aim rewrites the direction argument", false, "no shoot remote or target")
end
hub.config.AimMethod, hub.config.AimEnabled = "Camera", false

local report = _G.__REPORT_REMOTE
local firedBefore = _G.__HARNESS_FIRED or 0
local blockedBefore = AC.blocked
report:FireServer("TestPlayer")
check("report remote is dropped", (_G.__HARNESS_FIRED or 0) == firedBefore,
    tostring((_G.__HARNESS_FIRED or 0) - firedBefore) .. " reached the server")
check("filter counted the drop", AC.blocked > blockedBefore, tostring(AC.blocked - blockedBefore) .. " dropped")

local safe = _G.__SAFE_REMOTE
local safeBefore = _G.__HARNESS_FIRED or 0
safe:FireServer()
check("ordinary remotes still pass", (_G.__HARNESS_FIRED or 0) > safeBefore)

local kicksBefore, acKicksBefore = _G.__HARNESS_KICKS or 0, AC.kicks
_G.__LOCAL_PLAYER:Kick("test")
check("kick is swallowed", (_G.__HARNESS_KICKS or 0) == kicksBefore and AC.kicks > acKicksBefore,
    "kicks seen=" .. tostring(AC.kicks))

AC.lastLimitScan = 0
hub.config.AcSpeedLimiter, hub.config.AcSpeedCeiling = true, 60
hub.acArm()
check("limit fields clamped in Lua tables",
    _G.__GC[2].MaxWalkSpeed <= 60 and _G.__GC[2].SpeedLimit <= 60,
    tostring(_G.__GC[2].MaxWalkSpeed) .. " / " .. tostring(_G.__GC[2].SpeedLimit))

hub.config.NoRecoil, hub.config.NoSpread = true, true
local patched = hub.patchWeapons()
check("recoil and spread zeroed", patched >= 2 and _G.__GC[1].Recoil == 0 and _G.__GC[1].Spread == 0,
    tostring(patched) .. " fields, recoil=" .. tostring(_G.__GC[1].Recoil))
hub.config.NoRecoil, hub.config.NoSpread = false, false

hub.config.AcRemoteRateLimit = 2
for index = 1, 12 do pump(0.1) end
local rateBefore = _G.__HARNESS_FIRED or 0
for index = 1, 6 do hub.fireRemote(safe) end
local passed = (_G.__HARNESS_FIRED or 0) - rateBefore
check("remote rate limiter holds the extras", passed <= 2, passed .. " of 6 passed")
hub.config.AcRemoteRateLimit = 20

-- ── every switch, on then off ───────────────────────────────────────────────
-- alt-only is on by default and refuses the loud toys; the stress run wants
-- them on, so it is lifted for the duration and put back afterwards
local altOnly = hub.config.AltOnlyMode
hub.config.AltOnlyMode = false
local driven = 0
for _, tab in ipairs(hub.tabs) do
    for _, api in ipairs(tab.toggles or {}) do
        if pcall(api.Set, true, false) then driven = driven + 1 end
    end
end
-- thirty virtual seconds with every feature live at once
for index = 1, 60 do pump(0.5) end
local errorsDuringStress = #_G.__HARNESS_ERRORS
for _, tab in ipairs(hub.tabs) do
    for _, api in ipairs(tab.toggles or {}) do pcall(api.Set, false, false) end
end
for index = 1, 6 do pump(0.05) end
hub.config.AltOnlyMode = altOnly
check("every switch drives on and off", driven >= 60, driven .. " switches")
check("thirty seconds with everything on stays clean", errorsDuringStress == 0,
    tostring(errorsDuringStress) .. " harness errors")

-- ── panic ───────────────────────────────────────────────────────────────────
local okPanic = hub.panic()
check("panic clears aim, trigger and flight",
    okPanic == true and hub.config.AimEnabled == false and hub.config.TriggerBot == false
    and hub.config.FlyEnabled == false and hub.flying() == false)
check("panic clears the esp", hub.espCount() == 0, tostring(hub.espCount()))

-- ── the hub's own self-test ─────────────────────────────────────────────────
local passedChecks, totalChecks = hub.selfTest()
check("built-in self-test", totalChecks >= 30 and passedChecks == totalChecks,
    tostring(passedChecks) .. "/" .. tostring(totalChecks))

local log = _G.__SkillHubErrorLog
check("no entries in the error log", type(log) ~= "table" or #log == 0,
    type(log) == "table" and tostring(#log) or "none")

-- ── the window must survive what Roblox does to GUIs ───────────────────────
local win = hub.window()
check("window has ResetOnSpawn off",
    win ~= nil and win.Screen ~= nil and win.Screen.ResetOnSpawn == false,
    win and win.Screen and tostring(win.Screen.ResetOnSpawn) or "no window")
check("window lists nine tabs", win ~= nil and win.Root ~= nil
    and #win.Root:GetDescendants() > 300, win and win.Root and #win.Root:GetDescendants() or "no window")

-- ── hybrid aim: the mouse delta follows the angle, not the screen distance ──
local camera = _G.workspace.CurrentCamera
hub.scan(true)
hub.config.AimEnabled = true
hub.config.AimMethod = "Hybrid"
hub.config.AimTeamCheck = true
hub.config.AimHumanize = false
hub.config.AimSmooth = 0
hub.config.AimStepLimit = 90
hub.config.AimMouseSensitivity = 0.5
camera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(0, 10, -100))
local aimTarget = hub.pickTarget()
hub.state.target = aimTarget
if aimTarget then
    local before = camera.CFrame.LookVector
    hub.stepAim(aimTarget, 0.016)
    local px, py = hub.lastAimPixels()
    local point = hub.aimPoint()
    local want = (point - camera.CFrame.Position).Unit
    local angle = math.deg(math.acos(math.clamp(before:Dot(want), -1, 1)))
    local sent = math.sqrt(px * px + py * py)
    check("hybrid sends mouse pixels for the angle",
        math.abs(sent - angle / 0.5) <= math.max(1.5, angle * 0.2),
        string.format("%.1f px for %.1f°", sent, angle))
    check("hybrid reports the mouse method", hub.method() == "mouse", tostring(hub.method()))
else
    check("hybrid sends mouse pixels for the angle", false, "no target")
    check("hybrid reports the mouse method", false, "no target")
end

-- the harness mouse does not move the camera, which is exactly what an
-- unlocked cursor looks like: three misses must switch to camera writes
for _ = 1, 6 do pump(0.02) end
check("mouse that does not turn the view falls back", hub.fallbacks() >= 1,
    tostring(hub.fallbacks()) .. " fallbacks")
check("fallback reports the camera method", hub.method() == "camera", tostring(hub.method()))

-- ── the camera the game hands over after a match load ─────────────────────
local oldCamera = camera
local newCamera = _G.Instance.new("Camera")
newCamera.ViewportSize = _G.Vector2.new(1280, 720)
newCamera.Parent = _G.workspace
newCamera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(0, 10, -100))
_G.workspace.CurrentCamera = newCamera
hub.config.AimMethod = "Camera"
hub.config.AimSmooth = 0.5
pump(0.02)
local oldLook = oldCamera.CFrame.LookVector
local newLook = newCamera.CFrame.LookVector
if aimTarget then hub.stepAim(aimTarget, 0.016) end
check("aim writes to the camera the game is rendering",
    newCamera.CFrame.LookVector:Dot(newLook) < 0.9999 and oldCamera.CFrame.LookVector:Dot(oldLook) > 0.9999,
    string.format("new %.4f · old %.4f", newCamera.CFrame.LookVector:Dot(newLook), oldCamera.CFrame.LookVector:Dot(oldLook)))
_G.workspace.CurrentCamera = oldCamera

-- ── a match hands the player a new character ──────────────────────────────
local beforeChar = hub.character()
local newChar = _G.__SPAWN_CHARACTER(_G.__LOCAL_PLAYER, "MatchCharacter", Vector3.new(0, 3, 0))
for _ = 1, 6 do pump(0.05) end
check("character rebinds when a match loads", hub.character() == newChar and beforeChar ~= newChar,
    tostring(hub.character() and hub.character().Name))
check("the new body is alive", hub.alive() == true)
hub.scan(true)
local respawnTarget = hub.pickTarget()
check("aim finds a target after the swap", respawnTarget ~= nil,
    respawnTarget and respawnTarget.name or "none")

-- ── the render-step driver is real ─────────────────────────────────────────
hub.state.target = respawnTarget
camera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(0, 10, -100))
local beforeRender = camera.CFrame.LookVector
for _ = 1, 6 do pump(0.02) end
local renderTurn = math.deg(math.acos(math.clamp(beforeRender:Dot(camera.CFrame.LookVector), -1, 1)))
check("render-step driver is bound", hub.renderBound() == true, tostring(hub.renderBound()))
check("aim turns the camera on the render step", renderTurn > 1,
    string.format("%.1f deg over 6 frames", renderTurn))

-- ── the doctor answers ────────────────────────────────────────────────────
local report = hub.doctor()
check("doctor prints a report", type(report) == "string" and string.find(report, "window", 1, true) ~= nil
    and string.find(report, "tabs", 1, true) ~= nil and string.find(report, "aim method", 1, true) ~= nil,
    type(report))

-- ── one whole match start in a single pass: the game swaps the camera, the ──
-- local body and every enemy body before the first frame of the round
_G.workspace.CurrentCamera = newCamera
local roster = _G.__HARNESS_PLAYERS
local freshEnemy = _G.__SPAWN_CHARACTER(roster[2], "ArenaEnemy", Vector3.new(-14, 3, -36))
freshEnemy:SetAttribute("Team", "Red")
local freshLocal = _G.__SPAWN_CHARACTER(_G.__LOCAL_PLAYER, "ArenaLocal", Vector3.new(0, 3, 0))
freshLocal:SetAttribute("Team", "Blue")
newCamera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(0, 10, -100))
hub.config.AimTeamCheck = true
hub.config.AimMethod = "Camera"
hub.config.AimEnabled = true
for _ = 1, 8 do pump(0.05) end
hub.scan(true)
local matchTarget = hub.pickTarget()
check("match start finds the respawned enemy", matchTarget ~= nil and matchTarget.name == "EnemyOne",
    matchTarget and matchTarget.name or "none")
if matchTarget then
    -- look 30-odd degrees to the left of the crosshair: the enemy is still in
    -- the cone, but the step has room to turn
    newCamera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(-40, 10, -60))
    hub.state.target = matchTarget
    local before = newCamera.CFrame.LookVector
    hub.stepAim(matchTarget, 0.016)
    local turned = math.deg(math.acos(math.clamp(before:Dot(newCamera.CFrame.LookVector), -1, 1)))
    check("match start turns the new camera", turned > 0.5, string.format("%.1f°", turned))
else
    check("match start turns the new camera", false, "no target")
end
_G.workspace.CurrentCamera = oldCamera

-- ── the aim rate limit switch owns the per-frame ceiling ───────────────────
hub.config.AimMethod = "Camera"
hub.config.AimSmooth = 0
hub.config.AimStepLimit = 3
hub.config.AcAimRateLimit = true
hub.config.AimEnabled = true
hub.scan(true)
local rateTarget = hub.pickTarget()
if rateTarget then
    camera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(-30, 10, -80))
    local from = camera.CFrame.LookVector
    hub.stepAim(rateTarget, 0.016)
    local capped = math.deg(math.acos(math.clamp(from:Dot(camera.CFrame.LookVector), -1, 1)))
    check("aim step ceiling holds", capped <= 3.6, string.format("%.1f°", capped))

    hub.config.AcAimRateLimit = false
    camera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(-30, 10, -80))
    from = camera.CFrame.LookVector
    hub.stepAim(rateTarget, 0.016)
    local uncapped = math.deg(math.acos(math.clamp(from:Dot(camera.CFrame.LookVector), -1, 1)))
    check("aim rate limit switch removes the ceiling", uncapped > 4, string.format("%.1f°", uncapped))
    hub.config.AcAimRateLimit = true
else
    check("aim step ceiling holds", false, "no target")
    check("aim rate limit switch removes the ceiling", false, "no target")
end

-- ── chat spam is paced by ChatDelay, not by the loop tick ──────────────────
hub.config.ChatSpam, hub.config.ChatMessage = true, "gg"
hub.config.ChatDelay = 6
hub.state.lastChat = _G.__CLOCK.now - 10
_G.__HARNESS_CHAT = 0
for _ = 1, 10 do pump(0.2) end
local firstChats = _G.__HARNESS_CHAT or 0
check("chat spam sends once, not every tick", firstChats == 1, tostring(firstChats))
for _ = 1, 40 do pump(0.2) end
local totalChats = _G.__HARNESS_CHAT or 0
check("chat spam honours ChatDelay", totalChats == 2, tostring(totalChats))
hub.config.ChatSpam = false

-- ── with the speed hack off the game keeps its own speed ──────────────────
local liveBody = hub.character()
local liveHumanoid = liveBody and liveBody:FindFirstChildOfClass("Humanoid")
if liveHumanoid then
    hub.config.WalkSpeedEnabled = false
    for _ = 1, 4 do pump(0.05) end
    liveHumanoid.WalkSpeed = 22      -- the game's own modifier, e.g. Paintball
    for _ = 1, 8 do pump(0.05) end
    check("no speed hack leaves the game's speed alone", liveHumanoid.WalkSpeed == 22,
        tostring(liveHumanoid.WalkSpeed))
else
    check("no speed hack leaves the game's speed alone", false, "no humanoid")
end

-- ── auto scope presses the button once, not fifty times a second ──────────
hub.scan(true)
local scopeTarget = hub.pickTarget()
if scopeTarget then
    hub.config.AimEnabled = true
    hub.config.AutoScope = true
    hub.state.target = scopeTarget
    _G.__SCOPE_PRESS, _G.__SCOPE_RELEASE = 0, 0
    for _ = 1, 10 do pump(0.05) end
    check("auto scope presses once", _G.__SCOPE_PRESS == 1, tostring(_G.__SCOPE_PRESS))
    hub.config.AutoScope = false
    for _ = 1, 4 do pump(0.05) end
    check("auto scope releases once", _G.__SCOPE_RELEASE == 1, tostring(_G.__SCOPE_RELEASE))
else
    check("auto scope presses once", false, "no target")
    check("auto scope releases once", false, "no target")
end

-- ── the camera FOV override is off by default and restores what it took ────
local fovBefore = camera.FieldOfView
hub.config.CameraFov = 0
for _ = 1, 3 do pump(0.4) end
check("camera FOV is left alone by default", camera.FieldOfView == fovBefore, tostring(camera.FieldOfView))
hub.config.CameraFov = 100
for _ = 1, 3 do pump(0.4) end
check("camera FOV override applies", camera.FieldOfView == 100, tostring(camera.FieldOfView))
hub.config.CameraFov = 0
for _ = 1, 3 do pump(0.4) end
check("camera FOV override restores", camera.FieldOfView == fovBefore, tostring(camera.FieldOfView))

-- ── panic undoes the one-shot switches too ────────────────────────────────
local gravityBefore = _G.workspace.Gravity
hub.config.LowGravity = true
hub.gravity(true)
for _ = 1, 3 do pump(0.4) end
check("low gravity applies", _G.workspace.Gravity == 80, tostring(_G.workspace.Gravity))
hub.panic()
check("panic restores gravity", math.abs(_G.workspace.Gravity - gravityBefore) < 0.01,
    tostring(_G.workspace.Gravity))

-- ── every worker is alive, and a throwing frame cannot kill one ───────────
for _ = 1, 60 do pump(0.05) end          -- three virtual seconds
local beats = hub.state.beats
local missing = {}
for _, name in ipairs({ "combat", "esp", "movement", "utility", "fun", "staff", "recoil", "fall", "kick", "aim" }) do
    local at = beats[name]
    if not at or (_G.__CLOCK.now - at) > 5 then missing[#missing + 1] = name end
end
check("every worker is still beating", #missing == 0,
    #missing == 0 and "10/10" or ("stalled: " .. table.concat(missing, ", ")))

local loopErrorsBefore = hub.state.perf.loopErrors or 0
hub.protect("harness fault", function() error("injected failure") end)
local survived = (hub.state.perf.loopErrors or 0) == loopErrorsBefore + 1
local errorLog = _G.__SkillHubErrorLog
if errorLog then for index = #errorLog, 1, -1 do errorLog[index] = nil end end
check("a throwing frame is contained and logged", survived, tostring(loopErrorsBefore) .. " → "
    .. tostring(hub.state.perf.loopErrors or 0))

-- ── the safe-mode panel, for when the window cannot be built at all ────────
local fallbackScreen = hub.fallback("harness check")
check("safe-mode panel builds", fallbackScreen ~= nil and #fallbackScreen:GetDescendants() >= 10,
    fallbackScreen and #fallbackScreen:GetDescendants() .. " instances" or "nil")
if fallbackScreen then pcall(function() fallbackScreen:Destroy() end) end

-- ── unload ─────────────────────────────────────────────────────────────────
local destroyed = hub.destroy()
for _ = 1, 4 do pump(0.05) end
local guiGone = true
for _, child in ipairs(_G.gethui():GetChildren()) do
    if child.Name == "SkillHubRIVALS" then guiGone = false end
end
check("destroy removes the window and the export", destroyed == true and guiGone)
"""



def main() -> int:
    if not os.path.exists(HUB):
        print("hub not found at %s" % HUB)
        return 1
    source = io.open(HUB, encoding="utf-8").read()

    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.execute(PRELUDE)

    loader = runtime.eval("function(src) return task_spawn(function() local chunk, err = load(src, 'SkillHub.lua') if not chunk then error(err, 0) end local ok, result = xpcall(chunk, function(message) return debug.traceback(message, 1) end) if not ok then error(result, 0) end return result end) end")
    loader(source)
    boot_errors = [str(x) for x in runtime.eval("_G.__HARNESS_ERRORS").values()]
    if boot_errors:
        print("boot errors:")
        for line in boot_errors[:8]:
            print("   " + line)

    runtime.execute(CHECKS_BOOT)
    runtime.execute(CHECKS_GUI)
    runtime.execute(CHECKS_RUN)
    runtime.execute(CHECKS_MATCH)
    runtime.execute(CHECKS_AFTER)

    results = runtime.eval("_G.__RESULTS")
    scheduler_errors = [str(x) for x in runtime.eval("_G.__HARNESS_ERRORS").values()]
    failures = []
    for entry in results.values():
        label = str(entry["label"])
        ok = entry["ok"] is True or entry["ok"] == True
        detail = entry["detail"]
        detail = "" if detail is None else "  - " + str(detail)
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
    print("LOAD OK - the whole hub runs in a mocked Roblox")
    return 0


if __name__ == "__main__":
    sys.exit(main())
