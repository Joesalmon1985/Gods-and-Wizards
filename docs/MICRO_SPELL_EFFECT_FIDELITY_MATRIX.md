# Micro Spell Effect Fidelity Matrix (Run H + K)

**Date:** 2026-06-13 (Run K counter/dual/random silence)  
**Branch:** `milestone/run-k-rules-training-completion`  
**Authority:** `SpellCombatStatusRules`, `SpellCombatRules`, `TestSpellEffectFidelity`, `TestCounterSpell`, `TestDualCast`, `TestRandomSilence`

## Implemented (runtime + tests)

| Effect family | Fields | Runtime | Tests |
|---|---|---|---|
| Instant damage/heal/mana | `damage`, `heal`, `mana_gain` | `SpellCombatRules` | existing combat tests |
| Cooldown gate | `cooldown_seconds` | `SpellCombatRules.can_cast` | `TestSpellEffectFidelity` observe |
| DoT | `dot_dps`, `dot_duration` | `SpellCombatStatusRules.tick_statuses` | `TestSpellEffectFidelity` |
| Barrier | `barrier_absorb_amount`, `barrier_duration` | `resolve_incoming_damage` | `TestSpellEffectFidelity` |
| Shield | `shield_block_charges`, `shield_duration` | `resolve_incoming_damage` | `TestSpellEffectFidelity` |
| Silence | `silence_all_duration` | `can_cast` lockout | `TestSpellEffectFidelity` |
| Buff/debuff duration | `buff_*`, `debuff_*`, durations | status apply + tick expiry | `TestSpellEffectFidelity` |
| Cast/CD rate mods | `buff_cast_rate_mult`, `buff_cooldown_rate_mult`, debuff opposites | status modifiers in session tick | partial via status engine |
| Regen mods | `buff_hp_regen_delta`, `buff_mana_regen_delta`, debuff opposites | session regen tick | partial via status engine |
| Status expiry | `expires_at` on statuses | `tick_statuses` | `TestSpellEffectFidelity` |
| Observation | cooldowns + statuses | `SpellCombatSession.observe` | `TestSpellEffectFidelity` |
| Deterministic replay | — | seeded duel policy | `TestSpellEffectFidelity` |
| Counter spell | `is_counter_spell` | `apply_counter_spell` clears DoT + silence | `TestCounterSpell` |
| Dual cast | `dual_cast` | second `apply_spell_effects` in session | `TestDualCast` |
| Random silence | `silence_random_duration`, `silence_random_n` | `_apply_random_silence` | `TestRandomSilence` |

## Explicitly deferred (post–Run K)

| Effect | Reason |
|---|---|
| Full catalogue field parity | Not every spell id has per-spell contract test |
| Spell–spell edge-case parity | Counter chains, simultaneous expiry ordering beyond v1 tests |

## Status key

- **Implemented** — behaviour in core + targeted test
- **Partial** — engine hook exists; not every catalogue spell verified
- **Deferred** — documented; do not claim implemented in audits
