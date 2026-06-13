"""Load macro_training_v2 CSV exports into PyTorch-ready tensors."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
import torch

from etl.featurizers import (
    COMPACT_MACRO_ACTION_SLOTS,
    MACRO_FEATURE_SIZE,
    MACRO_FEATURIZER_VERSION,
    featurize_macro_observation,
)

SCHEMA_VERSION = "macro_training_v2"
LAYOUT_VERSION = "compact_global_index_v1"


@dataclass
class MacroV2Dataset:
    features: torch.Tensor
    targets: torch.Tensor
    masks: torch.Tensor
    rewards: torch.Tensor
    terminal: torch.Tensor
    metadata: dict[str, Any]

    def __len__(self) -> int:
        return int(self.features.shape[0])


def _parse_json_column(value: Any, default: Any) -> Any:
    if value is None or (isinstance(value, float) and np.isnan(value)):
        return default
    if isinstance(value, (list, dict)):
        return value
    text = str(value).strip()
    if not text:
        return default
    return json.loads(text)


def _compact_global_indices(legal_ids: list[Any], mask_bits: list[Any]) -> list[int]:
    indices: list[int] = []
    for i, bit in enumerate(mask_bits):
        if i >= len(legal_ids):
            break
        if bool(bit):
            indices.append(i)
    return indices[:COMPACT_MACRO_ACTION_SLOTS]


def _macro_target_compact(legal_ids: list[Any], mask_bits: list[Any], selected_action_id: int) -> int:
    compact_indices = _compact_global_indices(legal_ids, mask_bits)
    if not compact_indices:
        return 0
    for compact_idx, global_idx in enumerate(compact_indices):
        if int(legal_ids[global_idx]) == int(selected_action_id):
            return compact_idx
    return 0


def load_macro_v2_csv(
    csv_path: str | Path,
    *,
    output_size: int | None = None,
    max_rows: int | None = None,
) -> MacroV2Dataset:
    path = Path(csv_path)
    frame = pd.read_csv(path)
    if max_rows is not None:
        frame = frame.head(max_rows)

    if frame.empty:
        raise ValueError(f"macro CSV has no rows: {path}")

    schema = str(frame.iloc[0]["telemetry_schema_version"])
    if schema != SCHEMA_VERSION:
        raise ValueError(f"expected schema {SCHEMA_VERSION}, got {schema}")

    resolved_output = output_size or COMPACT_MACRO_ACTION_SLOTS
    if resolved_output != COMPACT_MACRO_ACTION_SLOTS:
        raise ValueError(
            f"macro policy head must be {COMPACT_MACRO_ACTION_SLOTS} compact slots, got {resolved_output}"
        )

    features: list[np.ndarray] = []
    targets: list[int] = []
    masks: list[np.ndarray] = []
    rewards: list[float] = []
    terminal: list[float] = []

    for _, row in frame.iterrows():
        obs = _parse_json_column(row["pre_observation_json"], {})
        legal_ids = _parse_json_column(row["legal_action_ids_json"], [])
        mask_bits = _parse_json_column(row["legal_mask_json"], [])
        compact_indices = _compact_global_indices(legal_ids, mask_bits)
        compact_mask = [1.0] * len(compact_indices)
        compact_mask.extend([0.0] * (COMPACT_MACRO_ACTION_SLOTS - len(compact_mask)))

        feature = featurize_macro_observation(obs)
        if feature.shape[0] != MACRO_FEATURE_SIZE:
            raise ValueError(f"macro feature dim mismatch: {feature.shape[0]} != {MACRO_FEATURE_SIZE}")

        target = _macro_target_compact(legal_ids, mask_bits, int(row["selected_action_id"]))
        mask_arr = np.asarray(compact_mask, dtype=np.float32)
        if mask_arr[target] <= 0.0:
            legal_indices = np.flatnonzero(mask_arr > 0.0)
            if legal_indices.size == 0:
                raise ValueError("row has empty compact legal mask")
            target = int(legal_indices[0])

        features.append(feature)
        targets.append(target)
        masks.append(mask_arr)
        rewards.append(float(row.get("reward", 0.0)))
        terminal.append(1.0 if str(row.get("terminal", "false")).lower() == "true" else 0.0)

    feature_tensor = torch.from_numpy(np.stack(features))
    target_tensor = torch.tensor(targets, dtype=torch.long)
    mask_tensor = torch.from_numpy(np.stack(masks))
    reward_tensor = torch.tensor(rewards, dtype=torch.float32)
    terminal_tensor = torch.tensor(terminal, dtype=torch.float32)

    layout_key = str(frame.iloc[0].get("action_space_layout_key", ""))
    rules_version = str(frame.iloc[0].get("rules_version", ""))

    return MacroV2Dataset(
        features=feature_tensor,
        targets=target_tensor,
        masks=mask_tensor,
        rewards=reward_tensor,
        terminal=terminal_tensor,
        metadata={
            "schema_version": SCHEMA_VERSION,
            "featurizer_version": MACRO_FEATURIZER_VERSION,
            "feature_dim": MACRO_FEATURE_SIZE,
            "output_size": resolved_output,
            "sample_count": len(frame),
            "source_csv": str(path.resolve()),
            "action_space_layout_key": layout_key,
            "rules_version": rules_version,
            "legal_mask_layout_version": LAYOUT_VERSION,
        },
    )
