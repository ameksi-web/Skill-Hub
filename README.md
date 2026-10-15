# Skill Hub — Blox Fruits Hub + Skill Animator Studio

Two fully separated products live in this repository:

| File | What it is | Where it runs |
|------|------------|---------------|
| `main.lua` | **Skill Hub v3.0 Ultra** — Blox Fruits (Update 24+) executer hub | Injected by an executor (Synapse/Delta/Xeno/…) |
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

### Fixes in this version
* **Sea display** — PlaceId tables **plus** live `Workspace` island/mob/NPC scan and a level heuristic, so custom or unknown PlaceIds no longer default to Sea 1. Manual override + live "Sea Report" panel included.
* **Fighting Style equip** — resolves Melee/Sword/Gun/Fruit tools by `ToolTip` **and** by known style names, attributes and keyword heuristics, then equips via `Humanoid:EquipTool()` with a `tool.Parent = character` fallback. The switcher includes Black Leg, Electro, Fishman Karate, Dragon Breath, Superhuman, Death Step, Sharkman Karate, Electric Claw, Dragon Talon, Godhuman and Sanguine Art, and force-equips the Melee tool after switching.
* **Fly v2 (no flag, smooth)** — velocity-driven motion (no per-frame CFrame teleporting, so no stutter and no rubber-banding), smooth acceleration with a hard velocity-spike clamp, invisible client-only floor pad so the `Humanoid` stays grounded (`Running` state, never `Freefall`, never `PlatformStand`), stable hover when keys are released, auto re-arm after respawn, anti-void rescue.
* **Fly ⇄ Auto Farm ⇄ PvP cooperation** — a single movement governor: while the fly owns the character every travel request from Auto Farm / Boss Hunter / PvP Hunter becomes a fly **autopilot** target (distance-aware speed, manual WASD always wins), `WalkSpeed` is frozen during flight so the character controller cannot fight the velocity, and the tween/Velocity tug-of-war is gone.
* **Fly Status panel** — live velocity, altitude and who currently owns movement (manual / autopilot / tween).

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
