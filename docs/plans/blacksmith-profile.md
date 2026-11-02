# Character profile — weathered medieval blacksmith, age 45

**Draft implementation (2026-11-01, MOD-007):** a clothed 9,209-triangle review model now exists;
model bundle and four-angle previews are in the `blacksmith_review/` folder linked from
`tools/makehuman/README.md`. Preserves the maximum-height source, adds fitted clothes, apron,
short hair/beard and head modifiers. This brief remains the art target: exact scars/calluses,
rolled sleeves, period-specific collar/boots, detailed likeness, posture and animation are not yet reproduced.

Owner-requested MakeHuman trial, 2026-11-01. Art direction reference only: it does not change
Highway Holdout's modern zombie setting or add a medieval role to Core. For the game, the same
body can become a Workshop mechanic by changing the clothes. Town-life context: `town-life-plan.md` §3b.

## Identity and silhouette

**Working name:** Harlan, a right-handed village blacksmith, male, 45. A tall, lean, heavily worked
craftsman with a broad upper back and powerful forearms. His strength reads as years of lifting
and hammering: thick tendons, strong grip, a solid chest and moderately developed legs.
Avoid competition-bodybuilder symmetry and an exaggerated six-pack.

**Base settings:** male 1.00; age 45 years; muscle 0.80; weight 0.20; height 1.00 (maximum).
Script: `tools/makehuman/generate_blacksmith.py`. Let **H** be its measured bare-body height.
Keep that height for this trial rather than silently scaling him to a conventional 185–190 cm.
These settings are exact inputs; the measurements below are art targets for the manual pass,
not additional verified MakeHuman slider mappings. Preserve the three requested body sliders.

## Proportions to reproduce

Use an orthographic front and side view, neutral expression, bare feet, before adding clothes.
Ratios are approximate outside-surface targets; measure against H to reproduce across programs.

| Feature | Modeling target |
|---|---|
| Overall proportion | About 7.5 heads tall; head height ~0.133H |
| Shoulder width | ~0.25H across deltoids; upper back broader than hips |
| Hip width | ~0.18H; waist ~0.16H across in front view |
| Chest / waist / hip circumference | Roughly 0.57H / 0.44H / 0.51H; fitted clothing must not inflate these |
| Upper arm / forearm circumference | ~0.18H / 0.16H at widest points; right forearm ~3% thicker than left |
| Hand / foot length | ~0.11H / 0.15H; broad palms, thick knuckles, blunt fingertips |
| Body surface | Lean flanks, small lower-belly softness, shallow abdominal definition; prominent forearm tendons |

Make the asymmetry in a sculpt/shape pass only if it survives retargeting. Strong forearms, shoulder
mass and the apron silhouette matter more than fine veins at town-camera distance.

## Face and head

- **Shape:** long rectangular head, broad square jaw. Cheekbone width = 1.00 reference unit;
  jaw width ~0.90, temple width ~0.94. Chin broad and blunt, with a shallow central cleft.
- **Brow:** heavy supraorbital ridge, forehead tilted back about 8° from vertical in side view;
  two horizontal forehead furrows and a short paired crease between the eyebrows.
- **Eyes:** deep-set grey-green eyes, slightly hooded upper lids, outer corners down about 3°.
  One visible eye width between inner corners. Lower lids puffy with subtle dark circles;
  three short crow's-foot lines on each side. Expression alert and tired, mouth relaxed.
- **Nose:** broad bridge with a low healed bump in profile. Nose length ~0.30 of face length
  (hairline to chin); nostril width about the inner-eye distance. Tip broad, tilted slightly down.
  Nasal tip offset ~2 mm toward his left on the full-size model.
- **Mouth:** mouth width ~1.45× nostril width; thin upper lip, lower lip about 1.5× its visible height.
  Pronounced nasolabial folds; left mouth corner about 2 mm lower, without a permanent sneer.
- **Ears:** modestly protruding, upper edges level with brows, lobes near the nose base.
  Small notch in the rim of the left ear, ~3 mm deep; no jewelry.

## Skin, hair and work marks

Warm light-to-medium skin with a sun-darkened face and neck; mottled redness over cheeks and
nose, lighter skin beneath the collar. Slightly rough pores, cracked knuckles, callused palms.
Add small healed pale burn marks on the outside of both forearms, each ~5–15 mm; a thin
35 mm diagonal scar above the right eyebrow, breaking a small section of brow hair.
Soot is uneven dirt on fingers, wrists and cheek, not a uniform black overlay.

Hair: dark brown with ~35% grey at temples, receding corners; short rough crop, 25–35 mm long
on top, 8–12 mm on sides. Beard: 12–18 mm, square outline, slightly longer on chin, ~40% grey.
Use close-fitting hair/beard geometry or texture cards appropriate to the size budget; no loose strands.

## Posture and animation

**Neutral rigging model:** symmetrical T- or A-pose, straight pelvis/spine, relaxed open hands,
empty hands and separated limbs; no hammer baked into the mesh. Keep the neutral shape reusable.

**In-character idle:** feet about 0.15H apart, toes 8° outward, knees flexed ~4°. Upper thoracic
spine leans forward ~6°, head projects ~0.015H ahead of neutral with chin tucked ~3°.
Scapulae slightly protracted; right shoulder ~0.005H lower. Weight about 60% over the left leg.
Hands hang heavy with fingers gently curved. This is an animation pose, not a permanent bent skeleton.

**At the anvil:** hip hinge ~15–20°, knees ~8°, left foot half a foot-length forward. Right arm
swings the hammer while the left steadies work with tongs. Keep hammer/tongs separate hand props.
For the game trial, select/retarget a hammering clip after rigging rather than building a new animation system.

## Clothes and modeling handoff

Medieval reference outfit: coarse undyed linen shirt, rolled sleeves just below elbows; worn
dark-brown leather apron from upper chest to just above knees, split at the lower centre for leg
clearance; faded charcoal wool trousers; ankle-high brown leather boots with rounded toes.
Wide simple belt with a small pouch. No armour, fantasy spikes, cape or large loose accessories.
Keep apron panels close to the thighs and weight them to legs, or shorten to mid-thigh if retargeting clips.

For Highway Holdout, swap to a faded work shirt, leather workshop apron, work trousers and steel-toe
boots; retain the face, age and build. This is a proposed costume adaptation, not an automatic cast change.

**Acceptance:** front/side/back views agree; actual height is logged; neutral mesh rigs cleanly;
apron clears walking and hammering; ≤ ~10,000 triangles with eyes/hair/clothes included, a single
atlas ≤ 1024 px (512 px in game), target ≤ 3 MB animated. Retopology/decimation and atlas work
are still required if the MakeHuman export exceeds those budgets. No game artId assigned yet.
