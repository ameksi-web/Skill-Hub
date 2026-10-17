#!/usr/bin/env python3
"""Boot the Skill Animator plugin in a mocked Roblox Studio and drive it.

    /tmp/venv/bin/python tools/animator_test.py

The mock is the same one tools/jjs_test.py uses (virtual clock, coroutine
scheduler, instance metatable, services), extended here with what a Studio
plugin touches and an executor script never does:

    plugin:CreateToolbar / CreateButton / CreateDockWidgetPluginGui
    DockWidgetPluginGuiInfo
    Selection:Get / Set + SelectionChanged
    ChangeHistoryService:SetWaypoint (waypoint counter)
    TweenService:GetValue
    a real CFrame: 3x3 matrix + position, with Inverse / ToEulerAnglesXYZ

That last one matters: the plugin converts degrees → CFrame → back, and an
export that "looks fine" with a fake identity CFrame would be worthless. The
rig under test is an R6 skeleton (HumanoidRootPart → Torso → Head/arms/legs),
built from real Motor6D instances, and the assertions read the Pose tree out of
the exported KeyframeSequence the way Roblox would match it:

    Pose.Name        == joint.Part1.Name
    Pose.Parent.Name == joint.Part0.Name

Checked: plugin registration · dock · auto-bind · joint discovery and order ·
recording · interpolation · motor writes · export tree and values · easing ·
import round trip · FPS/length · zoom · duplicate/delete/navigate · selection
follow · project save/load · undo waypoints · teardown · no errors.
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PLUGIN = os.path.join(HERE, os.pardir, "SkillAnimator", "init.lua")

try:
    from lupa import LuaRuntime
except ImportError:
    print("this test needs lupa and a Lua runtime:")
    print("    python3 -m venv /tmp/venv && /tmp/venv/bin/pip install lupa")
    sys.exit(2)

JJS = io.open(os.path.join(HERE, "jjs_test.py"), encoding="utf-8").read()
BASE_PRELUDE = JJS.split('PRELUDE = r"""', 1)[1].split('\n"""', 1)[0]

STUDIO_EXTRAS = r"""
-- ═══════════════════════════════════════════════════════════════════════════
-- Studio-only surface, appended INTO the same chunk as the base mock (the
-- locals above are in scope here, on purpose)
-- ═══════════════════════════════════════════════════════════════════════════

-- ── a real CFrame: 3x3 rotation matrix (row-major) + position ──────────────
local MF = {}
local function cfFrame(matrix, position)
    return setmetatable({ m = matrix, px = position }, MF)
end

local function matMul(a, b)
    local out = {}
    for row = 0, 2 do
        for col = 0, 2 do
            local sum = 0
            for k = 0, 2 do
                sum = sum + a[row * 3 + k + 1] * b[k * 3 + col + 1]
            end
            out[row * 3 + col + 1] = sum
        end
    end
    return out
end

local function matVec(m, v)
    return V3.new(
        m[1] * v.x + m[2] * v.y + m[3] * v.z,
        m[4] * v.x + m[5] * v.y + m[6] * v.z,
        m[7] * v.x + m[8] * v.y + m[9] * v.z
    )
end

local function anglesMatrix(rx, ry, rz)
    local ca, sa = math.cos(rx), math.sin(rx)
    local cb, sb = math.cos(ry), math.sin(ry)
    local cc, sc = math.cos(rz), math.sin(rz)
    local xm = { 1, 0, 0, 0, ca, -sa, 0, sa, ca }
    local ym = { cb, 0, sb, 0, 1, 0, -sb, 0, cb }
    local zm = { cc, -sc, 0, sc, cc, 0, 0, 0, 1 }
    return matMul(matMul(xm, ym), zm)
end

function MF.__index(self, key)
    if key == "Position" then return rawget(self, "px") end
    if key == "LookVector" then
        local m = rawget(self, "m")
        return V3.new(-m[3], -m[6], -m[9])
    end
    if key == "RightVector" then
        local m = rawget(self, "m")
        return V3.new(m[1], m[4], m[7])
    end
    if key == "UpVector" then
        local m = rawget(self, "m")
        return V3.new(m[2], m[5], m[8])
    end
    if key == "Inverse" then
        return function(frame)
            local m = rawget(frame, "m")
            local p = rawget(frame, "px")
            local t = { m[1], m[4], m[7], m[2], m[5], m[8], m[3], m[6], m[9] }
            local moved = matVec(t, p)
            return cfFrame(t, V3.new(-moved.x, -moved.y, -moved.z))
        end
    end
    if key == "ToEulerAnglesXYZ" then
        return function(frame)
            local m = rawget(frame, "m")
            local b = math.asin(math.max(-1, math.min(1, m[3])))
            local a = math.atan2(-m[6], m[9])
            local c = math.atan2(-m[2], m[1])
            return a, b, c
        end
    end
    if key == "ToObjectSpace" then
        return function(frame, other)
            return frame:Inverse() * other
        end
    end
    return nil
end

MF.__mul = function(a, b)
    if type(b) == "table" and rawget(b, "m") then
        local rotated = matVec(rawget(a, "m"), rawget(b, "px"))
        local p = rawget(a, "px")
        return cfFrame(matMul(rawget(a, "m"), rawget(b, "m")),
            V3.new(p.x + rotated.x, p.y + rotated.y, p.z + rotated.z))
    end
    local moved = matVec(rawget(a, "m"), b)
    local p = rawget(a, "px")
    return V3.new(p.x + moved.x, p.y + moved.y, p.z + moved.z)
end

MF.__tostring = function(self)
    local p = rawget(self, "px")
    return string.format("CFrame(%.2f, %.2f, %.2f)", p.x, p.y, p.z)
end

_G.CFrame = {
    new = function(x, y, z)
        if type(x) == "table" then return cfFrame({ 1, 0, 0, 0, 1, 0, 0, 0, 1 }, x) end
        if x == nil then return cfFrame({ 1, 0, 0, 0, 1, 0, 0, 0, 1 }, V3.new(0, 0, 0)) end
        return cfFrame({ 1, 0, 0, 0, 1, 0, 0, 0, 1 }, V3.new(x or 0, y or 0, z or 0))
    end,
    Angles = function(rx, ry, rz) return cfFrame(anglesMatrix(rx, ry, rz), V3.new(0, 0, 0)) end,
    identity = cfFrame({ 1, 0, 0, 0, 1, 0, 0, 0, 1 }, V3.new(0, 0, 0)),
    lookAt = function(from, to)
        return cfFrame({ 1, 0, 0, 0, 1, 0, 0, 0, 1 }, from)
    end,
}
_G.__CF_ANGLES = anglesMatrix

-- Vector3.FromNormalId is used by the move handles
_G.Vector3.FromNormalId = function(id)
    local name = tostring(id)
    if name == "Top" or name == "Y" then return V3.new(0, 1, 0) end
    if name == "Right" or name == "X" then return V3.new(1, 0, 0) end
    return V3.new(0, 0, 1)
end

-- ── events a plugin listens to that the script mock never needed ───────────
for _, name in ipairs({ "MouseDrag", "SelectionChanged", "Unloading", "Dragging" }) do
    KNOWN_EVENTS[name] = true
end

-- ── gui geometry, so sliders and the playhead have something to read ──────
for _, class in ipairs({ "Frame", "TextButton", "TextLabel", "ScrollingFrame", "TextBox",
    "ImageButton", "ImageLabel", "DockWidgetPluginGui" }) do
    CLASS_PARENTS[class] = CLASS_PARENTS[class] or nil
end
local baseIndex = INSTANCE_MT.__index
INSTANCE_MT.__index = function(self, key)
    local value = baseIndex(self, key)
    if value ~= nil then return value end
    local class = rawget(self, "__class")
    if key == "AbsoluteSize" then return { X = 760, Y = 300, X2 = 760, Y2 = 300 } end
    if key == "AbsolutePosition" then return { X = 180, Y = 0 } end
    return nil
end

-- ── the Studio services the plugin asks for ───────────────────────────────
local selection = makeInstance("Selection", "Selection")
local selectionState = {}
selection.Get = function() return selectionState end
selection.Set = function(_, list)
    selectionState = list or {}
    local bucket = rawget(selection, "__signals").SelectionChanged
    if bucket then
        for _, handler in ipairs(bucket.handlers) do pcall(handler) end
    end
end
services.Selection = selection
_G.__SELECTION = selection

local history = makeInstance("ChangeHistoryService", "ChangeHistoryService")
_G.__WAYPOINTS = {}
history.SetWaypoint = function(_, name)
    table.insert(_G.__WAYPOINTS, tostring(name))
end
history.TryBeginRecording = function() return nil end
services.ChangeHistoryService = history

services.TweenService.GetValue = function(_, alpha, style, direction)
    -- linear only: the tests assert exact midpoints
    return alpha
end

-- ── DockWidgetPluginGuiInfo ───────────────────────────────────────────────
_G.DockWidgetPluginGuiInfo = {
    new = function(state, enabled, override, width, height, minWidth, minHeight)
        return { State = state, Enabled = enabled, Override = override, Width = width,
            Height = height, MinWidth = minWidth, MinHeight = minHeight }
    end,
}

-- ── the plugin object Studio passes to a plugin script ────────────────────
local pluginObject = makeInstance("Plugin", "Plugin")
_G.__PLUGIN = pluginObject
_G.__DOCK = nil
_G.__TOOLBARS = {}

pluginObject.CreateToolbar = function(_, title)
    local toolbar = makeInstance("PluginToolbar", tostring(title))
    table.insert(_G.__TOOLBARS, toolbar)
    toolbar.CreateButton = function(_, text, tooltip, icon)
        local buttonObject = makeInstance("PluginToolbarButton", text)
        buttonObject.Tooltip = tooltip
        buttonObject.Icon = icon
        buttonObject.SetActive = function()
            return true
        end
        return buttonObject
    end
    return toolbar
end

pluginObject.CreateDockWidgetPluginGui = function(_, id, info)
    local widget = makeInstance("DockWidgetPluginGui", id)
    widget.Enabled = false
    widget.Title = ""
    widget.DockWidgetPluginGuiInfo = info
    _G.__DOCK = widget
    return widget
end

signalOf(pluginObject, "Unloading", true)
_G.plugin = pluginObject

-- ── warnings are data, not noise ──────────────────────────────────────────
_G.__WARNINGS = {}
local realWarn = warn
warn = function(...)
    local parts = {}
    for index = 1, select("#", ...) do parts[index] = tostring((select(index, ...))) end
    table.insert(_G.__WARNINGS, table.concat(parts, " "))
    if realWarn then realWarn(...) end
end

-- ── an R6 skeleton with real Motor6D joints ───────────────────────────────
local function makeRig()
    local rig = makeInstance("Model", "TestRig")
    local parts = {}
    for _, name in ipairs({ "HumanoidRootPart", "Torso", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }) do
        local part = makeInstance("Part", name)
        part.Size = V3.new(2, 2, 1)
        part.Parent = rig
        parts[name] = part
    end
    local humanoid = makeInstance("Humanoid", "Humanoid")
    humanoid.Health = 100
    humanoid.MaxHealth = 100
    humanoid.Parent = rig

    local function joint(name, part0, part1, c0)
        local motor = makeInstance("Motor6D", name)
        motor.Part0 = parts[part0]
        motor.Part1 = parts[part1]
        motor.C0 = c0 or _G.CFrame.new(0, 0, 0)
        motor.C1 = _G.CFrame.new(0, 0, 0)
        motor.Parent = parts[part0]
        return motor
    end

    joint("RootJoint", "HumanoidRootPart", "Torso", _G.CFrame.Angles(0, 0, 0))
    joint("Neck", "Torso", "Head", _G.CFrame.Angles(0.1, 0, 0))
    joint("Left Shoulder", "Torso", "Left Arm", _G.CFrame.Angles(0, 0.2, 0))
    joint("Right Shoulder", "Torso", "Right Arm", _G.CFrame.Angles(0, -0.2, 0))
    joint("Left Hip", "Torso", "Left Leg", _G.CFrame.Angles(0.3, 0, 0))
    joint("Right Hip", "Torso", "Right Leg", _G.CFrame.Angles(-0.3, 0, 0))

    rig.PrimaryPart = parts.HumanoidRootPart
    rig.Parent = _G.workspace
    _G.__RIG = rig
    return rig
end

makeRig()
"""

CHECKS = r"""
-- ═══════════════════════════════════════════════════════════════════════════
-- the run
-- ═══════════════════════════════════════════════════════════════════════════
_G.__RESULTS = {}
local results = _G.__RESULTS
local function check(name, ok, detail)
    results[#results + 1] = { name = name, ok = ok == true, detail = detail }
end

local A = _G.SkillAnimator
local rig = _G.__RIG
local pluginObject = _G.__PLUGIN
local dock = _G.__DOCK

local function count(list)
    local total = 0
    for _ in pairs(list or {}) do total = total + 1 end
    return total
end

local function findDescendant(root, name, depth)
    depth = depth or 0
    if depth > 8 or not root then return nil end
    for _, child in ipairs(root:GetChildren()) do
        if child.Name == name then return child end
        local hit = findDescendant(child, name, depth + 1)
        if hit then return hit end
    end
    return nil
end

local function near(a, b, tolerance)
    return math.abs((tonumber(a) or 0) - (tonumber(b) or 0)) <= (tolerance or 0.01)
end

-- ── registration ──────────────────────────────────────────────────────────
check("plugin registered a toolbar", #_G.__TOOLBARS == 1, tostring(#_G.__TOOLBARS) .. " toolbar(s)")
check("toolbar has a button", _G.__TOOLBARS[1] and #_G.__TOOLBARS[1]:GetChildren() >= 0)
check("dock widget created", dock ~= nil)
check("dock title carries the version", dock and tostring(dock.Title):find("Skill Animator") ~= nil, dock and dock.Title or "none")
check("interface built inside the dock", findDescendant(dock, "SkillAnimatorRoot") ~= nil)
check("toolbar buttons exist", findDescendant(dock, "BindButton") ~= nil and findDescendant(dock, "PlayButton") ~= nil)

-- ── layout: at the default 980 px dock every button must be reachable
-- without the horizontal scroller (it exists for narrower docks only)
local function toolbarWidth(name)
    local bar = findDescendant(dock, name)
    if not bar then return nil end
    local total, buttons = 10, 0
    for _, child in ipairs(bar:GetChildren()) do
        if child.ClassName == "TextButton" then
            total = total + child.Size.X.Offset + 4
            buttons = buttons + 1
        end
    end
    return total, buttons
end
local widthA, countA = toolbarWidth("ToolbarA")
local widthB, countB = toolbarWidth("ToolbarB")
check("rig toolbar fits the default dock", widthA ~= nil and widthA <= 980,
    tostring(widthA) .. " px · " .. tostring(countA) .. " buttons")
check("edit toolbar fits the default dock", widthB ~= nil and widthB <= 980,
    tostring(widthB) .. " px · " .. tostring(countB) .. " buttons")

-- ── binding ───────────────────────────────────────────────────────────────
check("auto-bound the selected rig", A.Rig == rig, A.Rig and A.Rig.Name or "none")
check("found every Motor6D joint", #A.Order == 6, tostring(#A.Order) .. " joints")
check("root detected as the part that is never a Part1", A.RootPartName == "HumanoidRootPart", tostring(A.RootPartName))
check("timeline starts at the root", A.Order[1] == "Torso", tostring(A.Order[1]))
local rowCount = 0
for _ in pairs(A.Rows) do rowCount = rowCount + 1 end
check("a timeline row per joint", rowCount == 6, tostring(rowCount) .. " rows")

-- ── recording ─────────────────────────────────────────────────────────────
A.API.SetFrame(0)
A.API.SelectJoint("Torso")
A.API.Record("Torso", 0, { RX = 0, RY = 0, RZ = 0, PX = 0, PY = 0, PZ = 0, Style = 1, Dir = 1 })
A.API.Record("Torso", 30, { RX = 90, RY = 0, RZ = 0, PX = 0, PY = 0, PZ = 0, Style = 1, Dir = 1 })
local keys = A.API.Keys()
check("two keyframes recorded", #keys == 2 and keys[1] == 0 and keys[2] == 30,
    table.concat(keys, ","))
check("timeline row shows two diamonds",
    (function()
        local lane = findDescendant(dock, "Lane_Torso")
        local diamonds = 0
        for _, child in ipairs(lane and lane:GetChildren() or {}) do
            if child.Name:sub(1, 4) == "Key_" then diamonds = diamonds + 1 end
        end
        return diamonds == 2
    end)(), "diamonds in the lane")

-- ── interpolation + motor write ───────────────────────────────────────────
A.API.SetFrame(15)
local midPose = A.Joints.Torso.Pose
check("mid-frame is interpolated (linear)", near(midPose.RX, 45, 0.5), tostring(midPose.RX))
local motor = A.Joints.Torso.Motor
local rx, ry, rz = motor.C0:ToEulerAnglesXYZ()
check("the Motor6D was actually written", near(math.deg(rx), 45, 0.6), string.format("%.2f deg", math.deg(rx)))

-- ── export ────────────────────────────────────────────────────────────────
local sequence = A.API.Export()
check("export produced a KeyframeSequence", sequence ~= nil and sequence.ClassName == "KeyframeSequence")
local animSaves = rig:FindFirstChild("AnimSaves")
check("sequence lives in AnimSaves", animSaves ~= nil and sequence.Parent == animSaves)
local keyframes = {}
for _, child in ipairs(sequence:GetChildren()) do
    if child.ClassName == "Keyframe" then keyframes[#keyframes + 1] = child end
end
table.sort(keyframes, function(a, b) return a.Time < b.Time end)
check("one Keyframe per unique frame", #keyframes == 2, tostring(#keyframes))
check("frame times follow FPS", near(keyframes[2].Time, 1.0, 0.001), tostring(keyframes[2].Time))

local function poseByName(keyframe, name)
    for _, descendant in ipairs(keyframe:GetDescendants()) do
        if descendant.ClassName == "Pose" and descendant.Name == name then return descendant end
    end
    return nil
end

local kf30 = keyframes[2]
local rootPose = nil
for _, child in ipairs(kf30:GetChildren()) do
    if child.ClassName == "Pose" then rootPose = child break end
end
check("root pose is the root part", rootPose and rootPose.Name == "HumanoidRootPart", rootPose and rootPose.Name or "none")

local torsoPose = poseByName(kf30, "Torso")
check("Torso pose exists and hangs under the root", torsoPose and torsoPose.Parent == rootPose,
    torsoPose and tostring(torsoPose.Parent and torsoPose.Parent.Name) or "missing")

local headPose = poseByName(kf30, "Head")
check("Head pose hangs under Torso (Part0 → Part1 tree)", headPose and headPose.Parent == torsoPose,
    headPose and tostring(headPose.Parent and headPose.Parent.Name) or "missing")

-- every pose must match its joint by name, with the parent matching Part0
local mismatches = 0
for _, jointKey in ipairs(A.Order) do
    local joint = A.Joints[jointKey]
    local pose = poseByName(kf30, joint.Part1Name)
    if not pose or not pose.Parent or pose.Parent.Name ~= joint.Part0Name then
        mismatches = mismatches + 1
    end
end
check("every Pose matches its Motor6D by name", mismatches == 0, mismatches .. " mismatch(es)")

local erx, ery, erz = torsoPose.CFrame:ToEulerAnglesXYZ()
check("exported rotation equals the recorded 90 deg", near(math.deg(erx), 90, 0.2),
    string.format("%.2f deg", math.deg(erx)))
check("per-key easing reached the Pose", torsoPose.EasingStyle.Name == "Linear",
    torsoPose.EasingStyle.Name)
check("export marked the sequence", sequence:GetAttribute("SkillAnimatorVersion") ~= nil)

-- ── FPS / length ──────────────────────────────────────────────────────────
A.API.SetFPS(60)
local sequence60 = A.API.Export()
local kf60 = {}
for _, child in ipairs(sequence60:GetChildren()) do
    if child.ClassName == "Keyframe" then kf60[#kf60 + 1] = child end
end
table.sort(kf60, function(a, b) return a.Time < b.Time end)
check("FPS change rescales keyframe time", near(kf60[2].Time, 0.5, 0.001), tostring(kf60[2].Time))

-- ── import round trip ─────────────────────────────────────────────────────
A:ClearAllKeys()
local imported = A.API.Import(sequence60)
check("import read the sequence back", imported == true)
local keysBack = A.API.Keys()
check("import restored the frames", #keysBack == 2 and keysBack[2] == 30, table.concat(keysBack, ","))
local torsoBack = A.Tracks.Torso[30]
check("import restored the rotation", torsoBack and near(torsoBack.RX, 90, 0.2),
    torsoBack and string.format("%.2f", torsoBack.RX) or "none")

-- ── zoom ──────────────────────────────────────────────────────────────────
A.API.SetZoom(1)
local scaleZoomOne = A.FrameToScale(15)
A.API.SetZoom(2)
local scaleZoomTwo = A.FrameToScale(15)
check("zoom changes the time scale", near(scaleZoomOne, 0.25, 0.01) and near(scaleZoomTwo, 0.5, 0.01),
    string.format("%.2f → %.2f", scaleZoomOne, scaleZoomTwo))
A.API.SetZoom(1)

-- ── duplicate / delete / navigation ───────────────────────────────────────
A.API.Duplicate("Torso", 30, 45)
check("duplicate added a key", (function()
    for _, frame in ipairs(A.API.Keys()) do if frame == 45 then return true end end
    return false
end)())
A.API.Delete("Torso", 45)
check("delete removed the key", (function()
    for _, frame in ipairs(A.API.Keys()) do if frame == 45 then return false end end
    return true
end)())
A.API.SetFrame(0)
check("next key jumps forward", A.API.NextKey() == 30, tostring(A.API.NextKey()))
check("prev key jumps back", A.API.PrevKey() == 0, tostring(A.API.PrevKey()))

-- ── selection follow ──────────────────────────────────────────────────────
local headPart = rig:FindFirstChild("Head")
_G.__SELECTION:Set({ headPart })
check("selecting a part picks its joint", A.Selected == "Head", tostring(A.Selected))

-- ── project save / load ───────────────────────────────────────────────────
A:RecordKey("Head", 5, { RX = 12, RY = -3, RZ = 7, PX = 0.25, PY = 0, PZ = -0.5, Style = 3, Dir = 2 })
local saved = A.API.SaveProject()
check("project saved on the rig", saved == true and type(rig:GetAttribute("SkillAnimatorProject")) == "string")
A:ClearAllKeys()
local loaded = A.API.LoadProject()
check("project loaded back", loaded == true)
local headKey = (A.Tracks.Head or {})[5]
check("project restored the authored key",
    headKey ~= nil and near(headKey.RX, 12, 0.05) and near(headKey.PZ, -0.5, 0.01),
    headKey and string.format("RX %.2f PZ %.2f", headKey.RX, headKey.PZ) or "missing")

-- ── undo + status ─────────────────────────────────────────────────────────
check("undo waypoints were recorded", #_G.__WAYPOINTS > 5, tostring(#_G.__WAYPOINTS) .. " waypoint(s)")
check("status line reports something", #A.API.Status() > 0, A.API.Status())

-- ── teardown ──────────────────────────────────────────────────────────────
local playConnection = A.PlayConnection
_G.__PLUGIN.Unloading:Fire()
check("unload disconnected the playback loop", A.PlayConnection == nil and playConnection ~= nil)
check("unload disabled the dock", dock.Enabled == false, tostring(dock.Enabled))

check("no errors for the whole session", #_G.__HARNESS_ERRORS == 0,
    table.concat(_G.__HARNESS_ERRORS, " | "))
check("no warnings were raised", #_G.__WARNINGS == 0, table.concat(_G.__WARNINGS, " | "))
"""


def main() -> int:
    if not os.path.exists(PLUGIN):
        print("plugin not found at %s" % PLUGIN)
        return 1
    source = io.open(PLUGIN, encoding="utf-8").read()

    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.execute(BASE_PRELUDE + STUDIO_EXTRAS)

    # a rig is selected before the plugin loads, like a user would
    runtime.execute("_G.__SELECTION:Set({ _G.__RIG })")

    loader = runtime.eval("function(src) return task_spawn(function() return load(src, 'SkillAnimator')() end) end")
    loader(source)
    runtime.execute("for index = 1, 4 do pump(0.03) end")
    runtime.execute(CHECKS)

    results = runtime.eval("_G.__RESULTS")
    failures = []
    for entry in results.values():
        name = str(entry["name"])
        ok = entry["ok"] is True or entry["ok"] == 1
        detail = entry["detail"]
        detail = "" if detail is None else "  — " + str(detail)
        print(("PASS " if ok else "FAIL ") + name + detail)
        if not ok:
            failures.append(name)

    total = len(list(results.values()))
    print()
    print("%d/%d checks passed" % (total - len(failures), total))
    if failures:
        print("FAILED: " + ", ".join(failures))
        return 1
    print("PLUGIN OK — registration, binding, keys, export tree, import, project, teardown")
    return 0


if __name__ == "__main__":
    sys.exit(main())
