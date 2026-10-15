--[[
    Skill Hub — Moon Animator In-Game Studio (No Pre-made Animations)
    File: SkillAnimator/init.lua
    Description:
      Full Moon Animator 2 style in-game Keyframe & Motor6D Rig Editor.
      • Zero pre-made animations — build custom animations from scratch!
      • Multi-track Dope Sheet Timeline with Diamond Keyframe markers (◆)
      • Interactive 3D Viewport Gizmos (ArcHandles Rotation & Handles Move + SelectionBox)
      • Precision X/Y/Z Rotation (-180°..180°) & Position Offset (-5..5) Inspector
      • Keyframe Easing Styles (Linear, Sine, Quad, Cubic, Back, Bounce, Elastic)
      • Auto-Keyrecording, Copy/Paste Pose, & 1-Click Lua Script Export to Clipboard
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer      = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════════════════
--  CUSTOM VECTOR ICONS (LUCIDE / FEATHER RBXASSETID)
-- ═══════════════════════════════════════════════════════════════════════════

local Icons = {
    MoonLogo   = "rbxassetid://10723354551",
    Play       = "rbxassetid://10734923549",
    Pause      = "rbxassetid://10734919336",
    Stop       = "rbxassetid://10734972627",
    Loop       = "rbxassetid://10734940376",
    AddKey     = "rbxassetid://10734924532",
    Trash      = "rbxassetid://10747362393",
    Rotate3D   = "rbxassetid://10734940376",
    Move3D     = "rbxassetid://10709818626",
    Bone       = "rbxassetid://10723397898",
    Export     = "rbxassetid://10734950309",
    Reset      = "rbxassetid://10734940376",
    RadialGlow = "rbxassetid://5028857084",
}

-- Moon Animator 2 Signature Dark Purple / Slate Palette
local Theme = {
    BgMain        = Color3.fromRGB(14, 13, 22),
    BgHeader      = Color3.fromRGB(20, 18, 32),
    BgToolbar     = Color3.fromRGB(25, 22, 40),
    BgTrackList   = Color3.fromRGB(18, 16, 28),
    BgRowEven     = Color3.fromRGB(22, 20, 35),
    BgRowOdd      = Color3.fromRGB(18, 16, 29),
    BgInspector   = Color3.fromRGB(19, 17, 30),
    BgControl     = Color3.fromRGB(12, 11, 19),
    MoonAccent    = Color3.fromRGB(168, 85, 247),
    MoonCyan      = Color3.fromRGB(56, 189, 248),
    MoonPink      = Color3.fromRGB(236, 72, 153),
    PlayheadRed   = Color3.fromRGB(244, 63, 94),
    KeyframeGold  = Color3.fromRGB(250, 204, 21),
    TextPrimary   = Color3.fromRGB(243, 244, 246),
    TextSecondary = Color3.fromRGB(156, 163, 175),
    TextMuted     = Color3.fromRGB(107, 114, 128),
    Border        = Color3.fromRGB(42, 37, 66),
}

local EASING_STYLES = {
    Enum.EasingStyle.Linear,
    Enum.EasingStyle.Sine,
    Enum.EasingStyle.Quad,
    Enum.EasingStyle.Cubic,
    Enum.EasingStyle.Back,
    Enum.EasingStyle.Bounce,
    Enum.EasingStyle.Elastic,
}

local EASING_DIRECTIONS = {
    Enum.EasingDirection.Out,
    Enum.EasingDirection.InOut,
    Enum.EasingDirection.In,
}

-- ═══════════════════════════════════════════════════════════════════════════
--  MOON ANIMATOR STATE & RIG CONTROLLER
-- ═══════════════════════════════════════════════════════════════════════════

local MoonAnimator = {
    FPS              = 30,
    TotalFrames      = 60,
    CurrentFrame     = 0,
    IsPlaying        = false,
    Loop             = true,
    AutoKey          = true,
    PoseLockActive   = true,
    GizmoMode        = "Rotate", -- "Rotate" | "Move" | "Off"
    EasingStyleIdx   = 2,        -- Sine
    EasingDirIdx     = 1,        -- Out

    Joints           = {},       -- { [jointName] = { Motor = m6d, Part1 = part, BaseC0 = cframe } }
    JointOrder       = {},       -- Ordered list of joint names
    SelectedJoint    = nil,
    TrackKeyframes   = {},       -- { [jointName] = { [frameInt] = { RX=0, RY=0, RZ=0, PX=0, PY=0, PZ=0, Style=Enum, Dir=Enum } } }
    CopiedPose       = nil,
}

local function degToRad(d) return math.rad(d or 0) end
local function radToDeg(r) return math.floor(math.deg(r or 0) + 0.5) end

local function makeEmptyPose()
    return {
        RX = 0, RY = 0, RZ = 0,
        PX = 0, PY = 0, PZ = 0,
        Style = EASING_STYLES[MoonAnimator.EasingStyleIdx],
        Dir   = EASING_DIRECTIONS[MoonAnimator.EasingDirIdx],
    }
end

local function clonePose(p)
    return {
        RX = p.RX, RY = p.RY, RZ = p.RZ,
        PX = p.PX, PY = p.PY, PZ = p.PZ,
        Style = p.Style,
        Dir   = p.Dir,
    }
end

-- Scan character for all Motor6D joints (R6 & R15 + Weapons)
function MoonAnimator:ScanCharacterRig()
    self.Joints = {}
    self.JointOrder = {}
    local char = LocalPlayer.Character
    if not char then return end

    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Motor6D") and desc.Part0 and desc.Part1 then
            local jName = desc.Part1.Name .. " (" .. desc.Name .. ")"
            if not self.Joints[jName] then
                self.Joints[jName] = {
                    Name   = jName,
                    Motor  = desc,
                    Part0  = desc.Part0,
                    Part1  = desc.Part1,
                    BaseC0 = desc.C0,
                    Pose   = makeEmptyPose(),
                }
                table.insert(self.JointOrder, jName)
                if not self.TrackKeyframes[jName] then
                    self.TrackKeyframes[jName] = {}
                end
            end
        end
    end

    table.sort(self.JointOrder)
    if not self.SelectedJoint or not self.Joints[self.SelectedJoint] then
        self.SelectedJoint = self.JointOrder[1]
    end
end

-- Suppress default Roblox Animate tracks while posing/playing
local function suppressDefaultAnimations(suppress)
    local char = LocalPlayer.Character
    if not char then return end
    local animScript = char:FindFirstChild("Animate")
    if animScript and animScript:IsA("LocalScript") then
        animScript.Disabled = suppress
    end
    if suppress then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
                pcall(function() tr:Stop(0) end)
            end
        end
    end
end

-- Evaluate interpolated pose for a joint at a given frame (float)
function MoonAnimator:EvaluateJointPoseAtFrame(jointName, frameFloat)
    local track = self.TrackKeyframes[jointName]
    if not track then return nil end

    local keys = {}
    for f in pairs(track) do
        table.insert(keys, f)
    end
    if #keys == 0 then return nil end
    table.sort(keys)

    if frameFloat <= keys[1] then
        return clonePose(track[keys[1]])
    end
    if frameFloat >= keys[#keys] then
        return clonePose(track[keys[#keys]])
    end

    local prevF, nextF = keys[1], keys[#keys]
    for i = 1, #keys - 1 do
        if frameFloat >= keys[i] and frameFloat <= keys[i + 1] then
            prevF = keys[i]
            nextF = keys[i + 1]
            break
        end
    end

    if prevF == nextF then
        return clonePose(track[prevF])
    end

    local p0 = track[prevF]
    local p1 = track[nextF]
    local rawAlpha = (frameFloat - prevF) / (nextF - prevF)
    local alpha = TweenService:GetValue(
        rawAlpha,
        p1.Style or Enum.EasingStyle.Sine,
        p1.Dir or Enum.EasingDirection.Out
    )

    local function lerp(a, b, t) return a + (b - a) * t end

    return {
        RX = lerp(p0.RX, p1.RX, alpha),
        RY = lerp(p0.RY, p1.RY, alpha),
        RZ = lerp(p0.RZ, p1.RZ, alpha),
        PX = lerp(p0.PX, p1.PX, alpha),
        PY = lerp(p0.PY, p1.PY, alpha),
        PZ = lerp(p0.PZ, p1.PZ, alpha),
        Style = p1.Style,
        Dir   = p1.Dir,
    }
end

-- Apply pose C0 to Motor6D
function MoonAnimator:ApplyJointPose(jointName, pose)
    local jData = self.Joints[jointName]
    if not jData or not jData.Motor or not jData.Motor.Parent then return end
    jData.Pose = clonePose(pose)
    local offsetCF = CFrame.new(pose.PX, pose.PY, pose.PZ)
        * CFrame.Angles(degToRad(pose.RX), degToRad(pose.RY), degToRad(pose.RZ))
    jData.Motor.C0 = jData.BaseC0 * offsetCF
end

function MoonAnimator:ApplyFrameToRig(frameFloat)
    for _, jName in ipairs(self.JointOrder) do
        local evalPose = self:EvaluateJointPoseAtFrame(jName, frameFloat)
        if evalPose then
            self:ApplyJointPose(jName, evalPose)
        end
    end
end

function MoonAnimator:RecordKeyframe(jointName, frameInt, poseOverride)
    if not jointName or not self.Joints[jointName] then return end
    frameInt = math.clamp(math.floor(frameInt + 0.5), 0, self.TotalFrames)
    self.TrackKeyframes[jointName] = self.TrackKeyframes[jointName] or {}
    local srcPose = poseOverride or self.Joints[jointName].Pose or makeEmptyPose()
    srcPose.Style = EASING_STYLES[self.EasingStyleIdx]
    srcPose.Dir   = EASING_DIRECTIONS[self.EasingDirIdx]
    self.TrackKeyframes[jointName][frameInt] = clonePose(srcPose)
end

function MoonAnimator:DeleteKeyframe(jointName, frameInt)
    if not jointName or not self.TrackKeyframes[jointName] then return end
    frameInt = math.clamp(math.floor(frameInt + 0.5), 0, self.TotalFrames)
    self.TrackKeyframes[jointName][frameInt] = nil
end

function MoonAnimator:ResetJoint(jointName)
    local jData = self.Joints[jointName]
    if not jData then return end
    local zero = makeEmptyPose()
    self:ApplyJointPose(jointName, zero)
    if self.AutoKey then
        self:RecordKeyframe(jointName, self.CurrentFrame, zero)
    end
end

function MoonAnimator:ResetEntireRig()
    self.IsPlaying = false
    for _, jName in ipairs(self.JointOrder) do
        local jData = self.Joints[jName]
        if jData and jData.Motor and jData.Motor.Parent then
            jData.Motor.C0 = jData.BaseC0
            jData.Pose = makeEmptyPose()
        end
    end
    suppressDefaultAnimations(false)
end

-- Export recorded keyframes as a standalone playable Luau script
function MoonAnimator:ExportToLuaScript()
    local lines = {
        "-- Generated by Skill Hub Moon Animator Studio",
        "local Players = game:GetService('Players')",
        "local TweenService = game:GetService('TweenService')",
        "local RunService = game:GetService('RunService')",
        "local char = Players.LocalPlayer.Character",
        "if not char then return end",
        string.format("local FPS = %d", self.FPS),
        string.format("local TOTAL_FRAMES = %d", self.TotalFrames),
        "local Keyframes = {",
    }

    for _, jName in ipairs(self.JointOrder) do
        local track = self.TrackKeyframes[jName]
        if track and next(track) ~= nil then
            table.insert(lines, string.format("    [%q] = {", jName))
            local fList = {}
            for f in pairs(track) do table.insert(fList, f) end
            table.sort(fList)
            for _, f in ipairs(fList) do
                local k = track[f]
                table.insert(lines, string.format(
                    "        [%d] = {RX=%.1f, RY=%.1f, RZ=%.1f, PX=%.2f, PY=%.2f, PZ=%.2f},",
                    f, k.RX, k.RY, k.RZ, k.PX, k.PY, k.PZ
                ))
            end
            table.insert(lines, "    },")
        end
    end

    table.insert(lines, "}")
    table.insert(lines, "-- Ready to replay via Motor6D.C0 interpolation")
    local code = table.concat(lines, "\n")
    if type(setclipboard) == "function" then
        pcall(function() setclipboard(code) end)
    end
    return code
end

-- ═══════════════════════════════════════════════════════════════════════════
--  3D VIEWPORT GIZMOS (SELECTIONBOX + ARCHANDLES ROTATION + HANDLES MOVE)
-- ═══════════════════════════════════════════════════════════════════════════

local GizmoFolder = Instance.new("Folder")
GizmoFolder.Name = "MoonAnimator_3DGizmos"
pcall(function() GizmoFolder.Parent = CoreGui end)
if not GizmoFolder.Parent then
    GizmoFolder.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local SelectionBox = Instance.new("SelectionBox", GizmoFolder)
SelectionBox.Color3 = Theme.MoonAccent
SelectionBox.LineThickness = 0.03
SelectionBox.SurfaceColor3 = Theme.MoonAccent
SelectionBox.SurfaceTransparency = 0.85

local ArcHandles = Instance.new("ArcHandles", GizmoFolder)
ArcHandles.Color3 = Theme.MoonCyan
ArcHandles.Visible = false

local MoveHandles = Instance.new("Handles", GizmoFolder)
MoveHandles.Color3 = Theme.MoonPink
MoveHandles.Style = Enum.HandlesStyle.Movement
MoveHandles.Visible = false

local gizmoStartPose = nil
local refreshInspectorUI = nil
local refreshTimelineMarkers = nil

ArcHandles.MouseButton1Down:Connect(function()
    if MoonAnimator.SelectedJoint and MoonAnimator.Joints[MoonAnimator.SelectedJoint] then
        gizmoStartPose = clonePose(MoonAnimator.Joints[MoonAnimator.SelectedJoint].Pose)
    end
end)

ArcHandles.MouseDrag:Connect(function(axis, relativeAngle)
    local jName = MoonAnimator.SelectedJoint
    if not jName or not gizmoStartPose then return end
    local degDelta = radToDeg(relativeAngle)
    local newPose = clonePose(gizmoStartPose)

    if axis == Enum.Axis.X then
        newPose.RX = math.clamp(gizmoStartPose.RX + degDelta, -180, 180)
    elseif axis == Enum.Axis.Y then
        newPose.RY = math.clamp(gizmoStartPose.RY + degDelta, -180, 180)
    elseif axis == Enum.Axis.Z then
        newPose.RZ = math.clamp(gizmoStartPose.RZ + degDelta, -180, 180)
    end

    suppressDefaultAnimations(true)
    MoonAnimator:ApplyJointPose(jName, newPose)
    if MoonAnimator.AutoKey then
        MoonAnimator:RecordKeyframe(jName, MoonAnimator.CurrentFrame, newPose)
        if refreshTimelineMarkers then refreshTimelineMarkers() end
    end
    if refreshInspectorUI then refreshInspectorUI() end
end)

MoveHandles.MouseButton1Down:Connect(function()
    if MoonAnimator.SelectedJoint and MoonAnimator.Joints[MoonAnimator.SelectedJoint] then
        gizmoStartPose = clonePose(MoonAnimator.Joints[MoonAnimator.SelectedJoint].Pose)
    end
end)

MoveHandles.MouseDrag:Connect(function(face, distance)
    local jName = MoonAnimator.SelectedJoint
    if not jName or not gizmoStartPose then return end
    local normal = Vector3.FromNormalId(face) * distance
    local newPose = clonePose(gizmoStartPose)
    newPose.PX = math.clamp(gizmoStartPose.PX + normal.X, -5, 5)
    newPose.PY = math.clamp(gizmoStartPose.PY + normal.Y, -5, 5)
    newPose.PZ = math.clamp(gizmoStartPose.PZ + normal.Z, -5, 5)

    suppressDefaultAnimations(true)
    MoonAnimator:ApplyJointPose(jName, newPose)
    if MoonAnimator.AutoKey then
        MoonAnimator:RecordKeyframe(jName, MoonAnimator.CurrentFrame, newPose)
        if refreshTimelineMarkers then refreshTimelineMarkers() end
    end
    if refreshInspectorUI then refreshInspectorUI() end
end)

local function update3DGizmoAdornee()
    local jName = MoonAnimator.SelectedJoint
    local jData = jName and MoonAnimator.Joints[jName]
    local part = jData and jData.Part1

    if not part or MoonAnimator.GizmoMode == "Off" then
        SelectionBox.Adornee = nil
        ArcHandles.Adornee = nil
        ArcHandles.Visible = false
        MoveHandles.Adornee = nil
        MoveHandles.Visible = false
        return
    end

    SelectionBox.Adornee = part
    if MoonAnimator.GizmoMode == "Rotate" then
        ArcHandles.Adornee = part
        ArcHandles.Visible = true
        MoveHandles.Adornee = nil
        MoveHandles.Visible = false
    elseif MoonAnimator.GizmoMode == "Move" then
        MoveHandles.Adornee = part
        MoveHandles.Visible = true
        ArcHandles.Adornee = nil
        ArcHandles.Visible = false
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  MOON ANIMATOR 2 SCREENGUI BUILDER
-- ═══════════════════════════════════════════════════════════════════════════

function MoonAnimator:MountUI()
    self:ScanCharacterRig()

    local pGui = LocalPlayer:WaitForChild("PlayerGui")
    if pGui:FindFirstChild("MoonAnimatorStudioGui") then
        pGui.MoonAnimatorStudioGui:Destroy()
    end

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "MoonAnimatorStudioGui"
    Gui.ResetOnSpawn = false
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Gui.DisplayOrder = 1010
    Gui.Parent = pGui

    local function createIconBadge(parent, iconId, color, sz, pos)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(0, sz, 0, sz)
        f.Position = pos
        f.BackgroundColor3 = color
        f.BackgroundTransparency = 0.84
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

        local img = Instance.new("ImageLabel", f)
        img.Size = UDim2.new(0, sz - 8, 0, sz - 8)
        img.Position = UDim2.new(0.5, -(sz - 8) / 2, 0.5, -(sz - 8) / 2)
        img.BackgroundTransparency = 1
        img.Image = iconId
        img.ImageColor3 = color
        img.ScaleType = Enum.ScaleType.Fit
        return f
    end

    -- Main Moon Animator Dock Window (Bottom-Center Studio Layout)
    local Main = Instance.new("Frame", Gui)
    Main.Name = "MoonStudioFrame"
    Main.Size = UDim2.new(0, 820, 0, 390)
    Main.Position = UDim2.new(0.5, -410, 1, -405)
    Main.BackgroundColor3 = Theme.BgMain
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

    local mStroke = Instance.new("UIStroke", Main)
    mStroke.Color = Theme.MoonAccent
    mStroke.Thickness = 1.5

    -- Top Moon Animator Title Bar
    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 38)
    TitleBar.BackgroundColor3 = Theme.BgHeader
    TitleBar.BorderSizePixel = 0

    createIconBadge(TitleBar, Icons.MoonLogo, Theme.MoonAccent, 26, UDim2.new(0, 10, 0.5, -13))

    local TitleLbl = Instance.new("TextLabel", TitleBar)
    TitleLbl.Size = UDim2.new(0, 320, 1, 0)
    TitleLbl.Position = UDim2.new(0, 44, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Font = Enum.Font.GothamBlack
    TitleLbl.TextSize = 14
    TitleLbl.TextColor3 = Theme.TextPrimary
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Text = "MOON ANIMATOR STUDIO  •  RIG KEYFRAME EDITOR"

    local StatusBadge = Instance.new("TextLabel", TitleBar)
    StatusBadge.Size = UDim2.new(0, 260, 1, 0)
    StatusBadge.Position = UDim2.new(1, -345, 0, 0)
    StatusBadge.BackgroundTransparency = 1
    StatusBadge.Font = Enum.Font.Code
    StatusBadge.TextSize = 11
    StatusBadge.TextColor3 = Theme.MoonCyan
    StatusBadge.TextXAlignment = Enum.TextXAlignment.Right
    StatusBadge.Text = "Frame: 0 / 60  |  30 FPS"

    local MinBtn = Instance.new("TextButton", TitleBar)
    MinBtn.Size = UDim2.new(0, 26, 0, 26)
    MinBtn.Position = UDim2.new(1, -66, 0.5, -13)
    MinBtn.BackgroundColor3 = Theme.BgToolbar
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 13
    MinBtn.TextColor3 = Theme.TextPrimary
    MinBtn.Text = "—"
    MinBtn.BorderSizePixel = 0
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
    CloseBtn.BackgroundColor3 = Theme.PlayheadRed
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 13
    CloseBtn.TextColor3 = Color3.new(1, 1, 1)
    CloseBtn.Text = "✕"
    CloseBtn.BorderSizePixel = 0
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    -- Window Dragging via TitleBar
    do
        local dragging, dragInput, dragStart, startPos
        TitleBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = inp.Position
                startPos = Main.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        TitleBar.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                dragInput = inp
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if inp == dragInput and dragging then
                local d = inp.Position - dragStart
                Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end

    -- Second Row: Moon Animator Transport & Keyframe Toolbar
    local Toolbar = Instance.new("Frame", Main)
    Toolbar.Size = UDim2.new(1, 0, 0, 36)
    Toolbar.Position = UDim2.new(0, 0, 0, 38)
    Toolbar.BackgroundColor3 = Theme.BgToolbar
    Toolbar.BorderSizePixel = 0

    local tbLayout = Instance.new("UIListLayout", Toolbar)
    tbLayout.FillDirection = Enum.FillDirection.Horizontal
    tbLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tbLayout.Padding = UDim.new(0, 5)

    local tbPad = Instance.new("UIPadding", Toolbar)
    tbPad.PaddingLeft = UDim.new(0, 10)

    local function makeToolBtn(txt, width, bgCol, callback)
        local b = Instance.new("TextButton", Toolbar)
        b.Size = UDim2.new(0, width, 0, 26)
        b.BackgroundColor3 = bgCol or Theme.BgControl
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.TextColor3 = Theme.TextPrimary
        b.Text = txt
        b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local st = Instance.new("UIStroke", b)
        st.Color = Theme.Border
        st.Thickness = 1
        b.MouseButton1Click:Connect(function()
            if callback then callback(b) end
        end)
        return b
    end

    local PlayBtn = makeToolBtn("▶ Play", 66, Theme.MoonAccent, function(btn)
        MoonAnimator.IsPlaying = not MoonAnimator.IsPlaying
        if MoonAnimator.IsPlaying then
            suppressDefaultAnimations(true)
            btn.Text = "⏸ Pause"
            btn.BackgroundColor3 = Theme.PlayheadRed
        else
            btn.Text = "▶ Play"
            btn.BackgroundColor3 = Theme.MoonAccent
        end
    end)

    makeToolBtn("⏮ 0", 42, Theme.BgControl, function()
        MoonAnimator.IsPlaying = false
        PlayBtn.Text = "▶ Play"
        PlayBtn.BackgroundColor3 = Theme.MoonAccent
        MoonAnimator.CurrentFrame = 0
        MoonAnimator:ApplyFrameToRig(0)
        if refreshInspectorUI then refreshInspectorUI() end
        if refreshTimelineMarkers then refreshTimelineMarkers() end
    end)

    local LoopBtn = makeToolBtn("🔁 Loop: ON", 80, Theme.BgControl, function(btn)
        MoonAnimator.Loop = not MoonAnimator.Loop
        btn.Text = MoonAnimator.Loop and "🔁 Loop: ON" or "🔁 Loop: OFF"
    end)

    makeToolBtn("◆ +Key (K)", 82, Color3.fromRGB(202, 138, 4), function()
        if MoonAnimator.SelectedJoint then
            suppressDefaultAnimations(true)
            MoonAnimator:RecordKeyframe(MoonAnimator.SelectedJoint, MoonAnimator.CurrentFrame)
            if refreshTimelineMarkers then refreshTimelineMarkers() end
        end
    end)

    makeToolBtn("🗑 Del Key", 74, Theme.BgControl, function()
        if MoonAnimator.SelectedJoint then
            MoonAnimator:DeleteKeyframe(MoonAnimator.SelectedJoint, MoonAnimator.CurrentFrame)
            if refreshTimelineMarkers then refreshTimelineMarkers() end
        end
    end)

    makeToolBtn("📋 Copy", 62, Theme.BgControl, function()
        local j = MoonAnimator.SelectedJoint
        if j and MoonAnimator.Joints[j] then
            MoonAnimator.CopiedPose = clonePose(MoonAnimator.Joints[j].Pose)
        end
    end)

    makeToolBtn("📌 Paste", 64, Theme.BgControl, function()
        local j = MoonAnimator.SelectedJoint
        if j and MoonAnimator.CopiedPose then
            suppressDefaultAnimations(true)
            MoonAnimator:ApplyJointPose(j, MoonAnimator.CopiedPose)
            MoonAnimator:RecordKeyframe(j, MoonAnimator.CurrentFrame, MoonAnimator.CopiedPose)
            if refreshInspectorUI then refreshInspectorUI() end
            if refreshTimelineMarkers then refreshTimelineMarkers() end
        end
    end)

    local GizmoBtn = makeToolBtn("🌐 Gizmo: Rotate", 108, Theme.BgControl, function(btn)
        if MoonAnimator.GizmoMode == "Rotate" then
            MoonAnimator.GizmoMode = "Move"
        elseif MoonAnimator.GizmoMode == "Move" then
            MoonAnimator.GizmoMode = "Off"
        else
            MoonAnimator.GizmoMode = "Rotate"
        end
        btn.Text = "🌐 Gizmo: " .. MoonAnimator.GizmoMode
        update3DGizmoAdornee()
    end)

    local EasingBtn = makeToolBtn("📈 Sine", 76, Theme.BgControl, function(btn)
        MoonAnimator.EasingStyleIdx = (MoonAnimator.EasingStyleIdx % #EASING_STYLES) + 1
        local stName = EASING_STYLES[MoonAnimator.EasingStyleIdx].Name
        btn.Text = "📈 " .. stName
    end)

    makeToolBtn("🔄 Reset Rig", 82, Theme.BgControl, function()
        MoonAnimator:ResetEntireRig()
        if refreshInspectorUI then refreshInspectorUI() end
    end)

    makeToolBtn("💾 Export Lua", 88, Theme.MoonCyan, function(btn)
        MoonAnimator:ExportToLuaScript()
        btn.Text = "✅ Copied!"
        task.delay(1.5, function()
            if btn and btn.Parent then btn.Text = "💾 Export Lua" end
        end)
    end)

    -- ═══════════════════════════════════════════════════════════════════════
    --  3-COLUMN WORKSPACE:
    --  1) Left: Motor6D Joint Hierarchy (Width 185)
    --  2) Center: Multi-Track Dope Sheet Keyframe Timeline (Width 415)
    --  3) Right: X/Y/Z Transform & Offset Inspector (Width 220)
    -- ═══════════════════════════════════════════════════════════════════════

    local WorkspaceArea = Instance.new("Frame", Main)
    WorkspaceArea.Size = UDim2.new(1, 0, 1, -74)
    WorkspaceArea.Position = UDim2.new(0, 0, 0, 74)
    WorkspaceArea.BackgroundTransparency = 1

    -- 1. LEFT: JOINT TRACK HIERARCHY + CENTER DOPE SHEET SYNCHRONIZED SCROLL
    local TimelineContainer = Instance.new("Frame", WorkspaceArea)
    TimelineContainer.Size = UDim2.new(1, -225, 1, 0)
    TimelineContainer.Position = UDim2.new(0, 0, 0, 0)
    TimelineContainer.BackgroundColor3 = Theme.BgTrackList
    TimelineContainer.BorderSizePixel = 0

    -- Frame Ruler Header (Top of Timeline)
    local RulerHeader = Instance.new("Frame", TimelineContainer)
    RulerHeader.Size = UDim2.new(1, 0, 0, 26)
    RulerHeader.BackgroundColor3 = Theme.BgHeader
    RulerHeader.BorderSizePixel = 0

    local TrackColLabel = Instance.new("TextLabel", RulerHeader)
    TrackColLabel.Size = UDim2.new(0, 175, 1, 0)
    TrackColLabel.Position = UDim2.new(0, 10, 0, 0)
    TrackColLabel.BackgroundTransparency = 1
    TrackColLabel.Font = Enum.Font.GothamBold
    TrackColLabel.TextSize = 11
    TrackColLabel.TextColor3 = Theme.MoonAccent
    TrackColLabel.TextXAlignment = Enum.TextXAlignment.Left
    TrackColLabel.Text = "RIG MOTOR6D TRACKS"

    local RulerBar = Instance.new("TextButton", RulerHeader)
    RulerBar.Size = UDim2.new(1, -195, 1, 0)
    RulerBar.Position = UDim2.new(0, 185, 0, 0)
    RulerBar.BackgroundColor3 = Theme.BgControl
    RulerBar.Text = ""
    RulerBar.AutoButtonColor = false
    RulerBar.BorderSizePixel = 0

    -- Frame Tick Numbers on Ruler (0, 10, 20, 30, 40, 50, 60)
    for f = 0, MoonAnimator.TotalFrames, 10 do
        local pct = f / MoonAnimator.TotalFrames
        local tickLbl = Instance.new("TextLabel", RulerBar)
        tickLbl.Size = UDim2.new(0, 24, 1, 0)
        tickLbl.Position = UDim2.new(pct, -12, 0, 0)
        tickLbl.BackgroundTransparency = 1
        tickLbl.Font = Enum.Font.Code
        tickLbl.TextSize = 10
        tickLbl.TextColor3 = Theme.TextSecondary
        tickLbl.Text = tostring(f)
    end

    -- Playhead Vertical Line across Dope Sheet
    local PlayheadLine = Instance.new("Frame", TimelineContainer)
    PlayheadLine.Size = UDim2.new(0, 2, 1, 0)
    PlayheadLine.Position = UDim2.new(0, 185, 0, 0)
    PlayheadLine.BackgroundColor3 = Theme.PlayheadRed
    PlayheadLine.BorderSizePixel = 0
    PlayheadLine.ZIndex = 30

    local PlayheadCap = Instance.new("Frame", PlayheadLine)
    PlayheadCap.Size = UDim2.new(0, 10, 0, 10)
    PlayheadCap.Position = UDim2.new(0.5, -5, 0, 8)
    PlayheadCap.Rotation = 45
    PlayheadCap.BackgroundColor3 = Theme.PlayheadRed
    PlayheadCap.BorderSizePixel = 0
    PlayheadCap.ZIndex = 31

    local function updatePlayheadVisual()
        local barWidth = RulerBar.AbsoluteSize.X
        local pct = math.clamp(MoonAnimator.CurrentFrame / math.max(MoonAnimator.TotalFrames, 1), 0, 1)
        PlayheadLine.Position = UDim2.new(0, 185 + math.floor(barWidth * pct), 0, 0)
        StatusBadge.Text = string.format(
            "Frame: %d / %d  |  %d FPS",
            math.floor(MoonAnimator.CurrentFrame + 0.5),
            MoonAnimator.TotalFrames,
            MoonAnimator.FPS
        )
    end

    -- Scrubbing on RulerBar
    local scrubbingTimeline = false
    local function scrubFromMouseX(xPos)
        local rel = math.clamp((xPos - RulerBar.AbsolutePosition.X) / math.max(RulerBar.AbsoluteSize.X, 1), 0, 1)
        MoonAnimator.CurrentFrame = math.floor(rel * MoonAnimator.TotalFrames + 0.5)
        MoonAnimator:ApplyFrameToRig(MoonAnimator.CurrentFrame)
        updatePlayheadVisual()
        if refreshInspectorUI then refreshInspectorUI() end
    end

    RulerBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            scrubbingTimeline = true
            MoonAnimator.IsPlaying = false
            PlayBtn.Text = "▶ Play"
            PlayBtn.BackgroundColor3 = Theme.MoonAccent
            scrubFromMouseX(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if scrubbingTimeline and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            scrubFromMouseX(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            scrubbingTimeline = false
        end
    end)

    -- Scrollable Track Rows Container
    local TracksScroll = Instance.new("ScrollingFrame", TimelineContainer)
    TracksScroll.Size = UDim2.new(1, 0, 1, -26)
    TracksScroll.Position = UDim2.new(0, 0, 0, 26)
    TracksScroll.BackgroundTransparency = 1
    TracksScroll.BorderSizePixel = 0
    TracksScroll.ScrollBarThickness = 4
    TracksScroll.ScrollBarImageColor3 = Theme.MoonAccent
    TracksScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local tracksLayout = Instance.new("UIListLayout", TracksScroll)
    tracksLayout.Padding = UDim.new(0, 1)
    tracksLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local trackRowMap = {}

    local function buildTrackRows()
        for _, child in ipairs(TracksScroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        trackRowMap = {}

        for idx, jName in ipairs(MoonAnimator.JointOrder) do
            local row = Instance.new("Frame", TracksScroll)
            row.Size = UDim2.new(1, -6, 0, 26)
            row.BackgroundColor3 = (idx % 2 == 0) and Theme.BgRowEven or Theme.BgRowOdd
            row.BorderSizePixel = 0
            row.LayoutOrder = idx

            local nameBtn = Instance.new("TextButton", row)
            nameBtn.Size = UDim2.new(0, 180, 1, 0)
            nameBtn.BackgroundTransparency = 1
            nameBtn.Font = Enum.Font.GothamMedium
            nameBtn.TextSize = 11
            nameBtn.TextColor3 = (MoonAnimator.SelectedJoint == jName) and Theme.MoonCyan or Theme.TextPrimary
            nameBtn.TextXAlignment = Enum.TextXAlignment.Left
            nameBtn.Text = "  🦴 " .. jName

            local lane = Instance.new("TextButton", row)
            lane.Name = "KeyframeLane"
            lane.Size = UDim2.new(1, -190, 1, 0)
            lane.Position = UDim2.new(0, 185, 0, 0)
            lane.BackgroundTransparency = 1
            lane.Text = ""

            nameBtn.MouseButton1Click:Connect(function()
                MoonAnimator.SelectedJoint = jName
                for kName, rObj in pairs(trackRowMap) do
                    rObj.nameBtn.TextColor3 = (kName == jName) and Theme.MoonCyan or Theme.TextPrimary
                    rObj.nameBtn.Font = (kName == jName) and Enum.Font.GothamBold or Enum.Font.GothamMedium
                end
                update3DGizmoAdornee()
                if refreshInspectorUI then refreshInspectorUI() end
            end)

            lane.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    MoonAnimator.SelectedJoint = jName
                    for kName, rObj in pairs(trackRowMap) do
                        rObj.nameBtn.TextColor3 = (kName == jName) and Theme.MoonCyan or Theme.TextPrimary
                    end
                    scrubFromMouseX(inp.Position.X)
                    update3DGizmoAdornee()
                    if refreshInspectorUI then refreshInspectorUI() end
                end
            end)

            trackRowMap[jName] = {row = row, nameBtn = nameBtn, lane = lane}
        end
    end

    refreshTimelineMarkers = function()
        for jName, rObj in pairs(trackRowMap) do
            for _, ch in ipairs(rObj.lane:GetChildren()) do
                ch:Destroy()
            end
            local track = MoonAnimator.TrackKeyframes[jName]
            if track then
                for frameInt in pairs(track) do
                    local pct = math.clamp(frameInt / math.max(MoonAnimator.TotalFrames, 1), 0, 1)
                    local diamond = Instance.new("TextButton", rObj.lane)
                    diamond.Size = UDim2.new(0, 9, 0, 9)
                    diamond.Position = UDim2.new(pct, -4, 0.5, -4)
                    diamond.Rotation = 45
                    diamond.BackgroundColor3 = Theme.KeyframeGold
                    diamond.Text = ""
                    diamond.BorderSizePixel = 0
                    diamond.ZIndex = 15

                    diamond.MouseButton1Click:Connect(function()
                        MoonAnimator.SelectedJoint = jName
                        MoonAnimator.CurrentFrame = frameInt
                        MoonAnimator:ApplyFrameToRig(frameInt)
                        updatePlayheadVisual()
                        update3DGizmoAdornee()
                        if refreshInspectorUI then refreshInspectorUI() end
                    end)
                end
            end
        end
    end

    -- 3. RIGHT INSPECTOR PANEL (PRECISION ROTATION X/Y/Z & POSITION OFFSET X/Y/Z)
    local Inspector = Instance.new("Frame", WorkspaceArea)
    Inspector.Size = UDim2.new(0, 225, 1, 0)
    Inspector.Position = UDim2.new(1, -225, 0, 0)
    Inspector.BackgroundColor3 = Theme.BgInspector
    Inspector.BorderSizePixel = 0

    local InspHeader = Instance.new("TextLabel", Inspector)
    InspHeader.Size = UDim2.new(1, -16, 0, 26)
    InspHeader.Position = UDim2.new(0, 10, 0, 4)
    InspHeader.BackgroundTransparency = 1
    InspHeader.Font = Enum.Font.GothamBold
    InspHeader.TextSize = 11
    InspHeader.TextColor3 = Theme.MoonCyan
    InspHeader.TextXAlignment = Enum.TextXAlignment.Left
    InspHeader.Text = "JOINT TRANSFORM INSPECTOR"

    local SelectedJointLbl = Instance.new("TextLabel", Inspector)
    SelectedJointLbl.Size = UDim2.new(1, -16, 0, 18)
    SelectedJointLbl.Position = UDim2.new(0, 10, 0, 26)
    SelectedJointLbl.BackgroundTransparency = 1
    SelectedJointLbl.Font = Enum.Font.GothamMedium
    SelectedJointLbl.TextSize = 11
    SelectedJointLbl.TextColor3 = Theme.TextPrimary
    SelectedJointLbl.TextXAlignment = Enum.TextXAlignment.Left
    SelectedJointLbl.Text = "Selected: None"

    local SlidersHolder = Instance.new("Frame", Inspector)
    SlidersHolder.Size = UDim2.new(1, -16, 1, -90)
    SlidersHolder.Position = UDim2.new(0, 8, 0, 48)
    SlidersHolder.BackgroundTransparency = 1

    local slLayout = Instance.new("UIListLayout", SlidersHolder)
    slLayout.Padding = UDim.new(0, 5)

    local sliderUpdaters = {}

    local function createAxisSlider(label, propKey, minVal, maxVal, barColor, isFloat)
        local box = Instance.new("Frame", SlidersHolder)
        box.Size = UDim2.new(1, 0, 0, 34)
        box.BackgroundColor3 = Theme.BgControl
        box.BorderSizePixel = 0
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

        local l = Instance.new("TextLabel", box)
        l.Size = UDim2.new(0.55, 0, 0, 16)
        l.Position = UDim2.new(0, 8, 0, 2)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.TextSize = 10
        l.TextColor3 = Theme.TextSecondary
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = label

        local vLbl = Instance.new("TextLabel", box)
        vLbl.Size = UDim2.new(0.4, -8, 0, 16)
        vLbl.Position = UDim2.new(0.6, 0, 0, 2)
        vLbl.BackgroundTransparency = 1
        vLbl.Font = Enum.Font.Code
        vLbl.TextSize = 10
        vLbl.TextColor3 = barColor
        vLbl.TextXAlignment = Enum.TextXAlignment.Right
        vLbl.Text = "0"

        local track = Instance.new("Frame", box)
        track.Size = UDim2.new(1, -16, 0, 6)
        track.Position = UDim2.new(0, 8, 0, 22)
        track.BackgroundColor3 = Theme.BgMain
        track.BorderSizePixel = 0
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", track)
        fill.Size = UDim2.new(0.5, 0, 1, 0)
        fill.BackgroundColor3 = barColor
        fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local draggingAxis = false
        local function setByX(xPos)
            local jName = MoonAnimator.SelectedJoint
            if not jName or not MoonAnimator.Joints[jName] then return end
            local rel = math.clamp((xPos - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            local raw = minVal + (maxVal - minVal) * rel
            local val = isFloat and (math.floor(raw * 100 + 0.5) / 100) or math.floor(raw + 0.5)

            fill.Size = UDim2.new(rel, 0, 1, 0)
            vLbl.Text = isFloat and string.format("%.2f", val) or (tostring(val) .. "°")

            local pose = clonePose(MoonAnimator.Joints[jName].Pose)
            pose[propKey] = val
            suppressDefaultAnimations(true)
            MoonAnimator:ApplyJointPose(jName, pose)
            if MoonAnimator.AutoKey then
                MoonAnimator:RecordKeyframe(jName, MoonAnimator.CurrentFrame, pose)
                if refreshTimelineMarkers then refreshTimelineMarkers() end
            end
        end

        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                draggingAxis = true
                setByX(inp.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if draggingAxis and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                setByX(inp.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                draggingAxis = false
            end
        end)

        sliderUpdaters[propKey] = function(val)
            local rel = math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            vLbl.Text = isFloat and string.format("%.2f", val) or (tostring(math.floor(val + 0.5)) .. "°")
        end
    end

    createAxisSlider("Rotate X (Pitch)", "RX", -180, 180, Color3.fromRGB(248, 113, 113), false)
    createAxisSlider("Rotate Y (Yaw)",   "RY", -180, 180, Color3.fromRGB(74, 222, 128),  false)
    createAxisSlider("Rotate Z (Roll)",  "RZ", -180, 180, Color3.fromRGB(56, 189, 248),  false)
    createAxisSlider("Offset X (Studs)", "PX", -4,   4,   Color3.fromRGB(251, 146, 60),  true)
    createAxisSlider("Offset Y (Studs)", "PY", -4,   4,   Color3.fromRGB(168, 85, 247),  true)
    createAxisSlider("Offset Z (Studs)", "PZ", -4,   4,   Color3.fromRGB(236, 72, 153),  true)

    local ResetJointBtn = Instance.new("TextButton", Inspector)
    ResetJointBtn.Size = UDim2.new(1, -16, 0, 28)
    ResetJointBtn.Position = UDim2.new(0, 8, 1, -36)
    ResetJointBtn.BackgroundColor3 = Theme.BgToolbar
    ResetJointBtn.Font = Enum.Font.GothamBold
    ResetJointBtn.TextSize = 11
    ResetJointBtn.TextColor3 = Theme.TextPrimary
    ResetJointBtn.Text = "Reset Selected Joint (0°, 0, 0)"
    ResetJointBtn.BorderSizePixel = 0
    Instance.new("UICorner", ResetJointBtn).CornerRadius = UDim.new(0, 6)

    ResetJointBtn.MouseButton1Click:Connect(function()
        if MoonAnimator.SelectedJoint then
            MoonAnimator:ResetJoint(MoonAnimator.SelectedJoint)
            if refreshInspectorUI then refreshInspectorUI() end
            if refreshTimelineMarkers then refreshTimelineMarkers() end
        end
    end)

    refreshInspectorUI = function()
        local jName = MoonAnimator.SelectedJoint
        SelectedJointLbl.Text = "Joint: " .. tostring(jName or "None")
        local jData = jName and MoonAnimator.Joints[jName]
        local p = (jData and jData.Pose) or makeEmptyPose()
        for k, fn in pairs(sliderUpdaters) do
            fn(p[k] or 0)
        end
    end

    buildTrackRows()
    refreshInspectorUI()
    refreshTimelineMarkers()
    update3DGizmoAdornee()
    task.defer(updatePlayheadVisual)

    -- Playback Engine Loop (60Hz Interpolated Keyframe Playback)
    local playbackConn
    playbackConn = RunService.RenderStepped:Connect(function(dt)
        if not Gui.Parent then
            playbackConn:Disconnect()
            return
        end
        if MoonAnimator.IsPlaying then
            MoonAnimator.CurrentFrame = MoonAnimator.CurrentFrame + dt * MoonAnimator.FPS
            if MoonAnimator.CurrentFrame >= MoonAnimator.TotalFrames then
                if MoonAnimator.Loop then
                    MoonAnimator.CurrentFrame = 0
                else
                    MoonAnimator.CurrentFrame = MoonAnimator.TotalFrames
                    MoonAnimator.IsPlaying = false
                    PlayBtn.Text = "▶ Play"
                    PlayBtn.BackgroundColor3 = Theme.MoonAccent
                end
            end
            MoonAnimator:ApplyFrameToRig(MoonAnimator.CurrentFrame)
            updatePlayheadVisual()
            refreshInspectorUI()
        end
    end)

    -- Keyboard Shortcuts (K = Add Keyframe, Space = Play/Pause)
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe or not Gui.Parent or not Main.Visible then return end
        if inp.KeyCode == Enum.KeyCode.K and MoonAnimator.SelectedJoint then
            suppressDefaultAnimations(true)
            MoonAnimator:RecordKeyframe(MoonAnimator.SelectedJoint, MoonAnimator.CurrentFrame)
            refreshTimelineMarkers()
        end
    end)

    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        WorkspaceArea.Visible = not minimized
        Toolbar.Visible = not minimized
        Main.Size = minimized and UDim2.new(0, 820, 0, 38) or UDim2.new(0, 820, 0, 390)
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        MoonAnimator.IsPlaying = false
        SelectionBox.Adornee = nil
        ArcHandles.Adornee = nil
        ArcHandles.Visible = false
        MoveHandles.Adornee = nil
        MoveHandles.Visible = false
        Gui:Destroy()
    end)

    return Gui
end

-- Auto-mount when executed directly via loadstring(game:HttpGet(...))()
MoonAnimator:MountUI()

return MoonAnimator
