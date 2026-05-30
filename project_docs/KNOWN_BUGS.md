# KNOWN BUGS

## Active Bugs

No confirmed active runtime bugs are currently documented.

## Suspected Issues / Risks

### Large Overworld Coordinator

- Affected file: `lib/game/shinobi_world_game.dart`
- Risk: File is significantly above the preferred target size and coordinates several responsibilities (world load, encounter trigger, HUD state, camera, joystick).
- Suspected cause: First-demo features accumulated in the main Flame game class.
- Workaround: Keep new logic in dedicated controllers/components and extract pieces when touching this area. Extractions suggested in `TODO_GLOBAL.md`.

### Persistence Store Growth

- Affected file: `lib/data/first_demo_store.dart`
- Risk: Store may grow into a database god file as more systems are persisted.
- Suspected cause: First-demo run, village, ninja, and player-profile storage are currently together.
- Workaround: Split schema and storage operations if adding new persistence domains.

### NinjaSpawnerComponent — Spawn Point May Be Off-Map

- Affected file: `lib/game/ninja_spawner_component.dart`
- Risk: The random spawn point is calculated as a ring around the player at buffer distance. If the player is near a map edge, spawn points may be outside the world bounds.
- Suspected cause: No map-bounds clamping in `_randomSpawnPoint()`.
- Workaround: Low impact for now (NPCs just wander outside the visible area and will be despawned). Fix by clamping spawn points to `[0, mapWidth] × [0, mapHeight]` once camera bounds are also added.

### No Camera Bounds

- Affected file: `lib/game/shinobi_world_game.dart`
- Risk: Player can walk past the edge of the generated map tiles.
- Suspected cause: `camera.setBounds()` was removed to avoid a `flame/experimental` import that isn't explicitly declared.
- Workaround: Player-side position clamping or use Flame's `BoundedPositionBehavior` as a follow-up task.

### Placeholder Systems

- Affected systems:
  - procedural map visuals
  - NPC behaviors (wander only; no patrol/encounter logic)
  - jutsu hand seal validation
  - turn-based combat reaction window
- Risk: Placeholder logic may be mistaken for final design.
- Workaround: Treat placeholders as scaffolding and keep replacing values/behavior with YAML-driven systems.

## Resolved Bugs

### Ninjas Did Not Spawn & Combat Trigger Disconnected

- Reported: Spawner did not activate any ninjas on the overworld; colliding with them did not trigger combat, preventing testing of combat and jutsu systems.
- Confirmed cause:
  1. Generated ninjas had `active: false` (saved as `active = 0` in SQLite), but spawner queried for `active = 1`.
  2. Spawner alignments `'bad'` and `'village'` did not map to color states (`'hostile'`, `'friendly'`, `'neutral'`).
  3. Overworld encounter detection scanned only for `EnemyComponent` (which is never spawned) and completely ignored `ActiveNinjaComponent`.
- Resolution:
  - Ninjas are now generated with `active: true`.
  - Automatic migration query sets existing DB rows to `active = 1` for seamless updates.
  - mapped alignments to overworld color categories (`'hostile'`, `'friendly'`, `'neutral'`).
  - Integrated `ActiveNinjaComponent` collision into overworld encounters, dynamically building `EnemyConfig` and selecting combat jutsus from SQLite stats. On victory, they are permanently removed.

### Enemy Collision Froze Before Combat Screen

- Reported: Colliding with an enemy froze the overworld and the battle screen never appeared.
- Confirmed cause: `_enemyConfig` and `_enemyJutsu` were declared `late final` in `ShinobiWorldGame`, but `_updateEncounter` reassigns them to the collided enemy's config and jutsu list.
- Resolution: Active enemy encounter fields are now mutable `late` fields. `DemoGameScreen` keeps `GameWidget` mounted and displays `CombatScreen` as a full-screen overlay while `ShinobiWorldGame` pauses during combat.

### Camera Follow Did Not Work

- Cause: Map/player were previously added outside the Flame world rendered by the camera.
- Resolution: Components were moved into `world` and camera follow was corrected.

### Combat Screen Had Only Flee

- Cause: Combat screen was initially a placeholder.
- Resolution: Added playable attack and jutsu actions through `BattleController`. Combat screen fully redesigned 2026-05-26.
