# Purpose: 3D models for the runner and brute zombies, in the style of the study's walker (characters.zombie). Spec: docs/graphics-spec-iso.md
"""Rounded, cartoony green zombies (no gore) modeled facing +X like the study's characters. The walker is about
1.3 units tall; the runner is ~0.9x and thinner, the brute ~1.6x and much wider."""
from geometry import box, sphere, beam, rod
import bpy
import characters
from zombie_details import surfaces, finish_parts, walker_costume, runner_costume, brute_costume


def _face(x, z, s, mouth=True):
    """Dark eye sockets (and an open mouth) on the front of a head whose front surface is at x."""
    for y in (-.1 * s, .1 * s):
        box('sleepy eye socket', (x, y, z + .06 * s), (.02, .055 * s, .04 * s), 'zombie_dark', .01)
    if mouth:
        box('gaping mouth', (x - .005, 0, z - .07 * s), (.02, .1 * s, .045 * s), 'black', .01)


def _runner():
    """Lean sprinter: leaning far forward, mid-stride, one arm reaching and one swung back."""
    for y, hip, knee, foot, tilt in ((.11, (0, .11, .5), (.17, .11, .3), (.24, .11, .08), 0),
                                     (-.11, (0, -.11, .5), (-.1, -.11, .3), (-.3, -.11, .2), -.6)):
        beam('ragged shorts leg', hip, knee, .12, 'iron', .12, .03)
        beam('thin green shin', knee, foot, .085, 'zombie', .085, .025)
        box('worn sneaker', (foot[0] + .04, y, foot[2] - .02), (.26, .13, .11), 'cream', .035, (0, tilt, 0))
        box('sneaker stripe', (foot[0] + .04, y, foot[2] - .02), (.12, .135, .03), 'coral', .008, (0, tilt, 0))
    box('ragged shorts', (0, 0, .52), (.22, .3, .16), 'iron', .04)
    torso = sphere('lean leaning torso', (.12, 0, .72), (.15, .19, .26), 'rust', 2)
    torso.rotation_euler = (0, .8, 0)
    box('torn tank top hem', (.0, 0, .6), (.12, .32, .06), 'rust', .02, (0, .8, 0))
    sphere('bony shoulder blades', (.12, 0, .82), (.14, .2, .09), 'zombie_dark', 1)
    sphere('forward-thrust head', (.42, 0, .99), (.19, .18, .2), 'zombie', 2)
    sphere('patchy scalp', (.34, .01, 1.13), (.14, .14, .07), 'zombie_dark', 1)
    sphere('zombie nose', (.61, 0, .99), (.045, .05, .055), 'zombie', 1)
    _face(.6, .99, 1)
    for y in (-.15, .15):
        sphere('ear', (.4, y * 1.15, .99), (.05, .05, .065), 'zombie', 1)
    # Left arm reaches forward, right arm trails behind.
    beam('thin upper arm', (.28, .2, .86), (.42, .25, .7), .085, 'zombie', .085, .025)
    beam('thin forearm', (.42, .25, .7), (.66, .21, .79), .075, 'zombie', .075, .02)
    sphere('clawing hand', (.7, .21, .79), (.08, .06, .05), 'zombie', 1)
    for yy in (-.025, .025):
        rod('thin finger', (.74, .21 + yy, .79), (.82, .21 + yy, .8), .014, 'zombie')
    beam('thin upper arm', (.26, -.2, .86), (.1, -.25, .66), .085, 'zombie', .085, .025)
    beam('thin forearm', (.1, -.25, .66), (-.12, -.24, .62), .075, 'zombie', .075, .02)
    sphere('trailing hand', (-.16, -.24, .62), (.07, .055, .05), 'zombie', 1)


def _brute():
    """Hulking zombie: short thick legs, a huge chest, small hunched head and knuckle-dragging fists."""
    for y in (-.3, .3):
        box('big worn boot', (.06, y, .12), (.5, .3, .24), 'black', .07)
        beam('thick trouser leg', (0, y, .2), (-.02, y * .95, .8), .32, 'denim', .32, .06)
    sphere('overall belly', (0, 0, 1.0), (.45, .52, .45), 'denim', 2)
    sphere('barrel chest', (.05, 0, 1.38), (.46, .56, .38), 'rust', 2)
    box('overall bib', (.38, 0, 1.12), (.12, .5, .4), 'denim', .05)
    for y in (-.2, .2):
        beam('overall strap', (.4, y, 1.3), (.2, y * 1.3, 1.78), .09, 'wood_dark', .05, .02)
        sphere('strap button', (.45, y, 1.3), (.04, .04, .04), 'yellow', 1)
    box('torn shirt patch', (.43, -.15, 1.55), (.06, .18, .14), 'coral', .02, (0, -.4, .2))
    sphere('back hump', (-.12, 0, 1.6), (.3, .4, .2), 'rust', 2)
    sphere('thick neck', (.3, 0, 1.68), (.22, .27, .17), 'zombie_dark', 2)
    for y in (-.6, .6):
        sphere('massive shoulder', (.02, y * .95, 1.58), (.23, .23, .21), 'rust', 2)
        beam('torn sleeve', (0, y * 1.02, 1.58), (.1, y * 1.15, 1.28), .3, 'rust', .3, .07)
        beam('huge forearm', (.1, y * 1.15, 1.3), (.36, y * 1.1, .75), .3, 'zombie', .3, .08)
        sphere('big fist', (.42, y * 1.1, .6), (.24, .21, .22), 'zombie', 2)
        for dy in (-.1, 0, .1):
            sphere('knuckle', (.6, y * 1.1 + dy, .66), (.06, .05, .05), 'zombie_dark', 1)
    sphere('small hunched head', (.44, 0, 1.78), (.27, .25, .26), 'zombie', 2)
    sphere('scarred scalp', (.34, 0, 1.98), (.2, .2, .09), 'zombie_dark', 1)
    box('heavy brow', (.66, 0, 1.87), (.08, .34, .07), 'zombie_dark', .03)
    for y in (-.1, .1):
        box('sleepy eye socket', (.705, y, 1.82), (.02, .07, .045), 'black', .01)
    box('jutting jaw', (.61, 0, 1.62), (.24, .34, .14), 'zombie', .05)
    for y in (-.1, .1):
        box('blunt tooth', (.71, y, 1.72), (.05, .05, .07), 'cream', .015)
    for y in (-.22, .22):
        sphere('small ear', (.4, y * 1.15, 1.79), (.06, .05, .08), 'zombie', 1)


def _detailed(make, costume):
    surfaces()
    before = set(bpy.data.objects)
    make()
    costume()
    finish_parts(before)


def walker():
    _detailed(characters.zombie, walker_costume)


def runner():
    _detailed(_runner, runner_costume)


def brute():
    _detailed(_brute, brute_costume)
