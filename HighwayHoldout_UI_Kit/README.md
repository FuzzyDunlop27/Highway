# Highway Holdout — menu and inventory art

89 production PNG assets: 14 Blender inventory icons, 5 Blender building thumbnails, and 70 vector-derived surfaces, control states and glyphs. Editable Blender scenes, SVGs, generation scripts, design tokens and four layout previews are included.

## Use with Claude
Read `CLAUDE_HANDOFF.md` and `manifest.json`. Claude has already integrated these PNGs into the app HUD and build drawer on main; do not replace that integration blindly. Inventory and pause previews are visual proposals, not implemented screens.

## Files
- `png/`: transparent RGBA masters, imported as @2x.
- `source_blender/`: editable inventory props and building thumbnail scenes.
- `source_svg/`: editable surfaces and white template glyphs.
- `scripts/`: Blender rendering, SVG creation/export and Pillow preview generation.
- `previews/`: inventory (iPad), build drawer (iPhone), pause (iPhone), component states.
- `reference/`: individual asset metadata and diorama backdrop for previews.
- `manifest.json`: dimensions, @2x logical sizes, cap insets and SHA-256 checksums.
- `design_tokens.json`: palette, spacing and typography roles.

Blender models and vectors are newly authored geometry and shapes. Preview lettering uses the local Avenir Next font; font files are not bundled. Use system fonts in the app.
