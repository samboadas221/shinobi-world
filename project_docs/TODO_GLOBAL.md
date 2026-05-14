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
   - Use passive simulation config for strength gain and casualties.
   - Activate/deactivate NPCs based on player proximity.
2. Improve first-demo loading flow.
   - Show staged generation progress.
   - Persist background generation completion state.
3. Expand character creation.
   - Make ability point effects apply to runtime stats.
   - Persist all chosen customization in a durable profile model.
4. Expand jutsu practice.
   - Persist jutsu EXP and level.
   - Apply level changes to combat damage/cost/seal requirements.
5. Add more jutsu YAML files and make loadout pools richer.

## Lower Priority

1. Improve placeholder art and UI polish.
2. Add more summon contracts.
3. Add village relationships and friendliness calculations.
4. Add bounty/bingo-list gameplay.
5. Add training fields as actual map locations instead of HUD-only mechanics.

## Documentation Tasks

1. Keep `SESSION_LOG.md` updated after every meaningful session.
2. Keep `CURRENT_TASK.md` accurate before and after every task.
3. Update `ARCHITECTURE.md` after structural changes.
4. Add bugs to `KNOWN_BUGS.md` when discovered.

