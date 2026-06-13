from __future__ import annotations

from pathlib import Path

import pytest

from etl.macro_v2_loader import load_macro_v2_csv
from etl.featurizers import MACRO_FEATURE_SIZE


FIXTURE = Path(__file__).parent / "fixtures" / "macro_training_v2_tiny.csv"


def test_load_macro_v2_csv_shapes() -> None:
    dataset = load_macro_v2_csv(FIXTURE)
    assert len(dataset) == 3
    assert dataset.features.shape == (3, MACRO_FEATURE_SIZE)
    assert dataset.targets.shape == (3,)
    assert dataset.masks.shape == (3, 64)
    assert dataset.metadata["schema_version"] == "macro_training_v2"
    assert dataset.metadata["action_space_layout_key"] == "actions_8"


def test_macro_targets_respect_legal_mask() -> None:
    dataset = load_macro_v2_csv(FIXTURE)
    for i in range(len(dataset)):
        target = int(dataset.targets[i].item())
        assert float(dataset.masks[i, target].item()) > 0.0


def test_macro_rejects_wrong_schema(tmp_path: Path) -> None:
    bad_csv = tmp_path / "bad.csv"
    bad_csv.write_text("telemetry_schema_version\nmacro_training_v1\n", encoding="utf-8")
    with pytest.raises(ValueError):
        load_macro_v2_csv(bad_csv)
