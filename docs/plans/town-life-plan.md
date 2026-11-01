# Town life plan — humans (chunks 3M-2, 3M-3)

_Draft 2026-11-01. Owner wants a varied cast of survivors walking around doing different jobs, "like Tropico". Nothing built yet. Chunk entries: `docs/BUILD-QUEUE.md`._

## 1. What the player should feel
- The base is a small living settlement, not a static diorama: at a glance you can tell who is farming, who is hauling, who is building, who is idle.
- Your choices show up as people: add a worker to the Farm and someone walks over and starts hoeing; send a run and two people walk out the gate.
- Hordes have a human beat: the warning siren sends everyone running inside; "Held!" brings them back out.
- Variety: no two neighbours look identical (mixed body types, clothes, ages — adults only).

## 2. Ground rules
- **Looks only.** Core decides the numbers (how many work at each building, build, are away, are defenders, are idle). Town life draws those numbers. It never sends a `Command`, never changes saves, never affects combat. Zombies don't attack civilians (they are indoors during hordes anyway).
- **Deterministic and testable:** who-goes-where and task choice are pure functions in `Core/Sources/HoldoutCore/Presentation/` (seeded by survivor slot + day, no wall clock), tested like `CharacterMotion3D`. The App only places models and plays clips.
- **Tuning in JSON:** caps, walk speed, task lengths, the per-building task table → `Content/presentation.json → townLife`.
- **Missing model = labeled box**, as for every model.
- **Naming (owner decided 2026-11-01):** they are **survivors** everywhere (Core, HUD, docs). Not "townspeople" or "settlers".

## 3. Cast and animations (3M-2)
Mixamo, one character per file, all clips on one timeline (D-038 pipeline). Download: FBX Binary, With Skin, 30 fps, **In Place** where offered. Folder: `HighwayHoldout_3D_Sources/mixamo-humans/<artId>/`.

| artId | Who | Clips |
|---|---|---|
| `unit_defender` | armed survivor (soldier/SWAT-type Mixamo character) | rifle idle, rifle walk, rifle run, rifle aim + fire, hit reaction |
| `civ_a` … `civ_d` | 4 different civilians (e.g. worker in overalls, woman in jacket, older man, young woman) | idle, walk, run (panic), carry-box walk, hammering, digging/planting, pick up from ground, talking/gesturing, sitting (optional) |

- Variety = 4 models × 2–3 tints (`reality3d.characters.variants`, like runner/brute) → ~8–12 looks. Slight random height scale (±5%) per person from the seed.
- Size budget: ≤ 3 MB per character (walker is 3.0 MB) → ~15 MB total. If too big: fewer clips per civilian, or explore one shared clip library (needs cross-file animation binding, not done in D-038 — note as risk).
- Small hand props (crate, sack, hoe, hammer) as tiny separate models attached to the hand joint; skip any that's fiddly — the clip alone reads fine from the game camera.

## 4. Who is on screen (3M-3)
- One visible person per survivor, up to `townLife.maxVisible` (start at 40). Over the cap, each role is scaled down proportionally so the mix still matches.
- Roles come from Core each tick (`GameLoop.population` + per-building `assignedWorkers`, construction jobs, active runs): **worker@building**, **builder@site**, **away** (not drawn, except leaving/returning), **defender** (3M-2's layer, not town life), **trainee** (drills at the Barracks), **idle**.
- Each person keeps a stable slot id so the same face keeps the same job when numbers change by one (no shuffling the whole town). When a role count drops, the most recently assigned person leaves first.
- Home = nearest Shelter with room (else HQ). Purely visual.

## 5. Daily loop and tasks
Simple state machine per person: **go to work → task loop → (carry delivery) → break → task loop … → go home**. There is no day/night yet, so "go home" happens on a slow seeded timer (people trickle in and out), not all at once.

Per-building task table (JSON; first ideas):

| Building | Workers do | Deliveries |
|---|---|---|
| Farm | dig/plant in the plots, pick up, kneel | carry a sack to Storage/HQ every N seconds |
| Scavenger Post | sort scrap (pick up / hammer) | carry a crate to Storage |
| Workshop | hammer at a bench, talk | — |
| Storage | stack crates (pick up, carry short hops) | — |
| HQ | talk in pairs, idle | — |
| Barracks (trainees) | rifle aim / idle drill in a row | — |
| Watchtower / MG nest (civilian worker) | stand on platform, idle | — |
| Construction site (builders) | walk to site, hammer around the footprint | — |
| Idle survivors | wander short loops near HQ, chat in pairs, sit | — |

Task spots: a few points around each building's footprint (computed from the footprint, no hand-placed data), so workers spread out instead of stacking.

## 6. Events
- **Worker count changed** (−/+): a person walks from home/HQ to the building, or walks away from it, within a few seconds.
- **Construction job starts/ends:** builders walk to the site / back.
- **Scavenging run sent:** the team walks to the nearest map edge and fades out; **collected/returned:** they fade in at the edge carrying sacks and walk to Storage.
- **Horde warning:** everyone runs (panic clip) to the nearest Shelter/HQ and fades out at the door. **Horde over ("Held!")**: they come back out and resume. "HQ fell": stay hidden until the next day/state reset.
- **Tap a survivor:** small label "Farmer · Farm" (role + workplace). No names yet.

## 7. Paths and performance
- Walk on the tile grid around buildings and walls (never through them) using a small cached A* in `Core/Presentation` over the same blocking rules as `FlowField` (gates/openings only). Cap path requests per frame; reuse paths between the same two buildings.
- Motion and walk-rate via `CharacterMotion3D` (no foot sliding, smooth turns).
- Caps: `maxVisible`, max path requests per frame, animation update only for on-screen people; at far zoom drop to every-other-frame updates. Target: no fps loss at day 40 vs. before 3M-3 (check with 5R's readout if available).

## 7b. Crowd budget: how many people can we have on screen? (owner request 2026-11-01)
The owner wants **lots** of people and zombies, many assets, a large world, and **no hot phone**. So the caps are measured, not guessed. Do this as the **first step of 3M-3** (it needs 3M-2's human models), or fold it into 5R if 5R runs first — 5R already owns the fps readout and stress tests.

**Device floor (owner decided 2026-11-01, D-040):** latest iOS only, minimum phone **iPhone 15 Pro (A17 Pro, 8 GB)**. All caps are measured on an iPhone 15 Pro. Applying it (deployment target + App Store device restriction) is part of this step or 5R. iPads need their own floor (probably M1 or newer, still open).

**What we know so far:** 1R spike: 100 animated zombies at 60 fps on an iPhone 18 Pro with shadows. 4R: day-40 horde (47 zombies) ~59–60 fps in the *simulator* (not representative of a real phone). Never measured: humans, a big map, sustained heat over 15+ minutes, or an older phone.

**How to measure:**
1. A DEBUG **crowd stress scene** (extend the 1R spike or 5R's readout) with sliders: zombies (0–300), survivors (0–200), number of buildings, map size, shadows on/off, camera zoom.
2. Record per run: frame time (CPU and GPU separately, Instruments / MetalFX HUD), memory, triangle count, and `ProcessInfo.thermalState` every 30 s over a **15-minute sustained run** (peak fps lies; heat shows after minutes).
3. Run on the floor phone (owner provides or borrows one) and on the newest phone; the simulator only for rough checks.
4. Pass line per setting: steady 60 fps with ~30% frame-time headroom (≤ ~11 ms of the 16.7 ms), thermal state never above "fair" in 15 minutes, memory under ~1.5 GB.

**How to turn it into caps:** cost per character ≈ (frame time with N characters − frame time with none) ÷ N, measured separately for zombies and survivors at near and far zoom. Max characters = (budget − cost of the world and buildings) ÷ cost per character. Write the results as a table in `docs/plans/crowd-budget.md` and set `townLife.maxVisible`, zombie draw caps and per-device tiers in `Content/presentation.json`.

**Free win:** survivors hide indoors during hordes (§6), so survivors and zombies are almost never on screen at the same time. The *combined* cap can go to whoever is out: lots of survivors in peacetime, lots of zombies in a horde.

**Levers to raise the cap (try in this order, measure each):**
- **Character detail levels (LOD):** a lower-poly copy of each character (Blender decimate in the exporter) used when far from the camera; Mixamo characters are high-poly for a phone.
- **Animation detail levels:** far characters update their animation at 30 or 15 per second; off-screen ones don't animate at all.
- **Shadows** only for characters near the camera; a cheap blob shadow for the rest.
- **Shared textures** (one atlas for all survivor looks, 512 px), fewer materials per character.
- **Culling:** nothing off-screen is drawn; big world drawn in chunks.
- **Heat guard:** if `thermalState` reaches "serious", automatically lower the visible cap and shadows (and tell nobody — it should just quietly stay cool); the 5R Battery saver uses the same knobs.

**Exit:** the table exists, caps are set from it, and a 15-minute horde + busy town run on the floor phone stays at 60 fps without going above "fair" heat.

## 8. Later (not in 3M-3; see `docs/IDEAS.md`)
Names and faces you can follow, needs/happiness (Tropico-style), day/night with people sleeping, survivors who can be bitten, morale from victories (ties to idea §5 rewards).

## 9. Open questions for the owner
1. ~~Name~~ — decided: **survivors**.
2. ~~Visible cap~~ — owner wants as many as possible; set by the §7b measurement (40 is only the starting guess).
3. Should the defender look clearly military, or like an armed civilian?
4. ~~Minimum phone~~ — decided: iPhone 15 Pro, latest iOS (D-040). Still open: can the owner get an iPhone 15 Pro to test on? iPad minimum?
