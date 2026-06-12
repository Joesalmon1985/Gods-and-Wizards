# Training & Audit UI Plan (Run I — I9)

Separate from normal player mode — for ML engineers and rules auditors.

---

## Dashboards

| Dashboard | Data | Entry |
|---|---|---|
| Macro baseline eval | win rate, VP, breach rate | `run_macro_baseline_eval.gd` |
| Micro baseline eval | duel outcomes | `run_micro_baseline_eval.gd` |
| Batch balance | CSV aggregates | `run_batch_sim.gd` |
| Neural train smoke | loss curve | `run_*_neural_train.gd` |

Future: Godot scene or external notebook consuming CSV — not in Run I impl.

---

## Legal mask inspection

- Display `legal_mask` bit count + decode sample actions via `ActionSpace.to_layout_key()`.
- Compare mask before/after Run H rule changes for regression.

---

## Export status

- Schema version (`macro_training_v2`, `micro_combat_v2`).
- Row counts, seed, policy name footer on export complete.

---

## Rules audit mode

- `strategic_audit_2d_mode` — step bot, view events + legal list.
- Forced breach scenarios via test fixtures pattern.

---

## Visibility tier

Training UI must not ship in player-facing build; gate behind dev flag or separate run mode.

---

## Tests

- `TestMacroTrainingEnv`, `TestMacroTrainingTelemetry`, `TestTrainingEvaluationHarness`
