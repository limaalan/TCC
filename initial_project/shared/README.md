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

Current responsibilities include:

- `game_enums.gd`
- `net/net_keys.gd` and `net/net_payloads.gd`
- `network_config.gd`
- `match_config.gd` and `match_preset_registry.gd`
- weapon definitions and inventory under `weapons/`
- metrics serialization and logging under `metrics/`

The release builder (`scripts/build_release.py`, from the repository root)
materializes these files into temporary copies of each project. Exported
builds do not depend on local junctions or a previous `.godot/` cache.
