# Shared Contracts

This directory is the single source of truth for scripts shared by the
`Client` and `Server` Godot projects.

Expected workflow:

1. Put shared scripts here.
2. Run `initial_project/setup_shared_links.ps1` once on each machine.
3. Access shared scripts from both projects through `res://shared/...`.

Important rules:

- Do not edit `Client/shared` directly.
- Do not edit `Server/shared` directly.
- Those paths are local junctions that point back to this directory.

Examples of future shared files:

- `game_enums.gd`
- `net_keys.gd`
- `net_payloads.gd`
- `network_config.gd`
