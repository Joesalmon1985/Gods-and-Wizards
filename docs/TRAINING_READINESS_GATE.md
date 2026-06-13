# Training Readiness Gate (G4) — v2 after Run K

**Date:** 2026-06-13  
**Branch:** `milestone/run-k-rules-training-completion`  
**Supersedes:** G4 gate dated 2026-06-12 (Run G) for training pipeline claims.

## Decision

**`GO_FOR_TRAINING`** — macro/micro v2 export, PyTorch BC, checkpoint metadata, and **live Godot policy rollouts** (Route B) are operational at smoke scale.

See [RUN_K_RULES_TRAINING_COMPLETION.md](RUN_K_RULES_TRAINING_COMPLETION.md) for commands, artifact paths, and eval numbers.

## Gate criteria (Run K)

| Criterion | Result |
|---|---|
| Macro rules enforceable headless | Pass — breach cascade + hero movement contracts |
| Micro combat spell subset + fidelity flags | Pass — counter/dual/random silence + status engine |
| Legal masks in export | Pass — macro + micro (pass-only micro steps filtered in Python ETL) |
| Python PyTorch BC | Pass — `training/` package, pytest 11/11 |
| Live eval (not offline-only) | Pass — `LearnedPolicyEvaluator` + `evaluate_*_policy.py` |
| Full Godot test suite | Pass — 121 modules, exit 0 |

## Documented gaps (train with eyes open)

### Macro observation

- BC smoke policy uses **16-dim** `MacroFeatureFeaturizer`; board tensor (240) recorded in `board_features_json` for future models.
- `trade_bonus` / `draft_bonus` / `wizard_access` card effects still stubbed.

### Micro combat

- Pass action (`__pass__`) not in loadout index space — BC ETL skips pass-only rows.
- Fixed loadout pairs recommended for first serious training (`hero_patrol` vs `demon_breach`).

### Export / dataset

- Generated CSVs and checkpoints under `logs/` (gitignored).
- Rewards remain provisional (`MacroTrainingEnv`, `MicroCombatTrainingReward`).

## Related docs

- [RUN_K_RULES_TRAINING_COMPLETION.md](RUN_K_RULES_TRAINING_COMPLETION.md)
- [MACRO_BOARD_FEATURIZER_SPEC.md](MACRO_BOARD_FEATURIZER_SPEC.md)
- [NEURAL_TRAINING_SUITE_DESIGN.md](NEURAL_TRAINING_SUITE_DESIGN.md)
- [training/README.md](../training/README.md)
