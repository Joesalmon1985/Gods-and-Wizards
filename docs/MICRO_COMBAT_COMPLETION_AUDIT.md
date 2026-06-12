# Micro Spell Combat Completion Audit (G3)

**Date:** 2026-06-12  
**Branch:** `milestone/run-g-game-completion-training-suites`  
**Scope:** `SpellCombatSession` headless tactical combat — determinism, export, catalogue fidelity.

## Verdict

Micro combat is **complete for isolated training**. Session is headless, seeded, and deterministic. v2 export fixes terminal `winner_id`. Spell catalogue has **partial fidelity** vs JSON spec (subset of effect types implemented).

## Session core

| Criterion | Status | Implementation | Tests |
|---|---|---|---|
| Headless duel | Complete | `spell_combat_session.gd` | `TestSpellCombatSession` |
| Seeded reproducibility | Complete | `SpellCombatSession.start_duel` | `TestSpellCombatSession` |
| Legal spell query | Complete | `spell_combat_rules.gd` | `TestSpellCombatSession` |
| Illegal spell rejected | Complete | `SpellCombatSession.step` | `TestSpellCombatSession` |
| Timeline + combat_end | Complete | `spell_combat_session.gd` | `TestSpellCombatSession` |
| No GameState mutation | Complete | Isolated session | `TestMicroCombatTelemetry` |
| Pass when no legal spells | Complete | `SpellCombatRules.PASS_SPELL_ID` | Session tests |

## Training environment

| Component | Path |
|---|---|
| Env wrapper | `godot_game/core/sim/micro_combat_training_env.gd` |
| Feature featurizer | `godot_game/core/ml/micro_combat_feature_featurizer.gd` |
| Export entry | `godot_game/run_modes/run_micro_combat_export.gd` |

Tests: `TestMicroCombatTelemetry`, `TestMicroNeuralTrainer`

## Export (micro_combat_v2)

| Fix / field | Status |
|---|---|
| Terminal `winner_id` | **Fixed** — post-step winner on terminal row (`micro_combat_telemetry_exporter.gd` line 49) |
| `episode_id`, `encounter_id` | Present |
| `loadout_a_id`, `loadout_b_id` | Present |
| `pre_observation_json`, `post_observation_json` | Present |
| `reward_components_json`, `timeline_events_json` | Present |
| Schema version | `micro_combat_v2` (`micro_combat_telemetry_schema.gd`) |

## Spell catalogue fidelity

| Area | Status | Notes |
|---|---|---|
| Load + schema version | Complete | `SpellCatalog.load_default()` — `spell_catalog_v1` |
| Required fields per spell | Complete | `TestSpellCatalog` |
| Loadout validation | Complete | `hero_patrol`, `demon_breach` fixtures |
| Effect type subset | **Partial** | JSON spec may define effects not fully simulated in `SpellCombatRules` |
| Full spell roster vs spec | **Partial** | Catalogue loads; not every JSON effect kind has combat runtime |
| Cooldowns in observation export | Partial | In session state; not all obs columns expose cooldown vector |

Reference: `godot_game/data/spells/`, [SPELL_BALANCE_SOURCE.md](SPELL_BALANCE_SOURCE.md)

## Gaps (non-blocking)

1. Global spell action index across variable loadouts — deferred to G12 schema work.
2. Pass action outside legal mask — documented; use `__pass__` when mask all-zero.
3. Macro loop does not invoke spell combat — by design ([MACRO_MICRO_INTEGRATION_DESIGN.md](MACRO_MICRO_INTEGRATION_DESIGN.md)).

## Related docs

- [MICRO_SPELL_COMBAT_TRAINING_ENV_CONTRACT.md](MICRO_SPELL_COMBAT_TRAINING_ENV_CONTRACT.md)
- [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md)
