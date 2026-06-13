# Run K — Rules Engine Completion and NN Training Foundation

**Branch:** `milestone/run-k-rules-training-completion` (from `main`; do not merge without review)  
**Date:** 2026-06-13  
**Supersedes:** proposed separate Runs L–S (consolidated here)

---

## Summary

Run K closes breach cascade semantics, hero-movement contracts, audit CSV export, micro spell fidelity (`counter_spell`, `dual_cast`, random silence), macro board featurizer, Python/PyTorch BC training, and **live Godot policy-in-the-loop evaluation** (Route B).

| Gate | Verdict |
|---|---|
| K0 breach cascade | **Pass** — cascade spread implemented + 14 contract assertions |
| K0B hero movement | **Pass** — 21 contract assertions |
| K5 live-eval route | **Route B** — Python trains PyTorch → exports Godot JSON weights → `LearnedPolicyEvaluator` headless rollouts |
| K9 smoke train/eval | **Pass** — checkpoints + live eval CSVs under `logs/` |

---

## K0 — Breach cascade verdict

**Gap (pre-K):** Fourth demon on a full node incremented breach only; no neighbor spread.

**Implementation:** `spread_rules.gd` — `_breach_node_and_spread` / `_cascade_add_to_neighbor`; events `BreachCascadeEvent`, `BreachSpreadSkippedEvent`.

**Semantics:**

1. Max 3 demons per node (`MAX_DEMONS_PER_NODE`).
2. Attempt at 3 demons: no 4th; breach +1; +1 demon to each **adjacent** node (not infection-deck draw).
3. Full adjacent nodes breach recursively; each node breaches at most once per calculation.
4. Deterministic neighbor order via `board.get_adjacent_nodes`.
5. Infection-deck spread (`resolve_player_turn_end`) does **not** use adjacency — only breach cascade does.

**Tests:** `TestBreachCascadeContract` (14 assertions), updated `TestDemonSpread` (infection vs cascade distinction).

---

## K0B — Hero movement verdict

```
Hero movement verdict: Base allowance = GameConstants.HERO_ACTIONS_PER_TURN (4) per hero; one MOVE_HERO = one edge step.
Development modifier verdict: Sum of built-card hero_actions_bonus via DevelopmentEffectEngine; per-hero budget refreshed each turn.
Demon-clearing verdict: ContactResolutionRules removes ALL demons on entered node (GD-002 / RC-C-001); macro instant resolution.
Legal mask/export verdict: LegalActionQuery masks exhausted heroes; macro_training_v2 records MOVE_HERO rows and legal_mask_json.
Remaining limitations: Movement event payload does not yet include movement_modifier_sources breakdown per card id.
```

**Tests:** `TestRuleContractHeroMovement` (21 assertions).

---

## K1 — Design closure

| ID | Decision |
|---|---|
| RC-D-006 | Cannot build new development in demon-occupied city |
| GD-018 | **Reject 4th build** (no REPLACE_DEVELOPMENT in v1) |
| GD-019 | No macro wizard piece in v1 |
| GD-020 | Hostile hero clash — both removed (GD-014) |
| NTD-013 | Macro reward profiles: `vp_delta`, `survival`, `win_max`; default god-agent = `vp_delta` |
| NTD-014 | Micro reward = damage dealt/taken + win bonus |

---

## K2 — Audit CSV

- `AuditCsvExporter` + `run_audit_playthrough.gd` — provenance columns (`rules_version`, `catalog_version`, `git_sha`).
- Playthrough `road_count` / `production_check` summaries fixed (see `TestPlaythroughCsvExporter`).
- `ExportPathResolver` resolves `logs/` paths relative to repo root.

**Tests:** `TestAuditExport`.

---

## K3 — Micro spell fidelity

| Feature | Status |
|---|---|
| `is_counter_spell` | Implemented — `SpellCombatStatusRules.apply_counter_spell` |
| `dual_cast` | Implemented — second `apply_spell_effects` in `SpellCombatSession.step` |
| `silence_random_*` | Implemented — `_apply_random_silence` (e.g. `quiet`, `spell_shock`) |

**Tests:** `TestCounterSpell`, `TestDualCast`, `TestRandomSilence`, existing `TestSpellEffectFidelity`.

---

## K4 — Macro board featurizer

- `MacroBoardFeaturizer` — 60 nodes × 4 features (demon norm, hero owner, city owner, road-adjacent flag).
- `MacroTrainingEnv.get_observation()` includes `board_features_json`.
- Dense board tensor in export observation JSON; BC featurizer for Route B remains 16-dim `MacroFeatureFeaturizer` (prototype).

Spec: [MACRO_BOARD_FEATURIZER_SPEC.md](MACRO_BOARD_FEATURIZER_SPEC.md)

**Tests:** `TestMacroBoardFeaturizer`.

---

## K5 — Python training package

**Path:** `training/` — PyTorch BC, `masked_policy.py`, `checkpoint_metadata.py`, ETL loaders, pytest (11 tests).

**Live eval route:** **Route B** — Godot loads JSON weights; Python `eval/evaluate_*_policy.py` subprocesses Godot learned eval run modes.

---

## K6 / K7 — Smoke train + live eval (K9)

### Run K endpoint — acceptance evidence

#### Macro/god neural policy

```text
checkpoint path: logs/checkpoints/run_k_macro_god_bc.json
metadata path: logs/checkpoints/run_k_macro_god_bc.json.meta.json
checkpoint_loaded: true (all held-out episodes)
observation_supplied: true
legal_mask_supplied: true
held-out episodes: 5 (seeds 900–904)
completed episodes: 3 (natural game end: breach loss)
turn-capped episodes: 2 (seeds 901, 903; max_steps=300)
crashes: 0 (all godot_exit_code=0)
illegal applied actions: 0 (compact_global_index_v1, 64-slot head)
raw model fallback count: 0 (no illegal-action fallback path used)
baseline comparison: vs macro baselines seed 900, 5 episodes — heuristic avg_vp=0.8; BC live 3/5 natural completions, avg_vp≈1.0, 0 illegal actions
result summary: Post-cleanup Route B eval; 256-dim obs (macro_policy_v2); compact legal mask before argmax; train acc=0.832 on 500 export rows.
```

**Live eval proof (Route B):** `LearnedPolicyEvaluator.evaluate_macro` loads JSON weights, extracts `MacroFeatureFeaturizer` obs, builds compact legal mask from `LegalActionQuery`, selects via masked `TinyNeuralNetwork`, applies via `MacroTrainingEnv.step`. Eval CSV columns: `completed_episode`, `turn_capped`, `crashed`, `illegal_action_count`, `game_finished`, `godot_exit_code`.

#### Micro/combatant neural policy

```text
checkpoint path: logs/checkpoints/run_k_micro_combatant_bc.json
metadata path: logs/checkpoints/run_k_micro_combatant_bc.json.meta.json
checkpoint_loaded: true (all held-out combats)
observation_supplied: true
legal_mask_supplied: true
held-out combats: 10 (seeds 901–910, hero_patrol vs demon_breach)
completed combats: 10
timeouts: 0 (all finished in 28 steps, max_steps=200)
crashes: 0 (all godot_exit_code=0)
illegal applied actions: 0 (loadout_spells_plus_pass_v1, 6-slot head including pass)
raw model fallback count: 0
baseline comparison: vs micro baselines seed 800, 10 episodes — random hero_win_rate=0.4; heuristics 0.0 hero wins; BC live 0/10 hero wins, avg_steps=28
result summary: Shared role-conditioned policy (Option B); train acc=1.0 on 560 export rows; 0 illegal-action fallbacks on held-out eval (seed 901).
```

**Hero-side / demon-side vs shared policy (Option B):** Single checkpoint `run_k_micro_combatant_bc.json` is a **shared role-conditioned policy** trained on both combatants' turns. `MicroCombatFeatureFeaturizer` encodes role via observation features. Action head: 5 loadout spell slots + dedicated pass slot (`loadout_spells_plus_pass_v1`).

**Live eval proof (Route B):** `LearnedPolicyEvaluator.evaluate_micro` loads weights, `session.observe()` + `build_legal_mask()`, masked spell selection, `env.step(spell_id)`. Eval CSV: `completed`, `illegal_action_count`, `steps`, `winner_id`, `godot_exit_code`.

#### Generated artefact handling

```text
logs/ — gitignored; not committed
logs/checkpoints/ — gitignored; not committed
logs/eval_macro_run_k.csv — gitignored; not committed
logs/eval_micro_run_k.csv — gitignored; not committed
Committed fixtures only: training/tests/fixtures/ (tiny synthetic CSVs)
```

---

### Commands (Linux)

```bash
# Export
scripts/invoke-godot-headless.sh --headless --path godot_game --import
scripts/invoke-godot-headless.sh --headless --path godot_game \
  -s res://run_modes/run_macro_training_export.gd \
  -- --episodes 10 --seed 100 --max-steps 40 --output logs/run_k_macro_train.csv
scripts/invoke-godot-headless.sh --headless --path godot_game \
  -s res://run_modes/run_micro_combat_export.gd \
  -- --episodes 20 --seed 200 --max-steps 60 --output logs/run_k_micro_train.csv

# Train
cd training && .venv/bin/python -m train.train_macro_bc \
  --csv ../logs/run_k_macro_train.csv \
  --output-weights ../logs/checkpoints/run_k_macro_god_bc.json
.venv/bin/python -m train.train_micro_bc \
  --csv ../logs/run_k_micro_train.csv \
  --output-weights ../logs/checkpoints/run_k_micro_combatant_bc.json

# Live eval (Godot rollouts)
.venv/bin/python -m eval.evaluate_macro_policy \
  --checkpoint ../logs/checkpoints/run_k_macro_god_bc.json \
  --episodes 5 --seed 900 --output ../logs/eval_macro_run_k.csv --godot-root ..
.venv/bin/python -m eval.evaluate_micro_policy \
  --checkpoint ../logs/checkpoints/run_k_micro_combatant_bc.json \
  --episodes 10 --seed 901 --output ../logs/eval_micro_run_k.csv --godot-root ..
```

### Artifacts (gitignored; not committed)

| Path | Rows / size |
|---|---|
| `logs/run_k_macro_train.csv` | 500 step rows (10 episodes) |
| `logs/run_k_micro_train.csv` | 560 step rows (20 combats) |
| `logs/checkpoints/run_k_macro_god_bc.json` | Godot weights + `.pt` + `.meta.json` |
| `logs/checkpoints/run_k_micro_combatant_bc.json` | Godot weights + `.pt` + `.meta.json` |
| `logs/eval_macro_run_k.csv` | 5 live macro episodes |
| `logs/eval_micro_run_k.csv` | 10 live micro combats |

### Macro live eval (seed 900–904, final acceptance 2026-06-13)

| Seed | completed | turn_capped | steps | breach | VP | illegal_actions | godot_exit |
|---|---|---|---|---|---|---|---|
| 900 | yes | no | 82 | 10 | 1 | 0 | 0 |
| 901 | no | **yes** | 300 | 0 | 0 | 0 | 0 |
| 902 | yes | no | 152 | 12 | 1 | 0 | 0 |
| 903 | no | **yes** | 300 | 0 | 3 | 0 | 0 |
| 904 | yes | no | 130 | 134 | 1 | 0 | 0 |

### Micro live eval (seed 901–910, final acceptance 2026-06-13)

All 10 episodes: `completed=true`, `godot_exit_code=0`, `illegal_action_count=0`, winner `demon_breach`, 28 steps per combat.

---

## Test suite (Run K)

**Godot full suite (final acceptance 2026-06-13):**

```text
modules: 123
assertions: 167745
failures: 0
SCRIPT ERROR count: 0
exit code: 0
log: logs/run_k_final_full_suite.txt
```

**Python pytest:** 11 passed (`cd training && python -m pytest -q`)

**Harness:** `test_runner.gd` registers `TestScriptErrorMonitor` (`OS.add_logger`) and fails the suite when any module emits a Godot `ERROR_TYPE_SCRIPT` during `module.run()`. Summary line: `SCRIPT ERROR count: N`. Harmless shutdown noise only: `ERROR: 1 resources still in use at exit` (CanvasItem RID leak).

New modules: `TestAuditExport`, `TestMacroBoardFeaturizer`, `TestCounterSpell`, `TestDualCast`, `TestRandomSilence`, `TestBreachCascadeContract`, `TestRuleContractHeroMovement`, `TestMacroLegalActionLayout`, `TestMicroLegalActionLayout`, `TestScriptErrorMonitor` (harness).

```bash
scripts/invoke-godot-headless.sh --headless --path godot_game -s res://tests/test_runner.gd 2>&1 | tee logs/run_k_final_full_suite.txt
grep -n "SCRIPT ERROR\|FAILED" logs/run_k_final_full_suite.txt || true
cd training && python -m pytest -q
```

---

## Remaining limitations (post-K)

- Macro BC policy head uses 64-slot compact legal layout; full action-space tensor not in head.
- `trade_bonus` / `draft_bonus` / `wizard_access` card effects still stubbed.
- Spell combat not integrated into macro economy loop (by design).
- Turn-capped macro eval episodes prove rollout stability, not strong play.

---

## Suggested commit message

```
Run K: breach cascade, training foundation, live policy eval

Implement breach neighbor cascade, hero movement contracts, audit CSV export,
micro spell fidelity, macro board featurizer, PyTorch BC training package,
and Route B live Godot eval for macro/micro checkpoints.
```
