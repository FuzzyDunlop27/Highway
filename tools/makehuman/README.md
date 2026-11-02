# MakeHuman blacksmith trial — chunk 3M-2MH

This is body-generation tooling for the owner-requested trial, not the full 3M-2 game integration.
The separate art brief is `docs/plans/blacksmith-profile.md`.

## Committed review assets and second character (3M-2MH-F)

The portable models now live in `HighwayHoldout_3D_Sources/makehuman/` in the repository,
including the existing blacksmith and the spec's **adult woman farmer**. See that folder's
README for licences, source recipes, build commands and limitations. Local export folders below
remain provenance/working copies; they are no longer the only place to find the finished assets.

Farmer: age 40, female, muscle/weight/height sliders .5; bare height 158.67095 cm,
clothed height 1.61135 m; short brown hair, grey T-shirt, faded denim overalls and worn boots.
`generate_farmer.py` runs in MakeHuman; `build_farmer_draft.py` builds the final review model.
Actual output is 9,196 triangles, one material/1024 px atlas (+512 px copy), 1,405,212-byte FBX
and 1,390,852-byte GLB. Four angles reviewed. `check_character_package.py` opens the packed
Blender files and imports isolated copies of both characters' FBX/GLB, confirming the counts,
height and textures without hidden dependencies. No rig/animation/game integration is implied.
The optional bandana/hand props were not added.

## Clothed review draft delivered (3M-2MH-L, 2026-11-01)

Open `/Users/rick/Documents/MakeHuman/v1py3/exports/highway-blacksmith/blacksmith_review/`.
`blacksmith_review_bundle.zip` packages the model, previews, atlas, report and CC0 licence.

- `blacksmith_draft.blend` (packed atlas), `.fbx` (embedded atlas), `.glb` (self-contained).
- `blacksmith_front.png`, `_threequarter.png`, `_side.png`, `_back.png`; all four reviewed.
- `blacksmith_albedo.png` = one 1024 px atlas; `_512.png` is the later game-export copy.
- **9,209 triangles**, one mesh/material; FBX **1,216,604 bytes**, GLB **1,217,008 bytes**.
  Clean FBX reimport confirms triangle count, finite geometry, one material, no missing images
  and matching exported height (about 2.47072 m including boots/hair).
- Fitted source: `../blacksmith_dressed_dlczxnwx/` contains MHM/FBX and `dressed_source.json`.
  Muscle .8, weight .2 and height 1.0 retained; saved age is 44.99998 due to MHM serialization.
  Face shapes change measured bare-body height slightly to 243.94306 cm. Original base remains untouched.
- Look: squarer jaw/aged head modifier, middle-aged skin warmed by tint, short greying hair/beard,
  linen-colored collared shirt, charcoal trousers, brown shoes, split leather apron and belt.
  Garments use bundled CC0 MakeHuman assets, re-fitted to this exact body; apron/beard authored here.
- Build: run `tools/makehuman/dress_blacksmith.py` inside MakeHuman, then Blender:
  `--background --python tools/blender/build_blacksmith_draft.py -- <dressed.fbx> <output_folder>`.
  Helpers `blacksmith_geometry.py` and shared `character_review.py` assemble/bake/export/render/verify.
- Visual iteration fixed apron clipping, imported skin shaders and a jagged shirt/trouser cutoff.
  Original diffuse maps were rebuilt into explicit skin/eye shaders before baking; imported custom normals remain disabled.

**Review draft, not final production art:** long sleeves remain (not rolled); shirt collar and shoes are adapted
modern asset silhouettes; exact eyebrow scar/burns/hand calluses, micro-wrinkles and precise grey-hair percentages
are not reproduced. Beard is a low-detail shell; no custom work pose, rig, animation, deformation test,
animation-time apron clearance, game conversion or real-phone performance check. The 512 px atlas is supplied
but exports currently use 1024 px; the ≤3 MB animated budget is not yet verified. Next is the 3M-2 rigging/
motion trial and art refinement, not starting the whole cast from scratch.

## Installed on Rick's Mac (2026-11-01)

- Open `/Users/rick/Applications/MakeHuman.app` in Finder. It is installed and was opened to the modeling screen.
- This is the official source revision below, reporting **1.3.0 alpha**, with a local Mac launcher and the official icon.
  The running macOS process/menu is named **Python**. Close that window normally before opening another copy.
- Runtime: `/Users/rick/Applications/MakeHuman-runtime/`; isolated packages in `venv/`.
  Homebrew installed Python 3.11.18 and Git LFS 3.8.1; game dependencies were not changed.
  Packages: NumPy 1.26.4, PyQt5 5.15.11, PyOpenGL 3.1.10 (dependency versions recorded in the environment).
- Official [system assets](https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html)
  installed from its CC0 ZIP into the runtime's `source/makehuman/data/`.
  The README's old Git asset repository returned 404; the official asset-pack mirror was used instead.
- User files/logs/exports: `/Users/rick/Documents/MakeHuman/v1py3/`.
  `scripts/generate_blacksmith.py` links to this repo's script, so it stays current.
- Scripting and FBX plugins are enabled; startup log confirms both loaded and ends with `Loading done`.
  `pip check` passes. Installation size is ~965 MB including the downloaded asset ZIP, plus Homebrew prerequisites.
- Provenance and asset ZIP checksum: `/Users/rick/Applications/MakeHuman-runtime/INSTALLATION.json`.
  Installation itself did not run the export; the subsequent live test below now has.

## Real export verified (2026-11-01, chunk 3M-2MH-V)

Actual files: `/Users/rick/Documents/MakeHuman/v1py3/exports/highway-blacksmith/blacksmith_hog2rxxs/`.
Contains `blacksmith_base.fbx`, editable `.mhm`, `generation_report.json`, copied textures,
imported `blacksmith_base.blend`, `blender_verification.json` and `blacksmith_base_preview.png`.

- Ran the repo script in the live MakeHuman scripting editor; success status and output files confirmed.
- All requested values applied: male, age 45, muscle .80, weight .20, maximum-height slider 1.00.
- MakeHuman height **244.38591 cm**; Blender 5.2.3 imported height **2.44385925 m** (error < 0.001 mm).
  Maximum height really is an unusually tall body; no silent rescaling was applied.
- Binary FBX **831,468 bytes**; two meshes (body + eyes), **28,796 triangles**, no armature;
  no unresolved image paths. Lowest point about -3.76 mm, within the checker tolerance but
  final game conversion must set feet exactly to ground.
- Imported custom normals caused severe visible surface facets. Verified the defect in a render,
  then imported with **`use_custom_normals=False`**; recomputed mesh normals give a clean preview.
  Use that importer option for this FBX in future conversion; the raw source FBX is preserved.
- Checker: `tools/blender/check_makehuman_fbx.py`. Run with Blender `--background --python <checker> -- <fbx>`.
  It verifies finite geometry, measured height and ground tolerance, reports budget/images, saves
  the imported source `.blend`, then renders a neutral clay review. Preview was visually inspected.
- **Not game-ready:** triangle count exceeds the ~10,000 target; no weathered face/skin, hair/beard,
  garments, rig or animations. Next in 3M-2: apply the chosen look, optimize/atlas while preserving
  deformation, rig/download clips, and only then integrate. Base-body preview is not a finished blacksmith.

## Run in MakeHuman

1. Open MakeHuman and save any current character. The script replaces the visible body with a fresh base.
2. In **Settings → Plugins**, enable `7_scripting` and `9_export_fbx`; restart if changed.
3. Open **Utilities → Scripting**, click **Load**, and choose `generate_blacksmith.py` in this folder.
4. Open **Utilities → Execute**, then click **Execute**. Do not run this with Terminal Python or Blender Python.
5. The status bar/log prints the output folder: MakeHuman's user **exports/highway-blacksmith/blacksmith_<unique suffix>/**.
   Each run makes a separate folder and preserves earlier exports. To change the root, edit `output_root` inside the function.

Expected outputs: `blacksmith_base.fbx` (binary, unrigged), editable `blacksmith_base.mhm`,
`generation_report.json` and any copied skin textures in `textures/`. Keep them together.
Failed runs may leave an incomplete folder; the success report is written only after FBX checks pass.

## What it makes

Adult male, age **45 years**, muscle **0.80**, weight **0.20**, height **1.00**.
These are MakeHuman slider values, not body-fat percentage, kilograms or a promised height in metres.
Maximum height is the slider endpoint for this body; use `measured_height_cm` in the report as the actual height.
Age uses `setAgeYears(45)` because the normalized age slider is nonlinear.
The reset removes previous shaping, garments, hair and poses. The result uses the default skin and rest pose, with no rig.
The weathering, face sculpt, hair, clothing and work stance in the brief need a separate art pass.

## Verify the actual export

- Confirm the report says muscle 0.8, weight 0.2, height 1.0, age 45, and a positive measured height.
- In Blender, import the FBX with normal unit conversion. Compare the bare-body height in metres to
  `measured_height_cm / 100`; do this before decimation, rigging or game scaling. Feet should be on the ground.
- Inspect face, hands, skin textures and all sides. The script checks the FBX signature, not mesh quality or texture completeness.
- Save a separate dressed/sculpted version. Keep its neutral rest pose for rigging; add the stoop in animation.
- Then use the existing 3M-2 route: owner rigs/downloads clips in Mixamo; integration work generalizes
  `tools/blender/export_characters.py` for the new human. That exporter currently supports the walker, not arbitrary humans.
- Before acceptance: ≤ ~10,000 triangles, atlas ≤ 1024 px before export / 512 px in game,
  target ≤ 3 MB including animations; 0.41 tiles per metre, feet at origin, front +X after game conversion.
  A default MakeHuman mesh is a source asset, not an assumed phone-ready model.

## API evidence and limits

Checked against upstream `master` revision `a8bc2d54ff0ac92e78ff71431b1023eda42bf482` on 2026-11-01:

- [Human setters, age conversion and reset](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/apps/human.py)
- [Scripting editor and execution tabs](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/plugins/7_scripting.py)
- [FBX config](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/plugins/9_export_fbx/__init__.py),
  [export function](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/plugins/9_export_fbx/mh2fbx.py),
  [binary unit metadata](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/plugins/9_export_fbx/fbx_binary.py)

This uses internal MakeHuman APIs, including the app's reset function, not a stable standalone Python SDK.
MakeHuman is installed in the user Applications folder; live base-body generation and Blender import are now
verified above. Mixamo rigging and game integration remain unverified. Its private environment is separate from the game.
Bundled assets have a [CC0 asset licence](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.ASSETS.md);
record the individual licences of any added community hair, clothes or textures. Mixamo-derived files retain D-038's local-only rule.
