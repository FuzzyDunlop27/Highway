# Graphics Spec — Phase 1 (for ChatGPT)

**Working title:** Highway Holdout (placeholder name)
**Game:** iPhone/iPad zombie-apocalypse town builder + tower defense. You grow a small survivor town at a highway exit and fortify it against zombie hordes. Later phases add travel along the highway to new towns.
**Status:** The game runs on colored-shape placeholders. Any file delivered with the exact filename below drops in and replaces its placeholder, so partial delivery is fine.

---

## 1. Visual direction
- **Camera:** top-down. Buildings and terrain can show a *slight* 3/4 tilt (you see a sliver of the front face). Units, zombies, and rotating turret tops are **pure top-down (seen from directly above)** because the game rotates them in code.
- **Style:** clean stylized vector / flat-shaded, bold readable silhouettes, dark outline (~3 px at master size), simple cel shading, single light source from the **top-left**.
- **Mood:** dusty, overgrown, post-apocalyptic but *not grim*. Muted world, bright readable accents.
- **No gore.** Zombies are cartoonish. Hits produce green goo, never blood. Target App Store rating around 12+.
- **Readability rule:** every unit, defense, and zombie must still be identifiable when shrunk to 48×48 px.
- **Color coding:** player-built things lean warm (wood, orange, yellow); zombies lean sickly green/purple; danger is red.

## 2. Palette (stick to these hex codes)
| Use | Hex |
|---|---|
| Grass (dusty) | #6B7A4B |
| Dirt | #8A6F4E |
| Asphalt | #4A4D52 |
| Concrete | #9A9890 |
| Rubble | #7A746B |
| Player wood | #B9844A |
| Player metal | #7D8C96 |
| Accent orange | #F2A03D |
| Safety yellow | #F5C842 |
| Zombie skin | #8FAF6A |
| Zombie clothes | #5B5470 |
| Goo | #A6E04F |
| Danger red | #D9483B |
| UI dark | #1E2126 |
| UI light | #EDE6D6 |
| Outline | #1A1A1A |

## 3. Technical rules
- **Format:** PNG, sRGB, **transparent background** (except terrain tiles and app icon).
- **Grid:** 1 tile = **128×128 px** master. Footprints: 1×1 = 128×128, 2×2 = 256×256, 3×3 = 384×384, 2×1 = 256×128.
- Art fits **inside** its canvas, centered, with ~4 px padding. No art cut off at edges.
- **No baked drop shadows** (the game adds shadows). No text or numbers in sprites.
- **Facing:** units, zombies, and turret tops face **right (east)**.
- **Upgrade levels:** one sprite per object for now. The game shows level 1–3 with a badge and tint.
- **Animation:** none required for Phase 1. Movement, recoil, bob, and flashes are done in code. One image per asset.
- **Terrain tiles** must tile seamlessly on all four sides.
- **Naming:** lowercase snake_case, exactly as listed. Category prefixes: `tile_` `dec_` `bld_` `def_` `unit_` `zmb_` `fx_` `icon_` `ui_`.

## 4. Workflow (recommended)
1. Make the **style anchor sheet** first (prompt in section 6). Approve it.
2. For every asset after that, attach the anchor sheet and say "match this style and palette exactly."
3. **One asset per image.** Generate at the listed size or larger, keeping the exact aspect ratio.
4. Deliver in priority order: **P1** makes the game playable with real art, **P2** completes Phase 1, **P3** is for later phases.

## 5. Asset list

### Terrain & decor
| Filename | Size | Description | Pri |
|---|---|---|---|
| tile_grass | 128×128 | Dusty, patchy grass. Seamless. | P1 |
| tile_dirt | 128×128 | Packed dirt with small pebbles. Seamless. | P1 |
| tile_asphalt | 128×128 | Cracked highway asphalt, weeds in cracks. Seamless. | P1 |
| tile_asphalt_line | 128×128 | Same asphalt with a faded yellow dashed lane line running left-right. | P2 |
| tile_concrete | 128×128 | Cracked sidewalk / parking-lot concrete. Seamless. | P2 |
| dec_rubble | 128×128 | Transparent overlay: scattered bricks and debris. | P2 |
| dec_tree_dead | 128×128 | Leafless dead tree, top-down. | P2 |
| dec_car_wreck | 256×128 | Rusted abandoned sedan, top-down, facing right. | P2 |

### Buildings (player town)
| Filename | Size | Description | Pri |
|---|---|---|---|
| bld_hq | 384×384 | Command center: fortified old gas station with sandbags, radio antenna, warm lights. Must read as the heart of the town. | P1 |
| bld_shelter | 256×256 | Boarded-up house with a patched roof. Survivor housing. | P1 |
| bld_farm | 256×256 | Raised garden beds and a small makeshift greenhouse. Food. | P1 |
| bld_scavenger | 256×256 | Garage with a pickup truck and scrap piles. Gathers scrap. | P1 |
| bld_workshop | 256×256 | Open-front shed with a workbench, tools, and a welding glow. | P2 |
| bld_barracks | 256×256 | Canvas tent with a sandbag ring and a weapon rack. Trains defenders. | P2 |
| bld_storage | 256×256 | Two stacked shipping containers. Stores resources. | P2 |
| bld_construction_2x2 | 256×256 | Generic wooden scaffolding and a tarp. Shown while any 2×2 is being built. | P1 |
| bld_construction_3x3 | 384×384 | Same idea, 3×3. | P2 |
| bld_rubble_2x2 | 256×256 | Collapsed building remains (destroyed state). | P2 |

### Defenses
| Filename | Size | Description | Pri |
|---|---|---|---|
| def_wall_wood | 128×128 | Square block of planks and posts. Must look solid when many sit side by side in a line. | P1 |
| def_wall_metal | 128×128 | Upgraded wall: corrugated sheet metal and rebar. Same tiling rule. | P2 |
| def_watchtower_base | 128×128 | Wooden tower platform seen from above (static). | P1 |
| def_watchtower_gunner | 128×128 | Survivor with a long rifle, pure top-down, facing right. Overlaid on the base and rotated by code. | P1 |
| def_mg_nest_base | 128×128 | Ring of sandbags (static). | P2 |
| def_mg_nest_gun | 128×128 | Mounted machine gun, pure top-down, barrel facing right. Rotated by code. | P2 |
| def_spikes | 128×128 | Floor trap: sharpened stakes / nail boards. Low profile. | P2 |
| def_barbwire | 128×128 | Floor coil of barbed wire. Slows zombies. | P2 |

### Units
| Filename | Size | Description | Pri |
|---|---|---|---|
| unit_survivor | 128×128 | Civilian worker, backpack, pure top-down, facing right. Figure fills ~55% of canvas. | P1 |
| unit_defender | 128×128 | Armed survivor with a rifle, orange armband, facing right. ~55% of canvas. | P1 |

### Zombies
| Filename | Size | Description | Pri |
|---|---|---|---|
| zmb_walker | 128×128 | Basic shambling zombie, arms forward, facing right. ~55% of canvas. | P1 |
| zmb_runner | 128×128 | Lean, hunched, fast-looking zombie. ~50% of canvas. | P2 |
| zmb_brute | 128×128 | Huge hulking zombie. ~85% of canvas. | P2 |

### Effects
| Filename | Size | Description | Pri |
|---|---|---|---|
| fx_muzzle_flash | 64×64 | Small yellow-orange star burst, pointing right. | P2 |
| fx_tracer | 64×16 | Thin bright bullet streak, horizontal. | P2 |
| fx_goo_splat | 128×128 | Green goo splat (zombie hit/death). | P1 |
| fx_dust_puff | 128×128 | Soft dust cloud (building placed/destroyed). | P2 |

### UI icons (256×256, transparent, simple and bold)
| Filename | Description | Pri |
|---|---|---|
| icon_food | Stack of canned food | P1 |
| icon_scrap | Gear on a metal plate | P1 |
| icon_survivors | Person silhouette | P1 |
| icon_defender | Person with rifle silhouette | P2 |
| icon_build | Hammer | P1 |
| icon_upgrade | Upward chevron / arrow | P1 |
| icon_demolish | Crowbar | P2 |
| icon_horde_alert | Zombie hand rising from ground | P1 |
| icon_clock | Simple clock | P2 |
| icon_speed | Fast-forward double arrow | P2 |
| icon_pause | Pause bars | P2 |
| icon_settings | Gear | P2 |
| ui_level_badge | Small chevron badge, blank (game adds number) | P2 |

### App icon
| Filename | Size | Description | Pri |
|---|---|---|---|
| app_icon | 1024×1024 | Opaque, no text. A lit watchtower or fortified gas station at dusk with zombie silhouettes at the edge. | P2 |
| app_icon_bg / app_icon_fg | 1024×1024 each | The same icon split into a background layer and a transparent foreground layer, for Apple's layered icon format. | P2 |

### Later phases (P3 — only if you have time)
`icon_medicine`, `icon_fuel`, `icon_ammo`, `icon_knowledge` (book), `veh_rv` (256×128 armored RV, top-down, facing right), `veh_pickup` (256×128).

## 6. Style anchor prompt (do this first)
> Create a single style reference sheet for a top-down 2D mobile game, zombie apocalypse town-builder. Clean stylized vector art, flat cel shading, ~3px dark outlines, light from top-left, no gore, no text. Use only this palette: [paste palette from section 2]. Show on a neutral background: one grass tile, one asphalt tile, a boarded-up house (slight 3/4 top-down), a wooden wall block, a wooden watchtower seen from above, a survivor with a rifle seen from directly above facing right, and a cartoony green zombie seen from directly above facing right. Everything must be readable at small sizes on a phone.

## 7. Honest limits to plan around
- Image generators drift in style across separate images. Re-attach the anchor sheet every time.
- Exact pixel sizes and transparency are not always respected. Expect to crop/resize. We'll run a script that trims and resizes into the game's asset folders.
- Multi-frame animation sheets rarely come out consistent. That's why Phase 1 needs none.
