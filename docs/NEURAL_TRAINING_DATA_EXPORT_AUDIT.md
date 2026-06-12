# Neural Training Data Export Audit

**Last updated:** 2026-06-12  
**Purpose:** Run C audit of whether headless macro economic and micro spell combat exports produce clean, deterministic, structured data suitable for future neural-network training pipelines. This document does **not** implement training; it assesses readiness and gaps.

---

## Executive summary

| Export | Classification | Honest verdict |
|---|---|---|
| **Macro economic** (`macro_training_v1`) | **Partial** | Useful step-level telemetry and weak imitation/RL prototyping; **not** production RL-ready. Observation is too sparse, transitions are incomplete, and provenance/episode keys are missing. |
| **Micro spell combat** (`micro_combat_v1`) | **Mostly Ready** (fixed loadouts) / **Partial** (general) | Usable for deterministic-bot imitation and small-scale RL on a fixed loadout pair with minor parsing; **not** ready for heterogeneous loadouts, multi-encounter macro coupling, or production pipelines without schema v2. |
| **Playthrough CSV** | **Debug Only** | Event-log replay for humans; wrong grain and no legal masks. |
| **Duel log CSV** (`CombatResolver`) | **Debug Only** | Different combat model (card duel); not aligned with `SpellCombatSession`. |

**Bottom line:** Both training telemetry exporters are real, versioned, deterministic, and test-covered — but they are **telemetry and prototyping contracts**, not finished ML datasets. Do not overstate readiness.

---

## Scope and non-goals

**In scope**

- Headless macro export: `MacroTrainingEnv` → `MacroTrainingTelemetryExporter`
- Headless micro export: `MicroCombatTrainingEnv` → `MicroCombatTelemetryExporter`
- Related tests, schemas, and comparison to other CSV exporters

**Out of scope (explicitly deferred)**

- Python training code, ML libraries, models, or training loops
- Godot-side neural network implementation
- Schema changes, new tests, or exporter fixes (recommendations only)

---

## Pre-step vs post-step timing (both exports)

Both exporters record **pre-step** state for observation, legal mask, and selected action, and **post-step** values for reward and terminal flag.

| Field group | Timing | Implication for RL |
|---|---|---|
| Observation scalars, `legal_*`, `selected_*` | Pre-step | State \(s_t\) |
| `reward`, `terminal` | Post-step | \(r_t\), `done` after action \(a_t\) |
| `game_finished`, `winner_id` (macro) | Pre-step | Often stale until terminal row |
| `winner_id` (micro) | Pre-step | Empty on terminal row; winner in `timeline_event_summary` |

To build \((s_t, a_t, r_t, s_{t+1}, \text{done})\), consumers must shift rows: `next_observation` = next row's pre-step fields, or replay from seed + action sequence.

---

## Macro economic export

### Pipeline

| Component | Path |
|---|---|
| Entry script | [`godot_game/run_modes/run_macro_training_export.gd`](../godot_game/run_modes/run_macro_training_export.gd) |
| Environment | [`godot_game/core/sim/macro_training_env.gd`](../godot_game/core/sim/macro_training_env.gd) |
| Session | `BotGameSession` (4-player bot game) |
| Exporter | [`godot_game/core/export/macro_training_telemetry_exporter.gd`](../godot_game/core/export/macro_training_telemetry_exporter.gd) |
| Schema | [`godot_game/core/export/macro_training_telemetry_schema.gd`](../godot_game/core/export/macro_training_telemetry_schema.gd) — `macro_training_v1` |

### Generate sample data

```powershell
$ProjectRoot = "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards"
$GodotProject = Join-Path $ProjectRoot "godot_game"
$Logs = Join-Path $ProjectRoot "logs"
$MacroCsv = Join-Path $Logs "macro_training_seed_42.csv"

& (Join-Path $ProjectRoot "scripts\Invoke-GodotHeadless.ps1") -ArgumentList @(
  "--headless", "--path", $GodotProject,
  "-s", "res://run_modes/run_macro_training_export.gd",
  "--", "--seed", "42", "--max-steps", "50", "--policy", "heuristic", "--output", $MacroCsv
)
```

**Default output:** `user://macro_training_seed_<seed>.csv`  
**Typical project path:** `logs/macro_training_seed_42.csv`

**Verified sample (2026-06-12):** 50 step rows + header; action space size 425 (IDs 0–424); first action `selected_action_id=116`, `selected_action_kind=build_road`.

### Exported columns (22)

| Column | Description |
|---|---|
| `telemetry_schema_version` | `macro_training_v1` |
| `seed` | Game/board setup seed |
| `step_index` | 0-based policy step within this export run |
| `player_id` | Acting player (always active player) |
| `round_number` | Macro round from `GameState` |
| `active_player_id` | Same as `player_id` for exported rows |
| `policy_name` | Bot policy (`heuristic`, `random`) |
| `victory_points` | Acting player's VP (pre-step) |
| `resources_json` | Acting player's resources as JSON object |
| `city_count` | Acting player's city count |
| `road_count` | Acting player's road count |
| `breach_count` | Global breach count |
| `total_demons` | Global demon count (sum over nodes) |
| `game_finished` | Pre-step terminal flag |
| `winner_id` | Pre-step winner (-1 if none) |
| `legal_action_ids_json` | Sorted action IDs for full action space |
| `legal_mask_json` | Parallel 0/1 legality bits |
| `selected_action_id` | Integer action ID taken |
| `selected_action_kind` | Action kind key (e.g. `build_road`, `end_turn`) |
| `reward` | Acting player's step reward (post-step) |
| `terminal` | Post-step game-over flag |
| `event_summaries` | Human-readable event text (`; `-joined) |

### Readiness checklist

| Criterion | Status | Notes |
|---|---|---|
| Row grain | **Steps** | One row per bot policy step (active-player action), not per event or full game |
| Deterministic from seed | **Yes** | `TestMacroTrainingTelemetry._test_deterministic_export` |
| Stable episode/game IDs | **No** | Only `seed` + `step_index`; no `episode_id` |
| Step numbers | **Yes** | `step_index` |
| Current observation/state | **Partial** | Aggregate scalars + `resources_json`; no board topology, heroes, per-node demons, dev cards |
| Legal action masks | **Yes** | Full fixed-size mask (~425 for radius-3 board with current rules) |
| Selected action IDs | **Yes** | `selected_action_id` + `selected_action_kind` |
| Action IDs stable & documented | **Partial** | Stable for fixed board layout via `ActionSpace.from_board`; layout key in code (`to_layout_key()`), not exported |
| Action parameters | **No** | Vertex, edge, hero, trade partner not in CSV — must decode from `action_id` + action space layout |
| Rewards | **Yes (provisional)** | +1.0 per VP gained; +10.0 terminal win; documented as provisional in env |
| Terminal/done flags | **Yes** | `terminal` post-step; `game_finished` pre-step (can disagree on last row) |
| Next observation | **No** | Derive from next row or replay |
| Outcome/winner | **Partial** | Terminal reward bonus; `winner_id` column often -1 until game ends |
| Schema versioned | **Yes** | `macro_training_v1` per row |
| Missing values explicit | **Partial** | Empty strings rare; `-1` for no winner; JSON fields always present |
| Multi-file merge safe | **Risky** | Same seed + different policy overwrites semantic identity; no episode UUID |
| Provenance | **Partial** | `seed`, `policy_name`, schema version; no rules version, commit SHA, scenario name |
| UI/presentation leakage | **Low** | Exporter stays headless; tests forbid scene nodes and direct `ActionRules.apply` |

### Board state and macro-specific gaps

| Feature | In export? |
|---|---|
| Hex/board encoding | **No** |
| Player resources | **Yes** (`resources_json`, acting player only) |
| Roads/cities (counts) | **Yes** (acting player counts only) |
| Heroes / demon positions | **No** (only global `total_demons`, `breach_count`) |
| Active player | **Yes** |
| Round/turn timing | **Partial** (`round_number`; no global turn counter in CSV) |
| Legal action mask | **Yes** |
| Action type + parameters | **Partial** (kind only; params via action ID lookup) |
| Bot policy for imitation | **Yes** (`policy_name` + selected action) |
| Event log state reconstruction | **Partial** | `event_summaries` is human text, not structured payloads; full replay needs seed + action sequence via rules engine |

### ML mode support

| Mode | Support | Notes |
|---|---|---|
| Supervised learning | **Weak** | Sparse features; no labels beyond bot actions |
| Imitation learning | **Partial** | Heuristic/random bot trajectories with mask + action; observation too weak for strong cloning |
| Reinforcement learning | **Partial** | Mask + action + reward + terminal exist; no `next_obs`, provisional reward, single-agent POV |
| Self-play | **No** | Only active player logged per step; no opponent observations in same row |
| Debugging/audit | **Yes** | Primary current use case |

### RL tuple readiness

Target: `episode_id, step_index, observation, legal_action_mask, selected_action, reward, next_observation, done, outcome`

| Field | Ready? |
|---|---|
| `episode_id` | **No** |
| `step_index` | **Yes** |
| `observation` | **Partial** (needs featurization) |
| `legal_action_mask` | **Yes** (JSON array; flatten in ETL) |
| `selected_action` | **Yes** |
| `reward` | **Yes** (provisional semantics) |
| `next_observation` | **No** (shift rows or replay) |
| `done` | **Yes** (`terminal`) |
| `outcome` | **Partial** |

**RL verdict: Partial**

### IL tuple readiness

Target: `observation, legal_action_mask, chosen_action, policy/source, outcome_or_value_target`

| Field | Ready? |
|---|---|
| `observation` | **Partial** |
| `legal_action_mask` | **Yes** |
| `chosen_action` | **Yes** |
| `policy/source` | **Yes** (`policy_name`) |
| `outcome_or_value_target` | **Partial** (terminal VP winner not reliably in row) |

**IL verdict: Partial** (usable for heuristic bot cloning experiments only)

### Flatness for ML pipelines

**Mostly JSON/blob-heavy for macro.** Core scalars are flat, but `legal_action_ids_json`, `legal_mask_json`, `resources_json`, and `event_summaries` require parsing. A typical ETL step must flatten masks to fixed-length vectors and decode action IDs via `ActionSpace` layout.

### Test coverage

| Test module | What it proves |
|---|---|
| `TestMacroTrainingTelemetry` | Schema columns, CSV determinism, row field presence, headless guard |
| `TestMacroTrainingEnv` | Observation determinism, legal actions vs `LegalActionQuery`, illegal step rejection, reward shape, action-sequence summary determinism |

**Not tested:** reward semantics on terminal row, mask bit correctness per action, file I/O round-trip, provenance fields, next-obs reconstruction.

### Recommended future changes (documentation only)

1. Add `episode_id`, `action_space_layout_key`, `rules_version`, optional `git_commit` column or header metadata row.
2. Export dense board observation spec (hex features, demon map, hero positions) or document external featurizer contract.
3. Add `loadout_a`/`loadout_b` equivalent: `scenario_name`, post-step `winner_id`, structured `events_json`.
4. Export `next_*` columns or dual pre/post rows per step.
5. Batch runner for multi-seed datasets with unique episode IDs.
6. Tests: terminal reward timing, mask vs `LegalActionQuery`, CSV ↔ replay parity.

---

## Micro spell combat export

### Pipeline

| Component | Path |
|---|---|
| Entry script | [`godot_game/run_modes/run_micro_combat_export.gd`](../godot_game/run_modes/run_micro_combat_export.gd) |
| Environment | [`godot_game/core/sim/micro_combat_training_env.gd`](../godot_game/core/sim/micro_combat_training_env.gd) |
| Session | [`godot_game/core/combat/spell_combat_session.gd`](../godot_game/core/combat/spell_combat_session.gd) |
| Exporter | [`godot_game/core/export/micro_combat_telemetry_exporter.gd`](../godot_game/core/export/micro_combat_telemetry_exporter.gd) |
| Schema | [`godot_game/core/export/micro_combat_telemetry_schema.gd`](../godot_game/core/export/micro_combat_telemetry_schema.gd) — `micro_combat_v1` |

### Generate sample data

```powershell
$ProjectRoot = "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards"
$GodotProject = Join-Path $ProjectRoot "godot_game"
$Logs = Join-Path $ProjectRoot "logs"
$MicroCsv = Join-Path $Logs "micro_combat_seed_123.csv"

& (Join-Path $ProjectRoot "scripts\Invoke-GodotHeadless.ps1") -ArgumentList @(
  "--headless", "--path", $GodotProject,
  "-s", "res://run_modes/run_micro_combat_export.gd",
  "--", "--seed", "123", "--max-steps", "80",
  "--loadout-a", "hero_patrol", "--loadout-b", "demon_breach",
  "--output", $MicroCsv
)
```

**Default output:** `user://micro_combat_seed_<seed>.csv`  
**Typical project path:** `logs/micro_combat_seed_123.csv`

**Verified sample (2026-06-12):** 40 step rows + header; duel ends at step 39 with `terminal=true`, `selected_spell_id=brain_hex`, `reward=11.4` (1.4 damage + 10 win bonus). **`winner_id` column empty** on terminal row; winner `demon_breach` appears only in `timeline_event_summary` (`combat_end` event).

### Exported columns (19)

| Column | Description |
|---|---|
| `telemetry_schema_version` | `micro_combat_v1` |
| `seed` | Combat RNG/setup seed |
| `step_index` | 0-based combat step |
| `sim_time` | Combat simulation clock (pre-step) |
| `active_combatant_id` | Whose turn |
| `combatant_id` | POV combatant (= active) |
| `health`, `mana` | Active combatant vitals |
| `opponent_id` | Opponent combatant ID |
| `opponent_health`, `opponent_mana` | Opponent vitals |
| `loadout_spell_ids_json` | Active loadout spell list (sorted) |
| `legal_spell_ids_json` | Currently castable spells |
| `legal_mask_json` | Binary mask over loadout order |
| `selected_spell_id` | Spell cast or `__pass__` |
| `reward` | Step reward for acting combatant (post-step) |
| `terminal` | Post-step combat finished |
| `winner_id` | Pre-step winner (often empty at terminal) |
| `timeline_event_summary` | Semicolon-joined `type:json` event strings |

**Not exported:** loadout IDs (`hero_patrol`, `demon_breach`), cooldown state, max health/mana, catalog version, pass action in mask.

### Readiness checklist

| Criterion | Status | Notes |
|---|---|---|
| Row grain | **Steps** | One row per spell cast or pass |
| Deterministic from seed + loadout | **Yes** | Session timeline test + telemetry CSV test |
| Stable episode/game IDs | **No** | `seed` only; loadouts are CLI-only |
| Step numbers | **Yes** | `step_index`, `sim_time` |
| Current observation | **Partial** | Vitals + loadout list; no cooldowns/status |
| Legal action masks | **Yes** | Over loadout order; **`__pass__` outside mask** |
| Selected action | **Yes** | String spell ID or `__pass__` |
| Action IDs stable & documented | **Partial** | Spell IDs from catalog JSON; mask width varies by loadout |
| Target information | **Implicit** | 1v1 — opponent is sole target; no multi-target field |
| Cast/cooldown timing | **Partial** | `sim_time` + events in summary; cooldowns not in obs |
| Damage/heal/effects | **Partial** | In `timeline_event_summary` JSON fragments |
| Rewards | **Yes (provisional)** | ±0.1× damage, +0.05× heal, +10 win |
| Terminal/done | **Yes** | `terminal` reliable when duel completes within `max_steps` |
| Next observation | **No** | Shift rows or replay |
| Outcome/winner | **Partial** | In timeline summary; `winner_id` column unreliable |
| Replay ↔ telemetry align | **Yes** | Same `step_deterministic_policy()` as `spell_combat_replay_mode.gd` |
| Schema versioned | **Yes** | `micro_combat_v1` |
| Multi-file merge | **Risky** | Same seed + different loadouts collide |
| Provenance | **Partial** | Seed + schema only |
| UI leakage | **Low** | No `GameState`; headless session tests |

### Combat-specific notes

- **Pass rows:** When no spell is legal, policy selects `__pass__` with empty `legal_spell_ids_json` and all-zero mask (see sample step 38).
- **Truncation:** If `--max-steps` cuts off before `finished`, last rows may have `terminal=false`.
- **Policy:** Export always uses deterministic bot (first sorted legal spell, else pass) — not human or configurable policy during export.

### ML mode support

| Mode | Support | Notes |
|---|---|---|
| Supervised learning | **Partial** | Fixed loadout pair gives stable feature/action space |
| Imitation learning | **Mostly Ready** | Fixed loadouts + deterministic bot + mask + action |
| Reinforcement learning | **Mostly Ready / Partial** | Good for fixed loadouts; variable loadouts need global action map |
| Self-play | **Partial** | 1v1 with alternating POV rows; same deterministic policy both sides |
| Debugging/audit | **Yes** | Timeline summary useful for humans |

### RL / IL tuple readiness

Same criteria as macro. For fixed `hero_patrol` vs `demon_breach`:

- **RL: Mostly Ready** with row-shift for `next_obs` and timeline parse for outcome
- **IL: Mostly Ready** for bot cloning on that loadout pair

For mixed loadouts or production: **Partial**.

### Flatness for ML pipelines

**Moderate.** Most vitals are scalar CSV fields. `loadout_spell_ids_json`, `legal_spell_ids_json`, `legal_mask_json`, and `timeline_event_summary` need JSON parsing. Easier to flatten than macro masks if loadout size is fixed.

### Test coverage

| Test module | What it proves |
|---|---|
| `TestMicroCombatTelemetry` | Schema, determinism, columns, no `GameState` in exporter |
| `TestSpellCombatSession` | Seeded timeline/winner, mana/cooldown legality, illegal spell rejection, `combat_end` in timeline |

**Not tested:** terminal `winner_id` column, pass-action semantics, reward arithmetic, CSV vs timeline cross-check, loadout variants in export.

### Distinction from `DuelLogExporter`

[`DuelLogExporter`](../godot_game/core/export/duel_log_exporter.gd) exports **card-duel** rounds from `CombatResolver` (attacker/defender moves, round damage). That is a separate combat model from `SpellCombatSession`. Do **not** merge duel logs with micro combat telemetry for training.

### Recommended future changes (documentation only)

1. Export `loadout_a_id`, `loadout_b_id`, `spell_catalog_version`, post-step `winner_id`.
2. Add cooldown vector to observation or separate columns.
3. Include pass in mask or explicit `pass_legal` column.
4. Structured `events_json` replacing semicolon text summary.
5. Global spell action index map for multi-loadout training.
6. Tests: terminal winner column, replay-export parity, reward formula, truncated episodes.

---

## Comparison to other exports

| Exporter | Model | Row grain | Legal mask | Classification |
|---|---|---|---|---|
| `MacroTrainingTelemetryExporter` | `BotGameSession` | Policy step | Yes | **Partial** |
| `MicroCombatTelemetryExporter` | `SpellCombatSession` | Combat step | Yes | **Mostly Ready / Partial** |
| `PlaythroughCsvExporter` | Event log replay | Event | No | **Debug Only** |
| `DuelLogExporter` | `CombatResolver` card duel | Round summary | No | **Debug Only** |

---

## Cross-cutting gaps

1. **No `episode_id`** — composite keys required until schema v2.
2. **No provenance block** — rules version, catalog version, commit SHA, scenario name not in CSV.
3. **No `next_observation`** — all transition-based RL needs ETL or replay.
4. **Provisional rewards** — both envs document interim shaping; not design-final.
5. **No batch export CLI** — one episode per invocation.
6. **No human trajectories** — bot/deterministic policy only.
7. **Macro and micro datasets are independent** — no encounter join key yet (see [MACRO_MICRO_INTEGRATION_DESIGN.md](MACRO_MICRO_INTEGRATION_DESIGN.md)).
8. **Doc drift:** [LOCAL_VERIFICATION.md](LOCAL_VERIFICATION.md) §4 documents macro/micro commands but the success checklist still lists only four legacy CSVs.

---

## Recommended future milestones (not implemented in Run C)

1. **NTD schema v2** — episode IDs, provenance header, post-step outcome fields, structured events.
2. **Macro board featurizer spec** — document or export fixed-length observation vector.
3. **Micro global action index** — stable spell action space across loadouts.
4. **Encounter-linked export** — when `EncounterBridge` drives micro from macro, propagate `encounter_id` and `macro_step_index`.
5. **Training export test matrix** — enforce gaps listed in [RULES_ENFORCEMENT_TEST_MATRIX.md](RULES_ENFORCEMENT_TEST_MATRIX.md).
6. **Batch dataset runner** — multi-seed, multi-policy, unique episode IDs, single merge-safe manifest.

---

## Related docs

- [RULES_ENFORCEMENT_TEST_MATRIX.md](RULES_ENFORCEMENT_TEST_MATRIX.md) — tests enforcing export contracts
- [RULES_GAP_ANALYSIS_AND_DECISION_LOG.md](RULES_GAP_ANALYSIS_AND_DECISION_LOG.md) — deferred NTD decisions
- [MACRO_MICRO_INTEGRATION_DESIGN.md](MACRO_MICRO_INTEGRATION_DESIGN.md) — how datasets should eventually relate
- [run_modes.md](run_modes.md) §E/F — export run mode reference
- [LOCAL_VERIFICATION.md](LOCAL_VERIFICATION.md) §4 — verification commands
