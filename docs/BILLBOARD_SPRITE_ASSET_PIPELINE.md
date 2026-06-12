# Billboard Sprite Asset Pipeline (Run I — I10)

Doom-style billboards for 3D macro and tactical presentation.

---

## Folder structure (planned)

```text
godot_game/assets/billboards/
  heroes/
  demons/
  cities/
  wizards/
  ui_status/
  manifest.json
```

---

## Workflow

1. Generate source art (see [ASSET_PROMPT_LIBRARY.md](ASSET_PROMPT_LIBRARY.md)).
2. Export PNG 256×256 (transparent), consistent light from upper-left.
3. Drop in class folder; Godot import: Filter OFF, Mipmaps ON.
4. Register in `manifest.json`:

```json
{
  "id": "hero_default",
  "path": "heroes/hero_default.png",
  "anchor": "feet",
  "scale": 1.0
}
```

5. Loader maps entity type + state → billboard texture in `BoardStateVisualizer` (Impl I6).

---

## Placeholders

Until art exists: colored `Sprite3D` with label text from entity type.

---

## Metadata contract

- `id`, `path`, `anchor` (feet | center), `scale`, optional `team_tint`
- Tests: manifest parse, every id resolvable (Impl I6)

---

## Performance

- Share materials per atlas where possible.
- Max 64 unique billboards loaded for macro board.
