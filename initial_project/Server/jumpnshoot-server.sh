#!/bin/sh
printf '\033c\033]0;%s\a' "Jump'n'Shoot Server"
base_path="$(dirname "$(realpath "$0")")"
"$base_path/jumpnshoot-server.x86_64" "$@"
