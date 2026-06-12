# Micro Spell Combat Training Environment Contract (G6)

**Date:** 2026-06-12  
**Branch:** `milestone/run-g-game-completion-training-suites`  
**Implementation:** `godot_game/core/sim/micro_combat_training_env.gd`  
**Session:** `godot_game/core/combat/spell_combat_session.gd`  
**Export schema:** `micro_combat_v2` — `godot_game/core/export/micro_combat_telemetry_schema.gd`

## Overview

Isolated 1v1 spell duel. No `GameState` mutation. Macro contact resolution does **not** use this env.

## Reset

```gdscript
env.reset(
  game_seed: int,
  loadout_a_id: String = "hero_patrol",
  loadout_b_id: String = "demon_breach"
) -> Dictionary
```

- Starts `SpellCombatSession.start_duel(seed, loadout_a, loadout_b)`.
- Returns `session.observe()` for active combatant.

## Observation

`session.observe(combatant_index := -1) -> Dictionary`

| Field | Type | Notes |
|---|---|---|
| `seed` | int | Combat seed |
| `sim_time` | float | Combat clock |
| `active_combatant_id` | String | Whose turn |
| `combatant_id` | String | POV combatant |
| `health`, `mana` | float | POV vitals |
| `opponent_id` | String | Opponent id |
| `opponent_health`, `opponent_mana` | float | Opponent vitals |
| `loadout_spell_ids` | Array[String] | POV loadout order |
| `finished`, `winner_id` | bool / String | Terminal |

Export adds `legal_spell_count` pre/post step. Cooldowns not in base obs.

**Featurizer:** `MicroCombatFeatureFeaturizer.extract(obs)` → 10-float vector.

## Action space

- Variable width: one slot per spell in active loadout (loadout order defines mask index).
- Special action: `SpellCombatRules.PASS_SPELL_ID` (`__pass__`) when no spell legal — **not** in mask bits.
- `MAX_SPELL_ACTIONS := 16` for neural output head (prototype cap).

## Legal mask

```gdscript
get_legal_spell_ids() -> Array[String]
build_legal_mask() -> Array[int]   # 1 = castable, per loadout order
```

- Mana, cooldown, and rules gate legality (`SpellCombatRules.legal_spell_ids`).
- Export: `legal_spell_ids_json` + `legal_mask_json`.

## Step

```gdscript
step(spell_id: String) -> Dictionary
step_policy() -> Dictionary   # first legal spell, else pass
```

Returns: `{ events, done, winner_id, observation, timeline, reward, selected_spell_id }`

Rewards via `session.get_rewards(actor_id, events)` or export `MicroCombatTrainingReward`.

## Rewards

| Component | Default weight |
|---|---|
| Damage dealt | ×0.1 |
| Healing | ×0.05 |
| Terminal win | +10.0 |

Profiles: `balanced`, `damage`, `survival` (`MicroCombatTrainingReward`).

## Terminal

- `is_done()` when `session.finished` (HP ≤ 0) or `max_steps` truncation in export loop.
- **v2 fix:** terminal row `winner_id` = post-step `session.winner_id` (was empty in v1).

## Export schema reference

**Schema:** `micro_combat_v2`  
**Exporter:** `micro_combat_telemetry_exporter.gd`  
**Run mode:** `run_modes/run_micro_combat_export.gd`

Key columns: `episode_id`, `encounter_id`, `loadout_a_id`, `loadout_b_id`, `spell_catalog_version`, `selected_action`, `pre_observation_json`, `post_observation_json`, `reward_components_json`, `timeline_events_json`, `winner_id`, `terminal`.

**Timing:** Pre-step obs/mask; post-step reward/terminal/winner.

**Tests:** `TestMicroCombatTelemetry`, `TestSpellCombatSession`, `TestMicroNeuralTrainer`

## Related docs

- [MICRO_COMBAT_COMPLETION_AUDIT.md](MICRO_COMBAT_COMPLETION_AUDIT.md)
- [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md)
