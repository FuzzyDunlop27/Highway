# Claude handoff — Highway Holdout

Give Claude the asset folder or ZIP and your existing Xcode project. Start with this prompt:

> Integrate the attached Highway Holdout asset pack into my existing iPhone/iPad town-builder and tower-defense game. Read CLAUDE_HANDOFF.md, manifest.json and the supplied graphics specification. Inspect the project before changing its renderer or asset lookup. Replace its colored-shape placeholders with the matching supplied PNGs. Keep the existing gameplay and architecture. Use the exact resource names, world footprints, centered pivots and east-facing rotation convention in this pack. Assemble watchtowers and machine-gun nests from separate static bases and rotating tops. Keep animation, shadows and level badges in code. Use the supplied HUD icons and app icon. Build the project and report any missing project-specific mappings. If I have not supplied the game source, ask for it before claiming to have integrated the assets.

## What is delivered

All 57 specified assets: 21 P1, 30 P2, and 6 optional P3. `ASSET_INDEX.md` enumerates them. `manifest.json` is the machine-readable source for dimensions, names and priority. The static asset set contains no spritesheets or animation frames.

Choose one import route:

1. **Xcode catalog:** add `HighwayHoldout.xcassets` to the app target, or merge its image sets into the existing catalog. Image resource names are the lowercase snake_case stems. The flattened app icon lives in the `AppIcon` app icon set. If the project already has an `AppIcon` set, replace its contents or rename one set and update the app-icon build setting; avoid duplicate resource names.
2. **Loose PNGs:** copy `png/` into the project's existing image-loading pipeline. Preserve basenames. If using a texture atlas, put these PNGs into the project's atlas and use its established loading code.

Do not import both versions as competing image resources. SVG masters, previews, build scripts, QA files and this guide are authoring material; they need not ship in the app.

## Canvas size and world size

The master image grid is **128 pixels per tile**. Pixel dimensions are source resolution, not a requirement to use 128 screen points per tile. If the renderer uses `T` scene units for one tile:

| Asset kind | Source canvas | Scene size |
|---|---|---|
| Terrain, decor, defenses, units, zombies | 128×128 | `T × T` |
| Standard buildings and 2×2 construction/rubble | 256×256 | `2T × 2T` |
| HQ and 3×3 construction | 384×384 | `3T × 3T` |
| Wreck, RV, pickup | 256×128 | `2T × T` |
| Goo and dust | 128×128 | `T × T` before effect animation |
| Muzzle flash | 64×64 | `0.5T × 0.5T` before effect tuning |
| Tracer | 64×16 | `0.5T × 0.125T` before effect tuning |
| HUD icons / badge | 256×256 | Set explicitly to the UI design size |

The main units occupy about half of their transparent canvas; the brute occupies substantially more. That empty space is intentional. **Do not trim images, auto-crop to visible bounds, or rescale units to fill their tile.** Transparent padding keeps pivots, relative unit sizes and the weapon overlays consistent.

The Xcode image sets supply one universal `1x` rendition at the exact master resolution. Set sprite sizes explicitly in the engine instead of deriving game units from UIKit's point size or device display scale. Regenerate higher-resolution renditions from the SVGs if a future camera zoom needs them.

Use logical footprints/collision shapes from the game, not the transparent bounds of each PNG. Keep an existing ground or placement anchor separate from the artwork's centered pivot when necessary.

## Facing, anchors and rotation

- Center anchor for every canvas: normalized `(0.5, 0.5)`.
- Units, zombies, vehicles and turret tops face **right/east** at zero rotation.
- Use pure overhead art for rotating objects. Buildings may show a small front wall; do not introduce perspective tilts to units.
- In SpriteKit's normal y-up scene coordinates, aim with `atan2(target.y - source.y, target.x - source.x)` directly. No 90° correction is needed.
- In a y-down rendering system, use its own angle convention and coordinate conversion.

SpriteKit loading example, if this is the existing engine:

```swift
import SpriteKit

let tileSide: CGFloat = 64 // Use the game's existing scale.
let texture = SKTexture(imageNamed: "unit_defender")
texture.filteringMode = .linear
let defender = SKSpriteNode(texture: texture)
defender.anchorPoint = CGPoint(x: 0.5, y: 0.5)
defender.size = CGSize(width: tileSide, height: tileSide)
defender.zRotation = atan2(target.y - defender.position.y,
                          target.x - defender.position.x)
```

`target` must be expressed in the same coordinate system as `defender.position`. The example is a loading convention, not a replacement for the game's existing entity system.

## Two-layer defenses

| Assembly | Static layer | Rotating top layer |
|---|---|---|
| Watchtower | `def_watchtower_base` | `def_watchtower_gunner` |
| Machine-gun nest | `def_mg_nest_base` | `def_mg_nest_gun` |

Each layer is a full 128×128 master canvas. Put both at the same center and give both size `T × T`. Rotate only the top. Avoid parenting the base beneath a rotating gun node. Apply a recoil translation to the gun layer or its child, without changing the assembly's center pivot.

Approximate muzzle attachment locations in source image coordinates, measured from the top-left:

| Layer | Muzzle pixel coordinate | Center-relative SpriteKit coordinate at scale `s = T / 128` |
|---|---|---|
| `unit_defender` | `(103, 62)` | `(39s, 2s)` |
| `def_watchtower_gunner` | `(111, 62)` | `(47s, 2s)` |
| `def_mg_nest_gun` | `(114, 64)` | `(50s, 0)` |

Attach effects to the rotating gun's local space, so the attachment rotates with the barrel. Tune flash size and recoil in the game. `fx_muzzle_flash` and `fx_tracer` are already horizontal and face east.

## Rendering and terrain

- Terrain is opaque; all four pixel boundaries match for repetitions of the same tile. Use `tile_asphalt_line` for a horizontal row of dashed highway lane markings.
- Texture filtering should be linear for the clean vector style. Use integer-aligned terrain quads where possible, prevent atlas texture bleeding with the renderer's normal extrusion/clamp strategy, and do not add gaps between tile quads.
- Grass/dirt/asphalt transitions are hard boundaries in this Phase 1 set. No road corners, autotile masks or blended transition tiles were specified.
- Suggested draw order: terrain, debris/ground traps/goo, buildings and defense bases, mobile units, rotating tops, temporary effects, world badges, HUD. Adapt this to the existing renderer's sorting rules.
- No cast shadows are baked into sprites. Add shadows in code if the current renderer uses them. Omit shadows for UI, goo, tracers and muzzle flashes.
- UI sprites are multicolor; use original image rendering, not template/tint-only rendering. For SwiftUI, use `.renderingMode(.original)` when appropriate.

## Building states and upgrades

- `bld_construction_2x2`: any 2×2 object under construction.
- `bld_construction_3x3`: HQ or another 3×3 object under construction.
- `bld_rubble_2x2`: collapsed 2×2 building. A separate destroyed 3×3 building is not specified; retain the game's fallback if needed.
- Upgrade levels use the same base art, with the game's existing tint and badge. There are no level-specific sprite variants.
- `ui_level_badge` is intentionally blank. Put the level number in its lower center, approximately `(128, 146)` in its 256×256 top-left image coordinates. Keep the upper chevron visible.

## Effects and animation

Movement, recoil, bobbing, hit flashes, effect scaling/fading and turret rotation remain code-driven. Dust is deliberately translucent and softly edged. Green goo is the hit/death effect; no blood sprites exist. Do not invent or search for nonexistent animation frame suffixes.

## App icon

- `app_icon.png`: opaque 1024×1024 flattened icon, ready for the supplied `AppIcon` set.
- `app_icon_bg.png`: opaque background layer.
- `app_icon_fg.png`: transparent foreground layer.
- Compositing foreground over background reconstructs the flattened PNG exactly.
- The icon is full-bleed with no baked rounded-corner mask.
- The two layers are source material for a layered icon workflow. This pack does not contain an Icon Composer `.icon` project; import the layers there if the project adopts that workflow. The provided Xcode catalog uses the flattened icon.

## Validation and remaining project work

The pack passed 289 automated checks and a local `actool` compilation for iPhone/iPad. The actual game project was not supplied, so no scene replacement, gameplay or device testing has occurred here.

After integration, build the real target, look for missing-texture placeholders, check the 1×1/2×2/3×3 footprints, aim both turret tops in all directions, verify UI sizing on iPhone and iPad, and inspect the app icon. Keep gameplay behavior unchanged unless separately requested.
