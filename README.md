# Skill Hub — Blox Fruits Hub + Skill Animator Studio

Two fully separated products live in this repository:

| File | What it is | Where it runs |
|------|------------|---------------|
| `main.lua` | **Skill Hub v3.7.2 Ultra** — Blox Fruits (Update 24+) executer hub | Injected by an executor (Synapse/Delta/Xeno/…) |
| `SkillAnimator/init.lua` | **Skill Animator Studio** — Moon Animator 2 style keyframe/rig editor | Roblox **Studio plugin** (no pre-made animations) |

---

## 1. Blox Fruits Hub — `main.lua`

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/main.lua"))()
```

### Tabs
* **Auto Farm** — level/nearest mob/boss farming, chests, Bring Mobs, Hitbox Expander, Triple-Layer Fast Attack.
* **PvP & Players** *(new)* — **Auto Kill Selected Player**, **Auto Kill PvP-Enabled Players**, **Skill Aimbot / AimLock**, Spectate, Tween/Teleport to Player, Player Hitbox Expander and a live **Player Scanner** (PvP status · Devil Fruit · Fighting Style · Sword · Gun · Level · Bounty).
* **Stats & Combat** — auto stats, Z/X/C/V skill caster, Haki/race, Kill Aura, and the **fixed Fighting Style switcher** (V1 · V2 · V3).
* **Fruits & Raids** — stock sniper, **Fruit Magnet** (`firetouchinterest` + Handle pull), upgraded Zioles roller with `OriginalName` auto-store, raids & awakening.
* **Teleport & Seas** — all-sea island tween teleport (S1/S2/S3 prefixed), sea travel, **Sea Detection control** (Auto / force 1-2-3 + live report).
* **ESP & Visuals** — Player ESP with PvP + full loadout, rarity-coloured Fruit ESP, chest/island/Mirage/Kitsune/boss ESP, tracers.
* **Misc & Settings** — **Undetected Bypass Fly**, Walk on Water, Infinite Geppo, Infinite Energy, No Dash Cooldown, Auto Collect Drops, Sea Event / Mirage tracker, Server Status HUD, anti-cheat disabler, rejoin/hop, FPS boost.

* **Hook engine is now opt-in (zero background interference)** — metamethod hooks cannot be removed from a live client, so the hub no longer installs one by default. Everything else (farm, PvP hunter, ESP, fly, anti-stun, anti-cheat watchdogs, SimRadius) is plain removable Lua. `Misc → Metamethod Hook Engine` turns the single safe hook on when you want the Kick guard, security-remote blocking and the aim raycast redirect; the status panel shows how many calls it intercepted (`CoreGui touched: never`).
* **Hook engine rewritten (fixes the CoreGui `attempt to call a nil value` error)** — the script used to install two raw, chained `__namecall` closures plus a raw `hookfunction(LocalPlayer.Kick)`, and it blocked any remote whose name merely *contained* generic words like `check`, `log`, `ban` or `flag`. That leaked into Roblox's own `CoreGui` modules. Now there is **one** unified hook: `newcclosure`-wrapped, `pcall`-protected with guaranteed fall-through to the untouched original call, blocking only unambiguous security endpoint names, with the Kick guard limited to `LocalPlayer`. A **Safe Hook Mode** toggle (default ON) disables interception entirely if an executor misbehaves, plus a live **Hook & Anti-Cheat Status** panel.
* **Animation load spam reduced** — `Bring Mobs` no longer destroys mobs' `Animator` (which made the engine keep replicating animation tracks for a dead animator). It can optionally stop the playing tracks instead.
* **`SimulationRadius` is now finite (`9e9`)** — `math.huge` produced `inf`/`NaN`, which corrupted physics, animation state and remote payloads downstream.

### Interface — "Porcelain" design system (2026)
* Soft-dark graphite surfaces in five intentional elevation steps, 1px hairline borders and 20px window radii — depth comes from surface layering and a soft drop shadow, **not** from neon or glow.
* Muted editorial accent family per tab (iris, clay, mauve, sand, sage, rose, steel) instead of saturated RGB.
* Redesigned components: pill switches with state labels, hairline sliders with floating value pills, soft-filled action buttons with hover/press states, dropdown lists with check dots, **segmented controls**, mono readout panels with a pulsing LIVE dot, inset text fields with focus rings.
* New chrome: floating window with title-bar drag, search field, ghost window controls, rail navigation with animated active pill, player identity card with Roblox headshot avatar, header status chips (sea/source, kill state, fly state, ping+FPS) and a bottom strip with hotkeys and a live clock.
* Toasts slide in with a draining progress hairline; the auto player list uses avatars, status lamps and inline actions.

### Fixes in this version
* **Sea display** — PlaceId tables **plus** live `Workspace` island/mob/NPC scan and a level heuristic, so custom or unknown PlaceIds no longer default to Sea 1. Manual override + live "Sea Report" panel included.
* **Fighting Style equip** — resolves Melee/Sword/Gun/Fruit tools by `ToolTip` **and** by known style names, attributes and keyword heuristics, then equips via `Humanoid:EquipTool()` with a `tool.Parent = character` fallback. The switcher includes Black Leg, Electro, Fishman Karate, Dragon Breath, Superhuman, Death Step, Sharkman Karate, Electric Claw, Dragon Talon, Godhuman and Sanguine Art, and force-equips the Melee tool after switching.
* **Fly v2 (no flag, smooth)** — velocity-driven motion (no per-frame CFrame teleporting, so no stutter and no rubber-banding), smooth acceleration with a hard velocity-spike clamp, invisible client-only floor pad so the `Humanoid` stays grounded (`Running` state, never `Freefall`, never `PlatformStand`), stable hover when keys are released, auto re-arm after respawn, anti-void rescue.
* **Fly ⇄ Auto Farm ⇄ PvP cooperation** — a single movement governor: while the fly owns the character every travel request from Auto Farm / Boss Hunter / PvP Hunter becomes a fly **autopilot** target (distance-aware speed, manual WASD always wins), `WalkSpeed` is frozen during flight so the character controller cannot fight the velocity, and the tween/Velocity tug-of-war is gone.
* **Buddha / giant combat fix** — scaled (Buddha) models are detected (markers, attributes, HipHeight, model height), the aim point moves to the torso centre, **every limb/torso part is sent as a blade hit** and reach auto-extends, so auto-kill finally lands on Buddha users. Kill Aura additionally slashes *every* attackable player within the aura radius.
* **Hitbox Expander v2** — player hitbox now scales the whole model (not one blob part) and restores every part exactly; live visualiser; independent **mob hitbox expander** with configurable size/range that works with Bring Mobs off and auto-restores.
* **Auto Player List** — live in-UI roster that refreshes every second: PvP status lamp, level, fruit, style, HP, distance, plus one-click `TGT` / `KILL` / `TP` / `CAM` buttons per player.
* **Fly Status panel** — live velocity, altitude and who currently owns movement (manual / autopilot / tween).

### v3.7.3 — the console now names our own lines, and they are fixed
With the whole interface running for the first time, Roblox's console started reporting errors *from this file* (`CoreGui.11596.Loadstring.loadstring.<id>` **is** this script — that is how an executor names a `loadstring` container, and the `Locales.en-us` module is only Roblox's error formatter). Two real bugs surfaced and are fixed:

* `selectTab` tweened `t.pillStroke`, but the tab record was created **without** that field → `TweenService:Create failed because Instance is null` on every tab click and in the boot sequence.
* **Every** UI animation now goes through `SafeTween(instance, info, props)`: a missing instance simply does nothing instead of reaching the engine, so that entire class of red line is gone (61 call sites). The instance helpers (`new`, `corner`, `hairline`, `pad`) also refuse to parent `nil` any more.
* Hotfixes in the same build: the debounce timers that could swallow the *first* report are initialised properly, and the boot banner shows the real version.

Regression test: the file is loaded in a mocked Roblox harness where `TweenService:Create(nil, …)` raises exactly like the engine does. v3.7.2 reproduces the user's error, v3.7.3 runs through the full boot **and** a click on every tab with zero errors.

### Critical fix (v3.7.2) — why the hub stopped loading, and what changed
**Root cause.** Lua (and Luau) allow only **200 active local variables per function**. `main.lua` is one giant chunk, and by commit `f776e6d` it had grown to **205** top-level locals, then 234 with the redesign and 259 with the diagnostics — so the file **no longer compiled at all**: the executor printed a compile error and the hub never started. Everything after that commit (design, hook work, console-error rounds) was shipping into a file that could not run.

**Fix.** The engine layer and the interface each run inside their own *factory function* now and hand their results back through a table:

```
               main chunk: ~130 locals   (was 259, limit 200)
local EngineFactory = function(E) … end   -- farm / PvP / ESP / fly / hooks
local UIFactory     = function(E) … end   -- "Porcelain" interface + all tabs
```

**Verification.** The file is now *executed* (not just parsed) in a harness with a mocked Roblox environment: it runs from the first line to the boot banner, connects 1 373 signals, and the evidence reporters print. Any further chunk-level local variable should go into one of the factories instead.

### Stability updates (v3.7.1)
* **Synthetic input back ON by default** — the `VirtualUser` / `VirtualInputManager` layer is what the Z/X/C/V skill caster, infinite geppo and Anti-AFK use; turning it off by default in v3.7 broke them. It is opt-out in `Misc → Synthetic Input`.
* **Cheap CoreGui watchdog** — it only reacts to scripts and numeric-named instances (max 10 captures/second); CoreGui receives thousands of descendants per session.
* **`SkillHubNoEvidence`** (or `Config.NoDiagnostics`) turns every diagnostic off in one line, and all of them are `pcall`-wrapped so they can never stop the hub from loading.

### Stability updates (v3.7)
* **Synthetic input is OFF by default.** `VirtualUser` / `VirtualInputManager` are the only engine *input* APIs this hub ever calls, and the engine funnels their failures through the CoreGui / Locales formatter. Fast Attack still fires through the packet layers and `Tool:Activate()`; re-enable the synthetic layer in `Misc → Synthetic Input` if you want it. Anti-AFK now nudges the character instead of clicking, so it needs no input API at all.
* **Script-identity sample** — the hub prints, at boot and in every report, how a real error *inside this file* is labelled in the console, so that label can be compared directly with any red line.
* **CoreGui watchdog (read-only)** — snapshots `CoreGui` the moment the hub starts (an instance already present cannot have been created by the hub) and logs every instance added there afterwards together with the Luau traceback of that moment. A traceback with no Luau frame means the engine created it from C.
* **Second error reporter** — besides `LogService.MessageOut`, `ScriptContext.Error` is now watched too: it hands over the failing script object, so the report can name the instance that raised the error.
* **`Misc → Console Audit (paste-ready)`** prints the whole evidence block on demand: CoreGui snapshot, CoreGui additions, the hub action trace and the identity sample.

### Stability updates (v3.5)
* **ESP billboard pooling** — the ESP no longer destroys and re-creates 100+ `BillboardGui`s twice per second; tags are pooled per adornee and only updated/swept. GUI churn around death/respawn is practically eliminated.
* **Death / respawn quiet window** — all heavy work (ESP, attack spam) stands down for ~2.5–3 s while the character is loading or unloading, exactly when Roblox rebuilds its own UI and when CoreScript errors are reported.
* **Synthetic input sandbox** — every `VirtualUser` / `VirtualInputManager` call is capability-gated, `pcall`ed, throttled and self-disabling (Xeno and other free executors only implement part of that unofficial API).
* **Tagged internal errors** — 39 internal steps run through `SkillHubStep`, which prints `[Skill Hub] step error @ main.lua:LINE` if code **in this file** fails, so console blame is never ambiguous.
* **Escape hatches**: `SkillHubNoHooks`, `SkillHubNoVirtualInput`, `SkillHubNoEsp`, `SkillHubSafeMode`, `SkillHubMinimalMode` (UI only, everything else off).

### Diagnosing console errors
Roblox tags each console line with where it was raised:
* `[Roblox][CoreGui...] ... Script 'CoreGui.<id>'` → raised inside a script that lives in `CoreGui` (Roblox's own CoreScripts are the usual owner of the `RobloxGui.Modules.Common.Locales.en-us` message; injected code can also reach that formatter through unofficial engine APIs, which is why the hub stops calling them by default).
* `-- [Blox Fruits] ...` → raised by the game.
* Lines without those tags that mention `main`/your executor → raised by scripts you injected.

The hub now *measures* this instead of asserting it: the boot line `[Skill Hub] CoreGui audit @ injection: … numeric-named: …` and the watchdog report printed with every engine error show whether a CoreGui script existed before the hub ran and whether anything was added to CoreGui while it was alive. Load with `Misc → CoreGui Watchdog` on (default) and send that block whenever a red `CoreGui` line appears.

If you want to prove a console error does **not** come from this hub, load it with the hook engine completely off:

```lua
getgenv().SkillHubNoHooks = true
loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/main.lua"))()
```

Other safety nets: meteathod hooks **cannot be removed** from a running client, so re-executing an updated build cleanly unloads the previous instance first (double-injection guard); **Safe Hook Mode** makes the hook a pure pass-through; and **Misc → Unload Skill Hub** tears everything down.

### Hotkeys
| Key | Action |
|-----|--------|
| `RightCtrl` / `F9` | Show / hide the window |
| `RightShift` | Toggle Skill Aimbot / AimLock |
| `RightAlt` | Toggle Undetected Bypass Fly |
| `Space` (mid-air) | Infinite Geppo jump (when enabled) |

---

## 2. Roblox Studio Plugin — `SkillAnimator/init.lua`

Moon Animator 2 style plugin: rig picking, keyframe timeline, easing curves, playback, onion skin, VFX, camera control and export — **with zero pre-made animations**.

Install:
1. Roblox Studio → **Plugins** tab → *Plugins Folder*.
2. Save the raw file there as `SkillAnimator.lua`
   `https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/SkillAnimator/init.lua`
3. Or paste it into a `Script` and use **Save as Local Plugin…**
