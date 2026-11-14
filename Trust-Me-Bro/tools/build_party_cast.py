"""Original party mascots modeled in Blender. No external or generated imagery.
Run: Blender --background --python tools/build_party_cast.py
Coordinate system: Blender -Y faces front, +Z up, origin at collider centre.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'characters'
OUT.mkdir(parents=True,exist_ok=True)
SOURCES = OUT.parents[1] / 'art' / 'source'
SOURCES.mkdir(parents=True,exist_ok=True)

def material(name, color, rough=.42):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1)
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Roughness'].default_value=rough
    return m

def empty(name, at=(0,0,0), parent=None):
    o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.location=at;o.parent=parent;return o

def sphere(name,at,scale,mat,parent=None,segments=20,rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=(0,0,0))
    o=bpy.context.object;o.name='SM_'+name;o.parent=parent;o.location=at;o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat)
    for face in o.data.polygons:face.use_smooth=True
    return o

def cone(name,at,scale,mat,parent=None,angle=0):
    bpy.ops.mesh.primitive_cone_add(vertices=4,radius1=1,radius2=.07,depth=2)
    o=bpy.context.object;o.name='SM_'+name;o.parent=parent;o.location=at;o.scale=scale;o.rotation_euler[1]=angle
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    bevel=o.modifiers.new('Soft sculpted edges','BEVEL');bevel.width=.08;bevel.segments=3
    o.data.materials.append(mat)
    for face in o.data.polygons:face.use_smooth=True
    return o

def ring(name,at,major,minor,mat,parent=None,rotation=(math.pi/2,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major,minor_radius=minor,major_segments=24,minor_segments=8)
    o=bpy.context.object;o.name='SM_'+name;o.parent=parent;o.location=at;o.rotation_euler=rotation;o.data.materials.append(mat)
    for face in o.data.polygons:face.use_smooth=True
    return o

def build(kind):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for m in list(bpy.data.materials):
        if m.users==0:bpy.data.materials.remove(m)
    coat=material('M_Coat',(1,1,1));cream=material('M_Cream',(1,.965,.84));ink=material('M_Ink',(.045,.065,.1),.28)
    boot=material('M_Boot',(.7,.7,.7));blush=material('M_Blush',(1,.42,.48));gold=material('M_Gold',(1,.66,.11),.28)
    green=material('M_Leaf',(.23,.74,.23));orange=material('M_Beak',(1,.37,.075));pearl=material('M_Pearl',(1,1,1),.23)
    root=empty('PartyMascot')
    body=empty('Body',parent=root)
    sphere('Body',(0,.025,-.18),(.43,.33,.51),coat,body)
    sphere('Belly',(0,-.265,-.17),(.32,.095,.34),cream,body)
    head=empty('Head',(0,0,.40),root)
    sphere('Head',(0,0,0),(.54,.39,.47),coat,head)
    # Brow/muzzle geometry and bright eyes read clearly from the shared camera.
    sphere('Muzzle',(0,-.333,-.10),(.38,.13,.25),cream,head)
    eyes=[]
    for x,side in ((-.19,'L'),(.19,'R')):
        # Keep each complete eye as one mesh around its own blink pivot.
        eye=empty('Eye'+side,(x,-.352,.095),head);eyes.append(eye)
        sphere('EyeWhite',(0,0,0),(.13,.075,.18),pearl,eye)
        sphere('Pupil',(0,-.070,-.005),(.064,.028,.106),ink,eye)
        sphere('EyeSpark',(-.018,-.098,.039),(.022,.012,.031),pearl,eye,12,8)
        sphere('Cheek',(math.copysign(.34,x),-.39,-.075),(.075,.025,.045),blush,head,12,8)
    sphere('Nose',(0,-.465,-.065),(.075,.044,.053),ink,head)
    sphere('Mouth',(0,-.456,-.175),(.088,.026,.041),ink,head)
    sphere('MouthSmile',(0,-.472,-.158),(.085,.018,.029),cream,head)
    for sign,side in ((-1,'L'),(1,'R')):
        arm=empty('Arm'+side,(sign*.43,0,-.08),root)
        sphere('Arm'+side,(sign*.105,0,-.12),(.19,.22,.32),coat,arm)
        sphere('Glove'+side,(sign*.14,-.04,-.30),(.205,.20,.205),cream,arm)
        foot=empty('Foot'+side,(sign*.235,0,-.62),root)
        sphere('Boot'+side,(0,-.09,-.075),(.25,.32,.205),boot,foot)
        sphere('Sole'+side,(0,-.10,-.19),(.245,.29,.065),cream,foot)
    if kind=='Bun':
        for sign in (-1,1):
            e=sphere('Ear',(sign*.28,.015,.58),(.145,.14,.48),coat,head);e.rotation_euler[1]=sign*.17
            e=sphere('EarInner',(sign*.29,-.11,.60),(.073,.035,.32),blush,head);e.rotation_euler[1]=sign*.17
        sphere('Tail',(0,.35,-.30),(.21,.22,.21),cream,body)
    elif kind=='Cub':
        for sign in (-1,1):
            sphere('Ear',(sign*.43,.0,.31),(.22,.15,.225),boot,head)
            sphere('EarInner',(sign*.43,-.12,.31),(.115,.035,.12),cream,head)
        # Original little explorer cap, deliberately broad and friendly.
        sphere('CapTop',(0,.03,.40),(.4,.32,.16),gold,head)
        sphere('CapBrim',(0,-.28,.36),(.40,.27,.047),gold,head)
        sphere('CapButton',(0,.03,.55),(.055,.055,.055),cream,head,12,8)
    elif kind=='Pip':
        sphere('Bill',(0,-.43,-.105),(.235,.18,.092),orange,head)
        for sign in (-1,1):
            tuft=sphere('Tuft',(sign*.09,.01,.50),(.08,.10,.23),gold,head);tuft.rotation_euler[1]=sign*.25
        sphere('Tail',(0,.31,-.28),(.20,.28,.15),gold,body)
    else:
        # Garden sprite, with petal-like ears and an actual leaf sprout.
        for sign in (-1,1):
            sphere('PetalEar',(sign*.45,0,.30),(.235,.14,.25),coat,head)
            sphere('EarCentre',(sign*.47,-.125,.32),(.11,.025,.12),green,head)
            leaf=sphere('Leaf',(sign*.16,.03,.56),(.23,.065,.12),green,head);leaf.rotation_euler[1]=-sign*.45
        sphere('LeafStem',(0,.04,.50),(.045,.045,.16),gold,head,12,8)
    # One joined mesh per animated limb group gives a tiny draw-call footprint.
    for group in (body,head,*eyes,*[bpy.data.objects[n] for n in ('ArmL','ArmR','FootL','FootR')]):
        meshes=[o for o in group.children if o.type=='MESH']
        if not meshes:continue
        bpy.ops.object.select_all(action='DESELECT')
        for o in meshes:o.select_set(True)
        bpy.context.view_layer.objects.active=meshes[0]
        # Bake the bevel only for this export; preserve source build operations.
        bpy.ops.object.join()
        joined=bpy.context.object;joined.name='SM_'+group.name
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCES/(kind.lower()+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(kind.lower()+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False)
    tris=sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons)
    return {'character':kind,'triangles':tris,'file':kind.lower()+'.glb','bytes':(OUT/(kind.lower()+'.glb')).stat().st_size}

report=[build(k) for k in ('Bun','Cub','Pip','Sprout')]
(OUT/'manifest.json').write_text(json.dumps({'author':'Original modeled assets for Trust Me, Bro!','pipeline':'Blender geometry modeling; no generated images or video','characters':report},indent=2))
(OUT/'LICENSE.txt').write_text('Original models created for this project in Blender. No third-party models, textures, or generated images were used. Source build script: tools/build_party_cast.py.\n')
print('PARTY_CAST_BUILT',json.dumps(report))
