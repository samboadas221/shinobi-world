# CURRENT TASK

## Active Task

Improve road generation: replace random-drift roads with human-like 90-degree turn roads, and add straight exit roads leading from each village toward every other village.

## Status

Completed.

## Progress

- Replaced the random-drift wander logic in `_growRoad` with clean 90-degree turn logic:
  - Spine roads (2-wide) go straight for 10–27 tiles then make a sharp 90-degree turn.
  - Branch roads (1-wide) are perfectly straight — no turns at all.
- Added `_growExitRoads`: for each other village in the world run, draws a straight 2-wide stone road from the village core to the grid edge in the dominant cardinal direction toward that village.
  - *Fix:* When generating the starting village (where no other villages are known yet), it falls back to generating 4 exit roads in all cardinal directions.
- Added `otherVillages` parameter to both `generateVillageLayout` and `_tryGenerate`.
- Updated `world_layout_generator.dart` to pass the filtered other-village list.
- Added a "Regenerate World" UI button on the top right of the screen for debug testing of layouts.
- `flutter analyze`: No issues found.
- `flutter test`: All 3 tests passed.
- Windows Release: `build\windows\x64\runner\Release\shinobi_world.exe`
- Android APK: `build\app\outputs\flutter-apk\app-release.apk` (54.4MB)

## Affected Files

- `lib/game/world_layout/building_layout_generator.dart`
- `lib/game/world_layout/world_layout_generator.dart`
- `project_docs/CURRENT_TASK.md`
- `project_docs/SESSION_LOG.md`

## Warnings

None.

## Blockers

None.

## Next Steps

1. User to review the improved road layout and exit roads in the Windows build.
2. Consider rendering exit roads in a distinct color (e.g. brighter stone) to make them visually distinguishable from internal roads.
