# Drafting & Card Economy UI Plan (Run I — I6)

**Catalogue:** 96 cards, 32 per age ([DEVELOPMENT_CARD_CATALOG.md](DEVELOPMENT_CARD_CATALOG.md))

---

## Presentation requirements

- Show card name, age, cost icons, VP/effect summary from `DevelopmentCatalog`.
- Hand panel: cards in `player.development_hand`.
- City slots: up to 3 built IDs per city with purge indicator if occupied.

---

## Affordability

- Grey out unaffordable `BUILD_DEVELOPMENT` actions (resources after Run H discounts via `production_discount`).
- Show discounted cost when `DevelopmentEffectEngine.apply_build_cost_discount` applies.

---

## Demon-occupied block (verified Run H)

- Cannot play new development onto city vertex with demons > 0.
- UI: red slot overlay + tooltip; no submit button.
- Existing built cards remain until round purge.

---

## Draft UX

| State | UI |
|---|---|
| `awaiting_draft_step` | Modal or side panel with pack cards |
| Pick legal | Highlight selectable cards from pack |
| Bot waiting | Show pending picks per player |
| `draft_bonus` peek | Banner with peeked card (`DraftPackPeekEvent`) |

Current 2D play: draft picks appear in keyboard action list — replace with card grid in Impl I4.

**3D wizard-world (Run J):** no draft pack or hand UI — drafting is AI/bot gods only in wizard mode. Phase 5 of [RUN_J_PLANNING_DARK_FANTASY_REUSE.md](RUN_J_PLANNING_DARK_FANTASY_REUSE.md) covers read-only built-development indicators on city vertices via `StrategicDevelopmentViewModel` (e.g. granary, mine once built). Human draft UX remains 2D (Impl I4).

---

## Audit visibility

Audit mode shows all players' packs and hands for debugging (read-only).

---

## Tests

- `TestStrategicDraftViewModel`, `TestStrategicDevelopmentViewModel`
- Future: scene test for card grid → `DRAFT_PICK` submission boundary
