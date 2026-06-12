#!/usr/bin/env python3
"""Scan donor_projects image assets and emit docs/donor_asset_reuse_matrix.csv."""

from __future__ import annotations

import argparse
import csv
import os
import sys
from pathlib import Path

try:
    from PIL import Image  # type: ignore

    HAS_PILLOW = True
except ImportError:
    HAS_PILLOW = False

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp"}

OWNERSHIP = (
    "Created by Joe in earlier donor project; okay for internal reuse, still track source path."
)

CSV_COLUMNS = [
    "source_project",
    "source_path",
    "asset_type",
    "dimensions",
    "has_alpha",
    "file_size",
    "visual_category",
    "technical_quality",
    "style_fit",
    "ownership_status",
    "reuse_recommendation",
    "suggested_target_path",
    "notes",
]


def categorize(rel_path: str) -> str:
    lower = rel_path.lower()
    if "/spells/icons/" in lower:
        return "spell_icons"
    if any(x in lower for x in ("/wizard", "/mage", "/warlock", "/druid", "/cleric")) and (
        "/sprites/" in lower or "/rotation/" in lower or "/walk/" in lower or "/idle/" in lower
    ):
        if "/rotation/" in lower or "/walk/" in lower or "/front" in lower or "/back" in lower:
            return "directional_character_sprites"
        return "single_view_character_sprites"
    if "/enemynpc/" in lower or "/npc/" in lower:
        return "enemy_portraits"
    if "/hexagons/" in lower or "/forest/" in lower:
        if "cairn" in lower or "tree" in lower or "grass" in lower:
            return "tree_sprites"
        return "hex_floor_textures"
    if "/panorama/" in lower:
        return "panoramas"
    if "/menu/" in lower or "title" in lower:
        return "menu/title_images"
    if "/world/art/floors/" in lower or "/floors/" in lower:
        return "terrain_textures"
    if "/world/art/" in lower:
        return "props"
    if "/sound/" in lower or lower.endswith((".wav", ".ogg", ".mp3")):
        return "sfx"
    return "other"


def suggest_target(project: str, rel_path: str, category: str) -> tuple[str, str]:
    """Return (reuse_recommendation, suggested_target_path)."""
    lower = rel_path.lower()
    base = f"donor_projects/{project}/"

    if category == "spell_icons":
        name = Path(rel_path).stem.lower()
        if any(
            k in name
            for k in ("fireball", "silence", "shield", "quicken", "focus", "regen", "blight", "aid")
        ):
            return (
                "Use in Run J",
                "godot_game/assets/billboards/ui_status/",
            )
        return ("Use later", "godot_game/assets/billboards/ui_status/")

    if category == "single_view_character_sprites":
        if "wizard" in lower or "mage" in lower:
            return ("Use in Run J", "godot_game/assets/billboards/wizards/")
        if any(c in lower for c in ("apostate", "blight", "demon", "warlock")):
            return ("Use in Run J", "godot_game/assets/billboards/demons/")
        if any(c in lower for c in ("cleric", "druid", "apprentice", "hero", "archon")):
            return ("Use in Run J", "godot_game/assets/billboards/heroes/")
        return ("Use later", "godot_game/assets/billboards/heroes/")

    if category == "directional_character_sprites":
        return ("Use later", "godot_game/assets/billboards/heroes/")

    if category == "tree_sprites":
        if any(x in Path(rel_path).name for x in ("T1_C1", "T1_C2", "T2_C1", "T2_C3")):
            return ("Use in Run J", "godot_game/assets/billboards/props/")
        return ("Use later", "godot_game/assets/billboards/props/")

    if category == "terrain_textures":
        return ("Needs manual review", "godot_game/assets/terrain/")

    if category == "panoramas":
        return ("Reference only", "godot_game/assets/environment/")

    if category == "menu/title_images":
        return ("Reference only", "")

    if category == "enemy_portraits":
        return ("Use later", "godot_game/assets/billboards/demons/")

    return ("Needs manual review", "")


def image_info(path: Path) -> tuple[str, str]:
    if not HAS_PILLOW:
        return ("unknown", "unknown")
    try:
        with Image.open(path) as img:
            w, h = img.size
            has_alpha = "yes" if img.mode in ("RGBA", "LA", "PA") else "no"
            return (f"{w}x{h}", has_alpha)
    except OSError:
        return ("unreadable", "unknown")


def scan_donor_root(donor_root: Path, project_name: str) -> list[dict]:
    rows: list[dict] = []
    if not donor_root.is_dir():
        return rows

    for path in sorted(donor_root.rglob("*")):
        if not path.is_file():
            continue
        ext = path.suffix.lower()
        if ext not in IMAGE_EXTENSIONS:
            continue
        rel = str(path.relative_to(donor_root.parent)).replace("\\", "/")
        category = categorize(rel)
        reuse, target = suggest_target(project_name, rel, category)
        dims, alpha = image_info(path)
        size = path.stat().st_size

        rows.append(
            {
                "source_project": project_name,
                "source_path": rel,
                "asset_type": ext.lstrip("."),
                "dimensions": dims,
                "has_alpha": alpha,
                "file_size": str(size),
                "visual_category": category,
                "technical_quality": "good" if size > 1024 else "small",
                "style_fit": "high" if project_name == "dark_fantasy" else "medium",
                "ownership_status": OWNERSHIP,
                "reuse_recommendation": reuse,
                "suggested_target_path": target,
                "notes": "",
            }
        )
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit donor project image assets into donor_asset_reuse_matrix.csv"
    )
    parser.add_argument(
        "--donor-root",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "donor_projects",
        help="Root folder containing donor subprojects",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "docs" / "donor_asset_reuse_matrix.csv",
        help="Output CSV path",
    )
    parser.add_argument(
        "--projects",
        nargs="*",
        default=["dark_fantasy", "KF_wizard_game"],
        help="Donor subproject folder names to scan",
    )
    args = parser.parse_args()

    all_rows: list[dict] = []
    for project in args.projects:
        project_path = args.donor_root / project
        all_rows.extend(scan_donor_root(project_path, project))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS)
        writer.writeheader()
        writer.writerows(all_rows)

    pillow_note = "Pillow available" if HAS_PILLOW else "Pillow unavailable; dimensions/alpha unknown"
    print(f"Wrote {len(all_rows)} rows to {args.output} ({pillow_note})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
