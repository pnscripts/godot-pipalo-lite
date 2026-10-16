#!/usr/bin/env bash
# Web export of the demo, driven in real Chrome with real multi-touch (CDP Input.dispatchTouchEvent):
# finger 1 holds the joystick to the right, finger 2 presses Jump. A test-only autoload prints the
# player's position to the browser console. Needs GODOT (4.7.1 with web templates), Google Chrome and
# PN_PLAYWRIGHT pointing at playwright-core's index.mjs.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/build/web-check"
rm -rf "$OUT" && mkdir -p "$OUT"
mkdir -p "$OUT/project" && cp -r "$ROOT/addons" "$ROOT/demo" "$ROOT/project.godot" "$OUT/project/"
cp "$ROOT/tools/web/web_probe.gd" "$ROOT/tools/web/export_presets.cfg" "$OUT/project/"
sed -i 's|^PipaloLite="\*res://addons/pipalo_lite/pipalo_device.gd"|&\nWebProbe="*res://web_probe.gd"|' "$OUT/project/project.godot"
sed -i 's|^export_path=.*|export_path="../out/index.html"|' "$OUT/project/export_presets.cfg"
mkdir -p "$OUT/out"
(cd "$OUT/project" && "${GODOT:-godot}" --headless --import >/dev/null 2>&1 || true; "${GODOT:-godot}" --headless --export-release "Web" ../out/index.html >/dev/null)
python3 -m http.server 8493 --bind 127.0.0.1 --directory "$OUT/out" >/dev/null 2>&1 & SRV=$!
trap 'kill $SRV' EXIT
sleep 1
node "$ROOT/tools/web/touch.mjs" "$OUT" drive "[234,546]" "[1170,590]"
