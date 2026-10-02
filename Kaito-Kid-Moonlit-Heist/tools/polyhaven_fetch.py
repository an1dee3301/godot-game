"""Fetch CC0 Poly Haven assets (glTF models / PBR textures) at a given resolution.
Usage: python3 tools/polyhaven_fetch.py models|textures RES id1 id2 ...  -> assets/polyhaven/<kind>/<id>/"""
import json, os, sys, urllib.request
kind, res, ids = sys.argv[1], sys.argv[2], sys.argv[3:]
root = os.path.join("assets", "polyhaven", kind)
def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "KaitoKidGame/1.0"})
    return urllib.request.urlopen(req, timeout=60).read()
for aid in ids:
    try:
        files = json.loads(get(f"https://api.polyhaven.com/files/{aid}"))
    except Exception as e:
        print("MISSING", aid, e); continue
    out = os.path.join(root, aid); os.makedirs(out, exist_ok=True)
    if kind == "models":
        g = files["gltf"].get(res) or files["gltf"][sorted(files["gltf"])[0]]
        g = g["gltf"]
        open(os.path.join(out, aid + ".gltf"), "wb").write(get(g["url"]))
        for rel, inc in g.get("include", {}).items():
            p = os.path.join(out, rel); os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, "wb").write(get(inc["url"]))
    else:
        for m, key in [("Diffuse", "diff"), ("nor_gl", "nor"), ("Rough", "rough"), ("AO", "ao")]:
            if m in files and res in files[m]:
                f = files[m][res].get("jpg") or files[m][res].get("png")
                ext = "jpg" if "jpg" in files[m][res] else "png"
                open(os.path.join(out, f"{key}.{ext}"), "wb").write(get(f["url"]))
    print("ok", aid)
