# 3D Interaction Model (Run I — I5)

Per interaction: input, feedback, session API, events, tests, deferred.

---

## Hex select (inspect)

| | |
|---|---|
| Input | Left click ray → hex |
| Feedback | Highlight + tooltip (resources, demons) |
| API | Read `BoardWorldMapper` snapshot only |
| Events | — |
| Tests | Ray pick → coord contract |
| Deferred | Impl I3 |

---

## Hex select (build city)

| | |
|---|---|
| Input | Click vertex / city site mode |
| Feedback | Green/red affordance from legal mask |
| API | `submit_human_action(BUILD_CITY)` |
| Events | `CityBuiltEvent` |
| Tests | Illegal site rejected; no direct state patch |
| Deferred | M22 / Impl I3 |

---

## Hero move

| | |
|---|---|
| Input | Select hero → click destination node |
| Feedback | Path preview, budget counter |
| API | `MOVE_HERO` |
| Events | Move, contact resolution, `HeroClashEvent` |
| Tests | Integration with legal mask |
| Deferred | Impl I3 |

---

## Trade

| | |
|---|---|
| Input | HUD offer builder (not world pick) |
| API | `TRADE_OFFER` / `TRADE_ACCEPT` |
| Events | Trade* + `TradeOfferExpiredEvent` |
| Tests | [TRADE_UI_PLAN.md](TRADE_UI_PLAN.md) |
| Deferred | Impl I4 |

---

## Draft pick

| | |
|---|---|
| Input | Card click or keyboard (existing) |
| API | `DRAFT_PICK` |
| Events | `DraftCardPickedEvent`, peek events |
| Tests | `TestHumanMacro2dMode` pattern |
| Deferred | Rich card UI — Impl I4 |

---

## Bot advance (spectator)

| | |
|---|---|
| Input | Enter / N (existing wizard-world) |
| API | `BotGameSession.advance_one_player_turn` |
| Tests | `TestRunModes` |
| Status | Verified |

---

## Encounter → tactical (future)

| | |
|---|---|
| Input | Prompt when wizard marker enters radius |
| API | Pause macro; `SpellCombatSession.start_duel` |
| Deferred | Not in v1 macro loop — GD-001 |
