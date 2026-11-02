# Buildings & look overhaul plan (owner request 2026-11-01, D-046)

_Owner asked for four things: (1) placing buildings is too hard, they take a lot of room for tiny buildings; (2) show people actually building, like Tropico; (3) building models in the new (Chicago) style; (4) a plan for better textures — everything looks flat — and a first map that looks like **Roscoe Village, Chicago** (owner's map screenshot: Damen / Wolcott / Ravenswood × Cornelia / Newport / Roscoe, alleys mid-block, Metra embankment along Ravenswood). Chunks: track **H** (buildings) and track **Q** (look quality) in `docs/BUILD-QUEUE.md`._

## 1. Why placing feels hard (diagnosis)
- **1 tile ≈ 2.44 m** (models exported at 0.41 tiles per metre, D-037). A 1.8 m person is ~0.7 tile.
- Six of the seven buildings are **2 × 2 tiles = 4.9 × 4.9 m of ground**, but the models are a **4 × 4 m shell** (D-037 note), so each one looks smaller than the space it blocks, with a visible empty rim.
- The starting fence ring is 9 × 7 tiles. Inside: 35 tiles, the HQ takes 9 and the watchtower 1. Room for about **two** more 2 × 2 buildings before the player must rebuild the fence.
- Junk and wrecks (`dec_*`) dragged against the compound block tiles too.
- Placing: the ghost opens at the screen centre (often on a blocked tile), there is no rotate, and nothing helps you find a spot that fits.

## 2. The fix (chunks CORE-010, APP-006)
**Smaller footprints** (numbers in `buildings.json`, first guesses, owner can change):

| Building | Now | New | What it looks like at that size |
|---|---|---|---|
| HQ | 3 × 3 | 3 × 3 (unchanged) | the landmark: fortified corner brick building |
| Shelter | 2 × 2 | **2 × 1** | converted garage / row of cots under a tarp |
| Farm | 2 × 2 | 2 × 2 (unchanged) | raised beds + window-frame cold frames |
| Scavenger | 2 × 2 | **2 × 1** | gear shed with a parked cargo bike / van nose |
| Workshop | 2 × 2 | **2 × 1** | corrugated shed with a workbench under an awning |
| Barracks | 2 × 2 | **2 × 1** | sandbagged brick shed, rifle rack |
| Storage | 2 × 2 | **2 × 1** | shipping container (a 20 ft container is ~6 × 2.4 m ≈ 2.5 × 1 tiles) |

- **Rotation:** 2 × 1 buildings can be turned (tap Rotate). Core stores `facing`; the footprint turns with it. Save migration: old 2 × 2 buildings keep their origin and shrink to the new footprint facing south (always fits, frees space).
- **Bigger starting compound:** fence ring from 9 × 7 to **13 × 9** (JSON `startingLayout`; both maps, the validator wants them to match). More fence = more HP for the first hordes; check the day-1–5 hordes still hurt (balance note in `balance.md`).
- **Spot finder:** `GameLoop.suggestSpot(defId:facing:near:)` = nearest valid origin to a tile (Core, tested). The ghost opens there instead of the screen centre; if nothing fits nearby the bar says "No room — expand your fence".
- **Models fill their footprint:** interim (APP-006) the App scales each model to its footprint minus a small margin (`presentation.json reality3d.fitToFootprint`, look only); the real fix is the new models in MOD-010.

**Considered, not chosen now:** a finer grid (half-size tiles, 80 × 60). It fixes the problem at the root but touches every map, footprint, speed, range, path and save; ~3× the work of CORE-010. Revisit if CORE-010 isn't enough.

## 3. People building things, Tropico-style (chunk RND-008)
Today a build job just shows a construction-site box and a progress bar; the builder is a number. Tropico shows workers walking to the site, carrying materials, hammering, and the building rising in stages. Look only — Core stays the truth (`Base.jobs`, `buildersPerJob`), like town life (D-031, RND-007).
- **Stages from job progress:** 0–25 % cleared lot + stakes + material pile, 25–60 % foundation + frame/scaffold, 60–99 % walls up with scaffold, 100 % finished model with a short dust puff. Per-building stage models from MOD-010 (`<artId>_stage1…3`), fallback to the generic `bld_construction_*`.
- **Builders:** for each running job, `buildersPerJob` survivors walk from the HQ (or Storage) to the site, carrying a plank/sack the first trip, then stand at work spots around the footprint and loop hammer / saw / carry. A queued job with no free builder shows a "waiting for builder" icon. Repairs and rubble rebuilds use the same picture. Upgrades: scaffold around the old model.
- **When the job ends** builders walk back; when a horde warning comes they run inside (same rule as RND-007).
- Planning (who stands where, walk targets) is seeded pure math in `Core/Sources/HoldoutCore/Presentation/` with tests, like `CharacterMotion3D`.
- Needs hammer + carry clips on the farmer (owner Mixamo download, `OWNER-DOWNLOADS.md` Part C).
- This takes the "builders walk to construction sites" part out of RND-007, so RND-007 is smaller.

## 4. Building models in the new style (chunk MOD-010)
"New style" = the Chicago neighborhood look from D-044 (yellow/red brick two-flats, storefronts, garages), not the Quaternius downtown kit pieces the MOD-001 buildings used. Player buildings should look like **survivors took over and fortified neighborhood structures**: brick and limestone, boarded windows, plywood, corrugated metal, tarps, sandbags, chain-link, string lights.
- One recipe per building in `tools/blender/recipes_buildings.py`, shaped to the new footprints (§2), front facing the way `facing` says.
- **Three looks per building (L1 / L2 / L3)**: L1 scrappy (tarps, pallets), L2 repaired (new plywood, a second storey or annex), L3 fortified (metal sheeting, rooftop lookout, lights). `buildings.json` gets an art id per level (`sprite` per level).
- **Construction stages** (`_stage1…3`, §3) and **rubble** per footprint size (2 × 1, 2 × 2, 3 × 3).
- Uses the shared **Chicago trim sheet** from TXT-003 (§5) so 30+ models stay small; ≤ 3,000 triangles each; size table.
- Review sheets (4 angles) beside the neighborhood houses so the owner can approve the style before all 7 are done: do the HQ + Shelter first, stop for a yes.

## 5. Why everything looks flat, and how to fix it (chunks TXT-002, TXT-003)
Causes, biggest first:
1. **No sky lighting.** One dusk sun + one flat fill light. Real scenes get most of their light from the sky. RealityKit supports **image-based lighting** (an HDRI sky image lights every surface and adds reflections): `ImageBasedLightComponent` + `ImageBasedLightReceiverComponent`. Single biggest win, costs one ~1–2 MB image.
2. **No surface detail.** D-037 dropped normal and roughness maps and shrank textures to 512 px to save size. Without normal maps, brick, asphalt and grass are flat pictures; without roughness, everything has the same dull shine. Bring them back where they show (ground, building walls) — budget-checked.
3. **No contact shadows / ambient occlusion.** Corners, eaves, and where walls meet the ground stay as bright as open surfaces. Fix: **bake AO in Blender** into the model textures (free at run time), plus RealityKit's `GroundingShadowComponent` under buildings and characters (check iOS 18 support in the spike).
4. **Same tile repeated everywhere.** No variation, no edges, no curbs. Fix: per-tile seeded variation (rotate/tint), soft blends, **curbs and parkways**, plus **decals**: oil stains, cracks, puddles, manhole covers, crosswalks, leaf piles, painted parking lines.
5. **Bare streets.** Roscoe Village is defined by **big parkway trees** in rows along every street, alleys with garages and wooden power poles, and **back porches** (the wooden stair-porches on the back of Chicago two-flats). We have none. Trees = MOD-009 (needs owner downloads Part B); porches, poles, wires, fences, gangways = TXT-003.
6. **Colour grade.** The dusk sun tints everything orange-brown. An overcast or late-afternoon HDRI with a cooler fill gives the grey-sky-and-brick Chicago feel. Post effects (tone curve, bloom, fog): check in the TXT-002 spike what RealityKit on iOS 18 allows with a virtual camera; don't promise it.

**Professional trick we'll use: a trim sheet.** One shared 2048 px texture set (colour + normal + roughness + AO) holding strips of Chicago materials — yellow brick, red brick, limestone lintels and sills, cornice, wood siding, window frames, boarded plywood, corrugated metal, tar roof, chain-link. Every building maps its faces onto strips of it. Result: much higher detail than per-model 512 px textures, and *smaller* total size, because all buildings share one set. Plus a few tiling ground materials (asphalt, sidewalk, grass, dirt) with normal maps.

**Where the textures come from (owner, Part E in `OWNER-DOWNLOADS.md`):**
- **Poly Haven** (CC0, already used): 1 HDRI sky + PBR texture sets (brick, asphalt, sidewalk, roofing, plywood, corrugated metal). Download colour + normal (GL) + roughness + AO.
- **ambientCG.com** (CC0, same kind of PBR sets; good for brick, roofing, metal).
- **Your own photos (optional, the most "Roscoe" option):** take straight-on daylight photos of brick walls, limestone, alley asphalt, back porches on an overcast day; the agent turns them into tileable textures. Only photos you took yourself; no business signs or logos.
- Not needed / avoid: paid marketplaces, anything "free for personal use only", AI-generated textures with unclear licence.

## 6. The Roscoe Village map (chunk MAP-001)
A new map `phase1_roscoe` replaces `phase1_chicago` for new games (old saves keep their map, like D-044).
- **Real blocks are big.** Damen→Wolcott is ~200 m; Cornelia→Newport ~100 m. Today's map is 40 × 30 tiles ≈ 98 × 73 m, about half of one block. Plan: grow to about **64 × 48 tiles (~156 × 117 m)** and show the **Wolcott & Newport / Roscoe corner**: Roscoe St (shops, taverns) along the south, Newport (one-way, residential) through the middle, the **alley** between them, Wolcott running north–south, and a **big brick loft building** (like the old pencil factory) as a landmark, with the **Metra embankment** (green, raised tracks) as the east map edge zombies can't cross. The full screenshot area would be ~600 × 400 m — too big for a phone; the rest is suggested at the map edge.
- Compound starts on a vacant lot off the alley; houses are two-flats/greystones/frame cottages on narrow lots with parkway trees, gangways and back porches.
- Generic names for businesses (no real tavern/shop names or logos); real street names are fine on map labels only if the owner wants them.
- A bigger map changes horde walk times and balance: zombies' route length, warning time and spawn edges get checked (`ChicagoMapTests`-style tests: every spawn edge reaches the HQ).

## 8. Taking over neighborhood houses (chunks CORE-011, APP-007 — owner said yes 2026-11-01)
Instead of only building on empty lots, survivors can **claim an existing house, garage or shop on the map** and turn it into one of their buildings. It fits Roscoe Village (the neighborhood is already full of sturdy brick buildings) and saves room. Grew out of `IDEAS.md` §4 "fortify a place you found".
- **Which ones:** map decorations marked `claimable` in the map JSON, with the uses each allows (e.g. two-flat → Shelter or Barracks; garage → Workshop or Storage; storefront → Storage or Scavenger; cottage → Shelter; tavern → Shelter). Wrecks, poles, trees, junk stay plain decorations.
- **How:** tap the house → "Take over" → pick a use → it becomes a normal build job (builders, slot, queue). Cost = that building's level-1 cost × `claim.costPct` (first guess 60 %: walls already stand) + a clean-out time (`claim.buildSecondsPct`, first guess 75 %). Only houses **next to or inside your fence / within `claim.maxDistanceTiles` of a building you own** can be claimed, so you grow outward block by block.
- **What it becomes:** a real building of that type, with the **house's footprint** (often 3 × 4 or 4 × 3) and its own art (the house model + fortified dressing: boarded windows, sandbags, tarp). Houses are sturdier: HP × `claim.hpMultiplier` (first guess 1.5). Big houses give a bonus where it makes sense: Shelter housing scales with footprint area (`claim.housingPerTile`), Storage cap likewise. Upgrades L2/L3 work as normal.
- **Zombies:** an unclaimed house blocks paths like today; a claimed one is a building zombies can attack and turn to rubble. Rubble can be rebuilt (rubble rules) — the house is not lost forever.
- **Demolish:** a claimed house can be given up (back to an empty, boarded-up decoration? or a cleared lot) — first guess: becomes a cleared lot (buildable), refund per `demolishRefundPct`.
- **Save:** building stores `claimedFrom` (decoration id/position); the save lists claimed decorations so the map hides the original one. Migration bumps the version.
- **Not in scope:** claiming defenses from the map, looting a house for one-off scrap (could be a later "search the house" idea), interiors.

## 7. Order and dependencies
- **CORE-010** Core: compact footprints, rotation, bigger compound, spot finder — ready now.
- **APP-006** App: easier placing (Rotate, auto spot, fit-to-footprint) — needs CORE-010.
- **TXT-002** App: lighting & materials spike (HDRI, normal/roughness back, grounding shadows, fps + size table) — needs owner Part E (an HDRI + 3 texture sets is enough to start).
- **TXT-003** Art: Chicago trim sheet + restyled neighborhood houses, porches, poles, curbs, decals — needs TXT-002.
- **MOD-010** Art: player building models (L1–L3, stages, rubble) in the new style — needs CORE-010 and TXT-003.
- **RND-008** App: builders at work — needs MOD-010, APP-006 and the farmer's hammer/carry clips (Part C).
- **MAP-001** Core + Art: Roscoe Village map — needs TXT-003, CORE-010, and trees from MOD-009.
- **CORE-011** Core: take over neighborhood houses — needs CORE-010.
- **APP-007** App + art: "Take over" button and fortified house looks — needs CORE-011, APP-006 and MOD-010 (the fortified dressing style). MAP-001 should mark its houses `claimable`.
