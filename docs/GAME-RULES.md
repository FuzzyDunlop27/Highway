# GAME-RULES — the central game-logic rule set

_The one place to read and tweak how the game plays. Owner: change a rule's words or number here and tell an agent "apply my GAME-RULES changes". Agents: this file must match the game; when you change a rule or a `Content/*.json` knob, update the line here in the same commit._

- **Numbers live in `Content/*.json`** (the code never hardcodes them). Each rule names its knob as `file → field` and the current value, so you can also change the number straight in the JSON.
- **Status:** ✅ live in the game · 🟡 planned (chunk named) · 💡 idea, not scheduled.
- Times are in-game seconds/minutes at 1x speed. "Day N" = the Nth regular horde.
- Why a rule is the way it is: `docs/DECISIONS.md`. Formulas and pacing targets: `docs/features/balance.md`.

## 1. Time and speed
| Rule | Knob (current) | Status |
|---|---|---|
| The game runs in fixed ticks | `economy.json → ticksPerSecond` (10) | ✅ |
| Speeds: pause, 1x, 2x | `economy.json → speedOptions` ([0,1,2]) | ✅ |
| Autosave | `economy.json → autosaveSeconds` (30 real s) | ✅ |

## 2. Resources and storage
| Rule | Knob (current) | Status |
|---|---|---|
| Resources: Food, Scrap, Survivors | `resources.json → resources` | ✅ |
| Start with 150 food, 200 scrap, 6 survivors | `resources.json → starting` | ✅ (food/water start changes in §4) |
| Food and scrap each cap at 500 + HQ/Storage bonuses; extra output is lost | `resources.json → baseCap`, `buildings.json → storageAdded` | ✅ |
| Survivors cap at housing (HQ 8/12/16, Shelter 4/7/10) | `buildings.json → housing` | ✅ |
| **New resource: Water** | `resources.json` (new entry) | 🟡 1W |
| **New resource: Canned goods** (a protected food reserve, §4) | `resources.json` (new entry) | 🟡 2W |

## 3. Survivors
| Rule | Knob (current) | Status |
|---|---|---|
| A new survivor arrives every 60 s while housing is free, paying 10 food | `resources.json → survivorArrival` | ✅ |
| Arrivals pause during a horde | `survivorArrival.pausedDuringHorde` (true) | ✅ |
| No arrivals while the town is hungry or thirsty | `survival.shortage.blocksArrivals` (true) | 🟡 1W |
| **A successful town attracts people faster** (owner, 2026-11-01): arrival time = 60 s ÷ **town appeal**, so appeal 2.0 = a newcomer every 30 s | `resources.json → survivorArrival.appeal` | 🟡 1W |
| Appeal starts at 1.0. +0.25 if food is going up, +0.25 if water is going up, +0.1 per horde held in a row (up to +0.5) | `appeal.foodSurplusBonus`, `waterSurplusBonus`, `perHeldHordeBonus`, `heldHordeBonusMax` | 🟡 1W |
| Appeal is capped at 2.0, and halved for 10 min after the HQ falls (the held-horde streak resets) | `appeal.max`, `appeal.hqFallMultiplier`, `appeal.hqFallSeconds` | 🟡 1W |
| Holding a horde also brings 1–2 newcomers at once (if housing is free and the town isn't short) | `appeal.heldHordeArrivals` ([1,2], seeded) | 🟡 1W |
| The HUD shows town appeal and why ("food up, water up, 3 hordes held") | App | 🟡 3W |
| Survivors are never killed; at 0 HP they're out for 2 min | `units.json → knockedOutSeconds` (120) | ✅ |
| Workers are set per building (−/+); defenders, trainees, runners, builders come first | `buildings.json → workers` | ✅ |

## 4. Food and water (survival) — owner design 2026-11-01
**Idea:** every survivor eats and drinks. A new town starts with a little to live on — canned goods, bottled water, one working well, and a broken garden to fix — and the player grows the food and water supply from there. Running short hurts, but never wipes the town.

**Starting supplies (new game)**
| Rule | Knob (proposed) | Status |
|---|---|---|
| Start with 50 fresh food + 100 canned goods + 60 water | `resources.json → starting` | 🟡 1W/2W |
| One working Well (L1) next to the HQ | `buildings.json → startingLayout` | 🟡 1W |
| One broken Garden near the HQ: starts as rubble, cheap to fix | `startingLayout → startsBroken` + rubble repair rules | 🟡 1W |
| One broken Well on the map to fix later (more water) | `startingLayout → startsBroken` | 🟡 1W |

**Upkeep**
| Rule | Knob (proposed) | Status |
|---|---|---|
| Each survivor (incl. defenders) eats 0.5 food/min | `resources.json → foodUpkeepPerSurvivorPerMin` (0 today → 0.5) | 🟡 1W |
| Each survivor drinks 0.5 water/min | `survival.waterUpkeepPerSurvivorPerMin` | 🟡 1W |
| People on a run or hunt don't eat at home (the run's food cost is their rations) | `survival.awayEatsAtHome` (false) | 🟡 1W |
| Fresh food is eaten first, canned goods only when fresh runs out | `survival.eatOrder` (["food","canned"]) | 🟡 2W |
| Gardens/farms use a little water | building `waterUsePerMin` (Garden 1, Farm 2/3/4) | 🟡 1W |

**Running short** (never a wipe)
| Rule | Knob (proposed) | Status |
|---|---|---|
| No food (fresh + canned = 0) → **Hungry**: all building output × 0.5 | `survival.shortage.hungryOutputMultiplier` | 🟡 1W |
| No water → **Thirsty**: output × 0.25 (water is worse than food) | `survival.shortage.thirstyOutputMultiplier` | 🟡 1W |
| After 3 min hungry/thirsty, one survivor **leaves town** every 2 min (idle first, defenders last). No one dies of hunger (owner confirmed 2026-11-01) | `survival.shortage.leaveAfterSeconds` (180), `leaveIntervalSeconds` (120) | 🟡 1W |
| Never fewer than 4 survivors from leaving | `survival.shortage.minSurvivors` (4) | 🟡 1W |
| Nobody leaves during a horde or while you're away | `survival.shortage.leavingPausedDuringHorde`, `…WhileAway` | 🟡 1W |
| While away, upkeep still runs but stops at 0; the welcome-back screen says "food ran out" | `offline.json` (catch-up) | 🟡 1W (+4B) |

**Ways to get food**
| Source | How it works | Knob (proposed) | Status |
|---|---|---|---|
| Garden (2×2) | Starter food: the broken one is fixed first. 1 worker, 4/6/9 food/min; upgrade = more beds | `buildings.json → garden` | 🟡 1W |
| Farm (2×2) | Bigger fields: 2 workers, 10/20/35 food/min | `buildings.json → farm` | ✅ (water use 🟡) |
| Foraging | Free from day 1 at the HQ: 2 survivors, 3 min, +25 food; early food before the garden works | `buildings.json → hq.runs` (new run type) | 🟡 2W |
| Hunting Lodge (2×2) | Send hunters out (like a scavenging run): Short Hunt 5 min / 2 people / +60 food; Long Hunt 1 h / 3 people / +450 food | `buildings.json → hunting_lodge.runs` | 🟡 2W |
| Chicken Coop (1×1) | Small steady food, no workers: 2 food/min, uses 0.5 water/min | `buildings.json → chicken_coop` | 🟡 2W |
| Cannery (2×2) | Workers turn fresh food into canned goods: 2 workers, 5/10/15 food/min canned | `buildings.json → cannery` | 🟡 2W |

**Why can food?** Canned goods (1) have their own pantry cap (+300 per Cannery level), so they add storage; (2) are **not lost when the HQ falls**; (3) are the rations long runs and hunts need; (4) are what you'll pack when you travel (Phase 3). Fresh food can also spoil — `survival.freshSpoilPctPerHour`, **0 at first** (turn it on in the balance pass if food piles up).

**Ways to get water**
| Source | How it works | Knob (proposed) | Status |
|---|---|---|---|
| Well (1×1) | 1 worker, 6/10/15 water/min. Broken wells are fixed with the normal repair rules | `buildings.json → well` | 🟡 1W |
| Rain Catcher (1×1) | No workers, cheap. Fills only during rain showers (seeded, ~2 min every 8–15 min), 8 water/min while raining, holds 40 | `buildings.json → rain_catcher`, `survival.rain` | 🟡 1W |
| Water Filter | Unlocks boiling/filtering creek water: +50% well output | `research.json → water_filtration` | 🟡 2W |
| Fishing / lake water | Maps on the lake shore (Lake Michigan idea) | `docs/IDEAS.md` §1 | 💡 Phase 2 |
| Water Tower | Extra water storage | — | 💡 |

## 5. Buildings and construction
| Rule | Knob (current) | Status |
|---|---|---|
| Buildings level 1→3; upgrades need an HQ level | `buildings.json → levels[].requiredHq` | ✅ |
| Build slots per HQ level: 2/3/4, queue up to 6; cost paid when a job starts | `buildings.json → rules.constructionSlotsByHq`, `constructionQueueLength` | ✅ |
| Each job borrows 1 idle survivor as builder | `rules.buildersPerJob` (1) | ✅ |
| Demolish refunds 50%; cancelling a running job refunds 75% | `rules.demolishRefundPct`, `cancelRefundPct` | ✅ |
| Repair costs 50% of level cost × missing HP; rubble rebuild 50% of invested | `rules.repair`, `rules.rubble` | ✅ |
| New game: HQ, closed ring of 28 **Chain Fence** walls (the starting barricade, owner 2026-11-01; was wood), 1 staffed watchtower | `buildings.json → startingLayout`; positions in the map's `startingPositions` | ✅ (+ well, garden 🟡 1W) |
| New games start on the **Chicago block**: 4-lane main street (not buildable) + side street, alley, houses, shops, vacant lots; old saves keep the highway map | `GameStore.startingMapId`; `maps/phase1_chicago.json` | ✅ (D-044) |
| Build and repair during hordes | `rules.buildDuringHorde` (true) | ✅ |
| Barrier choices (drawn as a line, share one wall limit 40/80/120): Wood Wall 10 scrap 200 HP; **Chain Fence** 15 scrap 300 HP (no research); Metal Wall 30 scrap 800 HP (needs Metal Fortification) — level 1 numbers | `buildings.json → defenses wall_wood / wall_fence / wall_metal` | ✅ (fence numbers are a first guess, D-043) |
| Map props and neighborhood buildings (houses, shops, garages, street lights, wrecks, trees, junk, weeds) block building and zombies on their tiles | `maps/*.json → decorations` | ✅ |
| Zombies enter at both ends of the main street and of the side street | `maps/phase1_chicago.json → spawnEdges` (ids shared with `hordes.json`) | ✅ |

## 6. Hordes and spotters
**Today:** a countdown to the next horde is always on screen, and arrows show the spawn edges 60 s before it arrives.
**Owner design 2026-11-01:** survivors posted as **spotters** call out hordes. Better spotters = earlier and better warnings.

| Rule | Knob (current / proposed) | Status |
|---|---|---|
| Horde 1 at 4.5 min, then 10 min after each horde ends; clock runs only with the app open | `hordes.json → schedule` (270, 600) | ✅ |
| Horde size grows by day and by what you've built (not by what you've stored) | `hordes.json → budget` | ✅ |
| Spawn edge arrows appear 60 s before arrival | `hordes.json → schedule.warningSeconds` (60) | ✅ → replaced by spotters 🟡 1L |
| **Lookout Post** (1×1, 1 worker = the spotter). Its level is its height: L1 rooftop platform, L2 tall tower, L3 crow's nest. Sight 10 / 16 / 24 tiles | `buildings.json → lookout` | 🟡 1L |
| An edge is **watched** if a staffed Lookout can see its spawn point (within sight). The HQ roof counts as a tiny lookout (sight 6, no worker) | `lookout.levels[].sightTiles`, `hq.lookoutSightTiles` | 🟡 1L |
| Warning time on a watched edge: 45 / 60 / 75 s by Lookout level. Unwatched edge: 10 s ("you hear them coming") | `lookout.levels[].warningSeconds`, `hordes.json → spotting.unwatchedWarningSeconds` | 🟡 1L |
| **Binoculars** (research): +30 s warning on every lookout; **Radio** (research, HQ 3): +30 s more, and scavengers on runs can spot too | `research.json → binoculars`, `radio` | 🟡 1L |
| What the spotter calls out grows with level: L1 edge + time; L2 + rough size ("about 15"); L3 + types ("2 brutes") | `lookout.levels[].intel` | 🟡 1L |
| The callout: banner "Horde spotted — east off-ramp, 75 s", arrows on that edge, siren sound hook, survivors head inside | App (3W) | 🟡 1L + 3W |
| The HUD always shows the day and a rough "next horde in ~6 min" (so 5-minute sessions can still plan); the exact countdown and edges only once spotted | `hordes.json → spotting.roughClockRoundingSeconds` (60) | 🟡 1L |
| Watchtower gunners also spot a little (sight 6, warning 20 s) | `watchtower.spotSightTiles` | 🟡 1L |
| Horde Alert (while away): "A horde has been spotted"; it waits frozen at the edge until you Engage | `offline.json → hordeAlert`, `hordes.json → bonusHorde` | 🟡 4B/5B (designed) |

## 7. Combat and zombies
| Rule | Knob (current) | Status |
|---|---|---|
| Walker 60 HP / Runner 30 HP fast / Brute 500 HP wrecks walls (×3) | `zombies.json` | ✅ |
| Zombies flow to the HQ and bash the weakest wall; damaged walls attract more | `hordes.json → pathing` | ✅ |
| Towers fire only when staffed; a defender in a tower ×1.5 damage | `units.json → garrison` | ✅ |
| Defenders: 120 HP, train at the Barracks (25 food + 25 scrap, 60 s) | `units.json → defender` | ✅ |

## 8. Runs and research
| Rule | Knob (current) | Status |
|---|---|---|
| Scavenging runs: Quick 5 min, Long 1 h, Overnight 4 h; rewards wait until collected; no risk yet | `buildings.json → scavenger.runs` | ✅ |
| Runs can lose people | `docs/IDEAS.md` §2 | 💡 |
| Research at the Workshop, one at a time; kept by the group for future bases | `research.json` | ✅ |
| Research: Metal Fortification, Marksmanship, Agriculture (farms ×1.25; also gardens 🟡) | `research.json → items` | ✅ |

## 9. Setbacks and time away
| Rule | Knob (current) | Status |
|---|---|---|
| No game over. HQ falls → horde ends, lose 25% of stored food and scrap (canned goods and water are safe 🟡), other buildings become rubble | `economy.json → hqFall` | ✅ |
| Time factor (setting, default OFF): up to 12 h of credit, no combat, horde clock frozen | `offline.json → timeFactor` | 🟡 4B/5B |

## Change log
- 2026-11-01 — Starting barricade is now 28 Chain Fence sections instead of wood walls (300 HP each instead of 200).
- 2026-11-01 — New games start on the Chicago block map (D-044).
- 2026-11-01 — Added the Chain Fence barrier and more map props (D-043).
- 2026-11-01 — Owner confirmed: short supplies make survivors leave (no deaths); added town appeal (successful towns attract people faster).
- 2026-11-01 — Created as the central rule set; added the owner's food/water survival and spotter design (D-042).
