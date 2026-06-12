# Macro Game Completion Audit (G1)

**Date:** 2026-06-12  
**Branch:** `milestone/run-g-game-completion-training-suites`  
**Scope:** Headless macro economic rules RC-A through RC-G (40 contracts).  
**Sources:** [RULEBOOK.md](RULEBOOK.md), [RULE_CONTRACT_TEST_INVENTORY.md](RULE_CONTRACT_TEST_INVENTORY.md)

## Verdict

Macro economic loop is **complete for training gate purposes**. All breach/demon-cap contracts are covered; mandatory breach scenario test passes. Five known gaps remain (three design-ambiguous, two partial) — none block `GO_FOR_TRAINING`.

**Mandatory check:** `TestForcedBreachScenario` — breach progression, loss at 10, summary/CSV reporting — **passes**.

## Summary

| Status | Count |
|---|---|
| Complete | 35 |
| Partial | 2 |
| Design ambiguity | 3 |

## Rule contract table

| ID | Rule | Status | Implementation | Tests |
|---|---|---|---|---|
| RC-A-001 | Max 3 demons per node | Complete | `spread_rules.gd` | `TestDemonSpread`, `TestRuleContractBreach` |
| RC-A-002 | 4th demon → breach, not placed | Complete | `spread_rules.gd` | `TestDemonSpread`, `TestForcedBreachScenario`, `TestRuleContractBreach` |
| RC-A-003 | Breach limit 10 | Complete | `breach_end_condition.gd` | `TestBreachEnd`, `TestRuleContractBreach` |
| RC-A-004 | Breach visible in summary/CSV/play | Complete | `event_summary.gd`, `playthrough_csv_exporter.gd` | `TestForcedBreachScenario`, `TestRuleContractUiBoundary` |
| RC-A-005 | Multi-breach per turn (rate>1, same node) | Complete | `spread_rules.gd` | `TestRuleContractBreach` |
| RC-B-001 | Spread end of each player turn | Complete | `action_rules.gd` | `TestInfectionDeckSpread`, `TestRuleContractInfection` |
| RC-B-002 | Initial infection_rate 2 | Complete | `spread_rules.gd` | `TestInfectionDeckSpread`, `TestRuleContractInfection` |
| RC-B-003 | infection_rate draws per turn | Complete | `spread_rules.gd` | `TestInfectionDeckSpread` |
| RC-B-004 | Seeded draw order deterministic | Complete | `spread_rules.gd` | `TestDemonSpread`, `TestRuleContractInfection` |
| RC-B-005 | Discard reshuffle deterministic | Complete | `spread_rules.gd` | `TestRuleContractInfection` |
| RC-B-006 | Age end infection_rate +1 | Complete | `draft_rules.gd` | `TestDraftAgeAdvance` |
| RC-B-007 | Age-weighted reshuffle probabilities | Design ambiguity | — | — |
| RC-C-001 | Hero clears all demons on enter | Complete | `contact_resolution_rules.gd` | `TestMacroContactResolution` |
| RC-C-002 | Demon spawn onto hero cleared | Complete | `contact_resolution_rules.gd` | `TestMacroContactResolution`, `TestInfectionDeckSpread` |
| RC-C-003 | No SpellCombatSession in macro | Complete | — (omission) | `TestMacroContactResolution` |
| RC-C-004 | Friendly hero stacking | Design ambiguity | — | — |
| RC-D-001 | Demon >0 suppresses production | Complete | `city_occupation_rules.gd` | `TestCityDemonOccupation` |
| RC-D-002 | Full round occupied → purge dev | Complete | `city_occupation_rules.gd` | `TestCityDemonOccupation` |
| RC-D-003 | Timer reset on demon clear | Complete | `city_occupation_rules.gd` | `TestCityDemonOccupation` |
| RC-D-004 | Block build dev while occupied | Complete | `development_rules.gd` | `TestCityDemonOccupation` |
| RC-D-005 | Occupation visible in view-model | Complete | `strategic_development_view_model.gd` | `TestRuleContractUiBoundary` |
| RC-D-006 | New dev in occupied city | Design ambiguity | — | — |
| RC-E-001 | 4 actions per hero per turn | Complete | `turn_lifecycle_rules.gd` | `TestHeroActionBudget` |
| RC-E-002 | Failed move no consume | Complete | `move_rules.gd` | `TestHeroActionBudget` |
| RC-E-003 | Budget resets on turn boundary | Complete | `turn_lifecycle_rules.gd` | `TestHeroActionBudget` |
| RC-E-004 | Independent hero budgets | Complete | `turn_lifecycle_rules.gd` | `TestHeroActionBudget` |
| RC-E-005 | Budget in view-model | Complete | `game_state_summary.gd` | `TestStrategicPlayIntegration`, `TestRuleContractUiBoundary` |
| RC-F-001 | turn_number increments on END_TURN | Complete | `action_rules.gd` | `TestTurnLifecycle` |
| RC-F-002 | round_number on full cycle | Complete | `action_rules.gd` | `TestActionApplication` |
| RC-F-003 | TurnPhase in state | Complete | `turn_lifecycle_rules.gd` | `TestTurnLifecycle` |
| RC-F-004 | END_TURN always legal | Complete | `legal_action_query.gd` | `TestStrategicPlayIntegration` |
| RC-F-005 | Production at round boundary | Partial | `production_rules.gd` | `TestTurnLifecycle` |
| RC-F-006 | Per-turn flags reset | Complete | `turn_lifecycle_rules.gd` | `TestTurnLifecycle` |
| RC-G-001 | Active player only may offer | Complete | `legal_action_query.gd`, `trade_offer_rules.gd` | `TestRuleContractTrading` |
| RC-G-002 | Target accepts on their turn | Complete | `trade_offer_rules.gd` | `TestTradeOfferAccept`, `TestRuleContractTrading` |
| RC-G-003 | Reject leaves resources | Complete | `trade_offer_rules.gd` | `TestTradeOfferAccept` |
| RC-G-004 | Duplicate offer same turn blocked | Complete | `trade_offer_rules.gd` | `TestTradeOfferAccept` |
| RC-G-005 | Offer dedup clears on END_TURN | Complete | `trade_offer_rules.gd` | `TestRuleContractTrading` |
| RC-G-006 | PLAYER_TRADE deprecated | Complete | `legal_action_query.gd` | `TestTradeOfferAccept` |
| RC-G-007 | Pending offers survive until accept/reject | Partial | `trade_offer_rules.gd` | `TestRuleContractTrading` |

## Known gaps (documented, not blocking)

| ID | Gap | Notes |
|---|---|---|
| RC-B-007 | Age-weighted infection reshuffle | Simple discard reshuffle only; rulebook probabilities deferred |
| RC-C-004 | Friendly hero stacking | Single hero per node enforced implicitly; stacking rule undefined |
| RC-D-006 | New dev in occupied city | Build blocked; rule for cards already in hand/slots undefined |
| RC-F-005 | Production timing | Production at round wrap only (documented v1 gap) |
| RC-G-007 | Pending offer persistence | Implemented; contract marked Partial pending design confirmation |

## Related docs

- [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md)
- [TRAINING_READINESS_GATE.md](TRAINING_READINESS_GATE.md)
