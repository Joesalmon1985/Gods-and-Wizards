# UI Information Architecture (Run I — I3)

**Purpose:** Group macro, micro, and training data with source, view model, display, update trigger, visibility tier.

---

## Macro data groups

| Group | Source | View model | Display | Update trigger | Tier |
|---|---|---|---|---|---|
| Turn / phase | `GameState` | `StrategicAuditViewModel` | Top bar | Every action / END_TURN | Player |
| VP / breach | `Player`, `GameState` | Summary helpers | VP panel | City build, breach event | Player |
| Resources | `Player.resources` | Play mode summary | Resource strip | Production, trade, build | Player |
| Board topology | `HexBoard`, cities, roads | `BoardWorldMapper` | 2D/3D board | Build, spread | Player |
| Demons / infection | `GameState` demon map | Audit VM + events | Counters, tint | END_TURN spread | Player |
| Heroes | `state.heroes` | Audit VM | Tokens | MOVE_HERO, clash | Player |
| Legal actions | `LegalActionQuery` | Mask in VM | Action list | Any state change | Player / Dev |
| Events | `EventLog` | Audit VM | Ticker | Each applied action | Dev default |
| Draft | `draft_*` fields | `StrategicDraftViewModel` | Draft panel | Round wrap | Player |
| Developments | cities + hand | `StrategicDevelopmentViewModel` | Slot UI | Build, purge | Player |
| Trade offers | `pending_trade_offers` | Derived in play mode | Inbox | offer/accept/expiry | Player |
| Production | `ProductionPhaseEvent` | Event log | Ticker | Turn start | Dev |

---

## Micro (tactical) data groups

| Group | Source | View model | Display | Update trigger | Tier |
|---|---|---|---|---|---|
| Combatants | `SpellCombatSession` | observe dict | HP/mana bars | step | Player |
| Cooldowns | session observe | timeline presenter | Icons | step | Player |
| Statuses | `statuses` in observe | Planned icons | Buff/debuff | step | Player |
| Timeline | `session.timeline` | `SpellCombatTimelinePresenter` | Log / replay | step | Dev |

Only show status icons for effects in [MICRO_SPELL_EFFECT_FIDELITY_MATRIX.md](MICRO_SPELL_EFFECT_FIDELITY_MATRIX.md) § implemented.

---

## Training / debug data groups

| Group | Source | Display | Tier |
|---|---|---|---|
| Legal mask bits | `MacroTrainingEnv` | Hex dump / heatmap | Training |
| Reward components | telemetry CSV | Dashboard | Training |
| Export schema version | exporter header | Footer | Training |
| Baseline eval metrics | `TrainingEvaluationHarness` | Table | Training |

---

## Proposed shared HUD view-model layer

```text
HudShellViewModel
  ├─ from BotGameSession (macro modes)
  ├─ composes: TurnStrip, ResourceStrip, VPStrip, EventTicker
  └─ read-only; subscribes to session.events appended signal (future)
```

Implementation: Impl I1. Existing VMs remain; shell aggregates without duplicating rules logic.

---

## Tests needed (future)

- HUD VM field parity with `StrategicAuditViewModel`
- No `GameState` mutation from HUD assembly
- Trade expiry display when `TradeOfferExpiredEvent` fires
