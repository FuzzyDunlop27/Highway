#!/usr/bin/env python3
# Purpose: Turn ChatGPT PNGs into trimmed, resized @1x/@2x/@3x Xcode imagesets. Spec: docs/graphics-spec-phase1.md
"""
Usage:
    python3 tools/import_art.py <folder_of_pngs> [--view topdown|iso] [--out App/Assets.xcassets] [--dry-run]

Views (docs/features/rendering-art.md, DECISIONS D-016): the game draws each view from its own folder.
  --view topdown (default) -> Art/TopDown/  top-down art per docs/graphics-spec-phase1.md (trimmed + fitted).
  --view iso                -> Art/Iso/      isometric art per docs/graphics-spec-iso.md: NOT trimmed; scaled so its
                                             width is the footprint diamond width; facing frames like zmb_walker_se.png.
  --view ui                 -> Art/UI/      finished UI kit pieces (HighwayHoldout_UI_Kit/png): every ui_*.png is copied
                                             unchanged as a @2x image; ui_glyph_* are template images (tinted in code).
  UI icons (icon_*, ui_*) always go to Art/UI/, whatever the view.

Needs Pillow:  python3 -m pip install Pillow

What it does for each PNG whose name matches the graphics spec (e.g. bld_hq.png):
  - Sprites: trims empty transparent border, scales the art to fit its canvas (keeping
    the "figure fills ~55%" sizes from the spec), centers it, writes @1x/@2x/@3x.
  - Terrain tiles (tile_*): no trimming (they must tile seamlessly); just resized to fill.
  - app_icon: written as a 1024x1024 opaque AppIcon. app_icon_bg/fg go to AppIconLayers/.
Point size = master size / 4, so a 128px master tile is 32pt: 32px @1x, 64px @2x, 96px @3x.
Unknown filenames are skipped with a warning (and a "did you mean" hint).
Re-running overwrites the previous output for the same name, so it is safe to repeat.
"""
import argparse
import difflib
import json
import re
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is not installed. Run: python3 -m pip install Pillow")

POINTS_PER_MASTER_PX = 0.25  # 128px master tile -> 32pt; 256px icon -> 64pt
SCALES = (1, 2, 3)
PAD_MASTER_PX = 4            # spec: ~4px padding at master size
UI_DARK = (0x1E, 0x21, 0x26)

# name -> (master width px, master height px, fill, mode)
#   fill = fraction of the canvas the art's longest side should occupy (spec "~55% of canvas")
#   mode = "sprite" (trim + fit + center) or "tile" (opaque, seamless: resize to fill, no trim)
T1, T2, T3 = 128, 256, 384
ASSETS = {
    # Terrain & decor
    "tile_grass": (T1, T1, 1.0, "tile"), "tile_dirt": (T1, T1, 1.0, "tile"),
    "tile_asphalt": (T1, T1, 1.0, "tile"), "tile_asphalt_line": (T1, T1, 1.0, "tile"),
    "tile_concrete": (T1, T1, 1.0, "tile"),
    "dec_rubble": (T1, T1, 1.0, "sprite"), "dec_tree_dead": (T1, T1, 1.0, "sprite"),
    "dec_car_wreck": (T2, T1, 1.0, "sprite"),
    # Buildings
    "bld_hq": (T3, T3, 1.0, "sprite"), "bld_construction_3x3": (T3, T3, 1.0, "sprite"),
    **{n: (T2, T2, 1.0, "sprite") for n in (
        "bld_shelter", "bld_farm", "bld_scavenger", "bld_workshop", "bld_barracks",
        "bld_storage", "bld_construction_2x2", "bld_rubble_2x2")},
    # Defenses (walls fill edge-to-edge so a line of them looks solid)
    "def_wall_wood": (T1, T1, 1.0, "sprite"), "def_wall_metal": (T1, T1, 1.0, "sprite"),
    "def_watchtower_base": (T1, T1, 1.0, "sprite"), "def_watchtower_gunner": (T1, T1, 0.6, "sprite"),
    "def_mg_nest_base": (T1, T1, 1.0, "sprite"), "def_mg_nest_gun": (T1, T1, 0.7, "sprite"),
    "def_spikes": (T1, T1, 1.0, "sprite"), "def_barbwire": (T1, T1, 1.0, "sprite"),
    # Units & zombies (sizes from the spec)
    "unit_survivor": (T1, T1, 0.55, "sprite"), "unit_defender": (T1, T1, 0.55, "sprite"),
    "zmb_walker": (T1, T1, 0.55, "sprite"), "zmb_runner": (T1, T1, 0.50, "sprite"),
    "zmb_brute": (T1, T1, 0.85, "sprite"),
    # Effects
    "fx_muzzle_flash": (64, 64, 1.0, "sprite"), "fx_tracer": (64, 16, 1.0, "sprite"),
    "fx_goo_splat": (T1, T1, 1.0, "sprite"), "fx_dust_puff": (T1, T1, 1.0, "sprite"),
    # UI icons (256 master -> 64pt)
    **{n: (256, 256, 1.0, "sprite") for n in (
        "icon_food", "icon_scrap", "icon_survivors", "icon_defender", "icon_build",
        "icon_upgrade", "icon_demolish", "icon_horde_alert", "icon_clock", "icon_speed",
        "icon_pause", "icon_settings", "ui_level_badge",
        "icon_medicine", "icon_fuel", "icon_ammo", "icon_knowledge")},  # last row: P3
    # Vehicles (P3)
    "veh_rv": (T2, T1, 1.0, "sprite"), "veh_pickup": (T2, T1, 1.0, "sprite"),
}
APP_ICONS = {"app_icon", "app_icon_bg", "app_icon_fg"}
XCODE_INFO = {"author": "xcode", "version": 1}


def normalize(stem):
    """'Bld HQ (1)' / 'bld-hq-copy' -> 'bld_hq'. Tolerates common download-name junk."""
    s = stem.strip().lower()
    s = re.sub(r"\s*\(\d+\)$", "", s)           # "name (1)"
    s = re.sub(r"[_\-\s]*(copy|final|v\d+)$", "", s)
    return re.sub(r"[\s\-]+", "_", s)


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")


def has_transparency(img):
    lo, _ = img.getchannel("A").getextrema()
    return lo < 250


def fit_sprite(img, cw, ch, fill, warn):
    """Trim transparent border, scale to fit inside the padded canvas, center. Returns master-size RGBA."""
    if not has_transparency(img):
        warn("no transparent pixels — background may be baked in (spec wants transparent)")
    box = img.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    if box is None:
        warn("image is fully transparent; skipped")
        return None
    art = img.crop(box)
    k = min((cw - 2 * PAD_MASTER_PX) * fill / art.width, (ch - 2 * PAD_MASTER_PX) * fill / art.height)
    art = art.resize((max(1, round(art.width * k)), max(1, round(art.height * k))), Image.LANCZOS)
    canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    canvas.paste(art, ((cw - art.width) // 2, (ch - art.height) // 2), art)
    return canvas


def fit_tile(img, cw, ch, warn):
    """Opaque seamless tile: center-crop to the target aspect, no trimming or padding."""
    target = cw / ch
    if abs(img.width / img.height - target) > 0.02:
        warn(f"aspect {img.width}x{img.height} doesn't match {cw}x{ch}; center-cropping (may break seams)")
        if img.width / img.height > target:
            w = round(img.height * target)
            img = img.crop(((img.width - w) // 2, 0, (img.width - w) // 2 + w, img.height))
        else:
            h = round(img.width / target)
            img = img.crop((0, (img.height - h) // 2, img.width, (img.height - h) // 2 + h))
    return img


FACINGS = ("e", "ne", "n", "nw", "w", "sw", "s", "se")
VIEW_FOLDERS = {"topdown": "TopDown", "iso": "Iso", "ui": "UI"}


def write_ui_kit_image(img, name, out_root):
    """UI kit pieces are final: copy pixels unchanged as @2x; glyphs become template images SwiftUI can tint."""
    folder = out_root / "Art" / "UI" / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    img.save(folder / f"{name}@2x.png", optimize=True)
    contents = {"images": [{"filename": f"{name}@2x.png", "idiom": "universal", "scale": "2x"}], "info": XCODE_INFO}
    if name.startswith("ui_glyph_"):
        contents["properties"] = {"template-rendering-intent": "template"}
    write_json(folder / "Contents.json", contents)
    return folder


def base_name(name):
    """'zmb_walker_se' -> 'zmb_walker' (facing frames share their base asset's size)."""
    m = re.match(r"^(.*)_(" + "|".join(FACINGS) + r")$", name)
    return m.group(1) if m and m.group(1) in ASSETS else name


def fit_iso(img, cw, ch, warn):
    """Isometric art: keep everything (no trim, the ground point matters); scale to the footprint diamond width.
    A w x h footprint is (w + h) * 128 px wide at master size, i.e. canvas width + height. Height follows the image."""
    width = cw + ch
    height = max(1, round(img.height * width / img.width))
    if not has_transparency(img) and not img.width == 2 * img.height:
        warn("no transparent pixels; isometric sprites need a transparent background")
    return img.resize((width, height), Image.LANCZOS)


def write_imageset(master, name, cw, ch, out_root, folder_name):
    folder = out_root / "Art" / folder_name / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    images = []
    for s in SCALES:
        w = max(1, round(cw * POINTS_PER_MASTER_PX * s))
        h = max(1, round(ch * POINTS_PER_MASTER_PX * s))
        fname = f"{name}@{s}x.png"
        master.resize((w, h), Image.LANCZOS).save(folder / fname, optimize=True)
        images.append({"filename": fname, "idiom": "universal", "scale": f"{s}x"})
    write_json(folder / "Contents.json", {"images": images, "info": XCODE_INFO})
    return folder


def write_app_icon(img, name, out_root, warn):
    if img.size != (1024, 1024):
        warn(f"is {img.width}x{img.height}; resizing to 1024x1024")
        img = img.resize((1024, 1024), Image.LANCZOS)
    if name == "app_icon":
        if has_transparency(img):
            warn("app icon must be opaque; filling transparent areas with UI dark")
        flat = Image.new("RGB", img.size, UI_DARK)
        flat.paste(img, (0, 0), img)
        folder = out_root / "AppIcon.appiconset"
        folder.mkdir(parents=True, exist_ok=True)
        flat.save(folder / "app_icon.png", optimize=True)
        write_json(folder / "Contents.json", {"images": [{"filename": "app_icon.png", "idiom": "universal",
                   "platform": "ios", "size": "1024x1024"}], "info": XCODE_INFO})
        return folder
    # Layered icon parts: not an asset-catalog format; saved for Apple's Icon Composer.
    folder = out_root.parent / "AppIconLayers"
    folder.mkdir(parents=True, exist_ok=True)
    img.save(folder / f"{name}.png", optimize=True)
    return folder


def main():
    repo = Path(__file__).resolve().parent.parent
    ap = argparse.ArgumentParser(description="Import ChatGPT PNGs into the Xcode asset catalog.")
    ap.add_argument("src", type=Path, help="folder of PNGs named per docs/graphics-spec-phase1.md")
    ap.add_argument("--out", type=Path, default=repo / "App" / "Assets.xcassets", help="asset catalog folder")
    ap.add_argument("--dry-run", action="store_true", help="check names and report, write nothing")
    ap.add_argument("--view", choices=sorted(VIEW_FOLDERS), default="topdown", help="which view this art is for")
    args = ap.parse_args()

    if not args.src.is_dir():
        sys.exit(f"Not a folder: {args.src}")
    files = sorted(p for p in args.src.iterdir() if p.suffix.lower() == ".png")
    if not files:
        sys.exit(f"No PNG files in {args.src}")

    if not args.dry_run:  # catalog + group folder markers Xcode expects
        write_json(args.out / "Contents.json", {"info": XCODE_INFO})
        write_json(args.out / "Art" / "Contents.json", {"info": XCODE_INFO})
        for sub in ("UI", VIEW_FOLDERS[args.view]):  # namespaced: the game asks for "Iso/bld_farm"
            write_json(args.out / "Art" / sub / "Contents.json",
                       {"info": XCODE_INFO, "properties": {"provides-namespace": True}})

    known = sorted(set(ASSETS) | APP_ICONS)
    done, warnings, seen = 0, 0, {}
    for path in files:
        name = normalize(path.stem)

        def warn(msg, _p=path):
            nonlocal warnings
            warnings += 1
            print(f"  WARNING {_p.name}: {msg}")

        if args.view == "ui":
            if not name.startswith("ui_"):
                warn("--view ui only takes ui_*.png files, skipped")
                continue
            if not args.dry_run:
                dest = write_ui_kit_image(Image.open(path).convert("RGBA"), name, args.out)
                print(f"  ok      {path.name} -> {dest.relative_to(args.out.parent)}")
            done += 1
            continue
        base = base_name(name)
        if base not in ASSETS and name not in APP_ICONS:
            hint = difflib.get_close_matches(name, known, n=1, cutoff=0.6)
            warn("unknown filename, skipped" + (f" (did you mean '{hint[0]}'?)" if hint else ""))
            continue
        if name in seen:
            warn(f"same asset as {seen[name]}; this one overwrites it")
        seen[name] = path.name

        img = Image.open(path).convert("RGBA")
        if args.dry_run:
            print(f"  ok      {path.name} -> {name}")
            done += 1
            continue
        if name in APP_ICONS:
            dest = write_app_icon(img, name, args.out, warn)
        else:
            cw, ch, fill, mode = ASSETS[base]
            is_ui = name.startswith(("icon_", "ui_"))
            folder_name = "UI" if is_ui else VIEW_FOLDERS[args.view]
            if args.view == "iso" and not is_ui:
                if img.width < (cw + ch) * 0.75:
                    warn(f"only {img.width} px wide; will look blurry (want ~{cw + ch})")
                master = fit_iso(img, cw, ch, warn)
                cw, ch = master.size
            else:
                if max(img.width / cw, img.height / ch) < 0.75:  # smaller than the @3x output
                    warn(f"only {img.width}x{img.height}; will look blurry (want ~{cw}x{ch})")
                master = fit_tile(img, cw, ch, warn) if mode == "tile" else fit_sprite(img, cw, ch, fill, warn)
            if master is None:
                continue
            dest = write_imageset(master, name, cw, ch, args.out, folder_name)
        print(f"  ok      {path.name} -> {dest.relative_to(args.out.parent)}")
        done += 1

    print(f"\nImported {done} of {len(files)} file(s), {warnings} warning(s). Output: {args.out}")
    return 1 if warnings and done == 0 else 0


if __name__ == "__main__":
    sys.exit(main())
