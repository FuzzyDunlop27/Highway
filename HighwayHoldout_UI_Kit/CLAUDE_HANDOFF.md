# Claude implementation handoff

## Preserve existing integration
The app already imports this kit under `Art/UI` and uses `KitStyle.swift`. Reuse that implementation and keep all gameplay state changes behind Core Commands. No gameplay code was changed by this final packaging pass.

From the repository root, import only when updating assets:

```sh
python3 tools/import_art.py HighwayHoldout_UI_Kit/png --view ui
```

The importer preserves the PNG canvas and registers each master at @2x. Item masters are 512×512 (256×256 pt intrinsic); building cards are 512×384 (256×192 pt intrinsic). Give illustrations explicit display frames and use scaledToFit. Do not crop or stretch them. The old build reference logical sizes have been corrected to match this importer.

Use `manifest.json` cap_insets_pt for stretchable surfaces, e.g. Image("Art/UI/ui_panel_light").resizable(capInsets: EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24), resizingMode: .stretch). Individual controls have their own insets. Only ui_glyph_* assets are templates; tint them in code. Resource illustrations retain their original colors.

Overlay live text, quantities, prices, locks and progress in SwiftUI. Clip progress fills to the current fraction, including zero. Match pressed, selected, disabled and locked states to actual behavior; explain unavailable purchases. Keep targets at least 44 pt and honor safe areas and accessibility labels. Previews show composition, not fixed-size screen implementations.

## Scope
Food, scrap and survivor illustrations match current HUD concepts. Other props (fuel, ammo, medicine, water, battery, cloth, radio, knowledge, tools, wood, defender) are an art library, not a request to introduce resources or mechanics. Mockup counts, day, item descriptions and controls are illustrative. Inventory/storage and pause/settings screens still need actual implementation in their planned milestones.

Only five dedicated building menu thumbnails exist. Add exact-id thumbnails for metal wall and remaining structures, or use their existing isometric fallback. The generic ui_build_wall depicts wood and should not represent wall_metal.

## Reproduction
Blender scripts use Blender's Python; SVG export uses Node with sharp; previews use Python with Pillow and the macOS Avenir Next font. Existing source Blender scenes are included. No runtime dependency on Blender, Python, Node or Pillow is required by the game.
