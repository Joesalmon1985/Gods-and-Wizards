"""Load micro_combat_v2 CSV exports into PyTorch-ready tensors."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
import torch

from etl.featurizers import MICRO_FEATURE_SIZE, MICRO_FEATURIZER_VERSION, featurize_micro_observation

SCHEMA_VERSION = "micro_combat_v2"
DEFAULT_OUTPUT_SIZE = 16


@dataclass
class MicroV2Dataset:
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


def _micro_target_index(row: pd.Series, output_size: int) -> int:
    selected = str(row["selected_action"])
    loadout = _parse_json_column(row["loadout_spell_ids_json"], [])
    if selected in loadout:
        index = loadout.index(selected)
        if index < output_size:
            return index
    legal_ids = _parse_json_column(row["legal_spell_ids_json"], [])
    if selected in legal_ids:
        if selected in loadout:
            return loadout.index(selected)
        return legal_ids.index(selected)
    return 0


def load_micro_v2_csv(
    csv_path: str | Path,
    *,
    output_size: int | None = None,
    max_rows: int | None = None,
) -> MicroV2Dataset:
    path = Path(csv_path)
    frame = pd.read_csv(path)
    if max_rows is not None:
        frame = frame.head(max_rows)

    if frame.empty:
        raise ValueError(f"micro CSV has no rows: {path}")

    schema = str(frame.iloc[0]["telemetry_schema_version"])
    if schema != SCHEMA_VERSION:
        raise ValueError(f"expected schema {SCHEMA_VERSION}, got {schema}")

    mask_lengths = [
        len(_parse_json_column(row["legal_mask_json"], []))
        for _, row in frame.iterrows()
    ]
    inferred_output = max(mask_lengths) if mask_lengths else DEFAULT_OUTPUT_SIZE
    resolved_output = output_size or inferred_output

    features: list[np.ndarray] = []
    targets: list[int] = []
    masks: list[np.ndarray] = []
    rewards: list[float] = []
    terminal: list[float] = []
    skipped_pass_only = 0

    for _, row in frame.iterrows():
        obs = _parse_json_column(row["pre_observation_json"], {})
        if "legal_spell_count" not in obs:
            obs["legal_spell_count"] = len(_parse_json_column(row["legal_spell_ids_json"], []))

        mask_bits = _parse_json_column(row["legal_mask_json"], [])
        if len(mask_bits) < resolved_output:
            mask_bits = mask_bits + [0] * (resolved_output - len(mask_bits))
        elif len(mask_bits) > resolved_output:
            mask_bits = mask_bits[:resolved_output]

        mask_arr = np.asarray(mask_bits, dtype=np.float32)
        legal_indices = np.flatnonzero(mask_arr > 0.0)
        if legal_indices.size == 0:
            skipped_pass_only += 1
            continue

        feature = featurize_micro_observation(obs)
        if feature.shape[0] != MICRO_FEATURE_SIZE:
            raise ValueError(f"micro feature dim mismatch: {feature.shape[0]} != {MICRO_FEATURE_SIZE}")

        target = _micro_target_index(row, resolved_output)
        if mask_arr[target] <= 0.0:
            target = int(legal_indices[0])

        features.append(feature)
        targets.append(target)
        masks.append(mask_arr)
        rewards.append(float(row.get("reward", 0.0)))
        terminal.append(1.0 if str(row.get("terminal", "false")).lower() == "true" else 0.0)

    if not features:
        raise ValueError(f"micro CSV has no trainable rows after filtering pass-only steps: {path}")

    feature_tensor = torch.from_numpy(np.stack(features))
    target_tensor = torch.tensor(targets, dtype=torch.long)
    mask_tensor = torch.from_numpy(np.stack(masks))
    reward_tensor = torch.tensor(rewards, dtype=torch.float32)
    terminal_tensor = torch.tensor(terminal, dtype=torch.float32)

    return MicroV2Dataset(
        features=feature_tensor,
        targets=target_tensor,
        masks=mask_tensor,
        rewards=reward_tensor,
        terminal=terminal_tensor,
        metadata={
            "schema_version": SCHEMA_VERSION,
            "featurizer_version": MICRO_FEATURIZER_VERSION,
            "feature_dim": MICRO_FEATURE_SIZE,
            "output_size": resolved_output,
            "sample_count": len(features),
            "skipped_pass_only_rows": skipped_pass_only,
            "source_csv": str(path.resolve()),
            "spell_catalog_version": str(frame.iloc[0].get("spell_catalog_version", "")),
            "rules_version": "run_g_v2",
        },
    )
