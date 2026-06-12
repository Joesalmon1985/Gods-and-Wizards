# Training Readiness Gate (G4)

**Date:** 2026-06-12  
**Branch:** `milestone/run-g-game-completion-training-suites`  
**Inputs:** [MACRO_GAME_COMPLETION_AUDIT.md](MACRO_GAME_COMPLETION_AUDIT.md), [CARD_ECONOMY_COMPLETION_AUDIT.md](CARD_ECONOMY_COMPLETION_AUDIT.md), [MICRO_COMBAT_COMPLETION_AUDIT.md](MICRO_COMBAT_COMPLETION_AUDIT.md)

## Decision

**Run H regression (2026-06-12):** Full suite exit 0 after production timing, trade expiry, card flags, and spell status engine. **`GameRng` per-instance fix** restores batch-sim determinism (`TestBalanceConfig`). Macro/micro training modules unchanged in contract; re-run before serious RL if obs schema extended for new player flags.

Part 2 milestones G5–G13 may proceed. G10–G11 (neural training suites) are authorised with documented gaps below.

Alternative **`GO_FOR_BASELINES_ONLY`** was considered; not selected — headless envs, masks, and v2 export are sufficient for prototype BC/RL in Godot.

## Gate criteria

| Criterion | Result |
|---|---|
| Macro rules enforceable headless | Pass — 35/40 RC-A–G Complete; 5 known gaps non-blocking |
| Mandatory breach scenario | Pass — `TestForcedBreachScenario` |
| Card economy playable | Pass — 96 cards, draft loop, build costs |
| Micro combat deterministic | Pass — `TestSpellCombatSession`, telemetry determinism |
| Legal masks reliable | Pass — `TestMacroTrainingEnv`, `TestRuleContractExport` |
| UI-independent training path | Pass — `MacroTrainingEnv`, `MicroCombatTrainingEnv` |
| Full test suite | Required before merge — see RUN_G_PLAN verification command |

## Documented gaps (train with eyes open)

### Macro observation

- `MacroTrainingEnv.get_observation()` is **aggregate scalars** (VP, resources, counts, breach/demon totals, draft flags).
- **Full global state** (per-hex demons, hero positions, board topology, all players) is **deferred** — design target in [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md).
- v2 CSV includes `pre_observation_json` / `post_observation_json` but content matches env dict, not dense board tensor.
- Featurizer: 16-dim vector (`MacroFeatureFeaturizer`) — prototyping only.

### Card effects

- **`trade_bonus`**, **`draft_bonus`**, **`wizard_access`**: catalogue complete; runtime stub in `DevelopmentEffectEngine`.
- Training on trade/wizard-heavy strategies will not reflect card text until effects implemented.

### Micro combat

- Spell **effect subset** vs JSON catalogue — damage/heal/cooldown core path only.
- Variable loadout action space — fixed pairs (`hero_patrol` vs `demon_breach`) recommended for first training runs.

### Export / dataset

- v2 schemas add episode IDs and post-step fields; still no batch manifest or Python pipeline in-repo.
- Rewards are **provisional** (`MacroTrainingEnv`, `MicroCombatTrainingReward`).

## Milestone routing

| Gate outcome | Allowed |
|---|---|
| `GO_FOR_TRAINING` | G5–G13 including G10–G11 neural suites |
| `GO_FOR_BASELINES_ONLY` | G5–G9, G12–G13 only (no NN training) |
| `NO_GO` | Stop; fix macro/micro/export blockers |

## Related docs

- [MACRO_TRAINING_ENV_CONTRACT.md](MACRO_TRAINING_ENV_CONTRACT.md)
- [MICRO_SPELL_COMBAT_TRAINING_ENV_CONTRACT.md](MICRO_SPELL_COMBAT_TRAINING_ENV_CONTRACT.md)
- [NEURAL_TRAINING_SUITE_DESIGN.md](NEURAL_TRAINING_SUITE_DESIGN.md)
