# Micro Spell Effect Fidelity Matrix (Run H)

**Date:** 2026-06-12  
**Branch:** `milestone/run-h-rules-card-spell-fidelity`  
**Authority:** `SpellCombatStatusRules`, `SpellCombatRules`, `TestSpellEffectFidelity`

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

## Explicitly deferred (Run H scope)

| Effect | Reason |
|---|---|
| `is_counter_spell` interrupt semantics | Complex interaction parity; needs dedicated contract suite |
| `dual_cast` double resolution | Catalogue edge case; unsafe without full interaction model |
| Full catalogue field parity | Prioritised high-value effects only; remaining fields documented here |
| Spell–spell edge-case parity | Counter chains, simultaneous expiry ordering beyond v1 tests |

## Status key

- **Implemented** — behaviour in core + targeted test
- **Partial** — engine hook exists; not every catalogue spell verified
- **Deferred** — documented; do not claim implemented in audits
