from __future__ import annotations

import json
from pathlib import Path

import checkpoint_metadata
import pytest


def test_save_and_load_metadata_roundtrip(tmp_path: Path) -> None:
    weights = tmp_path / "policy.json"
    weights.write_text("{}", encoding="utf-8")
    metadata = checkpoint_metadata.new_metadata(
        run_id="test_run",
        policy_kind="macro_bc",
        schema_version="macro_training_v2",
        rules_version="run_g_v2",
        training_seed=7,
        source_csv=str(tmp_path / "data.csv"),
        feature_dim=16,
        output_size=8,
        hidden_size=8,
        epochs=1,
        learning_rate=1e-3,
        batch_size=2,
        final_loss=0.5,
        final_accuracy=0.75,
        weights_json_path=str(weights),
        featurizer_version="macro_feature_v1",
    )
    sidecar = checkpoint_metadata.save_metadata(metadata, weights)
    loaded = checkpoint_metadata.load_metadata(weights)
    assert sidecar.exists()
    assert loaded.run_id == "test_run"
    assert loaded.policy_kind == "macro_bc"
    assert loaded.schema_version == "macro_training_v2"
    for field in checkpoint_metadata.REQUIRED_FIELDS:
        assert str(getattr(loaded, field)).strip()


def test_metadata_validation_rejects_unknown_policy_kind(tmp_path: Path) -> None:
    metadata = checkpoint_metadata.CheckpointMetadata(
        run_id="bad",
        policy_kind="unknown",
        schema_version="macro_training_v2",
        rules_version="run_g_v2",
        created_at="2026-06-13T00:00:00+00:00",
        training_seed=1,
        source_csv="data.csv",
        feature_dim=16,
        output_size=8,
        hidden_size=8,
        epochs=1,
        learning_rate=1e-3,
        batch_size=2,
        final_loss=0.0,
        final_accuracy=0.0,
        weights_json_path=str(tmp_path / "w.json"),
        featurizer_version="macro_feature_v1",
        framework="pytorch",
    )
    with pytest.raises(ValueError):
        metadata.validate()
