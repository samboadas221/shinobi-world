# KNOWN BUGS

## Active Bugs

No confirmed active runtime bugs are currently documented.

## Suspected Issues / Risks

### Large Overworld Coordinator

- Affected file: `lib/game/shinobi_world_game.dart`
- Risk: File is above the preferred target size and coordinates several responsibilities.
- Suspected cause: First-demo features accumulated in the main Flame game class.
- Workaround: Keep new logic in dedicated controllers/components and extract pieces when touching this area.

### Persistence Store Growth

- Affected file: `lib/data/first_demo_store.dart`
- Risk: Store may grow into a database god file as more systems are persisted.
- Suspected cause: First-demo run, village, ninja, and player-profile storage are currently together.
- Workaround: Split schema and storage operations if adding new persistence domains.

### Placeholder Systems

- Affected systems:
  - procedural map visuals
  - NPC spawn/despawn behavior
  - jutsu practice
  - turn-based combat
- Risk: Placeholder logic may be mistaken for final design.
- Workaround: Treat placeholders as scaffolding and keep replacing values/behavior with YAML-driven systems.

### Generated/Untracked Files

- Affected areas:
  - `windows/`
  - `.idea/`
  - `assets/`
  - `test/`
- Risk: Some files are currently untracked in git status.
- Workaround: Before any commit, review `git status --short` carefully and include only intended files.

## Resolved Bugs

### Enemy Collision Froze Before Combat Screen

- Reported: Colliding with an enemy froze the overworld and the battle screen never appeared.
- Confirmed cause: `_enemyConfig` and `_enemyJutsu` were declared `late final` in `ShinobiWorldGame`, but `_updateEncounter` reassigns them to the collided enemy's config and jutsu list.
- Resolution: Active enemy encounter fields are now mutable `late` fields. `DemoGameScreen` also keeps `GameWidget` mounted and displays `CombatScreen` as a full-screen overlay while `ShinobiWorldGame` pauses during combat.
- Validation: Earlier transition validation passed with `dart format lib test`, `flutter analyze`, `flutter test`, and `flutter build windows --debug`. Post-root-cause validation still needs rerun because the app rejected escalation due to usage limits.

### Camera Follow Did Not Work

- Cause: Map/player were previously added outside the Flame world rendered by the camera.
- Resolution: Components were moved into `world` and camera follow was corrected.

### Combat Screen Had Only Flee

- Cause: Combat screen was initially a placeholder.
- Resolution: Added playable attack and jutsu actions through `BattleController`.
