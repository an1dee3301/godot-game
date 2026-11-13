"""Standalone, read-only structural QA for the original Blender mascot sources.

Run: blender --background --python-exit-code 1 --python tools/verify_party_cast.py
Writes assets/characters/structure-qa.json. Requires only Blender's bpy/bmesh.
The historical detailed qa-report.json is deliberately left intact.
"""
import json
import math
from pathlib import Path

import bmesh
import bpy

ROOT = Path(__file__).resolve().parents[1]
KINDS = ("bun", "cub", "pip", "sprout")
PIVOTS = {
    "Body": ("PartyMascot", (0.0, 0.0, 0.0)),
    "Head": ("PartyMascot", (0.0, 0.0, 0.4)),
    "ArmL": ("PartyMascot", (-0.43, 0.0, -0.08)),
    "ArmR": ("PartyMascot", (0.43, 0.0, -0.08)),
    "FootL": ("PartyMascot", (-0.235, 0.0, -0.62)),
    "FootR": ("PartyMascot", (0.235, 0.0, -0.62)),
    "EyeL": ("Head", (-0.19, -0.352, 0.095)),
    "EyeR": ("Head", (0.19, -0.352, 0.095)),
}


def inspect_source(kind):
    result = {
        "source": f"art/source/{kind}.blend",
        "pass": False,
        "errors": [],
        "meshes": [],
        "pivots": {},
        "evaluated_triangles": 0,
        "external_images": [],
    }
    errors = result["errors"]
    source = ROOT / result["source"]
    if not source.is_file():
        errors.append("Authored Blender source is missing")
        return result
    bpy.ops.wm.open_mainfile(filepath=str(source))
    objects = bpy.context.scene.objects
    mascot = objects.get("PartyMascot")
    if mascot is None or mascot.type != "EMPTY":
        errors.append("PartyMascot root empty is missing")
    for name, (parent, expected) in PIVOTS.items():
        obj = objects.get(name)
        if obj is None:
            errors.append(f"Missing animated part/pivot: {name}")
            continue
        location = tuple(obj.location)
        result["pivots"][name] = {
            "parent": obj.parent.name if obj.parent else None,
            "location": [round(v, 6) for v in location],
        }
        if obj.type != "EMPTY" or obj.parent is None or obj.parent.name != parent:
            errors.append(f"{name}: incorrect pivot type or parent (expected {parent})")
        if any(not math.isfinite(v) or abs(v - target) > 0.0001 for v, target in zip(location, expected)):
            errors.append(f"{name}: pivot is outside its animation contract")
        if not any(child.type == "MESH" for child in obj.children):
            errors.append(f"{name}: animated group has no mesh child")
    scene_meshes = [obj for obj in objects if obj.type == "MESH"]
    if len(scene_meshes) != len(PIVOTS):
        errors.append(f"Expected eight independently animated meshes, found {len(scene_meshes)}")
    for obj in objects:
        if any(not math.isfinite(v) or abs(v - 1.0) > 0.0001 for v in obj.scale):
            errors.append(f"{obj.name}: unapplied scale")
    coordinates = []
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for obj in scene_meshes:
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        try:
            mesh.calc_loop_triangles()
            triangles = len(mesh.loop_triangles)
            result["evaluated_triangles"] += triangles
            if not mesh.vertices or triangles == 0:
                errors.append(f"{obj.name}: empty evaluated geometry")
            if not obj.material_slots or any(slot.material is None for slot in obj.material_slots):
                errors.append(f"{obj.name}: missing material slots")
            if any(face.material_index >= len(obj.material_slots) for face in mesh.polygons):
                errors.append(f"{obj.name}: face references a missing material")
            finite = True
            for vertex in mesh.vertices:
                world = obj.matrix_world @ vertex.co
                if not all(math.isfinite(value) for value in (*vertex.co, *world)):
                    finite = False
                else:
                    coordinates.append(tuple(world))
            if not finite:
                errors.append(f"{obj.name}: non-finite geometry")
            # This topology summary uses only Blender's built-in mesh API.
            topology = bmesh.new()
            try:
                topology.from_mesh(mesh)
                loose = sum(not vertex.link_edges for vertex in topology.verts)
                if loose:
                    errors.append(f"{obj.name}: {loose} loose vertices")
                result["meshes"].append({
                    "name": obj.name,
                    "vertices": len(mesh.vertices),
                    "evaluated_triangles": triangles,
                    "material_slots": len(obj.material_slots),
                    "boundary_edges": sum(edge.is_boundary for edge in topology.edges),
                    "finite_geometry": finite,
                })
            finally:
                topology.free()
        finally:
            evaluated.to_mesh_clear()
    if coordinates:
        lower = [min(point[axis] for point in coordinates) for axis in range(3)]
        upper = [max(point[axis] for point in coordinates) for axis in range(3)]
        dimensions = [upper[axis] - lower[axis] for axis in range(3)]
        result["world_bounds"] = {
            "min": [round(v, 6) for v in lower],
            "max": [round(v, 6) for v in upper],
            "dimensions": [round(v, 6) for v in dimensions],
        }
        if any(value <= 0.0 for value in dimensions) or not 1.2 <= dimensions[2] <= 3.2:
            errors.append("Authored bounds are outside the expected mascot size")
    else:
        errors.append("No finite bounds could be measured")
    if not 1000 <= result["evaluated_triangles"] <= 15000:
        errors.append("Evaluated triangle count is outside the 1,000–15,000 cast budget")
    for image in bpy.data.images:
        if image.source not in {"FILE", "TILED"}:
            continue
        packed = bool(image.packed_file) or bool(image.packed_files)
        image_path = Path(bpy.path.abspath(image.filepath)) if image.filepath else None
        exists = packed or (image_path is not None and image_path.is_file())
        result["external_images"].append({"name": image.name, "packed": packed, "available": exists})
        if not exists:
            errors.append(f"{image.name}: external image is missing")
    result["mesh_count"] = len(scene_meshes)
    result["pass"] = not errors
    return result


report = {
    "checker": "Standalone Blender structural checks; no external skills or packages",
    "blender": bpy.app.version_string,
    "coordinate_system": "Blender Z up, -Y front; glTF export converts to game Y up",
    "characters": {},
}
for character in KINDS:
    outcome = inspect_source(character)
    report["characters"][character] = outcome
    print("CAST_STRUCTURE_QA", character, "pass=", outcome["pass"], "triangles=", outcome["evaluated_triangles"], "errors=", len(outcome["errors"]))
report["pass"] = all(result["pass"] for result in report["characters"].values())
target = ROOT / "assets" / "characters" / "structure-qa.json"
target.write_text(json.dumps(report, indent=2) + "\n")
print("CAST_STRUCTURE_REPORT", target.relative_to(ROOT), "pass=", report["pass"])
if not report["pass"]:
    raise RuntimeError("Mascot structural QA failed; inspect assets/characters/structure-qa.json")
