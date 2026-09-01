# Debug Preview

This folder contains isolated scenes to inspect client maps in first person.

## Files

- `preview_map_prototype.tscn`

Both scenes instantiate:

- the selected client map
- `res://_debug/player_local_preview.tscn`

## How to use

1. Open `Project Settings > Autoload`.
2. Temporarily disable `Server` (`res://server/server.tscn`).
3. Keep `AudioManager` and `SettingsManager` enabled.
4. Open one of the scenes in this folder.
5. Run with `F6` (`Play Current Scene`).

## Notes

- This mode uses a stripped preview player with only collision and camera.
- Press `Esc` to release/capture the mouse.
- This mode is for movement, camera, perspective and collision validation.
- Match flow, lobby, networking and synced gameplay are intentionally not active here.
