import sys; sys.path.insert(0, "/private/tmp/claude-501/-Users-andytran-Coding-Godot/eccd311a-705d-4e77-9182-c5a7d6315bd3/scratchpad/blender")
from common import *
from mathutils.bvhtree import BVHTree
load()
body = bpy.data.objects["Body"]
mats = [m.name for m in body.data.materials]
TOPS = next(i for i, n in enumerate(mats) if "Tops" in n)
SKIN = [i for i, n in enumerate(mats) if "SKIN" in n]
bm = bmesh.new(); bm.from_mesh(body.data)
bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()
deform = bm.verts.layers.deform.active
uvl = bm.loops.layers.uv.active
# Weld the glTF UV-seam splits on the top so seams aren't treated as open edges.
tv0 = list({v for f in bm.faces if f.material_index == TOPS for v in f.verts})
bmesh.ops.remove_doubles(bm, verts=tv0, dist=1e-5)
bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()
# A clean white texel on the chest to use for new geometry.
clean_uv = None
for f in bm.faces:
    c = f.calc_center_median()
    if f.material_index == TOPS and c.y > 0.05 and 1.22 < c.z < 1.3 and 0.11 < abs(c.x) < 0.16:
        clean_uv = f.loops[0][uvl].uv.copy(); break
print("clean uv", clean_uv)

# 1) Skin BVH (what the jacket hugs).
skin_faces = [f for f in bm.faces if f.material_index in SKIN]
sv = {v for f in skin_faces for v in f.verts}
idx = {v: i for i, v in enumerate(sv)}
bvh = BVHTree.FromPolygons([v.co.copy() for v in sv], [[idx[v] for v in f.verts] for f in skin_faces])

# 2) Delete hood + front opening + cutaway skirt.
def v_half(z):
    return 0.012 + (1.47 - z) * 0.24
kill = []
for f in bm.faces:
    if f.material_index != TOPS: continue
    c = f.calc_center_median()
    if c.z > 1.47: kill.append(f); continue
    if c.z > 1.42 and (c.y < 0.0 or abs(c.x) < 0.13): kill.append(f); continue
    if c.y > 0.0 and 1.08 < c.z <= 1.42 and abs(c.x) < v_half(c.z): kill.append(f); continue
    if c.y > 0.0 and c.z <= 1.06 and abs(c.x) < (1.06 - c.z) * 0.5: kill.append(f); continue
bmesh.ops.delete(bm, geom=kill, context='FACES')
tops_faces = [f for f in bm.faces if f.material_index == TOPS]
tv = {v for f in tops_faces for v in f.verts}
# Smooth the stair-stepped cut onto the ideal V / cutaway line.
bm.edges.ensure_lookup_table()
for e in bm.edges:
    if not (e.is_boundary and all(v in tv for v in e.verts)): continue
    for v in e.verts:
        if v.co.y <= 0.0: continue
        if 1.08 < v.co.z <= 1.42:
            want = v_half(v.co.z)
        elif v.co.z <= 1.06:
            want = (1.06 - v.co.z) * 0.5
        else:
            continue
        side = 1.0 if v.co.x >= 0 else -1.0
        if abs(abs(v.co.x) - want) < 0.05:
            v.co.x = side * max(want, 0.004)
print("tops verts", len(tv), "killed", len(kill))

# 3) Tailor: pull the baggy hoodie in toward the body, keeping a little of its fold detail.
for v in tv:
    loc, n, i, d = bvh.find_nearest(v.co)
    if loc is None: continue
    target = loc + n * (0.022 if v.co.z > 0.9 else 0.03)
    v.co = v.co.lerp(target, 0.72)

# Fit only the arm-weighted jacket sleeves. Fade the adjustment into the
# shoulder so the jacket body and its seam keep their tailored shape.
arm_groups = {g.index for g in body.vertex_groups
              if "UpperArm" in g.name or "LowerArm" in g.name}
lower_arm_groups = {g.index for g in body.vertex_groups if "LowerArm" in g.name}
for v in tv:
    weights = v[deform] if deform is not None else {}
    arm_weight = sum(weights.get(group, 0.0) for group in arm_groups)
    if arm_weight <= 0.45: continue
    blend = max(0.0, min(1.0, (arm_weight - 0.45) / 0.35))
    blend = blend * blend * (3.0 - 2.0 * blend)
    lower_weight = sum(weights.get(group, 0.0) for group in lower_arm_groups)
    # Compress the ribbed wrist band to a short, clean sleeve edge.
    if lower_weight > 0.5 and v.co.z < 1.315:
        v.co.z += 0.018 * min(1.0, (1.315 - v.co.z) / 0.04) * blend
    loc, n, i, d = bvh.find_nearest(v.co)
    if loc is not None:
        v.co = v.co.lerp(loc + n * 0.0135, 0.85 * blend)

# 5) Lapels: fold a strip outward along each side of the V opening.
bm.edges.ensure_lookup_table()
v_edges = [e for e in bm.edges if e.is_boundary and all(v in tv for v in e.verts)
           and all(v.co.y > 0.0 and 1.1 < v.co.z < 1.43 for v in e.verts)]
# Sample only the jacket, before adding the folded faces to the mesh.
jf = [f for f in bm.faces if f.material_index == TOPS]
jv = list({v for f in jf for v in f.verts}); jidx = {v: i for i, v in enumerate(jv)}
jbvh = BVHTree.FromPolygons([v.co.copy() for v in jv], [[jidx[v] for v in f.verts] for f in jf])
res = bmesh.ops.extrude_edge_only(bm, edges=v_edges)
lap_v = [g for g in res["geom"] if isinstance(g, bmesh.types.BMVert)]
# Keep the fold attached to its original edge, including its skin weights.
for v in lap_v:
    source = next((e.other_vert(v) for e in v.link_edges
                   if e.other_vert(v) in tv), None)
    if source is not None and deform is not None:
        for bone, weight in source[deform].items():
            v[deform][bone] = weight

# Relax only the free edge's height. The cut edge has uneven vertical spacing;
# carrying that spacing straight across the fold makes thin, pointed triangles.
lap_z = {}
for side in (-1, 1):
    chain = sorted((v for v in lap_v if v.co.x * side > 0), key=lambda v: v.co.z)
    if len(chain) < 3: continue
    heights = [v.co.z for v in chain]
    for _ in range(2):
        heights = [heights[0]] + [0.6 * heights[i] + 0.2 * (heights[i-1] + heights[i+1])
                                    for i in range(1, len(chain)-1)] + [heights[-1]]
    lap_z.update(zip(chain, heights))

for v in lap_v:
    z = lap_z.get(v, v.co.z)
    side = 1.0 if v.co.x > 0 else -1.0
    # A continuous width curve with a single, deliberate notch at collar height.
    notch = max(0.0, 1.0 - abs(z - 1.35) / 0.035)
    width = 0.03 + (z - 1.1) * 0.2 - 0.052 * notch * notch
    x = side * (v_half(z) + width)
    p = Vector((x, v.co.y, z))
    loc, n, i, d = jbvh.find_nearest(p)
    # Use the jacket only for depth: nearest-point X/Z jumps cause edge spikes.
    v.co = Vector((x, (loc.y if loc is not None else p.y) + 0.007, z))
for f in [g for g in res["geom"] if isinstance(g, bmesh.types.BMFace)]:
    f.material_index = TOPS
    for l in f.loops: l[uvl].uv = clean_uv
print("lapel edges", len(v_edges))

bm.normal_update(); bm.to_mesh(body.data); bm.free()
body.data.update()
render("suit")
bpy.ops.export_scene.gltf(filepath=W + "kaito_suit.glb", export_format='GLB', export_animations=False, export_skins=True, export_yup=True)
print("EXPORTED")
