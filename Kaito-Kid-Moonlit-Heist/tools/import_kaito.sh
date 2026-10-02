#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
assets_dir="$project_dir/assets/characters/vroid"
godot="/Applications/Godot.app/Contents/MacOS/Godot"

patch_import() {
    python3 - "$assets_dir/hairsample_male.glb.import" "$1" <<'PY'
from pathlib import Path
import re
import sys

reference = Path(sys.argv[1]).read_text()
target = Path(sys.argv[2])
contents = target.read_text()
pattern = re.compile(r'(?ms)^_subresources=\{\n.*?(?=^gltf/naming_version=)')
match = pattern.search(reference)
if not match or 'res://assets/characters/vroid/vroid_bone_map.tres' not in match.group():
    raise SystemExit('Reference import has no VRoid retarget block')
if not re.search(r'(?m)^gltf/naming_version=', contents):
    raise SystemExit(f'No glTF import settings in {target}')
if pattern.search(contents):
    contents = pattern.sub(lambda _: match.group(), contents, count=1)
else:
    contents = re.sub(r'(?m)^gltf/naming_version=',
                      lambda _: match.group() + 'gltf/naming_version=',
                      contents, count=1)
target.write_text(contents)
PY
}

# Allows checking the import-file patch without a Kaito VRM export.
if [[ "${1:-}" == "--patch-import" && $# -eq 2 ]]; then
    patch_import "$2"
    exit 0
fi
if [[ $# -ne 0 ]]; then
    echo "Usage: $0 [--patch-import FILE]" >&2
    exit 2
fi

vrm="$assets_dir/kaito.vrm"
glb="$assets_dir/kaito.glb"
if [[ ! -f "$vrm" ]]; then
    echo "Missing VRM export: $vrm" >&2
    exit 1
fi

python3 "$project_dir/tools/vrm_prep.py" "$vrm" "$glb"
"$godot" --headless --path "$project_dir" --import
patch_import "$glb.import"
"$godot" --headless --path "$project_dir" --import
