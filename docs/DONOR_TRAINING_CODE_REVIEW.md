# Donor Training Code Review (G7)

**Date:** 2026-06-12  
**Branch:** `milestone/run-g-game-completion-training-suites`  
**Policy:** Reference-only — **do not merge** donor code into `godot_game/`. See [PROJECT_STATUS.md](PROJECT_STATUS.md).

## Purpose

Review donor projects for ideas adaptable to Run G training suites without violating single-`GameState` architecture.

## Donor: `donor_projects/board_game_M13`

Headless Catan-style prototype — already largely migrated into `godot_game/core/`.

### Adapt (patterns, not files)

| Donor artifact | Idea for Run G | Active equivalent |
|---|---|---|
| `GameSimulator` | Seeded multi-round bot sim loop | `BotGameSession`, `BatchSimRunner` |
| `BotTurnResolver` + heuristic/random policies | Imitation labels for BC | `BotTurnResolver`, `MacroNeuralTrainer.collect_heuristic_samples` |
| `LegalActionQuery` + `ActionSpace` | Fixed action IDs + mask | Same pattern in active core |
| `DebugRunExporter` | Headless CSV from sim result | `MacroTrainingTelemetryExporter` (v2, masks + rewards) |
| `export_debug_run.gd` | CLI `--seed` export entry | `run_macro_training_export.gd` |
| `EventLog` / replay baseline | Determinism audit | `GameEvent` log + `TestMacroTrainingEnv` replay checks |
| `TestBotSimulation`, `TestDeterminism` | Sim regression tests | `TestBotGameSession`, telemetry tests |

### Do not merge

- Duplicate `GameState`, `ScenarioBuilder`, or parallel rule modules.
- UI-bound export (`debug_game_controller.gd`) — training must stay headless.
- M13 debug CSV schema (event rows, no legal mask) — superseded by `macro_training_v2`.

## Donor: `donor_projects/KF_wizard_game`

Wizard presentation + card combat encounter prototype.

### Adapt (concepts, not scenes)

| Donor artifact | Idea for Run G | Active equivalent |
|---|---|---|
| `DeckRuntime.gd` | Draw/discard pile lifecycle | Spell loadout + cooldown state in `SpellCombatSession` |
| `MagicCombatEncounter.gd` | Turn-based spell encounter flow | `SpellCombatSession.step` + timeline |
| Combat profiles on nodes | Loadout/id-based combatants | `CombatantSpellLoadout` (`hero_patrol`, `demon_breach`) |
| `UIManager` card choice | Human spell pick UX | Deferred — `spell_combat_play_mode` (presentation) |
| 3D settlement/wizard views | Embodied layer | `godot_game/embodied/` — not in training path |

### Do not merge

- Scene-graph combat orchestration into core rules.
- KF card-duel model — active tactical canon is `SpellCombatSession`, not `CombatResolver`.
- Donor `DevCardDeck` stub — active catalogue is `development_cards_v1.json` (96 cards).

## Cross-cutting rules

1. **One authoritative `GameState`** — donors remain under `donor_projects/` with `project.godot.donor.txt`.
2. **Extract patterns, reimplement in core** — copy-paste imports forbidden.
3. **Headless first** — any training hook must pass architecture tests (no scene nodes in exporters).
4. **Determinism** — donor sim determinism tests informed `TestMacroTrainingTelemetry` design.

## Related docs

- [integration_plan.md](integration_plan.md)
- [NEURAL_TRAINING_SUITE_DESIGN.md](NEURAL_TRAINING_SUITE_DESIGN.md)
