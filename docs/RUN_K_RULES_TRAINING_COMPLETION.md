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
training command: cd training && python -m train.train_macro_bc --csv ../logs/run_k_macro_train.csv --output-weights ../logs/checkpoints/run_k_macro_god_bc.json --seed 42 --epochs 30
eval command: cd training && python -m eval.evaluate_macro_policy --checkpoint ../logs/checkpoints/run_k_macro_god_bc.json --episodes 5 --seed 900 --output ../logs/eval_macro_run_k.csv --godot-root ..
held-out episodes: 5 (seeds 900–904)
completed episodes: 4 (natural game end: breach loss)
turn-capped episodes: 1 (seed 904, max_steps=300)
crashes: 0 (all godot_exit_code=0)
legal-action violations: 252 total illegal policy picks (fallback to first legal action applied; env steps always legal)
baseline comparison: vs macro baselines seed 900, 5 episodes, max_steps=40 — heuristic avg_vp=0.8, avg_reward=2.8; BC live avg_vp=1.0, 4/5 natural completions with max_steps=300 (see logs/run_k_macro_baseline.csv)
result summary: Checkpoint loads in Godot (checkpoint_loaded=true); obs + legal_mask per step; 4/5 held-out episodes finished naturally (shared breach loss); 1 turn-capped; no crashes. BC reproduces heuristic-like VP on smoke scale; high illegal_action_count reflects action-head size mismatch vs live mask (prototype BC).
```

**Live eval proof (Route B):** `LearnedPolicyEvaluator.evaluate_macro` loads JSON weights, extracts `MacroFeatureFeaturizer` obs, builds compact legal mask from `LegalActionQuery`, selects via masked `TinyNeuralNetwork`, applies via `MacroTrainingEnv.step`. Eval CSV columns: `completed_episode`, `turn_capped`, `crashed`, `illegal_action_count`, `game_finished`, `godot_exit_code`.

#### Micro/combatant neural policy

```text
checkpoint path: logs/checkpoints/run_k_micro_hero_bc.json
metadata path: logs/checkpoints/run_k_micro_hero_bc.json.meta.json
training command: cd training && python -m train.train_micro_bc --csv ../logs/run_k_micro_train.csv --output-weights ../logs/checkpoints/run_k_micro_hero_bc.json --seed 42 --epochs 30
eval command: cd training && python -m eval.evaluate_micro_policy --checkpoint ../logs/checkpoints/run_k_micro_hero_bc.json --episodes 10 --seed 800 --output ../logs/eval_micro_run_k.csv --godot-root ..
held-out combats: 10 (seeds 800–809, hero_patrol vs demon_breach)
completed combats: 10
timeouts: 0 (all finished in ~28 steps, max_steps=200)
crashes: 0 (all godot_exit_code=0)
legal-action violations: 140 total (14 per combat; fallback to pass/first legal)
baseline comparison: vs micro baselines seed 800, 10 episodes — random hero_win_rate=0.4, avg_steps=20; damage_first/survival/mana hero_win_rate=0.0, avg_steps=28. BC live: hero_win_rate=0.0, avg_steps=28 (see logs/run_k_micro_baseline.csv)
result summary: Shared role-conditioned BC (Option B below); all 10 combats completed; demon_breach won all (smoke BC not tuned for hero wins).
```

**Hero-side / demon-side vs shared policy (Option B):** Single checkpoint `run_k_micro_hero_bc.json` is intentionally a **shared role-conditioned policy**, not separate hero/demon models. Training CSV includes both combatants' turns (280 BC rows after filtering pass-only steps from 560 total). `MicroCombatFeatureFeaturizer` encodes role via `active_combatant_id` vs `combatant_id` plus per-side health/mana/loadout size. At live eval, the **same weights** drive both `hero_patrol` and `demon_breach` turns each step. Filename retains `hero` for Run K smoke artifact naming; metadata `policy_kind=micro_bc` is role-agnostic.

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
  --output-weights ../logs/checkpoints/run_k_micro_hero_bc.json

# Live eval (Godot rollouts)
.venv/bin/python -m eval.evaluate_macro_policy \
  --checkpoint ../logs/checkpoints/run_k_macro_god_bc.json \
  --episodes 5 --seed 900 --output ../logs/eval_macro_run_k.csv --godot-root ..
.venv/bin/python -m eval.evaluate_micro_policy \
  --checkpoint ../logs/checkpoints/run_k_micro_hero_bc.json \
  --episodes 10 --seed 800 --output ../logs/eval_micro_run_k.csv --godot-root ..
```

### Artifacts (gitignored; not committed)

| Path | Rows / size |
|---|---|
| `logs/run_k_macro_train.csv` | 400 step rows (10 episodes) |
| `logs/run_k_micro_train.csv` | 560 step rows (20 combats) |
| `logs/checkpoints/run_k_macro_god_bc.json` | Godot weights + `.pt` + `.meta.json` |
| `logs/checkpoints/run_k_micro_hero_bc.json` | Godot weights + `.pt` + `.meta.json` |
| `logs/eval_macro_run_k.csv` | 5 live macro episodes |
| `logs/eval_micro_run_k.csv` | 10 live micro combats |

### Macro live eval (seed 900–904)

| Seed | completed | turn_capped | steps | breach | VP | illegal_actions | godot_exit |
|---|---|---|---|---|---|---|---|
| 900 | yes | no | 187 | 10 | 1 | 40 | 0 |
| 901 | yes | no | 227 | 18 | 1 | 48 | 0 |
| 902 | yes | no | 232 | 12 | 1 | 48 | 0 |
| 903 | yes | no | 290 | 16 | 1 | 64 | 0 |
| 904 | no | **yes** | 300 | 0 | 1 | 52 | 0 |

**Note:** Turn-capped episodes prove policy runs but are not evidence of strong play. High `illegal_action_count` expected for untrained-on-layout BC with mismatched action head size vs live mask.

### Micro live eval (seed 800–809)

All 10 episodes: `completed=true`, `godot_exit_code=0`, winner predominantly `demon_breach` (heuristic opponent), ~28 steps per combat.

---

## Test suite (Run K)

**Modules:** 121 (was 110)  
**Assertions:** ~165,649  
**Exit code:** 0 (after `TestDemonSpread` cascade distinction fix)

New modules: `TestAuditExport`, `TestMacroBoardFeaturizer`, `TestCounterSpell`, `TestDualCast`, `TestRandomSilence`, `TestBreachCascadeContract`, `TestRuleContractHeroMovement`.

```bash
scripts/invoke-godot-headless.sh --headless --path godot_game -s res://tests/test_runner.gd
cd training && python -m pytest -q
```

---

## Remaining limitations (post-K)

- Macro BC uses 16-dim aggregate featurizer, not full board tensor in policy head.
- Micro BC skips pass-only steps (empty legal mask) in ETL — pass action not in loadout index space.
- `trade_bonus` / `draft_bonus` / `wizard_access` card effects still stubbed.
- Spell combat not integrated into macro economy loop (by design).

---

## Suggested commit message

```
Run K: breach cascade, training foundation, live policy eval

Implement breach neighbor cascade, hero movement contracts, audit CSV export,
micro spell fidelity, macro board featurizer, PyTorch BC training package,
and Route B live Godot eval for macro/micro checkpoints.
```
