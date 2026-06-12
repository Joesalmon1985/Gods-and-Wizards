# Rules Enforcement Test Matrix

**Last updated:** 2026-06-12 (post–Run D v1 macro implementation)  
**Purpose:** Map game rules and export contracts to test modules. Used for Run C training-data audit and ongoing milestone verification.

Design intent: [RULEBOOK.md](RULEBOOK.md). Implementation gaps: [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md).

---

## How to read this matrix

| Column | Meaning |
|---|---|
| **Area** | Subsystem or contract domain |
| **Rule / contract** | What must hold |
| **Test module** | Godot test class (`godot_game/tests/`) |
| **Status** | `Enforced`, `Partial`, or `Not enforced` |
| **Notes** | Gaps, suite filter, or follow-up |

Run the full suite:

```powershell
& "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\scripts\Invoke-GodotHeadless.ps1" `
  -ArgumentList @("--headless", "--path", "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game", "-s", "res://tests/test_runner.gd")
```

Integration tests for training exports are registered in [`godot_game/tests/test_registry.gd`](../godot_game/tests/test_registry.gd) under `CATEGORY_INTEGRATION`.

---

## Core rules engine (summary)

| Area | Rule / contract | Test module | Status | Notes |
|---|---|---|---|---|
| Legal actions | Mask size matches action space | `TestLegalActions` | Enforced | Foundation for macro masks |
| Action application | Illegal actions rejected | `TestActionRules`, domain tests | Enforced | |
| Multi-step turn | Bot loops until `END_TURN` | `TestBotPolicy`, bot integration | Enforced | Each step = one legal action |
| Bot policy | Same seed → same heuristic choices | `TestHeuristicBot`, `TestBotPolicy` | Enforced | Macro export policy source |
| Game over | VP win (21) and breach loss at **10** | `TestGameOver`, `TestBreachEnd` | Enforced | |
| Determinism | Same seed + actions → same state | Multiple integration tests | Enforced | Project-wide contract |

---

## Intended v1 macro rules (design — mostly not enforced yet)

| Area | Rule / contract | Test module | Status | Notes |
|---|---|---|---|---|
| Macro contact resolution | Hero entering demon node removes **all** demons instantly | `TestMacroContactResolution` | **Enforced** | |
| Demon cap | Max 3 demons per node; 4th → breach, not placed | `TestDemonSpread`, `TestInfectionDeckSpread` | **Enforced** | |
| Infection deck spread | Draw `infection_rate` nodes per player turn end | `TestInfectionDeckSpread` | **Enforced** | |
| Hero action budget | 4 actions per hero per turn | `TestHeroActionBudget` | **Enforced** | |
| City demon occupation | Demon > 0 → 0 production; full round → purge dev cards | `TestCityDemonOccupation` | **Enforced** | |
| Offer/accept trading | Asymmetric offer/accept; no ports | `TestTradeOfferAccept` | **Enforced** | `PLAYER_TRADE` deprecated |
| Turn lifecycle / phase | `TurnPhase`, per-turn counters | `TestTurnLifecycle` | **Enforced** | |
| Drafting skeleton | Pack pass, hand, city slots | `TestDraftSession` | **Partial** | Auto-pick; no human draft action |
| No tactical combat in macro | Macro loop never invokes `SpellCombatSession` | Architecture implicit | **Enforced by omission** | GD-001 |
| Legacy card duel | `CombatResolver` / `EncounterRules` not v1 macro path | `TestCombatRules` | **Legacy** | Debug/reference only |

---

## Macro training data export

| Area | Rule / contract | Test module | Status | Notes |
|---|---|---|---|---|
| Macro training env | Same seed → identical initial observation | `TestMacroTrainingEnv` | Enforced | |
| Macro training env | Legal actions match `LegalActionQuery` | `TestMacroTrainingEnv` | Enforced | |
| Macro training env | Inactive player has empty legal set | `TestMacroTrainingEnv` | Enforced | |
| Macro training env | Illegal step produces no events | `TestMacroTrainingEnv` | Enforced | |
| Macro training env | Reward dict keyed per player | `TestMacroTrainingEnv` | Enforced | Shape only; not semantic values |
| Macro training env | Same seed + action script → same summary | `TestMacroTrainingEnv` | Enforced | |
| Macro training schema | `STEP_COLUMNS` non-empty; version `macro_training_v1` | `TestMacroTrainingTelemetry` | Enforced | |
| Macro export determinism | Same seed/steps/policy → identical CSV | `TestMacroTrainingTelemetry` | Enforced | |
| Macro export row shape | All schema columns on every row | `TestMacroTrainingTelemetry` | Enforced | |
| Macro export row shape | `legal_mask_json` is JSON array | `TestMacroTrainingTelemetry` | Enforced | |
| Macro export row shape | `selected_action_id` recorded | `TestMacroTrainingTelemetry` | Enforced | |
| Macro export bounds | Row count ≤ `max_steps` | `TestMacroTrainingTelemetry` | Enforced | |
| Macro headless export | Exporter does not call `ActionRules.apply` directly | `TestMacroTrainingTelemetry` | Enforced | Architecture guard |
| Macro headless export | No `Node2D` / `Node3D` in exporter | `TestMacroTrainingTelemetry` | Enforced | |
| **Gap:** macro reward semantics | Terminal bonus on correct step; VP delta values | — | **Not enforced** | See [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md) |
| Macro mask spot-check | Step 0 mask bits match `LegalActionQuery` | `TestMacroTrainingTelemetry` | **Partial** | Step 0 only |
| Macro export `phase` column | Present on every row | `TestMacroTrainingTelemetry` | **Enforced** | Additive v1 column |
| **Gap:** macro terminal fields | Post-step `winner_id` / `game_finished` in CSV | — | **Not enforced** | Pre-step obs exported today |
| **Gap:** macro file I/O | `write_episode` round-trip equals `render_csv` | — | **Not enforced** | |
| **Gap:** macro provenance | Rules version, commit SHA in export | — | **Not enforced** | |
| **Gap:** macro next observation | Transition tuple reconstructable from CSV | — | **Not enforced** | |
| **Gap:** macro batch export | Multi-seed unique episode IDs | — | **Not enforced** | No batch runner yet |

---

## Micro spell combat training data export

| Area | Rule / contract | Test module | Status | Notes |
|---|---|---|---|---|
| Spell combat session | Same seed → same winner and timeline | `TestSpellCombatSession` | Enforced | Underpins export determinism |
| Spell combat session | Zero mana → no legal spells | `TestSpellCombatSession` | Enforced | |
| Spell combat session | Illegal spell rejected | `TestSpellCombatSession` | Enforced | |
| Spell combat session | Timeline includes `combat_end` | `TestSpellCombatSession` | Enforced | |
| Spell combat session | Headless (no scene imports) | `TestSpellCombatSession` | Enforced | |
| Micro training schema | `STEP_COLUMNS`; version `micro_combat_v1` | `TestMicroCombatTelemetry` | Enforced | |
| Micro export determinism | Same seed/steps/loadouts → identical CSV | `TestMicroCombatTelemetry` | Enforced | Default loadouts only in test |
| Micro export row shape | All schema columns present | `TestMicroCombatTelemetry` | Enforced | |
| Micro export row shape | `legal_mask_json` is JSON array | `TestMicroCombatTelemetry` | Enforced | |
| Micro headless export | Exporter does not reference `GameState` | `TestMicroCombatTelemetry` | Enforced | Macro/micro separation |
| **Gap:** micro terminal winner | `winner_id` column populated post-step | — | **Not enforced** | Empty on terminal row today |
| **Gap:** micro pass action | Pass rows when mask all-zero | — | **Not enforced** | |
| **Gap:** micro reward formula | Damage/heal/win bonus arithmetic | — | **Not enforced** | |
| **Gap:** replay ↔ export parity | CSV steps match `SpellCombatSession.timeline` | — | **Not enforced** | Replay mode uses same policy |
| **Gap:** micro loadout variants | Export with non-default loadouts | — | **Not enforced** | CLI supports; tests use defaults |
| **Gap:** micro truncation | Last row when `max_steps` < duel length | — | **Not enforced** | |
| **Gap:** micro provenance | Loadout IDs and catalog version in CSV | — | **Not enforced** | CLI-only today |
| **Gap:** micro next observation | Transition tuple reconstructable | — | **Not enforced** | |

---

## Non-training exports (explicit exclusions)

| Area | Rule / contract | Test module | Status | Notes |
|---|---|---|---|---|
| Playthrough CSV | Event log export for bot session | `TestPlaythroughCsv` (if present) | Partial | **Debug Only** for NN training |
| Duel log CSV | Card duel round export | Duel integration tests | Partial | **Not** spell combat telemetry |
| Training vs debug | NN datasets use telemetry schemas only | — | **Policy** | See NTD-008 in [RULES_GAP_ANALYSIS_AND_DECISION_LOG.md](RULES_GAP_ANALYSIS_AND_DECISION_LOG.md) |

---

## Recommended future test additions (Run C — not implemented)

### Macro rules (priority)

1. Hero move onto demon node → all demons removed; hero remains.
2. Demon spread/spawn onto hero node → demon removed immediately.
3. Demon cap at 3: 4th placement attempt increments breach, does not add demon.
4. Hero action budget: 5th move in same turn illegal for same hero.
5. City with demon count > 0 produces 0 resources.
6. City demon occupied full round → development cards removed.

### Export / telemetry

7. `TestMacroTrainingTelemetry`: assert terminal row `reward` includes +10 when `terminal=true` and game has winner.
8. `TestMacroTrainingTelemetry`: spot-check mask bits against `LegalActionQuery.get_view` for fixed seed step 0.
9. `TestMicroCombatTelemetry`: assert final row `terminal=true` implies `combat_end` in timeline summary with `winner_id`.
10. `TestMicroCombatTelemetry`: compare step count and selected spells to direct `SpellCombatSession` replay.
11. `TestMicroCombatTelemetry`: episode with pass-only step when mana exhausted.
12. Shared fixture: document composite episode key `(seed, policy, step_index)` and `(seed, loadout_a, loadout_b, step_index)` for merge tests.

---

## Related docs

- [RULEBOOK.md](RULEBOOK.md) — intended v1 rules
- [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md) — design vs implementation
- [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md) — readiness assessment
- [RULES_GAP_ANALYSIS_AND_DECISION_LOG.md](RULES_GAP_ANALYSIS_AND_DECISION_LOG.md) — deferred decisions
- [TESTING_AND_GIT_WORKFLOW.md](TESTING_AND_GIT_WORKFLOW.md) — test-first milestone process
