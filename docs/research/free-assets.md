# Free 3D / UI asset sources (research, 2026-11-01)

**Status:** research only. Nothing downloaded, nothing changed in the game. Licenses below come from
vendor pages and blog roundups; re-check each asset's own license page before shipping.

## Direction (owner, 2026-11-01)
Go **realistic / gritty**, not cartoony. Current art mixes cartoony buildings with realistic Mixamo
zombies, so one side has to change; redoing the world with free realistic assets is the cheaper side.
Owner is open to redoing all the graphics.

## Candidate sources
| Source | License | Style | Notes |
|---|---|---|---|
| [Kenney Retro Urban Kit](https://kenney.nl/assets/retro-urban-kit) | CC0 | Muted, worn low-poly | 120 files: houses, shops, fences, roads, vans. Gritty-ish, still blocky. |
| [Poly Haven (e.g. Hidden Alley collection)](https://polyhaven.com/collections/hidden_alley) | CC0 | Realistic, high detail | 39 props. Sample: Covered Car = ~13K tris, 50 MB at 4K textures. Needs trimming. |
| [Quaternius Zombie Apocalypse Kit](https://quaternius.com/packs/zombieapocalypsekit.html) | CC0 | Cartoony | Vehicles/props may still be usable; characters don't fit the realistic direction. |
| [Quaternius Downtown City MegaKit](https://quaternius.com/packs/downtowncitymegakit.html) | CC0 | Realistic city blocks | 315 modular models (glTF/Blend/FBX). Worth testing for streets. |
| Kenney Survival Kit / City Kit | CC0 | Bright, toy-like | Too cartoony; skip. |
| Majadroid 3D Apocalyptic Building / City | CC0 | Ruined skyscrapers | Free pack of 7 ruins plus billboards. |
| AI image-to-3D (TRELLIS 2, MIT) | MIT | Varies | Self-host; for signature pieces only. Hunyuan3D has region limits. Meshy/Tripo free tiers: license unclear. |
| UI: Kenney UI Pack (CC0), game-icons.net (CC BY 3.0, credit required) | see left | Flat | For HUD/menu icons. |

## Performance concerns (realistic assets)
- Poly Haven downloads default to 4K textures (tens of MB). Use 1K; estimate 1-3 MB per prop (untested).
- Aim for roughly 2K-5K triangles per prop (to be confirmed by measuring on a real device).
- Reuse one model for many placements instead of loading copies.
- Downloads arrive as glTF/FBX; need conversion to USDZ (Apple Reality Converter or a script).

## Proposed next steps (not started)
1. **Spike:** 4-6 assets (a Poly Haven prop, a Retro Urban Kit building, a Quaternius vehicle) converted to
   USDZ, rendered next to the Mixamo zombie; judge the look and measure frame rate on a device.
2. Record a DECISIONS entry ("realistic style, free CC0 assets") and rewrite `graphics-spec-phase1.md`
   (it still describes the retired flat top-down style).
3. Write a conversion script (glTF/FBX to USDZ, shrink textures).
4. Replace the world in waves: terrain/roads, buildings, props/defenses.
5. Keep an asset license table (source + license per asset).

## Spike results (2026-11-01, simulator)
**How to open:** long-press the horde chip → Debug → 3D spike → More → **Free assets**. Or launch with
`-spike3DWalkers 35 -spike3DScene free`. Screenshots: `docs/plans/spike-free-assets/`.

**Rebuild the models:** `/Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/free_assets_spike_export.py -- App/Spike3D/FreeAssets`.
Sources and USDZ are git-ignored (like the Mixamo walker), so each Mac re-downloads and re-converts.
Models stay in real metres; the spike shrinks them by `freeAssets.metresToTiles` = 0.41 in `spike3d.json` so a 1.8 m person matches the walker.

| Asset (Poly Haven, CC0, 1K) | Triangles | Real size (m) | USDZ |
|---|---|---|---|
| covered_car | 12,592 | 1.8 × 4.4 × 1.4 | 2.6 MB |
| concrete_road_barrier_02 | 23,822 | 1.6 × 0.4 × 1.1 | 3.6 MB |
| metal_trash_can (2 cans) | 13,960 | 1.9 × 0.6 × 0.9 | 5.3 MB |
| Barrel_01 | 2,682 | 0.6 × 0.6 × 0.9 | 0.8 MB |
| old_tyre | 2,880 | 0.6 × 0.2 × 0.6 | 2.3 MB |

- **Look:** reads clearly realistic and matches the Mixamo zombies far better than the cartoony study models. Scale looks right.
- **Speed (iPhone 18 Pro simulator, RealityView, shadows on):** 60 fps at 35 and at 100 walkers, worst frame 17 ms.
  Loading the 14 placements took about 1.1 s on the main thread. Not yet measured on the real phone.
- **Size is the real cost:** ~14.6 MB for 5 props, mostly textures (a 1-tyre file is 2.3 MB). A full world needs shared
  texture sets or 512 px textures; decide that in the conversion script (step 3).
| Kenney Retro Urban Kit (CC0) | Triangles | Size | USDZ |
|---|---|---|---|
| 2-cell shop (wall-a-door + wall-a-window + 2 roofs) | 112 | 1 cell ≈ 3 m | 0.1 MB |
| truck-grey-cargo, detail-dumpster-open | 12, 24 | cells | 0.02-0.03 MB |

| Quaternius Downtown City MegaKit (CC0) | Triangles | Real size (m) | USDZ |
|---|---|---|---|
| Building_Small_1 (prebuilt 5-storey block) | 18,344 | 12.5 × 14.5 × 17 | 19.6 MB |

- **Buildings (added after the owner downloaded the zips):**
  - **Kenney** has no finished buildings, only 1-cell modular pieces (walls, roofs, windows) plus props and trucks. It's tiny (a few hundred triangles, 128 px textures) and reads as a tidy, slightly toy-like brick shop next to the realistic props: workable, but less gritty. Its glTF uses unlit materials; the converter now rebuilds them as normal textured materials (`fix_unlit`).
  - **Quaternius** buildings are real city blocks: the "small" one is 5 storeys, about 5 × 6 × 7 tiles at our scale (the HQ is 3 × 3). Looks right with the zombies, but far too big for a base building as-is and **19.6 MB** for one model. Use its modular pieces (a 1–2 storey shop) rather than the prebuilt blocks.
- **Speed with buildings:** still 60 fps at 100 walkers (simulator). Loading the scene on the main thread rose to ~3 s, mostly the Quaternius block (the game's ModelRegistry already loads in the background).
- **Total spike size:** 33 MB of USDZ for 11 models. Texture budget is the main problem to solve before replacing the world.
- **Screenshots:** `01-closeup-35-walkers.png`, `02-100-walkers.png`, `03-kenney-vs-polyhaven.png`, `04-quaternius-building.png`.
- **Suggested direction (owner decides):** Poly Haven for props, Quaternius modular pieces for buildings (assembled into small 2-storey shapes), shared/smaller textures; Kenney only as a fallback. Still to do: measure on the real phone.

## Change log
- 2026-11-01: first research pass.
- 2026-11-01: spike: 5 Poly Haven props as USDZ in a "Free assets" scene of the DEBUG 3D spike; 60 fps at 100 walkers (simulator). Buildings pending manual download.
- 2026-11-01: added Kenney (modular shop, truck, dumpster) and a Quaternius 5-storey block; Kenney unlit materials fixed in the converter; still 60 fps at 100 walkers.
