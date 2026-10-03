"""Rasterise Natural Earth 110m land (world-atlas land-110m.json, TopoJSON) to an equirectangular PNG mask."""
import json, struct, zlib, sys
W, H = 1024, 512
topo = json.load(open("assets/data/land-110m.json"))
sx, sy = topo["transform"]["scale"]; tx, ty = topo["transform"]["translate"]
arcs = []
for arc in topo["arcs"]:
	x = y = 0; pts = []
	for dx, dy in arc:
		x += dx; y += dy
		pts.append((x * sx + tx, y * sy + ty))
	arcs.append(pts)
def ring(indices):
	pts = []
	for i in indices:
		a = arcs[i] if i >= 0 else arcs[~i][::-1]
		pts.extend(a if not pts else a[1:])
	return pts
rings = []
for geom in topo["objects"]["land"]["geometries"]:
	polys = geom["arcs"] if geom["type"] == "MultiPolygon" else [geom["arcs"]]
	for poly in polys:
		for r in poly:
			pts = [((lon + 180) / 360 * W, (90 - lat) / 180 * H) for lon, lat in ring(r)]
			# Unwrap rings that cross the antimeridian so edges stay continuous; drawn at x-W, x, x+W.
			fixed = [pts[0]]
			for x, y in pts[1:]:
				px = fixed[-1][0]
				while x - px > W / 2: x -= W
				while px - x > W / 2: x += W
				fixed.append((x, y))
			rings.append(fixed)
rows = []
for py in range(H):
	yc = py + 0.5; row = bytearray(W)
	for r in rings:
		xs = []
		for (x1, y1), (x2, y2) in zip(r, r[1:] + r[:1]):
			if (y1 <= yc) != (y2 <= yc):
				xs.append(x1 + (yc - y1) * (x2 - x1) / (y2 - y1))
		if len(xs) % 2:
			continue  # ring not closed in x (Antarctica edge): skip this row segment
		xs.sort()
		for a, b in zip(xs[0::2], xs[1::2]):
			for shift in (-W, 0, W):
				for px in range(max(0, int(a + shift + 0.5)), min(W, int(b + shift + 0.5))):
					row[px] ^= 255
	rows.append(b"\x00" + bytes(row))
def chunk(t, d): return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 0, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b"")
open("assets/data/world_land_mask.png", "wb").write(png)
print("land fraction", sum(r.count(255) for r in rows) / (W * H))
