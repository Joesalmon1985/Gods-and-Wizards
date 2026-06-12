# UI / 3D Testing Strategy (Run I — I13)

---

## Contract test categories

### Scene launch

- Each `run_modes/*.tscn` instantiates without error headless or offscreen.
- Missing today: `wizard_world_mode`, `strategic_2d_mode` — add in Impl I1.

### View-model boundaries

- VMs expose read-only snapshots; no `GameState` writes.
- Covered: `TestRuleContractUiBoundary`, strategic VM tests.

### Submission boundaries

- Play controllers call `BotGameSession.submit_human_action` / `submit_human_draft_action` only.
- Covered: `TestHumanMacro2dMode`, architecture grep tests.

### Timeline / training consumption

- `SpellCombatTimelinePresenter` tolerates empty and populated timelines.
- Export row shape matches contract docs.

### Billboard metadata (future)

- Parse `manifest.json`; all paths exist under `assets/billboards/`.

---

## Recommended new tests (Impl I1+)

| Test | Proves |
|---|---|
| `TestHudShellViewModel` | Aggregates audit VM fields |
| `TestHexPickMapsToLegalAction` | Pick → action id, illegal rejected |
| `TestTradeInboxExpiryDisplay` | UI model removes expired offer id |
| `TestWizardWorldSceneLaunch` | F5 scene loads |

---

## CI integration

- Full suite remains gate; UI tests run in integration category.
- No screenshot tests in v1 — deterministic VM assertions only.

---

## Prohibited

- UI tests that mutate `GameState` directly to “fix” setup
- Skipping architecture tests for convenience
