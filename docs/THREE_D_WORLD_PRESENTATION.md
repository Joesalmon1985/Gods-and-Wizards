# 3D World Presentation Plan (Run I — I4)

---

## Visual direction

- **Low-poly hex board** — flat terrain tiles, slight elevation variance for readability.
- **Billboard sprites** — Doom-style agents for heroes, demons, cities, wizards (see [BILLBOARD_SPRITE_ASSET_PIPELINE.md](BILLBOARD_SPRITE_ASSET_PIPELINE.md)).
- **Readable scale** — board radius 3 fits in single camera frustum. Run J target: cosmetic wizard walk across ~5 hex centre spacings in ~180 s (see [RUN_J_PLANNING_DARK_FANTASY_REUSE.md](RUN_J_PLANNING_DARK_FANTASY_REUSE.md)); superseded the earlier ~0.3s/edge placeholder note.

---

## Camera modes

| Mode | Use | Controls |
|---|---|---|
| Strategic orbit | Default macro | Rotate/zoom around board center |
| Follow wizard | Wizard-world prototype | Follow cosmetic marker |
| Focus city | Build/develop (planned) | Snap to vertex |
| Tactical arena | Spell combat (isolated) | Fixed duel camera |

---

## Event VFX (cosmetic only)

| Event | VFX |
|---|---|
| DemonSpread | Red pulse on node |
| DemonsCleared | Brief flash + particle |
| HeroClash | Cross burst, both tokens fade |
| UnderworldSurge | Screen-edge vignette + shuffle SFX |
| Production | Resource icon float from hex |
| Breach | Global alarm tint |

VFX driven from event log; must not affect rules.

---

## Performance constraints

- Target: 60 FPS on mid-tier laptop, ≤500 draw calls for macro board.
- Instancing for repeated hex tiles; billboards as `Sprite3D` or custom quads.
- No per-frame legal-action recompute in visual layer.

---

## Current vs planned

| Item | Today | Planned |
|---|---|---|
| Terrain | `PlaneMesh` grid | Styled hex meshes + biome tints |
| Units | Colored boxes | Billboards |
| Wizard | Marker mesh | Embodied avatar (Impl I3) |
