# OWNER-DOWNLOADS — files only you can fetch (chunk OWN-001)

_No agent needs to open a browser for these. You find them, drop them in the folder shown, tick the box, and tell the agent "OWN-001 part N done". Keep the original file names. Everything here stays out of git (public repo) except where noted._

**General rules:** free licence only (CC0 or Mixamo's free terms); never paste account passwords into chat; if an item can't be found, pick the closest match and write what you picked in `NOTES.txt` inside that folder. Prefer **1K** resolution (2K only if the 1K looks blurry on a phone).

Root folder for everything below: `HighwayHoldout_3D_Sources/`

## Part A — Terrain textures (needed by chunk TXT-001) · Poly Haven → Textures
Download each as **Diffuse (JPG), 1K**. Also grab **Normal (GL) JPG, 1K** and **Roughness JPG, 1K** if offered (agents may skip them; cheap to have). Folder: `terrain/<short-name>/`, one folder per texture, original file names.

| Short name | What to look for (search terms) | Used for |
|---|---|---|
| `grass_green` | short green/yellowish lawn grass, even, no flowers (search "grass") | main grass tile |
| `grass_dry` | dry, patchy, dead-looking grass | grass near road, variety |
| `dirt_ground` | bare brown dirt/mud, small stones ("dirt", "ground", "mud") | dirt tile, paths |
| `gravel` | grey gravel/small stones ("gravel") | shoulder, yard edges |
| `asphalt_cracked` | worn grey road asphalt with cracks ("asphalt", "road") | road tile |
| `asphalt_markings` | asphalt with a painted line, if it exists (else skip; we draw the line ourselves) | road centre line |
| `concrete_cracked` | weathered/cracked concrete slab ("concrete", "pavement") | concrete tile, sidewalks |
| `concrete_clean` | plain grey concrete, lightly worn | parking/yard slabs |
Need 6–8 textures total; 5 are required (`grass_green`, `dirt_ground`, `asphalt_cracked`, `concrete_cracked`, `gravel`).

## Part B — Foliage & scatter models (needed by chunk MOD-009) · Poly Haven → Models
Format: **glTF (.gltf + .bin + textures folder), 1K**, same as the props you already downloaded. Folder: `free-assets/polyhaven/<asset-name>/` (same place as `covered_car`, so the existing export scripts find them). Low-poly versions preferred; skip anything over ~20 MB.

| Item | What to look for | How many |
|---|---|---|
| Live trees | 2–3 different deciduous trees (oak/birch/maple style), medium size ("tree") | 2–3 |
| Dead/bare trees | 1–2 leafless or dead trees (we have one dead trunk already) | 1–2 |
| Conifer | 1 pine/spruce, optional | 0–1 |
| Bushes | 2–3 shrubs/bushes of different shapes ("bush", "shrub") | 2–3 |
| Grass clumps / weeds | tall-grass tufts, weeds, dandelions, fern ("grass", "weed", "plant") | 3–4 |
| Rocks | small and medium rocks/boulders ("rock", "boulder") | 2–3 |
| Roadside junk | tyre pile, litter, broken fence, traffic cone, pothole decal if any | 3–5, optional |
If Poly Haven lacks something (e.g. conifer), **Quaternius "Ultimate Nature"** or **Kenney Nature Kit** (both CC0, glTF/GLB) are fine substitutes; put them in `free-assets/quaternius/` or `free-assets/kenney/`.

## Part C — Mixamo humans (needed by chunk MOD-003; **hammering + carry-box walk on the farmer are also needed by chunk RND-008, builders at work**) · mixamo.com (free Adobe account)
**Update 2026-11-01:** the MakeHuman farmer is already rigged in Mixamo and in the game (`sv_farmer`, used for all humans). So the live need is **more clips for the farmer first**: Idle, carry-box walk, hammering, digging/planting (plus a rifle prop later). The 4 extra civilians and a separate defender below are optional "more looks" until the owner wants them.
Settings for every download: **Format FBX Binary (.fbx), Skin: With Skin, 30 fps, Keyframe Reduction: none**, and tick **In Place** wherever the animation offers it. Folder: `mixamo-humans/<artId>/`. Full table and rationale: `docs/plans/town-life-plan.md` §3.

| Folder | Character | Animations to download (each its own FBX; first one "With Skin", the rest can be "Without Skin") |
|---|---|---|
| `unit_defender` | a soldier/SWAT/survivalist with a rifle look | rifle idle · rifle walk · rifle run · rifle aim + fire (shooting) · hit reaction |
| `civ_a` | worker in overalls / male civilian | idle · walk · run (panic) · carry box walk · hammering · digging/planting · pick up from ground · talking/gesturing |
| `civ_b` | woman in a jacket | same animation list as `civ_a` |
| `civ_c` | older man | same list |
| `civ_d` | young woman | same list |
If a character is large (>~6 MB as FBX) pick another. Sitting is optional. Names don't matter; keep Mixamo's own.

## Part D — Small task props (chunk RND-007), only if you find them quickly · Poly Haven / Quaternius / Kenney
glTF or GLB, 1K: wooden crate (have), cloth/grain sack, hoe or shovel, hammer, bucket, wheelbarrow. Folder: `free-assets/polyhaven/<asset-name>/`. Skip any you can't find; the animation reads fine without a prop.

## Part E — Better-looking materials (needed by chunk TXT-002, then TXT-003) · Poly Haven + ambientCG.com
Why: today's textures are small and have no bump/shine maps, so everything looks flat (plan: `docs/plans/buildings-and-look-plan.md` §5). For each texture download **Colour/Diffuse + Normal (GL) + Roughness + AO**, JPG, **2K** (the agent shrinks them). Folder: `materials/<short-name>/`, original file names. CC0 only.

| Short name | Search terms | Used for |
|---|---|---|
| `hdri_sky` | Poly Haven **HDRIs**: "overcast" or "cloudy" city/suburb, late afternoon; download **2K .hdr** | lights the whole map (biggest single improvement) — **start here** |
| `asphalt` | "asphalt", "road" — worn grey, fine cracks | streets, alley (we still have none) — required for TXT-002 |
| `brick_red` | "red brick", "brick wall" — Chicago common brick, slightly dirty | houses, HQ — required for TXT-002 |
| `sidewalk` | "concrete pavement", "sidewalk", "concrete tiles" with joints | sidewalks — required for TXT-002 |
| `brick_yellow` | "yellow brick", "cream brick" | two-flats |
| `limestone` | "limestone", "sandstone blocks", "stone wall" (light grey/beige) | greystone fronts, lintels |
| `wood_siding` | "wood siding", "painted planks" | frame cottages, back porches |
| `plywood` | "plywood" | boarded windows, survivor repairs |
| `metal_corrugated` | "corrugated metal", "rusty metal sheet" | sheds, garages, fortifications |
| `roofing` | "roofing", "asphalt shingles", "tar roof" | roofs |

**Optional, most "Roscoe" option — your own photos:** on an overcast day, take straight-on photos (phone held flat, no shadows) of a red brick wall, a yellow brick wall, limestone trim, an alley's asphalt and a wooden back porch. Put them in `materials/my-photos/`. The agent turns them into tileable textures. Only photos you took; skip business signs and logos.

## Checklist (tick as you go)
- [ ] A: terrain textures (5 required + up to 3 extra) → `terrain/`
- [ ] B: foliage and scatter → `free-assets/…`
- [ ] C: Mixamo humans → `mixamo-humans/`
- [ ] D: task props (optional)
- [ ] E: HDRI sky + material textures (HDRI, asphalt, red brick, sidewalk required) → `materials/`
After each part: tell the agent which part and "OWN-001 part A done". The agent only checks that the files exist, opens the licence notes, and starts the chunk that needs them.
