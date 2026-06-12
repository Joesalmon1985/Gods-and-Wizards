# Micro Combat Presentation Plan (Run I — I8)

**Scope:** Isolated `SpellCombatSession` — not macro loop.

---

## Arena layout

- Flat duel plane; two combatant billboards facing.
- HP / mana bars above each sprite.
- Central timeline strip for recent events.

---

## Status icons (Run H implemented only)

| Status | Icon treatment |
|---|---|
| DoT | Green drip / poison |
| Barrier | Blue hex shield with absorb count |
| Shield | Silver chevron (charges) |
| Silence | Muted mouth / grey cast bar |
| Buff / debuff | Up/down arrows on cast/CD/regen |

Do **not** show icons for deferred effects (`is_counter_spell`, `dual_cast`).

---

## Spell picker

- Grid of legal spells from session + pass action.
- Cooldown overlay from `observe()["cooldowns_by_spell_id"]`.
- Silence disables entire grid except pass.

---

## Timeline / replay

- `SpellCombatTimelinePresenter` renders event type + spell_id.
- Replay mode auto-steps policy; play mode waits for pick.

---

## Training overlay

- Optional panel: step index, reward components, policy name.
- Consumes same observe dict as export — no separate rules path.

---

## Tests

- `TestPlayableMicroCombat`, `TestSpellEffectFidelity`, `TestSpellCombatTimelinePresenter`
