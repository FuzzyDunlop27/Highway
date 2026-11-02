# IDEAS — owner's future ideas (parked, NOT approved to build)

Nothing here is in `BUILD-QUEUE.md`. Agents: do not build these; "design for, don't build."
When the owner picks one, turn it into a chunk in `BUILD-QUEUE.md` and a `DECISIONS.md` entry.

## 1. Setting: Lake Michigan shoreline (added 2026-11-01)
- Maps/towns sit along the shore of Lake Michigan, because settlements want freshwater. The map progression "takes you around" the lake: Wisconsin, Illinois, Indiana, Michigan.
- Named stops: **Chicago** and **Holland (MI)** at minimum.
- Fits Phase 2 ("more maps; the highway as a route between bases", `GAME-DESIGN.md`). Lake access could feed a water/fishing resource later.
- Open: how many stops, order (clockwise/counter-clockwise), real vs. inspired layouts, art/landmark needs (new CC0 assets, D-036).

## 2. Supply runs: risk, then a mini-game (added 2026-11-01)
- **Step 1 (logic only):** runs can lose people. Today runs are risk-free (`docs/features/scavenging-research.md`, "Not built: risk of losses"). Needs balance decisions: loss chance per run type, whether defenders/gear lower it, permanent death vs. knocked out (see STATUS open question on permanent death).
- **Step 2 (later):** the run becomes something you play, like Oregon Trail hunting: a short real-time mini-game whose result sets the haul and losses. Auto-resolve option for players who skip it.
- **Population balance (added 2026-11-01):** population becomes something you manage. Too few people and you can't staff buildings, defend, or survive losses; too many and food, housing and safety strain. Run losses (above) are one drain, so you must replace people to stay healthy.
  - Today: survivors arrive on a timer while housing is free and food covers `foodCost`; housing caps the count; food upkeep is 0 (`docs/features/economy.md`). Turning on `foodUpkeepPerSurvivorPerMin` is the natural "too many" pressure (already a STATUS open question).
  - Possible levers (all numbers in `Content/*.json`): upkeep per head, housing/crowding penalties (unrest, slower arrivals, disease), a visible "ideal population" gauge in the HUD, and arrivals that slow or stop when you are over capacity.
  - **Decided 2026-11-01 (D-042, chunk CORE-005):** running out of food/water makes survivors leave (no deaths); a successful town attracts people faster (town appeal) and held hordes bring newcomers. Rules: `docs/GAME-RULES.md` §3–4. Still open: crowding penalties and an "ideal population" gauge.
- Core stays deterministic: the App plays the mini-game and sends the result to Core as a `Command` with a seeded outcome. Don't put mini-game timing in Core.

## 3. Real-time weather and season (added 2026-11-01)
- Weather follows the real calendar/time: December = snow, summer = sun/storms, etc.
- Rule from AGENTS.md applies: Core never reads the wall clock. The App reads the date, sends it in as input (like the offline-time input), and Core only sees a season/weather value.
- Likely mostly visual (RealityKit particles, lighting, sky). Optional gameplay: snow slows zombies, winter lowers farm output. Any such numbers go in `Content/*.json`.
- Open: gameplay effects or cosmetic only? Real location weather (needs network, conflicts with "offline") vs. date-only seasons (offline-safe, recommended).

## 4. Neighborhood start: fortify a place you found (added 2026-11-01)
- **Partly scheduled (2026-11-01, D-046):** taking over existing houses is now tickets CORE-011/APP-007 (`docs/BUILD-QUEUE.md`). The buildable-area mask and pre-placed choke points are still ideas.
- Maps feel like a real neighborhood (houses, streets, fences). You can only build inside your claimed area, with the fortress already there.
- Some defense work is already done: conveniently placed barriers/buildings (walls, parked vehicles, fences, sturdy houses) form natural choke points. You are **fortifying** a found location, not starting from scratch.
- Design implications: pre-placed, non-demolishable (or costly to remove) blocking pieces per map; a buildable-area mask (Core map data: `Content/` JSON); zombie paths must still reach the base through the gaps. Fits the existing wall/pathing rules (`docs/features/pathing.md`, `construction.md`) and the CC0 modular-building art direction (D-036).
- Open: size of the buildable area, whether it can grow (claim adjacent lots), how pre-placed pieces get damaged/repaired.

## 5. Horde variety and rewards for winning (added 2026-11-01)
- **Variety:** hordes shouldn't always be huge. Mix in small ones (just a couple of zombies), medium ones, and the occasional big one, so the player gets breathing room and big hordes feel like events.
- **Reward:** winning must feel like winning, not just surviving. Candidate rewards (owner unsure which; could combine):
  - **Experience / town level:** held hordes earn XP that levels the town, unlocking perks, research, or buildings.
  - **Zombie drops:** valuables from kills (scrap, parts, rare items), possibly rarer from tougher types like Brutes.
  - **Morale / survivors:** a win brings new arrivals or a morale boost (ties to the population balance idea).
  - **Bigger payoff for bigger hordes** so risk is rewarded.
- Today (`docs/features/hordes.md`): hordes are sized from a threat budget that scales with spent value and day (`Content/hordes.json` `budget`, `composition`). A held horde pays `completionBonus` and kills give `loot` (`Content/zombies.json`); there is no XP and no small-horde variation. Likely starting point: a random size roll per horde from the seeded RNG (kept deterministic), plus a reward table in `Content/*.json`.
- Open: which reward type(s)? Should small hordes still pay anything? Does the player see a "victory" summary after each held horde?

## How these connect
The shoreline (1) gives each map a setting, the neighborhood start (4) is how each map plays, supply runs (2) is how you leave the base, and weather (3) is the skin over all of it.

## 6. Deeper town life, Tropico-style (added 2026-11-01)
- After chunk RND-007 (survivors visibly walking and working, looks only): named survivors you can follow, needs/happiness, day/night with sleeping, survivors who can be bitten, morale from held hordes (ties to §5).
- Each of these adds Core state + a save migration, so each is its own decision. Design notes: `docs/plans/town-life-plan.md` §8.
