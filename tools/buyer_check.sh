#!/usr/bin/env bash
# Buyer check: the repository archive as the Godot Asset Library downloads it (git archive, so the
# export-ignore rules apply), unpacked into a fresh project with the plugin enabled; the editor
# must open it without errors and the test suite must pass there. Copyright (c) 2026 PN Scripts. MIT.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
GODOT=${GODOT:-godot}
W=$ROOT/build/buyer
rm -rf "$W" && mkdir -p "$W"
git -C "$ROOT" archive --format=zip -o "$W/download.zip" HEAD
unzip -q "$W/download.zip" -d "$W/project"
echo "== files a buyer gets:"; (cd "$W/project" && find . -type f | sort | sed 's/^/   /')
mkdir -p "$W/project/tests" && cp "$ROOT/tests/run_tests.gd" "$W/project/tests/"
cat > "$W/project/project.godot" <<'P'
config_version=5

[application]

config/name="Fresh Buyer Project"
config/features=PackedStringArray("4.7")

[autoload]

PipaloLite="*res://addons/pipalo_lite/pipalo_device.gd"

[editor_plugins]

enabled=PackedStringArray("res://addons/pipalo_lite/plugin.cfg")
P
"$GODOT" --headless --path "$W/project" --import >/dev/null 2>&1 || true
echo "== editor opens the project with the plugin enabled"
"$GODOT" --headless --editor --path "$W/project" --quit-after 60 2>&1 | grep -E "ERROR|SCRIPT" && { echo "editor reported errors"; exit 1; } || echo "no errors"
echo "== test suite in the buyer project"
"$GODOT" --headless --path "$W/project" -s tests/run_tests.gd | tail -1
