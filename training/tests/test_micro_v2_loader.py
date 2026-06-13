from __future__ import annotations

from pathlib import Path

import pytest

from etl.micro_v2_loader import load_micro_v2_csv
from etl.featurizers import MICRO_FEATURE_SIZE


FIXTURE = Path(__file__).parent / "fixtures" / "micro_combat_v2_tiny.csv"


def test_load_micro_v2_csv_shapes() -> None:
    dataset = load_micro_v2_csv(FIXTURE)
    assert len(dataset) == 3
    assert dataset.features.shape == (3, MICRO_FEATURE_SIZE)
    assert dataset.targets.shape == (3,)
    assert dataset.masks.shape == (3, 6)
    assert dataset.metadata["schema_version"] == "micro_combat_v2"
    assert dataset.metadata["spell_catalog_version"] == "spell_catalog_v1"


def test_micro_targets_map_to_loadout_index() -> None:
    dataset = load_micro_v2_csv(FIXTURE)
    expected = [0, 0, 1]
    assert dataset.targets.tolist() == expected


def test_micro_rejects_wrong_schema(tmp_path: Path) -> None:
    bad_csv = tmp_path / "bad.csv"
    bad_csv.write_text("telemetry_schema_version\nmicro_combat_v1\n", encoding="utf-8")
    with pytest.raises(ValueError):
        load_micro_v2_csv(bad_csv)
