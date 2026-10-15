# Skill Hub — Blox Fruits Hub + Skill Animator Studio

Two fully separated products live in this repository:

| File | What it is | Where it runs |
|------|------------|---------------|
| `release/skillhub.release.lua` | **the build the world gets** — not Lua at all: a hex blob XOR-ed against a per-16-byte-block stream seeded from the current key. Without the key it unlocks to noise | Downloaded by `loader.lua` |
| `loader.lua` | **the only entry point** — takes the key (argument → `skillhub.key` → clipboard), unlocks, verifies the pinned checksum, refuses wrong keys and modified builds | **the link you hand out** |
| `tools/` | `build_release.py` (seal + lock + checksum), `seal_secret.py` (per-machine endpoint sealing) | Run before each release |
| `SkillAnimator/init.lua` | **Skill Animator Studio** — Moon Animator 2 style keyframe/rig editor | Roblox **Studio plugin** (no pre-made animations) |
| `main.lua` | the readable **source of truth** — deliberately **NOT published** (`.gitignore`, kept private/local) | Only you |

---

## 1. Blox Fruits Hub — closed build (key system)

**One link for everybody, one key to enter:**

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/loader.lua"))("<key>")
```

Current key: **`UPDATE 2026`** — replaced with every update (`tools/build_release.py --pass "<new key>"`).

Users who do not want to paste the key into the line can pick any of these:

```lua
-- once, saved in the executor workspace:
writefile("skillhub.key", "UPDATE 2026")

-- or just copy the key to the clipboard and run the plain loader:
loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/loader.lua"))()
```

What the loader does: reads the key → downloads the locked blob → unlocks it → checks the plaintext really is a Skill Hub build → verifies the pinned FNV-1a-32 checksum (a modified blob is refused, not executed) → prints build + hash + key hash → unloads any previous instance → runs the hub. A wrong key prints *WRONG KEY — nothing was executed*.

**The readable source is private.** `main.lua` is not in this repository (GitHub returns 404 for it) — the published artefact is only the locked blob, and the sealed Lua inside it has its comments blanked and every string literal encrypted. Nobody who has the repository can read the script.

**Rotation is the revoke button** — publishing an update with a new key cuts off everybody who had the old one:

```bash
python3 tools/build_release.py --pass "UPDATE 2027"    # re-lock the build with the new key
git add -A release loader.lua && git commit -m "update + new key" && git push
```

**Release commands**

```bash
python3 tools/build_release.py            # re-lock the build, re-pin loader.lua, print stats
python3 tools/build_release.py --check    # verify the published blob still unlocks to the current source
python3 tools/build_release.py --selftest # python ⇄ Lua agreement on hash, unlock and lock
python3 tools/build_release.py --unseal   # local readable copy (git-ignored, never published)
```

### Tabs
* **Auto Farm** — level/nearest mob/boss farming, chests, Bring Mobs, Hitbox Expander, Triple-Layer Fast Attack.
* **PvP & Players** *(new)* — **Auto Kill Selected Player**, **Auto Kill PvP-Enabled Players**, **Skill Aimbot / AimLock**, Spectate, Tween/Teleport to Player, Player Hitbox Expander and a live **Player Scanner** (PvP status · Devil Fruit · Fighting Style · Sword · Gun · Level · Bounty).
* **Stats & Combat** — auto stats, Z/X/C/V skill caster, Haki/race, Kill Aura, and the **fixed Fighting Style switcher** (V1 · V2 · V3).
* **Fruits & Raids** — stock sniper, **Fruit Magnet** (`firetouchinterest` + Handle pull), gacha roller with `OriginalName` auto-store behind a **first-sight acquisition ledger** (Update 30 moved the Gacha Dealer to Middletown), raids & awakening.
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

### v3.12.1 — closed build with a human key (`UPDATE 2026`)

* **The distribution is closed again, with a key system instead of a secret key**: `loader.lua` asks for the key, the current one is announced with the update (now `UPDATE 2026`). Users can pass it as an argument, keep it in `skillhub.key`, or simply copy it to the clipboard — the loader finds it either way.
* **One link, one key, no readable source**: the repository publishes a single locked blob (`release/skillhub.release.lua`); the sealed Lua inside it has comments blanked and every literal encrypted, and `main.lua` is not published at all.
* **Author credit in the interface**: the welcome toast now reads `Skill Hub v3.12 Ultra · by ameksi-web` (`Config.Author`, disable with `Config.ShowAuthor = false`), so every copy of your build carries your name.
* **Key hygiene, honestly:** a short human key such as `UPDATE 2026` is *guessable* — it gates casual sharing, not a determined attacker. For a build only your inner circle can open, use a longer key (`UPDATE 2026 · 7f3a91`) and rotate it every update; that costs one command.
* **One source of truth, one build step.** `tools/build_release.py` seals the current `main.lua` into both artefacts, re-pins both checksums, prints the stats, and refuses to publish anything with a leftover plaintext marker (`rbxassetid`, urls, webhooks).
* **Honest limits:** whoever holds the key can read what runs on their own machine (that is inherent to client-side scripts) — which is why access is a key you can rotate rather than a promise, and why the hub also fingerprints the machine it runs on.
* **Verified:** `BUILD CHECK OK`, `LOCK SELFTEST OK`, `SEAL SELFTEST OK`, a direct end-to-end unlock of the published blob with the key (411 377 bytes, hash `bc3eefe5`, matching the loader pin; a wrong key is refused), and the same build runs through the mocked-Roblox harness — `LOAD OK`, zero errors after clicking every tab and the self-test.

### v3.11 — only you can read it: the source is private, the build is key-locked

* **`main.lua` is no longer published.** It is untracked from the repository and listed in `.gitignore`; it stays the readable source of truth on your machine (and in this workspace) only.
* **What the repository holds now is noise without the key.** `release/skillhub.release.lua` is a hex blob: the sealed Lua (comments blanked, every literal encrypted) XOR-ed against a stream whose seed is `hash32(key .. ":" .. blockoffset)` and changes every 16 bytes. No Lua syntax, no strings, no comments, no source — `grep` on the repository finds nothing, and copying the file gives nothing.
* **Position-derived block seeds** mean recovering the stream in one block (Lua source has long runs of blanks where comments used to be — the classic known-plaintext attack) tells an attacker nothing about any other block, and the key itself is a 96-bit passphrase that never enters the repository (`.release_key`, git-ignored, `chmod 600`).
* **The loader is the only door.** It takes the key (loadstring argument → `skillhub.key` file → `Loader.Key`), unlocks the blob, sanity-checks that the plaintext really is our build, verifies the pinned FNV-1a-32 checksum (a modified blob is refused, not executed), prints build + hash + key hash, unloads any previous instance and runs it. A wrong key prints *WRONG KEY — nothing was executed* instead of a compile error.
* **Rotation is the revoke button:** `python3 tools/build_release.py --pass "<new key>"` re-locks the build; whoever had the old key is out. Rebuilding is also what publishes a new version — `loader.lua` (build + checksum) is re-pinned automatically.
* **Verification:** `python3 tools/build_release.py --selftest` proves Python and Lua agree byte-for-byte on hash *and* unlock (wrong key ⇒ garbage), `--check` proves the published blob still unlocks to the current source, `--unseal` writes a local copy for reading, and the unlocked build runs through the mocked-Roblox harness (`LOAD OK`, zero tab errors) — so the lock cannot silently break the script.
* **Honest limits:** anyone holding the key — including a friend you authorise — can read what runs on their machine (client-side scripts always can be dumped); that is why access is a key you can rotate rather than a promise. Git history of older commits still contains the previously published files until history is rewritten; remove the repository or make it private if you want that gone too.

### v3.10 — GUARD: anti-theft, anti-tamper, request privacy

**The honest part first.** A script that runs on somebody else's client can always be dumped by that client — no client-side trick changes that. What *can* be done is make a stolen copy **useless**, **traceable** and **refused**. That is what this release does, in three layers: the hub's own guard, a protected loader, and a sealed release build.

**1. Guard inside `main.lua`** (Misc → *Guard · anti-theft & request privacy*, and `SharedEnv.SkillHubInstance.guard`):

* **Pristine references** — `game.HttpGet`, `game.HttpPost`, `loadstring`, `debug.info` are captured once as plain function values and always invoked as **plain functions**, so a `__namecall` / `__index` hook installed by another script (before or after us) never sees, rewrites or fakes our calls.
* **Fingerprint** — a HWID-derived 12-char tag (`hash32(hwid .. "|skill-hub")`), shown in the status panel, printed at boot, attached as `X-SkillHub-Tag` to every request we tag. A leaked copy names the machine it came from.
* **Licence gate** — `Config.LicenseKeys` (FNV-1a hashes). Empty list = no gate (default). With a list, `Guard Mode = enforce` stops the combat engines on a copy that was not authorised (`Guard.blocked()` gates `fireAttackPackets` and `attackCharacter`) instead of quietly working for a thief. Misc prints *your* key hash so you can authorise a key by pasting it in.
* **Tamper audit** — the identity of all 31 engine closures is recorded at boot (`debug.info(fn, "s")`) and re-checked every `Config.TamperAuditSeconds` (default 30 s). If another script swaps one out, the console says which one, and in `enforce` mode firing halts so a hijacked hub cannot get *you* banned.
* **Hook radar** — reports whether the game's metatable currently carries `__namecall` and whether it is a Luau closure (i.e. somebody else's hook) instead of guessing.
* **Export seal** — `getgenv().SkillHubInstance` is wrapped in a metatable (`__metatable`, `__newindex` error) so nothing outside can overwrite `unload`, `config` or our callbacks — the classic move of replacing a hub's functions through `getgenv()`.
* **No third-party code** — the old `PreferExternalFluent` code path that pulled `dawid-scripts/Fluent` from GitHub is **removed**: a foreign payload runs in the same environment as this hub and could hook it or read the user's requests. The Porcelain interface is ours, so nothing is fetched.
* **Sealed secrets** — `Config.SealedEndpoint` holds a webhook/API url **XOR-sealed with a keystream derived from the machine fingerprint** (`tools/seal_secret.py`). The file never contains the url; on any other machine the blob is noise and the hub prints *fingerprint mismatch* instead of using it. The hub itself stores **no** plaintext endpoint.

**2. `loader.lua` — the link you share**

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ameksi-web/Skill-Hub/arena/99225303-skill-hub/loader.lua"))()
```

It captures `HttpGet` as a plain function, downloads the **sealed** build, verifies its FNV-1a-32 checksum against the value written by `tools/build_release.py` (a modified payload is **refused**, not executed), prints build + hash + machine tag, optionally enforces a key list (`RequireKey = true`, `Keys = { "<hash>" }`), unloads any previous instance, runs the payload and drops the payload reference again.

**3. `release/skillhub.release.lua` — the locked build**

`python3 tools/build_release.py` replaces every comment with spaces (**line numbers are preserved exactly**, so all `SkillHubStep("main.lua:1471", …)` labels keep their meaning), encrypts every string literal into `__S("<seed><hex>")` decoded at runtime by a 4-line XOR decoder on line 1, and writes the payload checksum into `loader.lua`. Verification for the last build: 2 179 literals sealed, 593 comments blanked, 7 704 → 7 704 lines, `LOAD OK` in the mocked-Roblox harness with zero tab errors, and no `rbxassetid` / `discord.com` / `game:HttpGet` plaintext left in the file.

**Commands**

```bash
python3 tools/build_release.py          # rebuild the locked payload + re-pin loader.lua
python3 tools/build_release.py --check  # verify the published blob still unlocks to the pinned checksum
python3 tools/seal_secret.py --selftest # prove python ⇄ Lua agree on the sealing
python3 tools/seal_secret.py --tag "<fingerprint from Misc>" --seal "https://discord.com/api/webhooks/…"
```

**The only way to make the source itself unreadable** is to stop publishing it: move `main.lua` to a private repository (or serve the sealed payload from a key-gated Cloudflare Worker) and distribute `loader.lua` alone. Until then the protection is: sealed build in the open, source of truth private-or-public by your choice, and a leaked copy that is traceable, checksum-refused and licence-stoppable.

### v3.9.1 — the error reporter was hiding the error, and the icons are drawn now

Your console:

```
CoreGui.10464.Loadstring.loadstring:810579:55: attempt to index nil with 'LogStepErrors'
Script '…Loadstring.loadstring:810579', Line 55 - function SkillHubStep
Script '…Loadstring.loadstring:810579', Line 2323
```

Three separate bugs, all in the hub:

1. **`SkillHubStep` indexed a nil `Config`.** The instrumentation function sits near the top of the file, but `local Config` was declared ~600 lines below it — so inside it `Config` resolved to a *global*, i.e. nil. Every time any step failed, the reporter crashed on `Config.LogStepErrors` instead of printing `[Skill Hub] step error @ … -> <the real message>`. `Config` is forward-declared now, so the line that was supposed to tell you what broke finally can.
2. **That crash was masking a real error one frame down.** `aimCameraAt` (new in v3.9, the auto-aim used while auto-killing) was declared *after* the PvP tick that calls it → inside the tick it was nil → "attempt to call a nil value" on every auto-aim attempt. Moved above the tick.
3. **`UnloadSkillHub` was declared after the Misc button that calls it** — the same class of bug, and it means the `Unload` button had never worked. It is forward-declared now.

**Icons: drawn, not downloaded.** Your next console line:

```
[Skill Hub] icon rbxassetid://10734962068 did not load — drawing the vector fallback
```

That is the whole 107233… / 107349… asset set — moderated/dead in-game, which is exactly why the Fruits tile was empty. Every icon in `CustomIcons` is now **drawn from primitives** (crossed swords for Auto Farm, a fruit with a leaf for Fruits, an eye for ESP, a compass, a skull, a gear, a chart, a magnet, …) in the tab accent colour: nothing can fail to load, no tile is ever blank, and the active-tab header icon follows the tab. Unknown ids still fall back to `ImageLabel` + the drawn glyph, and the console reports a dead asset at most once per id.

**New release gate:** an `use-before-definition` static check over the whole file (Lua resolves a local declared after a function body to a global, so the call fails at runtime — the mock harness never walks that path). It flags the old build (`UnloadSkillHub`) and passes v3.9.1.

### v3.9 — fly you can actually stop, hitboxes up to 200 studs, deadlier auto-kill

**Fly ("I am flying and cannot stop")** — three separate causes, all fixed:

* the **autopilot snatch-back**: with Auto Farm / PvP Hunter running, the fly re-took control the moment you released the keys. The travel request is now paused while you are parked **and** for `Fly hold` seconds (default 1.2 s, Misc slider) after your last key press;
* **LeftCtrl = Park** (new): stops the character dead in the air, clears the autopilot target and holds that exact position until you press a movement key (or LeftCtrl) again. Same thing as the new `Misc → Park Fly` button;
* **hard hover brake**: releasing WASD/Space now brakes with a much stronger curve and snaps the residual velocity to zero instead of gliding on;
* a **Tween that was already running** used to keep dragging the character after the fly was switched on — enabling the fly stops it;
* **Infinite Geppo and Dash no longer add their own velocity while flying** (that was the "I keep drifting upward" feel);
* switching the fly off now clears the autopilot target, the park state and both velocities.

**Hitbox Expander**

* both sliders go to **200 studs** (mobs 10–200, players 6–200), the mob range slider to 3000;
* **whole-model scaling**: the root part grows to the configured size and every limb scales with it (up to ×4), so big/Buddha-sized models are hit by the game's own raycasts instead of one invisible blob. `Scale the whole model` toggles it off;
* mob parts now store **and restore** `Massless` as well (it used to stay true after switching the expander off);
* new **Expand every PvP player hitbox** mode (aura targets included, restored exactly when they leave).

**Auto Kill Players**

* attack bursts every **0.08 s** by default (`Attack Burst Interval` slider, 0.05–0.5 s), skills every `Skill Combo Interval` (0.15–1 s) and only when the target is actually in reach;
* the hunter now **glues itself to a moving target**: it re-issues the travel request while out of reach, so a running player cannot leave the fight;
* **Target Priority** dropdown — Nearest · Lowest HP · Weakest;
* **Auto AimLock while Auto Kill** keeps the camera on the victim (shared aim code with AimLock);
* auto-equips a weapon when your hand is empty (attacks do nothing bare-handed);
* `Auto Kill Selected falls back to nearest` is now an explicit toggle;
* hover height slider (0–40 studs) on top of the existing hover distance.

### v3.8.1 — the line from the console, and why some tabs looked dead

```
PlayerGui is not a valid member of Player 'Players.…'
Script '…Loadstring.loadstring:687882', Line 1671 - function getPvPStatus
Script '…Loadstring.loadstring:687882', Line 6184 - function rebuild
```

`PlayerGui` is a **child** of a `Player`, never a property — so `plr.PlayerGui` threw on every PvP scan. That call lives in the auto player list, which is built while the PvP tab is filled in: the exception unwound out of the build pass and **every widget after that point (entire tabs) was never created**. That is exactly why some tabs did nothing and the Fruit tab had nothing in it.

* the lookup is `plr:FindFirstChild("PlayerGui")` now (same for every other Player child);
* the first player-list rebuild runs inside `SkillHubStep` (the 1 s refresh loop was already protected);
* **build safety net** — every widget method (`AddToggle`, `AddButton`, `AddSlider`, `AddDropdown`, `AddSegmented`, `AddLabel`, `AddLivePanel`, `AddInput`, `AddPlayerList`) is wrapped in `SkillHubStep`, so one bad widget can never wipe out the rest of the build again;
* **tab clicks** are wrapped too: a failing click logs `[Skill Hub] step error @ tab click -> <tab>` instead of silently doing nothing;
* **tab census + self-test** — the boot log prints `[Skill Hub] tab census -> Auto Farm=… · PvP & Players=… · Fruits & Raids=…` (widget count per page) and `Misc → Tab Self-Test` selects every tab in turn and reports failures. An empty tab can no longer hide;
* **icon fallback** — if an icon asset id never loads, the tile draws a vector badge instead of staying blank and the console names the asset (`[Skill Hub] icon rbxassetid://… did not load`);
* static gate added to the release checklist: a scan for Player-child access written as a property (`plr.PlayerGui`, `plr.Backpack`, …) — it flags the old build and passes this one.

### v3.8 — honest fruit reports + Update 30

**The false "выбил фрукт" notification is fixed.** The old watcher announced *every*
`ChildAdded` in `Backpack`/`Character`, so moving a hotbar slot onto a fruit you already
owned (an eaten Kitsune, anything stored and re-equipped) printed "Fruit Rolled / Obtained"
and even fired an unnecessary `StoreFruit`. Fruits are now tracked by an acquisition ledger:

* only a tool **first seen inside the Backpack** counts — that is where pick-ups, gacha rolls and dealer purchases land;
* the same instance is never announced twice (equipping, re-parenting, un-storing);
* the same fruit name is never announced twice within a 60 s window;
* a fruit removed from a container is remembered for 8 s, so taking it back out stays silent;
* auto-store follows the same rule (no more redundant `StoreFruit` calls on a slot move).

Proven with a replay harness (`/tmp/fruit_test.py`): the *old* build notified **4 times**
for two real acquisitions, v3.8 notifies **twice** — exactly the two genuine ones.
`Fruits & Raids → "Fruit Obtained Notifications"` toggles the toast.

**Update 30 awareness (Sea 1 rework, live since 2026-09-05):**

* **Magnet** (Mythical) and the seven **chromatic skins** (Lime Blade, Topaz Diamond, Scarlet Ghost, Yellow Lightning, Starlight Gravity, Runic Fiend, Arcsteel Magnet) added to the roster, the rarity table and Fruit ESP colours; `getFruitTier` now prefers an exact match, so "Yellow Lightning" is no longer reported as "Light".
* **Advanced Combat** added to the fighting-style database (V1/V2/V3 switcher, `CommF_` remote `BuyAdvancedCombat`).
* **Island tween teleport resolves live models** — all sixteen First Sea islands were rebuilt, so the hard-coded CFrames can be stale. The hub now looks the island up in `Workspace` (including `Map` / `Islands` / `Locations` / `World`) and flies to its bounding-box centre, falling back to the stored CFrame.
* **Magnet Event** and **Island Secret** signatures added to the Sea Event tracker; level/EXP readouts no longer assume the old 2,800 cap (Update 30 raises it to 3,000 through the 40 Island Secrets).

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

**v3.8 — the reporter can no longer stay silent on your line.** The LogService handler used to require the text `CoreGui`/`Locales` *inside* the message before it printed anything; executors frequently hand the line over without that prefix (the script name is formatted by Roblox, not carried in the payload). Now **any** `attempt to call a nil value` error is captured, our own `[Skill Hub]` output is ignored so the dump cannot feed itself, and the boot log prints

```
[Skill Hub] console watchlist armed · LogService.MessageOut + ScriptContext.Error · every "attempt to call a nil value" now prints our action trace, the CoreGui snapshot and the failing instance name
```

If that line is **not** in your console above the red text, the build that ran is not v3.8 (a cached copy of an older `main.lua` — GitHub raw caches for ~5 minutes; re-execute). If it *is* there and the red line still appears, the block underneath it is the answer and always contains the failing instance name, the CoreGui state before/after the hub started, the last tab switches/actions the hub performed, and which layers were active (`synthetic input`, `hookEngine`).

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
