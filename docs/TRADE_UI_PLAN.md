# Trade UI Plan (Run I — I7)

**Rules base:** Verified Run H — offer/accept, dedup, expiry after full player cycle.

---

## Offer builder

- Partner selector (3 opponents).
- Give / receive resource dropdowns, amounts 1–3.
- Legality from `LegalActionQuery` for `TRADE_OFFER`.
- Disable duplicate signature same turn (RC-G-004).

---

## Pending offers inbox

- List `state.pending_trade_offers` addressed to active player.
- Show offerer, terms, offer age (turns remaining = `player_count - turn_age`).
- Accept / reject buttons → `TRADE_ACCEPT` / `TRADE_REJECT`.
- Remove row on `TradeOfferExpiredEvent`.

---

## Trade bonus display

- When acceptor has built `trade_bonus` cards, show "+N bonus" on accept preview (Run H).

---

## Audit view

- All pending offers table for all players.
- Event log filter: `TradeOfferMadeEvent`, `TradeAcceptedEvent`, `TradeRejectedEvent`, `TradeOfferExpiredEvent`.

---

## Must never

- Transfer resources without `TradeOfferRules.apply_accept`.
- Mutate `pending_trade_offers` from UI scripts.

---

## Tests

- `TestRuleContractTrading` (core)
- Future UI: inbox clears on expiry event consumption
