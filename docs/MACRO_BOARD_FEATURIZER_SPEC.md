# Macro Board Featurizer Spec (GD-012)

**Version:** `macro_board_v1`  
**Implementation:** `godot_game/core/ml/macro_board_featurizer.gd`  
**Run:** K4 (Run K)

---

## Purpose

Fixed-length board tensor for macro/god-agent training and telemetry. Complements aggregate scalar observations in `MacroTrainingEnv`; does not replace `MacroFeatureFeaturizer` (16-dim BC prototype).

---

## Board topology

- Radius-3 hex board → **60 nodes** (`board.get_all_nodes_sorted()` order).
- Order is deterministic for a given seed and board generation rules.

---

## Per-node features (4 × 60 = 240 values)

| Index offset | Name | Range | Source |
|---|---|---|---|
| +0 | `demon_norm` | 0.0–1.0 | `demon_count / MAX_DEMONS_PER_NODE` (3) |
| +1 | `hero_owner_norm` | 0.0–1.0 | `(player_id + 1) / 4` if hero present, else 0 |
| +2 | `city_owner_norm` | 0.0–1.0 | `(player_id + 1) / 4` if city present, else 0 |
| +3 | `road_adjacent` | 0 or 1 | Any road on edge touching node |

Flattened vector length: **240** (`BOARD_FEATURE_SIZE`).

---

## Export / observation

- `MacroTrainingEnv.get_observation()` → `board_features_json` (JSON array of floats).
- `macro_training_v2` step rows: embedded in `pre_observation_json` / `post_observation_json`.
- Schema columns unchanged; board features are inside observation JSON (additive).

---

## Training usage (Run K)

- **Telemetry / dataset v2:** board features recorded for future dense featurizers.
- **Route B BC (smoke):** policy still uses `MacroFeatureFeaturizer` (16 dims) for `TinyNeuralNetwork` compatibility.

Future work: dedicated MLP input = scalars + board tensor, or CNN over node graph.

---

## Tests

- `TestMacroBoardFeaturizer` — size, determinism, observation JSON, demon normalization.
