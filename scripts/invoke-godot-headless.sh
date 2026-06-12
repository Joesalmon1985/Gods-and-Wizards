#!/usr/bin/env bash
# Run Godot headless and propagate exit code (Linux counterpart to Invoke-GodotHeadless.ps1).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GODOT_PROJECT="$PROJECT_ROOT/godot_game"

GODOT_EXE="${GODOT_EXE:-$HOME/Documents/Godot/Godot_v4.5.2-stable_linux.x86_64}"

if [[ ! -x "$GODOT_EXE" ]]; then
  echo "Godot executable not found or not executable: $GODOT_EXE" >&2
  echo "Set GODOT_EXE to your Godot 4.5+ binary." >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <godot-args...>" >&2
  echo "Example: $0 --headless --path \"$GODOT_PROJECT\" -s res://tests/test_runner.gd" >&2
  exit 1
fi

"$GODOT_EXE" "$@"
exit $?
