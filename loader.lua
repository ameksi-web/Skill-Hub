--[[
    Skill Hub — closed build loader + KEY MENU

    loadstring(game:HttpGet(".../loader.lua"))()              -- откроется меню ввода ключа
    loadstring(game:HttpGet(".../loader.lua"))("<key>")       -- или сразу с ключом

    Ключ ищется сам: аргумент → файл skillhub.key → буфер обмена.
    Если ключа нет или он неверный — появляется небольшое окно с полем ввода;
    верный ключ сохраняется в skillhub.key, окно закрывается, хаб запускается.

    release/skillhub.release.lua в репозитории — не Lua, а hex-шум: поток XOR,
    seed которого меняется каждые 16 байт и считается от ключа. Без ключа читать
    нечего, а ротация ключа (tools/build_release.py --pass "<новый>") отзывает
    доступ у всех, кто знал старый.
]]

local SharedEnv = (getgenv and getgenv()) or _G or {}

local Loader = {
    Build        = "v3.13",
    ExpectedHash = "1e757e73",
    Payload      = "https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/release/skillhub.release.lua",
    KeyFile      = "skillhub.key",
    Key          = "",
    Title        = "Skill Hub",
    Subtitle     = "Введите ключ доступа",
    Placeholder  = "ключ, например UPDATE 2026",
}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- ── pristine download handle ────────────────────────────────────────────────
local HttpGet = nil
do
    local ok, fn = pcall(function() return game.HttpGet end)
    if ok and type(fn) == "function" then HttpGet = fn end
end

local function fetch(url)
    if not HttpGet or type(url) ~= "string" then return nil end
    local ok, body = pcall(HttpGet, game, url)     -- plain call: __namecall hooks never see it
    if ok and type(body) == "string" and #body > 0 then return body end
    return nil
end

-- ── same hash as main.lua's Guard and tools/build_release.py ────────────────
-- >>> HASH32-CORE
local function mul32(a, b)
    local result = 0
    for _ = 1, 32 do
        if b % 2 == 1 then result = (result + a) % 4294967296 end
        a = (a * 2) % 4294967296
        b = math.floor(b / 2)
    end
    return result
end

local function xor32(a, b)
    if type(bit32) == "table" and type(bit32.bxor) == "function" then return bit32.bxor(a, b) end
    local result, bit = 0, 1
    for _ = 1, 32 do
        if a % 2 ~= b % 2 then result = result + bit end
        a, b, bit = math.floor(a / 2), math.floor(b / 2), bit * 2
    end
    return result
end

local function hash32(text)
    local hash = 2166136261
    local value = tostring(text or "")
    for index = 1, #value do
        hash = xor32(hash, (string.byte(value, index) or 0) % 256)
        hash = mul32(hash, 16777619)
    end
    return string.format("%08x", hash)
end
-- <<< HASH32-CORE

-- ── unlock: the key IS the access control ───────────────────────────────────
-- >>> UNLOCK-CORE
local function unlock(hex, key)
    if type(hex) ~= "string" or #hex == 0 then return nil end
    local out = {}
    local length = #hex - (#hex % 2)
    local index = 1
    while index <= length do
        local seed = tonumber(hash32(tostring(key) .. ":" .. math.floor((index - 1) / 2)), 16) or 1
        if seed == 0 then seed = 1 end
        for _ = 1, 16 do
            if index > length then break end
            local byte = tonumber(string.sub(hex, index, index + 1), 16)
            if not byte then return nil end
            seed = xor32(seed, (seed * 8192) % 4294967296)
            seed = xor32(seed, math.floor(seed / 131072))
            seed = xor32(seed, (seed * 32) % 4294967296)
            out[#out + 1] = string.char(xor32(byte, seed % 256))
            index = index + 2
        end
    end
    return table.concat(out)
end
-- <<< UNLOCK-CORE

-- ── key sources: argument → key file → Loader.Key → clipboard ───────────────
local function readKeyFile()
    local readers = { readfile, syn and syn.readfile }
    for _, reader in ipairs(readers) do
        if type(reader) == "function" then
            local ok, text = pcall(reader, Loader.KeyFile)
            if ok and type(text) == "string" and #text > 0 then return (string.gsub(text, "%s+$", "")) end
        end
    end
    return nil
end

local function readClipboard()
    local getters = { getclipboard, syn and syn.getclipboard }
    for _, getter in ipairs(getters) do
        if type(getter) == "function" then
            local ok, text = pcall(getter)
            if ok and type(text) == "string" and #text > 0 then
                local first = string.match(text, "^([^\r\n]+)")
                if first and #first <= 64 then return (string.gsub(first, "%s+$", "")) end
            end
        end
    end
    return nil
end

local function saveKey(key)
    local writers = { writefile, syn and syn.writefile }
    for _, writer in ipairs(writers) do
        if type(writer) == "function" then
            local ok = pcall(writer, Loader.KeyFile, key)
            if ok then return true end
        end
    end
    return false
end

-- ── key menu: type the key once, it is remembered ──────────────────────────
local function showKeyMenu(reason, onSubmit)
    local players = game:GetService("Players")
    local player = players.LocalPlayer
    local guiParent = player and (player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10))
    if not guiParent then
        print("[Skill Hub] " .. reason .. " — и окно ввода показать не удалось (нет PlayerGui)")
        return
    end
    local old = guiParent:FindFirstChild("SkillHubKeyGate")
    if old then old:Destroy() end

    local screen = Instance.new("ScreenGui")
    screen.Name = "SkillHubKeyGate"
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 2147483647
    screen.IgnoreGuiInset = true
    screen.Parent = guiParent

    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(0, 384, 0, 208)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundColor3 = rgb(5, 6, 8)
    shadow.BackgroundTransparency = 0.35
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 1
    shadow.Parent = screen
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 22)
    shadowCorner.Parent = shadow

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 384, 0, 208)
    card.Position = UDim2.new(0.5, 0, 0.5, -2)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = rgb(20, 22, 27)
    card.BorderSizePixel = 0
    card.ZIndex = 2
    card.Parent = screen
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 20)
    cardCorner.Parent = card
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = rgb(46, 51, 61)
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 4, 0, 46)
    accent.Position = UDim2.new(0, 22, 0, 26)
    accent.BackgroundColor3 = rgb(126, 141, 255)
    accent.BorderSizePixel = 0
    accent.ZIndex = 3
    accent.Parent = card
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(1, 0)
    accentCorner.Parent = accent

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 0, 26)
    title.Position = UDim2.new(0, 38, 0, 24)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 19
    title.TextColor3 = rgb(233, 235, 240)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = Loader.Title
    title.ZIndex = 3
    title.Parent = card

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -60, 0, 16)
    subtitle.Position = UDim2.new(0, 38, 0, 50)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 13
    subtitle.TextColor3 = rgb(150, 156, 172)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = Loader.Subtitle
    subtitle.ZIndex = 3
    subtitle.Parent = card

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -44, 0, 44)
    box.Position = UDim2.new(0, 22, 0, 84)
    box.BackgroundColor3 = rgb(12, 14, 18)
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 15
    box.TextColor3 = rgb(233, 235, 240)
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.PlaceholderText = Loader.Placeholder
    box.PlaceholderColor3 = rgb(96, 102, 116)
    box.Text = ""
    box.ZIndex = 3
    box.Parent = card
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 12)
    boxCorner.Parent = box
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = rgb(46, 51, 61)
    boxStroke.Thickness = 1
    boxStroke.Parent = box
    local boxPad = Instance.new("UIPadding")
    boxPad.PaddingLeft = UDim.new(0, 14)
    boxPad.PaddingRight = UDim.new(0, 14)
    boxPad.Parent = box

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -44, 0, 44)
    button.Position = UDim2.new(0, 22, 0, 138)
    button.BackgroundColor3 = rgb(126, 141, 255)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextSize = 15
    button.TextColor3 = rgb(13, 14, 17)
    button.Text = "ВОЙТИ"
    button.AutoButtonColor = false
    button.ZIndex = 3
    button.Parent = card
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 12)
    buttonCorner.Parent = button

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -44, 0, 16)
    status.Position = UDim2.new(0, 22, 0, 186)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 12
    status.TextColor3 = rgb(150, 156, 172)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Text = reason .. " · Enter — подтвердить, ключ сохранится на этом устройстве"
    status.ZIndex = 3
    status.Parent = card

    local busy = false
    local function submit()
        if busy then return end
        local key = string.gsub(box.Text or "", "^%s+", "")
        key = string.gsub(key, "%s+$", "")
        if #key == 0 then
            status.TextColor3 = rgb(226, 132, 122)
            status.Text = "Введите ключ"
            return
        end
        busy = true
        status.TextColor3 = rgb(150, 156, 172)
        status.Text = "Проверяю ключ…"
        local ok, err = pcall(onSubmit, key, function(message, colour)
            busy = false
            status.TextColor3 = colour or rgb(226, 132, 122)
            status.Text = message
        end)
        if not ok then
            busy = false
            status.TextColor3 = rgb(226, 132, 122)
            status.Text = "Ошибка: " .. tostring(err)
        end
    end

    button.MouseEnter:Connect(function() button.BackgroundColor3 = rgb(150, 162, 255) end)
    button.MouseLeave:Connect(function() button.BackgroundColor3 = rgb(126, 141, 255) end)
    button.Activated:Connect(submit)
    box.FocusLost:Connect(function(enterPressed) if enterPressed then submit() end end)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if boxStroke.Color ~= rgb(46, 51, 61) then boxStroke.Color = rgb(46, 51, 61) end
    end)
    task.defer(function()
        if box and box.Parent then
            pcall(function() box:CaptureFocus() end)
        end
    end)
end

local function closeKeyMenu()
    local players = game:GetService("Players")
    local player = players.LocalPlayer
    local guiParent = player and player:FindFirstChildOfClass("PlayerGui")
    local menu = guiParent and guiParent:FindFirstChild("SkillHubKeyGate")
    if menu then menu:Destroy() end
end

-- ── boot the hub once the payload is unlocked ──────────────────────────────
local function boot(inner, key)
    local payloadHash = hash32(inner)
    print(string.format("[Skill Hub] %s · unlocked %d bytes · hash %s · key %s",
        tostring(Loader.Build), #inner, payloadHash, hash32(key)))

    if type(Loader.ExpectedHash) == "string" and Loader.ExpectedHash ~= "" and Loader.ExpectedHash ~= "00000000"
        and payloadHash ~= Loader.ExpectedHash then
        print("[Skill Hub] CHECKSUM MISMATCH — refusing to run a modified build")
        print(string.format("    expected %s · received %s", tostring(Loader.ExpectedHash), payloadHash))
        return false
    end

    local previous = SharedEnv.SkillHubInstance
    if previous and type(previous.unload) == "function" then
        pcall(previous.unload)
    end

    local compiler = loadstring or load
    local chunk, compileError = compiler(inner)
    if not chunk then
        print("[Skill Hub] the payload did not compile: " .. tostring(compileError))
        return false
    end

    local ok, err = pcall(chunk)
    if not ok then
        print("[Skill Hub] the hub raised an error while booting: " .. tostring(err))
        return false
    end
    return true
end

-- ── main flow ──────────────────────────────────────────────────────────────
local source = fetch(Loader.Payload)
if not source then
    print("[Skill Hub] couldn't download the build (проверь HttpGet / интернет)")
    return
end

local body = string.match(source, "^[^\n]*\n(.*)$") or source
body = string.gsub(body, "%s+", "")
source = nil

local function tryKey(key)
    if type(key) ~= "string" or #key == 0 then return nil end
    local inner = unlock(body, key)
    if inner and #inner > 32 and string.sub(inner, 1, 9) == "local __S" then return inner end
    return nil
end

-- note: `type(...)` would itself error when the loader is called with no
-- argument at all (`loadstring(...)()`), so the varargs are read first.
local firstArg = ...
local key = nil
if type(firstArg) == "string" and #firstArg > 0 then
    key = firstArg
elseif type(Loader.Key) == "string" and #Loader.Key > 0 then
    key = Loader.Key
else
    key = readKeyFile() or readClipboard()
end

if key then
    local inner = tryKey(key)
    if inner and boot(inner, key) then
        return
    end
end

local reason = key and "Неверный ключ" or "Ключ нужен для запуска"

local function attempt(candidate, reportError)
    local inner = tryKey(candidate)
    if not inner then
        reportError("Неверный ключ — попробуй ещё раз")
        return
    end
    if not saveKey(candidate) then
        print("[Skill Hub] ключ не сохранён (writefile недоступен) — окно закроется, хаб запустится")
    end
    closeKeyMenu()
    if not boot(inner, candidate) then
        showKeyMenu("Ключ принят, но запуск сорвался — смотри консоль", attempt)
    end
end

showKeyMenu(reason, attempt)
