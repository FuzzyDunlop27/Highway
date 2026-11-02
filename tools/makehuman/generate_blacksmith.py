# Purpose: Make a repeatable MakeHuman body and binary FBX. Notes: docs/features/characters-3d.md
"""Load in MakeHuman Utilities > Scripting; run from Utilities > Execute.

Save your current character first. Requires enabled 7_scripting and 9_export_fbx.
Creates a fresh, unrigged base body; profile details are a separate modeling pass.
Uses MakeHuman's internal API; see README.md for the verified source revision.
"""


def generate_blacksmith():
    # Keep imports/settings inside this function: MakeHuman executes scripts with
    # exec() inside a function, whose locals are not the globals of new functions.
    import importlib
    import json
    import math
    import tempfile
    from pathlib import Path

    import mh
    from core import G

    settings = {"age_years": 45.0, "gender": 1.0,
                "muscle": 0.80, "weight": 0.20, "height": 1.0}
    output_root = Path(mh.getPath("exports")) / "highway-blacksmith"
    app = G.app
    human = app.selectedHuman
    if app.currentFile.modified:
        raise RuntimeError("Save your current character before running this script.")

    plugin = app.modules.get("9_export_fbx")
    if plugin is None:
        raise RuntimeError("Enable 9_export_fbx in Settings > Plugins, then restart.")
    # Validate the exporter before resetting the visible character.
    exporter = importlib.import_module(plugin.__name__ + ".mh2fbx")
    config = plugin.FbxConfig()
    output_root.mkdir(parents=True, exist_ok=True)
    output_dir = Path(tempfile.mkdtemp(prefix="blacksmith_", dir=str(output_root)))

    # Same reset as Files > New, after the explicit unsaved-work check above.
    app._resetHuman()
    human.setSkeleton(None)
    human.setGender(settings["gender"])
    human.setAgeYears(settings["age_years"])
    human.setMuscle(settings["muscle"])
    human.setWeight(settings["weight"])
    human.setHeight(settings["height"])
    human.setName("Blacksmith age 45 - base body")

    actual = {"age_years": human.getAgeYears(), "gender": human.getGender(),
              "muscle": human.getMuscle(), "weight": human.getWeight(),
              "height": human.getHeight()}
    for key, expected in settings.items():
        if not math.isclose(actual[key], expected, abs_tol=1e-6):
            raise RuntimeError("MakeHuman did not apply {}: {}".format(key, actual[key]))
    height_cm = float(human.getHeightCm())
    if not math.isfinite(height_cm) or height_cm <= 0:
        raise RuntimeError("MakeHuman returned an invalid measured height.")

    # Keep native decimetre coordinates. Upstream binary FBX writes a constant
    # UnitScaleFactor=10 (10 cm/unit), so scale=1 preserves the physical height.
    # Do not copy the GUI's extra scale multiplier into this direct API call.
    config.setHuman(human)
    config.binary = True
    config.scale = 1.0
    config.unit = "decimeter"
    config.feetOnGround = True
    config.hiddenGeom = False
    config.useRelPaths = True

    model_path = output_dir / "blacksmith_base.mhm"
    fbx_path = output_dir / "blacksmith_base.fbx"
    human.save(str(model_path))
    exporter.exportFbx(str(fbx_path), config)
    # Catch empty/ASCII/obviously incomplete output. This is not an import test.
    with fbx_path.open("rb") as stream:
        signature = stream.read(23)
    if signature != b"Kaydara FBX Binary  \x00\x1a\x00" or fbx_path.stat().st_size <= 27:
        raise RuntimeError("Expected a nonempty binary FBX at {}".format(fbx_path))

    report = {"requested": settings, "actual": actual,
              "measured_height_cm": height_cm,
              "fbx_coordinate_unit": "decimeter; UnitScaleFactor 10 cm/unit",
              "rigged": False, "profile_details_applied": False,
              "fbx_bytes": fbx_path.stat().st_size,
              "next_check": "Import FBX in Blender; compare height, feet and textures."}
    (output_dir / "generation_report.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8")
    app.redraw()
    print("Blacksmith base exported: {}".format(fbx_path))
    print("Measured height: {:.2f} cm; keep the textures folder beside the FBX.".format(height_cm))
    app.statusPersist("Blacksmith exported to {}".format(output_dir))


# Intentionally no __main__ guard: MakeHuman's scripting plugin uses exec().
generate_blacksmith()
