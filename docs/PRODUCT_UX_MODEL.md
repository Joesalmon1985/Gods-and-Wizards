# Product UX Model (Run I — I1)

**Date:** 2026-06-12  
**Authority:** Verified Run H mechanics only ([PRODUCT_SURFACE_AUDIT.md](PRODUCT_SURFACE_AUDIT.md))

---

## Launch and default experience

1. **Developer default (today):** F5 → `wizard_world_mode` (3D spectator prototype).
2. **Near-term human play:** `strategic_play_2d_mode` — keyboard legal-action picker, one human + three bots.
3. **Long-term product default (planned):** unified 3D macro shell with shared HUD + embodied wizard layer (Impl I1–I7).

---

## Mode map

```text
[App launch]
    ├─ Player macro (future): 3D board + HUD → BotGameSession.submit_human_action
    ├─ Dev 2D play: strategic_play_2d_mode (keyboard)
    ├─ Dev audit: strategic_audit_2d_mode (step/batch bots)
    ├─ Tactical lab: spell_combat_play_mode / replay_mode (isolated)
    └─ Training/debug: headless export/eval scripts (no scene)
```

---

## Player vs dev vs audit

| Surface | Audience | Input | Mutates state? |
|---|---|---|---|
| 2D play mode | Designer / dev playtest | Keyboard list picker | Via session API only |
| 3D wizard-world | Spectator / vertical slice | Enter/N advance bots | Bot advance only |
| Audit 2D | Rules debugging | Step/batch | Bot advance only |
| Training dashboards | ML / balance | CLI | Headless only |

---

## Macro loop UX (verified rules)

Per active player turn:

1. **Turn start → PRODUCTION** (active player's cities only; occupied = 0).
2. **Main phase** — unlimited legal builds/trades/hero moves until `END_TURN`.
3. **END_TURN** — infection draws, optional Underworld Surge, trade offer age check.
4. **Round wrap** — draft step (keyboard pick in 2D play); age advance bumps infection rate.

Trade: offer on your turn; target accepts on theirs; offers expire after full player cycle.

Combat boundary: macro hero contact = instant demon clear / hero clash. **No** `SpellCombatSession` in macro loop.

---

## Encounter / tactical boundary (planned)

3D human encounters may pause macro and open `SpellCombatSession` — **not implemented** in macro economy. Product docs must not imply tactical combat affects production, draft, or VP unless explicitly integrated in a future milestone.

---

## Input roadmap

| Phase | Input |
|---|---|
| Now | Keyboard action list, ui_accept |
| Impl I2 | Shared HUD + focus model |
| Impl I3 | Hex pick → legal build/develop actions |
| Impl I5 | 3D ray pick + affordance highlights |
