# Highway Holdout — Game Design (Phase 1 focus)

_Working title. Source of truth for design decisions. Keep this short; details live in docs/features/*.md._

## Pitch
Zombie-apocalypse town builder + tower defense for iPhone (15+) and iPad. Grow a small survivor town at a highway exit (Tropico-style feel), fortify its weak spots, and watch your defenses hold off hordes. Fully offline, no ads, no IAP, no multiplayer.

## Player fantasy / hook
- Fun to build and grow the town; thrilling to watch it defend itself.
- Clear weak areas to fortify (roads in, gaps in walls).

## Session design
- **5 minutes:** queue work (construction, scavenging runs, defender training, research) and leave.
- **2 hours:** do that, then fight hordes live and keep building during the fight.

## Core rules
- **Build live:** you can place, upgrade, and repair at any time, including mid-horde.
- **Resources (Phase 1):** Food, Scrap, Survivors (population); Water and Canned goods planned (1W/2W). Storage caps from HQ + Storage buildings.
- **Survival (owner, 2026-11-01, planned):** survivors eat and drink. A new town starts with canned goods, bottled water, a working well and a broken garden to fix; grow food with gardens, farms, foraging, hunting, chickens and canning, and water with wells and rain catchers. Shortages slow work and make people leave, never a wipe.
- **Spotters (owner, 2026-11-01, planned):** survivors posted at Lookout Posts call out hordes. Higher lookouts see farther; binoculars/radio give earlier warning and more detail. Unwatched roads give almost no warning.
- **All rules and their knobs in one place:** `docs/GAME-RULES.md`.
- **Hordes:** run on an in-game clock that only advances while the app is open. They enter from telegraphed map edges (highway on/off ramps, side roads). Size scales with day count and town size.
- **Zombie pathing:** flow field toward the HQ. Walls are passable at high cost (zombies bash through), so they naturally pile up at the weakest points.
- **No game over:** if the HQ falls, the horde ends, you lose a % of stored resources, and destroyed buildings become rubble to repair. Setback, never a wipe.
- **Time factor (setting, default OFF):** when ON, the world keeps moving while the app is closed — resources accumulate (to storage caps), construction/training/research finish. No attacks ever happen while closed. Offline credit capped (tunable, e.g. 12h).
- **Horde Alert notifications (setting):** while away, a local notification may say a horde was spotted. That horde waits at the map edge indefinitely. The player triggers it ("Engage") when ready for bonus loot. Ignoring it costs nothing — it's frozen.
- **Knowledge (research):** stored on the survivor group, not the base, so it carries to future bases. Phase 1 ships only a stub (3 items).
- **Speed:** pause, 1x, 2x.

## Phase 1 content
- **Buildings:** HQ (3×3), Shelter, Farm, Scavenger Post, Workshop, Barracks, Storage (2×2). Planned: Garden, Cannery, Hunting Lodge (2×2); Well, Rain Catcher, Chicken Coop, Lookout Post (1×1).
- **Defenses:** Wood Wall → Metal Wall, Watchtower (long range, single target), MG Nest (short range, rapid), Spike Trap (damage), Barbed Wire (slow). Upgrade levels 1–3.
- **Units:** Survivor (worker), Defender (trained at Barracks, can garrison towers / patrol).
- **Zombies:** Walker (baseline), Runner (fast, fragile), Brute (slow tank, wrecks walls).
- **Research stub:** Metal Fortification (unlocks metal walls), Marksmanship (+tower range), Agriculture (+farm yield).

## Future phases (design for, don't build)
- **Phase 2:** more maps; the highway as a route between bases; choose when to leave.
- **Phase 3:** Oregon Trail-style travel — pick what to bring, defend en route.
- **Phase 4:** take over occupied bases (outcome depends on supplies brought); attack mode.
- Owner's parked ideas (Lake Michigan setting, supply-run risk + mini-game, real-time weather, fortify-a-found-neighborhood): `docs/IDEAS.md`.
- Leaving a base is always optional. Playing one base forever is valid.
- Progress that carries over: Knowledge + what you pack. Timing must avoid "hours of play, then start over" feeling.

## Visual rules
Top-down, simple placeholder shapes first. Art spec: docs/graphics-spec-phase1.md. Missing art = colored shape with label.
Two views (owner, 2026-10-31): **isometric "Tropico style"** is the normal view; **top-down** is the building view (auto while placing/moving, or by a button). Built in milestone 1V; the simulation stays a square grid.
