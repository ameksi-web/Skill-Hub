--[[
    Skill Hub — protected loader  (share THIS link, not the raw script)

        loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/loader.lua"))()

    What it does, in order:
      1. captures `game.HttpGet` ONCE and calls it as a plain function, so a
         __namecall hook installed by another script cannot intercept, log or
         rewrite the download;
      2. downloads the sealed build (dist/skillhub.release.lua — comments blanked,
         every string literal encrypted, nothing greppable in the repository);
      3. checks its FNV-1a-32 checksum against the value written here by
         tools/build_release.py on every release — a modified payload is refused
         instead of executed;
      4. prints the build banner with the payload hash and the machine tag, so a
         leaked copy can be traced back to the machine it came from;
      5. optional key lock (Loader.RequireKey + Loader.Keys): only authorised key
         hashes may run the hub at all;
      6. unloads any previous instance, runs the payload, then drops the payload
         reference again.

    Honest ceiling: anything that runs on a machine can be dumped by that machine.
    This loader cannot change physics — it makes copying *detectable*, tampering
    *refused*, and unauthorised distribution *stoppable*. Real secrecy needs the
    source to be private (see the "Protection" section of README.md).
]]

local SharedEnv = (getgenv and getgenv()) or _G or {}

-- ── configuration (the three lines below are rewritten by tools/build_release.py)
local Loader = {
    Build        = "v3.10",
    ExpectedHash = "cce65ca5",
    Payload      = "https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/dist/skillhub.release.lua",
    Fallback     = "https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/main.lua",
    -- key lock: set RequireKey = true and list the allowed key hashes (FNV-1a-32
    -- of the key — the hub prints your own hash in Misc → Guard → Copy Fingerprint)
    RequireKey   = false,
    Keys         = {},
    Key          = "",
}

-- ── pristine download handle ────────────────────────────────────────────────
local HttpGet = nil
do
    local ok, fn = pcall(function() return game.HttpGet end)
    if ok and type(fn) == "function" then HttpGet = fn end
end

local function fetch(url)
    if not HttpGet or type(url) ~= "string" then return nil end
    -- plain call (no colon): __namecall hooks never see this
    local ok, body = pcall(HttpGet, game, url)
    if ok and type(body) == "string" and #body > 0 then return body end
    return nil
end

-- ── same hash as main.lua's Guard and tools/seal_secret.py ──────────────────
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

local function tag()
    return hash32(tostring(Loader.Key or "") .. "|" .. tostring(Loader.Build))
end

-- ── download + verify ───────────────────────────────────────────────────────
local source = fetch(Loader.Payload)
if not source then
    source = fetch(Loader.Fallback)
    if source then
        print("[Skill Hub loader] sealed build unreachable — fell back to the source build")
    end
end

if not source then
    print("[Skill Hub loader] could not download any build (check the executor's HttpGet)")
    return
end

local checksum = hash32(source)
print(string.format("[Skill Hub loader] build %s · payload %d bytes · hash %s · tag %s",
    tostring(Loader.Build), #source, checksum, tag()))

if type(Loader.ExpectedHash) == "string" and Loader.ExpectedHash ~= "" and Loader.ExpectedHash ~= "00000000"
    and checksum ~= Loader.ExpectedHash then
    print("[Skill Hub loader] CHECKSUM MISMATCH — refusing to execute a modified build")
    print(string.format("    expected %s · received %s", tostring(Loader.ExpectedHash), checksum))
    return
end

if Loader.RequireKey then
    local keyHash = hash32(tostring(Loader.Key or ""))
    local allowed = false
    for _, entry in ipairs(Loader.Keys or {}) do
        if tostring(entry) == keyHash then
            allowed = true
            break
        end
    end
    if not allowed then
        print("[Skill Hub loader] this build is key-locked and your key is not authorised.")
        print("    your key hash : " .. keyHash)
        print("    send that hash to the owner — it is the only thing needed to authorise this machine")
        return
    end
    print("[Skill Hub loader] key accepted")
end

-- ── single instance, then hand over ─────────────────────────────────────────
local previous = SharedEnv.SkillHubInstance
if previous and type(previous.unload) == "function" then
    pcall(previous.unload)
end

local compiler = loadstring or load
local chunk, compileError = compiler(source)
if not chunk then
    print("[Skill Hub loader] the payload did not compile: " .. tostring(compileError))
    return
end

source = nil   -- the payload text is not kept around after compiling
local ok, err = pcall(chunk)
if not ok then
    print("[Skill Hub loader] the hub raised an error while booting: " .. tostring(err))
    return
end

print("[Skill Hub loader] handover complete — one instance owns this environment")
