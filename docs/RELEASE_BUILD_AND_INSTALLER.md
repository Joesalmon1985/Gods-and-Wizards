# Windows release build and installer prototype

**Status:** Prototype documentation and export script (Run E11). Build outputs remain untracked.

## Prerequisites

- Godot 4.x editor installed locally (same version as `godot_game/project.godot`).
- Windows 10/11 with PowerShell.
- Optional: WiX or Inno Setup for a future installer pass (not automated here).

## Export preset

1. Open `godot_game/` in the Godot editor.
2. **Project → Export…**
3. Add a **Windows Desktop** preset if missing.
4. Set executable name to `GodsAndWizards.exe`.
5. Enable **Embed PCK** for a single-file prototype build.
6. Save export settings to `godot_game/export_presets.cfg` (local only unless explicitly committed).

## Headless export script

From the repository root:

```powershell
.\scripts\Export-WindowsBuild.ps1
```

The script:

- Verifies the Godot binary via `scripts/Invoke-GodotHeadless.ps1`.
- Runs `--export-release "Windows Desktop"` when `export_presets.cfg` exists.
- Writes artifacts under `build/windows/` (gitignored).

## Manual verification checklist

- [ ] Launch `build/windows/GodsAndWizards.exe` on a clean Windows profile.
- [ ] Open **2D One-God Play Mode** (`strategic_play_2d_mode.tscn` as main scene override).
- [ ] Open **Wizard World Mode** and confirm WASD / Q/E / camera toggle.
- [ ] Run the headless test suite before tagging a release candidate.

## Installer prototype (deferred)

A signed installer is out of scope for Run E. Recommended next step: Inno Setup script wrapping `build/windows/` with Start Menu shortcut and uninstall entry.
