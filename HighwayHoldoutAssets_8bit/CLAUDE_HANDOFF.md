# Claude handoff — Highway Holdout 8-bit edition

Copy this prompt when ready to integrate:

> Use this 57-asset 8-bit pack as an alternative art theme for Highway Holdout. Read this guide, manifest.json and the repository's AGENTS.md, STATUS.md, MAP.md and rendering-art feature note first. Preserve the existing Core/App architecture and gameplay. Integrate the supplied HighwayHoldout8bit.xcassets image sets through ArtRegistry using their existing snake_case ids. Use nearest-neighbor filtering, preserve each full transparent canvas and set sprite sizes explicitly from the world tile size. Assemble watchtowers and machine-gun nests with static bases and separately rotating tops. Avoid duplicate names from the v1 catalog. Build the real app and verify the art at gameplay scale. Do not rewrite game logic or add future-phase gameplay just because P3 graphics are available.

## Import route

This pack supplies exact finished canvases. Use `HighwayHoldout8bit.xcassets`, or merge its image sets into the game's catalog while preserving their contents. If the app already contains v1 images with the same names, replace those art image sets when choosing v2, or select a separate build configuration. Do not add two catalogs that define the same image resource names to the same target.

The current `tools/import_art.py` trims sprites, recenters visible art, and resizes with Lanczos. That behavior changes the intentional pixel grid, asymmetric weapon positions and relative unit sizes. Its name-validation `--dry-run` was run successfully, but use this pack's prepared catalog for the actual integration. Do not run the normal importer over these sprites unless it is first given an explicit preserve-canvas / nearest-neighbor mode.

Keep the original pack available for visual comparison. Generating this second pack did not choose a permanent art style or install it into the app.

## Dimensions and pixel scale

| Kind | Logical pixel canvas | Delivered PNG master |
|---|---|---|
| One world tile / ordinary unit | 32×32 | 128×128 |
| 2×2 building | 64×64 | 256×256 |
| HQ / 3×3 construction | 96×96 | 384×384 |
| 2×1 vehicle | 64×32 | 256×128 |
| Muzzle flash | 16×16 | 64×64 |
| Tracer | 16×4 | 64×16 |
| Goo / dust | 32×32 | 128×128 |
| HUD icons / level badge | 32×32 | 256×256 |
| App icon and layers | 128×128 | 1024×1024 |

In a scene whose tile side is `T`, a 128px world sprite is `T × T`, 256px building is `2T × 2T`, and the HQ is `3T × 3T`. Unit canvases remain a full tile; the figure occupies only part of it. Do not enlarge the visible figure to fill its canvas. Set UI size independently.

The catalog follows the repository's 32pt-per-tile convention: for ordinary world sprites, @1x is the logical pixel image, @2x is exactly doubled, and @3x exactly tripled. HUD images have a 64pt nominal size, using 2×/4×/6× their 32px logical drawings. App-icon source layers have a 256pt nominal size, using 2×/4×/6× their 128px logical drawings. The app icon itself is 1024×1024 and opaque.

## Preserve the pixel style

- SpriteKit: set each loaded texture's `filteringMode = .nearest` in ArtRegistry.
- SwiftUI HUD: use `.interpolation(.none)` and `.renderingMode(.original)` as appropriate.
- Retain exact aspect ratios and centered `(0.5, 0.5)` anchors. Do not trim transparent borders or add smoothing during atlas creation.
- Prefer camera scales that map logical pixels to integer display pixels when practical. Smooth camera zoom and arbitrary-angle rotation can produce uneven pixel widths or shimmering; assess that on-device. Do not change movement, targeting or rotation behavior just to force an art rule.
- Use the opaque terrain tiles without gaps. Terrain-to-terrain transition masks and road-corner tiles are not part of this set.
- All visible pixels use one of the original 16 palette colors. Dust uses checker gaps and solid colors instead of a blur. Code may fade entire effects over time.

```swift
let texture = SKTexture(imageNamed: "unit_defender")
texture.filteringMode = .nearest
let sprite = SKSpriteNode(texture: texture)
sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
sprite.size = CGSize(width: tileSide, height: tileSide)
```

Use the project's existing node factories and ArtRegistry. The code above only illustrates the texture setting and size convention.

## Facing and weapon layers

Units, zombies, vehicles and gun tops face east at zero rotation. Both members of each defense assembly use the same 128×128 canvas and center:

| Base, stays static | Top, rotates |
|---|---|
| `def_watchtower_base` | `def_watchtower_gunner` |
| `def_mg_nest_base` | `def_mg_nest_gun` |

In SpriteKit's y-up coordinates, use `atan2(dy, dx)` directly. The simulation uses y-down map coordinates, so preserve the renderer's established coordinate conversion. Keep rotation on the top node, not the base.

Updated approximate muzzle coordinates in the 128px PNG canvas, from the top-left:

| Sprite | Muzzle center | Center-relative SpriteKit offset, `s = T / 128` |
|---|---|---|
| `unit_defender` | `(104, 62)` | `(40s, 2s)` |
| `def_watchtower_gunner` | `(116, 62)` | `(52s, 2s)` |
| `def_mg_nest_gun` | `(116, 62)` | `(52s, 2s)` |

Attach flash/tracer effects in the rotating top's local coordinate system. Keep recoil, movement, bobbing, hit flashes and fades in code. There are no animation frame suffixes.

## States, HUD and app icon

Construction images preserve 2×2 and 3×3 footprints. Rubble is provided for 2×2 buildings. All upgrade levels share one image; use the game's existing number/tint badge system. Put the level number in the blank lower center of `ui_level_badge`, around `(128,146)` in its 256px master canvas.

The icon is `AppIcon` in the supplied catalog. Resolve any existing app-icon set name before merging. `app_icon_bg.png` plus `app_icon_fg.png` reconstructs the flattened `app_icon.png` exactly. The layers can be imported into Icon Composer; a `.icon` project is not included.

P3 icons and vehicles are art-only extras. Their presence does not authorize implementing future-phase features.

## Checks and remaining work

460 asset checks and 169 exact catalog-rendition checks pass. The catalog compiles with local Xcode for iPhone and iPad. The repository importer recognizes all 57 names in dry-run mode. Review images include 48px sprites, all-angle turret overlays and a composed scene.

The running game was not modified or tested with this pack. After integration, build the app, look for missing-art placeholders, verify footprint scale and turret alignment, and inspect both iPhone and iPad UI. Preserve Core and content tuning.
