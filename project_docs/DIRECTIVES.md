# DIRECTIVES

This is the highest priority continuity file for future AI agents working on Shinobi World.

## Required Startup Reading

Before making code or config changes, always read these files:

1. `project_docs/PROJECT_OVERVIEW.md`
2. `project_docs/ARCHITECTURE.md`
3. `project_docs/CURRENT_TASK.md`
4. `project_docs/STYLE_GUIDE.md`
5. `main_goal.txt`

Read additional docs only when relevant to the task.

## Operational Rules

1. Immediately document every new task in `CURRENT_TASK.md` before implementation.
2. When finishing a task, update:
   - `CURRENT_TASK.md`
   - `SESSION_LOG.md`
   - `ARCHITECTURE.md` if architecture changed
   - `TODO_GLOBAL.md` and `KNOWN_BUGS.md` if priorities or bugs changed
3. Never silently refactor unrelated systems.
4. Never rewrite architecture without explicit justification.
5. Preserve existing architecture and code style unless the task requires a change.
6. Keep files modular and small. Target 50-200 lines per Dart file; hard limit is 500 lines.
7. Prefer many small readable files over giant files.
8. If a task is large, first create a plan, then split it into isolated subtasks.
9. Always document important decisions, assumptions, temporary hacks, technical debt, and unfinished work.
10. Never delete project knowledge from markdown files unless it is obsolete or incorrect; prefer appending and clarifying.
11. Maintain continuity across sessions as a primary goal.
12. Before ending a session:
    - summarize completed work
    - summarize pending work
    - leave the repo in a resumable state
13. Minimize token usage:
    - avoid rereading unnecessary files
    - avoid giant outputs
    - avoid unnecessary explanations
14. Do not overengineer solutions. Build the smallest durable system that fits the current feature.
15. Do not add libraries unless needed. If a new library is needed, ask the user first.

## Shinobi World Specific Rules

1. Everything gameplay-related must be config-driven through YAML.
2. No gameplay values may be hardcoded in Dart.
3. Config files must stay modular by domain under `assets/configs/`.
4. Do not mix UI, world exploration, combat, AI, persistence, and config parsing in the same file.
5. Use Drift for persistent large-data systems such as generated villages, NPCs, player profiles, and long-lived run state.
6. Use Flame for overworld runtime logic and components.
7. Turn-based combat must remain separate from overworld exploration.
8. Jutsu behavior, chakra cost, damage, seals, training effects, and progression must be data-driven.
9. NPCs may be stored passively in Drift and only actively simulated when near the player.

## Validation Expectations

When code changes are made, run when possible:

1. `dart format lib test`
2. `flutter analyze`
3. `flutter test`
4. `flutter build windows --debug` when desktop build validity matters

If a command cannot be run, document why in `SESSION_LOG.md` and final response.

