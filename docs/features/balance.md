# Feature: Balance (which JSON knobs to turn)

_All numbers live in `Content/*.json`. This note explains the targets, the formulas, and what to change. Numbers below were checked with a rough greedy economy sim, not real play; expect to retune in 1E._

## Pacing targets
- **First horde ~4.5 min** (`hordes.json schedule.firstHordeSeconds` = 270): 5 walkers, one edge. Starting layout (HQ, 12 wood walls, 1 staffed watchtower) wins it easily: tower 20 dmg/s + HQ 10 dmg/s vs 60 HP walkers.
- **5-min session, leave 4 h (time factor on):** come back to finished queue, full storage, survivors at housing cap, a Long Run reward waiting. Caps (500 base, +500 per Storage L1) stop runaway.
- **30 min (1C exit check):** HQ 2 reached; first brute seen (day 3, ~27 min).
- **2-hour session:** HQ 3 at ~80–95 min; hordes 10–11 with 2+ brutes from 3 edges.
- **HQ falls:** lose 25% of stored food and scrap (`economy.json hqFall.resourceLossPct`). Never survivors, never buildings (they become rubble).

## Key formulas
- **Production:** `productionPerMin × (workersStaffed / workers)` per building, stopped at cap. Agriculture ×1.25 on farms.
- **Storage cap (food and scrap each):** `resources.baseCap (500) + HQ storageAdded + Σ Storage storageAdded`.
- **Housing:** HQ housing + Σ Shelter housing. New survivor every 60 s if housing is free and food ≥ 10.
- **Horde timing:** horde 1 at 270 s; then 600 s after the previous horde ends. Clock runs only with the app open and unpaused.
- **Horde size:** `budget = round((5 + 4 × (day − 1)) × townFactor)`; `townFactor = clamp(1 + townValue / 10000, 1, 1.5)`. townValue = resources spent on standing buildings (stored resources don't count, so hoarding never makes hordes bigger).
- **Composition:** guaranteed units first, then weighted fill. Threat cost: walker 1, runner 2, brute 10. Days 1–2 walkers only; 3–4 add runners + 1 brute; 5–8 brutes in the mix; 9+ 2 brutes, 3 edges.
- **Bonus (Horde Alert) horde:** budget × 1.5, loot × 2. Frozen at the edge until Engage.
- **Wall math:** time for one zombie to break a wall = `wallHp / (damageVsBuildingsPerSec × wallBashMultiplier)`. Wood L1 vs walker: 40 s. Vs brute: under 3 s. Metal L1 vs brute: ~11 s.
- **Pathing:** wall tile cost = `currentHp × 0.05 × pathCostWeight`, so damaged walls pull more zombies (pile-up at weak points).
- **Offline credit:** `min(timeAway, 12 h)`, production × 1.0, no combat, horde clock frozen.

## Expected progress, 0–120 min (active play, 1x)
| Min | Town | Horde |
|---|---|---|
| 0–5 | Farm, Scavenger Post, Shelter; queue 2nd farm/post | #1 at 4.5: 5 walkers |
| 5–15 | Storage, 2nd Shelter, Barracks; ~16 survivors | — |
| 15–30 | 2nd watchtower, Workshop, first defenders; HQ 2 started ~27 | #2 ~16: 9 walkers. #3 ~27: 1 brute + runners, 2 edges |
| 30–60 | HQ 2 done ~30; farms/posts to L2; MG nest; research Marksmanship or Metal Fortification | #4 ~39, #5 ~50 (budget 17–21) |
| 60–90 | Metal walls on weak points; Storage L2; HQ 3 started ~65–70, done ~80–95 | #6–#8 (budget 25–33, 1–2 brutes) |
| 90–120 | L3 upgrades, 4th build slot; storage near cap → spend on defenses | #9–#11 (budget 37–45 × up to 1.5, 3 edges) |

Income check: ~20/min each at 15 min, ~40 food + 60 scrap/min at 60 min. Scrap is the bottleneck by design; food piles up after 60 min (see open question).

## If it feels too slow / too hard
| Problem | Turn this |
|---|---|
| Early game drags | `resources.json` starting scrap; Farm/Scavenger L1 `productionPerMin`; L1 `buildSeconds` |
| HQ 2/3 too late | HQ level `cost` and `buildSeconds` in `buildings.json` |
| First horde too early/late | `hordes.json schedule.firstHordeSeconds` |
| Hordes too frequent | `schedule.intervalSeconds` |
| Hordes too big late | `budget.budgetPerDay`, `townFactorMax` |
| Brutes too punishing | `zombies.json` brute `hp` / `wallBashMultiplier`; `composition` brute `guaranteed`/weight |
| Walls useless | wall `hp` per level; walker `damageVsBuildingsPerSec` |
| Towers too weak | `damage` / `fireRate`; `units.json garrison.towerDamageMultiplier` |
| Coming back feels empty | `resources.baseCap`, Storage `storageAdded`, `offline.json productionEfficiency`, run rewards |
| Coming back feels too generous | lower `maxOfflineCreditHours` or `productionEfficiency` (e.g. 0.5) |
| HQ fall too harsh/soft | `economy.json hqFall.resourceLossPct` |

## Files
- `Content/resources.json`, `buildings.json`, `zombies.json`, `units.json`, `hordes.json`, `research.json`, `offline.json`, `economy.json`

## Change log
- 2026-10-31 — First tuning pass for all Phase 1 content files.
