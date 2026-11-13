"""Blender-authored, original game-show set for Trust Me, Bro!.
No images, texture generators, paid assets or third-party meshes are used.
Run from Blender: --background --python tools/build_showground.py
Coordinates below are game Y-up; the export converts to glTF Y-up.
"""
import bpy, bmesh, math, random, pathlib, json, importlib.util
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'world'; OUT.mkdir(parents=True,exist_ok=True)
SOURCE=ROOT/'tools'/'source';SOURCE.mkdir(parents=True,exist_ok=True)
(ROOT/'tools'/'.gdignore').touch();(SOURCE/'.gdignore').touch()
bpy.context.preferences.filepaths.save_version=0
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
random.seed(5743)
PALETTE={'cream':'fff1d5','white':'fffdf0','navy':'263854','deep':'172c45','wood':'bb8057','wood_light':'e1af78','wood_dark':'845841','coral':'ef6b65','coral_dark':'c74a55','blue':'68aed8','mint':'67bdae','yellow':'edc765','leaf':'4b986f','leaf_light':'7cbd82','leaf_dark':'33745b','signal':'edc765','Screen_Face':'fff4df','Screen_Answer_A':'fa636b','Screen_Answer_B':'51a6f5','Screen_Answer_C':'47cda4','Screen_Answer_D':'ffcf4d'}
MATS={}
def gp(p):return (p[0],-p[2],p[1])
def mat(name):
    if name not in MATS:
        m=bpy.data.materials.new(name); rgba=tuple(int(PALETTE[name][i:i+2],16)/255 for i in (0,2,4))+(1,)
        rgba=tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgba[:3])+(1,)
        m.diffuse_color=rgba
        if name.startswith('Screen_'):
            # A color output connected directly to Surface is exported as KHR_materials_unlit.
            output=next(n for n in m.node_tree.nodes if n.type=='OUTPUT_MATERIAL')
            rgb=m.node_tree.nodes.new('ShaderNodeRGB');rgb.outputs[0].default_value=rgba
            m.node_tree.links.new(rgb.outputs[0],output.inputs['Surface'])
        else:
            bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bs.inputs['Base Color'].default_value=rgba;bs.inputs['Roughness'].default_value=.68
        MATS[name]=m
    return MATS[name]
def setup(o,name,p,m):
    o.name=name;o.location=gp(p);o.data.materials.clear();o.data.materials.append(mat(m));return o

def finish(o,bevel=0,smooth=False):
    bpy.context.view_layer.objects.active=o
    if bevel:
        mod=o.modifiers.new('Crafted roundover','BEVEL');mod.width=bevel;mod.segments=3;bpy.ops.object.modifier_apply(modifier=mod.name)
    for p in o.data.polygons:p.use_smooth=smooth
    if bevel:
        mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');mod.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=mod.name)
    return o

def cube(name,p,s,m,bevel=.10,rotation=0):
    bpy.ops.mesh.primitive_cube_add(size=1);o=setup(bpy.context.object,name,p,m);o.dimensions=(s[0],s[2],s[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.rotation_euler.z=-rotation
    return finish(o,min(bevel,min(s)*.43),True)
def cyl(name,p,r,h,m,vertices=32,bevel=.06,top=None):
    if top is None:bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=h)
    else:bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r,radius2=top,depth=h)
    return finish(setup(bpy.context.object,name,p,m),min(bevel,h*.2),True)
def sphere(name,p,s,m):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=1);o=setup(bpy.context.object,name,p,m);o.scale=(s[0],s[2],s[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,0,True)
def beam(name,a,b,r,m):
    pa,pb=Vector(gp(a)),Vector(gp(b));bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=r,depth=(pb-pa).length);o=setup(bpy.context.object,name,(0,0,0),m);o.location=(pa+pb)/2;o.rotation_euler=(pb-pa).to_track_quat('Z','Y').to_euler();return finish(o,0,True)
def mesh(name,verts,faces,m):
    data=bpy.data.meshes.new(name);data.from_pydata([gp(v)for v in verts],[],faces);data.update();o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);data.materials.append(mat(m));return o
def outline(w,d,z=0,n=96,power=4):
    points=[]
    for i in range(n):
        a=math.tau*i/n;u,v=math.cos(a),math.sin(a)
        points.append((math.copysign(abs(u)**(2/power),u)*w/2,math.copysign(abs(v)**(2/power),v)*d/2+z))
    return points

def ring(name,w,d,iw,id,y0,y1,m,z=-1.7,iz=0,power=4):
    out=outline(w,d,z,power=power);inside=outline(iw,id,iz,power=power if iw>w*.9 else 8);n=len(out)
    verts=[(x,y,zz)for y,path in ((y0,out),(y1,out),(y0,inside),(y1,inside))for x,zz in path];faces=[]
    for i in range(n):
        j=(i+1)%n
        faces.extend([(i,j,n+j,n+i),(n+i,n+j,3*n+j,3*n+i),(2*n+i,3*n+i,3*n+j,2*n+j),(i,2*n+i,2*n+j,j)])
    return finish(mesh(name,verts,faces,m),.045,False)
def solid_slab(name,w,d,y,h,m,z=0,power=4):
    path=outline(w,d,z,power=power);n=len(path);vs=[(x,yy,zz)for yy in(y-h/2,y+h/2)for x,zz in path];fs=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n)for i in range(n)]
    return finish(mesh(name,vs,fs,m),.08,False)
def star(name,p,r,m,depth=.12):
    x,y,z=p;v=[]
    for zz in (-depth/2,depth/2):
        for i in range(10):
            a=math.pi/2+i*math.pi/5;rr=r if i%2==0 else r*.46;v.append((x+math.cos(a)*rr,y+math.sin(a)*rr,z+zz))
    fs=[tuple(range(9,-1,-1)),tuple(range(10,20))]+[(i,(i+1)%10,(i+1)%10+10,i+10)for i in range(10)]
    return finish(mesh(name,v,fs,m),.03,False)
def tree(x,z,h=3.4):
    y=-.88
    cyl('Shaped orchard trunk',(x,y+h*.38,z),.24,h*.76,'wood',16,.06,top=.17)
    beam('Single branching bough',(x,y+h*.48,z),(x-.55,y+h*.74,z+.08),.13,'wood_light')
    for off,s,c in [((0,h*.82,0),(1.02,1.15,.94),'leaf'),((-.68,h*.8,.03),(.76,.83,.72),'leaf_light'),((.65,h*.85,-.12),(.75,.86,.73),'leaf'),((.04,h*1.06,-.12),(.72,.78,.68),'leaf_light')]:sphere('Pruned round canopy',(x+off[0],y+off[1],z+off[2]),s,c)
    for dx,dy in [(-.55,h*.83),(.4,h*.98)]:sphere('Small coral orchard fruit',(x+dx,y+dy,z+.67),(.14,.15,.14),'coral')
def export(name):
    grouped={}
    for o in list(bpy.context.scene.objects):
        if o.type=='MESH':grouped.setdefault(o.data.materials[0].name,[]).append(o)
    for name_,objects in grouped.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=objects[0];o.name=name_ if name_.startswith('Screen_') else 'Showground_'+name_
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.dissolve_degenerate(bm,dist=1e-6,edges=list(bm.edges));bmesh.ops.triangulate(bm,faces=[f for f in bm.faces if len(f.verts)>4]);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
    bpy.ops.object.select_all(action='SELECT');bpy.ops.export_scene.gltf(filepath=str(OUT/name),export_format='GLB',export_apply=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
    stats={'meshes':len(grouped),'triangles':0,'materials':list(grouped)}
    for o in bpy.context.scene.objects:
        if o.type=='MESH':o.data.calc_loop_triangles();stats['triangles']+=len(o.data.loop_triangles)
    return stats

# One manufactured arena body, with a genuinely open trap basin.
# The central void runs from the pad undersides through the elimination plane.
ring('Continuous navy showground foundation',22.1,23.6,14.6,14.6,-4.65,-2.0,'navy',z=-1.7)
ring('Warm wood rounded fascia',22.35,23.85,14.6,14.6,-2.05,-1.48,'wood',z=-1.7)
ring('Continuous ivory promenade',22.5,24.0,14.6,14.6,-1.5,-.97,'cream',z=-1.7)
# Outer crown trim is a connected strip rather than floating garden props.
ring('Naval promenade perimeter inlay',22.2,23.7,21.82,23.32,-.98,-.91,'navy',z=-1.7,iz=-1.7,power=4)
# Shadowed deep navy basin. No collision: eliminated actors reach y=-6 as before.
solid_slab('Deep open trap basin floor',14.7,14.7,-7.1,.3,'deep',power=8)
for x in(-7.26,7.26):cube('Trap basin inner side',(x,-3.9,0),(.16,6.3,14.5),'deep',.03)
for z in(-7.26,7.26):cube('Trap basin inner end',(0,-3.9,z),(14.5,6.3,.16),'deep',.03)
# Narrow visible stage rim: no wide walkway that implies extra safe answers.
ring('Continuous cream stage frame',14.5,14.5,13.74,13.74,-.70,-.28,'cream',z=0,iz=0,power=20)
ring('Continuous navy stage reveal',14.6,14.6,13.76,13.76,-.875,-.685,'navy',z=0,iz=0,power=20)
for x in(-7.1,7.1):
    for z in(-7.1,7.1):
        cyl('Golden pad-frame fastener',(x,-.36,z),.25,.17,'yellow',24,.035)
# Front of the showground has a clear face, a centre seal and deliberate ribs.
for x in(-7.7,-5.9,-4.1,4.1,5.9,7.7):
    cube('Rounded lower fascia flute',(x,-3.32,-1.7+11.8*(1-(abs(x)/11.05)**4)**.25+.035),(.18,1.55,.15),'blue',.07)
for x,r in[(-.95,.28),(0,.4),(.95,.28)]:star('Fascia three-star seal',(x,-2.82,10.12),r,'yellow',.1)
# Four inset lights and feet support the visible manufacturing language.
for x in(-9.1,9.1):
    for z in(-5.4,5.8):
        cube('Timber underside bracket',(x,-2.2,z),(.36,2.4,.5),'wood_dark',.12)
        cyl('Cream deck rivet',(x,-.95,z),.15,.08,'yellow',20,.018)
# Integrated Cheer Squad stage, physically matching the existing balcony bounds.
cube('Cheer station navy structure',(0,.65,-10),(15.3,1.3,2.7),'navy',.22)
cube('Cheer station warm wood fascia',(0,1.15,-10),(15.3,.55,2.7),'wood',.18)
cube('Cheer station ivory decking',(0,1.46,-10),(15.0,.10,2.5),'cream',.05)
for i in range(25):cube('Cheer station plank joint',(-7.15+i*.595,1.518,-10),(.018,.012,2.25),'wood_light',.003)
cube('Cheer station coral front inset',(0,.81,-8.61),(10.8,.61,.10),'coral',.14)
for x in(-6.9,6.9):
    cube('Cheer station end parapet',(x,1.98,-10),(.45,1.02,2.38),'cream',.17)
    cube('Cheer station end cap',(x,2.51,-10),(.59,.10,2.7),'wood_light',.045)
# Rear acoustic backdrop / seating supports, two purposeful steps, no extra walkable collision.
for z,y,d in[(-11.6,1.72,.9),(-12.55,2.12,1.0)]:
    cube('Tiered grandstand riser',(0,y-.26,z),(14.5,.5,d),'wood',.10)
    cube('Tiered grandstand cream top',(0,y+.035,z),(14.7,.10,d),'cream',.045)
# One giant physical quiz TV replaces the small decorative marquee and festoon.
# The board stays behind the spectator station; its flat answer surfaces are unlit.
def screen_panel(name,p,w,h,depth,m,radius=.22):
    x,y,z=p;path=[]
    for cx,cy,start in[(w/2-radius,h/2-radius,0),(-w/2+radius,h/2-radius,90),(-w/2+radius,-h/2+radius,180),(w/2-radius,-h/2+radius,270)]:
        for i in range(7):
            a=math.radians(start+i*90/6);path.append((cx+math.cos(a)*radius,cy+math.sin(a)*radius))
    n=len(path)
    verts=[(x+xx,y+yy,z+zz)for zz in(-depth/2,depth/2)for xx,yy in path]
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n)for i in range(n)]
    return finish(mesh(name,verts,faces,m),min(.018,depth*.15),False)
# Legs sit on the rear grandstand instead of adding a new playable platform.
for x in(-6.3,6.3):
    cube('Giant quiz TV support foot',(x,2.24,-12.82),(1.35,.18,1.04),'navy',.075)
    cube('Giant quiz TV bracket',(x,2.50,-13.4),(.58,.60,1.50),'wood',.14)
    cube('Giant quiz TV cream bracket cap',(x,2.70,-13.4),(.74,.16,1.64),'cream',.065)
screen_panel('Giant quiz TV coral shell',(0,5.2,-14.1),23.0,5.2,.70,'coral',.48)
screen_panel('Giant quiz TV navy bezel',(0,5.2,-13.69),22.6,4.8,.18,'navy',.36)
screen_panel('Screen_Face',(0,5.2,-13.555),22.1,4.32,.11,'Screen_Face',.26)
for letter,x in zip('ABCD',[-8.145,-2.715,2.715,8.145]):
    screen_panel('Screen_Answer_'+letter,(x,3.85,-13.47),5.20,1.34,.10,'Screen_Answer_'+letter,.20)
# Restrained asymmetric landscape on the SAME connected promenade.
solid_slab('Left clipped planting bed',3.1,6.8,-.81,.25,'leaf_dark',z=-6.5,power=3)
# Move the bed to the side, leaving the full playable footprint unobscured.
bpy.context.object.location.x=-9.65
# Function creates models at actual planting grade.
tree(-9.65,-7.9,3.35)
for p,s,c in[((-9.5,-.65,-4.6),(1.03,.52,.86),'leaf'),((-10.0,-.56,-5.5),(.8,.65,.75),'leaf_light'),((-8.9,-.7,-5.1),(.63,.48,.68),'leaf')]:sphere('Clipped orchard understory',p,s,c)
# A shorter right-hand planting balances the left silhouette without mirroring it.
for p,s,c in[((9.45,-.59,-4.5),(1.02,.66,1.2),'leaf'),((10.12,-.69,-3.7),(.76,.47,.81),'leaf_light'),((8.9,-.7,-3.45),(.55,.42,.58),'leaf_dark')]:sphere('Right clipped topiary',p,s,c)
for x,z in[(-9.6,-4.2),(9.7,-3.7)]:
    for k in range(3):
        a=k*math.tau/3;sphere('Tiny planted gold flower',(x+math.cos(a)*.22,-.30,z+math.sin(a)*.22),(.12,.05,.12),'yellow')
# Two coral stage pylons complete the side architecture, low enough to preserve actor silhouettes.
for x in(-9.7,9.7):
    cube('Low coral stage pylon',(x,-.22,2.8),(1.18,1.45,1.18),'coral',.25)
    cube('Pylon ivory cap',(x,.55,2.8),(1.35,.16,1.35),'cream',.07)
    star('Pylon brass star',(x,.02,3.43),.27,'yellow',.08)
scene_stats=export('party_garden.glb')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'party_showground.blend'))
# Answer modules: weighty manufactured trapdoors with a crisp, tintable play surface.
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
cube('Navy answer trap chassis',(0,-.48,0),(6.5,.62,6.5),'navy',.23)
cube('Cream answer outer roundover',(0,-.23,0),(6.52,.28,6.52),'cream',.20)
cube('Warning light trim',(0,-.085,0),(6.35,.10,6.35),'signal',.15)
cube('Tintable answer face',(0,-.018,0),(6.16,.10,6.16),'white',.16)
# Small physical fasteners, kept outside player foot placement.
for x in(-2.76,2.76):
    for z in(-2.76,2.76):cyl('Answer brass corner rivet',(x,.035,z),.07,.015,'yellow',16,.003)
pad_stats=export('answer_platform.glb')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'answer_platform.blend'))
# Sparse, original modeled cloud geometry for establishing shots.
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for p,sz in [((0,0,0),(1.8,.6,.6)),((-.8,.18,.04),(.8,.85,.65)),((.3,.3,0),(1,1,.8)),((1.15,.08,.05),(.8,.7,.6))]:sphere('Soft authored cloud lobe',p,sz,'white')
cloud_stats=export('marshmallow_cloud.glb')
summary={'showground':scene_stats,'answer_platform':pad_stats,'authoring_source':'tools/source/party_showground.blend','palette':PALETTE,'quiz_screen':{'face_front_z':-13.5,'face_center':[0,5.2,-13.5],'face_size':[22.1,4.32],'question_zone_y':[4.68,7.20],'answer_centers_x':[-8.145,-2.715,2.715,8.145],'answer_center_y':3.85,'answer_size':[5.2,1.34],'answer_front_z':-13.42,'question_text_z':-13.47,'answer_text_z':-13.39},'gameplay_bounds':{'pad_centres':[-3.4,3.4],'pad_size':6.5,'pad_top':0,'balcony_top':1.5,'balcony_z':-10,'fall_threshold':-6}}
(OUT/'model_stats.json').write_text(json.dumps({'garden':scene_stats,'answer_platform':pad_stats,'cloud':cloud_stats},indent=2))
(OUT/'showground_stats.json').write_text(json.dumps(summary,indent=2))
print('SHOWGROUND_EXPORT',json.dumps(summary))
