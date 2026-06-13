"""Checkpoint sidecar metadata for Run K PyTorch BC exports."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

METADATA_FILENAME_SUFFIX = ".meta.json"
REQUIRED_FIELDS = (
    "run_id",
    "policy_kind",
    "schema_version",
    "rules_version",
    "created_at",
    "training_seed",
    "source_csv",
    "feature_dim",
    "output_size",
    "hidden_size",
    "epochs",
    "learning_rate",
    "batch_size",
    "final_loss",
    "final_accuracy",
    "weights_json_path",
    "featurizer_version",
    "framework",
)


@dataclass
class CheckpointMetadata:
    run_id: str
    policy_kind: str
    schema_version: str
    rules_version: str
    created_at: str
    training_seed: int
    source_csv: str
    feature_dim: int
    output_size: int
    hidden_size: int
    epochs: int
    learning_rate: float
    batch_size: int
    final_loss: float
    final_accuracy: float
    weights_json_path: str
    featurizer_version: str
    framework: str = "pytorch"
    framework_version: str = ""
    git_commit: str = ""
    action_space_layout_key: str = ""
    spell_catalog_version: str = ""
    sample_count: int = 0
    eval_metrics: dict[str, Any] = field(default_factory=dict)
    extra: dict[str, Any] = field(default_factory=dict)

    def validate(self) -> None:
        payload = asdict(self)
        missing = [name for name in REQUIRED_FIELDS if not str(payload.get(name, "")).strip()]
        if missing:
            raise ValueError(f"checkpoint metadata missing required fields: {missing}")
        if self.policy_kind not in {"macro_bc", "micro_bc"}:
            raise ValueError(f"unsupported policy_kind: {self.policy_kind}")
        if self.schema_version not in {"macro_training_v2", "micro_combat_v2"}:
            raise ValueError(f"unsupported schema_version: {self.schema_version}")

    def to_dict(self) -> dict[str, Any]:
        data = asdict(self)
        if not data["extra"]:
            data.pop("extra")
        return data

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "CheckpointMetadata":
        known = {f.name for f in cls.__dataclass_fields__.values()}
        kwargs = {key: data[key] for key in known if key in data}
        extra = {key: value for key, value in data.items() if key not in known}
        if extra:
            kwargs["extra"] = extra
        return cls(**kwargs)


def metadata_path_for_weights(weights_json_path: str | Path) -> Path:
    path = Path(weights_json_path)
    return path.with_suffix(path.suffix + ".meta.json")


def save_metadata(metadata: CheckpointMetadata, weights_json_path: str | Path) -> Path:
    metadata.validate()
    metadata.weights_json_path = str(weights_json_path)
    out_path = metadata_path_for_weights(weights_json_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(metadata.to_dict(), indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return out_path


def load_metadata(weights_json_path: str | Path) -> CheckpointMetadata:
    meta_path = metadata_path_for_weights(weights_json_path)
    if not meta_path.exists():
        raise FileNotFoundError(f"metadata sidecar not found: {meta_path}")
    data = json.loads(meta_path.read_text(encoding="utf-8"))
    metadata = CheckpointMetadata.from_dict(data)
    metadata.validate()
    return metadata


def new_metadata(
    *,
    run_id: str,
    policy_kind: str,
    schema_version: str,
    rules_version: str,
    training_seed: int,
    source_csv: str,
    feature_dim: int,
    output_size: int,
    hidden_size: int,
    epochs: int,
    learning_rate: float,
    batch_size: int,
    final_loss: float,
    final_accuracy: float,
    weights_json_path: str,
    featurizer_version: str,
    framework_version: str = "",
    git_commit: str = "",
    action_space_layout_key: str = "",
    spell_catalog_version: str = "",
    sample_count: int = 0,
    eval_metrics: dict[str, Any] | None = None,
) -> CheckpointMetadata:
    return CheckpointMetadata(
        run_id=run_id,
        policy_kind=policy_kind,
        schema_version=schema_version,
        rules_version=rules_version,
        created_at=datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        training_seed=training_seed,
        source_csv=source_csv,
        feature_dim=feature_dim,
        output_size=output_size,
        hidden_size=hidden_size,
        epochs=epochs,
        learning_rate=learning_rate,
        batch_size=batch_size,
        final_loss=final_loss,
        final_accuracy=final_accuracy,
        weights_json_path=weights_json_path,
        featurizer_version=featurizer_version,
        framework_version=framework_version,
        git_commit=git_commit,
        action_space_layout_key=action_space_layout_key,
        spell_catalog_version=spell_catalog_version,
        sample_count=sample_count,
        eval_metrics=eval_metrics or {},
    )
