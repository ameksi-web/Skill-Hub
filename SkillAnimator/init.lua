--[[
    Skill Animator — Roblox Studio Plugin (Moon Animator 2 Style)
    File: SkillAnimator/init.lua
    How to install in Roblox Studio:
      1. Save this file as "SkillAnimator.lua" inside your Roblox Studio Plugins folder
         (In Roblox Studio: Plugins Tab -> Plugins Folder -> drop SkillAnimator.lua inside)
         OR right-click in Studio Explorer -> "Save as Local Plugin..."
      2. Click the "Skill Animator" button on the Roblox Studio Plugins Toolbar!
      3. Select any R6 / R15 / Custom Rig in the Explorer or 3D Viewport and click "+ Bind Selected Rig".

    Features (Zero Pre-made Animations — Pure Custom Keyframe Studio):
      • Native Roblox Studio DockWidgetPluginGui (Bottom Timeline Dock like Moon Animator 2)
      • Full Studio Selection Service integration (bind any Dummy/Rig from Explorer/Viewport)
      • Multi-track Motor6D Dope Sheet Timeline with Diamond Keyframes (◆) & Frame Ruler
      • 3D Studio Viewport Gizmos (ArcHandles Rotation Rings & Handles Translation Arrows + SelectionBox)
      • Precision X/Y/Z Rotation (-180°..180°) & Position Offset (-5..5) Inspector
      • Easing Styles & Directions (Linear, Sine, Quad, Cubic, Back, Bounce, Elastic)
      • 1-Click Export to native Roblox `KeyframeSequence` inside `Rig.AnimSaves` (ready to Publish to Roblox!)
      • Full ChangeHistoryService Undo/Redo waypoint support
]]

local Selection            = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RunService           = game:GetService("RunService")
local TweenService         = game:GetService("TweenService")
local UserInputService     = game:GetService("UserInputService")
local CoreGui              = game:GetService("CoreGui")
local Workspace            = game:GetService("Workspace")

-- ═══════════════════════════════════════════════════════════════════════════
--  CUSTOM VECTOR ICONS & MOON ANIMATOR 2 STUDIO THEME
-- ═══════════════════════════════════════════════════════════════════════════

local Icons = {
    Logo       = "rbxassetid://10723354551",
    Play       = "rbxassetid://10734923549",
    Pause      = "rbxassetid://10734919336",
    Stop       = "rbxassetid://10734972627",
    Loop       = "rbxassetid://10734940376",
    AddKey     = "rbxassetid://10734924532",
    Trash      = "rbxassetid://10747362393",
    Bone       = "rbxassetid://10723397898",
    Export     = "rbxassetid://10734950309",
    RadialGlow = "rbxassetid://5028857084",
}

local Theme = {
    BgMain        = Color3.fromRGB(15, 14, 24),
    BgHeader      = Color3.fromRGB(22, 20, 35),
    BgToolbar     = Color3.fromRGB(27, 24, 43),
    BgTrackList   = Color3.fromRGB(19, 17, 30),
    BgRowEven     = Color3.fromRGB(23, 21, 37),
    BgRowOdd      = Color3.fromRGB(19, 17, 31),
    BgInspector   = Color3.fromRGB(20, 18, 32),
    BgControl     = Color3.fromRGB(12, 11, 20),
    MoonAccent    = Color3.fromRGB(168, 85, 247),
    MoonCyan      = Color3.fromRGB(56, 189, 248),
    MoonPink      = Color3.fromRGB(236, 72, 153),
    PlayheadRed   = Color3.fromRGB(244, 63, 94),
    KeyframeGold  = Color3.fromRGB(250, 204, 21),
    SuccessGreen  = Color3.fromRGB(34, 197, 94),
    TextPrimary   = Color3.fromRGB(243, 244, 246),
    TextSecondary = Color3.fromRGB(156, 163, 175),
    TextMuted     = Color3.fromRGB(107, 114, 128),
    Border        = Color3.fromRGB(45, 40, 70),
}

local EASING_STYLES = {
    {Tween = Enum.EasingStyle.Linear,  Pose = Enum.PoseEasingStyle.Linear},
    {Tween = Enum.EasingStyle.Sine,    Pose = Enum.PoseEasingStyle.Sine},
    {Tween = Enum.EasingStyle.Quad,    Pose = Enum.PoseEasingStyle.Quad},
    {Tween = Enum.EasingStyle.Cubic,   Pose = Enum.PoseEasingStyle.Cubic},
    {Tween = Enum.EasingStyle.Back,    Pose = Enum.PoseEasingStyle.Back},
    {Tween = Enum.EasingStyle.Bounce,  Pose = Enum.PoseEasingStyle.Bounce},
    {Tween = Enum.EasingStyle.Elastic, Pose = Enum.PoseEasingStyle.Elastic},
}

local EASING_DIRECTIONS = {
    {Tween = Enum.EasingDirection.Out,   Pose = Enum.PoseEasingDirection.Out},
    {Tween = Enum.EasingDirection.InOut, Pose = Enum.PoseEasingDirection.InOut},
    {Tween = Enum.EasingDirection.In,    Pose = Enum.PoseEasingDirection.In},
}

-- ═══════════════════════════════════════════════════════════════════════════
--  SKILL ANIMATOR STUDIO STATE & RIG ENGINE
-- ═══════════════════════════════════════════════════════════════════════════

local StudioAnimator = {
    ActiveRig        = nil,
    AnimationName    = "SkillAnimation_01",
    FPS              = 30,
    TotalFrames      = 60,
    CurrentFrame     = 0,
    IsPlaying        = false,
    Loop             = true,
    AutoKey          = true,
    GizmoMode        = "Rotate", -- "Rotate" | "Move" | "Off"
    EasingStyleIdx   = 2,        -- Sine
    EasingDirIdx     = 1,        -- Out

    Joints           = {},       -- { [jointKey] = { Motor=m6d, Part0=p0, Part1=p1, BaseC0=cf, BaseTransform=cf, Pose=pose } }
    JointOrder       = {},
    SelectedJoint    = nil,
    TrackKeyframes   = {},       -- { [jointKey] = { [frameInt] = { RX, RY, RZ, PX, PY, PZ, StyleIdx, DirIdx } } }
    CopiedPose       = nil,
}

local function degToRad(d) return math.rad(d or 0) end
local function radToDeg(r) return math.floor(math.deg(r or 0) + 0.5) end

local function makeEmptyPose()
    return {
        RX = 0, RY = 0, RZ = 0,
        PX = 0, PY = 0, PZ = 0,
        StyleIdx = StudioAnimator.EasingStyleIdx,
        DirIdx   = StudioAnimator.EasingDirIdx,
    }
end

local function clonePose(p)
    return {
        RX = p.RX or 0, RY = p.RY or 0, RZ = p.RZ or 0,
        PX = p.PX or 0, PY = p.PY or 0, PZ = p.PZ or 0,
        StyleIdx = p.StyleIdx or StudioAnimator.EasingStyleIdx,
        DirIdx   = p.DirIdx or StudioAnimator.EasingDirIdx,
    }
end

local function setStudioWaypoint(actionName)
    pcall(function()
        ChangeHistoryService:SetWaypoint("SkillAnimator: " .. tostring(actionName))
    end)
end

-- Find a valid Rig model from Roblox Studio Selection or Workspace
function StudioAnimator:FindRigFromSelection()
    local selected = {}
    pcall(function() selected = Selection:Get() end)

    for _, obj in ipairs(selected) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            return obj
        elseif obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") then
            return obj.Parent
        end
    end

    -- Fallback: search Workspace for any Dummy / Rig with Motor6D
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
            return child
        end
    end
    return nil
end

function StudioAnimator:BindRig(rigModel)
    if not rigModel or not rigModel:IsA("Model") then return false end
    self.ActiveRig = rigModel
    self.Joints = {}
    self.JointOrder = {}
    self.TrackKeyframes = {}

    for _, desc in ipairs(rigModel:GetDescendants()) do
        if desc:IsA("Motor6D") and desc.Part0 and desc.Part1 then
            local partName = desc.Part1.Name
            local key = partName
            if self.Joints[key] then
                key = partName .. " (" .. desc.Name .. ")"
            end
            self.Joints[key] = {
                Key    = key,
                PartName = partName,
                Motor  = desc,
                Part0  = desc.Part0,
                Part1  = desc.Part1,
                BaseC0 = desc.C0,
                Pose   = makeEmptyPose(),
            }
            table.insert(self.JointOrder, key)
            self.TrackKeyframes[key] = {}
        end
    end

    table.sort(self.JointOrder)
    self.SelectedJoint = self.JointOrder[1]
    setStudioWaypoint("Bind Rig " .. rigModel.Name)
    return #self.JointOrder > 0
end

function StudioAnimator:EvaluateJointPoseAtFrame(jointKey, frameFloat)
    local track = self.TrackKeyframes[jointKey]
    if not track then return nil end

    local keys = {}
    for f in pairs(track) do table.insert(keys, f) end
    if #keys == 0 then return nil end
    table.sort(keys)

    if frameFloat <= keys[1] then return clonePose(track[keys[1]]) end
    if frameFloat >= keys[#keys] then return clonePose(track[keys[#keys]]) end

    local prevF, nextF = keys[1], keys[#keys]
    for i = 1, #keys - 1 do
        if frameFloat >= keys[i] and frameFloat <= keys[i + 1] then
            prevF = keys[i]
            nextF = keys[i + 1]
            break
        end
    end

    if prevF == nextF then return clonePose(track[prevF]) end

    local p0 = track[prevF]
    local p1 = track[nextF]
    local rawAlpha = (frameFloat - prevF) / (nextF - prevF)
    local styleEntry = EASING_STYLES[p1.StyleIdx or 2] or EASING_STYLES[2]
    local dirEntry   = EASING_DIRECTIONS[p1.DirIdx or 1] or EASING_DIRECTIONS[1]
    local alpha = TweenService:GetValue(rawAlpha, styleEntry.Tween, dirEntry.Tween)

    local function lerp(a, b, t) return a + (b - a) * t end

    return {
        RX = lerp(p0.RX, p1.RX, alpha),
        RY = lerp(p0.RY, p1.RY, alpha),
        RZ = lerp(p0.RZ, p1.RZ, alpha),
        PX = lerp(p0.PX, p1.PX, alpha),
        PY = lerp(p0.PY, p1.PY, alpha),
        PZ = lerp(p0.PZ, p1.PZ, alpha),
        StyleIdx = p1.StyleIdx,
        DirIdx   = p1.DirIdx,
    }
end

function StudioAnimator:ApplyJointPose(jointKey, pose)
    local jData = self.Joints[jointKey]
    if not jData or not jData.Motor or not jData.Motor.Parent then return end
    jData.Pose = clonePose(pose)
    local deltaCF = CFrame.new(pose.PX, pose.PY, pose.PZ)
        * CFrame.Angles(degToRad(pose.RX), degToRad(pose.RY), degToRad(pose.RZ))
    jData.Motor.C0 = jData.BaseC0 * deltaCF
end

function StudioAnimator:ApplyFrameToRig(frameFloat)
    for _, jKey in ipairs(self.JointOrder) do
        local evalPose = self:EvaluateJointPoseAtFrame(jKey, frameFloat)
        if evalPose then
            self:ApplyJointPose(jKey, evalPose)
        end
    end
end

function StudioAnimator:RecordKeyframe(jointKey, frameInt, poseOverride)
    if not jointKey or not self.Joints[jointKey] then return end
    frameInt = math.clamp(math.floor(frameInt + 0.5), 0, self.TotalFrames)
    self.TrackKeyframes[jointKey] = self.TrackKeyframes[jointKey] or {}
    local srcPose = poseOverride or self.Joints[jointKey].Pose or makeEmptyPose()
    srcPose.StyleIdx = self.EasingStyleIdx
    srcPose.DirIdx   = self.EasingDirIdx
    self.TrackKeyframes[jointKey][frameInt] = clonePose(srcPose)
    setStudioWaypoint("Record Keyframe")
end

function StudioAnimator:DeleteKeyframe(jointKey, frameInt)
    if not jointKey or not self.TrackKeyframes[jointKey] then return end
    frameInt = math.clamp(math.floor(frameInt + 0.5), 0, self.TotalFrames)
    self.TrackKeyframes[jointKey][frameInt] = nil
    setStudioWaypoint("Delete Keyframe")
end

function StudioAnimator:ResetJoint(jointKey)
    local jData = self.Joints[jointKey]
    if not jData then return end
    local zero = makeEmptyPose()
    self:ApplyJointPose(jointKey, zero)
    if self.AutoKey then
        self:RecordKeyframe(jointKey, self.CurrentFrame, zero)
    end
end

function StudioAnimator:ResetEntireRig()
    self.IsPlaying = false
    for _, jKey in ipairs(self.JointOrder) do
        local jData = self.Joints[jKey]
        if jData and jData.Motor and jData.Motor.Parent then
            jData.Motor.C0 = jData.BaseC0
            jData.Pose = makeEmptyPose()
        end
    end
    setStudioWaypoint("Reset Rig")
end

-- Export directly to native Roblox Studio `KeyframeSequence` inside `Rig.AnimSaves`!
function StudioAnimator:ExportToKeyframeSequence()
    if not self.ActiveRig then return nil end

    local animSaves = self.ActiveRig:FindFirstChild("AnimSaves")
    if not animSaves then
        animSaves = Instance.new("Model")
        animSaves.Name = "AnimSaves"
        animSaves.Parent = self.ActiveRig
    end

    local existing = animSaves:FindFirstChild(self.AnimationName)
    if existing then existing:Destroy() end

    local kfs = Instance.new("KeyframeSequence")
    kfs.Name = self.AnimationName
    kfs.Loop = self.Loop
    kfs.Priority = Enum.AnimationPriority.Action

    -- Gather all unique frames across all tracks
    local allFramesMap = {[0] = true}
    for _, track in pairs(self.TrackKeyframes) do
        for f in pairs(track) do
            allFramesMap[f] = true
        end
    end

    local sortedFrames = {}
    for f in pairs(allFramesMap) do table.insert(sortedFrames, f) end
    table.sort(sortedFrames)

    for _, frameInt in ipairs(sortedFrames) do
        local kf = Instance.new("Keyframe")
        kf.Name = "Keyframe_" .. tostring(frameInt)
        kf.Time = frameInt / math.max(self.FPS, 1)

        -- Build hierarchical or flat Pose instances for each joint at this frame
        local rootPart = self.ActiveRig.PrimaryPart or self.ActiveRig:FindFirstChild("HumanoidRootPart")
        local rootPose = Instance.new("Pose")
        rootPose.Name = rootPart and rootPart.Name or "HumanoidRootPart"
        rootPose.Weight = 1
        rootPose.Parent = kf

        for _, jKey in ipairs(self.JointOrder) do
            local jData = self.Joints[jKey]
            local evalPose = self:EvaluateJointPoseAtFrame(jKey, frameInt)
            if jData and evalPose then
                local poseInst = Instance.new("Pose")
                poseInst.Name = jData.PartName
                poseInst.Weight = 1
                poseInst.CFrame = CFrame.new(evalPose.PX, evalPose.PY, evalPose.PZ)
                    * CFrame.Angles(degToRad(evalPose.RX), degToRad(evalPose.RY), degToRad(evalPose.RZ))

                local st = EASING_STYLES[evalPose.StyleIdx or 2] or EASING_STYLES[2]
                local dr = EASING_DIRECTIONS[evalPose.DirIdx or 1] or EASING_DIRECTIONS[1]
                poseInst.EasingStyle = st.Pose
                poseInst.EasingDirection = dr.Pose
                poseInst.Parent = rootPose
            end
        end

        kf.Parent = kfs
    end

    kfs.Parent = animSaves
    pcall(function() Selection:Set({kfs}) end)
    setStudioWaypoint("Export KeyframeSequence to AnimSaves")
    return kfs
end

-- ═══════════════════════════════════════════════════════════════════════════
--  3D STUDIO VIEWPORT GIZMOS (SELECTIONBOX + ARCHANDLES + HANDLES)
-- ═══════════════════════════════════════════════════════════════════════════

local GizmoFolder = CoreGui:FindFirstChild("SkillAnimator_StudioGizmos")
if GizmoFolder then GizmoFolder:Destroy() end
GizmoFolder = Instance.new("Folder")
GizmoFolder.Name = "SkillAnimator_StudioGizmos"
GizmoFolder.Parent = CoreGui

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
    local jKey = StudioAnimator.SelectedJoint
    if jKey and StudioAnimator.Joints[jKey] then
        gizmoStartPose = clonePose(StudioAnimator.Joints[jKey].Pose)
    end
end)

ArcHandles.MouseDrag:Connect(function(axis, relativeAngle)
    local jKey = StudioAnimator.SelectedJoint
    if not jKey or not gizmoStartPose then return end
    local degDelta = radToDeg(relativeAngle)
    local newPose = clonePose(gizmoStartPose)

    if axis == Enum.Axis.X then
        newPose.RX = math.clamp(gizmoStartPose.RX + degDelta, -180, 180)
    elseif axis == Enum.Axis.Y then
        newPose.RY = math.clamp(gizmoStartPose.RY + degDelta, -180, 180)
    elseif axis == Enum.Axis.Z then
        newPose.RZ = math.clamp(gizmoStartPose.RZ + degDelta, -180, 180)
    end

    StudioAnimator:ApplyJointPose(jKey, newPose)
    if StudioAnimator.AutoKey then
        StudioAnimator:RecordKeyframe(jKey, StudioAnimator.CurrentFrame, newPose)
        if refreshTimelineMarkers then refreshTimelineMarkers() end
    end
    if refreshInspectorUI then refreshInspectorUI() end
end)

MoveHandles.MouseButton1Down:Connect(function()
    local jKey = StudioAnimator.SelectedJoint
    if jKey and StudioAnimator.Joints[jKey] then
        gizmoStartPose = clonePose(StudioAnimator.Joints[jKey].Pose)
    end
end)

MoveHandles.MouseDrag:Connect(function(face, distance)
    local jKey = StudioAnimator.SelectedJoint
    if not jKey or not gizmoStartPose then return end
    local normal = Vector3.FromNormalId(face) * distance
    local newPose = clonePose(gizmoStartPose)
    newPose.PX = math.clamp(gizmoStartPose.PX + normal.X, -5, 5)
    newPose.PY = math.clamp(gizmoStartPose.PY + normal.Y, -5, 5)
    newPose.PZ = math.clamp(gizmoStartPose.PZ + normal.Z, -5, 5)

    StudioAnimator:ApplyJointPose(jKey, newPose)
    if StudioAnimator.AutoKey then
        StudioAnimator:RecordKeyframe(jKey, StudioAnimator.CurrentFrame, newPose)
        if refreshTimelineMarkers then refreshTimelineMarkers() end
    end
    if refreshInspectorUI then refreshInspectorUI() end
end)

local function update3DGizmoAdornee()
    local jKey = StudioAnimator.SelectedJoint
    local jData = jKey and StudioAnimator.Joints[jKey]
    local part = jData and jData.Part1

    if not part or StudioAnimator.GizmoMode == "Off" then
        SelectionBox.Adornee = nil
        ArcHandles.Adornee = nil
        ArcHandles.Visible = false
        MoveHandles.Adornee = nil
        MoveHandles.Visible = false
        return
    end

    SelectionBox.Adornee = part
    if StudioAnimator.GizmoMode == "Rotate" then
        ArcHandles.Adornee = part
        ArcHandles.Visible = true
        MoveHandles.Adornee = nil
        MoveHandles.Visible = false
    elseif StudioAnimator.GizmoMode == "Move" then
        MoveHandles.Adornee = part
        MoveHandles.Visible = true
        ArcHandles.Adornee = nil
        ArcHandles.Visible = false
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  BUILD STUDIO DOCK WIDGET OR STANDALONE STUDIO GUI
-- ═══════════════════════════════════════════════════════════════════════════

function StudioAnimator:BuildEditorInterface(containerParent)
    local Main = Instance.new("Frame", containerParent)
    Main.Name = "SkillAnimatorRoot"
    Main.Size = UDim2.new(1, 0, 1, 0)
    Main.BackgroundColor3 = Theme.BgMain
    Main.BorderSizePixel = 0

    -- Top Header Bar
    local Header = Instance.new("Frame", Main)
    Header.Size = UDim2.new(1, 0, 0, 34)
    Header.BackgroundColor3 = Theme.BgHeader
    Header.BorderSizePixel = 0

    local TitleLbl = Instance.new("TextLabel", Header)
    TitleLbl.Size = UDim2.new(0, 380, 1, 0)
    TitleLbl.Position = UDim2.new(0, 14, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Font = Enum.Font.GothamBlack
    TitleLbl.TextSize = 13
    TitleLbl.TextColor3 = Theme.TextPrimary
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Text = "🌙 SKILL ANIMATOR STUDIO  •  ROBLOX STUDIO PLUGIN"

    local RigStatusLbl = Instance.new("TextLabel", Header)
    RigStatusLbl.Size = UDim2.new(0, 340, 1, 0)
    RigStatusLbl.Position = UDim2.new(1, -354, 0, 0)
    RigStatusLbl.BackgroundTransparency = 1
    RigStatusLbl.Font = Enum.Font.Code
    RigStatusLbl.TextSize = 11
    RigStatusLbl.TextColor3 = Theme.MoonCyan
    RigStatusLbl.TextXAlignment = Enum.TextXAlignment.Right
    RigStatusLbl.Text = "Rig: None  |  Frame: 0 / 60 (30 FPS)"

    -- Second Row: Moon Animator Transport & Rig Toolbar
    local Toolbar = Instance.new("Frame", Main)
    Toolbar.Size = UDim2.new(1, 0, 0, 36)
    Toolbar.Position = UDim2.new(0, 0, 0, 34)
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

    local buildTrackRows

    makeToolBtn("➕ Bind Selected Rig", 132, Theme.SuccessGreen, function()
        local rig = StudioAnimator:FindRigFromSelection()
        if rig and StudioAnimator:BindRig(rig) then
            RigStatusLbl.Text = string.format("Rig: %s (%d Motor6Ds)  |  Frame: %d / %d", rig.Name, #StudioAnimator.JointOrder, StudioAnimator.CurrentFrame, StudioAnimator.TotalFrames)
            if buildTrackRows then buildTrackRows() end
            if refreshInspectorUI then refreshInspectorUI() end
            if refreshTimelineMarkers then refreshTimelineMarkers() end
            update3DGizmoAdornee()
        else
            RigStatusLbl.Text = "⚠ Select a Rig/Dummy with Motor6D in Studio Explorer!"
        end
    end)

    local PlayBtn = makeToolBtn("▶ Play", 66, Theme.MoonAccent, function(btn)
        StudioAnimator.IsPlaying = not StudioAnimator.IsPlaying
        btn.Text = StudioAnimator.IsPlaying and "⏸ Pause" or "▶ Play"
        btn.BackgroundColor3 = StudioAnimator.IsPlaying and Theme.PlayheadRed or Theme.MoonAccent
    end)

    makeToolBtn("⏮ 0", 42, Theme.BgControl, function()
        StudioAnimator.IsPlaying = false
        PlayBtn.Text = "▶ Play"
        PlayBtn.BackgroundColor3 = Theme.MoonAccent
        StudioAnimator.CurrentFrame = 0
        StudioAnimator:ApplyFrameToRig(0)
        if refreshInspectorUI then refreshInspectorUI() end
    end)

    makeToolBtn("🔁 Loop: ON", 80, Theme.BgControl, function(btn)
        StudioAnimator.Loop = not StudioAnimator.Loop
        btn.Text = StudioAnimator.Loop and "🔁 Loop: ON" or "🔁 Loop: OFF"
    end)

    makeToolBtn("◆ +Key", 66, Color3.fromRGB(202, 138, 4), function()
        if StudioAnimator.SelectedJoint then
            StudioAnimator:RecordKeyframe(StudioAnimator.SelectedJoint, StudioAnimator.CurrentFrame)
            if refreshTimelineMarkers then refreshTimelineMarkers() end
        end
    end)

    makeToolBtn("🗑 Del Key", 72, Theme.BgControl, function()
        if StudioAnimator.SelectedJoint then
            StudioAnimator:DeleteKeyframe(StudioAnimator.SelectedJoint, StudioAnimator.CurrentFrame)
            if refreshTimelineMarkers then refreshTimelineMarkers() end
        end
    end)

    makeToolBtn("📋 Copy", 58, Theme.BgControl, function()
        local j = StudioAnimator.SelectedJoint
        if j and StudioAnimator.Joints[j] then
            StudioAnimator.CopiedPose = clonePose(StudioAnimator.Joints[j].Pose)
        end
    end)

    makeToolBtn("📌 Paste", 60, Theme.BgControl, function()
        local j = StudioAnimator.SelectedJoint
        if j and StudioAnimator.CopiedPose then
            StudioAnimator:ApplyJointPose(j, StudioAnimator.CopiedPose)
            StudioAnimator:RecordKeyframe(j, StudioAnimator.CurrentFrame, StudioAnimator.CopiedPose)
            if refreshInspectorUI then refreshInspectorUI() end
            if refreshTimelineMarkers then refreshTimelineMarkers() end
        end
    end)

    makeToolBtn("🌐 Gizmo: Rotate", 108, Theme.BgControl, function(btn)
        if StudioAnimator.GizmoMode == "Rotate" then
            StudioAnimator.GizmoMode = "Move"
        elseif StudioAnimator.GizmoMode == "Move" then
            StudioAnimator.GizmoMode = "Off"
        else
            StudioAnimator.GizmoMode = "Rotate"
        end
        btn.Text = "🌐 Gizmo: " .. StudioAnimator.GizmoMode
        update3DGizmoAdornee()
    end)

    makeToolBtn("📈 Sine", 72, Theme.BgControl, function(btn)
        StudioAnimator.EasingStyleIdx = (StudioAnimator.EasingStyleIdx % #EASING_STYLES) + 1
        btn.Text = "📈 " .. EASING_STYLES[StudioAnimator.EasingStyleIdx].Tween.Name
    end)

    makeToolBtn("🔄 Reset Rig", 80, Theme.BgControl, function()
        StudioAnimator:ResetEntireRig()
        if refreshInspectorUI then refreshInspectorUI() end
    end)

    makeToolBtn("💾 Save to AnimSaves", 136, Theme.MoonCyan, function(btn)
        local kfs = StudioAnimator:ExportToKeyframeSequence()
        if kfs then
            btn.Text = "✅ Saved in AnimSaves!"
            task.delay(1.8, function()
                if btn and btn.Parent then btn.Text = "💾 Save to AnimSaves" end
            end)
        end
    end)

    -- 3-Column Workspace Area
    local WorkspaceArea = Instance.new("Frame", Main)
    WorkspaceArea.Size = UDim2.new(1, 0, 1, -70)
    WorkspaceArea.Position = UDim2.new(0, 0, 0, 70)
    WorkspaceArea.BackgroundTransparency = 1

    -- Left + Center: Track Hierarchy & Dope Sheet Timeline
    local TimelineContainer = Instance.new("Frame", WorkspaceArea)
    TimelineContainer.Size = UDim2.new(1, -230, 1, 0)
    TimelineContainer.BackgroundColor3 = Theme.BgTrackList
    TimelineContainer.BorderSizePixel = 0

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
    TrackColLabel.Text = "MOTOR6D RIG TRACKS"

    local RulerBar = Instance.new("TextButton", RulerHeader)
    RulerBar.Size = UDim2.new(1, -195, 1, 0)
    RulerBar.Position = UDim2.new(0, 185, 0, 0)
    RulerBar.BackgroundColor3 = Theme.BgControl
    RulerBar.Text = ""
    RulerBar.AutoButtonColor = false
    RulerBar.BorderSizePixel = 0

    for f = 0, StudioAnimator.TotalFrames, 10 do
        local pct = f / StudioAnimator.TotalFrames
        local tickLbl = Instance.new("TextLabel", RulerBar)
        tickLbl.Size = UDim2.new(0, 24, 1, 0)
        tickLbl.Position = UDim2.new(pct, -12, 0, 0)
        tickLbl.BackgroundTransparency = 1
        tickLbl.Font = Enum.Font.Code
        tickLbl.TextSize = 10
        tickLbl.TextColor3 = Theme.TextSecondary
        tickLbl.Text = tostring(f)
    end

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
        local pct = math.clamp(StudioAnimator.CurrentFrame / math.max(StudioAnimator.TotalFrames, 1), 0, 1)
        PlayheadLine.Position = UDim2.new(0, 185 + math.floor(barWidth * pct), 0, 0)
        local rigName = StudioAnimator.ActiveRig and StudioAnimator.ActiveRig.Name or "None"
        RigStatusLbl.Text = string.format(
            "Rig: %s  |  Frame: %d / %d (%d FPS)",
            rigName,
            math.floor(StudioAnimator.CurrentFrame + 0.5),
            StudioAnimator.TotalFrames,
            StudioAnimator.FPS
        )
    end

    local scrubbingTimeline = false
    local function scrubFromMouseX(xPos)
        local rel = math.clamp((xPos - RulerBar.AbsolutePosition.X) / math.max(RulerBar.AbsoluteSize.X, 1), 0, 1)
        StudioAnimator.CurrentFrame = math.floor(rel * StudioAnimator.TotalFrames + 0.5)
        StudioAnimator:ApplyFrameToRig(StudioAnimator.CurrentFrame)
        updatePlayheadVisual()
        if refreshInspectorUI then refreshInspectorUI() end
    end

    RulerBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            scrubbingTimeline = true
            StudioAnimator.IsPlaying = false
            PlayBtn.Text = "▶ Play"
            PlayBtn.BackgroundColor3 = Theme.MoonAccent
            scrubFromMouseX(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if scrubbingTimeline and inp.UserInputType == Enum.UserInputType.MouseMovement then
            scrubFromMouseX(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            scrubbingTimeline = false
        end
    end)

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

    buildTrackRows = function()
        for _, child in ipairs(TracksScroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        trackRowMap = {}

        for idx, jKey in ipairs(StudioAnimator.JointOrder) do
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
            nameBtn.TextColor3 = (StudioAnimator.SelectedJoint == jKey) and Theme.MoonCyan or Theme.TextPrimary
            nameBtn.TextXAlignment = Enum.TextXAlignment.Left
            nameBtn.Text = "  🦴 " .. jKey

            local lane = Instance.new("TextButton", row)
            lane.Size = UDim2.new(1, -190, 1, 0)
            lane.Position = UDim2.new(0, 185, 0, 0)
            lane.BackgroundTransparency = 1
            lane.Text = ""

            nameBtn.MouseButton1Click:Connect(function()
                StudioAnimator.SelectedJoint = jKey
                for kName, rObj in pairs(trackRowMap) do
                    rObj.nameBtn.TextColor3 = (kName == jKey) and Theme.MoonCyan or Theme.TextPrimary
                    rObj.nameBtn.Font = (kName == jKey) and Enum.Font.GothamBold or Enum.Font.GothamMedium
                end
                update3DGizmoAdornee()
                if refreshInspectorUI then refreshInspectorUI() end
            end)

            lane.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    StudioAnimator.SelectedJoint = jKey
                    for kName, rObj in pairs(trackRowMap) do
                        rObj.nameBtn.TextColor3 = (kName == jKey) and Theme.MoonCyan or Theme.TextPrimary
                    end
                    scrubFromMouseX(inp.Position.X)
                    update3DGizmoAdornee()
                    if refreshInspectorUI then refreshInspectorUI() end
                end
            end)

            trackRowMap[jKey] = {row = row, nameBtn = nameBtn, lane = lane}
        end
    end

    refreshTimelineMarkers = function()
        for jKey, rObj in pairs(trackRowMap) do
            for _, ch in ipairs(rObj.lane:GetChildren()) do
                ch:Destroy()
            end
            local track = StudioAnimator.TrackKeyframes[jKey]
            if track then
                for frameInt in pairs(track) do
                    local pct = math.clamp(frameInt / math.max(StudioAnimator.TotalFrames, 1), 0, 1)
                    local diamond = Instance.new("TextButton", rObj.lane)
                    diamond.Size = UDim2.new(0, 9, 0, 9)
                    diamond.Position = UDim2.new(pct, -4, 0.5, -4)
                    diamond.Rotation = 45
                    diamond.BackgroundColor3 = Theme.KeyframeGold
                    diamond.Text = ""
                    diamond.BorderSizePixel = 0
                    diamond.ZIndex = 15

                    diamond.MouseButton1Click:Connect(function()
                        StudioAnimator.SelectedJoint = jKey
                        StudioAnimator.CurrentFrame = frameInt
                        StudioAnimator:ApplyFrameToRig(frameInt)
                        updatePlayheadVisual()
                        update3DGizmoAdornee()
                        if refreshInspectorUI then refreshInspectorUI() end
                    end)
                end
            end
        end
    end

    -- Right Inspector: Rotation X/Y/Z & Position Offset X/Y/Z
    local Inspector = Instance.new("Frame", WorkspaceArea)
    Inspector.Size = UDim2.new(0, 230, 1, 0)
    Inspector.Position = UDim2.new(1, -230, 0, 0)
    Inspector.BackgroundColor3 = Theme.BgInspector
    Inspector.BorderSizePixel = 0

    local InspHeader = Instance.new("TextLabel", Inspector)
    InspHeader.Size = UDim2.new(1, -16, 0, 24)
    InspHeader.Position = UDim2.new(0, 10, 0, 4)
    InspHeader.BackgroundTransparency = 1
    InspHeader.Font = Enum.Font.GothamBold
    InspHeader.TextSize = 11
    InspHeader.TextColor3 = Theme.MoonCyan
    InspHeader.TextXAlignment = Enum.TextXAlignment.Left
    InspHeader.Text = "TRANSFORM INSPECTOR"

    local SelectedJointLbl = Instance.new("TextLabel", Inspector)
    SelectedJointLbl.Size = UDim2.new(1, -16, 0, 18)
    SelectedJointLbl.Position = UDim2.new(0, 10, 0, 24)
    SelectedJointLbl.BackgroundTransparency = 1
    SelectedJointLbl.Font = Enum.Font.GothamMedium
    SelectedJointLbl.TextSize = 11
    SelectedJointLbl.TextColor3 = Theme.TextPrimary
    SelectedJointLbl.TextXAlignment = Enum.TextXAlignment.Left
    SelectedJointLbl.Text = "Joint: None"

    local SlidersHolder = Instance.new("Frame", Inspector)
    SlidersHolder.Size = UDim2.new(1, -16, 1, -86)
    SlidersHolder.Position = UDim2.new(0, 8, 0, 44)
    SlidersHolder.BackgroundTransparency = 1

    local slLayout = Instance.new("UIListLayout", SlidersHolder)
    slLayout.Padding = UDim.new(0, 4)

    local sliderUpdaters = {}

    local function createAxisSlider(label, propKey, minVal, maxVal, barColor, isFloat)
        local box = Instance.new("Frame", SlidersHolder)
        box.Size = UDim2.new(1, 0, 0, 32)
        box.BackgroundColor3 = Theme.BgControl
        box.BorderSizePixel = 0
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

        local l = Instance.new("TextLabel", box)
        l.Size = UDim2.new(0.55, 0, 0, 15)
        l.Position = UDim2.new(0, 8, 0, 2)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.TextSize = 10
        l.TextColor3 = Theme.TextSecondary
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = label

        local vLbl = Instance.new("TextLabel", box)
        vLbl.Size = UDim2.new(0.4, -8, 0, 15)
        vLbl.Position = UDim2.new(0.6, 0, 0, 2)
        vLbl.BackgroundTransparency = 1
        vLbl.Font = Enum.Font.Code
        vLbl.TextSize = 10
        vLbl.TextColor3 = barColor
        vLbl.TextXAlignment = Enum.TextXAlignment.Right
        vLbl.Text = "0"

        local track = Instance.new("Frame", box)
        track.Size = UDim2.new(1, -16, 0, 6)
        track.Position = UDim2.new(0, 8, 0, 20)
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
            local jKey = StudioAnimator.SelectedJoint
            if not jKey or not StudioAnimator.Joints[jKey] then return end
            local rel = math.clamp((xPos - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            local raw = minVal + (maxVal - minVal) * rel
            local val = isFloat and (math.floor(raw * 100 + 0.5) / 100) or math.floor(raw + 0.5)

            fill.Size = UDim2.new(rel, 0, 1, 0)
            vLbl.Text = isFloat and string.format("%.2f", val) or (tostring(val) .. "°")

            local pose = clonePose(StudioAnimator.Joints[jKey].Pose)
            pose[propKey] = val
            StudioAnimator:ApplyJointPose(jKey, pose)
            if StudioAnimator.AutoKey then
                StudioAnimator:RecordKeyframe(jKey, StudioAnimator.CurrentFrame, pose)
                if refreshTimelineMarkers then refreshTimelineMarkers() end
            end
        end

        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingAxis = true
                setByX(inp.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if draggingAxis and inp.UserInputType == Enum.UserInputType.MouseMovement then
                setByX(inp.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
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
    ResetJointBtn.Size = UDim2.new(1, -16, 0, 26)
    ResetJointBtn.Position = UDim2.new(0, 8, 1, -34)
    ResetJointBtn.BackgroundColor3 = Theme.BgToolbar
    ResetJointBtn.Font = Enum.Font.GothamBold
    ResetJointBtn.TextSize = 11
    ResetJointBtn.TextColor3 = Theme.TextPrimary
    ResetJointBtn.Text = "Reset Joint (0°, 0, 0)"
    ResetJointBtn.BorderSizePixel = 0
    Instance.new("UICorner", ResetJointBtn).CornerRadius = UDim.new(0, 6)

    ResetJointBtn.MouseButton1Click:Connect(function()
        if StudioAnimator.SelectedJoint then
            StudioAnimator:ResetJoint(StudioAnimator.SelectedJoint)
            if refreshInspectorUI then refreshInspectorUI() end
            if refreshTimelineMarkers then refreshTimelineMarkers() end
        end
    end)

    refreshInspectorUI = function()
        local jKey = StudioAnimator.SelectedJoint
        SelectedJointLbl.Text = "Joint: " .. tostring(jKey or "None")
        local jData = jKey and StudioAnimator.Joints[jKey]
        local p = (jData and jData.Pose) or makeEmptyPose()
        for k, fn in pairs(sliderUpdaters) do
            fn(p[k] or 0)
        end
    end

    -- Auto-bind initial rig if one is selected in Studio
    local initialRig = self:FindRigFromSelection()
    if initialRig then
        self:BindRig(initialRig)
    end
    buildTrackRows()
    refreshInspectorUI()
    refreshTimelineMarkers()
    update3DGizmoAdornee()
    task.defer(updatePlayheadVisual)

    -- 60Hz Playback Interpolation Loop in Studio
    RunService.RenderStepped:Connect(function(dt)
        if not Main.Parent then return end
        if StudioAnimator.IsPlaying then
            StudioAnimator.CurrentFrame = StudioAnimator.CurrentFrame + dt * StudioAnimator.FPS
            if StudioAnimator.CurrentFrame >= StudioAnimator.TotalFrames then
                if StudioAnimator.Loop then
                    StudioAnimator.CurrentFrame = 0
                else
                    StudioAnimator.CurrentFrame = StudioAnimator.TotalFrames
                    StudioAnimator.IsPlaying = false
                    PlayBtn.Text = "▶ Play"
                    PlayBtn.BackgroundColor3 = Theme.MoonAccent
                end
            end
            StudioAnimator:ApplyFrameToRig(StudioAnimator.CurrentFrame)
            updatePlayheadVisual()
            refreshInspectorUI()
        end
    end)

    return Main
end

-- ═══════════════════════════════════════════════════════════════════════════
--  ROBLOX STUDIO PLUGIN REGISTRATION (plugin:CreateToolbar / DockWidget)
-- ═══════════════════════════════════════════════════════════════════════════

if plugin then
    local toolbar = plugin:CreateToolbar("Skill Animator")
    local toggleButton = toolbar:CreateButton(
        "Skill Animator",
        "Open Skill Animator (Moon Animator Style Keyframe Editor)",
        Icons.Logo
    )
    toggleButton.ClickableWhenViewportHidden = true

    local widgetInfo = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Bottom,
        false, -- InitiallyEnabled
        false, -- OverridePreviousState
        880,   -- DefaultWidth
        360,   -- DefaultHeight
        600,   -- MinWidth
        250    -- MinHeight
    )

    local dockWidget = plugin:CreateDockWidgetPluginGui("SkillAnimatorStudioDock", widgetInfo)
    dockWidget.Title = "Skill Animator Studio (Moon Style)"

    StudioAnimator:BuildEditorInterface(dockWidget)

    toggleButton.Click:Connect(function()
        dockWidget.Enabled = not dockWidget.Enabled
        toggleButton:SetActive(dockWidget.Enabled)
        if not dockWidget.Enabled then
            SelectionBox.Adornee = nil
            ArcHandles.Adornee = nil
            ArcHandles.Visible = false
            MoveHandles.Adornee = nil
            MoveHandles.Visible = false
        else
            update3DGizmoAdornee()
        end
    end)
else
    -- Fallback if tested via Roblox Studio Command Bar
    local existing = CoreGui:FindFirstChild("SkillAnimatorStudioPreview")
    if existing then existing:Destroy() end
    local sg = Instance.new("ScreenGui", CoreGui)
    sg.Name = "SkillAnimatorStudioPreview"
    local holder = Instance.new("Frame", sg)
    holder.Size = UDim2.new(0, 880, 0, 360)
    holder.Position = UDim2.new(0.5, -440, 1, -370)
    holder.BackgroundTransparency = 1
    StudioAnimator:BuildEditorInterface(holder)
end

return StudioAnimator
