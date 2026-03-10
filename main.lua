--[[
    Skill Hub - Murder Mystery 2
    By: ameksi-web
    GitHub: https://github.com/ameksi-web/Skill-Hub
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Player            = Players.LocalPlayer

-- ═══════════════════════════════════════
--  СОСТОЯНИЯ
-- ═══════════════════════════════════════
local STATE = {
    ESPEnabled       = false,
    MurderESP        = false,
    GunBot           = false,
    KnifeAura        = false,
    GodMode          = false,
    InfiniteCoins    = false,
    AutoFarm         = false,
    SpeedHack        = false,
    NoClip           = false,
    AntiBan          = true,
    FakeLag          = false,
}

local SETTINGS = {
    WalkSpeed        = 50,
    JumpPower        = 100,
    KnifeAuraRadius  = 10,
}

-- ═══════════════════════════════════════
--  УДАЛИТЬ СТАРЫЙ GUI
-- ═══════════════════════════════════════
if Player.PlayerGui:FindFirstChild("SkillHub") then
    Player.PlayerGui:FindFirstChild("SkillHub"):Destroy()
end

-- ═══════════════════════════════════════
--  ЦВЕТА (Rinns Hub Blue Lock стиль)
-- ═══════════════════════════════════════
local C = {
    BG          = Color3.fromRGB(8,   10,  20),
    BG2         = Color3.fromRGB(12,  15,  30),
    BG3         = Color3.fromRGB(18,  22,  45),
    Accent      = Color3.fromRGB(0,   140, 255),
    AccentDark  = Color3.fromRGB(0,   90,  200),
    Cyan        = Color3.fromRGB(0,   220, 255),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecond  = Color3.fromRGB(160, 175, 210),
    TextDim     = Color3.fromRGB(90,  105, 150),
    Green       = Color3.fromRGB(50,  255, 130),
    Red         = Color3.fromRGB(255, 70,  70),
    Yellow      = Color3.fromRGB(255, 210, 50),
    Purple      = Color3.fromRGB(150, 80,  255),
    Divider     = Color3.fromRGB(25,  35,  70),
    BtnOn       = Color3.fromRGB(0,   50,  140),
    BtnOff      = Color3.fromRGB(20,  25,  55),
}

-- ═══════════════════════════════════════
--  GUI
-- ═══════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SkillHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = Player.PlayerGui

-- Главное окно
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 560, 0, 440)
Main.Position = UDim2.new(0.5, -280, 0.5, -220)
Main.BackgroundColor3 = C.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)

-- Обводка
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = C.Accent
mainStroke.Thickness = 1.5

-- Линия сверху
local topLine = Instance.new("Frame", Main)
topLine.Size = UDim2.new(1, 0, 0, 2)
topLine.BackgroundColor3 = C.Accent
topLine.BorderSizePixel = 0
topLine.ZIndex = 10

local lineGrad = Instance.new("UIGradient", topLine)
lineGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   C.BG),
    ColorSequenceKeypoint.new(0.3, C.Accent),
    ColorSequenceKeypoint.new(0.7, C.Cyan),
    ColorSequenceKeypoint.new(1,   C.BG),
})

-- ═══════════════════════════════════════
--  DRAG
-- ═══════════════════════════════════════
local dragging, dragInput, dragStart, startPos

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

-- ═══════════════════════════════════════
--  ЛЕВЫЙ САЙДБАР
-- ═══════════════════════════════════════
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 155, 1, 0)
Sidebar.BackgroundColor3 = C.BG2
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 16)

-- Фикс правых углов сайдбара
local sF = Instance.new("Frame", Sidebar)
sF.Size = UDim2.new(0, 16, 1, 0)
sF.Position = UDim2.new(1, -16, 0, 0)
sF.BackgroundColor3 = C.BG2
sF.BorderSizePixel = 0

-- Лого блок
local logoBlock = Instance.new("Frame", Sidebar)
logoBlock.Size = UDim2.new(1, 0, 0, 105)
logoBlock.BackgroundTransparency = 1
logoBlock.ZIndex = 3

-- Иконка (вместо png — текстовая)
local logoIcon = Instance.new("TextLabel", logoBlock)
logoIcon.Size = UDim2.new(0, 55, 0, 55)
logoIcon.Position = UDim2.new(0.5, -27, 0, 10)
logoIcon.BackgroundColor3 = C.BtnOn
logoIcon.Text = "💀"
logoIcon.TextSize = 28
logoIcon.BorderSizePixel = 0
logoIcon.ZIndex = 4
Instance.new("UICorner", logoIcon).CornerRadius = UDim.new(0, 12)

-- Свечение иконки
local iconGlow = Instance.new("ImageLabel", logoBlock)
iconGlow.Size = UDim2.new(0, 75, 0, 75)
iconGlow.Position = UDim2.new(0.5, -37, 0, 0)
iconGlow.BackgroundTransparency = 1
iconGlow.Image = "rbxassetid://5028857084"
iconGlow.ImageColor3 = C.Accent
iconGlow.ImageTransparency = 0.6
iconGlow.ZIndex = 3

local hubTitle = Instance.new("TextLabel", logoBlock)
hubTitle.Size = UDim2.new(1, 0, 0, 20)
hubTitle.Position = UDim2.new(0, 0, 0, 70)
hubTitle.BackgroundTransparency = 1
hubTitle.Text = "Skill Hub"
hubTitle.TextColor3 = C.TextPrimary
hubTitle.TextSize = 16
hubTitle.Font = Enum.Font.GothamBold
hubTitle.ZIndex = 4

local hubSub = Instance.new("TextLabel", logoBlock)
hubSub.Size = UDim2.new(1, 0, 0, 15)
hubSub.Position = UDim2.new(0, 0, 0, 89)
hubSub.BackgroundTransparency = 1
hubSub.Text = "Murder Mystery 2"
hubSub.TextColor3 = C.Accent
hubSub.TextSize = 11
hubSub.Font = Enum.Font.Gotham
hubSub.ZIndex = 4

-- Разделитель
local logoDivider = Instance.new("Frame", Sidebar)
logoDivider.Size = UDim2.new(1, -20, 0, 1)
logoDivider.Position = UDim2.new(0, 10, 0, 108)
logoDivider.BackgroundColor3 = C.Divider
logoDivider.BorderSizePixel = 0
logoDivider.ZIndex = 3

-- Навигация
local NavFrame = Instance.new("Frame", Sidebar)
NavFrame.Size = UDim2.new(1, 0, 1, -115)
NavFrame.Position = UDim2.new(0, 0, 0, 112)
NavFrame.BackgroundTransparency = 1
NavFrame.ZIndex = 3

local navLayout = Instance.new("UIListLayout", NavFrame)
navLayout.Padding = UDim.new(0, 3)

local navPad = Instance.new("UIPadding", NavFrame)
navPad.PaddingLeft  = UDim.new(0, 7)
navPad.PaddingRight = UDim.new(0, 7)

-- Версия
local verLbl = Instance.new("TextLabel", Sidebar)
verLbl.Size = UDim2.new(1, 0, 0, 18)
verLbl.Position = UDim2.new(0, 0, 1, -20)
verLbl.BackgroundTransparency = 1
verLbl.Text = "v1.0 | MM2"
verLbl.TextColor3 = C.TextDim
verLbl.TextSize = 11
verLbl.Font = Enum.Font.Gotham
verLbl.ZIndex = 4

-- ═══════════════════════════════════════
--  ПРАВАЯ ПАНЕЛЬ
-- ═══════════════════════════════════════
local RightPanel = Instance.new("Frame", Main)
RightPanel.Size = UDim2.new(1, -155, 1, 0)
RightPanel.Position = UDim2.new(0, 155, 0, 0)
RightPanel.BackgroundColor3 = C.BG
RightPanel.BorderSizePixel = 0
RightPanel.ZIndex = 2

-- Хедер
local Header = Instance.new("Frame", RightPanel)
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = C.BG2
Header.BorderSizePixel = 0
Header.ZIndex = 3

local hFix = Instance.new("Frame", Header)
hFix.Size = UDim2.new(1, 0, 0, 16)
hFix.Position = UDim2.new(0, 0, 1, -16)
hFix.BackgroundColor3 = C.BG2
hFix.BorderSizePixel = 0

local PageTitle = Instance.new("TextLabel", Header)
PageTitle.Size = UDim2.new(1, -110, 1, 0)
PageTitle.Position = UDim2.new(0, 15, 0, 0)
PageTitle.BackgroundTransparency = 1
PageTitle.Text = "ESP / Visuals"
PageTitle.TextColor3 = C.TextPrimary
PageTitle.TextSize = 17
PageTitle.Font = Enum.Font.GothamBold
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.ZIndex = 5

-- Кнопки окна
local function makeWinBtn(txt, col, xOff)
    local b = Instance.new("TextButton", Header)
    b.Size = UDim2.new(0, 28, 0, 28)
    b.Position = UDim2.new(1, xOff, 0.5, -14)
    b.BackgroundColor3 = col
    b.Text = txt
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 14
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.ZIndex = 6
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end

local MinBtn   = makeWinBtn("—", Color3.fromRGB(255, 165, 0), -65)
local CloseBtn = makeWinBtn("✕", Color3.fromRGB(220, 40, 40),  -33)

local hDiv = Instance.new("Frame", Header)
hDiv.Size = UDim2.new(1, 0, 0, 1)
hDiv.Position = UDim2.new(0, 0, 1, -1)
hDiv.BackgroundColor3 = C.Divider
hDiv.BorderSizePixel = 0
hDiv.ZIndex = 4

-- Скролл
local Scroll = Instance.new("ScrollingFrame", RightPanel)
Scroll.Size = UDim2.new(1, -10, 1, -58)
Scroll.Position = UDim2.new(0, 5, 0, 54)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = C.Accent
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.ZIndex = 3

local scrollLayout = Instance.new("UIListLayout", Scroll)
scrollLayout.Padding = UDim.new(0, 5)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

local scrollPad = Instance.new("UIPadding", Scroll)
scrollPad.PaddingTop    = UDim.new(0, 5)
scrollPad.PaddingBottom = UDim.new(0, 5)

-- ═══════════════════════════════════════
--  НАВИГАЦИЯ
-- ═══════════════════════════════════════
local navEntries   = {}
local activePage   = nil

local function makeNav(emoji, text, tag)
    local btn = Instance.new("TextButton", NavFrame)
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.ZIndex = 5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0, 3, 0, 20)
    indicator.Position = UDim2.new(0, 0, 0.5, -10)
    indicator.BackgroundColor3 = C.Accent
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    local eLbl = Instance.new("TextLabel", btn)
    eLbl.Size = UDim2.new(0, 24, 1, 0)
    eLbl.Position = UDim2.new(0, 7, 0, 0)
    eLbl.BackgroundTransparency = 1
    eLbl.Text = emoji
    eLbl.TextSize = 15
    eLbl.ZIndex = 6

    local tLbl = Instance.new("TextLabel", btn)
    tLbl.Size = UDim2.new(1, -35, 1, 0)
    tLbl.Position = UDim2.new(0, 33, 0, 0)
    tLbl.BackgroundTransparency = 1
    tLbl.Text = text
    tLbl.TextColor3 = C.TextSecond
    tLbl.TextSize = 12
    tLbl.Font = Enum.Font.Gotham
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.ZIndex = 6

    local function activate()
        for _, e in ipairs(navEntries) do
            TweenService:Create(e.btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            TweenService:Create(e.ind, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            TweenService:Create(e.lbl, TweenInfo.new(0.2), {TextColor3 = C.TextSecond}):Play()
            e.lbl.Font = Enum.Font.Gotham
        end

        btn.BackgroundColor3 = C.BtnOn
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        TweenService:Create(indicator, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        TweenService:Create(tLbl, TweenInfo.new(0.2), {TextColor3 = C.TextPrimary}):Play()
        tLbl.Font = Enum.Font.GothamBold
        activePage = tag
        PageTitle.Text = text

        for _, child in ipairs(Scroll:GetChildren()) do
            if child:IsA("Frame") then
                child.Visible = child.Name:sub(1, #tag) == tag
            end
        end
    end

    btn.MouseButton1Click:Connect(activate)

    btn.MouseEnter:Connect(function()
        if activePage ~= tag then
            btn.BackgroundColor3 = C.BtnOn
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.7}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if activePage ~= tag then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
        end
    end)

    table.insert(navEntries, {btn = btn, ind = indicator, lbl = tLbl, tag = tag, activate = activate})
    return activate
end

local activateESP    = makeNav("👁️", "ESP / Visuals", "esp")
local activateCombat = makeNav("⚔️", "Combat",        "combat")
local activateFarm   = makeNav("💰", "Farm / Coins",  "farm")
local activateMove   = makeNav("🏃", "Movement",      "move")
local activateAnti   = makeNav("🛡️", "Anti-Ban",      "anti")
local activateMisc   = makeNav("🔧", "Misc",          "misc")

-- ═══════════════════════════════════════
--  СТРОИТЕЛИ ЭЛЕМЕНТОВ
-- ═══════════════════════════════════════
local itemIdx = 0

local function makeSection(tag, text)
    itemIdx += 1
    local f = Instance.new("Frame", Scroll)
    f.Name = tag .. "_sec_" .. itemIdx
    f.Size = UDim2.new(1, 0, 0, 26)
    f.BackgroundTransparency = 1
    f.LayoutOrder = itemIdx
    f.ZIndex = 3

    local line = Instance.new("Frame", f)
    line.Size = UDim2.new(1, -10, 0, 1)
    line.Position = UDim2.new(0, 5, 0.5, 0)
    line.BackgroundColor3 = C.Divider
    line.BorderSizePixel = 0

    local g = Instance.new("UIGradient", line)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.Accent),
        ColorSequenceKeypoint.new(1, C.BG),
    })

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0, 0, 1, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundColor3 = C.BG
    lbl.BorderSizePixel = 0
    lbl.Text = "  " .. text .. "  "
    lbl.TextColor3 = C.Accent
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.ZIndex = 4
end

-- Toggle
local function makeToggle(tag, name, desc, stateKey, cb)
    itemIdx += 1
    local item = Instance.new("Frame", Scroll)
    item.Name = tag .. "_item_" .. itemIdx
    item.Size = UDim2.new(1, 0, 0, 56)
    item.BackgroundColor3 = C.BG3
    item.BorderSizePixel = 0
    item.LayoutOrder = itemIdx
    item.ZIndex = 3
    Instance.new("UICorner", item).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", item)
    stroke.Color = C.Divider
    stroke.Thickness = 1

    local bar = Instance.new("Frame", item)
    bar.Size = UDim2.new(0, 3, 0, 36)
    bar.Position = UDim2.new(0, 0, 0.5, -18)
    bar.BackgroundColor3 = C.Accent
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

    local nLbl = Instance.new("TextLabel", item)
    nLbl.Size = UDim2.new(1, -95, 0, 20)
    nLbl.Position = UDim2.new(0, 14, 0, 7)
    nLbl.BackgroundTransparency = 1
    nLbl.Text = name
    nLbl.TextColor3 = C.TextPrimary
    nLbl.TextSize = 13
    nLbl.Font = Enum.Font.GothamBold
    nLbl.TextXAlignment = Enum.TextXAlignment.Left
    nLbl.ZIndex = 4

    local dLbl = Instance.new("TextLabel", item)
    dLbl.Size = UDim2.new(1, -95, 0, 15)
    dLbl.Position = UDim2.new(0, 14, 0, 30)
    dLbl.BackgroundTransparency = 1
    dLbl.Text = desc
    dLbl.TextColor3 = C.TextDim
    dLbl.TextSize = 10
    dLbl.Font = Enum.Font.Gotham
    dLbl.TextXAlignment = Enum.TextXAlignment.Left
    dLbl.ZIndex = 4

    -- Switch
    local swBG = Instance.new("Frame", item)
    swBG.Size = UDim2.new(0, 44, 0, 24)
    swBG.Position = UDim2.new(1, -54, 0.5, -12)
    swBG.BackgroundColor3 = C.BtnOff
    swBG.BorderSizePixel = 0
    swBG.ZIndex = 5
    Instance.new("UICorner", swBG).CornerRadius = UDim.new(1, 0)

    local swCircle = Instance.new("Frame", swBG)
    swCircle.Size = UDim2.new(0, 18, 0, 18)
    swCircle.Position = UDim2.new(0, 3, 0.5, -9)
    swCircle.BackgroundColor3 = C.TextDim
    swCircle.BorderSizePixel = 0
    swCircle.ZIndex = 6
    Instance.new("UICorner", swCircle).CornerRadius = UDim.new(1, 0)

    local swBtn = Instance.new("TextButton", swBG)
    swBtn.Size = UDim2.new(1, 0, 1, 0)
    swBtn.BackgroundTransparency = 1
    swBtn.Text = ""
    swBtn.ZIndex = 7

    local cardBtn = Instance.new("TextButton", item)
    cardBtn.Size = UDim2.new(1, -65, 1, 0)
    cardBtn.BackgroundTransparency = 1
    cardBtn.Text = ""
    cardBtn.ZIndex = 4

    local function upd()
        local on = STATE[stateKey]
        TweenService:Create(swBG, TweenInfo.new(0.2), {
            BackgroundColor3 = on and C.Accent or C.BtnOff
        }):Play()
        TweenService:Create(swCircle, TweenInfo.new(0.2), {
            Position = on and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
            BackgroundColor3 = on and C.TextPrimary or C.TextDim,
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {
            Color = on and C.AccentDark or C.Divider
        }):Play()
        TweenService:Create(bar, TweenInfo.new(0.2), {
            BackgroundColor3 = on and C.Cyan or C.Accent
        }):Play()
    end

    local function toggle()
        STATE[stateKey] = not STATE[stateKey]
        upd(); cb(STATE[stateKey])
    end

    swBtn.MouseButton1Click:Connect(toggle)
    cardBtn.MouseButton1Click:Connect(toggle)
    upd()
end

-- Button
local function makeButton(tag, name, desc, cb)
    itemIdx += 1
    local item = Instance.new("Frame", Scroll)
    item.Name = tag .. "_item_" .. itemIdx
    item.Size = UDim2.new(1, 0, 0, 56)
    item.BackgroundColor3 = C.BG3
    item.BorderSizePixel = 0
    item.LayoutOrder = itemIdx
    item.ZIndex = 3
    Instance.new("UICorner", item).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", item)
    stroke.Color = C.Divider; stroke.Thickness = 1

    local bar = Instance.new("Frame", item)
    bar.Size = UDim2.new(0, 3, 0, 36)
    bar.Position = UDim2.new(0, 0, 0.5, -18)
    bar.BackgroundColor3 = C.Purple
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

    local nLbl = Instance.new("TextLabel", item)
    nLbl.Size = UDim2.new(1, -95, 0, 20)
    nLbl.Position = UDim2.new(0, 14, 0, 7)
    nLbl.BackgroundTransparency = 1
    nLbl.Text = name
    nLbl.TextColor3 = C.TextPrimary
    nLbl.TextSize = 13
    nLbl.Font = Enum.Font.GothamBold
    nLbl.TextXAlignment = Enum.TextXAlignment.Left
    nLbl.ZIndex = 4

    local dLbl = Instance.new("TextLabel", item)
    dLbl.Size = UDim2.new(1, -95, 0, 15)
    dLbl.Position = UDim2.new(0, 14, 0, 30)
    dLbl.BackgroundTransparency = 1
    dLbl.Text = desc
    dLbl.TextColor3 = C.TextDim
    dLbl.TextSize = 10
    dLbl.Font = Enum.Font.Gotham
    dLbl.TextXAlignment = Enum.TextXAlignment.Left
    dLbl.ZIndex = 4

    local runBtn = Instance.new("TextButton", item)
    runBtn.Size = UDim2.new(0, 58, 0, 26)
    runBtn.Position = UDim2.new(1, -67, 0.5, -13)
    runBtn.BackgroundColor3 = C.AccentDark
    runBtn.Text = "RUN"
    runBtn.TextColor3 = C.TextPrimary
    runBtn.TextSize = 12
    runBtn.Font = Enum.Font.GothamBold
    runBtn.BorderSizePixel = 0
    runBtn.ZIndex = 5
    Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 7)

    runBtn.MouseButton1Click:Connect(function()
        TweenService:Create(runBtn, TweenInfo.new(0.1), {BackgroundColor3 = C.Cyan}):Play()
        task.spawn(cb)
        task.delay(0.5, function()
            TweenService:Create(runBtn, TweenInfo.new(0.2), {BackgroundColor3 = C.AccentDark}):Play()
        end)
    end)
    runBtn.MouseEnter:Connect(function()
        TweenService:Create(runBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.Accent}):Play()
    end)
    runBtn.MouseLeave:Connect(function()
        TweenService:Create(runBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.AccentDark}):Play()
    end)
end

-- Slider
local function makeSlider(tag, name, desc, min, max, default, settingKey, cb)
    itemIdx += 1
    local item = Instance.new("Frame", Scroll)
    item.Name = tag .. "_item_" .. itemIdx
    item.Size = UDim2.new(1, 0, 0, 70)
    item.BackgroundColor3 = C.BG3
    item.BorderSizePixel = 0
    item.LayoutOrder = itemIdx
    item.ZIndex = 3
    Instance.new("UICorner", item).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", item)
    stroke.Color = C.Divider; stroke.Thickness = 1

    local bar = Instance.new("Frame", item)
    bar.Size = UDim2.new(0, 3, 0, 50)
    bar.Position = UDim2.new(0, 0, 0.5, -25)
    bar.BackgroundColor3 = C.Yellow
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

    local nLbl = Instance.new("TextLabel", item)
    nLbl.Size = UDim2.new(0.6, 0, 0, 20)
    nLbl.Position = UDim2.new(0, 14, 0, 5)
    nLbl.BackgroundTransparency = 1
    nLbl.Text = name
    nLbl.TextColor3 = C.TextPrimary
    nLbl.TextSize = 13
    nLbl.Font = Enum.Font.GothamBold
    nLbl.TextXAlignment = Enum.TextXAlignment.Left
    nLbl.ZIndex = 4

    local vLbl = Instance.new("TextLabel", item)
    vLbl.Size = UDim2.new(0.4, -14, 0, 20)
    vLbl.Position = UDim2.new(0.6, 0, 0, 5)
    vLbl.BackgroundTransparency = 1
    vLbl.Text = tostring(default)
    vLbl.TextColor3 = C.Cyan
    vLbl.TextSize = 13
    vLbl.Font = Enum.Font.GothamBold
    vLbl.TextXAlignment = Enum.TextXAlignment.Right
    vLbl.ZIndex = 4

    local dLbl = Instance.new("TextLabel", item)
    dLbl.Size = UDim2.new(1, -20, 0, 14)
    dLbl.Position = UDim2.new(0, 14, 0, 25)
    dLbl.BackgroundTransparency = 1
    dLbl.Text = desc
    dLbl.TextColor3 = C.TextDim
    dLbl.TextSize = 10
    dLbl.Font = Enum.Font.Gotham
    dLbl.TextXAlignment = Enum.TextXAlignment.Left
    dLbl.ZIndex = 4

    local track = Instance.new("Frame", item)
    track.Size = UDim2.new(1, -28, 0, 5)
    track.Position = UDim2.new(0, 14, 0, 48)
    track.BackgroundColor3 = C.BtnOff
    track.BorderSizePixel = 0
    track.ZIndex = 4
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local pct0 = (default - min) / (max - min)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(pct0, 0, 1, 0)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local fg = Instance.new("UIGradient", fill)
    fg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.AccentDark),
        ColorSequenceKeypoint.new(1, C.Cyan),
    })

    local thumb = Instance.new("Frame", track)
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = UDim2.new(pct0, -7, 0.5, -7)
    thumb.BackgroundColor3 = C.TextPrimary
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 6
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local sliding = false
    local curVal  = default

    local function updSlider(x)
        local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        curVal = math.floor(min + (max - min) * p)
        fill.Size = UDim2.new(p, 0, 1, 0)
        thumb.Position = UDim2.new(p, -7, 0.5, -7)
        vLbl.Text = tostring(curVal)
        if settingKey then SETTINGS[settingKey] = curVal end
        if cb then cb(curVal) end
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true; updSlider(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            updSlider(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)
end

-- ═══════════════════════════════════════
--  MM2 ЛОГИКА
-- ═══════════════════════════════════════

-- Найти все RemoteEvent / RemoteFunction
local function getRemotes(pattern)
    local list = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            if not pattern or obj.Name:lower():find(pattern:lower()) then
                table.insert(list, obj)
            end
        end
    end
    return list
end

-- ─── ESP ───
local espBBs = {}

local function clearESP()
    for _, bb in ipairs(espBBs) do
        pcall(function() bb:Destroy() end)
    end
    espBBs = {}
end

local function addESP(plr, color)
    if plr == Player then return end
    task.spawn(function()
        local char = plr.Character or plr.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart", 5)
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not root then return end

        local bb = Instance.new("BillboardGui")
        bb.Name = "SH_ESP"
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 130, 0, 50)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.Adornee = root
        bb.Parent = Workspace

        local nL = Instance.new("TextLabel", bb)
        nL.Size = UDim2.new(1, 0, 0.55, 0)
        nL.BackgroundTransparency = 1
        nL.Text = plr.Name
        nL.TextColor3 = color
        nL.TextSize = 14
        nL.Font = Enum.Font.GothamBold
        nL.TextStrokeTransparency = 0.5

        local hL = Instance.new("TextLabel", bb)
        hL.Size = UDim2.new(1, 0, 0.45, 0)
        hL.Position = UDim2.new(0, 0, 0.55, 0)
        hL.BackgroundTransparency = 1
        hL.Text = "HP: ?"
        hL.TextColor3 = C.Green
        hL.TextSize = 11
        hL.Font = Enum.Font.Gotham
        hL.TextStrokeTransparency = 0.5

        -- Определяем роль по оружию
        local function getColor()
            if plr.Character then
                for _, tool in ipairs(plr.Character:GetChildren()) do
                    if tool:IsA("Tool") then
                        local n = tool.Name:lower()
                        if n:find("knife") or n:find("murder") then
                            return C.Red   -- Убийца
                        elseif n:find("gun") or n:find("sheriff") then
                            return C.Yellow -- Шериф
                        end
                    end
                end
            end
            return color
        end

        local conn = RunService.Heartbeat:Connect(function()
            if not STATE.ESPEnabled and not STATE.MurderESP then
                bb:Destroy(); conn:Disconnect(); return
            end
            if hum then
                hL.Text = "HP: " .. math.floor(hum.Health)
                hL.TextColor3 = hum.Health > 50 and C.Green or C.Red
            end
            nL.TextColor3 = getColor()
        end)

        table.insert(espBBs, bb)
        plr.CharacterRemoving:Connect(function()
            bb:Destroy()
            conn:Disconnect()
        end)
    end)
end

local function refreshESP()
    clearESP()
    if not STATE.ESPEnabled and not STATE.MurderESP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        addESP(p, C.TextPrimary)
    end
    Players.PlayerAdded:Connect(function(p)
        if STATE.ESPEnabled or STATE.MurderESP then
            addESP(p, C.TextPrimary)
        end
    end)
end

-- ─── АВТО-СБОР МОНЕТ ───
-- Монеты: Workspace → Coins → [CoinObject] → MainCoin (BasePart)
local function collectCoins()
    local char = Player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Папка Coins в Workspace
    local coinsFolder = Workspace:FindFirstChild("Coins")
    if coinsFolder then
        for _, coinObj in ipairs(coinsFolder:GetChildren()) do
            if not STATE.AutoFarm then break end

            -- Ищем MainCoin внутри
            local mainCoin = coinObj:FindFirstChild("MainCoin")
                or coinObj:FindFirstChildWhichIsA("BasePart")
                or (coinObj:IsA("BasePart") and coinObj)

            if mainCoin then
                local saved = root.CFrame
                -- Телепорт к монете
                root.CFrame = CFrame.new(mainCoin.Position) * CFrame.new(0, 2, 0)
                task.wait(0.08)

                -- Touch (самый надёжный способ)
                pcall(function()
                    if firetouchinterest then
                        firetouchinterest(root, mainCoin, 0)
                        task.wait(0.05)
                        firetouchinterest(root, mainCoin, 1)
                    end
                end)

                -- ProximityPrompt
                for _, pp in ipairs(coinObj:GetDescendants()) do
                    if pp:IsA("ProximityPrompt") then
                        pcall(function() fireproximityprompt(pp) end)
                    end
                end

                -- ClickDetector
                for _, cd in ipairs(coinObj:GetDescendants()) do
                    if cd:IsA("ClickDetector") then
                        pcall(function() fireclickdetector(cd) end)
                    end
                end

                task.wait(0.05)
            end
        end
    end

    -- Также ищем монеты везде в Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not STATE.AutoFarm then break end
        local n = obj.Name:lower()
        if (n == "coin" or n == "coinobject" or n == "maincoin")
           and (obj:IsA("BasePart") or obj:IsA("MeshPart")) then
            local d = (obj.Position - root.Position).Magnitude
            if d < 500 then
                root.CFrame = CFrame.new(obj.Position) * CFrame.new(0, 2, 0)
                task.wait(0.08)
                pcall(function()
                    if firetouchinterest then
                        firetouchinterest(root, obj, 0)
                        task.wait(0.05)
                        firetouchinterest(root, obj, 1)
                    end
                end)
            end
        end
    end

    -- Remote'ы монет
    for _, r in ipairs(getRemotes("coin")) do
        pcall(function()
            if r:IsA("RemoteEvent") then
                r:FireServer("Collect")
                r:FireServer("Add", 999999)
                r:FireServer(999999)
            end
        end)
    end
end

-- ─── AUTO FARM LOOP ───
local farmThread = nil
local function startFarm()
    if farmThread then task.cancel(farmThread) end
    farmThread = task.spawn(function()
        while STATE.AutoFarm and task.wait(0.15) do
            pcall(collectCoins)
        end
    end)
end

-- ─── INFINITE COINS ───
local coinThread = nil
local function startInfiniteCoins()
    if coinThread then task.cancel(coinThread) end
    coinThread = task.spawn(function()
        while STATE.InfiniteCoins and task.wait(1) do
            pcall(function()
                -- leaderstats
                local ls = Player:FindFirstChild("leaderstats")
                if ls then
                    for _, v in ipairs(ls:GetChildren()) do
                        if v:IsA("IntValue") or v:IsA("NumberValue") then
                            local n = v.Name:lower()
                            if n:find("coin") or n:find("gold")
                               or n:find("cash") or n:find("money") then
                                v.Value = 999999999
                            end
                        end
                    end
                end

                -- Все Values у игрока
                for _, v in ipairs(Player:GetDescendants()) do
                    if v:IsA("IntValue") or v:IsA("NumberValue") then
                        local n = v.Name:lower()
                        if n:find("coin") or n:find("gold")
                           or n:find("cash") or n:find("money") then
                            v.Value = 999999999
                        end
                    end
                end

                -- Remote'ы
                for _, r in ipairs(getRemotes("coin")) do
                    pcall(function()
                        if r:IsA("RemoteEvent") then
                            r:FireServer("Add", 999999999)
                            r:FireServer(999999999)
                            r:FireServer("Collect")
                        end
                    end)
                end
            end)
        end
    end)
end

-- ─── GOD MODE ───
local godThread = nil
local function startGodMode()
    if godThread then task.cancel(godThread) end
    godThread = task.spawn(function()
        while STATE.GodMode and task.wait(0.1) do
            pcall(function()
                local char = Player.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.Health = hum.MaxHealth
                end
            end)
        end
    end)
end

-- ─── SPEED HACK ───
local function applySpeed()
    pcall(function()
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = STATE.SpeedHack and SETTINGS.WalkSpeed or 16
            hum.JumpPower = STATE.SpeedHack and SETTINGS.JumpPower or 50
        end
    end)
end

Player.CharacterAdded:Connect(function()
    task.wait(1)
    if STATE.SpeedHack then applySpeed() end
    if STATE.GodMode then startGodMode() end
end)

-- ─── NOCLIP ───
local noclipConn = nil
local function startNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if STATE.NoClip then
        noclipConn = RunService.Stepped:Connect(function()
            pcall(function()
                local char = Player.Character
                if not char then return end
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end)
        end)
    end
end

-- ─── KNIFE AURA ───
local auraThread = nil
local function startKnifeAura()
    if auraThread then task.cancel(auraThread) end
    auraThread = task.spawn(function()
        while STATE.KnifeAura and task.wait(0.1) do
            pcall(function()
                local char = Player.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= Player and p.Character then
                        local pr = p.Character:FindFirstChild("HumanoidRootPart")
                        local ph = p.Character:FindFirstChildOfClass("Humanoid")
                        if pr and ph and ph.Health > 0 then
                            local d = (pr.Position - root.Position).Magnitude
                            if d <= SETTINGS.KnifeAuraRadius then
                                root.CFrame = pr.CFrame * CFrame.new(0, 0, -2)
                                for _, r in ipairs(getRemotes()) do
                                    pcall(function()
                                        if r:IsA("RemoteEvent") then
                                            local n = r.Name:lower()
                                            if n:find("knife") or n:find("kill")
                                               or n:find("stab") or n:find("murder")
                                               or n:find("hit") or n:find("damage") then
                                                r:FireServer(p.Character, pr.Position)
                                                r:FireServer(pr.Position)
                                            end
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- ─── GUN BOT ───
local gunThread = nil
local function startGunBot()
    if gunThread then task.cancel(gunThread) end
    gunThread = task.spawn(function()
        while STATE.GunBot and task.wait(0.2) do
            pcall(function()
                local char = Player.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= Player and p.Character then
                        local pr = p.Character:FindFirstChild("HumanoidRootPart")
                        local ph = p.Character:FindFirstChildOfClass("Humanoid")
                        -- Ищем убийцу (с ножом)
                        local hasKnife = false
                        for _, tool in ipairs(p.Character:GetChildren()) do
                            if tool:IsA("Tool") and tool.Name:lower():find("knife") then
                                hasKnife = true; break
                            end
                        end
                        if pr and ph and ph.Health > 0 and hasKnife then
                            for _, r in ipairs(getRemotes()) do
                                pcall(function()
                                    if r:IsA("RemoteEvent") then
                                        local n = r.Name:lower()
                                        if n:find("shoot") or n:find("fire")
                                           or n:find("gun") or n:find("bullet")
                                           or n:find("hit") then
                                            r:FireServer(pr.Position, pr)
                                            r:FireServer(p.Character)
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- ─── SHOW ROLES ───
local function showRoles()
    local killer  = "Unknown"
    local sheriff = "Unknown"
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            for _, tool in ipairs(p.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    local n = tool.Name:lower()
                    if n:find("knife") or n:find("murder") then
                        killer = p.Name
                    elseif n:find("gun") or n:find("sheriff") then
                        sheriff = p.Name
                    end
                end
            end
        end
    end
    pcall(function()
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "[SkillHub] 🔪 Killer: "..killer.." | 🔫 Sheriff: "..sheriff,
            Color = C.Red,
            Font = Enum.Font.GothamBold,
            FontSize = Enum.FontSize.Size18,
        })
    end)
    print("[SkillHub] Killer: "..killer.." | Sheriff: "..sheriff)
end

-- ─── ANTI-BAN ───
local function initAntiBan()
    -- Блок кика
    pcall(function()
        Player.Kick = function()
            warn("[SkillHub] Kick заблокирован!")
        end
    end)

    if hookmetamethod then
        pcall(function()
            local old
            old = hookmetamethod(game, "__namecall", function(self, ...)
                local m = getnamecallmethod()
                if m == "Kick" then
                    warn("[SkillHub] :Kick() заблокирован!")
                    return nil
                end
                if STATE.AntiBan and (m == "FireServer" or m == "InvokeServer") then
                    local ok, name = pcall(function() return self.Name:lower() end)
                    if ok and (name:find("kick") or name:find("ban")
                       or name:find("punish") or name:find("report")) then
                        warn("[SkillHub] Remote ban заблокирован: " .. self.Name)
                        return nil
                    end
                end
                return old(self, ...)
            end)
        end)
    end

    -- Анти-войд
    RunService.Heartbeat:Connect(function()
        if not STATE.AntiBan then return end
        pcall(function()
            local char = Player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and root.Position.Y < -200 then
                root.CFrame = CFrame.new(0, 50, 0)
            end
        end)
    end)

    print("[SkillHub] 🛡️ Anti-Ban активен!")
end

-- ═══════════════════════════════════════
--  НАПОЛНЕНИЕ ВКЛАДОК
-- ═══════════════════════════════════════

-- ── ESP ──
makeSection("esp", "Визуалы")
makeToggle("esp", "Player ESP",
    "Имена и HP всех игроков над головой",
    "ESPEnabled", function(on)
        refreshESP()
    end)
makeToggle("esp", "Murder ESP",
    "Цвет по роли: 🔴 Убийца 🟡 Шериф",
    "MurderESP", function(on)
        refreshESP()
    end)
makeButton("esp", "Show Roles",
    "Вывести убийцу и шерифа в чат",
    showRoles)
makeButton("esp", "Refresh ESP",
    "Перезапустить ESP",
    refreshESP)

-- ── COMBAT ──
makeSection("combat", "Бой")
makeToggle("combat", "Gun Bot",
    "Авто-стрельба по убийце (шериф)",
    "GunBot", function(on)
        if on then startGunBot() end
    end)
makeToggle("combat", "Knife Aura",
    "Авто-удар ножом по игрокам рядом",
    "KnifeAura", function(on)
        if on then startKnifeAura() end
    end)
makeToggle("combat", "God Mode",
    "HP не опускается ниже максимума",
    "GodMode", function(on)
        if on then startGodMode() end
    end)
makeSlider("combat", "Knife Aura Radius",
    "Радиус срабатывания ауры (studs)",
    3, 30, 10, "KnifeAuraRadius", nil)

-- ── FARM ──
makeSection("farm", "Монеты")
makeToggle("farm", "Auto Farm",
    "Авто-сбор монет Coin/MainCoin с карты",
    "AutoFarm", function(on)
        if on then startFarm() end
    end)
makeToggle("farm", "Infinite Coins",
    "Бесконечные монеты через Values",
    "InfiniteCoins", function(on)
        if on then startInfiniteCoins() end
    end)
makeButton("farm", "Collect All Now",
    "Собрать все монеты с карты прямо сейчас",
    function()
        local oldState = STATE.AutoFarm
        STATE.AutoFarm = true
        collectCoins()
        STATE.AutoFarm = oldState
    end)

-- ── MOVEMENT ──
makeSection("move", "Передвижение")
makeToggle("move", "Speed Hack",
    "Увеличенная скорость и прыжок",
    "SpeedHack", function(on)
        applySpeed()
    end)
makeSlider("move", "Walk Speed",
    "Скорость бега (стандарт: 16)",
    16, 120, 50, "WalkSpeed", function(v)
        if STATE.SpeedHack then
            pcall(function()
                local hum = Player.Character
                    and Player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = v end
            end)
        end
    end)
makeSlider("move", "Jump Power",
    "Сила прыжка (стандарт: 50)",
    50, 350, 100, "JumpPower", function(v)
        if STATE.SpeedHack then
            pcall(function()
                local hum = Player.Character
                    and Player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpPower = v end
            end)
        end
    end)
makeToggle("move", "NoClip",
    "Проходить сквозь стены и объекты",
    "NoClip", function(on)
        startNoclip()
    end)
makeButton("move", "Teleport to Spawn",
    "Телепорт на точку спавна",
    function()
        pcall(function()
            local root = Player.Character
                and Player.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local sp = Workspace:FindFirstChildWhichIsA("SpawnLocation")
                or Workspace:FindFirstChild("Spawn")
            if sp then
                root.CFrame = sp.CFrame * CFrame.new(0, 5, 0)
            else
                root.CFrame = CFrame.new(0, 10, 0)
            end
        end)
    end)

-- ── ANTI-BAN ──
makeSection("anti", "Защита")
makeToggle("anti", "Anti-Kick",
    "Блокировать кик с сервера",
    "AntiBan", function(on)
        if on then initAntiBan() end
    end)
makeToggle("anti", "Fake Lag",
    "Имитация лага для защиты",
    "FakeLag", function(on) end)
makeButton("anti", "Rejoin",
    "Быстрый реконнект",
    function()
        local TS = game:GetService("TeleportService")
        TS:Teleport(game.PlaceId, Player)
    end)

-- ── MISC ──
makeSection("misc", "Прочее")
makeButton("misc", "Scan Remotes",
    "Вывести все Remote'ы в консоль",
    function()
        local c = 0
        for _, r in ipairs(game:GetDescendants()) do
            if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                print("[Remote] " .. r:GetFullName())
                c += 1
            end
        end
        print("[SkillHub] Remote'ов найдено: " .. c)
    end)
makeButton("misc", "Scan Coins",
    "Найти все монеты в Workspace",
    function()
        local c = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if n == "coin" or n == "maincoin" or n == "coinobject" then
                print("[Coin] " .. obj:GetFullName()
                    .. " | Pos: " .. tostring(
                        obj:IsA("BasePart") and obj.Position or Vector3.new()
                    ))
                c += 1
            end
        end
        print("[SkillHub] Монет найдено: " .. c)
    end)
makeButton("misc", "Scan Values",
    "Значения leaderstats в консоль",
    function()
        local ls = Player:FindFirstChild("leaderstats")
        if ls then
            for _, v in ipairs(ls:GetChildren()) do
                print("[Value] " .. v.Name .. " = " .. tostring(v.Value))
            end
        else
            for _, v in ipairs(Player:GetDescendants()) do
                if v:IsA("IntValue") or v:IsA("NumberValue") then
                    print("[Value] " .. v:GetFullName() .. " = " .. tostring(v.Value))
                end
            end
        end
    end)
makeButton("misc", "Copy PlaceId",
    "PlaceId в консоль",
    function()
        print("[SkillHub] PlaceId: " .. game.PlaceId)
    end)

-- ═══════════════════════════════════════
--  КНОПКИ ОКНА
-- ═══════════════════════════════════════
local minimized = false

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, 560, 0, 50)
        }):Play()
        Sidebar.Visible = false
        Scroll.Visible = false
        MinBtn.Text = "+"
    else
        Sidebar.Visible = true
        Scroll.Visible = true
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, 560, 0, 440)
        }):Play()
        MinBtn.Text = "—"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    for k in pairs(STATE) do STATE[k] = false end
    clearESP()
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back,
        Enum.EasingDirection.In), {
        Size     = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
    }):Play()
    task.wait(0.35)
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl
    or input.KeyCode == Enum.KeyCode.F9 then
        Main.Visible = not Main.Visible
    end
end)

-- ═══════════════════════════════════════
--  АНИМАЦИЯ ОТКРЫТИЯ
-- ═══════════════════════════════════════
Main.Size     = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)

TweenService:Create(Main,
    TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size     = UDim2.new(0, 560, 0, 440),
    Position = UDim2.new(0.5, -280, 0.5, -220),
}):Play()

-- ═══════════════════════════════════════
--  ЗАПУСК
-- ═══════════════════════════════════════
task.wait(0.6)
activateESP()
initAntiBan()

-- Пульсация свечения иконки
task.spawn(function()
    while task.wait(2) do
        TweenService:Create(iconGlow,
            TweenInfo.new(1.5, Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut, 0, true), {
            ImageTransparency = 0.35
        }):Play()
        task.wait(1.5)
    end
end)

-- Анимация линии
task.spawn(function()
    while task.wait(0.05) do
        lineGrad.Offset = Vector2.new(
            math.sin(tick() * 0.5) * 0.8, 0
        )
    end
end)

print("✅ [Skill Hub] MM2 загружен!")
print("🎮 RightCtrl / F9 — скрыть/показать")
