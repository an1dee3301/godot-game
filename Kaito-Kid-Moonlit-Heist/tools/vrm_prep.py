"""Prepare a CC0 VRoid VRM (0.x) for Godot: rotate the root 180 deg so it faces +Z (what Godot's
humanoid retarget expects) and write it as .glb. Usage: python3 tools_vrm_prep.py in.vrm out.glb"""
import json, struct, sys
src, dst = sys.argv[1], sys.argv[2]
b = open(src, 'rb').read()
jl = struct.unpack('<I', b[12:16])[0]
j = json.loads(b[20:20 + jl])
rest = b[20 + jl:]
for n in j['scenes'][j.get('scene', 0)]['nodes']:
    j['nodes'][n]['rotation'] = [0.0, 1.0, 0.0, 0.0]
js = json.dumps(j, separators=(',', ':')).encode()
js += b' ' * ((4 - len(js) % 4) % 4)
open(dst, 'wb').write(b'glTF' + struct.pack('<I', 2) + struct.pack('<I', 12 + 8 + len(js) + len(rest)) + struct.pack('<I', len(js)) + b'JSON' + js + rest)
