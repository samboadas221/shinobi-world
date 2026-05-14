# STYLE GUIDE

## Core Philosophy

This project favors readable, modular, data-driven code. The goal is long-term maintainability across many AI and human development sessions.

## File Size

- Target Dart file size: 50-200 lines.
- Hard limit: 500 lines.
- If a file grows beyond the target, consider extracting a focused controller, service, widget, or model.
- Avoid "god files" that combine unrelated systems.

## Organization

Group files by domain, not by generic file type.

Current domains:

- `app/`
- `character/`
- `combat/`
- `config/`
- `data/`
- `game/`
- `jutsu/`
- `screens/`
- `ui/`
- `world/`

## Naming

- Use descriptive file names such as `battle_controller.dart`, `world_run_generator.dart`, `overworld_practice_controller.dart`.
- Use `Config` suffix for typed YAML models.
- Use `Controller` for stateful domain logic.
- Use `Component` for Flame components.
- Use `Screen` for full Flutter screens.
- Use clear domain names over abbreviations.

## Config Rules

- All gameplay values belong in YAML.
- Config files must be modular under `assets/configs/`.
- Do not create giant config files.
- Do not hide gameplay constants in Dart.
- If a value controls gameplay, timing, damage, AI, spawn, progression, movement, training, economy, or world generation, expose it in YAML.

## UI Rules

- Flutter screens should orchestrate flow and delegate reusable sections to widgets under `lib/ui/`.
- Avoid mixing UI widgets with database, config parsing, or core simulation logic.
- Placeholder UI is acceptable for the demo, but it should not become architecture.

## Flame Rules

- Flame components should focus on runtime entity behavior and rendering.
- Keep overworld behavior separate from combat screens.
- Components may read typed config objects, but should not parse YAML.

## Persistence Rules

- Drift persistence belongs under `lib/data/`.
- Keep SQL table setup and storage logic focused.
- Large generated data such as NPCs, villages, runs, and player profiles should be persisted.
- Do not actively simulate every stored NPC at all times.

## Combat Rules

- Combat is turn-based.
- Speed determines turn order.
- Damage formulas and reaction windows must be config-driven.
- Combat state should not directly mutate overworld internals; return a result object to the caller.

## Forbidden Patterns

- Hardcoded gameplay values in Dart.
- Unrelated refactors during feature work.
- Giant files that combine UI, logic, persistence, and config.
- Silent architecture rewrites.
- Deleting project knowledge from docs without a replacement explanation.

## Formatting

- Use `dart format lib test` after code changes.
- Keep imports clean.
- Prefer explicit code over clever compact code.
- Comments should explain non-obvious decisions, not restate obvious code.

