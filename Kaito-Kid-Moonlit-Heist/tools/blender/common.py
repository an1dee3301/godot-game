import bpy, bmesh, math, sys
from mathutils import Vector
W = "/private/tmp/claude-501/-Users-andytran-Coding-Godot/eccd311a-705d-4e77-9182-c5a7d6315bd3/scratchpad/blender/"
def load():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=W + "src.glb")
    for o in list(bpy.data.objects):
        if o.type == 'MESH' and o.name.startswith("Icosphere"):
            bpy.data.objects.remove(o)
def render(name, views=(("front", (0, 2.6, 1.15)), ("side", (2.6, 0, 1.15)), ("back", (0, -2.6, 1.3)), ("face", (0.35, 0.9, 1.5)))):
    scn = bpy.context.scene
    scn.render.engine = 'BLENDER_EEVEE'
    scn.render.resolution_x = 900; scn.render.resolution_y = 900
    if not scn.world: scn.world = bpy.data.worlds.new("w")
    scn.world.color = (0.12, 0.13, 0.16)
    for o in [o for o in bpy.data.objects if o.type in ('LIGHT', 'CAMERA')]: bpy.data.objects.remove(o)
    for i, (rot, e) in enumerate([((-40, 0, 200), 3.0), ((-30, 0, 30), 1.5)]):
        L = bpy.data.lights.new("L%d" % i, 'SUN'); L.energy = e
        lo = bpy.data.objects.new("L%d" % i, L); scn.collection.objects.link(lo)
        lo.rotation_euler = [math.radians(a) for a in rot]
    cam = bpy.data.cameras.new("C"); co = bpy.data.objects.new("C", cam); scn.collection.objects.link(co); scn.camera = co
    for tag, pos in views:
        co.location = pos
        target = Vector((0, 0, 1.55 if tag == "face" else 1.0))
        d = target - Vector(pos); co.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
        cam.lens = 85 if tag == "face" else 50
        scn.render.filepath = W + "%s_%s.png" % (name, tag)
        bpy.ops.render.render(write_still=True)
