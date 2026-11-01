# Purpose: Chunk 2M missing-model checker: lists art ids the game uses that have no App/Models/<id>.usdz. Notes: docs/features/models-3d.md
# Run: python3 tools/check_models.py   (exit code 1 if a building, defense, state or decoration model is missing)
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, 'Content')
MODELS = os.path.join(ROOT, 'App', 'Models')


def sprites(node):
    """Every "sprite" (and "turretSprite") value in a JSON tree."""
    if isinstance(node, dict):
        for key, value in node.items():
            if key in ('sprite', 'turretSprite') and isinstance(value, str):  # turrets: chunk 4R
                yield value
            else:
                yield from sprites(value)
    elif isinstance(node, list):
        for value in node:
            yield from sprites(value)


def load(name):
    with open(os.path.join(CONTENT, name)) as f:
        return json.load(f)


def main():
    buildings = load('buildings.json')
    world = set(sprites(buildings))
    rules = buildings['rules']
    world |= {rules['rubble']['rubbleSprite1x1'], rules['rubble']['rubbleSprite2x2']}
    world |= {v for k, v in rules['constructionSprites'].items() if not k.startswith('_')}  # '_' keys are notes
    for path in glob.glob(os.path.join(CONTENT, 'maps', '*.json')):
        with open(path) as f:
            world |= {d['id'] for d in json.load(f).get('decorations', [])}
    characters = set(sprites(load('zombies.json'))) | set(sprites(load('units.json')))
    have = {os.path.splitext(os.path.basename(p))[0] for p in glob.glob(os.path.join(MODELS, '*.usdz'))}

    missing = sorted(world - have)
    print(f'Buildings, defenses, states and decorations: {len(world) - len(missing)}/{len(world)} have models.')
    for art_id in missing:
        print(f'  MISSING {art_id}')
    later = sorted(characters - have)
    if later:
        print(f'Characters (chunk 3M, not counted): {", ".join(later)}')
    unused = sorted(have - world - characters)
    if unused:
        print(f'Models nothing uses: {", ".join(unused)}')
    return 1 if missing else 0


sys.exit(main())
