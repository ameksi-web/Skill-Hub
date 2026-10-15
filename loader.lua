--[[
    Skill Hub — PUBLIC loader  (this is the link to share with everybody)

        loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/loader.lua"))()

    No key, no arguments — paste and play. What it does:

      1. captures `game.HttpGet` once and calls it as a plain function, so a
         __namecall hook installed by another script cannot intercept, log or
         rewrite the download;
      2. downloads the sealed build (`release/skillhub.public.lua`): comments are
         blanked and every string literal is encrypted, so copying the file gives
         nobody the source — the readable source is not in this repository at all;
      3. verifies the FNV-1a-32 checksum pinned below — a modified payload is
         refused instead of executed;
      4. prints the build banner with the payload hash, then unloads any previous
         instance, runs the hub and drops the payload text again.

    Want access limited to specific people instead of everybody? Use
    `loader-key.lua` — same idea, but the build is locked and only a key holder
    can unlock it (see the "Protection" section of README.md).

    Honest note: whoever runs a client-side script can dump what runs on their own
    machine — that is why the source here is shipped sealed and stays private, and
    why the interface prints the author credit of this build.
]]

local SharedEnv = (getgenv and getgenv()) or _G or {}

-- ── configuration (rewritten by tools/build_release.py on every release) ────
local Loader = {
    Build        = "v3.12",
    ExpectedHash = "bc3eefe5",
    Payload      = "https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/release/skillhub.public.lua",
    Author       = "ameksi-web",
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

-- ── download + verify ───────────────────────────────────────────────────────
local source = fetch(Loader.Payload)
if not source then
    print("[Skill Hub loader] could not download the build (check the executor's HttpGet / your connection)")
    return
end

local payloadHash = hash32(source)
print(string.format("[Skill Hub loader] PUBLIC build %s by %s · payload %d bytes · hash %s",
    tostring(Loader.Build), tostring(Loader.Author), #source, payloadHash))

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
local chunk, compileError = compiler(source)
source = nil   -- the payload text is not kept around after compiling
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
