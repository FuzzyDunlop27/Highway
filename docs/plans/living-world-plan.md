# Living-world plan: making the 2D isometric game feel alive

_Status: proposal for the owner to choose from. Docs only, nothing built yet. Written 2026-10-31._
_A sister plan, `docs/plans/3d-rendering-plan.md`, covers a 3D-rendering alternative. Compare the two, then pick._

## The idea in one paragraph

Tropico on iOS feels alive because something is always moving: people walk to work, the light changes, smoke rises, the camera glides, and the music tells you when trouble is coming. We can get most of that feeling in the **current SpriteKit 2D isometric engine**, without a rewrite, using seven small build chunks. Almost all of the work is in `App/` (drawing, sound, camera). The game rules in `Core/` barely change, so these chunks can run alongside the gameplay track (1B, 2B, 2C…) without getting in its way.

## Decisions only you can make

1. **Is time of day a game rule, or just a look?** _My recommendation: just a look, but steered by the horde clock._
   - **Option A, recommended: visual only, steered by the horde clock.** The App already knows from Core when the next horde arrives. We paint the sky so that *day* fills the quiet time between hordes, *dusk* starts when the warning arrows appear (60 s before), *night* lasts the whole fight, and *dawn* breaks when the horde is held. Hordes then always arrive at dusk, with no new rules, no save change, no balance change, and no clash with the "time away" catch-up planned in 4B. The only downside is that a "day" is as long as a horde cycle (about 10 minutes), not a fixed length.
   - **Option B: a real game rule in Core.** Core keeps a day clock that affects things like slower farms at night or stronger hordes after dark. It adds depth, but it needs a save migration, new tests, a balance pass and careful work on offline catch-up. Better saved for Phase 2, once the core loop is fun.
   - **Option C: the phone's real clock.** Not recommended: playing at lunchtime would always be daytime, and it fights with time-away rules.
2. **Music in Phase 1?** `PHASE1-PLAN.md` currently lists music under "What NOT to build". Sound effects are already allowed (1E "simple sound hooks"). Chunk 2S needs you to lift that rule.
3. **Where the audio comes from** (see chunk 1S). It doesn't need a library: Apple's own built-in sound framework is enough. You choose the source of the sound files and approve each licence.
4. **When to fit these in.** The current milestone is 1C (gameplay). These chunks are outside it, so under the "phase discipline" rule in `AGENTS.md` they need your OK to be added to `BUILD-QUEUE.md`. You can run them between gameplay chunks or alongside them.
5. **Auto camera focus when a horde starts:** on by default? (Recommended: yes. Any touch cancels it, and an off switch can go into the 5B settings screen later.)

## Labels

New tracks, so the labels don't clash with the existing A (zombie art), B (gameplay), C (side work) and the 1D art pilot:
**K** = camera, **N** = day/night, **F** = effects and weather, **U** = survivors, **S** = sound.
Each chunk's "Needs" line overrides the strict wave rule (as 2A already does), so a wave-2 chunk here waits only for what it names, not for all of track B.

**Heads-up for every chunk:** `App/Rendering/GameScene.swift` is already at the ~250-line limit. New work goes into new files (for example `AtmosphereLayer.swift`) that GameScene only creates and updates. Several of these chunks touch GameScene, so run them one at a time, not in parallel. All look-and-feel numbers (colours, glide friction, particle rates, volumes) go in JSON (`Content/presentation.json` or a new App-only `Content/atmosphere.json` / `Content/audio.json`), never in Swift.

---

## The chunks

### 1K: Smooth camera (size S)
- **Goal:** the camera glides and settles like Tropico's instead of stopping dead, and it shows you where a horde is coming from.
- **Needs:** nothing.
- **Scope (App only):** in `App/Input/CameraController.swift`, (1) **inertia:** when you lift your finger, the map keeps sliding at your swipe speed and slows to a stop (friction from JSON); (2) **soft edges:** dragging past the map edge stretches a little, then eases back instead of hitting a wall; (3) **eased pinch zoom** that settles smoothly at the zoom limits; (4) **horde focus shot:** when a horde starts, the camera eases over (about 1.2 s) to frame the spawn edge(s), then hands control back. It is skipped if you touched the screen in the last few seconds, and any touch cancels it. All numbers go in a new `camera` block in `presentation.json`. Works in both views and in the wall tool's two-finger pan.
- **Do NOT build:** cinematic cut-scenes, a camera that follows zombies, a settings toggle (later, in 5B), screen shake on every shot.
- **Exit check:** in the simulator, a flick glides and stops smoothly; overscrolling springs back; a debug "Horde now" pans to the spawn edge; touching mid-pan stops it instantly; placing buildings and drawing walls still work; app builds; 60 fps.
- **Start prompt:** "Implement chunk 1K (smooth camera) from docs/plans/living-world-plan.md: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/input.md, and the 1K section only."

### 1N: Day and night (size M)
- **Goal:** the town is bright by day, turns orange at dusk as the warning arrows appear, goes dark blue at night with lit windows and lamps while you fight, and warms up at dawn when you hold.
- **Needs:** nothing, but **decision 1 must be made first** (this chunk assumes Option A).
- **Scope (App only):** a new `DayNightLayer.swift` turns Core's horde clock (countdown, warning, active, held) into a time of day. It draws one screen-sized colour tint on the camera with smooth colour changes between keyframes listed in `atmosphere.json`. **Night lights:** soft additive glow sprites (pre-made "light blobs", not SpriteKit's real-time lights) on building windows, lamp posts, tower muzzles and the HQ. Light positions are data in `presentation.json` (`assets.<id>.lights`), so no code changes when art changes. The UI (HUD, menus) is never tinted. During a fight the night is lit just enough that zombies stay readable.
- **Do NOT build:** Core changes, production or horde changes at night (that is Option B), SpriteKit `SKLightNode` or normal maps, moon or star art.
- **Exit check:** watch one full cycle in the simulator (use 2x speed or the debug menu): day → dusk exactly when arrows appear → night through the horde → dawn on "Held!". Zombies and health bars stay readable at night. Pausing freezes the light. Switching to top-down and back keeps the right tint. 60 fps on the day-40 horde test.
- **Start prompt:** "Implement chunk 1N (day/night, visual only, driven by the horde clock) from docs/plans/living-world-plan.md: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md and hordes.md, and the 1N section only."

### 1F: Smoke, fire and embers (size S–M)
- **Goal:** the town breathes: chimneys and cook fires smoke, damaged buildings smoulder, and fights leave drifting embers and dust.
- **Needs:** nothing.
- **Scope (App only):** particle effects built in code from numbers in `atmosphere.json` (no `.sks` editor files needed): **chimney/cook smoke** on staffed buildings (smoke anchor points as data in `presentation.json`, like lights); **smoulder** on buildings below half health and on rubble; **embers and ash** after a wall breaks, a building is destroyed, or a cluster of zombies dies, hooked into `App/Rendering/EventPlayer.swift`. Tiny soft-dot particle textures are generated in code, so missing art can never crash it. A hard cap on live emitters and particles (like the existing goo/tracer caps). Emitters off-screen or while paused go to sleep.
- **Do NOT build:** weather (2F), fire spreading as a game rule, Core changes.
- **Exit check:** at rest, farms/shelters smoke gently; a damaged wall smoulders; breaking a wall throws embers that drift and fade; the day-40 horde still runs at 60 fps; the node count stays near the 1,389 baseline plus the cap.
- **Start prompt:** "Implement chunk 1F (smoke, fire, embers) from docs/plans/living-world-plan.md: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md, and the 1F section only."

### 1U: Survivors walking to work (size M)
- **Goal:** little people walk between the HQ, shelters and their workplaces, and run for the HQ when a horde comes.
- **Needs:** nothing. Core already tells the App how many survivors staff each building (`Building.staffed`), and survivor sprites (`unit_survivor`, SE/NE) already exist.
- **Scope (App only, cosmetic):** a new `SurvivorLayer.swift` + `UnitNodeFactory.swift` (already planned in MAP). For each staffed worker, a walker shuttles between home (a shelter or the HQ) and the workplace on walkable tiles, with short pauses "at work". Paths are worked out once and cached. A simple bob like the zombie shamble (no new animation art needed). During a horde they hurry back to the HQ and stay hidden until it ends (matching `units.json` "flee to HQ"). A cap on visible walkers (for example 20) from JSON; beyond that the counts stay right but not everyone is drawn.
- **Why App only:** these walkers are decoration. They never touch the game result, so the simulation stays simple and the save is unchanged.
- **Do NOT build:** survivor positions in Core, survivors getting hurt, defenders (see "About chunk 2B" below), new art.
- **Exit check:** a fresh town shows walkers going to the farm/scavenger post and back; building a new farm sends someone there; at the horde warning they head home; 60 fps with 20 walkers plus the day-40 horde.
- **Start prompt:** "Implement chunk 1U (cosmetic survivors walking to jobs) from docs/plans/living-world-plan.md: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md and economy.md, and the 1U section only."

#### About chunk 2B (jobs + defenders): extend it, don't add a new Core chunk
- **Survivors:** 2B keeps them as numbers in Core (who works where). That's all 1U needs; when 2B lands, 1U simply reads the new worker counts. No change to 2B for this.
- **Defenders:** they really fight, so they must live in Core. **Add two lines to 2B's scope:** (1) a defender sent to a tower or a spot *walks there* at `units.json` speed along the zombie path grid (instead of appearing there), with position and facing saved; (2) Core emits events for "defender fired", "defender knocked out" and "defender back at HQ", so the App can draw shots and a stagger. Both are deterministic and testable.
- **Drawing defenders** is already in 3B's scope ("defender units (directional) with a hold-spot command"). Add: reuse 1U's walker drawing, muzzle flashes from the new events, and night lights on manned towers if 1N is built. No separate chunk needed.

### 1S: Sound engine, ambience and effects (size M)
- **Goal:** you can hear the town: wind and birds by day, crickets at night (if 1N exists), hammering at building sites, gunfire, zombie groans and walls cracking.
- **Needs:** nothing in code; **you supply (or approve) the sound files** first. No sound exists in the project yet.
- **Scope (App only):** a new `App/Audio/` folder with `SoundRegistry.swift` (sound id → file; **a missing file is just silent and logged, never a crash**, like ArtRegistry) and `AudioDirector.swift`, which listens to Core events and the horde clock. Built on Apple's built-in AVFoundation, so **no third-party library is needed** (adding one would need a DECISIONS entry and your approval). Ambience is 2–3 looping layers that fade in and out. Effects are capped (for example at most 4 gunshots at once) so a big fight doesn't turn into noise. Sounds get quieter when zoomed out or off-screen. The app uses the "ambient" audio mode: it respects the silent switch and plays alongside your own music. Volumes and limits go in a new `Content/audio.json`.
- **Where sound files come from (your call, licences recorded in `App/Audio/CREDITS.md`):** CC0 (no-strings) packs such as Kenney or CC0-only Freesound; paid royalty-free packs that allow use in a commercial app; GarageBand/Logic loops (Apple allows them in your own music); AI sound or music generators **only** if their terms grant commercial use; or a commissioned composer. Files go in as `.m4a` for loops/music and `.caf`/`.wav` for short effects.
- **Do NOT build:** music (2S), a volume settings screen (goes into 5B), voice acting, third-party audio libraries.
- **Exit check:** on a device or in the simulator with sound on: ambience loops without a gap; gunfire, groans and wall breaks fire on cue; the day-40 horde doesn't clip or stutter; the silent switch mutes it; deleting a sound file causes silence, not a crash.
- **Start prompt:** "Implement chunk 1S (sound engine, ambience, effects) from docs/plans/living-world-plan.md: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/hordes.md, and the 1S section only. Sound files are in <folder>."

### 2F: Weather, fog and dust (size M)
- **Goal:** some days are misty, rainy or dusty, so the same town looks different from day to day.
- **Needs:** 1N and 1F only (it reuses their tint and particle code).
- **Scope (App only):** weather states (clear, morning fog, rain, dust wind) picked each new "day" at random, weighted in `atmosphere.json`. Visual only, so it doesn't use Core's seeded random. **Rain:** one screen-space emitter on the camera plus a slightly darker tint. **Fog:** 2–3 large soft cloud sprites drifting slowly, thicker at dusk and dawn. **Dust:** blowing particles plus slanted chimney smoke. If 1S exists, rain and wind sounds follow the weather. Turned down automatically in iPhone Low Power Mode.
- **Do NOT build:** weather that changes gameplay (slower zombies in rain, and so on), puddles or reflections, snow, lightning strikes.
- **Exit check:** force each weather from the debug menu; each reads clearly but never hides zombies or menus; changes fade over a few seconds; 60 fps in rain plus night plus the day-40 horde (the worst case).
- **Start prompt:** "Implement chunk 2F (weather) from docs/plans/living-world-plan.md: read AGENTS.md, docs/STATUS.md, docs/MAP.md, docs/features/rendering-art.md, and the 2F section only."

### 2S: Music that reacts to hordes (size S–M)
- **Goal:** calm music while you build, rising tension when the warning arrows appear, a driving combat track during the horde, and a short "held" sting at dawn.
- **Needs:** 1S only, plus **decision 2** (lifting "no music in Phase 1") and the music files.
- **Scope (App only):** extend `AudioDirector` with music states (build / tension / combat / victory / HQ fell), crossfading on the horde clock, with fade times and volumes in `audio.json`. 3–5 tracks; looping tracks must loop cleanly.
- **Do NOT build:** a music player, a track picker, music that layers per zombie type.
- **Exit check:** one full cycle hears calm → tension at the arrows → combat at the first zombie → sting on "Held!" → calm, with no hard cuts; pausing the game fades the music down.
- **Start prompt:** "Implement chunk 2S (reactive music) from docs/plans/living-world-plan.md: read AGENTS.md, docs/STATUS.md, docs/MAP.md, and the 1S and 2S sections only. Music files are in <folder>."

---

## Recommended order

1. **1K camera** (small, safe, and you feel it in every second of play)
2. **1N day/night** (the biggest single "wow", once decision 1 is made)
3. **1F smoke and embers**
4. **1U survivors walking** (the town finally looks inhabited)
5. **1S sound** (as soon as you have sound files; it can move earlier)
6. **2F weather**
7. **2S music** (after decision 2)

Then the 2B additions and 3B defender drawing land with the gameplay track. Steps 1–4 together are roughly the "Tropico feel" core.

## Performance on iPhone (60 fps target)

Today's baseline is a day-40 horde at 60 fps with about 1,400 nodes, **measured in the simulator only**. The simulator is not a phone, so each chunk's exit check should also be run on a real iPhone (ideally an older one) before it's called done.

| Risk | Where | How we keep it safe |
|---|---|---|
| Stacking see-through screen-sized layers (tint + fog + rain) makes the GPU paint every pixel several times | 1N, 2F | One tint layer only; fog is 2–3 sprites, not a full-screen filter; no `SKEffectNode`/Core Image filters |
| Real-time lighting is very slow in SpriteKit | 1N | Use pre-made glow sprites, not `SKLightNode` |
| Too many particles in a big fight | 1F, 2F | Hard caps from JSON, sleep when off-screen/paused, cut in Low Power Mode |
| Path-finding for many walkers | 1U | Cache paths, cap visible walkers |
| Dozens of gunshots at once | 1S | Cap simultaneous sounds per type |
| Battery and heat (effects run even when nothing happens) | all | Lower effect rates when idle; reuse textures |

## What survives the future art redo (and the 3D option)

- **Survives the 2D art redo almost entirely:** all the logic, the camera feel, the day/night timing, sound and music, and all the numbers in JSON. What needs redoing is data, not code: light, smoke and chimney positions per building image (in `presentation.json`), maybe the tint colours to suit the new palette, and the survivor sprites (track A art work; the Mixamo route in D-026 could give them a real walk later).
- **If you pick the 3D plan instead:** the sound engine and all audio files, the camera *behaviour* (glide, focus shot), the "day follows the horde clock" rule, the 2B defender additions and every JSON number carry over. The SpriteKit tint, glow sprites and particle code would be rebuilt in 3D, though the design work in this plan still applies.
