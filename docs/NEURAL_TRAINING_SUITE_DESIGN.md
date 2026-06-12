# Neural Training Suite Design (G9)

**Date:** 2026-06-12  
**Branch:** `milestone/run-g-game-completion-training-suites`  
**Gate:** [TRAINING_READINESS_GATE.md](TRAINING_READINESS_GATE.md) — `GO_FOR_TRAINING`

## Goal

Prototype neural training **inside Godot** (headless) for macro and micro envs. Export telemetry for future external pipelines; do not depend on Python in v1 suite.

## Architecture

```
MacroTrainingEnv / MicroCombatTrainingEnv
        ↓ samples (features, mask, target)
TinyNeuralNetwork (1-hidden-layer MLP)
        ↓ masked argmax
evaluate_policy → metrics CSV
```

No scene nodes. No direct `ActionRules.apply` from trainers.

## Core: `TinyNeuralNetwork`

**Path:** `godot_game/core/ml/tiny_neural_network.gd`

| Property | Default |
|---|---|
| Hidden size | 8 |
| Activation | ReLU hidden, linear output |
| Init | Seeded Xavier-style small weights |
| Training | `train_supervised_step(features, target_index, lr)` — one-hot target, MSE on logits |
| Inference | `forward`, `choose_action_index(logits, legal_mask)` |

**Tests:** `TestTinyNeuralNetwork`

Serialization: `to_dict()` / `from_dict()` for checkpoint experiments.

## Macro suite (G10 direction)

| Component | Path |
|---|---|
| Env | `macro_training_env.gd` |
| Featurizer | `macro_feature_featurizer.gd` — 16 dims |
| Trainer | `macro_neural_trainer.gd` |
| Teacher | Heuristic bot (`collect_heuristic_samples`) |
| Output head size | `MAX_LEGAL_ACTIONS = 64` (prototype cap; full mask ~425 in export) |
| Eval metrics | steps, illegal_actions, total_reward, finished |

**Flow:** `MacroNeuralTrainer.train_from_seed(seed)` → `{ network, avg_loss, eval }` → `render_metrics_csv`.

**Tests:** `TestMacroNeuralTrainer`

**Limitation:** Featurizer is aggregate-only; BC quality capped until board featurizer lands (G12).

## Micro suite (G11 direction)

| Component | Path |
|---|---|
| Env | `micro_combat_training_env.gd` |
| Featurizer | `micro_combat_feature_featurizer.gd` — 10 dims |
| Trainer | `micro_neural_trainer.gd` |
| Teacher | Deterministic first-legal-spell policy |
| Output head | `MAX_SPELL_ACTIONS = 16` |
| Recommended loadouts | `hero_patrol` vs `demon_breach` |

**Tests:** `TestMicroNeuralTrainer`

## Behavioural cloning prototype

1. Reset env with fixed seed.
2. Roll teacher policy for N steps; record `(features, target_index, legal_mask)`.
3. Run supervised steps on `TinyNeuralNetwork`.
4. Evaluate learned policy on held-out seed; count illegal mask violations.

This is **proof-of-pipeline**, not production IL. No replay buffer, no PPO, no multi-episode batching in v1.

## Python hybrid path (future, not implemented)

Documented deferral for serious RL:

| Stage | Location | Notes |
|---|---|---|
| Export | Godot `macro_training_v2` / `micro_combat_v2` CSV | Episode IDs, masks, rewards |
| ETL | External Python | Flatten JSON obs/masks; build `(s,a,r,s',done)` |
| Training | PyTorch/JAX | PPO/BC on full obs once board featurizer exists |
| Deployment | Optional | Export weights → Godot inference hook (not in Run G) |

**Do not** add Python ML deps to Godot project. **Do not** train in editor UI.

## Evaluation harness (G8 alignment)

- Baseline bots: heuristic/random (`BotTurnResolver`).
- NN eval: `evaluate_policy` in macro/micro trainers.
- Compare: illegal action rate, mean reward over fixed step cap, terminal rate.
- Full game metrics: `BatchSimRunner` for bot baselines only.

## Out of scope (Run G)

- GPU acceleration
- Multi-agent self-play
- Reward profile CLI (`WinMaxAgent`, etc.) — designed in export audit, not wired
- Production dataset v2 batch runner (G12)
- Integrating micro combat into macro loop

## Related docs

- [MACRO_TRAINING_ENV_CONTRACT.md](MACRO_TRAINING_ENV_CONTRACT.md)
- [MICRO_SPELL_COMBAT_TRAINING_ENV_CONTRACT.md](MICRO_SPELL_COMBAT_TRAINING_ENV_CONTRACT.md)
- [DONOR_TRAINING_CODE_REVIEW.md](DONOR_TRAINING_CODE_REVIEW.md)
- [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md)
