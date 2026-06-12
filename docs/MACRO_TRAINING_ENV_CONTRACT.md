# Macro Training Environment Contract (G5)

**Date:** 2026-06-12  
**Branch:** `milestone/run-g-game-completion-training-suites`  
**Implementation:** `godot_game/core/sim/macro_training_env.gd`  
**Export schema:** `macro_training_v2` — `godot_game/core/export/macro_training_telemetry_schema.gd`

## Overview

Headless wrapper over `BotGameSession` (4-player bot game). One **policy step** = one legal action by the active player. UI must not call `ActionRules.apply` directly.

## Reset

```gdscript
env.reset(game_seed: int, policy: String = "heuristic") -> Dictionary
```

- Starts `BotGameSession.start_four_player(seed, policy)`.
- Returns initial observation for active player.
- Deterministic: same seed → same observation (`TestMacroTrainingEnv`).

## Observation

`get_observation(player_id: int) -> Dictionary`

| Field | Type | Notes |
|---|---|---|
| `seed` | int | Game seed |
| `player_id` | int | POV player |
| `round_number` | int | Macro round |
| `active_player_id` | int | Current actor |
| `is_active_player` | bool | POV is actor |
| `waiting_for_human` | bool | Human gate (false in bot export) |
| `waiting_for_draft` | bool | Draft phase flag |
| `victory_points` | int | Acting player VP |
| `resources` | Dict | wood/brick/wheat/sheep/ore counts |
| `city_count`, `road_count` | int | Acting player |
| `breach_count`, `total_demons` | int | Global |
| `game_finished`, `winner_id` | bool / int | Terminal state |
| `policy_name` | String | Bot policy id |
| `phase` | String | `TurnPhase` key |
| `draft_age`, `infection_rate` | int | Draft/demon context |
| `development_hand_json` | String | JSON array of card ids |
| `draft_pack_size` | int | Cards left in pack |
| `action_space_layout_key` | String | e.g. `actions_425` |

**Featurizer (optional):** `MacroFeatureFeaturizer.extract(obs)` → 16-float vector.  
**Gap:** Not full global board state — see [TRAINING_READINESS_GATE.md](TRAINING_READINESS_GATE.md).

## Action space

- Fixed layout from `ActionSpace.from_board(state)` — ~425 actions on radius-3 board.
- Actions are `GameAction` with stable integer `action_id` per layout.
- Kinds include: build road/city, move hero, bank trade, trade offer/accept/reject, draft pick, build development, end turn.
- `action_params_json` in export decodes vertex/edge/hero/target from selected action.

## Legal mask

```gdscript
get_legal_action_view(player_id) -> LegalActionView
get_legal_actions(player_id) -> Array[GameAction]
```

- Active player only; inactive → empty mask.
- Must match `LegalActionQuery.get_legal_actions_sorted(state)` (`TestMacroTrainingEnv`).
- Export: parallel `legal_action_ids_json` + `legal_mask_json` (0/1 bits).

## Step

```gdscript
step(action: GameAction) -> Dictionary
```

Returns: `{ events, done, rewards, summary, observation }`

- Illegal actions should be rejected by caller; env applies via `ActionRules` / session.
- `step_policy_action()` uses bot heuristic/random policy.

## Rewards

**Env step rewards** (`get_rewards()`):

| Component | Value |
|---|---|
| VP delta | +1.0 per VP gained this step (acting player) |
| Terminal win | +10.0 to `winner_id`; +0.0 others |
| Breach loss (`winner_id == -1`) | +0.0 all |

**Export components** (`MacroTrainingReward`): `vp_delta`, `breach_delta`, `terminal_win`, `demon_clear`; profiles `balanced`, `vp`, `survival`.

## Terminal

- `done` / `is_game_over()` when `session.finished` or VP/breach end condition fires.
- `summary`: seed, winner_id, breach_count, vp_by_player, outcome_reason.

## Export schema reference

**Schema:** `macro_training_v2`  
**Exporter:** `macro_training_telemetry_exporter.gd`  
**Run mode:** `run_modes/run_macro_training_export.gd`

Key columns: `episode_id`, `macro_step_index`, `rules_version`, `scenario_name`, `pre_observation_json`, `post_observation_json`, `reward_components_json`, `structured_events_json`, `terminal`.

**Timing:** Pre-step obs/mask/action; post-step reward/terminal/post_obs.

**Tests:** `TestMacroTrainingEnv`, `TestMacroTrainingTelemetry`, `TestRuleContractExport`

## Related docs

- [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md)
- [TRAINING_READINESS_GATE.md](TRAINING_READINESS_GATE.md)
