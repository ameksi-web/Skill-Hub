--[[
    Skill Hub - Murder Mystery 2
    Design: Rinns Hub Blue Lock Style
    Game: Murder Mystery 2
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local Player            = Players.LocalPlayer
local Mouse             = Player:GetMouse()

-- ═══════════════════════════════════════
--  ПРОВЕРКА ИГРЫ
-- ═══════════════════════════════════════
local MM2_PLACE_IDS = {142823291, 142823291}
local isMM2 = table.find(MM2_PLACE_IDS, game.PlaceId) ~= nil

-- ═══════════════════════════════════════
--  СОСТОЯНИЯ
-- ═══════════════════════════════════════
local STATE = {
    ESPEnabled      = false,
    GunBotEnabled   = false,
    KnifeAuraEnabled= false,
    AutoCollectEnabled = false,
    SpeedHackEnabled= false,
    NoClipEnabled   = false,
    InfiniteCoins   = false,
    AutoFarmEnabled = false,
    AntiBanEnabled  = true,
    GodModeEnabled  = false,
    ShowKiller      = false,
    ShowSheriff     = false,
    FakeLag         = false,
    MurderESP       = false,
    SheriffESP      = false,
}

local SETTINGS = {
    WalkSpeed       = 16,
    JumpPower       = 50,
    ESPDistance     = 500,
    KnifeAuraRadius = 10,
}

-- ═══════════════════════════════════════
--  ЗАГРУЗКА ЛОГОТИПА С GITHUB
-- ═══════════════════════════════════════
local LOGO_URL = "https://raw.githubusercontent.com/ameksi-web/Skill-Hub/main/Logo/logo.png"
local logoLoaded = false

-- ═══════════════════════════════════════
--  УДАЛИТЬ СТАРЫЙ GUI
-- ═══════════════════════════════════════
if Player.PlayerGui:FindFirstChild("SkillHub") then
    Player.PlayerGui:FindFirstChild("SkillHub"):Destroy()
end

-- ═══════════════════════════════════════
--  ЦВЕТА (Rinns Hub Blue Lock стиль)
-- ═══════════════════════════════════════
local Colors = {
    -- Основные
    BG          = Color3.fromRGB(8,   10,  20),   -- Очень тёмный синий
    BG2         = Color3.fromRGB(12,  15,  30),   -- Тёмный синий
    BG3         = Color3.fromRGB(18,  22,  45),   -- Синий фон карточки
    
    -- Акцент Blue Lock (яркий синий / cyan)
    Accent      = Color3.fromRGB(0,   140, 255),  -- Основной синий
    AccentDark  = Color3.fromRGB(0,   90,  200),  -- Тёмный синий
    AccentGlow  = Color3.fromRGB(30,  160, 255),  -- Светящийся
    Cyan        = Color3.fromRGB(0,   220, 255),  -- Cyan акцент
    
    -- Текст
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecond  = Color3.fromRGB(160, 175, 210),
    TextDim     = Color3.fromRGB(90,  105, 150),
    
    -- Статус
    Green       = Color3.fromRGB(50,  255, 130),
    Red         = Color3.fromRGB(255, 70,  70),
    Yellow      = Color3.fromRGB(255, 210, 50),
    Purple      = Color3.fromRGB(150, 80,  255),
    
    -- Полоска
    Divider     = Color3.fromRGB(25,  35,  70),
    
    -- Кнопка вкл
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

-- ───────────────────────────────────────
--  ГЛАВНОЕ ОКНО
-- ───────────────────────────────────────
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 560, 0, 440)
Main.Position = UDim2.new(0.5, -280, 0.5, -220)
Main.BackgroundColor3 = Colors.BG
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)

-- Внешнее свечение
local outerGlow = Instance.new("ImageLabel")
outerGlow.Name = "OuterGlow"
outerGlow.Size = UDim2.new(1, 60, 1, 60)
outerGlow.Position = UDim2.new(0, -30, 0, -30)
outerGlow.BackgroundTransparency = 1
outerGlow.Image = "rbxassetid://5028857084"
outerGlow.ImageColor3 = Colors.Accent
outerGlow.ImageTransparency = 0.75
outerGlow.ZIndex = 0
outerGlow.Parent = Main

-- Акцент-линия сверху (Blue Lock стиль)
local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 2)
topLine.BackgroundColor3 = Colors.Accent
topLine.BorderSizePixel = 0
topLine.ZIndex = 10
topLine.Parent = Main

-- Градиент линии
local lineGrad = Instance.new("UIGradient")
lineGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Colors.BG),
    ColorSequenceKeypoint.new(0.3, Colors.Accent),
    ColorSequenceKeypoint.new(0.7, Colors.Cyan),
    ColorSequenceKeypoint.new(1, Colors.BG),
})
lineGrad.Parent = topLine

-- ───────────────────────────────────────
--  DRAG
-- ───────────────────────────────────────
local dragging, dragInput, dragStart, startPos
local function setupDrag(frame)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
end

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        TweenService:Create(Main, TweenInfo.new(0.05), {Position = newPos}):Play()
    end
end)

-- ───────────────────────────────────────
--  ЛЕВАЯ БОКОВАЯ ПАНЕЛЬ (навигация)
-- ───────────────────────────────────────
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Colors.BG2
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = Main

-- Нижние углы — квадратные (только левые округлые)
local sideCorner = Instance.new("UICorner", Sidebar)
sideCorner.CornerRadius = UDim.new(0, 16)

local sideFix = Instance.new("Frame", Sidebar)
sideFix.Size = UDim2.new(0, 16, 1, 0)
sideFix.Position = UDim2.new(1, -16, 0, 0)
sideFix.BackgroundColor3 = Colors.BG2
sideFix.BorderSizePixel = 0
sideFix.ZIndex = 1

-- Лого + название в сайдбаре
local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(1, 0, 0, 110)
logoFrame.BackgroundTransparency = 1
logoFrame.ZIndex = 3
logoFrame.Parent = Sidebar

-- Логотип (загружаем с GitHub)
local logoImg = Instance.new("ImageLabel")
logoImg.Size = UDim2.new(0, 55, 0, 55)
logoImg.Position = UDim2.new(0.5, -27, 0, 12)
logoImg.BackgroundTransparency = 1
logoImg.Image = LOGO_URL
logoImg.ScaleType = Enum.ScaleType.Fit
logoImg.ZIndex = 5
logoImg.Parent = logoFrame

Instance.new("UICorner", logoImg).CornerRadius = UDim.new(0, 12)

-- Свечение логотипа
local logoGlow = Instance.new("ImageLabel")
logoGlow.Size = UDim2.new(0, 75, 0, 75)
logoGlow.Position = UDim2.new(0.5, -37, 0, 2)
logoGlow.BackgroundTransparency = 1
logoGlow.Image = "rbxassetid://5028857084"
logoGlow.ImageColor3 = Colors.Accent
logoGlow.ImageTransparency = 0.6
logoGlow.ZIndex = 4
logoGlow.Parent = logoFrame

-- Название
local hubName = Instance.new("TextLabel")
hubName.Size = UDim2.new(1, 0, 0, 22)
hubName.Position = UDim2.new(0, 0, 0, 72)
hubName.BackgroundTransparency = 1
hubName.Text = "Skill Hub"
hubName.TextColor3 = Colors.TextPrimary
hubName.TextSize = 17
hubName.Font = Enum.Font.GothamBold
hubName.ZIndex = 5
hubName.Parent = logoFrame

-- Подпись
local hubSub = Instance.new("TextLabel")
hubSub.Size = UDim2.new(1, 0, 0, 16)
hubSub.Position = UDim2.new(0, 0, 0, 93)
hubSub.BackgroundTransparency = 1
hubSub.Text = "Murder Mystery 2"
hubSub.TextColor3 = Colors.Accent
hubSub.TextSize = 11
hubSub.Font = Enum.Font.Gotham
hubSub.ZIndex = 5
hubSub.Parent = logoFrame

-- Разделитель под лого
local logoDivider = Instance.new("Frame")
logoDivider.Size = UDim2.new(1, -24, 0, 1)
logoDivider.Position = UDim2.new(0, 12, 0, 112)
logoDivider.BackgroundColor3 = Colors.Divider
logoDivider.BorderSizePixel = 0
logoDivider.ZIndex = 3
logoDivider.Parent = Sidebar

-- Навигация
local NavList = Instance.new("Frame")
NavList.Size = UDim2.new(1, 0, 1, -125)
NavList.Position = UDim2.new(0, 0, 0, 118)
NavList.BackgroundTransparency = 1
NavList.ZIndex = 3
NavList.Parent = Sidebar

local navLayout = Instance.new("UIListLayout", NavList)
navLayout.Padding = UDim.new(0, 3)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder

local navPad = Instance.new("UIPadding", NavList)
navPad.PaddingLeft = UDim.new(0, 8)
navPad.PaddingRight = UDim.new(0, 8)

-- ───────────────────────────────────────
--  ПРАВАЯ ПАНЕЛЬ (контент)
-- ───────────────────────────────────────
local ContentPanel = Instance.new("Frame")
ContentPanel.Name = "ContentPanel"
ContentPanel.Size = UDim2.new(1, -160, 1, 0)
ContentPanel.Position = UDim2.new(0, 160, 0, 0)
ContentPanel.BackgroundColor3 = Colors.BG
ContentPanel.BorderSizePixel = 0
ContentPanel.ZIndex = 2
ContentPanel.Parent = Main

-- Заголовок правой панели
local ContentHeader = Instance.new("Frame")
ContentHeader.Size = UDim2.new(1, 0, 0, 52)
ContentHeader.BackgroundColor3 = Colors.BG2
ContentHeader.BorderSizePixel = 0
ContentHeader.ZIndex = 3
ContentHeader.Parent = ContentPanel
setupDrag(ContentHeader)

local headerFix = Instance.new("Frame", ContentHeader)
headerFix.Size = UDim2.new(1, 0, 0, 16)
headerFix.Position = UDim2.new(0, 0, 1, -16)
headerFix.BackgroundColor3 = Colors.BG2
headerFix.BorderSizePixel = 0
headerFix.ZIndex = 2

-- Название текущей страницы
local PageTitle = Instance.new("TextLabel")
PageTitle.Name = "PageTitle"
PageTitle.Size = UDim2.new(1, -120, 1, 0)
PageTitle.Position = UDim2.new(0, 18, 0, 0)
PageTitle.BackgroundTransparency = 1
PageTitle.Text = "ESP & Visuals"
PageTitle.TextColor3 = Colors.TextPrimary
PageTitle.TextSize = 18
PageTitle.Font = Enum.Font.GothamBold
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.ZIndex = 5
PageTitle.Parent = ContentHeader

-- Кнопки окна
local function makeWinBtn(text, color, xOffset)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 28, 0, 28)
    btn.Position = UDim2.new(1, xOffset, 0.5, -14)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.ZIndex = 6
    btn.Parent = ContentHeader
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    return btn
end

local MinBtn   = makeWinBtn("—", Color3.fromRGB(255, 165, 0), -68)
local CloseBtn = makeWinBtn("✕", Color3.fromRGB(220, 40, 40), -35)

-- Разделитель
local headerDivider = Instance.new("Frame")
headerDivider.Size = UDim2.new(1, 0, 0, 1)
headerDivider.Position = UDim2.new(0, 0, 1, -1)
headerDivider.BackgroundColor3 = Colors.Divider
headerDivider.BorderSizePixel = 0
headerDivider.ZIndex = 4
headerDivider.Parent = ContentHeader

-- Скролл контента
local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, -12, 1, -65)
ContentScroll.Position = UDim2.new(0, 6, 0, 56)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 3
ContentScroll.ScrollBarImageColor3 = Colors.Accent
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentScroll.ZIndex = 3
ContentScroll.Parent = ContentPanel

local contentLayout = Instance.new("UIListLayout", ContentScroll)
contentLayout.Padding = UDim.new(0, 6)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

local contentPad = Instance.new("UIPadding", ContentScroll)
contentPad.PaddingTop = UDim.new(0, 6)
contentPad.PaddingBottom = UDim.new(0, 6)

-- ═══════════════════════════════════════
--  СТРАНИЦЫ
-- ═══════════════════════════════════════
local Pages = {}
local currentPage = nil

local function showPage(name)
    if currentPage == name then return end
    currentPage = name
    -- Скрываем все элементы
    for _, child in ipairs(ContentScroll:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("_item") then
            child.Visible = child.Name:find("^"..name)
        end
    end
    PageTitle.Text = name
end

-- ═══════════════════════════════════════
--  СТРОИТЕЛЬ КНОПОК
-- ═══════════════════════════════════════
local function makeSection(title, pageTag)
    local sec = Instance.new("Frame")
    sec.Name = pageTag .. "_section_" .. title
    sec.Size = UDim2.new(1, 0, 0, 28)
    sec.BackgroundTransparency = 1
    sec.LayoutOrder = #ContentScroll:GetChildren()
    sec.ZIndex = 3
    sec.Parent = ContentScroll

    local line = Instance.new("Frame", sec)
    line.Size = UDim2.new(1, -10, 0, 1)
    line.Position = UDim2.new(0, 5, 0.5, 0)
    line.BackgroundColor3 = Colors.Divider
    line.BorderSizePixel = 0

    local lineGr = Instance.new("UIGradient", line)
    lineGr.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Colors.Accent),
        ColorSequenceKeypoint.new(1, Colors.BG),
    })

    local lbl = Instance.new("TextLabel", sec)
    lbl.Size = UDim2.new(0, 120, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundColor3 = Colors.BG
    lbl.BorderSizePixel = 0
    lbl.Text = "  " .. title .. "  "
    lbl.TextColor3 = Colors.Accent
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.ZIndex = 4

    return sec
end

-- Кнопка-переключатель (Rinns Hub стиль)
local function makeToggle(pageTag, name, desc, stateKey, callback)
    local item = Instance.new("Frame")
    item.Name = pageTag .. "_item_" .. name
    item.Size = UDim2.new(1, 0, 0, 58)
    item.BackgroundColor3 = Colors.BG3
    item.BorderSizePixel = 0
    item.LayoutOrder = #ContentScroll:GetChildren()
    item.ZIndex = 3
    item.Parent = ContentScroll

    Instance.new("UICorner", item).CornerRadius = UDim.new(0, 10)

    local itemStroke = Instance.new("UIStroke", item)
    itemStroke.Color = Colors.Divider
    itemStroke.Thickness = 1

    -- Левая цветная полоска
    local leftBar = Instance.new("Frame", item)
    leftBar.Size = UDim2.new(0, 3, 0, 38)
    leftBar.Position = UDim2.new(0, 0, 0.5, -19)
    leftBar.BackgroundColor3 = Colors.Accent
    leftBar.BorderSizePixel = 0
    Instance.new("UICorner", leftBar).CornerRadius = UDim.new(0, 3)

    -- Название
    local nameLbl = Instance.new("TextLabel", item)
    nameLbl.Size = UDim2.new(1, -100, 0, 22)
    nameLbl.Position = UDim2.new(0, 16, 0, 8)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = name
    nameLbl.TextColor3 = Colors.TextPrimary
    nameLbl.TextSize = 14
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 4

    -- Описание
    local descLbl = Instance.new("TextLabel", item)
    descLbl.Size = UDim2.new(1, -100, 0, 16)
    descLbl.Position = UDim2.new(0, 16, 0, 32)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = desc
    descLbl.TextColor3 = Colors.TextDim
    descLbl.TextSize = 11
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.ZIndex = 4

    -- Toggle Switch (Blue Lock стиль)
    local switchBG = Instance.new("Frame", item)
    switchBG.Size = UDim2.new(0, 48, 0, 26)
    switchBG.Position = UDim2.new(1, -62, 0.5, -13)
    switchBG.BackgroundColor3 = Colors.BtnOff
    switchBG.BorderSizePixel = 0
    switchBG.ZIndex = 5
    Instance.new("UICorner", switchBG).CornerRadius = UDim.new(1, 0)

    local switchCircle = Instance.new("Frame", switchBG)
    switchCircle.Size = UDim2.new(0, 20, 0, 20)
    switchCircle.Position = UDim2.new(0, 3, 0.5, -10)
    switchCircle.BackgroundColor3 = Colors.TextDim
    switchCircle.BorderSizePixel = 0
    switchCircle.ZIndex = 6
    Instance.new("UICorner", switchCircle).CornerRadius = UDim.new(1, 0)

    local switchBtn = Instance.new("TextButton", switchBG)
    switchBtn.Size = UDim2.new(1, 0, 1, 0)
    switchBtn.BackgroundTransparency = 1
    switchBtn.Text = ""
    switchBtn.ZIndex = 7

    -- Кликабельна вся карточка
    local itemBtn = Instance.new("TextButton", item)
    itemBtn.Size = UDim2.new(1, -70, 1, 0)
    itemBtn.BackgroundTransparency = 1
    itemBtn.Text = ""
    itemBtn.ZIndex = 4

    local function updateSwitch()
        local on = STATE[stateKey]
        TweenService:Create(switchBG, TweenInfo.new(0.2), {
            BackgroundColor3 = on and Colors.Accent or Colors.BtnOff
        }):Play()
        TweenService:Create(switchCircle, TweenInfo.new(0.2), {
            Position = on and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
            BackgroundColor3 = on and Colors.TextPrimary or Colors.TextDim
        }):Play()
        TweenService:Create(itemStroke, TweenInfo.new(0.2), {
            Color = on and Colors.AccentDark or Colors.Divider
        }):Play()
        TweenService:Create(leftBar, TweenInfo.new(0.2), {
            BackgroundColor3 = on and Colors.Cyan or Colors.Accent
        }):Play()
    end

    local function toggle()
        STATE[stateKey] = not STATE[stateKey]
        updateSwitch()
        callback(STATE[stateKey])
    end

    switchBtn.MouseButton1Click:Connect(toggle)
    itemBtn.MouseButton1Click:Connect(toggle)

    updateSwitch()
    return item
end

-- Кнопка действия
local function makeButton(pageTag, name, desc, callback)
    local item = Instance.new("Frame")
    item.Name = pageTag .. "_item_" .. name
    item.Size = UDim2.new(1, 0, 0, 58)
    item.BackgroundColor3 = Colors.BG3
    item.BorderSizePixel = 0
    item.LayoutOrder = #ContentScroll:GetChildren()
    item.ZIndex = 3
    item.Parent = ContentScroll

    Instance.new("UICorner", item).CornerRadius = UDim.new(0, 10)
    local itemStroke = Instance.new("UIStroke", item)
    itemStroke.Color = Colors.Divider
    itemStroke.Thickness = 1

    local leftBar = Instance.new("Frame", item)
    leftBar.Size = UDim2.new(0, 3, 0, 38)
    leftBar.Position = UDim2.new(0, 0, 0.5, -19)
    leftBar.BackgroundColor3 = Colors.Purple
    leftBar.BorderSizePixel = 0
    Instance.new("UICorner", leftBar).CornerRadius = UDim.new(0, 3)

    local nameLbl = Instance.new("TextLabel", item)
    nameLbl.Size = UDim2.new(1, -100, 0, 22)
    nameLbl.Position = UDim2.new(0, 16, 0, 8)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = name
    nameLbl.TextColor3 = Colors.TextPrimary
    nameLbl.TextSize = 14
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 4

    local descLbl = Instance.new("TextLabel", item)
    descLbl.Size = UDim2.new(1, -100, 0, 16)
    descLbl.Position = UDim2.new(0, 16, 0, 32)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = desc
    descLbl.TextColor3 = Colors.TextDim
    descLbl.TextSize = 11
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.ZIndex = 4

    local runBtn = Instance.new("TextButton", item)
    runBtn.Size = UDim2.new(0, 64, 0, 28)
    runBtn.Position = UDim2.new(1, -72, 0.5, -14)
    runBtn.BackgroundColor3 = Colors.AccentDark
    runBtn.Text = "RUN"
    runBtn.TextColor3 = Colors.TextPrimary
    runBtn.TextSize = 12
    runBtn.Font = Enum.Font.GothamBold
    runBtn.BorderSizePixel = 0
    runBtn.ZIndex = 5
    Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 8)

    runBtn.MouseButton1Click:Connect(function()
        TweenService:Create(runBtn, TweenInfo.new(0.1), {
            BackgroundColor3 = Colors.Cyan
        }):Play()
        task.spawn(callback)
        task.delay(0.4, function()
            TweenService:Create(runBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Colors.AccentDark
            }):Play()
        end)
    end)

    -- Hover эффект
    runBtn.MouseEnter:Connect(function()
        TweenService:Create(runBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Colors.Accent
        }):Play()
    end)
    runBtn.MouseLeave:Connect(function()
        TweenService:Create(runBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Colors.AccentDark
        }):Play()
    end)

    return item
end

-- Слайдер
local function makeSlider(pageTag, name, desc, min, max, default, settingKey, callback)
    local item = Instance.new("Frame")
    item.Name = pageTag .. "_item_" .. name
    item.Size = UDim2.new(1, 0, 0, 72)
    item.BackgroundColor3 = Colors.BG3
    item.BorderSizePixel = 0
    item.LayoutOrder = #ContentScroll:GetChildren()
    item.ZIndex = 3
    item.Parent = ContentScroll

    Instance.new("UICorner", item).CornerRadius = UDim.new(0, 10)
    local itemStroke = Instance.new("UIStroke", item)
    itemStroke.Color = Colors.Divider
    itemStroke.Thickness = 1

    local leftBar = Instance.new("Frame", item)
    leftBar.Size = UDim2.new(0, 3, 0, 52)
    leftBar.Position = UDim2.new(0, 0, 0.5, -26)
    leftBar.BackgroundColor3 = Colors.Yellow
    leftBar.BorderSizePixel = 0
    Instance.new("UICorner", leftBar).CornerRadius = UDim.new(0, 3)

    local nameLbl = Instance.new("TextLabel", item)
    nameLbl.Size = UDim2.new(0.6, 0, 0, 20)
    nameLbl.Position = UDim2.new(0, 16, 0, 6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = name
    nameLbl.TextColor3 = Colors.TextPrimary
    nameLbl.TextSize = 14
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 4

    local valLbl = Instance.new("TextLabel", item)
    valLbl.Size = UDim2.new(0.4, -16, 0, 20)
    valLbl.Position = UDim2.new(0.6, 0, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = Colors.Cyan
    valLbl.TextSize = 14
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.ZIndex = 4

    local descLbl = Instance.new("TextLabel", item)
    descLbl.Size = UDim2.new(1, -20, 0, 14)
    descLbl.Position = UDim2.new(0, 16, 0, 26)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = desc
    descLbl.TextColor3 = Colors.TextDim
    descLbl.TextSize = 11
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.ZIndex = 4

    -- Track
    local track = Instance.new("Frame", item)
    track.Size = UDim2.new(1, -32, 0, 6)
    track.Position = UDim2.new(0, 16, 0, 50)
    track.BackgroundColor3 = Colors.BtnOff
    track.BorderSizePixel = 0
    track.ZIndex = 4
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    -- Fill
    local fill = Instance.new("Frame", track)
    local startPct = (default - min) / (max - min)
    fill.Size = UDim2.new(startPct, 0, 1, 0)
    fill.BackgroundColor3 = Colors.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    -- Thumb
    local thumb = Instance.new("Frame", track)
    thumb.Size = UDim2.new(0, 16, 0, 16)
    thumb.Position = UDim2.new(startPct, -8, 0.5, -8)
    thumb.BackgroundColor3 = Colors.TextPrimary
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 6
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    -- Gradient fill
    local fillGrad = Instance.new("UIGradient", fill)
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Colors.AccentDark),
        ColorSequenceKeypoint.new(1, Colors.Cyan),
    })

    local sliding = false
    local currentVal = default

    local function updateSlider(x)
        local abs = track.AbsolutePosition.X
        local w   = track.AbsoluteSize.X
        local pct = math.clamp((x - abs) / w, 0, 1)
        currentVal = math.floor(min + (max - min) * pct)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -8, 0.5, -8)
        valLbl.Text = tostring(currentVal)
        if settingKey then SETTINGS[settingKey] = currentVal end
        if callback then callback(currentVal) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            updateSlider(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    return item
end

-- ═══════════════════════════════════════
--  НАВИГАЦИЯ (вкладки сайдбара)
-- ═══════════════════════════════════════
local navItems = {}
local activeNavItem = nil

local function makeNavItem(text, emoji, pageTag)
    local btn = Instance.new("TextButton")
    btn.Name = "Nav_" .. pageTag
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.LayoutOrder = #navItems + 1
    btn.ZIndex = 5
    btn.Parent = NavList

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0, 3, 0, 22)
    indicator.Position = UDim2.new(0, 0, 0.5, -11)
    indicator.BackgroundColor3 = Colors.Accent
    indicator.BorderSizePixel = 0
    indicator.BackgroundTransparency = 1
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    local emojiLbl = Instance.new("TextLabel", btn)
    emojiLbl.Size = UDim2.new(0, 26, 1, 0)
    emojiLbl.Position = UDim2.new(0, 8, 0, 0)
    emojiLbl.BackgroundTransparency = 1
    emojiLbl.Text = emoji
    emojiLbl.TextSize = 16
    emojiLbl.ZIndex = 6

    local textLbl = Instance.new("TextLabel", btn)
    textLbl.Size = UDim2.new(1, -38, 1, 0)
    textLbl.Position = UDim2.new(0, 36, 0, 0)
    textLbl.BackgroundTransparency = 1
    textLbl.Text = text
    textLbl.TextColor3 = Colors.TextSecond
    textLbl.TextSize = 13
    textLbl.Font = Enum.Font.Gotham
    textLbl.TextXAlignment = Enum.TextXAlignment.Left
    textLbl.ZIndex = 6

    local function activate()
        -- Сбросить все
        for _, ni in ipairs(navItems) do
            TweenService:Create(ni.btn, TweenInfo.new(0.2), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(ni.indicator, TweenInfo.new(0.2), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(ni.text, TweenInfo.new(0.2), {
                TextColor3 = Colors.TextSecond
            }):Play()
            ni.text.Font = Enum.Font.Gotham
        end
        -- Активировать текущую
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0
        }):Play()
        btn.BackgroundColor3 = Colors.BtnOn
        TweenService:Create(indicator, TweenInfo.new(0.2), {
            BackgroundTransparency = 0
        }):Play()
        TweenService:Create(textLbl, TweenInfo.new(0.2), {
            TextColor3 = Colors.TextPrimary
        }):Play()
        textLbl.Font = Enum.Font.GothamBold
        activeNavItem = pageTag

        -- Показать страницу
        PageTitle.Text = text
        for _, child in ipairs(ContentScroll:GetChildren()) do
            if child:IsA("Frame") then
                local show = child.Name:sub(1, #pageTag) == pageTag
                child.Visible = show
            end
        end
    end

    btn.MouseButton1Click:Connect(activate)

    -- Hover
    btn.MouseEnter:Connect(function()
        if activeNavItem ~= pageTag then
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.7
            }):Play()
            btn.BackgroundColor3 = Colors.BtnOn
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeNavItem ~= pageTag then
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundTransparency = 1
            }):Play()
        end
    end)

    local entry = {btn = btn, indicator = indicator, text = textLbl, tag = pageTag, activate = activate}
    table.insert(navItems, entry)
    return entry
end

-- ═══════════════════════════════════════
--  СОЗДАНИЕ ВКЛАДОК
-- ═══════════════════════════════════════
local navESP     = makeNavItem("ESP / Visuals", "👁️", "esp")
local navCombat  = makeNavItem("Combat",        "⚔️", "combat")
local navFarm    = makeNavItem("Farm / Coins",  "💰", "farm")
local navMove    = makeNavItem("Movement",      "🏃", "move")
local navAnti    = makeNavItem("Anti-Ban",      "🛡️", "anti")
local navMisc    = makeNavItem("Misc",          "🔧", "misc")

-- Версия внизу сайдбара
local verLabel = Instance.new("TextLabel")
verLabel.Size = UDim2.new(1, 0, 0, 20)
verLabel.Position = UDim2.new(0, 0, 1, -22)
verLabel.BackgroundTransparency = 1
verLabel.Text = "v1.0 | MM2"
verLabel.TextColor3 = Colors.TextDim
verLabel.TextSize = 11
verLabel.Font = Enum.Font.Gotham
verLabel.ZIndex = 4
verLabel.Parent = Sidebar

-- ═══════════════════════════════════════
--  ЛОГИКА MM2
-- ═══════════════════════════════════════

-- ESP
local espObjects = {}
local function clearESP()
    for _, v in ipairs(espObjects) do
        pcall(function() v:Destroy() end)
    end
    espObjects = {}
end

local function createESP(player, color)
    if player == Player then return end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root then return end

    -- BillboardGui над головой
    local bb = Instance.new("BillboardGui")
    bb.Name = "SkillHubESP"
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 120, 0, 45)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.Adornee = root
    bb.Parent = Workspace

    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.Size = UDim2.new(1, 0, 0.6, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = player.Name
    nameLbl.TextColor3 = color
    nameLbl.TextSize = 14
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextStrokeTransparency = 0

    local hpLbl = Instance.new("TextLabel", bb)
    hpLbl.Size = UDim2.new(1, 0, 0.4, 0)
    hpLbl.Position = UDim2.new(0, 0, 0.6, 0)
    hpLbl.BackgroundTransparency = 1
    hpLbl.Text = "HP: " .. (hum and math.floor(hum.Health) or "?")
    hpLbl.TextColor3 = Colors.Green
    hpLbl.TextSize = 11
    hpLbl.Font = Enum.Font.Gotham
    hpLbl.TextStrokeTransparency = 0

    -- Обновление HP
    local conn = RunService.Heartbeat:Connect(function()
        if not STATE.ESPEnabled then
            bb:Destroy()
            return
        end
        if hum then
            hpLbl.Text = "HP: " .. math.floor(hum.Health)
        end
    end)

    table.insert(espObjects, bb)
    table.insert(espObjects, {Destroy = function() conn:Disconnect() end})
end

local function updateESP()
    clearESP()
    if not STATE.ESPEnabled then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            local color = Colors.TextPrimary
            createESP(p, color)
        end
    end
end

-- Murder ESP (показ убийцы/шерифа)
local function getMM2Role(player)
    pcall(function()
        for _, folder in ipairs(ReplicatedStorage:GetDescendants()) do
            if folder.Name == "GameData" or folder.Name == "PlayerData" or folder.Name == "RoleData" then
                for _, v in ipairs(folder:GetChildren()) do
                    if v.Name == player.Name or v.Name == "Role" then
                        return v.Value
                    end
                end
            end
        end
    end)
    -- Ищем через Values у персонажа
    if player.Character then
        local role = player.Character:FindFirstChild("Role")
            or player.Character:FindFirstChild("Murder")
            or player.Character:FindFirstChild("Sheriff")
        if role then return role.Value end
    end
    return "Unknown"
end

-- Показ убийцы в чате
local function showRoles()
    local killerName = "Unknown"
    local sheriffName = "Unknown"

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            -- Проверяем нож (убийца держит нож)
            local knife = p.Character:FindFirstChild("Knife")
                or p.Character:FindFirstChild("MM2Knife")
                or p.Character:FindFirstChildWhichIsA("Tool")
            if knife and (knife.Name:lower():find("knife") or knife.Name:lower():find("murder")) then
                killerName = p.Name
            end
            -- Проверяем пистолет (шериф)
            local gun = p.Character:FindFirstChild("Gun")
                or p.Character:FindFirstChild("Sheriff")
            if gun and (gun.Name:lower():find("gun") or gun.Name:lower():find("sheriff")) then
                sheriffName = p.Name
            end
        end
    end

    -- Вывод в чат / на экране
    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
        Text = "[SkillHub] 🔪 Killer: " .. killerName .. " | 🔫 Sheriff: " .. sheriffName,
        Color = Color3.fromRGB(255, 100, 100),
        Font = Enum.Font.GothamBold,
        FontSize = Enum.FontSize.Size18,
    })
end

-- GunBot (авто-стрельба по убийце)
local gunBotConn = nil
local function startGunBot()
    if gunBotConn then gunBotConn:Disconnect() end
    gunBotConn = RunService.Heartbeat:Connect(function()
        if not STATE.GunBotEnabled then
            gunBotConn:Disconnect()
            return
        end
        pcall(function()
            local char = Player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            -- Ищем убийцу
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and p.Character then
                    local proot = p.Character:FindFirstChild("HumanoidRootPart")
                    local knife = p.Character:FindFirstChild("Knife")
                        or p.Character:FindFirstChildWhichIsA("Tool")
                    if proot and knife and knife.Name:lower():find("knife") then
                        local dist = (proot.Position - root.Position).Magnitude
                        if dist < SETTINGS.ESPDistance then
                            -- Наводка на убийцу
                            local tool = char:FindFirstChildWhichIsA("Tool")
                            if tool then
                                for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                                    if r:IsA("RemoteEvent") then
                                        local n = r.Name:lower()
                                        if n:find("shoot") or n:find("fire")
                                           or n:find("gun") or n:find("bullet") then
                                            r:FireServer(proot.Position, proot)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end)
end

-- Knife Aura (убийца — авто-убийство рядом)
local knifeAuraConn = nil
local function startKnifeAura()
    if knifeAuraConn then knifeAuraConn:Disconnect() end
    knifeAuraConn = RunService.Heartbeat:Connect(function()
        if not STATE.KnifeAuraEnabled then
            knifeAuraConn:Disconnect()
            return
        end
        pcall(function()
            local char = Player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player and p.Character then
                    local proot = p.Character:FindFirstChild("HumanoidRootPart")
                    local phum = p.Character:FindFirstChildOfClass("Humanoid")
                    if proot and phum and phum.Health > 0 then
                        local dist = (proot.Position - root.Position).Magnitude
                        if dist <= SETTINGS.KnifeAuraRadius then
                            -- Телепорт и убийство
                            root.CFrame = proot.CFrame * CFrame.new(0, 0, -2)
                            for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                                if r:IsA("RemoteEvent") then
                                    local n = r.Name:lower()
                                    if n:find("knife") or n:find("kill")
                                       or n:find("stab") or n:find("murder") then
                                        r:FireServer(p.Character, proot.Position)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end)
end

-- Speed Hack
local function setSpeed(on)
    pcall(function()
        local char = Player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = on and SETTINGS.WalkSpeed or 16
            hum.JumpPower = on and SETTINGS.JumpPower or 50
        end
    end)
    Player.CharacterAdded:Connect(function(c)
        task.wait(1)
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and STATE.SpeedHackEnabled then
            hum.WalkSpeed = SETTINGS.WalkSpeed
            hum.JumpPower = SETTINGS.JumpPower
        end
    end)
end

-- NoClip
local noClipConn = nil
local function setupNoclip(on)
    if noClipConn then noClipConn:Disconnect(); noClipConn = nil end
    if on then
        noClipConn = RunService.Stepped:Connect(function()
            pcall(function()
                if not STATE.NoClipEnabled then
                    noClipConn:Disconnect(); return
                end
                local char = Player.Character
                if not char then return end
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then
                        p.CanCollide = false
                    end
                end
            end)
        end)
    end
end

-- God Mode
local godConn = nil
local function setupGodMode(on)
    if godConn then godConn:Disconnect(); godConn = nil end
    if on then
        godConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not STATE.GodModeEnabled then
                    godConn:Disconnect(); return
                end
                local char = Player.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.Health = hum.MaxHealth
                end
            end)
        end)
    end
end

-- Infinite Coins
local coinConn = nil
local function setupInfiniteCoins(on)
    if coinConn then task.cancel(coinConn); coinConn = nil end
    if on then
        coinConn = task.spawn(function()
            while STATE.InfiniteCoins and task.wait(1.5) do
                pcall(function()
                    for _, v in ipairs(Player:GetDescendants()) do
                        if v:IsA("IntValue") or v:IsA("NumberValue") then
                            local n = v.Name:lower()
                            if n:find("coin") or n:find("gold")
                               or n:find("money") or n:find("cash") then
                                v.Value = 999999999
                            end
                        end
                    end
                    local ls = Player:FindFirstChild("leaderstats")
                    if ls then
                        for _, s in ipairs(ls:GetChildren()) do
                            if s:IsA("IntValue") or s:IsA("NumberValue") then
                                pcall(function() s.Value = 999999999 end)
                            end
                        end
                    end
                    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                        if r:IsA("RemoteEvent") then
                            local n = r.Name:lower()
                            if n:find("coin") or n:find("reward") then
                                r:FireServer("Add", 999999)
                                r:FireServer(999999)
                            end
                        end
                    end
                end)
            end
        end)
    end
end

-- Auto Collect Coins (с карты)
local farmConn = nil
local function setupAutoFarm(on)
    if farmConn then task.cancel(farmConn); farmConn = nil end
    if on then
        farmConn = task.spawn(function()
            while STATE.AutoFarmEnabled and task.wait(0.2) do
                pcall(function()
                    local char = Player.Character
                    if not char then return end
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if not root then return end

                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if not STATE.AutoFarmEnabled then break end
                        local n = obj.Name:lower()
                        if n:find("coin") or n:find("reward") or n:find("gold")
                           or n:find("crate") or n:find("gift") or n:find("present") then
                            local tgt = obj:IsA("BasePart") and obj
                                or (obj:IsA("Model") and obj.PrimaryPart)
                            if tgt then
                                local dist = (tgt.Position - root.Position).Magnitude
                                if dist < 200 then
                                    root.CFrame = CFrame.new(tgt.Position) * CFrame.new(0, 2, 0)
                                    task.wait(0.1)
                                    -- Подбор через Touch
                                    if firetouchinterest then
                                        firetouchinterest(root, tgt, 0)
                                        task.wait(0.05)
                                        firetouchinterest(root, tgt, 1)
                                    end
                                    -- ProximityPrompt
                                    for _, pp in ipairs(obj:GetDescendants()) do
                                        if pp:IsA("ProximityPrompt") then
                                            pcall(function() fireproximityprompt(pp) end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end
end

-- Anti-Ban
local function initAntiBan()
    -- Блок кика
    if hookmetamethod then
        pcall(function()
            local oldNC
            oldNC = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if method == "Kick" then
                    warn("[SkillHub] Kick заблокирован!")
                    return nil
                end
                if STATE.AntiBanEnabled then
                    if method == "FireServer" or method == "InvokeServer" then
                        local n = pcall(function() return self.Name:lower() end) and self.Name:lower() or ""
                        if n:find("kick") or n:find("ban") or n:find("punish") then
                            warn("[SkillHub] Remote kick заблокирован: " .. self.Name)
                            return nil
                        end
                    end
                end
                return oldNC(self, ...)
            end)
        end)
    end

    -- Авто-восстановление из Void
    RunService.Heartbeat:Connect(function()
        if not STATE.AntiBanEnabled then return end
        pcall(function()
            local char = Player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and root.Position.Y < -200 then
                root.CFrame = CFrame.new(0, 50, 0)
            end
        end)
    end)

    -- Блок телепорта
    pcall(function()
        Player.Kick = function()
            warn("[SkillHub] Kick() заблокирован!")
        end
    end)

    print("[SkillHub] 🛡️ Anti-Ban активен!")
end

-- Fake Lag (задержка для защиты от детекта)
local fakeLagConn = nil
local function setupFakeLag(on)
    if fakeLagConn then task.cancel(fakeLagConn); fakeLagConn = nil end
    if on then
        fakeLagConn = task.spawn(function()
            while STATE.FakeLag and task.wait(math.random(15, 45)) do
                -- Имитация лага — небольшая пауза
                task.wait(math.random(1, 3) * 0.1)
            end
        end)
    end
end

-- ═══════════════════════════════════════
--  НАПОЛНЕНИЕ ВКЛАДОК
-- ═══════════════════════════════════════

-- ── ESP / Visuals ──
makeSection("ESP", "esp")

makeToggle("esp", "Player ESP", "Показывает всех игроков с именем и HP",
    "ESPEnabled", function(on)
        updateESP()
        if on then
            -- Обновляем ESP при добавлении игроков
            Players.PlayerAdded:Connect(function(p)
                task.wait(2)
                if STATE.ESPEnabled then
                    createESP(p, Colors.TextPrimary)
                end
            end)
        end
    end)

makeToggle("esp", "Murder ESP", "Подсвечивает убийцу красным",
    "MurderESP", function(on)
        clearESP()
        if on then
            -- Переопределяем ESP с ролями
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player then
                    local color = Colors.TextPrimary
                    if p.Character then
                        local tool = p.Character:FindFirstChildWhichIsA("Tool")
                        if tool and tool.Name:lower():find("knife") then
                            color = Colors.Red
                        elseif tool and tool.Name:lower():find("gun") then
                            color = Colors.Yellow
                        end
                    end
                    createESP(p, color)
                end
            end
        end
    end)

makeToggle("esp", "Sheriff ESP", "Подсвечивает шерифа жёлтым",
    "SheriffESP", function(on) end)

makeButton("esp", "Show Roles", "Вывести убийцу и шерифа в чат", showRoles)

-- ── Combat ──
makeSection("Combat", "combat")

makeToggle("combat", "Gun Bot", "Авто-прицел и стрельба по убийце",
    "GunBotEnabled", function(on)
        if on then startGunBot() end
    end)

makeToggle("combat", "Knife Aura", "Авто-убийство когда убийца рядом",
    "KnifeAuraEnabled", function(on)
        if on then startKnifeAura() end
    end)

makeToggle("combat", "God Mode", "Бесконечное HP — не умрёшь",
    "GodModeEnabled", function(on)
        setupGodMode(on)
    end)

makeSlider("combat", "Knife Aura Radius",
    "Радиус ауры ножа (studs)", 5, 30, 10,
    "KnifeAuraRadius", nil)

-- ── Farm / Coins ──
makeSection("Валюта", "farm")

makeToggle("farm", "Infinite Coins", "Бесконечные монеты / coins",
    "InfiniteCoins", function(on)
        setupInfiniteCoins(on)
    end)

makeToggle("farm", "Auto Farm", "Авто-сбор монет с карты",
    "AutoFarmEnabled", function(on)
        setupAutoFarm(on)
    end)

makeButton("farm", "Collect All Coins", "Собрать все монеты с карты одним нажатием",
    function()
        local char = Player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local collected = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if n:find("coin") or n:find("crate") or n:find("gift") then
                local tgt = obj:IsA("BasePart") and obj
                    or (obj:IsA("Model") and obj.PrimaryPart)
                if tgt then
                    root.CFrame = CFrame.new(tgt.Position) * CFrame.new(0,2,0)
                    task.wait(0.1)
                    if firetouchinterest then
                        firetouchinterest(root, tgt, 0)
                        firetouchinterest(root, tgt, 1)
                    end
                    collected += 1
                end
            end
        end
    end)

-- ── Movement ──
makeSection("Движение", "move")

makeToggle("move", "Speed Hack", "Увеличенная скорость бега",
    "SpeedHackEnabled", function(on)
        setSpeed(on)
    end)

makeSlider("move", "Walk Speed",
    "Скорость ходьбы (по умолчанию 16)", 16, 100, 50,
    "WalkSpeed", function(v)
        if STATE.SpeedHackEnabled then
            pcall(function()
                local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = v end
            end)
        end
    end)

makeSlider("move", "Jump Power",
    "Сила прыжка (по умолчанию 50)", 50, 300, 100,
    "JumpPower", function(v)
        if STATE.SpeedHackEnabled then
            pcall(function()
                local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpPower = v end
            end)
        end
    end)

makeToggle("move", "NoClip", "Проходить сквозь стены",
    "NoClipEnabled", function(on)
        setupNoclip(on)
    end)

makeButton("move", "Teleport to Spawn", "Телепорт на спавн",
    function()
        pcall(function()
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local spawn = Workspace:FindFirstChild("Spawn") or Workspace:FindFirstChildWhichIsA("SpawnLocation")
            if root and spawn then
                root.CFrame = spawn.CFrame * CFrame.new(0, 5, 0)
            end
        end)
    end)

-- ── Anti-Ban ──
makeSection("Защита", "anti")

makeToggle("anti", "Anti-Kick", "Блокировать кик с сервера",
    "AntiBanEnabled", function(on)
        if on then initAntiBan() end
    end)

makeToggle("anti", "Fake Lag", "Имитация лага для защиты от детекта",
    "FakeLag", function(on)
        setupFakeLag(on)
    end)

makeButton("anti", "Rejoin", "Быстрый реконнект в игру",
    function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, Player)
    end)

makeButton("anti", "Clear Logs", "Очистить консоль",
    function()
        if typeof(consoleclear) == "function" then
            consoleclear()
        end
    end)

-- ── Misc ──
makeSection("Прочее", "misc")

makeButton("misc", "Scan Remotes", "Показать все Remote'ы в консоли",
    function()
        local count = 0
        for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
            if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                print("[SkillHub Remote] " .. r:GetFullName())
                count += 1
            end
        end
        print("[SkillHub] Всего Remote'ов: " .. count)
    end)

makeButton("misc", "Scan Values", "Показать все Values игрока",
    function()
        for _, v in ipairs(Player:GetDescendants()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
                print("[SkillHub Value] " .. v:GetFullName() .. " = " .. tostring(v.Value))
            end
        end
    end)

makeButton("misc", "Copy PlaceId", "Скопировать PlaceId в консоль",
    function()
        print("[SkillHub] PlaceId: " .. game.PlaceId)
        print("[SkillHub] GameId: " .. game.GameId)
    end)

-- ═══════════════════════════════════════
--  КНОПКИ ОКНА
-- ═══════════════════════════════════════
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, 560, 0, 52)
        }):Play()
        Sidebar.Visible = false
        ContentScroll.Visible = false
        MinBtn.Text = "+"
    else
        Sidebar.Visible = true
        ContentScroll.Visible = true
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
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
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    task.wait(0.35)
    ScreenGui:Destroy()
end)

-- RightCtrl / F9 — показать/скрыть
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
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)

TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 560, 0, 440),
    Position = UDim2.new(0.5, -280, 0.5, -220)
}):Play()

-- ═══════════════════════════════════════
--  ЗАПУСК
-- ═══════════════════════════════════════
task.wait(0.6)

-- Активируем первую вкладку
navESP.activate()

-- Запуск Anti-Ban по умолчанию
initAntiBan()

-- Анимация логотипа
task.spawn(function()
    while task.wait(3) do
        TweenService:Create(logoGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut, 0, true), {
            ImageTransparency = 0.4
        }):Play()
        task.wait(1.5)
    end
end)

-- Анимация линии сверху
task.spawn(function()
    while task.wait(0.05) do
        local t = tick() % 4 / 4
        lineGrad.Offset = Vector2.new(t * 2 - 1, 0)
    end
end)

print("✅ [Skill Hub] Murder Mystery 2 — загружен!")
print("🔑 Горячие клавиши: RightCtrl / F9 — скрыть/показать")
