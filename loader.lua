--[[
    Skill Hub — protected loader  (the only link that is handed out)

        loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/loader.lua"))("<your-private-key>")

    The build it downloads is LOCKED: the file published in the repository is not
    Lua at all, it is a hex blob XOR-ed against a stream whose seed changes every
    16 bytes and comes from your key. Without the key it decrypts to noise — no
    source, no strings, no comments, nothing to copy or read.

    Flow:  key (argument → local key file → Loader.Key)
           → download the locked blob
           → unlock it with the key
           → verify the FNV-1a-32 checksum pinned in this file (a modified build is
             refused instead of executed)
           → print the build banner with the payload hash and the machine tag
           → unload any previous instance, run the payload, drop the payload text

    Honest ceiling: whoever holds the key can read what runs. That is exactly how
    access works here — hand out the key only to people you authorise, and rotate
    it (tools/build_release.py --pass "<new key>") the moment it leaks.
]]

local SharedEnv = (getgenv and getgenv()) or _G or {}

-- ── configuration (these lines are rewritten by tools/build_release.py) ─────
local Loader = {
    Build        = "v3.10",
    ExpectedHash = "cce65ca5",
    Payload      = "https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/release/skillhub.release.lua",
    KeyFile      = "skillhub.key",
    Key          = "",      -- leave empty: pass the key to the loader instead
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

-- ── unlock: the key is the access control ───────────────────────────────────
-- Every 16-byte block uses its own seed = hash32(key .. ":" .. offset), so the
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

-- ── the key: argument → local key file → Loader.Key ─────────────────────────
local function localKey()
    local readers = { readfile, syn and syn.readfile, isfile and function(name) return readfile and readfile(name) end }
    for _, reader in ipairs(readers) do
        if type(reader) == "function" then
            local ok, text = pcall(reader, Loader.KeyFile)
            if ok and type(text) == "string" and #text > 0 then return (string.gsub(text, "%s+$", "")) end
        end
    end
    return nil
end

local Key = nil
if type(...) == "string" and #(...) > 0 then
    Key = (...)
elseif type(Loader.Key) == "string" and #Loader.Key > 0 then
    Key = Loader.Key
else
    Key = localKey()
end

if not Key or #Key == 0 then
    print("[Skill Hub loader] this build is LOCKED — a key is required.")
    print("    pass it with the loadstring, exactly like this:")
    print("    loadstring(game:HttpGet(\"https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/loader.lua\"))(\"<your key>\")")
    print("    …or create the key file once, so you never paste it again:")
    print("    writefile(\"" .. Loader.KeyFile .. "\", \"<your key>\")")
    return
end

-- ── download, unlock, verify ────────────────────────────────────────────────
local source = fetch(Loader.Payload)
if not source then
    print("[Skill Hub loader] could not download the locked build (check the executor's HttpGet)")
    return
end

local header, body = string.match(source, "^([^\n]*)\n(.*)$")
if not body then
    body = source
    header = ""
end
body = string.gsub(body, "%s+", "")

local inner = unlock(body, Key)
if not inner or string.sub(inner, 1, 9) ~= "local __S" then
    print("[Skill Hub loader] WRONG KEY — the build did not unlock with this key (nothing was executed)")
    print("    your key hash : " .. hash32(Key) .. "   · send it to the owner only if you were meant to have access")
    return
end

local payloadHash = hash32(inner)
print(string.format("[Skill Hub loader] %s · unlocked %d bytes · hash %s · key %s",
    tostring(Loader.Build), #inner, payloadHash, hash32(Key)))

if type(Loader.ExpectedHash) == "string" and Loader.ExpectedHash ~= "" and Loader.ExpectedHash ~= "00000000"
    and payloadHash ~= Loader.ExpectedHash then
    print("[Skill Hub loader] CHECKSUM MISMATCH — refusing to execute a modified build")
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
inner = nil
if not chunk then
    print("[Skill Hub loader] the payload did not compile: " .. tostring(compileError))
    return
end

local ok, err = pcall(chunk)
if not ok then
    print("[Skill Hub loader] the hub raised an error while booting: " .. tostring(err))
    return
end

print("[Skill Hub loader] handover complete — one instance owns this environment")
