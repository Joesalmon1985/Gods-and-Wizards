# Development Card Economy Completion Audit (G2)

**Date:** 2026-06-12  
**Branch:** `milestone/run-g-game-completion-training-suites`  
**Scope:** 96-card catalogue, draft loop, effect engine, training readiness for card-driven rewards.

## Verdict

Card economy is **complete for catalogue and draft loop**; effect engine is **partial** for presentation-deferred effect types. Training can proceed on production/VP/hero effects; trade and wizard effects are stubbed and documented.

## Catalogue (RC-H-001 / RC-H-002)

| Item | Status | Implementation | Tests |
|---|---|---|---|
| 96 cards total | Complete | `development_catalog.gd`, `data/development/development_cards_v1.json` | `TestDevelopmentCatalog` |
| 32 cards per age (I–III) | Complete | `development_catalog.gd` | `TestDevelopmentCatalogValidator` |
| 8 categories × 4 cards per age | Complete | [DEVELOPMENT_CARD_CATALOG.md](DEVELOPMENT_CARD_CATALOG.md) | `TestDevelopmentCatalogValidator` |
| Per-card costs enforced | Complete | `development_rules.gd` | `TestDevelopmentPerCardCost` |

## Draft loop (RC-H-003 – RC-H-005)

| Item | Status | Implementation | Tests |
|---|---|---|---|
| 8-card packs, 3 ages | Complete | `draft_rules.gd` | `TestDraftPackDeal`, `TestDraftAgeAdvance` |
| DRAFT_PICK legality | Complete | `draft_rules.gd` | `TestDraftPickLegality` |
| Bot draft determinism | Complete | `draft_rules.gd` | `TestDraftDeterminism`, `TestDraftBotPolicy` |
| Age advance + infection_rate +1 | Complete | `draft_rules.gd` | `TestDraftAgeAdvance` |
| City max 3 dev slots | Complete | `development_rules.gd` | `TestDevelopmentBuild` |

## Effect engine (RC-H-008)

| Effect type | Runtime status | Notes |
|---|---|---|
| `production_flat`, `production_bonus_by_resource` | Complete | `DevelopmentEffectEngine.production_bonus_for_city` |
| `vp_flat`, end-game VP scalars | Complete | `ScoreRules`, `end_game_vp_bonus` |
| `hero_actions_bonus`, `hero_spawn` | Complete | Budget refresh, hero placement |
| `city_demon_protection`, `demon_clear_on_play` | Complete | Build-time and purge hooks |
| `production_discount` | Stub | Recognised; no-op on build |
| **`trade_bonus`** | **Complete (Run H)** | `DevelopmentEffectEngine.trade_bonus_for_player`; bonus on accept; `TestDevelopmentEffectFidelity` |
| **`draft_bonus`** | **Complete (Run H)** | Age-start pack peek; `DraftPackPeekEvent`; `TestDevelopmentEffectFidelity` |
| **`wizard_access`** | **Complete (Run H)** | Player flags `wizard_encounter_unlock`, `wizard_trade_unlock`; refresh on purge |
| **`production_discount`** | **Complete (Run H)** | `apply_build_cost_discount`; synthetic fixture in `TestDevelopmentEffectFidelity` |
| **Catalogue validator** | **Complete (Run H)** | Fails `implemented` cards with unimplemented effect types |

Implementation: `godot_game/core/rules/development_effect_engine.gd`  
Tests: `TestDevelopmentEffectType`, `TestDevelopmentBuild`, `TestCityDemonOccupation`

## Training readiness

| Signal | Ready? | Rationale |
|---|---|---|
| Production bonuses in rewards/obs | Yes | Affects `ProductionRules`; featurizer includes resources |
| VP effects in rewards | Yes | VP delta reward in `MacroTrainingEnv` |
| Hero action/spawn effects | Yes | Budget and board state mutate deterministically |
| Trade bonus effects | **Stub** | Cards exist; trade rules unchanged — document only |
| Wizard access effects | **Stub** | No macro wizard piece or encounter gate yet |
| Draft bonus effects | **Stub** | Draft loop fixed at 8 picks/age |

**Recommendation:** Include built-card production/VP/hero effects in macro training telemetry; exclude or zero-weight stub effect categories until rules land.

## Related docs

- [DEVELOPMENT_CARD_CATALOG.md](DEVELOPMENT_CARD_CATALOG.md)
- [TRAINING_READINESS_GATE.md](TRAINING_READINESS_GATE.md)
