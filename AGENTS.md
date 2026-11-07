# AGENTS

## Scope
- The gameplay code is under `initial_project/`, not the repo root. Root Markdown files cover project setup, contribution guidance and third-party credits.
- The game is named `jumpnshoot`; technical artifacts use `jumpnshoot-client` and `jumpnshoot-server`. Current Godot application titles still use `Jump'n'Shoot Client/Server`; changing those may affect `user://` data.
- There are two separate Godot projects: `initial_project/Server` and `initial_project/Client`. The build tooling pins Godot 4.5.1 standard.
- Current TCC sources live in `docs/report/main.tex` and its included files. `docs/tcc/TCC1.pdf` is the preserved TCC1 reference. Keep `docs/report/` unchanged during repository-only cleanups unless the author explicitly authorizes report edits.

## Project Boundaries
- Treat `Server` and `Client` as separate Godot projects with separate `project.godot` files, scenes, scripts, and `.godot/` state.
- Both projects define an autoload named `Server` from `res://server/server.tscn`, but they are different implementations. Do not copy paths or assumptions from one project into the other.
- Both projects also define `class_name Lobby`, again with separate client/server behavior. Be explicit about which project you are editing.

## Real Entrypoints
- Client entrypoint: `initial_project/Client/project.godot` -> main scene `res://game/main_game.tscn`.
- Client scene flow starts in `game/local_game_scene_manager.gd`, which immediately loads `res://ui/main_menu/main_menu.tscn`.
- Server entrypoint: `initial_project/Server/project.godot` -> main scene `res://game/main_game.tscn`, with the actual startup logic living in the autoload `res://server/server.tscn` / `server/server.gd`.

## Run And Verify
- Run the server before clients when execution is in scope. The Client loads its endpoint from `user://settings.cfg`; `default_settings.cfg` seeds the first profile with an empty address and port 7777. Configure an address before connecting.
- Canonical build and verification instructions are in `docs/build.md`; CI/release behavior is documented in `docs/publishing.md`.
- `scripts/tests/` contains Python tests for build/deploy/smoke tooling. `scripts/test_exports.py` and `scripts/smoke/` exercise real exported builds headlessly; the match smoke currently uses two clients and does not replace manual gameplay/audio/visual checks.
- `.github/workflows/ci.yml` and `release.yml` define CI, release, and deployment.
- If using CLI and Godot is on `PATH`, the projects to launch are:
  - `godot --path initial_project/Server`
  - `godot --path initial_project/Client`

## Multiplayer Wiring To Preserve
- The Server gets its port from `shared/network_config.gd`: valid integer CLI `--port` first, then `network/server_port` in ProjectSettings, default 7777. Gameplay uses UDP/ENet.
- `Server/server/server.gd` sets `MAX_CLIENTS = 64` and `MAX_LOBBIES = 4`. These are configuration limits, not measured capacity.
- `shared/match_preset_registry.gd` defines `tdm_highrise` and `koth_highrise`, currently with 2 players, a 300-second limit and a 20-point target. The `MatchConfig` fallback has 4 players, but the presets override it.
- Only `IDLE` lobbies accept entry; reaching preset capacity locks the lobby before loading and weapon selection. Entry into an ongoing match is not implemented by merely lowering the required player count.
- Both current presets select Highrise through separate map registries:
  - Server: `res://maps/highrise/server_map_highrise.tscn`
  - Client: `res://maps/highrise/map_highrise.tscn`
- The Highrise Server map has four initial spawn points per team; `spawn_players()` requires enough points for the admitted players.
- The client persists the player name under `profile/player_name` in `user://settings.cfg`.
- See `docs/configuration.md` for configuration locations, defaults and precedence.
- The optional one-room pilot is `scripts/run_loadtest.py`; see `docs/how_to/run-load-pilot.md`. `--players` counts all slots; `--human` reserves one, otherwise all are bots. Loadtest flags opt into 2–64 players (reusing existing spawn anchors above eight), high score/time and experimental spawn ammunition; without them normal presets/ammunition remain unchanged. Do not infer VPS capacity or graphical playability from local headless CSVs.

## Godot-Specific Gotchas
- Client UI/game flow depends heavily on scene groups with exact names: `LocalGameSceneManager`, `PlayerLocal`, `WeaponSelectionUI`, and `MatchInfoUi`.
- Client group and method names are centralized in `Client/game/client_names.gd`. The lobby currently unfreezes the local player through `METHOD_UNFREEZE`; processing is handled by `PlayerLocal.set_processing_enabled`. Older notes about `set_procecess` describe an obsolete API. Keep named group calls and their implementations in sync.
- Many networked interactions are string-keyed `Dictionary` payloads and RPC names shared between projects. Keep client/server changes in sync when touching lobby state, player state, weapon data, pickups, grenades, or match flow.
- `initial_project/shared/` is the source for common contracts, including `net/net_keys.gd` and `net/net_payloads.gd`. Local `Client/shared` and `Server/shared` are junctions prepared by `initial_project/setup_shared_links.ps1`; the release builder materializes shared files in temporary project copies.

## Repo Workflow Notes
- Root `.gitignore` ignores `.godot/`, `build/`, local shared junctions and other generated files. Client assets are not globally ignored by the current root rules; use `git ls-files` / `git check-ignore` for the file in question.
- Preserve pre-existing local changes. Do not rename historical binaries/manifests to simulate a new build, and do not remove documents/assets solely because a text search found no references.
- README documents a repo-specific commit style: prefix the message with a task number, e.g. `2. Criação do modelo de personagem`.
