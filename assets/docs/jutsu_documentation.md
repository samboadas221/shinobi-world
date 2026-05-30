# Jutsu System Documentation

This document explains the Shinobi World jutsu system — how to add jutsus,
configure their behaviour, understand the affinity system, and add new effect
types in Dart. Everything is YAML-driven; no Dart recompile is needed to add
or tweak a jutsu.

---

## 1. File Layout

```
assets/configs/jutsu/
├── jutsu_affinities.yaml      ← Global affinity multipliers + element opposites
├── jutsu_progression.yaml     ← EXP per use, level bonuses, max levels per jutsu
├── fireball.yaml              ← Individual jutsu definition
├── ember_shuriken.yaml
├── fire_wall.yaml
├── water_bullet.yaml
├── mist_step.yaml
├── water_shield.yaml
├── wind_slash.yaml
├── gale_push.yaml
├── cyclone_armor.yaml
├── earth_spike.yaml
├── stone_skin.yaml
├── mud_wall.yaml
├── lightning_spark.yaml
├── static_net.yaml
└── thunder_clap.yaml
```

Each jutsu lives in its own YAML file. The file is registered in
`assets/configs/config_manifest.yaml` under the `jutsu:` list.

---

## 2. Adding a New Jutsu (3 Steps)

### Step 1 — Create the YAML file

```yaml
# assets/configs/jutsu/my_new_jutsu.yaml
jutsu:
  id: my_new_jutsu                    # Must be unique snake_case
  display_name: "My New Jutsu"        # Shown in UI
  chakra_nature: fire                 # fire | water | wind | earth | lightning
  damage: 30                          # Base damage (0 for support/buff jutsus)
  chakra_cost: 20                     # Chakra consumed on cast
  hand_seals: [tiger, horse, snake]   # Sequence of hand seals required
  cast_time_seconds: 1.2              # Casting animation duration
  speed: 25                           # Projectile / action speed
  hand_seal_speed: 10                 # Minimum SpeedSeal stat to perform seals
  chakra_control: 22                  # Minimum ChakraControl stat required
  exp_gain: 5                         # Overworld EXP awarded per practice cast
  # Optional — omit if no effects:
  effects:
    - type: armor_buff
      value: 6
      duration_turns: 3
```

### Step 2 — Register in the manifest

Open `assets/configs/config_manifest.yaml` and add your file path to the `jutsu:` list:

```yaml
jutsu:
  - configs/jutsu/fireball.yaml
  - configs/jutsu/my_new_jutsu.yaml   # ← add here
```

### Step 3 — Set the max level in progression (optional)

Open `assets/configs/jutsu/jutsu_progression.yaml` and add your jutsu's `id`:

```yaml
max_levels:
  my_new_jutsu: 4
```

That's it — no Dart code required.

---

## 3. Full YAML Schema Reference

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | String | ✓ | — | Unique snake_case identifier |
| `display_name` | String | ✓ | — | Shown in UI |
| `chakra_nature` | String | ✓ | — | Element (fire/water/wind/earth/lightning) |
| `damage` | int | ✓ | — | Base damage; 0 for buffs/heals |
| `chakra_cost` | int | ✓ | — | Chakra spent on cast |
| `hand_seals` | List\<String\> | ✓ | — | Seal sequence |
| `cast_time_seconds` | double | ✓ | — | Cast animation duration |
| `speed` | int | — | 20 | Projectile/action speed |
| `hand_seal_speed` | int | — | 10 | Min SpeedSeal stat required |
| `chakra_control` | int | — | 20 | Min ChakraControl stat required |
| `exp_gain` | int | — | 5 | EXP per overworld practice |
| `next_level_id` | String | — | null | ID of the upgraded jutsu (level-up chain) |
| `next_level_exp_required` | int | — | null | Jutsu-specific EXP to unlock upgrade |
| `effects` | List | — | [] | Combat effects (see section 4) |

---

## 4. Effect System

Effects are applied during battle when the jutsu is used. Each entry in the
`effects` list is one effect.

### Effect schema

```yaml
effects:
  - type: armor_buff          # Effect type (see table below)
    value: 8                  # Magnitude (positive = buff, negative = debuff)
    duration_turns: 3         # Turns the effect lasts (0 = instant)
```

### Effect types

| `type` | Target | Description |
|---|---|---|
| `armor_buff` | Self | Increases caster's defense by `value` for `duration_turns` turns |
| `speed_buff` | Self | Increases caster's speed by `value` for `duration_turns` turns |
| `heal_hp` | Self | Instantly restores `value` HP (duration_turns must be 0) |
| `heal_chakra` | Self | Instantly restores `value` chakra (duration_turns must be 0) |
| `enemy_armor_debuff` | Enemy | Decreases enemy defense by `abs(value)` for `duration_turns` turns |
| `enemy_speed_debuff` | Enemy | Decreases enemy speed by `abs(value)` for `duration_turns` turns |

> **Tip:** Multiple effects on one jutsu are supported — just add multiple
> entries in the `effects` list.

### How effects work in combat

1. Player uses jutsu → `BattleController._useJutsu()` is called.
2. Damage is applied first (if `damage > 0`).
3. Each effect is applied in order via `BattleParticipant.applyEffect()`.
4. Instant effects (duration 0) fire immediately and are not tracked.
5. Duration effects add an `ActiveEffect` entry to the participant's list.
6. At the start of each enemy turn, `tickEffects()` decrements all durations
   and removes expired effects, reverting the stat change.

---

## 5. Affinity Multiplier System

Configured in `assets/configs/jutsu/jutsu_affinities.yaml`:

```yaml
jutsu_affinities:
  primary_multiplier: 1.25            # Jutsu matches caster's primary nature
  secondary_multiplier: 1.10         # Jutsu matches caster's secondary nature
  neutral_multiplier: 1.00           # Unrelated element
  opposite_primary_multiplier: 0.75  # Jutsu is opposite of primary nature
  opposite_secondary_multiplier: 0.90

  opposites:
    fire: water
    water: fire
    wind: earth
    earth: wind
    lightning: none                   # No opposite in this game
```

**How it works at runtime:**

When `DamageResolver.jutsuDamage()` is called:
1. It calls `JutsuAffinityConfig.multiplierFor(jutsuNature, casterPrimary, casterSecondary)`.
2. The method checks in priority order: primary match → secondary match → opposite primary → opposite secondary → neutral.
3. The base `damage` from the YAML is multiplied by the result.
4. `DamageConfig.minimumDamage` is applied as a floor.

**Example:** A fire-nature player using Fireball (fire, damage 28):
- Multiplier = 1.25 → final damage = 35 (before enemy defense reduction)

---

## 6. Level-Up Chains (Future Feature)

The system supports upgrade chains via `next_level_id` and `next_level_exp_required`:

```yaml
# fireball.yaml (Level 1)
jutsu:
  id: fireball
  next_level_id: fireball_lv2
  next_level_exp_required: 200
  ...

# fireball_lv2.yaml (Level 2)
jutsu:
  id: fireball_lv2
  display_name: "Fireball Lv.2"
  damage: 38
  chakra_cost: 16
  ...
```

When the player accumulates `next_level_exp_required` jutsu-specific EXP,
`OverworldPracticeController` (future: promotion logic) will swap the player's
jutsu slot to the `next_level_id` version.

> **Note:** Level-up chains are schema-ready but the promotion swap in Dart is
> not yet implemented. The jutsu will continue to level up via the standard
> `jutsu_progression.yaml` bonuses until chain logic is added.

---

## 7. Adding a New Effect Type in Dart

1. Add the enum value to `JutsuEffectType` in `lib/config/models/jutsu_config.dart`:
   ```dart
   enum JutsuEffectType {
     armorBuff, speedBuff, healHp, healChakra,
     enemyArmorDebuff, enemySpeedDebuff,
     myNewEffect,   // ← add here
   }
   ```

2. Map the YAML string in `JutsuEffect._parseEffectType()`:
   ```dart
   case 'my_new_effect': return JutsuEffectType.myNewEffect;
   ```

3. Handle apply and revert in `BattleParticipant._applyBuff()` and `_revertBuff()`.

4. Add a description string in `BattleController._describeEffect()`.

5. Add the YAML type string to this doc's effect types table.

---

## 8. Player Stats Reference

Stats come from `assets/configs/character/stats_scaling.yaml`. These are the
relevant stats that jutsus interact with:

| Stat key | Description |
|---|---|
| `HP` | Hit points in combat |
| `CP` | Chakra pool (max chakra) |
| `ChakraControl` | Governs which jutsus can be cast |
| `ChakraBuffer` | Max chakra cost that can be spent in one cast (overworld) |
| `SpeedSeal` | Minimum required for high-seal-speed jutsus |
| `Armor` | Reduces incoming damage |
| `Taijutsu` | Base attack used for physical strike damage |
| `Speed` | Determines turn order in combat |
