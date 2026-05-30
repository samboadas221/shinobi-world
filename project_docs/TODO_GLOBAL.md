# TODO GLOBAL

## High Priority

1. Split `lib/game/shinobi_world_game.dart` into smaller focused modules.
   - Suggested extractions:
     - encounter coordinator
     - overworld camera/controls setup
     - HUD state publisher
     - world loading coordinator
2. Split `lib/data/first_demo_store.dart` if persistence grows.
   - Suggested extractions:
     - schema/table creation
     - run storage
     - NPC/village storage
3. Implement proper fatal attack reaction window in combat.
   - Config already exists for reaction duration and input difficulty.
4. Make combat outcome affect persistent NPC/world state.
   - Enemy removal exists visually, but persistent state needs a durable model.
5. Continue removing any remaining hardcoded non-gameplay UI strings when they affect player-facing flow.

## Medium Priority

1. Improve NPC active/passive simulation.
   - NinjaSpawnerComponent is now live; add idle/patrol behaviors and conflict encounters.
   - Use passive simulation config for strength gain and casualties.
2. Improve first-demo loading flow.
   - Show staged generation progress.
   - Persist background generation completion state.
3. Expand character creation.
   - Make ability point effects apply to runtime stats.
   - Persist all chosen customization in a durable profile model.
4. Expand jutsu practice.
   - Persist jutsu EXP and level. ← partially done (DB write exists; level-up promotion not yet applied to combat)
   - Apply level changes to combat damage/cost/seal requirements at runtime.
5. Implement jutsu level-up chain promotion logic.
   - YAML schema is ready (next_level_id, next_level_exp_required).
   - OverworldPracticeController needs to swap the player's jutsu slot when threshold is reached.
6. Implement hand seal mini-game in combat.
   - Jutsu seal sequences are in config; no input validation exists yet.

## Lower Priority

1. Improve placeholder art and UI polish.
2. Add more summon contracts.
3. Add village relationships and friendliness calculations.
4. Add bounty/bingo-list gameplay.
5. Add training fields as actual map locations instead of HUD-only mechanics.
6. Add camera bounds (player cannot walk off map edges).
   - Was removed to avoid using flame/experimental; implement using Flame's built-in bounds or player-side clamping.

## Completed (Moved from High/Medium)

- ✅ Add 15 jutsus (3 per element) — done 2026-05-26
- ✅ Add elemental affinity damage multipliers — done 2026-05-26
- ✅ Add jutsu effect system (buffs/debuffs/heals) — done 2026-05-26
- ✅ Add building collision system — done 2026-05-26
- ✅ Spawn DB ninjas as active wandering NPCs on the overworld — done 2026-05-26
- ✅ Overhaul combat screen UI — done 2026-05-26

## Documentation Tasks

1. Keep `SESSION_LOG.md` updated after every meaningful session.
2. Keep `CURRENT_TASK.md` accurate before and after every task.
3. Update `ARCHITECTURE.md` after structural changes.
4. Add bugs to `KNOWN_BUGS.md` when discovered.
