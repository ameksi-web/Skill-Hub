#!/usr/bin/env python3
"""Boot the Free Blox Fruit hub for real in a mocked Roblox and drive it.

    /tmp/venv/bin/python tools/freeblox_test.py

The mock gives the hub a virtual clock, a coroutine scheduler (so its farm
loop really ticks), one shared instance metatable whose __namecall dispatch
emulates Roblox, real Vector3/CFrame/Color3 maths, a working file system for
the config, every service the hub touches, and a small Blox Fruits island: four
mobs (one boss), two chests with proximity prompts, a fruit lying on the
ground, a money drop and a quest NPC. The "server" only applies damage when the
player's own tool activates or the mouse clicks — the hub cannot do more than a
player can.

Checked: load · two tabs · nothing enabled at boot and nothing happens for six
virtual seconds · the scanner · auto farm travel and kills · boss mode · kill
aura · bring mobs · mob hitbox scaling and restore · auto skill · chests ·
fruit · drops · quest · paced travel under safe mode · save / load / autosave /
export / import / reset · the autoload-safe rule · all six themes rebuilding
the window with their own palette · UI scale · hide and panic keys · game
consumed keys ignored · every control in both tabs used · search · doctor ·
self-test · the theme dropdown · every palette complete · panic restoring a
    scaled hitbox · autosave-off · minimise / close · the config folder ·
    unload · a second boot with a saved config whose switches are all
true (theme restored, farm not started).
"""
import io, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
HUB = os.path.join(HERE, os.pardir, "Free Blox Fruit", "SkillHub.lua")

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


-- ═══════════════════════════════════════════════════════════════════════════
-- THE BLOX FRUITS WORLD — a small island, four mobs, two chests, a fruit,
-- a money drop and a quest NPC. The "server" only applies damage when the
-- player's own tool activates or the mouse clicks, which is exactly what the
-- hub is allowed to do.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── a real file system, so save / load / autosave are actually exercised ───
_G.__FS = {}
function _G.writefile(path, text) _G.__FS[path] = text return true end
function _G.readfile(path) return _G.__FS[path] end
function _G.isfile(path) return _G.__FS[path] ~= nil end
function _G.makefolder(path) _G.__FS[path] = _G.__FS[path] or "" return true end
function _G.delfile(path) _G.__FS[path] = nil return true end
function _G.getclipboard() return _G.__CLIPBOARD or "" end

-- ── the local player and its services ─────────────────────────────────────
local myPlayers = makeInstance("Players", "Players")
local localPlayer = makeInstance("Player", "TestPlayer")
localPlayer.UserId = 1
localPlayer.DisplayName = "TestPlayer"
localPlayer.Name = "TestPlayer"
local character, localHumanoid = humanoidModel("TestPlayerCharacter", 100, V3.new(0, 3, 0))
character.Parent = _G.workspace
localPlayer.Character = character
myPlayers.LocalPlayer = localPlayer
_G.__LOCAL_PLAYER = localPlayer
_G.__PLAYER_CHARACTER = character

local characterAdded = { listeners = {} }
function characterAdded:Connect(fn)
    table.insert(self.listeners, fn)
    return { Disconnect = function() end }
end
function characterAdded:Fire(newCharacter)
    for _, fn in ipairs(self.listeners) do pcall(fn, newCharacter) end
end
localPlayer.CharacterAdded = characterAdded

local myReplicated = makeInstance("Folder", "ReplicatedStorage")
local myTextChat = makeInstance("TextChatService", "TextChatService")
local myPlayerGui = makeInstance("PlayerGui", "PlayerGui")
myPlayerGui.Parent = localPlayer
_G.__PLAYER_GUI = myPlayerGui

local myServices = {
    Players = myPlayers, Workspace = _G.workspace,
    Lighting = makeInstance("Lighting", "Lighting"),
    CoreGui = makeInstance("CoreGui", "CoreGui"),
    ReplicatedStorage = myReplicated,
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
    TextChatService = myTextChat,
}
myServices.Lighting.Brightness = 1
myServices.Lighting.ClockTime = 14
myServices.TweenService.Create = function(_, instance, info, goal)
    return {
        Play = function() for key, value in pairs(goal) do pcall(function() instance[key] = value end) end end,
        Cancel = function() end,
        Completed = { Connect = function() end },
    }
end
myServices.UserInputService.IsKeyDown = function() return false end
myServices.UserInputService.InputBegan = signalOf(myServices.UserInputService, "InputBegan")
myServices.UserInputService.InputChanged = signalOf(myServices.UserInputService, "InputChanged")
myServices.UserInputService.InputEnded = signalOf(myServices.UserInputService, "InputEnded")
myServices.CollectionService.GetTags = function() return {} end
myServices.CollectionService.HasTag = function() return false end
myServices.HttpService.JSONEncode = function() return "{}" end
myServices.HttpService.JSONDecode = function() return {} end
myServices.SoundService.PlayLocalSound = function() end
myServices.Stats.Network = makeInstance("Network", "Network")
myServices.Stats.Network.ServerStatsItem = { ["Data Ping"] = { GetValue = function() return 42 end } }

_G.game.GetService = function(_, name) return myServices[name] or makeInstance(name, name) end
_G.game.PlaceId = 2753915549
_G.game.JobId = "blox-fruits-test"
_G.game.HttpGet = function() return "{}" end
_G.game.CoreGui = myServices.CoreGui
_G.__SERVICES = myServices

function METHODS.SendKeyEvent(self, down, key)
    if down then
        _G.__KEYS_SENT = (_G.__KEYS_SENT or 0) + 1
        _G.__LAST_KEY = key
    end
end

-- ── camera ─────────────────────────────────────────────────────────────────
local myCamera = makeInstance("Camera", "Camera")
myCamera.ViewportSize = { X = 1280, Y = 720 }
myCamera.CFrame = CFrame_new(V3.new(0, 8, 0), V3.new(0, 8, -40))
myCamera.FieldOfView = 70
myCamera.Parent = _G.workspace
_G.workspace.CurrentCamera = myCamera
_G.RaycastParams = { new = function() return { FilterType = nil, FilterDescendantsInstances = {} } end }

-- ── the local player's bag ────────────────────────────────────────────────
local backpack = makeInstance("Backpack", "Backpack")
backpack.Parent = localPlayer
local combat = makeInstance("Tool", "Combat")
combat.ToolTip = "Melee"
local combatHandle = makePart("Handle", V3.new(0, 3, 0), combat)
combat.Parent = backpack
local sword = makeInstance("Tool", "Katana")
sword.ToolTip = "Sword"
makePart("Handle", V3.new(0, 3, 0), sword)
sword.Parent = backpack

-- ── mobs ───────────────────────────────────────────────────────────────────
_G.__MOBS = {}
local function spawnMob(name, health, position)
    local model, humanoid = humanoidModel(name, health, position)
    model.Parent = _G.workspace
    _G.__MOBS[#_G.__MOBS + 1] = model
    return model, humanoid
end
local banditOne, banditOneHum = spawnMob("Bandit", 60, V3.new(0, 3, -12))
local banditTwo, banditTwoHum = spawnMob("Bandit", 60, V3.new(7, 3, -17))
local monkey, monkeyHum = spawnMob("Monkey", 40, V3.new(-18, 3, -9))
local boss, bossHum = spawnMob("Gorilla Boss", 600, V3.new(0, 3, -70))

-- ── chests with a real proximity prompt ───────────────────────────────────
_G.__CHESTS_OPENED = 0
local function spawnChest(position)
    local model = makeInstance("Model", "Chest")
    local part = makePart("ChestPart", position, model)
    model.PrimaryPart = part
    local prompt = makeInstance("ProximityPrompt", "Open")
    prompt.ObjectText = "Chest"
    prompt.ActionText = "Open"
    prompt.Parent = model
    model.Parent = _G.workspace
    return model
end
local chestOne = spawnChest(V3.new(5, 3, -14))
local chestTwo = spawnChest(V3.new(-9, 3, -19))
_G.__CHESTS = { chestOne, chestTwo }

-- ── a fruit on the ground (Blox Fruits spawns them as Tools) ──────────────
local fruitTool = makeInstance("Tool", "Dragon Fruit")
local fruitHandle = makePart("Handle", V3.new(10, 3, -25), fruitTool)
fruitTool.Parent = _G.workspace
_G.__FRUIT = fruitTool

-- ── a money drop ──────────────────────────────────────────────────────────
local money = makePart("Money", V3.new(-6, 3, -8))
money.Parent = _G.workspace
_G.__MONEY = money

-- ── the quest NPC ─────────────────────────────────────────────────────────
_G.__QUESTS = 0
local questNpc = makeInstance("Model", "Quest Giver")
local questPart = makePart("Torso", V3.new(2, 3, -5), questNpc)
questNpc.PrimaryPart = questPart
local questPrompt = makeInstance("ProximityPrompt", "Quest")
questPrompt.ObjectText = "Quest Giver"
questPrompt.ActionText = "Talk"
questPrompt.Parent = questNpc
questNpc.Parent = _G.workspace
_G.__QUEST_NPC = questNpc

_G.__HARNESS_PLAYERS = { _G.__LOCAL_PLAYER }

function _G.__SPAWN_DROP(name, x, y, z)
    local part = makePart(name, V3.new(x, y, z))
    part.Parent = _G.workspace
    return part
end

function _G.__CLEAR_MOBS()
    for _, model in ipairs(_G.__MOBS) do model.Parent = nil end
end

function _G.__SPAWN_MOB(name, health, x, y, z)
    local model = humanoidModel(name, health, V3.new(x, y, z))
    model.Parent = _G.workspace
    _G.__MOBS[#_G.__MOBS + 1] = model
    return model
end

-- ── the "server": damage, death, pickups, prompts ─────────────────────────
local function aliveMobs()
    local out = {}
    for _, model in ipairs(_G.__MOBS) do
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid and (tonumber(humanoid.Health) or 0) > 0 and model.Parent ~= nil then
            out[#out + 1] = model
        end
    end
    return out
end

local function localRoot()
    local current = _G.__LOCAL_PLAYER.Character
    return current and current:FindFirstChild("HumanoidRootPart") or nil
end

function _G.__HARNESS_DAMAGE(amount)
    local root = localRoot()
    if not root then return 0 end
    local best, bestDistance = nil, math.huge
    for _, model in ipairs(aliveMobs()) do
        local mobRoot = model:FindFirstChild("HumanoidRootPart")
        if mobRoot then
            local dx = mobRoot.Position.X - root.Position.X
            local dz = mobRoot.Position.Z - root.Position.Z
            local distance = math.sqrt(dx * dx + dz * dz)
            -- a scaled hitbox is easier to hit: use the model's own root size
            local reach = 14 + math.max(0, (mobRoot.Size and mobRoot.Size.X or 2) - 2) * 2
            if distance <= reach and distance < bestDistance then
                best, bestDistance = model, distance
            end
        end
    end
    if not best then return 0 end
    local humanoid = best:FindFirstChildOfClass("Humanoid")
    humanoid.Health = math.max(0, (tonumber(humanoid.Health) or 0) - amount)
    _G.__LAST_DAMAGED = best.Name
    if humanoid.Health <= 0 then
        _G.__KILLED = (_G.__KILLED or 0) + 1
        best.Parent = nil
    end
    return amount
end

function _G.mouse1click()
    _G.__HARNESS_CLICKS = (_G.__HARNESS_CLICKS or 0) + 1
    _G.__HARNESS_DAMAGE(8)
end

function _G.fireproximityprompt(prompt)
    _G.__HARNESS_PROMPTS = (_G.__HARNESS_PROMPTS or 0) + 1
    if not prompt then return false end
    local model = rawget(prompt, "__parent")
    if model and model.Name == "Chest" then
        _G.__CHESTS_OPENED = _G.__CHESTS_OPENED + 1
        model.Parent = nil
        return true
    end
    if model and model.Name == "Quest Giver" then
        _G.__QUESTS = _G.__QUESTS + 1
        return true
    end
    return true
end

-- a shot at the server's own tick: fruit and money are touch pickups
function _G.__SERVER_TICK(step)
    local root = localRoot()
    if not root then return end
    local function near(position, radius)
        local dx = position.X - root.Position.X
        local dy = position.Y - root.Position.Y
        local dz = position.Z - root.Position.Z
        return math.sqrt(dx * dx + dy * dy + dz * dz) <= radius
    end
    if _G.__FRUIT and _G.__FRUIT.Parent ~= nil then
        local handle = _G.__FRUIT:FindFirstChild("Handle")
        if handle and near(handle.Position, 5) then
            _G.__FRUIT.Parent = nil
            _G.__FRUITS_TAKEN = (_G.__FRUITS_TAKEN or 0) + 1
        end
    end
    -- touch pickups: anything the game leaves on the floor as money or loot
    for _, child in ipairs(_G.workspace:GetChildren()) do
        if child.ClassName == "Part" and child.Parent ~= nil then
            local name = string.lower(child.Name)
            if string.find(name, "money", 1, true) or string.find(name, "cash", 1, true)
                or string.find(name, "drop", 1, true) or string.find(name, "coin", 1, true) then
                if near(child.Position, 5) then
                    child.Parent = nil
                    _G.__MONEY_TAKEN = (_G.__MONEY_TAKEN or 0) + 1
                end
            end
        end
    end
end

-- ── one render/heartbeat pass for anything that binds to RunService ────────
do
    local run = myServices.RunService
    local function fire(bucket, step)
        if not bucket then return end
        for _, fn in ipairs(bucket.handlers) do pcall(fn, step) end
    end
    _G.__STEPPED = function(step)
        fire(rawget(run, "__signals").RenderStepped, step)
        fire(rawget(run, "__signals").Heartbeat, step)
        fire(rawget(run, "__signals").PreRender, step)
        if _G.__SERVER_TICK then _G.__SERVER_TICK(step) end
    end
end

for index = 1, 3 do pump(0.03) end

"""

CHECKS_BOOT = r"""-- ═══════════════════════════════════════════════════════════════════════════
-- BOOT — the file runs, the window is built, and nothing is enabled
-- ═══════════════════════════════════════════════════════════════════════════
local hub = _G.SkillHubFreeBloxFruit
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end

_G.__CONTROLS = {}
local function control(title)
    for _, entry in ipairs(hub.controls()) do
        if entry.title == title then return entry end
    end
    return nil
end
_G.__CONTROL = control
function _G.__SET(title, value)
    local entry = control(title)
    if entry and entry.api and entry.api.set then
        entry.api.set(value)
        return true
    end
    return false
end
function _G.__PUMP(seconds, step)
    step = step or 0.05
    local total = math.floor((seconds / step) + 0.5)
    for _ = 1, total do pump(step) end
end

check("the hub booted", hub ~= nil)
check("version", hub and hub.version == "v1.2", hub and hub.version)
check("two tabs, and only two", hub and #hub.tabs == 2,
    hub and table.concat(hub.tabTitles(), " / "))
check("the tabs are Auto Farm and Settings",
    hub and hub.tabTitles()[1] == "Auto Farm" and hub.tabTitles()[2] == "Settings",
    hub and table.concat(hub.tabTitles(), " / "))
check("controls registered", hub and #hub.controls() >= 25,
    hub and (#hub.controls() .. " controls") or "none")
check("the window is built", hub and hub.window() and hub.window().Root ~= nil)
check("the window has its own ScreenGui name",
    hub and hub.window().Screen.Name == "SkillHubFreeBloxFruit",
    hub and hub.window().Screen.Name)
check("no feature is enabled at boot", hub and hub.featuresOn() == 0,
    hub and (hub.featuresOn() .. " on") or "none")
local ACTION_KEYS = {
    "AutoFarm", "AutoQuest", "AutoAttack", "KillAura", "BringMobs", "MobHitbox",
    "AutoSkill", "AutoChest", "AutoFruit", "AutoDrops", "WalkSpeedEnabled", "JumpPowerEnabled",
}
local on = 0
for _, key in ipairs(ACTION_KEYS) do
    if hub.config[key] == true then on = on + 1 end
end
check("every action switch is false in the config", on == 0, tostring(on) .. " of " .. #ACTION_KEYS .. " true")
check("theme defaults to Aurora", hub.config.Theme == "Aurora", hub.config.Theme)
check("six themes are offered", #hub.themes == 6, tostring(#hub.themes))
check("boot raises no errors", #_G.__HARNESS_ERRORS == 0, #_G.__HARNESS_ERRORS .. " errors")
"""

CHECKS_MAIN = r"""local hub = _G.SkillHubFreeBloxFruit
local check, control, setControl, pumpFor = (function()
    local function c(label, condition, detail)
        table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
    end
    return c, _G.__CONTROL, _G.__SET, _G.__PUMP
end)()

local function position()
    local root = hub.root()
    return root and root.Position or _G.Vector3.new(0, 0, 0)
end
local function spawnNear(name, health, dx, dz)
    local p = position()
    return _G.__SPAWN_MOB(name, health, p.X + (dx or 0), p.Y, p.Z + (dz or 0))
end

-- ── the most important promise: boot does nothing at all ───────────────────
local clicksBefore = _G.__HARNESS_CLICKS or 0
local keysBefore = _G.__KEYS_SENT or 0
local promptsBefore = _G.__HARNESS_PROMPTS or 0
local startPosition = position()
pumpFor(6)
local moved = (position() - startPosition).Magnitude
check("six idle seconds: no attacks, clicks, keys or prompts",
    (_G.__HARNESS_CLICKS or 0) == clicksBefore and (_G.__KEYS_SENT or 0) == keysBefore
    and (_G.__HARNESS_PROMPTS or 0) == promptsBefore and hub.state.hits == 0 and hub.state.steps == 0,
    string.format("hits %d · steps %d · clicks +%d", hub.state.hits, hub.state.steps,
        (_G.__HARNESS_CLICKS or 0) - clicksBefore))
check("idle does not move the character", moved < 0.01, string.format("%.3f studs", moved))
check("no feature turned itself on", hub.featuresOn() == 0, hub.featuresOn() .. " on")

-- ── the scanner ────────────────────────────────────────────────────────────
local world = hub.scan(true)
check("scanner finds the mobs", #world.mobs >= 4, #world.mobs .. " mobs")
check("scanner finds both chests", #world.chests == 2, #world.chests .. " chests")
check("scanner finds the fruit", #world.fruits == 1, #world.fruits .. " fruit")
check("scanner finds the money drop", #world.drops >= 1, #world.drops .. " drops")
check("scanner finds the quest NPC", world.quest ~= nil, world.quest and world.quest.name or "none")
check("scanner flags the boss", (function()
    for _, mob in ipairs(world.mobs) do if mob.boss then return true end end
    return false
end)())

-- ── auto farm: travel, attack, kill ────────────────────────────────────────
hub.config.SafeMode = false
setControl("Auto farm", true)
pumpFor(6)
check("auto farm swings the weapon", hub.state.hits > 0, hub.state.hits .. " attacks")
check("auto farm kills a mob", hub.state.kills >= 1, hub.state.kills .. " kills")
check("auto farm travels between targets", hub.state.steps > 0, hub.state.steps .. " steps")
check("the server saw the kills", (_G.__KILLED or 0) >= 1, (_G.__KILLED or 0) .. " killed")
setControl("Auto farm", false)
pumpFor(0.5)
local hitsAtRest = hub.state.hits
pumpFor(1.2)
check("turning it off stops the attacks", hub.state.hits == hitsAtRest, hub.state.hits .. " attacks")

-- ── farm modes: the boss, spelled out on a clean island ────────────────────
_G.__CLEAR_MOBS()
pumpFor(0.5)
local boss = spawnNear("Gorilla Boss", 3000, 0, -45)
hub.config.FarmMode = "Boss"
setControl("Auto farm", true)
pumpFor(2)
local bossTarget = hub.state.target
check("boss mode picks the boss", bossTarget ~= nil and string.find(bossTarget.name, "Gorilla") ~= nil,
    bossTarget and bossTarget.name or "none")
local bossRoot = boss:FindFirstChild("HumanoidRootPart")
local bossDistance = bossRoot and (bossRoot.Position - position()).Magnitude or 999
check("boss mode travels toward it", hub.state.steps > 0 and bossDistance < 45,
    string.format("%.0f studs", bossDistance))
setControl("Auto farm", false)
hub.config.FarmMode = "Nearest mob"

-- ── kill aura hits what auto farm is not targeting ─────────────────────────
_G.__CLEAR_MOBS()
pumpFor(0.5)
spawnNear("Raider", 400, 5, 0)
spawnNear("Raider", 400, 0, 5)
local auraHits = hub.state.hits
setControl("Kill aura", true)
pumpFor(3)
check("kill aura attacks on its own", hub.state.hits > auraHits, (hub.state.hits - auraHits) .. " attacks")
setControl("Kill aura", false)

-- ── bring mobs pulls a distant mob closer ─────────────────────────────────
_G.__CLEAR_MOBS()
pumpFor(0.4)
local farMob = spawnNear("Raider", 500, 0, -45)
local function distanceTo(model)
    local root = model:FindFirstChild("HumanoidRootPart")
    return root and (root.Position - position()).Magnitude or math.huge
end
local bringBefore = distanceTo(farMob)
setControl("Bring mobs", true)
pumpFor(2)
setControl("Bring mobs", false)
local bringAfter = distanceTo(farMob)
check("bring mobs pulls the mob to your feet", bringAfter < bringBefore - 15,
    string.format("%.0f → %.0f studs", bringBefore, bringAfter))

-- ── mob hitbox scales and restores ─────────────────────────────────────────
hub.config.HitboxSize = 2.5
setControl("Mob hitbox", true)
pumpFor(0.8)
local scaled = false
for _, mob in ipairs(hub.scan(true).mobs) do
    if mob.root.Size.X > 2.01 then scaled = true end
end
check("mob hitbox scales the parts", scaled)
setControl("Mob hitbox", false)
pumpFor(0.8)
local restored = true
for _, mob in ipairs(hub.scan(true).mobs) do
    if math.abs(mob.root.Size.X - 2) > 0.01 then restored = false end
end
check("mob hitbox restores every part", restored)

-- ── auto skill presses the four keys ──────────────────────────────────────
hub.state.target = nil
local keysBeforeSkills = _G.__KEYS_SENT or 0
setControl("Auto skill", true)
pumpFor(3)
setControl("Auto skill", false)
check("auto skill presses Z / X / C / V", (_G.__KEYS_SENT or 0) > keysBeforeSkills,
    ((_G.__KEYS_SENT or 0) - keysBeforeSkills) .. " keys · last " .. tostring(_G.__LAST_KEY))

-- ── loot ──────────────────────────────────────────────────────────────────
_G.__CLEAR_MOBS()
pumpFor(0.3)
local chestsBefore = _G.__CHESTS_OPENED or 0
setControl("Auto chest", true)
pumpFor(9)
setControl("Auto chest", false)
check("auto chest fires the game's own prompt", (_G.__CHESTS_OPENED or 0) > chestsBefore,
    ((_G.__CHESTS_OPENED or 0) - chestsBefore) .. " opened")

setControl("Auto fruit", true)
pumpFor(9)
setControl("Auto fruit", false)
check("auto fruit walks onto it and it is picked up",
    (_G.__FRUITS_TAKEN or 0) >= 1 and hub.state.fruits >= 1,
    (_G.__FRUITS_TAKEN or 0) .. " taken")

local dropsBefore = hub.state.drops
local cash = _G.__SPAWN_DROP("Cash", position().X + 10, 3, position().Z - 2)
setControl("Auto drops", true)
pumpFor(7)
setControl("Auto drops", false)
check("auto drops collects the money", hub.state.drops > dropsBefore and cash.Parent == nil,
    (hub.state.drops - dropsBefore) .. " picked · part gone " .. tostring(cash.Parent == nil))

local questsBefore = _G.__QUESTS or 0
setControl("Auto quest", true)
pumpFor(7)
setControl("Auto quest", false)
check("auto quest talks to the quest NPC", (_G.__QUESTS or 0) > questsBefore,
    ((_G.__QUESTS or 0) - questsBefore) .. " accepted")

-- ── travel is paced, never one jump ───────────────────────────────────────
_G.__CLEAR_MOBS()
pumpFor(0.3)
spawnNear("Gorilla Boss", 9000, 0, -150)
hub.config.SafeMode = true
hub.config.SpeedCap = 40
hub.config.TravelStep = 10
hub.config.TravelDelay = 0.08
hub.config.FarmMode = "Boss"
hub.state.steps, hub.state.studs = 0, 0
setControl("Auto farm", true)
pumpFor(5)
setControl("Auto farm", false)
local averageStep = hub.state.steps > 0 and (hub.state.studs / hub.state.steps) or 999
check("safe mode caps every travel step",
    hub.state.steps > 3 and averageStep <= 3.21,
    string.format("%d steps · %.2f studs/step · cap 3.20", hub.state.steps, averageStep))
hub.config.FarmMode = "Nearest mob"
hub.config.SafeMode = false
"""

CHECKS_SETTINGS = r"""local hub = _G.SkillHubFreeBloxFruit
local check, control, setControl, pumpFor = (function()
    local function c(label, condition, detail)
        table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
    end
    return c, _G.__CONTROL, _G.__SET, _G.__PUMP
end)()

-- ── config: save, load, autosave, export, import, reset ───────────────────
local PATH = "FreeBloxFruit/config.json"
hub.config.SafeMode = false
hub.config.Warmup = nil
hub.config.AttackRate = 0.33
local wrote, text = hub.save()
check("save writes a JSON file", wrote == true and type(_G.__FS[PATH]) == "string",
    wrote and (#tostring(_G.__FS[PATH]) .. " bytes") or "no file")
check("the saved JSON carries the switches", text:find('"AutoFarm"', 1, true) ~= nil
    and text:find('"Theme"', 1, true) ~= nil, #text .. " bytes")
check("the saved JSON parses back", (function()
    local data = hub.decode(text)
    return type(data) == "table" and data.AutoFarm == false and math.abs(data.AttackRate - 0.33) < 0.001
end)())
hub.config.AttackRate = 0.5
local loaded, applied = hub.load()
check("load restores a value", loaded == true and math.abs(hub.config.AttackRate - 0.33) < 0.001,
    tostring(hub.config.AttackRate))

local autosaveBefore = _G.__FS[PATH]
hub.config.AttackRate = 0.41
pumpFor(2.5)
check("autosave writes two seconds after a change", _G.__FS[PATH] ~= autosaveBefore
    and _G.__FS[PATH]:find("0.41", 1, true) ~= nil, "autosave " .. tostring(hub.config.Autosave))

local exported, copied = hub.exportConfig()
check("export puts the JSON on the clipboard", copied == true and _G.__CLIPBOARD == exported
    and exported:find('"AttackRate"', 1, true) ~= nil, #exported .. " bytes")

hub.config.AttackRate = 0.6
hub.importConfig('{"AttackRate":0.27,"Theme":"Aurora"}')
pumpFor(0.4)
check("import applies a pasted config", math.abs(hub.config.AttackRate - 0.27) < 0.001,
    tostring(hub.config.AttackRate))

local safeResult = hub.applySafe({ AutoFarm = true, AutoAttack = true, Theme = "Verdant", AttackRate = 0.19 })
check("autoload-safe never restores a feature switch",
    hub.config.AutoFarm == false and hub.config.AutoAttack == false and hub.config.Theme == "Verdant",
    tostring(hub.config.AutoFarm) .. " / " .. tostring(hub.config.AutoAttack) .. " / " .. tostring(hub.config.Theme))
hub.applyTheme("Aurora")
pumpFor(0.3)

hub.reset()
pumpFor(0.3)
check("reset puts every switch back and defaults the theme",
    hub.featuresOn() == 0 and hub.config.Theme == "Aurora" and math.abs(hub.config.AttackRate - 0.18) < 0.001,
    hub.config.Theme .. " · " .. tostring(hub.config.AttackRate))

-- ── themes rebuild the window with a different palette ────────────────────
for _, name in ipairs({ "Midnight", "Obsidian", "Ivory", "Sakura", "Verdant", "Aurora" }) do
    local before = hub.window().Screen
    hub.applyTheme(name)
    pumpFor(0.4)
    local current, surface = hub.theme()
    local window = hub.window()
    local rootColor = window and window.Root and window.Root.BackgroundColor3
    local same = rootColor and surface and rootColor.R == surface.R and rootColor.G == surface.G and rootColor.B == surface.B
    check("theme " .. name .. " rebuilds the window in its own palette",
        current == name and window ~= nil and window.Screen ~= before and same == true and #hub.tabs == 2,
        tostring(current) .. " · screen swapped " .. tostring(window and window.Screen ~= before) .. " · colour " .. tostring(same))
end

local rebuiltControls = #hub.controls()
check("the rebuilt window keeps every control", rebuiltControls >= 25, rebuiltControls .. " controls")
check("the rebuilt window can still be used", setControl("Auto farm", true) and hub.config.AutoFarm == true,
    tostring(hub.config.AutoFarm))
setControl("Auto farm", false)

-- ── UI scale is applied live, without a rebuild ───────────────────────────
local scaleEntry = control("UI scale")
local scaleValue = nil
if scaleEntry then
    scaleEntry.api.set(1.2)
    pumpFor(0.1)
    for _, child in ipairs(hub.window().Screen:GetChildren()) do
        if child.ClassName == "UIScale" then scaleValue = child.Scale end
    end
    scaleEntry.api.set(1.0)
end
check("UI scale scales the whole window", scaleValue ~= nil and math.abs(scaleValue - 1.2) < 0.001,
    tostring(scaleValue))

-- ── keybinds ─────────────────────────────────────────────────────────────
local uis = _G.__SERVICES.UserInputService
local function press(key, processed)
    uis.InputBegan:Fire({ UserInputType = _G.Enum.UserInputType.Keyboard, KeyCode = { Name = key } }, processed == true)
    pumpFor(0.1)
end
local wasVisible = hub.window().Root.Visible ~= false
press("RightControl")
local hidden = hub.window().Root.Visible == false
press("RightControl")
check("the hide key hides and restores the window",
    wasVisible and hidden and hub.window().Root.Visible ~= false,
    tostring(wasVisible) .. "/" .. tostring(hidden))

setControl("Auto farm", true)
press("F1", true)
check("a keystroke the game consumed is ignored", hub.config.AutoFarm == true, tostring(hub.config.AutoFarm))
press("F1")
check("the panic key turns everything off", hub.featuresOn() == 0, hub.featuresOn() .. " on")

-- ── every control in both tabs responds ──────────────────────────────────
local SKIP = {
    ["Theme"] = true, ["Import config"] = true, ["Load config"] = true,
    ["Reset defaults"] = true, ["Panic — turn everything off"] = true,
}
local faultsBefore = select(1, hub.controlFaults())
local stuck = {}
local used = 0
for _, entry in ipairs(hub.controls()) do
    local api = entry.api
    if SKIP[entry.title] then
        -- destructive or rebuild-triggering: each has its own check above
    elseif entry.kind == "toggle" then
        local was = api.get() == true
        api.set(not was); pump(0.02)
        api.set(was); pump(0.02)
        used = used + 1
        if api.get() ~= was then stuck[#stuck + 1] = entry.title end
    elseif entry.kind == "slider" then
        local was = api.get()
        api.set(-1000000); pump(0.01)
        api.set(1000000); pump(0.01)
        api.set(was); pump(0.01)
        used = used + 1
        if math.abs((api.get() or 0) - was) > 0.01 then stuck[#stuck + 1] = entry.title end
    elseif entry.kind == "dropdown" then
        local was = api.get()
        for _, option in ipairs(api.options or {}) do api.set(option); pump(0.01) end
        api.set(was); pump(0.01)
        used = used + 1
        if api.get() ~= was then stuck[#stuck + 1] = entry.title end
    elseif entry.kind == "button" then
        api.press(); pump(0.05)
        used = used + 1
    elseif entry.kind == "input" then
        local was = api.get()
        api.commit("not json at all"); pump(0.05)
        api.commit(was); pump(0.02)
        used = used + 1
    elseif entry.kind == "keybind" then
        local was = api.get()
        api.commit("Q"); pump(0.02)
        api.commit(was); pump(0.02)
        used = used + 1
    end
end
pumpFor(0.6)
local faultsAfter, lastFault = hub.controlFaults()
check("every control in both tabs responds", (faultsAfter - faultsBefore) == 0,
    used .. " used · " .. (faultsAfter - faultsBefore) .. " fault(s)"
    .. (lastFault and (" · " .. tostring(lastFault)) or ""))
check("no control leaves its own state behind", #stuck == 0,
    #stuck == 0 and (used .. "/" .. used) or table.concat(stuck, ", "))
hub.reset()
pumpFor(0.3)

-- ── the window details ───────────────────────────────────────────────────
local window = hub.window()
check("the window survives a respawn and is parented", window.Screen ~= nil
    and window.Screen.Parent ~= nil and window.Screen.ResetOnSpawn == false)
check("the search box filters rows inside the page", (function()
    local search = nil
    for _, item in ipairs(window.Root:GetDescendants()) do
        if item.ClassName == "TextBox" and item.PlaceholderText
            and string.find(item.PlaceholderText, "search", 1, true) then search = item end
    end
    if not search then return false end
    search.Text = "chest"
    pumpFor(0.1)
    local farmTab, settingsTab = hub.tabs[1], hub.tabs[2]
    local shown, hiddenOther = 0, 0
    for _, panel in ipairs(farmTab.panels) do
        if panel.frame.Visible then
            for _, entry in ipairs(panel.index) do
                if entry.frame.Visible then shown = shown + 1 end
            end
        end
    end
    for _, panel in ipairs(settingsTab.panels) do
        if panel.frame.Visible then hiddenOther = hiddenOther + 1 end
    end
    search.Text = ""
    pumpFor(0.1)
    local restored = 0
    for _, panel in ipairs(farmTab.panels) do
        if panel.frame.Visible then restored = restored + 1 end
    end
    return shown == 1 and hiddenOther == 0 and restored == #farmTab.panels
end)())

-- ── doctor and self-test ─────────────────────────────────────────────────
local report = hub.doctor()
check("doctor prints a report", type(report) == "string" and report:find("controls", 1, true) ~= nil
    and report:find("theme", 1, true) ~= nil and report:find("config", 1, true) ~= nil, type(report))

local passed, total = hub.selfTest()
check("the hub's own self-test", total >= 12 and passed == total, passed .. "/" .. total)
check("no entries in the error log", #(_G.__SkillHubErrorLog or {}) == 0,
    #(_G.__SkillHubErrorLog or {}) .. " entries")
"""

CHECKS_MORE = r"""local hub = _G.SkillHubFreeBloxFruit
local check, control, setControl, pumpFor = (function()
    local function c(label, condition, detail)
        table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
    end
    return c, _G.__CONTROL, _G.__SET, _G.__PUMP
end)()

local function press(key, processed)
    _G.__SERVICES.UserInputService.InputBegan:Fire(
        { UserInputType = _G.Enum.UserInputType.Keyboard, KeyCode = { Name = key } }, processed == true)
    pumpFor(0.1)
end

-- ── a theme is chosen from the real dropdown ──────────────────────────────
hub.config.AttackRate = 0.29
local themeEntry = control("Theme")
local chose = false
if themeEntry and themeEntry.api then
    themeEntry.api.set("Obsidian")
    pumpFor(0.5)
    chose = hub.theme() == "Obsidian"
end
check("the theme dropdown switches the palette", chose, tostring(hub.theme()))
check("switching a theme keeps the farm values", math.abs(hub.config.AttackRate - 0.29) < 0.001,
    tostring(hub.config.AttackRate))
check("nothing is enabled by a rebuild", hub.featuresOn() == 0, hub.featuresOn() .. " on")

-- ── every palette defines every token ────────────────────────────────────
local palettes = hub.palettes()
local reference = {}
for key in pairs(palettes.Aurora) do reference[key] = true end
local missing = {}
for name, palette in pairs(palettes) do
    for key in pairs(reference) do
        if palette[key] == nil then missing[#missing + 1] = name .. "." .. key end
    end
    if type(palette.radius) ~= "table" or palette.radius.window == nil then
        missing[#missing + 1] = name .. ".radius"
    end
end
check("all six palettes are complete", #missing == 0,
    #missing == 0 and "6/6" or table.concat(missing, ", "))

-- ── panic restores the hitbox, not only the switches ─────────────────────
hub.config.HitboxSize = 3
setControl("Mob hitbox", true)
pumpFor(0.8)
_G.__SPAWN_MOB("Raider", 200, hub.root().Position.X + 3, 3, hub.root().Position.Z)
pumpFor(0.6)
local scaledAny = false
for _, mob in ipairs(hub.scan(true).mobs) do
    if mob.root.Size.X > 2.01 then scaledAny = true end
end
setControl("Auto farm", true)
hub.panic()
pumpFor(0.5)
local restoredAny = true
for _, mob in ipairs(hub.scan(true).mobs) do
    if math.abs(mob.root.Size.X - 2) > 0.01 then restoredAny = false end
end
check("panic restores a scaled mob hitbox", scaledAny and restoredAny,
    tostring(scaledAny) .. " / " .. tostring(restoredAny))
check("panic leaves every switch off", hub.featuresOn() == 0, hub.featuresOn() .. " on")

-- ── autosave off means the file is not touched ───────────────────────────
hub.config.Autosave = false
hub.save()
local frozen = _G.__FS["FreeBloxFruit/config.json"]
hub.config.AttackRate = 0.55
pumpFor(3)
check("autosave off leaves the file alone", _G.__FS["FreeBloxFruit/config.json"] == frozen)
hub.config.Autosave = true

-- ── the chrome: minimise and close ───────────────────────────────────────
local function ghost(name)
    for _, item in ipairs(hub.window().Root:GetDescendants()) do
        if item.ClassName == "TextButton" and item.Name == name then return item end
    end
    return nil
end
local minimise = ghost("Minimise")
local close = ghost("Close")
if minimise then
    minimise.MouseButton1Click:Fire()
    pumpFor(0.3)
end
check("minimise collapses the window", minimise ~= nil and hub.window().Minimized == true,
    tostring(hub.window().Minimized))
if minimise then
    minimise.MouseButton1Click:Fire()
    pumpFor(0.3)
end
check("minimise restores it", hub.window().Minimized == false, tostring(hub.window().Minimized))

if close then close.MouseButton1Click:Fire() end
pumpFor(0.3)
local hiddenByClose = hub.window().Root.Visible == false
press("RightControl")
check("close hides the window and the key brings it back",
    close ~= nil and hiddenByClose and hub.window().Root.Visible ~= false,
    tostring(hiddenByClose) .. " → " .. tostring(hub.window().Root.Visible))

-- ── an executor without writefile still gets export / import ─────────────
local savedWrite, savedRead, savedIsFile = writefile, readfile, isfile
writefile, readfile, isfile = nil, nil, nil
local wroteNoFile, textNoFile = hub.save()
local exportedNoFile, copiedNoFile = hub.exportConfig()
writefile, readfile, isfile = savedWrite, savedRead, savedIsFile
check("no file API: save reports honestly and export still works",
    wroteNoFile == false and type(textNoFile) == "string" and copiedNoFile == true
    and exportedNoFile == textNoFile,
    "wrote=" .. tostring(wroteNoFile) .. " · clipboard " .. tostring(copiedNoFile))
local themeBefore = hub.config.Theme
hub.config.AttackRate = 0.44
hub.config.ScanRange = 111
local snapshot = hub.exportConfig()
hub.config.AttackRate = 0.11
hub.config.ScanRange = 22
hub.importConfig(snapshot)
pumpFor(0.3)
check("no file API: import from the exported text restores the values",
    math.abs(hub.config.AttackRate - 0.44) < 0.001 and hub.config.ScanRange == 111
    and hub.config.Theme == themeBefore and hub.featuresOn() == 0,
    tostring(hub.config.AttackRate) .. " · " .. tostring(hub.config.ScanRange))

-- ── the config folder is created, and the file holds every key ───────────
hub.save()
local saved = _G.__FS["FreeBloxFruit/config.json"] or ""
local keyCount = 0
for key in pairs(hub.config) do
    if saved:find('"' .. key .. '"', 1, true) then keyCount = keyCount + 1 end
end
check("autosave creates the folder and writes every key",
    _G.__FS["FreeBloxFruit"] ~= nil and keyCount >= 30, keyCount .. " keys in " .. #saved .. " bytes")

-- ── leave a config on disk that a reboot must not act on ─────────────────
local PATH = "FreeBloxFruit/config.json"
hub.config.AutoFarm = true
hub.config.KillAura = true
hub.config.AutoChest = true
hub.config.AutoFruit = true
hub.config.Autoload = true
hub.config.Theme = "Ivory"
_G.__FS[PATH] = hub.encodeConfig()
hub.config.AutoFarm, hub.config.KillAura, hub.config.AutoChest, hub.config.AutoFruit = false, false, false, false

-- ── unload ───────────────────────────────────────────────────────────────
local destroyed = hub.destroy()
pumpFor(0.3)
local guiGone = true
for _, child in ipairs(_G.gethui():GetChildren()) do
    if child.Name == "SkillHubFreeBloxFruit" then guiGone = false end
end
check("destroy removes the window and the export",
    destroyed == true and guiGone and _G.SkillHubFreeBloxFruit == nil,
    tostring(destroyed) .. "/" .. tostring(guiGone))
"""

CHECKS_DESIGN = r"""-- ═══════════════════════════════════════════════════════════════════════════
-- the R31 layout: an outlined menu with a glowing rim, a title bar over the
-- page, two columns of group panels, and a bottom bar whose tabs are an icon
-- over a label. These checks fail if the window ever drifts back to the old
-- left rail, flat sections or text-glyph chrome.
-- ═══════════════════════════════════════════════════════════════════════════
local hub = _G.SkillHubFreeBloxFruit
local check, control, pumpFor = (function()
    local function c(label, condition, detail)
        table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
    end
    return c, _G.__CONTROL, _G.__PUMP
end)()

local window = hub.window()
local root = window.Root

-- the mock only stores properties that were written; a fresh Frame in real
-- Roblox has Position (0, 0), so read it the same way here
local function offsetX(inst)
    return inst.Position and inst.Position.X.Offset or 0
end
local function offsetY(inst)
    return inst.Position and inst.Position.Y.Offset or 0
end
local function scaleY(inst)
    return inst.Position and inst.Position.Y.Scale or 0
end

local function findByText(text, class)
    for _, item in ipairs(root:GetDescendants()) do
        if (not class or item.ClassName == class) and item.Text == text then return item end
    end
    return nil
end

local function panelsOf(tab)
    local out = {}
    for _, panel in ipairs(tab.panels or {}) do out[#out + 1] = panel end
    return out
end

-- ── the frame of the window ──────────────────────────────────────────────
check("the window is the redesigned size", root.Size.X.Offset == 840 and root.Size.Y.Offset == 600,
    tostring(root.Size.X.Offset) .. "x" .. tostring(root.Size.Y.Offset))
check("the window has an accent halo behind it", window.Glow ~= nil
    and window.Glow.BackgroundColor3 == hub.palettes()[hub.theme()].Glow,
    window.Glow and tostring(window.Glow.BackgroundColor3.R) or "none")
check("the window is outlined with a hairline", window.Stroke ~= nil
    and window.Stroke.ClassName == "UIStroke")

-- ── the title bar on top, the tab bar at the bottom ──────────────────────
local topbar = window.Topbar
local nav = window.Nav
check("the title bar is 54 px at the top", topbar ~= nil and topbar.Size.Y.Offset == 54
    and offsetY(topbar) == 0)
check("the tab bar is 58 px at the bottom", nav ~= nil and nav.Size.Y.Offset == 58
    and scaleY(nav) == 1 and offsetY(nav) == -58)
check("the title bar names the game and the build",
    window.HeaderTitle ~= nil
    and string.find(window.HeaderTitle.Text, "Blox Fruits", 1, true) ~= nil
    and string.find(window.HeaderTitle.Text, "v1.2", 1, true) ~= nil,
    window.HeaderTitle and window.HeaderTitle.Text or "none")
check("there is no left rail any more", findByText("Auto Farm", "TextButton") == nil,
    "a rail button still exists")

-- ── two tabs, each an icon over a label ──────────────────────────────────
local navButtons = {}
for _, child in ipairs(window.NavList:GetChildren()) do
    if child.ClassName == "TextButton" then navButtons[#navButtons + 1] = child end
end
check("the bottom bar holds exactly two tabs", #navButtons == 2, #navButtons .. " tabs")
local iconOverLabel = true
for _, button in ipairs(navButtons) do
    local label, glyph = nil, false
    for _, child in ipairs(button:GetDescendants()) do
        if child.ClassName == "TextLabel" and #child.Text > 0 then label = child end
        if child.ClassName == "Frame" and child.Size.X.Offset > 0 and child.Size.X.Offset <= 30
            and child.Size.Y.Offset == child.Size.X.Offset then glyph = true end
    end
    if not label or not glyph then iconOverLabel = false end
    if label and offsetY(label) <= 4 then iconOverLabel = false end
end
check("each tab draws an icon above its label", iconOverLabel)

-- the active tab is underlined and the header follows it
local farm, settings = hub.tabs[1], hub.tabs[2]
farm.Select()
pumpFor(0.2)
local farmUnderline = farm.pill ~= nil and farm.pill.Visible == true and farm.pill.Size.Y.Offset <= 3
check("the active tab carries an accent underline", farmUnderline)
settings.Select()
pumpFor(0.2)
check("switching a tab moves the underline", farm.pill.Visible == false and settings.pill.Visible == true)
check("switching a tab rewrites the title bar",
    string.find(window.HeaderTitle.Text, "Settings", 1, true) ~= nil, window.HeaderTitle.Text)
farm.Select()
pumpFor(0.2)

-- ── two columns of outlined group panels ─────────────────────────────────
local twoColumns = #farm.columns == 2 and #settings.columns == 2
for _, tab in ipairs(hub.tabs) do
    for _, column in ipairs(tab.columns) do
        if column.ClassName ~= "ScrollingFrame" then twoColumns = false end
    end
end
check("every page is two scrolling columns", twoColumns)

local function columnCount(tab, index)
    local seen = 0
    for _, panel in ipairs(tab.panels) do
        if panel.frame.Parent == tab.columns[index] then seen = seen + 1 end
    end
    return seen
end
check("Auto Farm splits 2 + 3 panels across the columns",
    columnCount(farm, 1) == 2 and columnCount(farm, 2) == 3,
    columnCount(farm, 1) .. " + " .. columnCount(farm, 2))
check("Settings splits its panels across the columns",
    columnCount(settings, 1) >= 3 and columnCount(settings, 2) >= 3,
    columnCount(settings, 1) .. " + " .. columnCount(settings, 2))

local outlined, titled = 0, 0
for _, panel in ipairs(farm.panels) do
    for _, child in ipairs(panel.frame:GetChildren()) do
        if child.ClassName == "UIStroke" then outlined = outlined + 1 end
    end
    for _, child in ipairs(panel.frame:GetDescendants()) do
        if child.ClassName == "TextLabel" and child.Text == string.upper(panel.title) then
            titled = titled + 1
            break
        end
    end
end
check("every group box is outlined", outlined == #farm.panels, outlined .. "/" .. #farm.panels)
check("every group box is titled in small caps", titled == #farm.panels, titled .. "/" .. #farm.panels)

-- ── the row widgets ──────────────────────────────────────────────────────
local kinds = {}
for _, entry in ipairs(hub.controls()) do kinds[entry.kind] = (kinds[entry.kind] or 0) + 1 end
local expected = { "toggle", "slider", "dropdown", "button", "input", "keybind", "theme" }
local missing = {}
for _, kind in ipairs(expected) do
    if not kinds[kind] then missing[#missing + 1] = kind end
end
check("the panels carry every row type", #missing == 0,
    "missing: " .. table.concat(missing, ", "))
check("there are enough rows to fill two pages", #hub.controls() >= 40, #hub.controls() .. " rows")

-- a checkbox shows its state on the right of the row
local farmToggle = control("Auto farm")
farmToggle.api.set(true)
pumpFor(0.3)
local onLabel = nil
for _, item in ipairs(root:GetDescendants()) do
    if item.ClassName == "TextLabel" and item.Text == "ON" then onLabel = item end
end
check("a checkbox row prints ON on the right side", onLabel ~= nil
    and onLabel.Position.X.Scale == 1 and onLabel.TextXAlignment.Name == "Right")
farmToggle.api.set(false)
pumpFor(0.3)

-- a slider carries a live readout
local rangeEntry = control("Attack range")
rangeEntry.api.set(32)
pumpFor(0.3)
local readout = nil
for _, item in ipairs(root:GetDescendants()) do
    if item.ClassName == "TextLabel" and item.Text == "32 studs" then readout = item end
end
check("a slider shows its value next to the label", readout ~= nil
    and readout.TextColor3 == hub.palettes()[hub.theme()].Accent)
rangeEntry.api.set(16)
pumpFor(0.2)

-- a dropdown expands inside its own panel
local modeEntry = control("Farm mode")
local selector = nil
for _, item in ipairs(root:GetDescendants()) do
    if item.ClassName == "TextButton" then
        for _, child in ipairs(item:GetChildren()) do
            if child.ClassName == "TextLabel" and child.Text == "Nearest mob" then selector = item end
        end
    end
end
local list = nil
if selector then
    for _, sibling in ipairs(selector.Parent.Parent:GetChildren()) do
        if sibling.ClassName == "Frame" and sibling ~= selector.Parent then
            for _, child in ipairs(sibling:GetChildren()) do
                if child.ClassName == "UIListLayout" and sibling.Visible == false then list = sibling end
            end
        end
    end
end
check("the farm-mode dropdown has a collapsed list inside the panel", list ~= nil)
if selector and list then
    selector.MouseButton1Click:Fire()
    pumpFor(0.2)
end
local opened = list ~= nil and list.Visible == true and list.Size.Y.Offset > 40
check("clicking the dropdown expands it under the row", opened,
    list and tostring(list.Visible) .. " · " .. tostring(list.Size.Y.Offset) or "no list")
if opened then
    local questOption = nil
    for _, child in ipairs(list:GetChildren()) do
        if child.ClassName == "TextButton" and string.find(child.Text, "Quest area", 1, true) then questOption = child end
    end
    if questOption then questOption.MouseButton1Click:Fire() end
    pumpFor(0.3)
end
check("picking an option writes it into the config and closes the list",
    hub.config.FarmMode == "Quest area" and list ~= nil and list.Visible == false,
    tostring(hub.config.FarmMode))
modeEntry.api.set("Nearest mob")
pumpFor(0.2)

-- the top bar chips reflect the hub state
local chips = window.Chrome and window.Chrome.chips
check("the title bar carries state chips", chips ~= nil and chips.stateText ~= nil
    and chips.acText ~= nil and chips.perfText ~= nil
    and chips.stateText.Text == "IDLE", chips and chips.stateText.Text or "none")
check("the tab bar has a shortcut hint", window.Chrome.hint ~= nil
    and string.find(window.Chrome.hint.Text, "panic", 1, true) ~= nil,
    window.Chrome.hint and window.Chrome.hint.Text or "none")

-- a page can be searched down to single rows (see checks_settings for the
-- full behaviour); here: a query that matches nothing leaves nothing shown
local search = nil
for _, item in ipairs(root:GetDescendants()) do
    if item.ClassName == "TextBox" and item.PlaceholderText and item.PlaceholderText == "search…" then
        search = item
    end
end
check("the title bar has a search field", search ~= nil)
if search then
    search.Text = "zzzz-no-such-row"
    pumpFor(0.2)
    local shown = 0
    for _, tab in ipairs(hub.tabs) do
        for _, panel in ipairs(tab.panels) do
            if panel.frame.Visible then shown = shown + 1 end
        end
    end
    search.Text = ""
    pumpFor(0.2)
    local restored = 0
    for _, panel in ipairs(farm.panels) do
        if panel.frame.Visible then restored = restored + 1 end
    end
    check("a query with no match hides every panel, clearing it restores them",
        shown == 0 and restored == #farm.panels, shown .. " shown · " .. restored .. " restored")
end
"""

CHECKS_EXTRA = r"""local hub = _G.SkillHubFreeBloxFruit
local check, control, setControl, pumpFor = (function()
    local function c(label, condition, detail)
        table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
    end
    return c, _G.__CONTROL, _G.__SET, _G.__PUMP
end)()

-- ── the theme picker is six real swatches, and clicking one works ─────────
local function themeCard()
    for _, item in ipairs(hub.window().Root:GetDescendants()) do
        if item.ClassName == "TextLabel" and item.Text == "THEME" then
            return item.Parent and item.Parent.Parent or nil
        end
    end
    return nil
end
local card = themeCard()
local swatches = {}
if card then
    for _, child in ipairs(card:GetDescendants()) do
        if child.ClassName == "TextButton" then swatches[#swatches + 1] = child end
    end
end
check("the theme picker paints six swatches", #swatches == 6, #swatches .. " swatches")
local clicked = false
if #swatches >= 3 then
    swatches[3].MouseButton1Click:Fire()
    pumpFor(0.5)
    clicked = hub.theme() == "Obsidian"
end
check("clicking a swatch rebuilds the window in that palette", clicked, tostring(hub.theme()))
check("the rebuilt picker still lists six", (function()
    local again = themeCard()
    local count = 0
    if again then
        for _, child in ipairs(again:GetDescendants()) do
            if child.ClassName == "TextButton" then count = count + 1 end
        end
    end
    return count == 6
end)())

-- ── profiles: three slots beside the main config ─────────────────────────
hub.config.AttackRate = 0.22
hub.config.ScanRange = 333
local wroteProfile, _, profilePath = hub.saveProfile("2")
check("a profile writes its own file", wroteProfile == true
    and profilePath == "FreeBloxFruit/profile-2.json"
    and type(_G.__FS[profilePath]) == "string",
    tostring(profilePath))
hub.config.AttackRate = 0.9
hub.config.ScanRange = 99
local loadedProfile = hub.loadProfile("2")
pumpFor(0.3)
check("loading a profile restores its values",
    loadedProfile == true and math.abs(hub.config.AttackRate - 0.22) < 0.001 and hub.config.ScanRange == 333,
    tostring(hub.config.AttackRate) .. " · " .. tostring(hub.config.ScanRange))
check("loading a profile never starts a feature", hub.featuresOn() == 0, hub.featuresOn() .. " on")

-- ── the window remembers where it was left ───────────────────────────────
hub.config.UiX, hub.config.UiY = 44, -26
hub.applyTheme(hub.config.Theme)
pumpFor(0.4)
local offsetX = hub.window().Root.Position.X.Offset
local offsetY = hub.window().Root.Position.Y.Offset
check("the window reopens where it was dragged", offsetX == 44 and offsetY == -26,
    tostring(offsetX) .. ", " .. tostring(offsetY))
hub.config.UiX, hub.config.UiY = 0, 0
hub.applyTheme(hub.config.Theme)
pumpFor(0.4)
check("the centre position restores", hub.window().Root.Position.X.Offset == 0,
    tostring(hub.window().Root.Position.X.Offset))

-- ── notifications toggle ─────────────────────────────────────────────────
local notifyEntry = control("Notifications")
local flipped = false
if notifyEntry then
    notifyEntry.api.set(false)
    local off = hub.config.NotifyActions == false
    notifyEntry.api.set(true)
    flipped = off and hub.config.NotifyActions == true
end
check("the notifications switch flips the config", flipped)

-- ── the farm panel reports a session ─────────────────────────────────────
local rows = hub.farmStatus()
local session, rates = nil, nil
for _, row in ipairs(rows) do
    if row.label == "session" then session = row.value end
    if row.label == "rates" then rates = row.value end
end
check("the farm panel shows a session clock and rates",
    session ~= nil and session:find("%d+:%d+") ~= nil and rates ~= nil and rates:find("/min") ~= nil,
    tostring(session) .. " · " .. tostring(rates))
local configRows = hub.configStatus()
local sawProfile, sawWindow = false, false
for _, row in ipairs(configRows) do
    if row.label == "profile" then sawProfile = true end
    if row.label == "window" then sawWindow = true end
end
check("the config panel shows the slot and the window position", sawProfile and sawWindow)
"""

CHECKS_REBOOT = r"""-- ═══════════════════════════════════════════════════════════════════════════
-- REBOOT — a real second run of the script, with a saved config on disk that
-- has every loud switch set to true. The theme comes back; the farm must not.
-- ═══════════════════════════════════════════════════════════════════════════
local hub = _G.SkillHubFreeBloxFruit
local function check(label, condition, detail)
    table.insert(_G.__RESULTS, { label = label, ok = condition == true, detail = detail })
end

check("second boot: the hub exists", hub ~= nil)
check("second boot: two tabs", hub and #hub.tabs == 2, hub and table.concat(hub.tabTitles(), " / "))
check("second boot: no feature is enabled, even from a saved config", hub and hub.featuresOn() == 0,
    hub and (hub.featuresOn() .. " on") or "none")
check("second boot: AutoFarm stays false", hub and hub.config.AutoFarm == false, hub and tostring(hub.config.AutoFarm))
check("second boot: AutoChest stays false", hub and hub.config.AutoChest == false, hub and tostring(hub.config.AutoChest))
check("second boot: the interface keys were restored", hub and hub.config.Theme == "Ivory",
    hub and hub.config.Theme)
check("second boot: the window uses the restored theme",
    hub and hub.window().Root.BackgroundColor3.R == hub.palettes().Ivory.BgSurface.R,
    hub and tostring(hub.window().Root.BackgroundColor3.R))
check("second boot: controls are registered", hub and #hub.controls() >= 25,
    hub and (#hub.controls() .. " controls"))
check("second boot: nothing moves for three seconds", (function()
    local position = hub.root().Position
    _G.__PUMP(3)
    return (hub.root().Position - position).Magnitude < 0.01 and hub.state.hits == 0
end)())
check("second boot: the saved file was not overwritten by defaults",
    _G.__FS["FreeBloxFruit/config.json"]:find('"AutoFarm":true', 1, true) ~= nil)
check("second boot: no errors", #_G.__HARNESS_ERRORS == 0, #_G.__HARNESS_ERRORS .. " errors")
hub.destroy()
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

    runtime.execute("_G.__RESULTS = {}")
    runtime.execute(CHECKS_BOOT)
    runtime.execute(CHECKS_MAIN)
    runtime.execute(CHECKS_SETTINGS)
    runtime.execute(CHECKS_EXTRA)
    runtime.execute(CHECKS_DESIGN)
    runtime.execute(CHECKS_MORE)

    # second run of the same script, with the config the first run left behind
    loader(source)
    runtime.execute(CHECKS_REBOOT)

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
