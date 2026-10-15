--[[
    Skill Hub — CLOSED build loader (key required)

        loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/loader.lua"))("<key>")

    The build is closed: `release/skillhub.release.lua` in the repository is not Lua
    at all — it is a hex blob XOR-ed against a stream whose seed changes every 16
    bytes and is derived from the key. Without the key it decrypts to noise: no
    source, no strings, no comments, nothing to copy or read.

    Key sources, in order (the first one found wins):
      1. the argument you pass to the loader          loadstring(...)("<key>")
      2. the file `skillhub.key` in the executor's workspace:
             writefile("skillhub.key", "<key>")
      3. Loader.Key below (leave empty — never publish a key in this file)
      4. whatever is in your clipboard — copy the key, then just run the loader

    Publishing a new update = handing out a new key:
        python3 tools/build_release.py --pass "<new key>"
    Old keys stop working immediately (the blob is re-locked), which is exactly how
    access is revoked.
]]

local SharedEnv = (getgenv and getgenv()) or _G or {}

-- ── configuration (Build + ExpectedHash are rewritten by tools/build_release.py)
local Loader = {
    Build        = "v3.12",
    ExpectedHash = "bc3eefe5",
    Payload      = "https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/release/skillhub.release.lua",
    KeyFile      = "skillhub.key",
    Key          = "",                       -- leave empty on purpose
    KeyHint      = "the current key is published with the latest update",
}

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
-- Every 16-byte block gets its own seed = hash32(key .. ":" .. offset), so the
-- stream never repeats and knowing one block tells nothing about the others.
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

-- ── the key: argument → key file → Loader.Key → clipboard ───────────────────
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

local Key, keySource = nil, "none"
if type(...) == "string" and #(...) > 0 then
    Key, keySource = (...), "argument"
elseif type(Loader.Key) == "string" and #Loader.Key > 0 then
    Key, keySource = Loader.Key, "Loader.Key"
else
    Key = readKeyFile()
    if Key then keySource = "skillhub.key" end
    if not Key then
        Key = readClipboard()
        if Key then keySource = "clipboard" end
    end
end

if not Key or #Key == 0 then
    print("[Skill Hub] this build is CLOSED — a key is required.")
    print("    " .. tostring(Loader.KeyHint))
    print("    paste it with the loader:")
    print("    loadstring(game:HttpGet(\"https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/loader.lua\"))(\"<key>\")")
    print("    …or copy the key and run the loader again (the clipboard is read automatically),")
    print("    …or save it once so you never paste it again:  writefile(\"" .. Loader.KeyFile .. "\", \"<key>\")")
    return
end

-- ── download, unlock, verify ────────────────────────────────────────────────
local source = fetch(Loader.Payload)
if not source then
    print("[Skill Hub] could not download the build (check the executor's HttpGet / your connection)")
    return
end

local body = string.match(source, "^[^\n]*\n(.*)$") or source
body = string.gsub(body, "%s+", "")

local inner = unlock(body, Key)
if not inner or string.sub(inner, 1, 9) ~= "local __S" then
    print("[Skill Hub] WRONG KEY — this build did not unlock (nothing was executed)")
    print("    key from " .. keySource .. " · its hash is " .. hash32(Key))
    print("    " .. tostring(Loader.KeyHint))
    return
end

local payloadHash = hash32(inner)
print(string.format("[Skill Hub] %s · unlocked %d bytes · hash %s · key %s (from %s)",
    tostring(Loader.Build), #inner, payloadHash, hash32(Key), keySource))

if type(Loader.ExpectedHash) == "string" and Loader.ExpectedHash ~= "" and Loader.ExpectedHash ~= "00000000"
    and payloadHash ~= Loader.ExpectedHash then
    print("[Skill Hub] CHECKSUM MISMATCH — refusing to run a modified build")
    print(string.format("    expected %s · received %s", tostring(Loader.ExpectedHash), payloadHash))
    return
end

-- ── single instance, then hand over ─────────────────────────────────────────
local previous = SharedEnv.SkillHubInstance
if previous and type(previous.unload) == "function" then
    pcall(previous.unload)
end

local compiler = loadstring or load
local chunk, compileError = compiler(inner)
inner = nil    -- the payload text is not kept around after compiling
if not chunk then
    print("[Skill Hub] the payload did not compile: " .. tostring(compileError))
    return
end

local ok, err = pcall(chunk)
if not ok then
    print("[Skill Hub] the hub raised an error while booting: " .. tostring(err))
    return
end

print("[Skill Hub] handover complete — one instance owns this environment")
