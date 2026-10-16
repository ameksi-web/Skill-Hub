#!/usr/bin/env python3
"""Budget guard for the Jujutsu Shenanigans hub: it may not get slow again.

    /tmp/venv/bin/python tools/perf_test.py [--seconds 22]

Boots the hub in the same mocked Roblox as tools/jjs_test.py, switches every
toggle on, and counts the engine calls the hub makes per virtual second
(GetDescendants / GetChildren / FindFirstChild / FindFirstChildOfClass /
FindFirstChildWhichIsA / IsA / Instance.new). Those calls are the traffic that
stalls a real client, and the rewrite in this branch cut them by ~3.4x.

The budgets below are roughly twice the numbers this build actually produced,
so ordinary jitter passes and a regression to the old per-frame style fails
loudly. The counters live in the mock only — the hub is not instrumented.
"""
import io, os, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
HUB = os.path.join(HERE, os.pardir, "Jujutsu Shenanigans", "SkillHub.lua")

try:
    from lupa import LuaRuntime
except ImportError:
    print("this test needs lupa and a Lua runtime:")
    print("    python3 -m venv /tmp/venv && /tmp/venv/bin/pip install lupa")
    sys.exit(2)

SECONDS = 22
arguments = sys.argv[1:]
if "--seconds" in arguments:
    index = arguments.index("--seconds")
    try:
        SECONDS = max(5, int(arguments[index + 1]))
    except (IndexError, ValueError):
        print("--seconds wants a number")
        sys.exit(2)

# one virtual second of engine traffic, measured on this build
BUDGET = {
    "GetDescendants": 60,
    "GetChildren": 40,
    "FindFirstChild": 90,
    "FindFirstChildOfClass": 90,
    "FindFirstChildWhichIsA": 30,
    "IsA": 90,
    "Instance.new": 30,          # steady state: the window is built once at load
}
TOTAL_BUDGET = 700               # per virtual second, everything together

src = io.open(os.path.join(HERE, "jjs_test.py"), encoding="utf-8").read()
PRELUDE = src.split('PRELUDE = r"""', 1)[1].split('\n"""', 1)[0]

INSTRUMENT = """
_G.__COUNT = {}
local function bump(key)
    _G.__COUNT[key] = (_G.__COUNT[key] or 0) + 1
end
local function wrap(name)
    local original = METHODS[name]
    if not original then return end
    METHODS[name] = function(...)
        bump(name)
        return original(...)
    end
end
for _, name in ipairs({ "GetDescendants", "GetChildren", "FindFirstChild", "FindFirstChildOfClass",
    "FindFirstChildWhichIsA", "IsA", "Destroy" }) do
    wrap(name)
end
local originalNew = _G.Instance.new
_G.Instance.new = function(...)
    bump("Instance.new")
    return originalNew(...)
end
"""

MEASURE = """
local hub = _G.SkillHubJujutsu
local count = _G.__COUNT
for key, value in pairs(count) do
    _G.__MEASURED = _G.__MEASURED or {}
    _G.__MEASURED[key] = value
end
"""


def main() -> int:
    if not os.path.exists(HUB):
        print("hub not found at %s" % HUB)
        return 1

    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.execute(PRELUDE + INSTRUMENT)

    source = io.open(HUB, encoding="utf-8").read()
    loader = runtime.eval("function(src) return task_spawn(function() return load(src, 'SkillHub.lua')() end) end")
    loader(source)

    # let the window finish building before the meter starts: the load-time
    # instance churn is paid once and is not what this budget is about
    runtime.execute("for index = 1, 8 do pump(0.25) end")
    runtime.execute("_G.__COUNT = {}")
    runtime.execute("""
local hub = _G.SkillHubJujutsu
for _, tab in ipairs(hub.tabs) do
    for _, api in ipairs(tab.toggles or {}) do pcall(function() api.Set(true, false) end) end
end
""")

    started = time.perf_counter()
    for _ in range(SECONDS * 4):
        runtime.execute("pump(0.25)")
    wall = time.perf_counter() - started
    runtime.execute(MEASURE)

    counts = dict(runtime.eval("_G.__MEASURED") or {})
    perf = dict(runtime.eval("_G.SkillHubJujutsu.state.perf") or {})

    failures = []
    print("per virtual second, every toggle on:")
    total = 0
    for name, budget in BUDGET.items():
        value = int(counts.get(name, 0))
        per_second = value / SECONDS
        total += value
        ok = per_second <= budget
        if not ok:
            failures.append("%s %.1f/s over budget %d" % (name, per_second, budget))
        print("  %-24s %8.1f / s   (budget %d)%s" % (name, per_second, budget, "" if ok else "   OVER"))
    total_per_second = total / SECONDS
    ok = total_per_second <= TOTAL_BUDGET
    if not ok:
        failures.append("total %.1f/s over budget %d" % (total_per_second, TOTAL_BUDGET))
    print("  %-24s %8.1f / s   (budget %d)%s" % ("all engine calls", total_per_second, TOTAL_BUDGET,
                                                 "" if ok else "   OVER"))
    print("  %-24s %8.3f s" % ("wall clock for %d virtual s" % SECONDS, wall))

    # the hub's own counters have to agree that the scanner is doing its job
    print()
    print("the hub's own counters:")
    walks = int(perf.get("structureScans") or 0)
    refreshes = int(perf.get("refreshCalls") or 0)
    visited = int(perf.get("visits") or 0)
    writes = int(perf.get("writes") or 0)
    skips = int(perf.get("skips") or 0)
    reused = int(perf.get("reused") or 0)
    print("  map walks %d · refreshes %d · instances visited %d" % (walks, refreshes, visited))
    print("  writes %d · skipped by the write cache %d · values reused %d" % (writes, skips, reused))
    if walks < 1:
        failures.append("the scanner never walked the map")
    if refreshes <= walks:
        failures.append("the cheap refresh tier never ran more often than the walk")
    if reused < 1:
        failures.append("nothing was reused — the caches are not working")

    report = runtime.eval("_G.SkillHubJujutsu.perf and _G.SkillHubJujutsu.perf.rows()")
    rows = len(list(report.values())) if report is not None else 0
    print("  perf report rows %d" % rows)
    if rows < 3:
        failures.append("the perf report has no rows to show")

    errors = [str(x) for x in runtime.eval("_G.__SkillHubErrorLog").values()
              if x is not None and str(x).strip()]
    if errors:
        failures.append("%d error(s) were logged while measuring" % len(errors))
        for line in errors[:5]:
            print("   " + line)

    print()
    if failures:
        for line in failures:
            print("FAIL " + line)
        print("PERF BUDGET FAILED — %d problem(s)" % len(failures))
        return 1
    print("PERF OK — the hub stays inside every budget with every toggle on")
    return 0


if __name__ == "__main__":
    sys.exit(main())
