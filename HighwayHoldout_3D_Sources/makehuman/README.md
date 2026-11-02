# MakeHuman character review models

These are committed, self-contained **static review assets**, not app-bundled or animated game characters.
They use bundled CC0 MakeHuman system assets; licence text is [LICENSE.ASSETS.md](LICENSE.ASSETS.md).
No Mixamo assets or animations are included in these committed packages. Owner-provided
`sv-farmer_*.fbx` motion downloads in this working folder are ignored/local under D-038.
They were not altered, used in the static builds, or validated for rig compatibility here.

| Character | Town-life role | Triangles | Clothed height | FBX size | Material / atlas |
|---|---|---:|---:|---:|---|
| Farmer | Adult woman survivor working at Farm | 9,196 | 1.61135 m | 1,405,212 bytes | 1 / 1024 px; 512 px copy supplied |
| Blacksmith | Workshop character art trial | 9,209 | 2.47072 m | 1,216,428 bytes | 1 / 1024 px; 512 px copy supplied |

Open each `*_draft.blend` directly in Blender (atlas packed), import `*_draft.fbx` (atlas embedded),
or use the self-contained `*_draft.glb`. The PNGs show front, three-quarter, side and back views.
`draft_report.json` records actual generation/build settings and clean FBX reimport checks.
`source/` preserves editable MakeHuman `.mhm` recipes and generation metadata; those need the
official MakeHuman system assets installed to open, but the finished models do not.

## Farmer specification

From `docs/plans/town-life-plan.md` §3b: a farmer in faded denim overalls, a grey shirt, work boots
and short brown hair. Female body, age 40 years, average height/weight/muscle sliders (.5),
neutral A-pose and empty hands. MakeHuman bare-body height is 158.67095 cm; boots/hair bring
the full export to 1.61135 m. This is distinct from the blacksmith's extreme-height body.
The optional bandana and hand props are omitted; no props are fused into the model.

Source assets: `middleage_asian_female`, `male_worksuit01`, `shoes02`, `short02`, and default eyes.
The workwear proxy uses the common hm08 mesh and is refitted to the female body in MakeHuman.
Diffuse-only shaders replace imported specular/normal wiring before baking; hair uses a simple
brown material. Faded clothing seams/pockets and worn boots come from the CC0 diffuse maps.

## Rebuild

1. Install the official MakeHuman source/system assets; see `tools/makehuman/README.md`.
2. Run `tools/makehuman/generate_farmer.py` in MakeHuman's scripting plugin. It backs up the current
   human, generates/fits the farmer, saves an MHM/FBX/report, and prints its new export folder.
3. Run Blender:

   ```sh
   /Applications/Blender.app/Contents/MacOS/Blender --background \
     --python tools/blender/build_farmer_draft.py -- \
     /path/to/farmer_source.fbx /path/to/farmer-review-output
   ```

4. For the blacksmith, run `tools/makehuman/dress_blacksmith.py` (reads the committed base MHM;
   set `HIGHWAY_REPO` when the checkout is elsewhere), then use `build_blacksmith_draft.py`.
5. Both builders use `character_review.py` for the atlas, portable exports, four renders and
   clean FBX reimport verification. Build outputs can go to a scratch folder, then replace reviewed assets.

## Verification and limits

Both actual exports were reopened into clean Blender 5.2.3 scenes: finite geometry, identical
triangle count, matching height within 1 mm, one material, no missing images. All eight views
were visually reviewed. Both GLBs were also imported separately; see final handoff verification.
The packed Blender files are checked for an embedded atlas and one mesh/material.

These are unrigged and unanimated. Deformation, finger/joint preservation after decimation,
work motions, clothing clearance, the full animated ≤3 MB budget, game scale/front conversion,
512 px game export, RealityKit integration and real-device performance remain to be tested.
Do not treat the static mesh budget as proof that full chunk 3M-2 is finished.
The blacksmith retains the maximum-height trial and draft historical costume/detail limitations
recorded in `tools/makehuman/README.md`. Farmer skin/hand detail is a first art pass.
