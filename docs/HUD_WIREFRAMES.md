# HUD Wireframes (Run I — I2)

ASCII wireframes for twelve HUD surfaces. **Must never mutate** `GameState` directly — submit via session APIs noted.

---

## 1. Top bar — turn context

```text
┌─────────────────────────────────────────────────────────────────┐
│ Dana (God) │ Round 3 │ Turn 11 │ Phase: ACTIVE_PLAYER │ Age II │
└─────────────────────────────────────────────────────────────────┘
```

Source: `StrategicAuditViewModel` / `GameStateSummary`  
Submit: — (read-only)

---

## 2. Victory and loss

```text
┌──────────────────┐
│ VP: 8 / 21       │
│ Breach: 4 / 10   │
└──────────────────┘
```

Source: `player.victory_points`, `state.breach_count`, `BalanceConfig`  
Submit: —

---

## 3. Infection / underworld

```text
┌─────────────────────────────┐
│ Infection rate: 3           │
│ Demons on board: 47         │
│ Last: Underworld Surge (R3) │
└─────────────────────────────┘
```

Source: `state.infection_rate`, demon counts, `UnderworldSurgeEvent` in log  
Submit: —

---

## 4. Resources

```text
┌─────────────────────────────────────────────┐
│ W:4  B:2  H:1  S:0  O:3                     │
└─────────────────────────────────────────────┘
```

Source: active `Player.resources`  
Submit: —

---

## 5. Hero budgets

```text
┌──────────────────────────────┐
│ Hero #0: 2 actions remaining │
│ Hero #1: 4 actions remaining │
└──────────────────────────────┘
```

Source: `state.hero_actions_remaining`  
Submit: `MOVE_HERO` via `submit_human_action`

---

## 6. City / development slots

```text
┌─────────────────────────────────────┐
│ City @ (0,0): [monument][empty][—]  │
│ Occupied: NO │ Hand: 2 cards        │
└─────────────────────────────────────┘
```

Source: `StrategicDevelopmentViewModel`  
Submit: `BUILD_DEVELOPMENT` (blocked if demons > 0 — verified Run H)

---

## 7. Draft panel

```text
┌──────────────── DRAFT (Age II, pick 3/8) ────────────────┐
│ Pack: [card_a] [card_b] [card_c] ...                    │
│ Pending: P0 ✓  P1 ·  P2 ·  P3 ·                        │
│ Peek (if draft_bonus): top of next pack = [card_x]      │
└─────────────────────────────────────────────────────────┘
```

Source: `StrategicDraftViewModel`, `DraftPackPeekEvent`  
Submit: `DRAFT_PICK` via session

---

## 8. Trade — offer builder

```text
┌────────── Offer ──────────┐
│ Give: 1 WOOD → Get: 1 BRICK│
│ To: Player 2              │
│ [Submit Offer]            │
└───────────────────────────┘
```

Source: legal `TRADE_OFFER` mask  
Submit: `TRADE_OFFER`

---

## 9. Trade — inbox

```text
┌──────── Pending offers ────────┐
│ #3 from P1: 1 BRICK → 1 WOOD   │
│   [Accept] [Reject]            │
│ (expires after offerer cycle)  │
└────────────────────────────────┘
```

Source: `state.pending_trade_offers`, `TradeOfferExpiredEvent`  
Submit: `TRADE_ACCEPT` / `TRADE_REJECT`

---

## 10. Legal actions drawer

```text
┌ Legal (42) ────────────────┐
│ > BUILD_CITY @ vertex …    │
│   BUILD_ROAD @ edge …      │
│   END_TURN                 │
└────────────────────────────┘
```

Source: `LegalActionQuery.get_view`  
Submit: selected `GameAction`

---

## 11. Event ticker

```text
┌ Events ────────────────────────────────┐
│ R3: Production +1 WHEAT @ city         │
│ R3: DemonSpread → (1,0)                │
│ R3: HeroClash @ (2,-1)                 │
└────────────────────────────────────────┘
```

Source: `session.events` / `EventLog`  
Submit: —

---

## 12. Training overlay (debug tier)

```text
┌ Training ──────────────────┐
│ seed:42 step:88 reward:0.5 │
│ legal_mask: 1248 bits set  │
└────────────────────────────┘
```

Source: `MacroTrainingEnv.observe` / export row  
Submit: — (separate debug mode)
