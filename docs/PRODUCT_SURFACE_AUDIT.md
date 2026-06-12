# Product Surface Audit (Run I — I0)

**Date:** 2026-06-12  
**Branch:** `milestone/run-i-3d-ui-ux-product-planning`  
**Base:** Run H @ `fdae8c9` (not merged to `main`)  
**Suite at I0:** 110 modules, 151,318 assertions, exit 0

Verified against code, tests, and [RUN_H_RULE_DECISIONS.md](RUN_H_RULE_DECISIONS.md). Status labels: **Verified implemented** | **Partial / deferred** | **Planned only**.

---

## Run modes

| Mode | Entry | Layer | Status |
|---|---|---|---|
| 3D wizard-world (F5 default) | `run_modes/wizard_world_mode.tscn` | 3D spectator + cosmetic wizard marker | Prototype |
| 3D macro spectator | `run_modes/macro_spectator_3d_mode.tscn` | Read-only 3D board | Prototype |
| 2D strategic playable | `run_modes/strategic_play_2d_mode.tscn` | Human keyboard macro | Near-term dev default |
| 2D strategic audit | `run_modes/strategic_audit_2d_mode.tscn` | Legal actions + events | Debug/audit |
| 2D strategic placeholder | `run_modes/strategic_2d_mode.tscn` | Minimal read-only 2D | Legacy/debug |
| Spell combat play | `run_modes/spell_combat_play_mode.tscn` | Isolated tactical UI | Isolated |
| Spell combat replay | `run_modes/spell_combat_replay_mode.tscn` | Auto policy replay | Isolated |
| Headless CSV / training | `run_*_export.gd`, `run_*_eval.gd`, `run_headless_bot_game.gd` | Headless | Complete (v2) |

---

## Session APIs

| API | Used by | Status |
|---|---|---|
| `BotGameSession` | All macro visual modes + headless bot CSV | Verified implemented |
| `SpellCombatSession` | Spell play/replay + micro export | Verified implemented (isolated) |
| `CombatResolver` | `run_headless_duel.gd` only | Legacy/debug |
| `MacroTrainingEnv` / `MicroCombatTrainingEnv` | Training runners | Verified implemented |

Presentation must submit via session APIs; no direct `GameState` mutation (enforced by architecture tests).

---

## View models and presenters

| Component | Source | Status |
|---|---|---|
| `StrategicAuditViewModel` | `BotGameSession`, summaries, legal mask | Verified |
| `StrategicDraftViewModel` | Draft packs, pending picks, hand | Verified |
| `StrategicDevelopmentViewModel` | Cities, hand, build legality | Verified |
| `StrategicBoardView` | Read-only board snapshot | Verified (no input) |
| `SpellCombatTimelinePresenter` | `SpellCombatSession.timeline` | Verified |
| Inline play-mode labels | `GameStateSummary` in `strategic_play_2d_mode.gd` | Verified |

**Planned only:** shared HUD view-model shell (see [UI_INFORMATION_ARCHITECTURE.md](UI_INFORMATION_ARCHITECTURE.md)).

---

## Run H mechanics (verified for product docs)

| Rule | Status | Evidence |
|---|---|---|
| Underworld Surge (RC-B-007) | Verified | `TestRuleContractInfectionSurge` |
| Hero hostile clash (RC-C-004) | Verified | `TestRuleContractHeroStacking` |
| No dev in occupied city (RC-D-006) | Verified | `TestRuleContractOccupiedDevelopment` |
| Turn-start production (RC-F-005) | Verified | `TestRuleContractProductionTiming` |
| Trade offer expiry (RC-G-007) | Verified | `TestRuleContractTrading` |
| Card effects (trade/draft/discount/wizard) | Verified | `TestDevelopmentEffectFidelity` |
| Spell DoT/barrier/shield/silence/status | Verified | `TestSpellEffectFidelity`, [MICRO_SPELL_EFFECT_FIDELITY_MATRIX.md](MICRO_SPELL_EFFECT_FIDELITY_MATRIX.md) |
| Counter-spell / dual_cast | Partial / deferred | Matrix § deferred |

---

## Assets, input, cameras

| Item | Status |
|---|---|
| `godot_game/assets/` | **Missing** — no billboard art pipeline on disk |
| Custom `InputMap` | **Missing** — keyboard via `_input` / `ui_accept` only |
| Mouse / hex click | **Planned only** (M22) |
| 3D meshes | Procedural (`PlaneMesh`, `BoxMesh`, runtime in `BoardStateVisualizer`) |
| Wizard marker | Cosmetic only in wizard-world mode |

---

## Test coverage gaps (product)

- No scene tests for `wizard_world_mode.tscn`, `strategic_2d_mode.tscn`
- No shared HUD contract tests
- No billboard metadata tests (pipeline not built)

See [UI_3D_TESTING_STRATEGY.md](UI_3D_TESTING_STRATEGY.md).
