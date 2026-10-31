# Highway Holdout asset pack

57 original static game assets drawn as editable vectors and exported as PNGs.
All 21 P1, 30 P2, and 6 optional P3 assets in the supplied specification are included.

## Start here

1. Open `previews/07_gameplay_art_mockup.png` to see the assets together.
2. Give Claude this folder (or the ZIP) and `CLAUDE_HANDOFF.md` along with your existing game project.
3. Use either the ready-made `HighwayHoldout.xcassets` catalog or the loose `png/` files. Their resource names match the specification.

| Folder / file | Contents |
|---|---|
| `png/` | 57 exact-size PNGs, including the app icon and its two layers |
| `HighwayHoldout.xcassets/` | Xcode image sets plus the `AppIcon` app icon set |
| `source_svg/` | 57 scalable, editable vector masters |
| `previews/` | Style anchor, category sheets, 48px review, seamless-tile review, turret rotations, example scene, app icon review |
| `CLAUDE_HANDOFF.md` | Copyable implementation prompt and integration details |
| `ASSET_INDEX.md` | Complete asset list with priority, size and description |
| `manifest.json` | Dimensions, priority, category, facing, centered anchors, opacity and SHA-256 hashes |
| `qa_report.json` | Automated validation results |
| `scripts/` | Deterministic source generation, PNG rendering and packaging |
| `reference/` | Original specification and local Xcode compilation log |

## Export contract

- PNG files have embedded sRGB profiles. Terrain, `app_icon`, and `app_icon_bg` are opaque. All other files have transparent backgrounds.
- World grid master: 128 pixels per tile. 2×2 buildings are 256×256, 3×3 buildings 384×384, vehicles 256×128. Effects retain their specified sizes. UI icons and the level badge are 256×256.
- Units, zombies, vehicles and rotating turret tops face east. The center of every canvas is the pivot; preserve transparent padding.
- No sprite includes text, numbers, animation frames, cast drop shadows, or gore. Preview labels and backgrounds are not part of the PNG sprites.
- SVG solid colors use the supplied 16-color palette. Antialiasing, transparency and the soft dust effect naturally produce intermediate pixel colors in PNGs.
- UI icon master sizes follow the spec. The six optional P3 assets use 256×256 for icons and 256×128 for vehicles.

## Verification

289 automated checks passed: filename coverage, dimensions, sRGB profile presence, opacity/transparency, padding, vector palette, matching terrain borders and exact app-icon layer reconstruction.

The Xcode catalog compiled successfully with the locally installed `actool` for iPhone and iPad, with iOS 17 as the validation deployment target. Its generated products included `Assets.car` and device icon renditions. The log is in `reference/xcode_asset_validation.txt`; local simulator-service warnings did not prevent compilation.

Preview sheets were visually reviewed, including units at 48×48, both rotating defense assemblies and the composed scene. These checks cover the asset pack. Integration and gameplay in your actual project still need testing.

## Editing or rebuilding

SVG files can be edited directly in a vector editor. If you edit an SVG directly, run only the rendering and packaging steps afterward; regenerating the drawings overwrites those edits.

Requirements: Python 3 with Pillow, and Node.js with `sharp`. The preview builder uses macOS Arial fonts; change `FONT` / `BOLD` in `scripts/package_assets.py` when using another platform.

```sh
# Recreate all vector drawings and metadata (overwrites SVG edits).
python3 scripts/build_assets.py

# Render exact-size sRGB PNGs from SVGs.
node scripts/render_assets.cjs

# Compose the final icon, create review sheets/catalog and run QA.
python3 scripts/package_assets.py
```

If `sharp` is installed outside the normal module search path, set `NODE_PATH` to that installation's `node_modules` directory. Use a Python interpreter with Pillow installed for the packaging step.

The final `app_icon.png` is composed from the two delivered PNG layers during packaging. This makes the delivered layers reconstruct the flattened icon exactly.

The supplied graphics spec contains no game balance, economy, persistence, navigation or combat implementation. This deliverable is the asset pack and integration handoff, not a runnable game.
