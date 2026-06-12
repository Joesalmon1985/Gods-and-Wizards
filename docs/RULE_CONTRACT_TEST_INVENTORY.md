# Rule Contract Test Inventory

**Last updated:** 2026-06-12 (Run H fidelity)  
**Purpose:** Map every intended v1 rule from the rulebook to contract tests. Tests must derive from design intent, not implementation quirks.

**Sources:** [RULEBOOK.md](RULEBOOK.md), [TURN_TIMING_AND_PHASE_MODEL.md](TURN_TIMING_AND_PHASE_MODEL.md), [DEVELOPMENT_CARD_CATALOG.md](DEVELOPMENT_CARD_CATALOG.md)

**Status key:** Covered | Partial | Missing | Undefined | Contradictory

---

## A — Breach and demon cap

| ID | Rule | Source | Implementation | Tests | Success | Reject | Edge | Events | Status |
|---|---|---|---|---|---|---|---|---|---|
| RC-A-001 | Max 3 demons per node | RULEBOOK § Demons | `spread_rules.gd` | `TestDemonSpread`, `TestRuleContractBreach` | try_add 0→1,1→2,2→3 | 4th not placed | cap at 3 | DemonSpreadEvent | Covered |
| RC-A-002 | 4th demon → breach, not placed | RULEBOOK § Demons | `spread_rules.gd` | `TestDemonSpread`, `TestForcedBreachScenario`, `TestRuleContractBreach` | forced END_TURN draw | — | repeated over-cap | BreachEvent | Covered |
| RC-A-003 | Breach limit 10 | RULEBOOK § Win/loss | `breach_end_condition.gd` | `TestBreachEnd`, `TestRuleContractBreach` | loss at 10 | no loss at 9 | exactly 10 | GameOverEvent | Covered |
| RC-A-004 | Breach visible in summary/CSV/play | Architecture | `event_summary.gd`, `playthrough_csv_exporter.gd` | `TestForcedBreachScenario`, `TestRuleContractUiBoundary` | summary + CSV row | — | — | readable text | Covered |
| RC-A-005 | Multi-breach per turn (rate>1, same node) | RULEBOOK § Demons | `spread_rules.gd` | `TestRuleContractBreach` | 2 draws same node | — | breach +2 | 2× BreachEvent | Covered |

---

## B — Infection deck timing

| ID | Rule | Source | Implementation | Tests | Success | Reject | Edge | Events | Status |
|---|---|---|---|---|---|---|---|---|---|
| RC-B-001 | Spread end of each player turn | TURN doc step 8 | `action_rules.gd` | `TestInfectionDeckSpread`, `TestRuleContractInfection` | P0 END_TURN spreads | not only round wrap | P1 also spreads | DemonSpreadEvent | Covered |
| RC-B-002 | Initial infection_rate 2 | RULEBOOK § Demons | `spread_rules.gd` | `TestInfectionDeckSpread`, `TestRuleContractInfection` | rate=2 after init | — | — | — | Covered |
| RC-B-003 | infection_rate draws per turn | RULEBOOK § Demons | `spread_rules.gd` | `TestInfectionDeckSpread` | 2 spreads | — | — | — | Covered |
| RC-B-004 | Seeded draw order deterministic | Architecture | `spread_rules.gd` | `TestDemonSpread`, `TestRuleContractInfection` | same seed → same | — | — | — | Covered |
| RC-B-005 | Discard reshuffle deterministic | RULEBOOK § Demons | `spread_rules.gd` | `TestRuleContractInfection` | empty pile → reshuffle | — | continue draw | — | Covered |
| RC-B-006 | Age end infection_rate +1 | RULEBOOK § Demons | `draft_rules.gd` | `TestDraftAgeAdvance` | +1 after 8 rounds | — | — | — | Covered |
| RC-B-007 | Age-weighted reshuffle probabilities | RULEBOOK § Demons | `spread_rules.gd` | `TestRuleContractInfectionSurge` | surge at age II/III | none age I | discard prepend | UnderworldSurgeEvent | Covered |

---

## C — Hero / demon contact resolution

| ID | Rule | Source | Implementation | Tests | Success | Reject | Edge | Events | Status |
|---|---|---|---|---|---|---|---|---|---|
| RC-C-001 | Hero clears all demons on enter | RULEBOOK § Heroes | `contact_resolution_rules.gd` | `TestMacroContactResolution` | 1/2/3 demons | — | hero remains | DemonsClearedEvent | Covered |
| RC-C-002 | Demon spawn onto hero cleared | RULEBOOK § Heroes | `contact_resolution_rules.gd` | `TestMacroContactResolution`, `TestInfectionDeckSpread` | spread to hero node | — | — | clearance event | Covered |
| RC-C-003 | No SpellCombatSession in macro | GD-001 | — (omission) | `TestMacroContactResolution` | grep macro path | — | — | — | Covered |
| RC-C-004 | Friendly hero stacking | RULEBOOK § Heroes | `move_rules.gd`, `contact_resolution_rules.gd` | `TestRuleContractHeroStacking` | friendly blocked | hostile clash | both removed | HeroClashEvent | Covered |

---

## D — City demon occupation

| ID | Rule | Source | Implementation | Tests | Success | Reject | Edge | Events | Status |
|---|---|---|---|---|---|---|---|---|---|
| RC-D-001 | Demon >0 suppresses production | RULEBOOK § Demon/city | `city_occupation_rules.gd` | `TestCityDemonOccupation` | 0 production | — | — | — | Covered |
| RC-D-002 | Full round occupied → purge dev | RULEBOOK § Demon/city | `city_occupation_rules.gd` | `TestCityDemonOccupation` | cards removed | — | VP update | CityDevelopmentPurgedEvent | Covered |
| RC-D-003 | Timer reset on demon clear | RULEBOOK § Demon/city | `city_occupation_rules.gd` | `TestCityDemonOccupation` | timer cleared | — | — | — | Covered |
| RC-D-004 | Block build dev while occupied | RULEBOOK § Demon/city | `development_rules.gd` | `TestCityDemonOccupation` | — | BUILD illegal | — | — | Covered |
| RC-D-005 | Occupation visible in view-model | UI boundary | `strategic_development_view_model.gd` | `TestRuleContractUiBoundary` | occupied flag | — | — | — | Covered |
| RC-D-006 | New dev in occupied city | RULEBOOK § Demon/city | — | — | — | — | — | — | Undefined |

---

## E — Hero action budget

| ID | Rule | Source | Implementation | Tests | Success | Reject | Edge | Events | Status |
|---|---|---|---|---|---|---|---|---|---|
| RC-E-001 | 4 actions per hero per turn | TURN doc | `turn_lifecycle_rules.gd` | `TestHeroActionBudget` | 4 moves | 5th illegal | — | — | Covered |
| RC-E-002 | Failed move no consume | TURN doc | `move_rules.gd` | `TestHeroActionBudget` | — | illegal rejected | budget unchanged | — | Covered |
| RC-E-003 | Budget resets on turn boundary | TURN doc | `turn_lifecycle_rules.gd` | `TestHeroActionBudget` | reset after turn | — | — | — | Covered |
| RC-E-004 | Independent hero budgets | TURN doc | `turn_lifecycle_rules.gd` | `TestHeroActionBudget` | hero B moves after A exhausted | — | — | — | Covered |
| RC-E-005 | Budget in view-model | UI boundary | `game_state_summary.gd` | `TestStrategicPlayIntegration`, `TestRuleContractUiBoundary` | hero_actions_remaining | — | — | — | Covered |

---

## F — Turn lifecycle and phases

| ID | Rule | Source | Implementation | Tests | Success | Reject | Edge | Events | Status |
|---|---|---|---|---|---|---|---|---|---|
| RC-F-001 | turn_number increments on END_TURN | TURN doc | `action_rules.gd` | `TestTurnLifecycle` | +1 per END_TURN | — | — | TurnEndedEvent | Covered |
| RC-F-002 | round_number on full cycle | TURN doc | `action_rules.gd` | `TestActionApplication` | wrap → round+1 | — | — | RoundStartedEvent | Covered |
| RC-F-003 | TurnPhase in state | TURN doc | `turn_lifecycle_rules.gd` | `TestTurnLifecycle` | ACTIVE_PLAYER | — | DRAFT_ROUND | — | Covered |
| RC-F-004 | END_TURN always legal | TURN doc | `legal_action_query.gd` | `TestStrategicPlayIntegration` | in mask | — | — | — | Covered |
| RC-F-005 | Production at active player turn start | TURN doc | `production_rules.gd`, `turn_lifecycle_rules.gd` | `TestRuleContractProductionTiming`, `TestProduction` | active player only | demon-occupied 0 | PRODUCTION phase | ProductionPhaseEvent | Covered |
| RC-F-006 | Per-turn flags reset | TURN doc | `turn_lifecycle_rules.gd` | `TestTurnLifecycle` | flags cleared | — | — | — | Covered |

---

## G — Trading

| ID | Rule | Source | Implementation | Tests | Success | Reject | Edge | Events | Status |
|---|---|---|---|---|---|---|---|---|---|
| RC-G-001 | Active player only may offer | RULEBOOK § Trading | `legal_action_query.gd`, `trade_offer_rules.gd` | `TestRuleContractTrading` | P0 offers on turn | P1 cannot offer as P0 | mask POV | TradeOfferMadeEvent | Covered |
| RC-G-002 | Target accepts on their turn | RULEBOOK § Trading | `trade_offer_rules.gd` | `TestTradeOfferAccept`, `TestRuleContractTrading` | accept transfers | wrong target illegal | — | TradeAcceptedEvent | Covered |
| RC-G-003 | Reject leaves resources | RULEBOOK § Trading | `trade_offer_rules.gd` | `TestTradeOfferAccept` | — | reject | unchanged | TradeRejectedEvent | Covered |
| RC-G-004 | Duplicate offer same turn blocked | RULEBOOK § Trading | `trade_offer_rules.gd` | `TestTradeOfferAccept` | — | 2nd illegal | — | — | Covered |
| RC-G-005 | Offer dedup clears on END_TURN | Run F contract | `trade_offer_rules.gd` | `TestRuleContractTrading` | re-offer next turn | — | — | — | Covered |
| RC-G-006 | PLAYER_TRADE deprecated | RULEBOOK § Trading | `legal_action_query.gd` | `TestTradeOfferAccept` | — | illegal | — | — | Covered |
| RC-G-007 | Pending offers expire after full cycle | RUN_H §5 | `trade_offer_rules.gd` | `TestRuleContractTrading` | accept on target turn | expired reject | turn-age expiry | TradeOfferExpiredEvent | Covered |

---

## H — Drafting and development cards

| ID | Rule | Source | Implementation | Tests | Success | Reject | Edge | Events | Status |
|---|---|---|---|---|---|---|---|---|---|
| RC-H-001 | 96 cards in catalogue | DEVELOPMENT_CARD_CATALOG | `development_catalog.gd` | `TestDevelopmentCatalog` | count=96 | — | — | — | Covered |
| RC-H-002 | 32 cards per age | CATALOG | `development_catalog.gd` | `TestDevelopmentCatalogValidator` | per-age count | — | — | — | Covered |
| RC-H-003 | 8 cards per pack, 3 ages | RULEBOOK § Drafting | `draft_rules.gd` | `TestDraftPackDeal`, `TestDraftAgeAdvance` | 8 rounds → age | — | 24 total | — | Covered |
| RC-H-004 | DRAFT_PICK legality | RULEBOOK § Drafting | `draft_rules.gd` | `TestDraftPickLegality` | legal pick | illegal rejected | — | — | Covered |
| RC-H-005 | Bot draft determinism | Architecture | `draft_rules.gd` | `TestDraftDeterminism`, `TestDraftBotPolicy` | same seed | — | — | — | Covered |
| RC-H-006 | City max 3 dev slots | RULEBOOK § Drafting | `development_rules.gd` | `TestDevelopmentBuild` | 3 slots | 4th illegal | — | — | Covered |
| RC-H-007 | Per-card costs enforced | CATALOG | `development_rules.gd` | `TestDevelopmentPerCardCost` | pay cost | cannot afford | — | — | Covered |
| RC-H-008 | Effect types by category | CATALOG | `development_effect_engine.gd` | `TestDevelopmentEffectType` | per type | — | — | — | Covered |

---

## I — UI / view-model boundary

| ID | Rule | Source | Implementation | Tests | Success | Reject | Edge | Events | Status |
|---|---|---|---|---|---|---|---|---|---|
| RC-I-001 | Breach count in summary | UI boundary | `game_state_summary.gd` | `TestRuleContractUiBoundary` | breach_count field | — | play status format | — | Covered |
| RC-I-002 | Infection rate in summary | UI boundary | `game_state_summary.gd` | `TestRuleContractUiBoundary` | infection_rate | — | — | — | Covered |
| RC-I-003 | Hero budgets in view-model | UI boundary | `strategic_audit_view_model.gd` | `TestStrategicPlayIntegration` | field present | — | — | — | Covered |
| RC-I-004 | Draft state in view-model | UI boundary | `strategic_draft_view_model.gd` | `TestStrategicDraftViewModel`, `TestRuleContractUiBoundary` | pack/hand | — | — | — | Covered |
| RC-I-005 | UI submits via session only | Architecture | `strategic_play_2d_mode.gd` | `TestHumanMacro2DMode` | session submit | no ActionRules.apply | — | — | Covered |

---

## J — Export / reporting

| ID | Rule | Source | Implementation | Tests | Success | Reject | Edge | Events | Status |
|---|---|---|---|---|---|---|---|---|---|
| RC-J-001 | Playthrough breach row | Export | `playthrough_csv_exporter.gd` | `TestForcedBreachScenario`, `TestRuleContractExport` | breach row | — | demon_breach_info | event_summary | Covered |
| RC-J-002 | Playthrough trade/draft/dev rows | Export | `playthrough_csv_exporter.gd` | `TestRuleContractExport` | event types present | — | forced fixture | — | Covered |
| RC-J-003 | Macro export deterministic | Export | `macro_training_telemetry_exporter.gd` | `TestMacroTrainingTelemetry` | same CSV | — | — | — | Covered |
| RC-J-004 | Legal mask matches query | Export | `legal_action_query.gd` | `TestMacroTrainingTelemetry`, `TestRuleContractExport` | step 0 + fixtures | — | — | — | Covered |
| RC-J-005 | Event summaries not blank | Export | `event_summary.gd` | `TestEventSummary`, `TestPlaythroughCsvExporter` | production_check | — | — | — | Covered |

---

## Related docs

- [RULES_ENFORCEMENT_TEST_MATRIX.md](RULES_ENFORCEMENT_TEST_MATRIX.md)
- [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md)
- [RULES_GAP_ANALYSIS_AND_DECISION_LOG.md](RULES_GAP_ANALYSIS_AND_DECISION_LOG.md)
