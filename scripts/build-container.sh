#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/.local/share/godot" "$HOME/.config"
ln -s /opt/godot/templates "$HOME/.local/share/godot/export_templates"
exec bash /source/scripts/build.sh "$@"
