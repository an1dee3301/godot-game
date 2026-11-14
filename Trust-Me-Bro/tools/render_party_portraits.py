"""Conventional Blender renders of the original modeled mascots; no AI imagery."""
import bpy,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'characters'/'portraits';OUT.mkdir(exist_ok=True)
COLORS=['ff6b61','6daaff','87eed0','ffe17c','be9bff','ff9ed1','fca66c','a4d8f0']
KINDS=['bun','cub','pip','sprout']
def linear(c):
    return c/12.92 if c<.04045 else ((c+.055)/1.055)**2.4
for i,color in enumerate(COLORS):
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art'/'source'/(KINDS[i%4]+'.blend')))
    rgb=tuple(linear(int(color[j:j+2],16)/255) for j in (0,2,4))
    for mat in bpy.data.materials:
        if mat.name.startswith('M_Coat') or mat.name.startswith('M_Boot'):
            value=tuple(v*.55 for v in rgb) if mat.name.startswith('M_Boot') else rgb
            mat.diffuse_color=(*value,1)
            shader=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
            shader.inputs['Base Color'].default_value=(*value,1)
    scene=bpy.context.scene
    scene.render.engine='BLENDER_EEVEE'
    scene.render.resolution_x=256;scene.render.resolution_y=256;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
    scene.render.film_transparent=True
    scene.view_settings.view_transform='Standard';scene.view_settings.exposure=-.3
    if hasattr(scene,'eevee') and hasattr(scene.eevee,'taa_render_samples'):scene.eevee.taa_render_samples=24
    scene.world=bpy.data.worlds.new('PortraitWorld')
    bg=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND')
    bg.inputs[0].default_value=(.50,.60,.75,1);bg.inputs[1].default_value=.35
    for label,pos,power,size in [('Key',(-3,-5,6),650,5),('Rim',(3,1,4),400,4)]:
        data=bpy.data.lights.new(label,'AREA');data.energy=power;data.shape='DISK';data.size=size
        lamp=bpy.data.objects.new(label,data);scene.collection.objects.link(lamp);lamp.location=pos
        lamp.rotation_euler=(Vector((0,0,.3))-lamp.location).to_track_quat('-Z','Y').to_euler()
    data=bpy.data.cameras.new('PortraitCamera');camera=bpy.data.objects.new('PortraitCamera',data);scene.collection.objects.link(camera)
    camera.location=(2,-6,2.2);camera.rotation_euler=(Vector((0,0,.40))-camera.location).to_track_quat('-Z','Y').to_euler()
    data.type='ORTHO';data.ortho_scale=2.6;scene.camera=camera
    scene.render.filepath=str(OUT/('avatar_%d.png'%i))
    bpy.ops.render.render(write_still=True)
    print('PORTRAIT_RENDERED',i)
