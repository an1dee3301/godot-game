"""Original Blender-modeled party props; no image/video generation or external art.
Run Blender --background --python tools/build_party_props.py
"""
import bpy,bmesh,math,pathlib,json
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/props';OUT.mkdir(parents=True,exist_ok=True)
SRC=ROOT/'tools/source';SRC.mkdir(parents=True,exist_ok=True)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
M={};STATS={};BUILT=[]
PALETTE={'M_Answer':'51a6f5','M_Cream':'fff6df','M_Peel':'ffcf4d','M_PeelLight':'ffe77c','M_PeelShade':'e4a936','M_Stem':'78493c','M_Bomb':'a681df','M_BombDark':'7554a2','M_Gold':'ffca4a','M_Ruby':'fa636b','M_Aqua':'47cda4','M_Blue':'51a6f5'}
def material(name):
    if name not in M:
        c=PALETTE[name];rgb=tuple(int(c[i:i+2],16)/255 for i in (0,2,4))+(1,)
        m=bpy.data.materials.new(name);m.diffuse_color=rgb
        bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bs.inputs['Base Color'].default_value=rgb
        bs.inputs['Roughness'].default_value=.32 if name in ('M_Answer','M_Bomb','M_Gold') else .55
        if name=='M_Gold':bs.inputs['Metallic'].default_value=.35
        M[name]=m
    return M[name]
def gp(p):return (p[0],-p[2],p[1])
def apply(obj):
    bpy.context.view_layer.objects.active=obj
    for mod in list(obj.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
def setup(obj,name,p,m):
    obj.name=name;obj.location=gp(p);obj.data.materials.append(material(m));BUILT.append(obj);return obj
def cube(name,p,size,m,bevel=.08):
    bpy.ops.mesh.primitive_cube_add(size=1)
    o=setup(bpy.context.object,name,p,m);o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Rounded toy edges','BEVEL');mod.width=min(bevel,min(size)*.42);mod.segments=3;apply(o)
    for poly in o.data.polygons:poly.use_smooth=True
    mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');mod.keep_sharp=True;apply(o)
    return o
def sphere(name,p,scale,m,segments=14,rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1)
    o=setup(bpy.context.object,name,p,m);o.scale=(scale[0],scale[2],scale[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for poly in o.data.polygons:poly.use_smooth=True
    return o
def cyl(name,a,b,r,m,vertices=12):
    pa,pb=Vector(gp(a)),Vector(gp(b));bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=(pb-pa).length)
    o=setup(bpy.context.object,name,(0,0,0),m);o.location=(pa+pb)/2;o.rotation_euler=(pb-pa).to_track_quat('Z','Y').to_euler()
    for poly in o.data.polygons:poly.use_smooth=True
    return o
def mesh(name,verts,faces,m,bevel=0):
    d=bpy.data.meshes.new(name);d.from_pydata([gp(v) for v in verts],[],faces);d.update();o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);d.materials.append(material(m));BUILT.append(o)
    if bevel:
        bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Soft toy corners','BEVEL');mod.width=bevel;mod.segments=2;apply(o)
    return o
def star(name,p,r,m,thickness=.025):
    x,y,z=p;v=[]
    for d in (-thickness/2,thickness/2):
        for i in range(10):
            a=math.pi/2+i*math.pi/5;rr=r if i%2==0 else r*.48;v.append((x+math.cos(a)*rr,y+math.sin(a)*rr,z+d))
    f=[tuple(range(9,-1,-1)),tuple(range(10,20))]+[(i,(i+1)%10,(i+1)%10+10,i+10)for i in range(10)]
    return mesh(name,v,f,m,thickness*.3)
def export(name):
    global BUILT
    bpy.ops.object.select_all(action='DESELECT')
    for o in BUILT:o.select_set(True)
    bpy.context.view_layer.objects.active=BUILT[0];bpy.ops.object.join();o=BUILT[0];o.name=name
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.dissolve_degenerate(bm,dist=1e-6,edges=list(bm.edges));bmesh.ops.triangulate(bm,faces=[f for f in bm.faces if len(f.verts)>4]);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
    o.data.calc_loop_triangles();tris=len(o.data.loop_triangles)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True)
    STATS[name]={'triangles':tris,'objects':1,'materials':len(o.data.materials),'dimensions_m':[round(v,4)for v in (o.dimensions.x,o.dimensions.z,o.dimensions.y)],'bytes':(OUT/(name+'.glb')).stat().st_size}
    o.location.x=(len(STATS)-1)*2.0
    BUILT=[]
# Answer block: cream inset panels leave a clean field for engine letter labels.
cube('Coated answer cube',(0,0,0),(1.05,1.05,1.05),'M_Answer',.12)
for side in (-1,1):
    sphere('Cream round letter panel',(0,0,side*.535),(.34,.34,.014),'M_Cream',segments=16,rings=8)
    sphere('Cream round letter panel',(side*.535,0,0),(.014,.34,.34),'M_Cream',segments=16,rings=8)
export('answer_block')
# A thick crescent banana with modeled peel facets, tapered ends and brown tips.
N=14;R=8;v=[]
for i in range(N+1):
    t=-1+2*i/N;x=t*.44;y=-.13+.30*t*t
    tangent=Vector((.44,.60*t,0)).normalized();normal=Vector((-tangent.y,tangent.x,0))
    radius=.10*(.45+.55*math.sin(math.pi*i/N)**.55)
    for j in range(R):
        a=j*math.tau/R;p=Vector((x,y,0))+normal*math.cos(a)*radius+Vector((0,0,math.sin(a)*radius))
        v.append(tuple(p))
f=[]
for i in range(N):
    for j in range(R):f.append((i*R+j,i*R+(j+1)%R,(i+1)*R+(j+1)%R,(i+1)*R+j))
f.extend([tuple(range(R-1,-1,-1)),tuple(range(N*R,(N+1)*R))])
o=mesh('Crescent banana',v,f,'M_Peel');o.data.materials.append(material('M_PeelLight'));o.data.materials.append(material('M_PeelShade'))
for i,p in enumerate(o.data.polygons):
    if i<N*R:p.material_index=[0,0,1,1,0,2,2,0][i%R];p.use_smooth=True
for sign in (-1,1):
    cyl('Banana brown tip',(sign*.43,.155,0),(sign*.485,.235,0),.041,'M_Stem',10)
    sphere('Peel tip collar',(sign*.427,.15,0),(.055,.055,.052),'M_PeelShade',10,6)
export('banana')
# Smoke bomb: chunky violet sphere, stitched equator, gold star and a curled fuse.
sphere('Purple smoke ball',(0,-.03,0),(.30,.30,.30),'M_Bomb',20,12)
cube('Fuse cap',(0,.263,0),(.19,.105,.19),'M_BombDark',.045)
cyl('Curled cotton fuse',(0,.30,0),(.025,.43,0),.022,'M_Cream',10)
cyl('Curled cotton fuse',(.025,.43,0),(.105,.465,0),.022,'M_Cream',10)
sphere('Warm fuse end',(.112,.467,0),(.03,.03,.03),'M_Gold',10,6)
star('Gold party star',(0,-.015,.292),.17,'M_Gold',.03)
export('smoke_bomb')
# Royal crown with a true hollow circlet, six softened triangular points and enamel gems.
v=[];segs=32
for r,y in [(.46,-.25),(.46,-.065),(.355,-.25),(.355,-.065)]:
    for i in range(segs):a=i*math.tau/segs;v.append((math.sin(a)*r,y,math.cos(a)*r))
f=[]
for i in range(segs):
    j=(i+1)%segs
    f.extend([(i,j,segs+j,segs+i),(2*segs+j,2*segs+i,3*segs+i,3*segs+j),(segs+i,segs+j,3*segs+j,3*segs+i),(j,i,2*segs+i,2*segs+j)])
mesh('Hollow golden circlet',v,f,'M_Gold',.014)
for k in range(6):
    a=k*math.tau/6;v=[]
    for r in (.46,.385):
        v.extend([(math.sin(a-.39)*r,-.07,math.cos(a-.39)*r),(math.sin(a+.39)*r,-.07,math.cos(a+.39)*r),(math.sin(a)*(r+.025),.35+(0.04 if k%2==0 else 0),math.cos(a)*(r+.025))])
    mesh('Crown raised point',v,[(0,1,2),(5,4,3),(0,3,4,1),(1,4,5,2),(2,5,3,0)],'M_Gold',.018)
    sphere('Crown point bauble',(math.sin(a)*.485,.36+(0.04 if k%2==0 else 0),math.cos(a)*.485),(.048,.048,.048),'M_Gold',10,6)
    o=sphere('Polished crown gem',(math.sin(a)*.467,-.145,math.cos(a)*.467),(.073,.062,.025),['M_Ruby','M_Aqua','M_Blue'][k%3],12,6)
    o.rotation_euler.z=-a
export('crown')
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'party_props.blend'))
(OUT/'model_stats.json').write_text(json.dumps(STATS,indent=2)+'\n')
print('PARTY_PROPS_EXPORT',json.dumps(STATS))
