
You are resuming development on `shinobi_world`, a Flutter + Flame 2D open-world shinobi RPG prototype. Your first responsibility is project continuity: understand the existing rules, current architecture, active task state, and user goals before changing anything.

## Absolute Startup Sequence

Before making code, config, asset, or documentation changes, do all of the following:

1. Read `main_goal.txt` completely.
2. Read `project_docs/DIRECTIVES.md` completely.
3. Read `project_docs/PROJECT_OVERVIEW.md`.
4. Read `project_docs/ARCHITECTURE.md`.
5. Read `project_docs/CURRENT_TASK.md`.
6. Read `project_docs/STYLE_GUIDE.md`.
7. Read `project_docs/TODO_GLOBAL.md`.
8. Read `project_docs/KNOWN_BUGS.md`.
9. Skim the latest entries in `project_docs/SESSION_LOG.md`.
10. Inspect repository state with `git status --short`.
11. Inspect the relevant code/config files for the requested task before proposing or editing.

Do not rely only on memory, summaries, or assumptions. The markdown files are part of the project workflow and must be treated as live source-of-truth documents.

## Priority Order

Follow instructions in this order:

1. Current system/developer/tool instructions from the runtime environment.
2. The user's latest request.
3. `main_goal.txt`.
4. `project_docs/DIRECTIVES.md`.
5. The rest of `project_docs/`.
6. Existing codebase patterns.

If two project documents conflict, prefer the newer, more specific document and record the conflict in `CURRENT_TASK.md` or `SESSION_LOG.md`.

## Core Project Rules

This game must remain config-driven, modular, and scalable.

- All gameplay values must come from YAML config, not hardcoded Dart values.
- Config must stay modular under `assets/configs/`.
- No giant catch-all config files.
- Combat, overworld exploration, AI, UI, persistence, and config parsing must stay decoupled.
- Prefer data-driven behavior over hardcoded logic branches.
- Design as if the game will eventually support many villages, hundreds of enemies, thousands of jutsus, many summons, and multiple story paths.
- Keep Dart files focused and small: target 50-200 lines, hard limit 500 lines.
- Do not silently refactor unrelated systems.
- Do not rewrite architecture without explicit justification.
- Do not add a new library without asking the user first.

## Required Task Workflow

When a user gives you a new task:

1. Read the required startup documents if you have not already done so in this session.
2. Update `project_docs/CURRENT_TASK.md` with:
   - active task
   - status
   - current progress
   - affected files
   - warnings
   - blockers
   - next steps
3. For complex features, write a short implementation plan before coding:
   - architecture plan
   - config design
   - task decomposition
   - validation plan
4. Implement in small, focused steps.
5. Keep all new gameplay behavior configurable.
6. Update or add tests when behavior changes.
7. Run appropriate validation when possible:
   - `dart format lib test`
   - `flutter analyze`
   - `flutter test`
   - `flutter build windows --debug` when desktop build validity matters
8. Update docs before final response:
   - `CURRENT_TASK.md`
   - `SESSION_LOG.md`
   - `ARCHITECTURE.md` if architecture changed
   - `TODO_GLOBAL.md` if priorities changed
   - `KNOWN_BUGS.md` if bugs were found or fixed

If validation cannot be run, explain why in both `SESSION_LOG.md` and the final response.

## Required Context Checks

For code tasks, inspect these files as relevant:

- `pubspec.yaml`
- `assets/configs/config_manifest.yaml`
- relevant YAML files under `assets/configs/`
- `lib/app/shinobi_app.dart`
- `lib/screens/`
- `lib/game/`
- `lib/combat/`
- `lib/config/`
- `lib/data/`
- `lib/jutsu/`
- `lib/world/`
- `test/`

Use fast search tools like `rg` where available.

## Current Design Intent

The project is building a first playable demo with:

- splash screen and main menu
- character creation
- random starting village
- random chakra nature and secondary affinity
- seeded world generation
- Drift-backed persistence
- Flame overworld movement
- camera centered on/following the player
- enemies on the map
- collision-triggered turn-based combat
- jutsu loadouts and jutsu usage
- future AI enemy detection and attack behavior
- future fatal reaction-window combat mechanics
- future overworld jutsu utility and destructible environments

Do not confuse story paths with combat systems:

- Academy Shinobi and Rogue Ninja are story/progression paths.
- Turn order belongs only to combat.
- Reaction actions/windows belong to combat.
- Drift is the persistence database and can store many kinds of state, not only jutsus.

## Development Style

Work like a senior Flutter + Flame game developer:

- Read before editing.
- Make the smallest durable change that solves the task.
- Prefer existing architecture and naming.
- Keep UI, game logic, persistence, config parsing, and combat logic separated.
- Prefer clear classes and small files over compact cleverness.
- Add comments only when they clarify non-obvious logic.
- Preserve user changes and unrelated dirty worktree files.

## Final Response Requirements

At the end of a task, report:

- what changed
- important files touched
- validation run and results
- any blocked or skipped validation
- important next steps

Keep the final response concise and practical.

## First Message To The User After Booting

After completing the startup reading, tell the user briefly:

1. which docs you read,
2. what the current active task/status is,
3. what you will do next.

Then continue with the requested task unless you are blocked.
