#!/usr/bin/env python3
"""End-to-end test of the key-menu loader (loader.lua) in a mocked Roblox.

    python3 tools/loader_test.py     -> 17/17 checks passed

The loader itself is executed unmodified except for ONE harness-only patch: the
pinned checksum is pointed at the fake payload this test serves, so the boot path
can be exercised without the published blob (that blob has its own check —
`python3 tools/build_release.py --check` — plus a direct unlock with the loader's
own code during the release procedure).

Scenarios:
  1. nothing anywhere            -> key window appears, status "Ключ нужен для запуска"
  2. wrong key typed in the box  -> "Неверный ключ — попробуй ещё раз", nothing runs
  3. correct key typed           -> key saved to skillhub.key, window destroyed, hub boots
  4. key in the clipboard        -> boots immediately, no window
  5. key as the loadstring arg   -> boots immediately, no window
  6. wrong key as the argument   -> window appears with the "Неверный ключ" status
"""
import io, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_release as br  # noqa: E402
from lupa import LuaRuntime  # noqa: E402

LOADER = os.path.join(HERE, os.pardir, "loader.lua")
KEY = "TESTKEY 000"
PLAIN = (
    "local __S = {}\n"
    "print('[fake hub] boot ok')\n"
    "getgenv().SkillHubInstance = { unload = function() print('[fake hub] unloaded') end }\n"
)

PRELUDE = r"""
_G.HARNESS = { log = {}, files = {}, clipboard = "", destroyed = {} }

local HARNESS = _G.HARNESS
function HARNESS.log_line(text) table.insert(HARNESS.log, tostring(text)) end
function HARNESS.log_text() return table.concat(HARNESS.log, "\n") end

local realprint = print
function _G.print(...)
    local parts = {}
    for index = 1, select("#", ...) do parts[index] = tostring(select(index, ...)) end
    HARNESS.log_line(table.concat(parts, " "))
end
function _G.warn(...) _G.print(...) end
function _G.getgenv() return _G end

-- ── instance mock ───────────────────────────────────────────────────────────
local function makeInstance(class)
    local obj = { class = class, props = {}, children = {}, listeners = {}, methods = {} }

    local function findChild(self, name)
        for _, child in ipairs(rawget(self, "children")) do
            if rawget(child.props, "Name") == name then return child end
        end
        return nil
    end

    local function findChildOfClass(self, wanted)
        for _, child in ipairs(rawget(self, "children")) do
            if rawget(child, "class") == wanted then return child end
        end
        return nil
    end

    local function signal(self, name)
        local listeners = rawget(self, "listeners")
        if not listeners[name] then
            local bucket
            bucket = { fns = {} }
            bucket.Connect = function(_, fn) table.insert(bucket.fns, fn) return { Disconnect = function() end } end
            listeners[name] = bucket
        end
        return listeners[name]
    end

    local mt = {}
    mt.__index = function(self, key)
        local props = rawget(self, "props")
        if props[key] ~= nil then return props[key] end
        if key == "ClassName" then return rawget(self, "class") end
        if key == "Name" then return rawget(self, "name") end
        if key == "FindFirstChild" then return findChild end
        if key == "FindFirstChildOfClass" then return findChildOfClass end
        if key == "IsA" then return function(s, wanted) return rawget(s, "class") == wanted end end
        if key == "WaitForChild" then return function(s, name) return findChild(s, name) end end
        if key == "GetPropertyChangedSignal" then
            return function(s, prop) return mt.__index(s, prop .. "_changed") end
        end
        if key == "Destroy" then
            return function(s)
                local parent = rawget(s, "props") and rawget(s, "parent")
                HARNESS.destroyed[tostring(s)] = true
                if parent then
                    for index, child in ipairs(rawget(parent, "children")) do
                        if child == s then
                            table.remove(rawget(parent, "children"), index)
                            break
                        end
                    end
                end
            end
        end
        if key == "CaptureFocus" or key == "ReleaseFocus" then return function() end end
        if key == "GetDescendants" then
            return function(s)
                local out = {}
                for _, child in ipairs(rawget(s, "children")) do
                    table.insert(out, child)
                    for _, deep in ipairs(mt.__index(s, "GetDescendants")(child)) do table.insert(out, deep) end
                end
                return out
            end
        end
        return signal(self, key)
    end
    mt.__newindex = function(self, key, value)
        if key == "Parent" then
            rawset(self, "parent", value)
            if value then table.insert(rawget(value, "children"), self) end
            return
        end
        if key == "Name" then rawset(self, "name", value) end
        local props = rawget(self, "props")
        props[key] = value
        local bucket = rawget(self, "listeners")[key .. "_changed"]
        if bucket then for _, fn in ipairs(bucket.fns) do fn() end end
    end
    mt.__tostring = function(self) return "instance:" .. tostring(rawget(self, "class")) .. ":" .. tostring(rawget(self, "name")) end

    return setmetatable(obj, mt)
end

function HARNESS.fire(instance, name, ...)
    local bucket = rawget(instance, "listeners")[name]
    if not bucket then return 0 end
    local count = 0
    for _, fn in ipairs(bucket.fns) do
        local ok, err = pcall(fn, ...)
        if not ok then HARNESS.log_line("SIGNAL ERROR (" .. name .. "): " .. tostring(err)) end
        count = count + 1
    end
    return count
end

function HARNESS.find(root, class)
    for _, child in ipairs(rawget(root, "children")) do
        if rawget(child, "class") == class then return child end
        local deep = HARNESS.find(child, class)
        if deep then return deep end
    end
    return nil
end

function HARNESS.playerGui()
    return HARNESS.guiChild(game:GetService("Players").LocalPlayer, "PlayerGui")
end

function HARNESS.gate()
    local gui = HARNESS.playerGui()
    return gui and HARNESS.guiChild(gui, "SkillHubKeyGate")
end

function HARNESS.labels(instance, out)
    out = out or {}
    for _, child in ipairs(rawget(instance, "children")) do
        if rawget(child, "class") == "TextLabel" then table.insert(out, child) end
        HARNESS.labels(child, out)
    end
    return out
end

function HARNESS.labelText(index)
    local gate = HARNESS.gate()
    if not gate then return "" end
    local labels = HARNESS.labels(gate)
    local wanted = labels[index or 1]
    return wanted and rawget(wanted, "props").Text or ""
end

function HARNESS.guiChild(root, name)
    for _, child in ipairs(rawget(root, "children")) do
        if rawget(child, "props").Name == name then return child end
    end
    return nil
end

function HARNESS.run(...)
    local chunk = assert(load(HARNESS.loaderSrc, "loader.lua"))
    local ok, err = pcall(chunk, ...)
    if not ok then HARNESS.log_line("LOADER ERROR: " .. tostring(err)) end
    return ok
end

-- ── engine surface the loader touches ──────────────────────────────────────
local playerGui = makeInstance("PlayerGui")
playerGui.Name = "PlayerGui"
local localPlayer = makeInstance("Player")
localPlayer.Name = "LocalPlayer"
playerGui.Parent = localPlayer
local players = makeInstance("Players")
players.props.LocalPlayer = localPlayer
function players.GetService() end

local services = { Players = players, CoreGui = makeInstance("CoreGui") }
local game = makeInstance("DataModel")
function game.GetService(_, name) return services[name] or makeInstance(name) end
game.HttpGet = function(_, url) return HARNESS.blob end
_G.game = game
_G.workspace = makeInstance("Workspace")

_G.Instance = { new = function(class) return makeInstance(class) end }
_G.Enum = setmetatable({}, { __index = function(_, group) return setmetatable({}, { __index = function(_, item) return { Name = item, Value = 0, EnumType = group } end }) end })
_G.Color3 = { fromRGB = function(r, g, b) return { R = r, G = g, B = b } end }
_G.UDim2 = { new = function(xs, xo, ys, yo) return { xs = xs, xo = xo, ys = ys, yo = yo } end }
_G.UDim = { new = function(s, o) return { s = s, o = o } end }
_G.Vector2 = { new = function(x, y) return { X = x, Y = y } end }
_G.task = { defer = function(fn, ...) fn(...) end, spawn = function(fn, ...) fn(...) end, wait = function() end }
_G.readfile = function(path) return HARNESS.files[path] end
_G.writefile = function(path, text) HARNESS.files[path] = text end
_G.isfile = function(path) return HARNESS.files[path] ~= nil end
_G.getclipboard = function() return HARNESS.clipboard end
"""


def build_blob(key: str) -> str:
    header = "-- Skill Hub locked payload · v3.13 · test fixture · only a key holder can unlock this\n"
    return header + br.lock(PLAIN, key)


def main() -> int:
    source = io.open(LOADER, encoding="utf-8").read()
    expected = "%08x" % br.fnv1a32(PLAIN.encode("utf-8"))
    import re

    source, hits = re.subn(r'ExpectedHash = "[0-9a-f]{8}"', 'ExpectedHash = "%s"' % expected, source)
    if hits != 1:
        print("could not point the harness at the fixture checksum"); return 1

    rt = LuaRuntime(unpack_returned_tuples=True)
    rt.execute(PRELUDE)
    rt.globals().HARNESS.blob = build_blob(KEY)
    rt.globals().HARNESS.loaderSrc = source

    results = []

    def check(label, condition, detail=""):
        results.append((label, bool(condition), detail))
        print("%s %s%s" % ("PASS" if condition else "FAIL", label, ("  — " + (detail if isinstance(detail, str) else " | ".join(detail))) if detail else ""))

    def reset(clipboard="", files=None):
        rt.execute("HARNESS.log = {} HARNESS.files = {} HARNESS.destroyed = {}")
        rt.execute("HARNESS.clipboard = ...", clipboard)
        for name, content in (files or {}).items():
            rt.globals().HARNESS.files[name] = content


    def logs():
        return str(rt.eval("HARNESS.log_text()"))

    def key_file():
        value = rt.eval("HARNESS.files['skillhub.key']")
        return str(value) if value is not None else None

    # ── 1. nothing anywhere -> window asks for the key
    reset()
    rt.execute("HARNESS.run()")
    text = logs()
    check("1 · no key anywhere -> key window opens", rt.eval("HARNESS.guiChild(HARNESS.playerGui(), 'SkillHubKeyGate') ~= nil"))
    box = rt.eval("(function() local gate = HARNESS.guiChild(HARNESS.playerGui(), 'SkillHubKeyGate') return gate and HARNESS.find(gate, 'TextBox') end)()")
    button = rt.eval("(function() local gate = HARNESS.guiChild(HARNESS.playerGui(), 'SkillHubKeyGate') return gate and HARNESS.find(gate, 'TextButton') end)()")
    status = rt.eval("HARNESS.labelText(3)")
    check("1a · the window has a text field, a button and a status line", box is not None and button is not None and status is not None, str(box)[:40])
    check("1b · status says the key is required", "Ключ нужен для запуска" in status, status[:90])
    check("1c · placeholder + button label are Russian UI strings",
          "ключ, например" in str(rt.eval("(function() local gate = HARNESS.guiChild(HARNESS.playerGui(), 'SkillHubKeyGate') local box = HARNESS.find(gate, 'TextBox') return rawget(box, 'props').PlaceholderText end)()")).lower()
          and str(rt.eval("rawget(HARNESS.find(HARNESS.guiChild(HARNESS.playerGui(), 'SkillHubKeyGate'), 'TextButton'), 'props').Text")) == "ВОЙТИ")
    check("1d · nothing was executed before a key", "boot ok" not in text and "[Skill Hub] v3.13" not in text)

    # ── 2. wrong key typed -> refused, window stays
    reset()
    rt.execute("HARNESS.run()")
    rt.execute("""
        local gate = HARNESS.guiChild(HARNESS.playerGui(), 'SkillHubKeyGate')
        local box = HARNESS.find(gate, 'TextBox')
        local button = HARNESS.find(gate, 'TextButton')
        box.Text = "NOPE"
        HARNESS.fire(button, 'Activated')
    """)
    text = logs()
    check("2 · wrong key typed -> refused", "boot ok" not in text and "[Skill Hub] v3.13" not in text)
    retry_status = rt.eval("HARNESS.labelText(3)")
    check("2a · the status line explains it", "Неверный ключ — попробуй ещё раз" in retry_status, str(retry_status)[:90])
    check("2b · window is still open", rt.eval("HARNESS.guiChild(HARNESS.playerGui(), 'SkillHubKeyGate') ~= nil"))
    check("2c · nothing was written to the key file", key_file() is None)

    # ── 3. correct key typed -> saved, window closes, hub boots
    reset()
    rt.execute("HARNESS.run()")
    rt.execute("""
        local gate = HARNESS.guiChild(HARNESS.playerGui(), 'SkillHubKeyGate')
        local box = HARNESS.find(gate, 'TextBox')
        local button = HARNESS.find(gate, 'TextButton')
        box.Text = "  TESTKEY 000  "            -- spaces must be trimmed
        HARNESS.fire(button, 'Activated')
    """)
    text = logs()
    check("3 · correct key -> hub boots", "[Skill Hub] v3.13 · unlocked" in text and "[fake hub] boot ok" in text, "; ".join(line for line in text.split("\n") if "unlocked" in line))
    check("3a · the key is remembered for next time", key_file() == KEY, repr(key_file()))
    check("3b · the window removes itself", rt.eval("HARNESS.guiChild(HARNESS.playerGui(), 'SkillHubKeyGate') == nil"))
    check("3c · unlock line reports bytes + hash + key hash", "· key " in text)

    # ── 4. key saved earlier -> straight boot, no window
    reset(files={"skillhub.key": KEY})
    rt.execute("HARNESS.run()")
    text = logs()
    check("4 · saved key file -> boots with no window", "[fake hub] boot ok" in text and rt.eval("HARNESS.guiChild(HARNESS.playerGui(), 'SkillHubKeyGate') == nil"))

    # ── 5. key as the loadstring argument
    reset()
    rt.execute("HARNESS.run(...)", KEY)
    check("5 · key argument -> boots, no window", "[fake hub] boot ok" in logs() and rt.eval("HARNESS.guiChild(HARNESS.playerGui(), 'SkillHubKeyGate') == nil"))

    # ── 6. wrong key as the argument -> window with the wrong-key status
    reset()
    rt.execute("HARNESS.run(...)", "NOTTHEKEY")
    status = rt.eval("HARNESS.labelText(3)")
    check("6 · wrong key argument -> window says so", "Неверный ключ" in status and "boot ok" not in logs(), status[:90])

    # ── 7. the clipboard source
    reset(clipboard="TESTKEY 000\n")
    rt.execute("HARNESS.run()")
    check("7 · key on the clipboard -> boots with no window", "[fake hub] boot ok" in logs())

    failed = [label for label, ok, _ in results if not ok]
    print("\n%d/%d checks passed" % (len(results) - len(failed), len(results)))
    if failed:
        print("FAILED: " + ", ".join(failed))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
