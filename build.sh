#!/usr/bin/env bash
# Builds a .plasmoid file (a zip of the package) ready to upload to the KDE Store.
set -euo pipefail
cd "$(dirname "$0")"

id=$(python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Id"])')
version=$(python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Version"])')
out="dist/nightscout-${version}.plasmoid"

mkdir -p dist
rm -f "$out"
python3 - "$out" <<'PY'
import os, sys, zipfile
out = sys.argv[1]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk("package"):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        for f in sorted(files):
            if f.startswith(".") or f.endswith(("~", ".swp")):
                continue
            path = os.path.join(root, f)
            z.write(path, os.path.relpath(path, "package"))
    z.write("LICENSE", "LICENSE")
PY

echo "Built $out ($id $version)"
