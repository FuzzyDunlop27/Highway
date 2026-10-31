# Zombie detail pass — 2026-10-31

Editable Blender geometry, not generated image concepts. Walker: worn jacket, loose tie and patching. Runner: sports jersey, race bib, wrist wrapping and trainers. Brute: industrial bib, belt, reinforced knees and safety helmet. Shared sunken eyes, uneven teeth, cheekbones and muted skin materials.

`comparison.png`: original row above, updated row below. `before/`: nine original sprites for comparison/recovery. Updated sprites live in `../png/zmb_*.png` and are imported into the app. The Python model sources remain the editable source of truth.

Validation: all nine RGBA images have unclipped bounds and matching canvas dimensions within each type. Import completed without warnings. Check an isometric horde in the simulator, including turns, overlapping crowds and zoomed-out readability. No new gameplay types or per-spawn costume variants were added.
