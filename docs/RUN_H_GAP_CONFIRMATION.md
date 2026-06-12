# Run H Gap Confirmation (H0)

**Date:** 2026-06-12  
**Branch:** `milestone/run-h-rules-card-spell-fidelity`  
**Base:** `main@ff7d30d` (Run G)

## Pre-flight baseline

| Metric | Value |
|---|---|
| Modules run | 104 |
| Assertions | 141726 |
| Failures | 0 |
| Exit code | 0 |

## Run H completion (2026-06-12)

| Metric | Value |
|---|---|
| Modules run | 110 |
| Assertions | 151318 |
| Failures | 0 |
| Exit code | 0 |

**Delivered:** macro surge/clash/production/trade expiry; card effect fidelity + validator honesty; spell status engine + fidelity tests; `GameRng` per-instance fix (determinism).

**Deferred (documented):** full spell catalogue parity (`is_counter_spell`, `dual_cast`, edge interactions).

## Five macro rule gaps

| ID | Gap | Pre-H status | Run H action |
|---|---|---|---|
| RC-B-007 | Age-weighted infection surge | Simple discard reshuffle only | Implement surge + contract tests |
| RC-C-004 | Hero stacking / hostile clash | All occupied nodes blocked | Friendly deny; hostile clash removes both |
| RC-D-006 | Dev in demon-occupied city | Build blocked; design ambiguous | Lock v1 + contract tests |
| RC-F-005 | Production timing | Round-wrap only | Active-player turn-start production |
| RC-G-007 | Trade offer persistence | Cross-turn until accept | Expire at offerer END_TURN |

## Card effect stubs

| Effect | Cards | Pre-H runtime |
|---|---|---|
| `trade_bonus` | 18 | No-op in `DevelopmentEffectEngine` |
| `wizard_access` | 15 | No-op (VP co-effect works) |
| `draft_bonus` | 1 | No-op |
| `production_discount` | 0 | Type known, no-op |

## Spell fidelity gaps

Instant damage/heal/mana/cooldown partial; DoT, barriers, shields, silence, buff/debuff durations, rate modifiers, status expiry not runtime-implemented.

## Training/export dependencies

- `GO_FOR_TRAINING` from Run G
- Production/trade timing changes may affect macro obs/rewards — H5 regression required
- Card flags not in featurizer until H3
- Micro obs lacks status/cooldown vectors until H4

## Proposed order

H1 decisions → H2 macro → H3 cards → H4 spells → H5 training → H6 docs → **STOP for review**
