"""Blender-authored festival dressing for Trust Me, Bro!.
Original geometry and flat materials only: no images, texture generators,
paid assets or third-party meshes.
Run with Blender (--background --python tools/build_festival.py) or with the
`bpy` Python module (python tools/build_festival.py).
Coordinates below are game Y-up; the export converts to glTF Y-up.
"""
import bpy, bmesh, math, random, pathlib, json
from mathutils import Vector
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'world'
SOURCE = ROOT / 'tools' / 'source'
OUT.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(parents=True, exist_ok=True)
bpy.context.preferences.filepaths.save_version = 0
random.seed(2111)
PALETTE = {
    'cream': 'fff1d5', 'white': 'fffdf0', 'navy': '263854', 'deep': '172c45',
    'wood': 'bb8057', 'wood_light': 'e1af78', 'wood_dark': '845841',
    'coral': 'ef6b65', 'coral_dark': 'c74a55', 'blue': '68aed8', 'mint': '67bdae',
    'yellow': 'edc765', 'ink': '1b2940', 'rope': '3a4763',
    # Emissive materials keep a `bulb_` prefix so the game can dim them in Lights Out.
    'bulb_warm': 'ffe6a3', 'bulb_coral': 'ff8d86', 'bulb_mint': '8ff0cf', 'bulb_blue': '8fd0ff',
    'fan_body': 'ffffff', 'fan_face': '1b2940', 'balloon': 'ffffff', 'sail': 'fffdf0',
}
EMISSION = {'bulb_warm': 3.2, 'bulb_coral': 2.6, 'bulb_mint': 2.6, 'bulb_blue': 2.6}
MATS = {}


def gp(p):
    return (p[0], -p[2], p[1])


def linear(hex_color):
    rgb = tuple(int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return tuple(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb) + (1,)


def mat(name):
    if name not in MATS:
        m = bpy.data.materials.new(name)
        rgba = linear(PALETTE[name])
        m.diffuse_color = rgba
        bs = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        bs.inputs['Base Color'].default_value = rgba
        bs.inputs['Roughness'].default_value = .35 if name == 'balloon' else .68
        if name in EMISSION:
            bs.inputs['Emission Color'].default_value = rgba
            bs.inputs['Emission Strength'].default_value = EMISSION[name]
        MATS[name] = m
    return MATS[name]


def reset():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for block in list(bpy.data.meshes):
        if block.users == 0:
            bpy.data.meshes.remove(block)


def setup(o, name, p, m):
    o.name = name
    o.location = gp(p)
    o.data.materials.clear()
    o.data.materials.append(mat(m))
    return o


def finish(o, bevel=0.0, smooth=False):
    bpy.context.view_layer.objects.active = o
    if bevel:
        mod = o.modifiers.new('Crafted roundover', 'BEVEL')
        mod.width = bevel
        mod.segments = 3
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for p in o.data.polygons:
        p.use_smooth = smooth
    if bevel:
        mod = o.modifiers.new('Weighted normals', 'WEIGHTED_NORMAL')
        mod.keep_sharp = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return o


def cube(name, p, s, m, bevel=.10, rotation=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1)
    o = setup(bpy.context.object, name, p, m)
    o.dimensions = (s[0], s[2], s[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.rotation_euler.z = -rotation
    return finish(o, min(bevel, min(s) * .43), True)


def cyl(name, p, r, h, m, vertices=24, bevel=.05, top=None):
    if top is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=r, depth=h)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r, radius2=top, depth=h)
    return finish(setup(bpy.context.object, name, p, m), min(bevel, h * .2), True)


def sphere(name, p, s, m, segments=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1)
    o = setup(bpy.context.object, name, p, m)
    o.scale = (s[0], s[2], s[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o, 0, True)


def beam(name, a, b, r, m, vertices=10, top=None):
    pa, pb = Vector(gp(a)), Vector(gp(b))
    if top is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=r, depth=(pb - pa).length)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r, radius2=top, depth=(pb - pa).length)
    o = setup(bpy.context.object, name, (0, 0, 0), m)
    o.location = (pa + pb) / 2
    o.rotation_euler = (pb - pa).to_track_quat('Z', 'Y').to_euler()
    return finish(o, 0, True)


def torus(name, p, major, minor, m, flat=True):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=24, minor_segments=10)
    o = setup(bpy.context.object, name, p, m)
    if not flat:
        o.rotation_euler.x = math.pi / 2
    return finish(o, 0, True)


def mesh(name, verts, faces, m):
    data = bpy.data.meshes.new(name)
    data.from_pydata([gp(v) for v in verts], [], faces)
    data.update()
    o = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(o)
    data.materials.append(mat(m))
    return o


def sheet(name, a, b, c, m):
    """A two-sided cloth triangle; each side owns its vertices so the mesh stays valid."""
    return mesh(name, [a, b, c, a, b, c], [(0, 1, 2), (5, 4, 3)], m)


def flag(name, a, b, drop, m):
    """A double-sided pennant hanging between two points of a garland."""
    ax, ay, az = a
    bx, by, bz = b
    mx, my, mz = (ax + bx) / 2, (ay + by) / 2 - drop, (az + bz) / 2
    return sheet(name, a, b, (mx, my, mz), m)


def catenary(a, b, sag, steps):
    a, b = Vector(a), Vector(b)
    points = []
    for i in range(steps + 1):
        t = i / steps
        p = a.lerp(b, t)
        p.y -= sag * 4 * t * (1 - t)
        points.append(tuple(p))
    return points


BULBS = ['bulb_warm', 'bulb_coral', 'bulb_warm', 'bulb_mint', 'bulb_warm', 'bulb_blue']


def garland(name, a, b, sag, bulbs, start=0):
    points = catenary(a, b, sag, bulbs * 2)
    for i in range(len(points) - 1):
        beam(name + ' wire', points[i], points[i + 1], .022, 'rope', 6)
    for k in range(1, bulbs * 2, 2):
        x, y, z = points[k]
        cyl(name + ' socket', (x, y - .05, z), .055, .09, 'navy', 10, .01)
        sphere(name + ' bulb', (x, y - .19, z), (.13, .15, .13), BULBS[(start + k // 2) % len(BULBS)], 12, 8)


def bunting(name, a, b, sag, count):
    points = catenary(a, b, sag, count)
    colors = ['coral', 'yellow', 'mint', 'blue', 'cream']
    for i in range(count):
        beam(name + ' cord', points[i], points[i + 1], .018, 'rope', 6)
        flag(name + ' pennant', points[i], points[i + 1], .46, colors[i % len(colors)])


def lamp(name, at, target, m='bulb_warm'):
    a, t = Vector(at), Vector(target)
    d = (t - a).normalized()
    beam(name + ' can', tuple(a - d * .18), tuple(a + d * .46), .25, 'navy', 16, top=.31)
    beam(name + ' lens', tuple(a + d * .44), tuple(a + d * .50), .27, m, 16)
    beam(name + ' yoke', tuple(a - d * .05 + Vector((0, .34, 0))), tuple(a - d * .05 - Vector((0, .02, 0))), .045, 'cream', 8)


def join_by_material(prefix):
    grouped = {}
    for o in list(bpy.context.scene.objects):
        if o.type == 'MESH':
            grouped.setdefault(o.data.materials[0].name, []).append(o)
    for name_, objects in grouped.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        if len(objects) > 1:
            bpy.ops.object.join()
        o = objects[0]
        o.name = prefix + '_' + name_
        o.data.name = o.name
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bmesh.ops.dissolve_degenerate(bm, dist=1e-6, edges=list(bm.edges))
        bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
        bm.to_mesh(o.data)
        bm.free()
    return grouped


def export(filename, prefix):
    grouped = join_by_material(prefix)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(OUT / filename), export_format='GLB', export_apply=True,
                              export_yup=True, export_animations=False, export_cameras=False,
                              export_lights=False)
    stats = {'meshes': len(grouped), 'triangles': 0, 'materials': sorted(grouped)}
    for o in bpy.context.scene.objects:
        if o.type == 'MESH':
            o.data.calc_loop_triangles()
            stats['triangles'] += len(o.data.loop_triangles)
    return stats


WATER = -4.95
STATS = {}
LAYOUT = {'fan_seats': [], 'lamps': [], 'balloon_anchors': [], 'water': WATER}

# ---------------------------------------------------------------- dressing kit
reset()


def barge(side):
    """A moored spectator barge beside the showground. `side` is -1 or +1."""
    cx, cz, length = side * 13.6, -9.4, 11.4
    tag = 'Port' if side < 0 else 'Starboard'
    lift = WATER + 7.7
    cube(tag + ' barge navy hull', (cx, WATER + .55, cz), (4.3, 1.5, length), 'navy', .42)
    cube(tag + ' barge coral waterline', (cx, WATER + 1.22, cz), (4.38, .24, length + .08), 'coral', .10)
    cube(tag + ' barge timber gunwale', (cx, WATER + 1.46, cz), (4.5, .28, length + .2), 'wood', .12)
    # Three rising tiers; the tallest sits furthest from the stage.
    for k in range(3):
        x = cx - side * 1.25 + side * k * 1.25
        top = lift - 4.9 + k * 1.05
        height = top - (WATER + 1.5)
        cube(tag + ' grandstand tier', (x, WATER + 1.5 + height / 2, cz), (1.27, height, length - .7), 'wood_light' if k % 2 else 'wood', .08)
        cube(tag + ' grandstand cream tread', (x, top + .04, cz), (1.31, .10, length - .62), 'cream', .04)
        for row in range(10):
            z = cz - (length - 1.9) / 2 + row * (length - 1.9) / 9
            LAYOUT['fan_seats'].append([round(x, 3), round(top + .09, 3), round(z, 3)])
    # Stage-side safety rail and a back wall finish the silhouette.
    rail_x = cx - side * 2.02
    for row in range(6):
        z = cz - length / 2 + .55 + row * (length - 1.1) / 5
        cyl(tag + ' rail post', (rail_x, lift - 4.42, z), .07, 1.0, 'cream', 10, .02)
    beam(tag + ' rail cap', (rail_x, lift - 3.94, cz - length / 2 + .5), (rail_x, lift - 3.94, cz + length / 2 - .5), .075, 'coral', 10)
    back_x = cx + side * 2.0
    cube(tag + ' barge back wall', (back_x, lift - 2.25, cz), (.26, 2.9, length - .5), 'navy', .08)
    cube(tag + ' barge back wall cap', (back_x, lift - .76, cz), (.4, .14, length - .36), 'cream', .05)
    for k, letter_color in enumerate(['coral', 'yellow', 'mint', 'blue']):
        z = cz - 3.6 + k * 2.4
        cyl(tag + ' back wall roundel', (back_x - side * .15, lift - 1.9, z), .52, .08, letter_color, 24, .02).rotation_euler.y = math.pi / 2
    # Masts carry the stage lamps and string lights.
    masts = []
    for z, height in ((cz - length / 2 + .7, 9.4), (cz + length / 2 - .7, 7.6)):
        mx = cx + side * 1.55
        top = lift - 1.2 + height - 6.2
        cyl(tag + ' mast foot', (mx, lift - 2.72, z), .34, .28, 'navy', 16, .05)
        cyl(tag + ' mast', (mx, (lift - 2.6 + top) / 2, z), .13, top - lift + 2.6, 'wood_light', 12, .02, top=.09)
        sphere(tag + ' mast finial', (mx, top + .12, z), (.17, .17, .17), 'yellow', 12, 8)
        cube(tag + ' mast yard', (mx - side * .35, top - .55, z), (1.5, .12, .12), 'cream', .04)
        masts.append((mx, top, z))
        for dx in (-.9, -.2):
            at = (mx + side * dx, top - .92, z)
            target = (side * 2.2, 0.0, z * .25)
            lamp(tag + ' stage lamp', at, target)
            LAYOUT['lamps'].append({'at': [round(v, 3) for v in at], 'target': [round(v, 3) for v in target]})
        LAYOUT['balloon_anchors'].append([round(mx, 3), round(top + .2, 3), round(z, 3)])
    bunting(tag + ' barge bunting', (masts[0][0], masts[0][1] - .25, masts[0][2]), (masts[1][0], masts[1][1] - .25, masts[1][2]), 1.1, 14)
    # Mooring line and a life ring on the bow.
    torus(tag + ' bow life ring', (cx, WATER + 1.0, cz + length / 2 + .05), .42, .13, 'cream', flat=False)
    for a in range(4):
        angle = a * math.pi / 2 + math.pi / 4
        sphere(tag + ' life ring band', (cx + math.cos(angle) * .42, WATER + 1.0 + math.sin(angle) * .42, cz + length / 2 + .07), (.15, .15, .15), 'coral', 10, 6)
    return masts


def tower(side):
    """A front-of-house lighting tower on the promenade."""
    x, z, base = side * 9.15, 7.35, -.97
    tag = 'Left' if side < 0 else 'Right'
    cube(tag + ' tower plinth', (x, base + .2, z), (1.05, .4, 1.05), 'navy', .12)
    cube(tag + ' tower plinth cap', (x, base + .44, z), (.86, .1, .86), 'cream', .04)
    top = 4.1
    for dx, dz in ((-.24, -.24), (.24, -.24), (-.24, .24), (.24, .24)):
        beam(tag + ' tower leg', (x + dx, base + .45, z + dz), (x + dx * .55, top, z + dz * .55), .055, 'wood_light', 8)
    for k in range(4):
        y = base + .9 + k * 1.0
        s = .24 - (.24 - .13) * (y - base - .45) / (top - base - .45)
        for a, b in (((-s, -s), (s, -s)), ((s, -s), (s, s)), ((s, s), (-s, s)), ((-s, s), (-s, -s))):
            beam(tag + ' tower brace', (x + a[0], y, z + a[1]), (x + b[0], y, z + b[1]), .03, 'cream', 6)
    cube(tag + ' tower head', (x, top + .1, z), (1.9, .16, .5), 'navy', .06)
    sphere(tag + ' tower finial', (x, top + .42, z), (.17, .2, .17), 'yellow', 12, 8)
    for dx in (-.62, 0, .62):
        at = (x + dx, top - .28, z - .05)
        target = (dx * 3.0 - side * 2.0, 0.0, 1.0)
        lamp(tag + ' tower lamp', at, target, 'bulb_coral' if dx == 0 else 'bulb_warm')
        LAYOUT['lamps'].append({'at': [round(v, 3) for v in at], 'target': [round(v, 3) for v in target]})
    LAYOUT['balloon_anchors'].append([round(x, 3), round(base + .6, 3), round(z + .5, 3)])
    return (x, top + .18, z)


for side_ in (-1, 1):
    masts_ = barge(side_)
    tower_top = tower(side_)
    tag_ = 'Left' if side_ < 0 else 'Right'
    # String lights: front tower -> near mast -> far mast -> giant screen corner.
    garland(tag_ + ' festoon front', tower_top, (masts_[1][0], masts_[1][1] - .1, masts_[1][2]), 1.5, 9, 0)
    garland(tag_ + ' festoon barge', (masts_[1][0], masts_[1][1] - .1, masts_[1][2]), (masts_[0][0], masts_[0][1] - .1, masts_[0][2]), 1.2, 8, 3)
    garland(tag_ + ' festoon screen', (masts_[0][0], masts_[0][1] - .1, masts_[0][2]), (side_ * 11.2, 7.72, -14.0), .7, 4, 1)
    for anchor in ((side_ * 6.9, 2.7, -10.0), (side_ * 9.7, .75, 2.8)):
        LAYOUT['balloon_anchors'].append(list(anchor))

# A marquee bulb run around the giant screen shell (23.0 x 5.2 m, centred y=5.2).
marquee = []
w, h, r, z_front = 22.82, 5.02, .42, -13.74
for i in range(-13, 14):
    marquee.append((i * (w - 2 * r) / 26, 5.2 + h / 2))
for i in range(-2, 3):
    marquee.append((w / 2, 5.2 + i * (h - 2 * r) / 4))
for i in range(13, -14, -1):
    marquee.append((i * (w - 2 * r) / 26, 5.2 - h / 2))
for i in range(2, -3, -1):
    marquee.append((-w / 2, 5.2 + i * (h - 2 * r) / 4))
LAYOUT['marquee'] = [[round(x, 3), round(y, 3), z_front] for x, y in marquee]
STATS['festival_dressing'] = export('festival_dressing.glb', 'Festival')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / 'festival_dressing.blend'))

# ------------------------------------------------------------------- crowd fan
reset()
sphere('Fan round body', (0, .36, 0), (.33, .36, .30), 'fan_body', 14, 9)
sphere('Fan head', (0, .86, 0), (.27, .25, .25), 'fan_body', 14, 9)
for sx in (-1, 1):
    sphere('Fan ear', (sx * .2, 1.09, 0), (.09, .11, .07), 'fan_body', 8, 6)
    sphere('Fan raised arm', (sx * .37, .66, .02), (.09, .2, .09), 'fan_body', 8, 6).rotation_euler.y = -sx * .5
    sphere('Fan foot', (sx * .15, .05, .08), (.12, .07, .15), 'fan_body', 8, 6)
    sphere('Fan eye', (sx * .1, .9, .225), (.038, .05, .03), 'fan_face', 8, 6)
sphere('Fan happy mouth', (0, .79, .235), (.06, .035, .03), 'fan_face', 8, 6)
STATS['crowd_fan'] = export('crowd_fan.glb', 'Fan')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / 'crowd_fan.blend'))

# --------------------------------------------------------------------- balloon
reset()
sphere('Balloon envelope', (0, 1.55, 0), (.42, .5, .42), 'balloon', 18, 12)
cyl('Balloon knot', (0, 1.02, 0), .06, .09, 'balloon', 10, .01, top=.02)
points_ = [(math.sin(i * .9) * .04, 1.0 - i * .1, math.cos(i * 1.3) * .03) for i in range(11)]
for i in range(10):
    beam('Balloon string', points_[i], points_[i + 1], .012, 'rope', 5)
STATS['party_balloon'] = export('party_balloon.glb', 'Balloon')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / 'party_balloon.blend'))

# -------------------------------------------------------------------- sailboat
reset()
hull = cube('Dinghy hull', (0, .16, 0), (.9, .42, 2.3), 'coral', .2)
cube('Dinghy cream deck', (0, .39, 0), (.78, .08, 2.05), 'cream', .04)
cube('Dinghy bench', (0, .47, .45), (.7, .08, .26), 'wood', .03)
cyl('Dinghy mast', (0, 1.75, -.15), .045, 2.7, 'wood_light', 8, .01)
beam('Dinghy boom', (0, .78, -.15), (0, .82, 1.0), .035, 'wood_light', 8)
sheet('Dinghy main sail', (0, .88, -.1), (0, 3.02, -.15), (0, .9, .98), 'sail')
sheet('Dinghy jib', (0, .7, -.28), (0, 2.6, -.2), (0, .62, -1.08), 'yellow')
sheet('Dinghy pennant', (0, 3.1, -.15), (0, 2.92, -.15), (0, 3.01, .32), 'coral')
STATS['sailboat'] = export('sailboat.glb', 'Boat')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / 'sailboat.blend'))

# ------------------------------------------------------------------------ buoy
reset()
cyl('Buoy float', (0, .12, 0), .46, .34, 'coral', 20, .09)
cyl('Buoy cream band', (0, .12, 0), .475, .1, 'cream', 20, .02)
cyl('Buoy tower', (0, .72, 0), .24, .9, 'cream', 14, .04, top=.12)
cyl('Buoy tower stripe', (0, .62, 0), .215, .2, 'coral', 14, .02, top=.19)
sphere('Buoy lamp', (0, 1.28, 0), (.14, .16, .14), 'bulb_warm', 12, 8)
STATS['buoy'] = export('buoy.glb', 'Buoy')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / 'buoy.blend'))

(OUT / 'festival_stats.json').write_text(json.dumps(STATS, indent=2))
(OUT / 'festival_layout.json').write_text(json.dumps(LAYOUT, indent=1))
print('FESTIVAL_EXPORT', json.dumps(STATS))
