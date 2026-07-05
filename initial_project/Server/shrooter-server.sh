#!/bin/sh
printf '\033c\033]0;%s\a' Server
base_path="$(dirname "$(realpath "$0")")"
"$base_path/shrooter-server.x86_64" "$@"
