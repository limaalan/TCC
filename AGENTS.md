# AGENTS

## Scope
- The gameplay code is under `initial_project/`, not the repo root. Root `*.md` files are mostly TCC/thesis/planning notes.
- There are two separate Godot 4.5 projects: `initial_project/Server` and `initial_project/Client`.

## Project Boundaries
- Treat `Server` and `Client` as separate Godot projects with separate `project.godot` files, scenes, scripts, and `.godot/` state.
- Both projects define an autoload named `Server` from `res://server/server.tscn`, but they are different implementations. Do not copy paths or assumptions from one project into the other.
- Both projects also define `class_name Lobby`, again with separate client/server behavior. Be explicit about which project you are editing.

## Real Entrypoints
- Client entrypoint: `initial_project/Client/project.godot` -> main scene `res://game/main_game.tscn`.
- Client scene flow starts in `game/local_game_scene_manager.gd`, which immediately loads `res://ui/main_menu/main_menu.tscn`.
- Server entrypoint: `initial_project/Server/project.godot` -> main scene `res://game/main_game.tscn`, with the actual startup logic living in the autoload `res://server/server.tscn` / `server/server.gd`.

## Run And Verify
- Run the server project first, then the client. The client autoload tries to connect to `127.0.0.1:7777` in `_ready()`.
- Focused local verification is manual launch of both Godot projects; there are no repo-level test, lint, CI, or task-runner configs in this repository.
- If using CLI and Godot is on `PATH`, the projects to launch are:
  - `godot --path initial_project/Server`
  - `godot --path initial_project/Client`

## Multiplayer Wiring To Preserve
- The server listens on port `7777` in `initial_project/Server/server/server.gd`.
- Matchmaking is intentionally constrained right now: `MAX_LOBBIES = 1` and `MAX_PLAYERS_PER_LOBBY = 2`.
- The current map flow is hardcoded to the farm maps:
  - Server loads `res://maps/server_map_farm.tscn`
  - Client loads `res://maps/map_farm.tscn`
- The client persists the player name under `profile/player_name` in `user://settings.cfg`.

## Godot-Specific Gotchas
- Client UI/game flow depends heavily on scene groups with exact names: `LocalGameSceneManager`, `PlayerLocal`, `WeaponSelectionUI`, and `MatchInfoUi`.
- There is an intentional typo in the local player API: `set_procecess`. It is called by name via `call_group` from `Client/server/lobby.gd`. If you rename it, update both sides together.
- Many networked interactions are string-keyed `Dictionary` payloads and RPC names shared between projects. Keep client/server changes in sync when touching lobby state, player state, weapon data, pickups, grenades, or match flow.

## Repo Workflow Notes
- Root `.gitignore` ignores `.godot/` and `initial_project/Client/assets`. Be careful when changing client assets and verify what Git is actually tracking before assuming an asset edit will be committed.
- README documents a repo-specific commit style: prefix the message with a task number, e.g. `2. Criação do modelo de personagem`.
