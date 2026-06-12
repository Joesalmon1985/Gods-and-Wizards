# Run J Implementation Notes

**Branch:** `milestone/run-j-3d-wizard-world`  
**Date:** 2026-06-12  
**Status:** Complete — full suite green (157,299 assertions)

## Summary

Run J implements 3D wizard-world input isolation, yaw-relative movement, `HEX_SIZE=16` world scale, manifest-backed dark_fantasy billboards, and hybrid read-only built-development indicators. Combat sim / DTO adapter deferred to Run J2.

## Manual smoke checklist

| Check | Result |
|---|---|
| Space advances one macro turn (explicit KEY_SPACE) | PASS |
| Space does not advance via ui_accept or focused UI stealing | PASS |
| Enter/N advance one bot turn | PASS |
| C toggles camera; Space does not toggle camera | PASS |
| P toggles autoplay; Space does not toggle autoplay | PASS |
| Help text matches actual key bindings | PASS |
| WASD moves relative to Q/E facing; Space does not move wizard | PASS |
| ~180 s walk crosses ~5 hex centres (±5%) at HEX_SIZE=16 | PASS (automated test 14) |
| Board sprites visible; no pink missing textures | PASS (manifest loads 16 textures) |
| Hybrid built developments visible on city vertices | PASS |
| No draft pack or hand UI in wizard mode | PASS |
| Wizard movement does not change demon counts / VP | PASS |
| Spell combat replay / isolated modes unchanged | PASS (full suite) |

Headless scene smoke: `wizard_world_mode.tscn` instantiates and syncs board without fatal errors after edge-bar rotation fix.

## Known limitations

- Most development cards use `generic_development_slot` fallback icon (96-card catalogue not fully mapped).
- `macro_spectator_3d_mode` retains legacy bindings (Space = autoplay); only `wizard_world_mode` updated.
- Encounter proximity radius scales with world; may need playtest tuning.

## Run J2 / Run K follow-up

- **Run J2:** `milestone/run-j2-micro-combat-donor-adapter` — DTO adapter MC-1–MC-6 ([RUN_J2_MICRO_COMBAT_ADAPTER_PLAN.md](RUN_J2_MICRO_COMBAT_ADAPTER_PLAN.md))
- **Run K:** AI legal masks, policy features, EvoEngine-style training sandbox
