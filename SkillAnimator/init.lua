--[[
    Skill Hub — Skill Animator Studio (Standalone & Modular Edition)
    File: SkillAnimator/init.lua
    Description: Complete Blox Fruits Skill Animation Controller, Keyframe
                 Timeline Scrubber, 3D VFX Engine & Z/X/C/V Combo Sequencer
                 with Custom Vector Icons.
]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")

local LocalPlayer       = Players.LocalPlayer

-- Load sibling modules if local filesystem (loadfile) is available, else use embedded modules
local function loadSubModule(path)
    if type(loadfile) == "function" then
        local ok, mod = pcall(function()
            local fn = loadfile(path)
            return fn and fn()
        end)
        if ok and mod then return mod end
    end
    return nil
end

local Presets = loadSubModule("SkillAnimator/AnimationPresets.lua") or {
    Icons = {
        Logo       = "rbxassetid://10734950309",
        Animator   = "rbxassetid://10723354551",
        Play       = "rbxassetid://10734923549",
        Stop       = "rbxassetid://10734972627",
        Loop       = "rbxassetid://10734940376",
        Speed      = "rbxassetid://10747384394",
        VFX        = "rbxassetid://10734982144",
        Combo      = "rbxassetid://10723397898",
        GlowCircle = "rbxassetid://5028857084",
    },
    Animations = {
        {Id = "godhuman_flurry",        Name = "Godhuman — Soaring Beast Flurry",      Category = "Fighting Style", AnimId = "rbxassetid://522635514", Speed = 1.45, Weight = 1.0, Looped = false, VFX = "GoldenShockwave",    Accent = Color3.fromRGB(250, 204, 21)},
        {Id = "sanguine_devour",        Name = "Sanguine Art — Bloodbane Drain",       Category = "Fighting Style", AnimId = "rbxassetid://616163682", Speed = 1.35, Weight = 1.0, Looped = false, VFX = "CrimsonSlash",       Accent = Color3.fromRGB(239, 68, 68)},
        {Id = "dragon_talon_inferno",   Name = "Dragon Talon — Talon Ignition",        Category = "Fighting Style", AnimId = "rbxassetid://616158929", Speed = 1.25, Weight = 1.0, Looped = false, VFX = "DragonEmber",        Accent = Color3.fromRGB(249, 115, 22)},
        {Id = "electric_claw_blitz",    Name = "Electric Claw — Thunderclap Slash",    Category = "Fighting Style", AnimId = "rbxassetid://656117878", Speed = 1.65, Weight = 1.0, Looped = false, VFX = "CyanLightning",      Accent = Color3.fromRGB(56, 189, 248)},
        {Id = "kitsune_tails_barrage",  Name = "Kitsune — Fox Fire Disruption",        Category = "Mythical Fruit", AnimId = "rbxassetid://707853694", Speed = 1.50, Weight = 1.0, Looped = false, VFX = "KitsuneAzureFlame",  Accent = Color3.fromRGB(34, 211, 238)},
        {Id = "dragon_rework_cataclysm",Name = "Dragon (East/West) — Imperial Cataclysm",Category = "Mythical Fruit",AnimId = "rbxassetid://616168032", Speed = 1.15, Weight = 1.0, Looped = false, VFX = "ConquerorHakiBurst", Accent = Color3.fromRGB(220, 38, 38)},
        {Id = "dough_awakened_pierce",  Name = "Awakened Dough — Piercing Clothesline",Category = "Mythical Fruit", AnimId = "rbxassetid://656118852", Speed = 1.40, Weight = 1.0, Looped = false, VFX = "GoldenShockwave",    Accent = Color3.fromRGB(253, 224, 71)},
        {Id = "cdk_dimensional_slash",  Name = "Cursed Dual Katana — Revolving Ravager",Category = "Mythical Sword",AnimId = "rbxassetid://522638767", Speed = 1.55, Weight = 1.0, Looped = false, VFX = "CrimsonSlash",       Accent = Color3.fromRGB(168, 85, 247)},
        {Id = "levitation_aura_idle",   Name = "Awakened Race V4 — Sovereign Float",   Category = "Aura & Pose",    AnimId = "rbxassetid://616006778", Speed = 0.85, Weight = 1.0, Looped = true,  VFX = "ConquerorHakiBurst", Accent = Color3.fromRGB(129, 140, 248)},
    },
    Combos = {
        ["One-Shot Godhuman + Kitsune + CDK"] = {
            {Weapon = "Melee",      Key = "C", Hold = 0.25, Delay = 0.35, VFX = "GoldenShockwave"},
            {Weapon = "Blox Fruit", Key = "C", Hold = 0.10, Delay = 0.40, VFX = "KitsuneAzureFlame"},
            {Weapon = "Blox Fruit", Key = "X", Hold = 0.15, Delay = 0.30, VFX = "KitsuneAzureFlame"},
            {Weapon = "Sword",      Key = "Z", Hold = 0.30, Delay = 0.35, VFX = "CrimsonSlash"},
            {Weapon = "Melee",      Key = "Z", Hold = 0.15, Delay = 0.25, VFX = "GoldenShockwave"},
        },
        ["Sanguine Art + Dragon + Shark Anchor"] = {
            {Weapon = "Melee",      Key = "Z", Hold = 0.20, Delay = 0.35, VFX = "CrimsonSlash"},
            {Weapon = "Sword",      Key = "X", Hold = 0.20, Delay = 0.30, VFX = "CyanLightning"},
            {Weapon = "Blox Fruit", Key = "C", Hold = 0.35, Delay = 0.45, VFX = "ConquerorHakiBurst"},
            {Weapon = "Melee",      Key = "C", Hold = 0.15, Delay = 0.25, VFX = "CrimsonSlash"},
        },
    },
}

local VFXEngine      = loadSubModule("SkillAnimator/VFXEngine.lua")
local ComboSequencer = loadSubModule("SkillAnimator/ComboSequencer.lua")

-- Fallback inline VFX if loaded without filesystem
if not VFXEngine then
    local Debris = game:GetService("Debris")
    VFXEngine = {PersistentAuraEnabled = false, CurrentAuraColor = Color3.fromRGB(56, 189, 248)}
    function VFXEngine.PlayPreset(presetName)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local colorMap = {
            ConquerorHakiBurst = Color3.fromRGB(220, 38, 38),
            KitsuneAzureFlame  = Color3.fromRGB(34, 211, 238),
            CrimsonSlash       = Color3.fromRGB(239, 68, 68),
            GoldenShockwave    = Color3.fromRGB(250, 204, 21),
            CyanLightning      = Color3.fromRGB(56, 189, 248),
            DragonEmber        = Color3.fromRGB(249, 115, 22),
        }
        local col = colorMap[presetName] or Color3.fromRGB(56, 189, 248)
        local sphere = Instance.new("Part")
        sphere.Anchored = true
        sphere.CanCollide = false
        sphere.Shape = Enum.PartType.Ball
        sphere.Material = Enum.Material.Neon
        sphere.Color = col
        sphere.Size = Vector3.new(2, 2, 2)
        sphere.CFrame = root.CFrame
        sphere.Transparency = 0.15
        sphere.Parent = Workspace
        TweenService:Create(sphere, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = Vector3.new(34, 34, 34),
            Transparency = 1,
        }):Play()
        Debris:AddItem(sphere, 0.6)
    end
end

if not ComboSequencer then
    local VirtualInputManager = game:GetService("VirtualInputManager")
    ComboSequencer = {IsRunning = false, LoopCombo = false}
    function ComboSequencer.ExecuteChain(steps, vfx, onStep)
        if ComboSequencer.IsRunning then return end
        ComboSequencer.IsRunning = true
        task.spawn(function()
            for i, s in ipairs(steps) do
                if not ComboSequencer.IsRunning then break end
                if onStep then pcall(onStep, i, s) end
                if vfx and s.VFX then pcall(function() vfx.PlayPreset(s.VFX) end) end
                pcall(function()
                    local kc = Enum.KeyCode[s.Key or "Z"]
                    VirtualInputManager:SendKeyEvent(true, kc, false, game)
                    task.wait(s.Hold or 0.15)
                    VirtualInputManager:SendKeyEvent(false, kc, false, game)
                end)
                task.wait(s.Delay or 0.3)
            end
            ComboSequencer.IsRunning = false
            if onStep then pcall(onStep, 0, nil) end
        end)
    end
    function ComboSequencer.Stop()
        ComboSequencer.IsRunning = false
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  ANIMATION TRACK CONTROLLER
-- ═══════════════════════════════════════════════════════════════════════════

local SkillAnimator = {
    CurrentTrack  = nil,
    ActivePreset  = Presets.Animations[1],
    Speed         = 1.25,
    Weight        = 1.0,
    Looped        = false,
    Frozen        = false,
    AutoVFXOnPlay = true,
}

local function getAnimator()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator", hum)
    end
    return animator
end

function SkillAnimator:StopCurrent()
    if self.CurrentTrack then
        pcall(function()
            self.CurrentTrack:Stop(0.15)
            self.CurrentTrack:Destroy()
        end)
        self.CurrentTrack = nil
    end
end

function SkillAnimator:PlayAnimation(animId, speed, weight, looped, vfxName)
    self:StopCurrent()
    local animator = getAnimator()
    if not animator then return nil end

    local cleanId = tostring(animId)
    if not cleanId:find("rbxassetid://") then
        cleanId = "rbxassetid://" .. cleanId:gsub("%D", "")
    end

    local animObj = Instance.new("Animation")
    animObj.AnimationId = cleanId

    local ok, track = pcall(function()
        return animator:LoadAnimation(animObj)
    end)

    if ok and track then
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = (looped ~= nil) and looped or self.Looped
        track:Play(0.12, weight or self.Weight, speed or self.Speed)
        self.CurrentTrack = track

        if self.AutoVFXOnPlay and vfxName then
            VFXEngine.PlayPreset(vfxName)
        end
        return track
    end
    return nil
end

function SkillAnimator:SetSpeed(newSpeed)
    self.Speed = newSpeed
    if self.CurrentTrack and not self.Frozen then
        pcall(function() self.CurrentTrack:AdjustSpeed(newSpeed) end)
    end
end

function SkillAnimator:SetFrozen(freeze)
    self.Frozen = freeze
    if self.CurrentTrack then
        pcall(function()
            self.CurrentTrack:AdjustSpeed(freeze and 0 or self.Speed)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  SKILL ANIMATOR STUDIO — CUSTOM VECTOR ICON & GLASS SCREENGUI
-- ═══════════════════════════════════════════════════════════════════════════

function SkillAnimator:MountUI()
    local pGui = LocalPlayer:WaitForChild("PlayerGui")
    if pGui:FindFirstChild("SkillAnimatorStudio") then
        pGui.SkillAnimatorStudio:Destroy()
    end

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "SkillAnimatorStudio"
    Gui.ResetOnSpawn = false
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Gui.DisplayOrder = 1005
    Gui.Parent = pGui

    -- Custom Vector Icon Helper (ImageLabel + Procedural Accent Badge)
    local function createCustomIcon(parent, iconAsset, accentColor, sizePx, posUDim)
        local badge = Instance.new("Frame", parent)
        badge.Size = UDim2.new(0, sizePx, 0, sizePx)
        badge.Position = posUDim
        badge.BackgroundColor3 = accentColor
        badge.BackgroundTransparency = 0.84
        badge.BorderSizePixel = 0
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 8)

        local bStroke = Instance.new("UIStroke", badge)
        bStroke.Color = accentColor
        bStroke.Thickness = 1
        bStroke.Transparency = 0.45

        local img = Instance.new("ImageLabel", badge)
        img.Size = UDim2.new(0, sizePx - 10, 0, sizePx - 10)
        img.Position = UDim2.new(0.5, -(sizePx - 10) / 2, 0.5, -(sizePx - 10) / 2)
        img.BackgroundTransparency = 1
        img.Image = iconAsset or Presets.Icons.Animator
        img.ImageColor3 = accentColor
        img.ScaleType = Enum.ScaleType.Fit

        -- Subtle center geometric dot so even if asset CDN lags, icon looks crisp
        local coreDot = Instance.new("Frame", badge)
        coreDot.Size = UDim2.new(0, 4, 0, 4)
        coreDot.Position = UDim2.new(0.5, -2, 0.5, -2)
        coreDot.BackgroundColor3 = accentColor
        coreDot.BackgroundTransparency = 0.35
        coreDot.BorderSizePixel = 0
        Instance.new("UICorner", coreDot).CornerRadius = UDim.new(1, 0)

        return badge, img
    end

    -- Studio Window
    local Win = Instance.new("Frame", Gui)
    Win.Name = "StudioWindow"
    Win.Size = UDim2.new(0, 620, 0, 430)
    Win.Position = UDim2.new(0.5, -310, 0.5, -215)
    Win.BackgroundColor3 = Color3.fromRGB(10, 12, 22)
    Win.BorderSizePixel = 0
    Win.ClipsDescendants = true
    Instance.new("UICorner", Win).CornerRadius = UDim.new(0, 14)

    local winStroke = Instance.new("UIStroke", Win)
    winStroke.Color = Color3.fromRGB(139, 92, 246)
    winStroke.Thickness = 1.6

    -- Top Gradient Ribbon
    local TopRibbon = Instance.new("Frame", Win)
    TopRibbon.Size = UDim2.new(1, 0, 0, 3)
    TopRibbon.BorderSizePixel = 0
    local ribGrad = Instance.new("UIGradient", TopRibbon)
    ribGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(56, 189, 248)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168, 85, 247)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(236, 72, 153)),
    })

    -- Header Bar
    local Header = Instance.new("Frame", Win)
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = Color3.fromRGB(15, 18, 32)
    Header.BorderSizePixel = 0

    createCustomIcon(Header, Presets.Icons.Animator, Color3.fromRGB(168, 85, 247), 32, UDim2.new(0, 14, 0.5, -16))

    local Title = Instance.new("TextLabel", Header)
    Title.Size = UDim2.new(0, 320, 0, 22)
    Title.Position = UDim2.new(0, 56, 0, 7)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 15
    Title.TextColor3 = Color3.fromRGB(248, 250, 252)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Text = "SKILL ANIMATOR STUDIO"

    local SubTitle = Instance.new("TextLabel", Header)
    SubTitle.Size = UDim2.new(0, 340, 0, 16)
    SubTitle.Position = UDim2.new(0, 56, 0, 27)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Font = Enum.Font.GothamMedium
    SubTitle.TextSize = 11
    SubTitle.TextColor3 = Color3.fromRGB(168, 85, 247)
    SubTitle.TextXAlignment = Enum.TextXAlignment.Left
    SubTitle.Text = "Keyframe Scrubber • 3D Skill VFX • Z/X/C/V Sequencer"

    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -42, 0.5, -15)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 13
    CloseBtn.TextColor3 = Color3.new(1, 1, 1)
    CloseBtn.Text = "✕"
    CloseBtn.BorderSizePixel = 0
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
    CloseBtn.MouseButton1Click:Connect(function()
        Win.Visible = not Win.Visible
    end)

    -- Dragging
    do
        local dragging, dragInput, dragStart, startPos
        Header.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = inp.Position
                startPos = Win.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        Header.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                dragInput = inp
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if inp == dragInput and dragging then
                local d = inp.Position - dragStart
                Win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end

    -- Timeline / Keyframe Scrubber Bar (Bottom Dock)
    local TimelineDock = Instance.new("Frame", Win)
    TimelineDock.Size = UDim2.new(1, -24, 0, 74)
    TimelineDock.Position = UDim2.new(0, 12, 1, -84)
    TimelineDock.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
    TimelineDock.BorderSizePixel = 0
    Instance.new("UICorner", TimelineDock).CornerRadius = UDim.new(0, 10)
    local tdStroke = Instance.new("UIStroke", TimelineDock)
    tdStroke.Color = Color3.fromRGB(30, 41, 59)
    tdStroke.Thickness = 1

    local TrackStatusLbl = Instance.new("TextLabel", TimelineDock)
    TrackStatusLbl.Size = UDim2.new(0.6, 0, 0, 20)
    TrackStatusLbl.Position = UDim2.new(0, 14, 0, 8)
    TrackStatusLbl.BackgroundTransparency = 1
    TrackStatusLbl.Font = Enum.Font.GothamBold
    TrackStatusLbl.TextSize = 12
    TrackStatusLbl.TextColor3 = Color3.fromRGB(241, 245, 249)
    TrackStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    TrackStatusLbl.Text = "Ready • Select a Skill Animation Preset"

    local TimecodeLbl = Instance.new("TextLabel", TimelineDock)
    TimecodeLbl.Size = UDim2.new(0.35, -14, 0, 20)
    TimecodeLbl.Position = UDim2.new(0.65, 0, 0, 8)
    TimecodeLbl.BackgroundTransparency = 1
    TimecodeLbl.Font = Enum.Font.Code
    TimecodeLbl.TextSize = 12
    TimecodeLbl.TextColor3 = Color3.fromRGB(56, 189, 248)
    TimecodeLbl.TextXAlignment = Enum.TextXAlignment.Right
    TimecodeLbl.Text = "0.00s / 0.00s (1.25x)"

    local ScrubberBg = Instance.new("Frame", TimelineDock)
    ScrubberBg.Size = UDim2.new(1, -210, 0, 8)
    ScrubberBg.Position = UDim2.new(0, 14, 0, 42)
    ScrubberBg.BackgroundColor3 = Color3.fromRGB(10, 13, 24)
    ScrubberBg.BorderSizePixel = 0
    Instance.new("UICorner", ScrubberBg).CornerRadius = UDim.new(1, 0)

    local ScrubberFill = Instance.new("Frame", ScrubberBg)
    ScrubberFill.Size = UDim2.new(0, 0, 1, 0)
    ScrubberFill.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    ScrubberFill.BorderSizePixel = 0
    Instance.new("UICorner", ScrubberFill).CornerRadius = UDim.new(1, 0)

    local FreezeBtn = Instance.new("TextButton", TimelineDock)
    FreezeBtn.Size = UDim2.new(0, 82, 0, 28)
    FreezeBtn.Position = UDim2.new(1, -182, 0, 32)
    FreezeBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    FreezeBtn.Font = Enum.Font.GothamBold
    FreezeBtn.TextSize = 11
    FreezeBtn.TextColor3 = Color3.fromRGB(241, 245, 249)
    FreezeBtn.Text = "❄ Freeze"
    FreezeBtn.BorderSizePixel = 0
    Instance.new("UICorner", FreezeBtn).CornerRadius = UDim.new(0, 7)

    FreezeBtn.MouseButton1Click:Connect(function()
        SkillAnimator:SetFrozen(not SkillAnimator.Frozen)
        FreezeBtn.BackgroundColor3 = SkillAnimator.Frozen and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(30, 41, 59)
        FreezeBtn.Text = SkillAnimator.Frozen and "▶ Resume" or "❄ Freeze"
    end)

    local StopTrackBtn = Instance.new("TextButton", TimelineDock)
    StopTrackBtn.Size = UDim2.new(0, 82, 0, 28)
    StopTrackBtn.Position = UDim2.new(1, -92, 0, 32)
    StopTrackBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
    StopTrackBtn.Font = Enum.Font.GothamBold
    StopTrackBtn.TextSize = 11
    StopTrackBtn.TextColor3 = Color3.new(1, 1, 1)
    StopTrackBtn.Text = "■ Stop"
    StopTrackBtn.BorderSizePixel = 0
    Instance.new("UICorner", StopTrackBtn).CornerRadius = UDim.new(0, 7)

    StopTrackBtn.MouseButton1Click:Connect(function()
        SkillAnimator:StopCurrent()
        ComboSequencer.Stop()
        TrackStatusLbl.Text = "Stopped all active tracks & combos"
    end)

    -- Live Playhead Updater
    RunService.RenderStepped:Connect(function()
        if not Gui.Parent then return end
        local tr = SkillAnimator.CurrentTrack
        if tr and tr.IsPlaying then
            local len = math.max(tr.Length, 0.01)
            local pos = math.clamp(tr.TimePosition, 0, len)
            ScrubberFill.Size = UDim2.new(pos / len, 0, 1, 0)
            TimecodeLbl.Text = string.format("%.2fs / %.2fs (%.2fx)", pos, len, SkillAnimator.Speed)
        end
    end)

    -- Left Column: Preset Animations & Custom ID Player
    local LeftScroll = Instance.new("ScrollingFrame", Win)
    LeftScroll.Size = UDim2.new(0.54, -18, 1, -150)
    LeftScroll.Position = UDim2.new(0, 12, 0, 58)
    LeftScroll.BackgroundTransparency = 1
    LeftScroll.BorderSizePixel = 0
    LeftScroll.ScrollBarThickness = 3
    LeftScroll.ScrollBarImageColor3 = Color3.fromRGB(168, 85, 247)
    LeftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local leftLayout = Instance.new("UIListLayout", LeftScroll)
    leftLayout.Padding = UDim.new(0, 6)

    -- Custom Animation ID Input Card
    local CustomCard = Instance.new("Frame", LeftScroll)
    CustomCard.Size = UDim2.new(1, -6, 0, 44)
    CustomCard.BackgroundColor3 = Color3.fromRGB(18, 24, 40)
    CustomCard.BorderSizePixel = 0
    Instance.new("UICorner", CustomCard).CornerRadius = UDim.new(0, 8)

    local AnimIdBox = Instance.new("TextBox", CustomCard)
    AnimIdBox.Size = UDim2.new(1, -92, 0, 28)
    AnimIdBox.Position = UDim2.new(0, 8, 0.5, -14)
    AnimIdBox.BackgroundColor3 = Color3.fromRGB(11, 15, 26)
    AnimIdBox.PlaceholderText = "Custom rbxassetid:// Animation ID..."
    AnimIdBox.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
    AnimIdBox.Text = ""
    AnimIdBox.Font = Enum.Font.Gotham
    AnimIdBox.TextSize = 11
    AnimIdBox.TextColor3 = Color3.fromRGB(241, 245, 249)
    AnimIdBox.BorderSizePixel = 0
    Instance.new("UICorner", AnimIdBox).CornerRadius = UDim.new(0, 6)

    local PlayCustomBtn = Instance.new("TextButton", CustomCard)
    PlayCustomBtn.Size = UDim2.new(0, 72, 0, 28)
    PlayCustomBtn.Position = UDim2.new(1, -78, 0.5, -14)
    PlayCustomBtn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    PlayCustomBtn.Font = Enum.Font.GothamBold
    PlayCustomBtn.TextSize = 11
    PlayCustomBtn.TextColor3 = Color3.new(1, 1, 1)
    PlayCustomBtn.Text = "▶ Play ID"
    PlayCustomBtn.BorderSizePixel = 0
    Instance.new("UICorner", PlayCustomBtn).CornerRadius = UDim.new(0, 6)

    PlayCustomBtn.MouseButton1Click:Connect(function()
        if AnimIdBox.Text ~= "" then
            SkillAnimator:PlayAnimation(AnimIdBox.Text, SkillAnimator.Speed, 1.0, SkillAnimator.Looped, "CyanLightning")
            TrackStatusLbl.Text = "Playing Custom ID: " .. AnimIdBox.Text
        end
    end)

    -- Populate Skill Animation Presets
    for _, preset in ipairs(Presets.Animations) do
        local item = Instance.new("Frame", LeftScroll)
        item.Size = UDim2.new(1, -6, 0, 50)
        item.BackgroundColor3 = Color3.fromRGB(18, 24, 40)
        item.BorderSizePixel = 0
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 8)

        createCustomIcon(item, Presets.Icons.Play, preset.Accent, 30, UDim2.new(0, 10, 0.5, -15))

        local nLbl = Instance.new("TextLabel", item)
        nLbl.Size = UDim2.new(1, -110, 0, 18)
        nLbl.Position = UDim2.new(0, 48, 0, 7)
        nLbl.BackgroundTransparency = 1
        nLbl.Font = Enum.Font.GothamBold
        nLbl.TextSize = 12
        nLbl.TextColor3 = Color3.fromRGB(241, 245, 249)
        nLbl.TextXAlignment = Enum.TextXAlignment.Left
        nLbl.Text = preset.Name

        local cLbl = Instance.new("TextLabel", item)
        cLbl.Size = UDim2.new(1, -110, 0, 14)
        cLbl.Position = UDim2.new(0, 48, 0, 26)
        cLbl.BackgroundTransparency = 1
        cLbl.Font = Enum.Font.Gotham
        cLbl.TextSize = 10
        cLbl.TextColor3 = preset.Accent
        cLbl.TextXAlignment = Enum.TextXAlignment.Left
        cLbl.Text = string.format("%s • %.2fx • VFX: %s", preset.Category, preset.Speed, preset.VFX)

        local runBtn = Instance.new("TextButton", item)
        runBtn.Size = UDim2.new(0, 54, 0, 26)
        runBtn.Position = UDim2.new(1, -62, 0.5, -13)
        runBtn.BackgroundColor3 = preset.Accent
        runBtn.Font = Enum.Font.GothamBold
        runBtn.TextSize = 11
        runBtn.TextColor3 = Color3.fromRGB(10, 12, 22)
        runBtn.Text = "CAST"
        runBtn.BorderSizePixel = 0
        Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 6)

        runBtn.MouseButton1Click:Connect(function()
            SkillAnimator.Speed = preset.Speed
            SkillAnimator:PlayAnimation(preset.AnimId, preset.Speed, preset.Weight, preset.Looped, preset.VFX)
            TrackStatusLbl.Text = "Casting: " .. preset.Name
        end)
    end

    -- Right Column: 3D VFX Triggers, Sovereign Aura & Z/X/C/V Combo Sequencer
    local RightScroll = Instance.new("ScrollingFrame", Win)
    RightScroll.Size = UDim2.new(0.46, -12, 1, -150)
    RightScroll.Position = UDim2.new(0.54, 0, 0, 58)
    RightScroll.BackgroundTransparency = 1
    RightScroll.BorderSizePixel = 0
    RightScroll.ScrollBarThickness = 3
    RightScroll.ScrollBarImageColor3 = Color3.fromRGB(56, 189, 248)
    RightScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local rightLayout = Instance.new("UIListLayout", RightScroll)
    rightLayout.Padding = UDim.new(0, 6)

    local function addRightButton(label, sub, color, iconId, cb)
        local card = Instance.new("TextButton", RightScroll)
        card.Size = UDim2.new(1, -6, 0, 46)
        card.BackgroundColor3 = Color3.fromRGB(18, 24, 40)
        card.Text = ""
        card.BorderSizePixel = 0
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

        createCustomIcon(card, iconId, color, 28, UDim2.new(0, 10, 0.5, -14))

        local l1 = Instance.new("TextLabel", card)
        l1.Size = UDim2.new(1, -50, 0, 18)
        l1.Position = UDim2.new(0, 46, 0, 6)
        l1.BackgroundTransparency = 1
        l1.Font = Enum.Font.GothamBold
        l1.TextSize = 12
        l1.TextColor3 = Color3.fromRGB(241, 245, 249)
        l1.TextXAlignment = Enum.TextXAlignment.Left
        l1.Text = label

        local l2 = Instance.new("TextLabel", card)
        l2.Size = UDim2.new(1, -50, 0, 14)
        l2.Position = UDim2.new(0, 46, 0, 24)
        l2.BackgroundTransparency = 1
        l2.Font = Enum.Font.Gotham
        l2.TextSize = 10
        l2.TextColor3 = Color3.fromRGB(148, 163, 184)
        l2.TextXAlignment = Enum.TextXAlignment.Left
        l2.Text = sub

        card.MouseButton1Click:Connect(cb)
    end

    addRightButton(
        "Toggle Sovereign Haki Aura",
        "Persistent 3D rising neon particles around character",
        Color3.fromRGB(56, 189, 248),
        Presets.Icons.VFX,
        function()
            VFXEngine.PersistentAuraEnabled = not VFXEngine.PersistentAuraEnabled
            TrackStatusLbl.Text = VFXEngine.PersistentAuraEnabled and "Sovereign Aura: ON" or "Sovereign Aura: OFF"
        end
    )

    addRightButton(
        "Burst: Conqueror's Haki Dome",
        "Crimson & dark lightning expansion shockwave",
        Color3.fromRGB(239, 68, 68),
        Presets.Icons.VFX,
        function()
            VFXEngine.PlayPreset("ConquerorHakiBurst")
            TrackStatusLbl.Text = "Triggered Conqueror's Haki Burst"
        end
    )

    addRightButton(
        "Burst: Kitsune Azure Flame",
        "Cyan fox-fire vortex & radial slash arcs",
        Color3.fromRGB(34, 211, 238),
        Presets.Icons.VFX,
        function()
            VFXEngine.PlayPreset("KitsuneAzureFlame")
            TrackStatusLbl.Text = "Triggered Kitsune Azure Flame"
        end
    )

    for comboName, steps in pairs(Presets.Combos) do
        addRightButton(
            "Combo: " .. comboName,
            "Auto weapon switch + Z/X/C/V sequence + 3D VFX",
            Color3.fromRGB(168, 85, 247),
            Presets.Icons.Combo,
            function()
                ComboSequencer.ExecuteChain(steps, VFXEngine, function(idx, step)
                    if step then
                        TrackStatusLbl.Text = string.format("Combo Step %d: [%s] Key %s", idx, step.Weapon, step.Key)
                    else
                        TrackStatusLbl.Text = "Combo Sequence Completed!"
                    end
                end)
            end
        )
    end

    return Gui
end

return SkillAnimator
