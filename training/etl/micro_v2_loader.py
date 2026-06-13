"""Load micro_combat_v2 CSV exports into PyTorch-ready tensors."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
import torch

from etl.featurizers import MICRO_FEATURE_SIZE, MICRO_FEATURIZER_VERSION, MICRO_POLICY_ACTION_SLOTS, featurize_micro_observation

SCHEMA_VERSION = "micro_combat_v2"
LAYOUT_VERSION = "loadout_spells_plus_pass_v1"
PASS_SPELL_ID = "__pass__"


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


def _normalize_mask(mask_bits: list[Any], loadout: list[str]) -> list[float]:
    bits = [float(x) for x in mask_bits]
    pass_index = len(loadout)
    if len(bits) == pass_index:
        bits.append(1.0)
    if len(bits) < MICRO_POLICY_ACTION_SLOTS:
        bits.extend([0.0] * (MICRO_POLICY_ACTION_SLOTS - len(bits)))
    elif len(bits) > MICRO_POLICY_ACTION_SLOTS:
        bits = bits[:MICRO_POLICY_ACTION_SLOTS]
    return bits


def _micro_target_index(row: pd.Series, loadout: list[str], mask_bits: list[float]) -> int:
    selected = str(row["selected_action"])
    pass_index = len(loadout)
    if selected == PASS_SPELL_ID:
        return pass_index
    if selected in loadout:
        index = loadout.index(selected)
        if index < pass_index and mask_bits[index] > 0.0:
            return index
    legal_indices = [i for i, bit in enumerate(mask_bits) if bit > 0.0]
    if not legal_indices:
        return pass_index
    return int(legal_indices[0])


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

    resolved_output = output_size or MICRO_POLICY_ACTION_SLOTS
    if resolved_output != MICRO_POLICY_ACTION_SLOTS:
        raise ValueError(
            f"micro policy head must be {MICRO_POLICY_ACTION_SLOTS} slots (spells+pass), got {resolved_output}"
        )

    features: list[np.ndarray] = []
    targets: list[int] = []
    masks: list[np.ndarray] = []
    rewards: list[float] = []
    terminal: list[float] = []
    skipped_pass_only = 0

    for _, row in frame.iterrows():
        obs = _parse_json_column(row["pre_observation_json"], {})
        loadout = _parse_json_column(row.get("loadout_spell_ids_json", []), [])
        if not loadout:
            loadout = obs.get("loadout_spell_ids", [])
        if isinstance(loadout, str):
            loadout = json.loads(loadout) if loadout else []

        mask_bits = _normalize_mask(_parse_json_column(row["legal_mask_json"], []), loadout)
        mask_arr = np.asarray(mask_bits, dtype=np.float32)
        legal_indices = np.flatnonzero(mask_arr > 0.0)
        if legal_indices.size == 0:
            skipped_pass_only += 1
            continue

        if "legal_spell_count" not in obs:
            obs["legal_spell_count"] = int(np.sum(mask_arr[:len(loadout)]))

        feature = featurize_micro_observation(obs)
        if feature.shape[0] != MICRO_FEATURE_SIZE:
            raise ValueError(f"micro feature dim mismatch: {feature.shape[0]} != {MICRO_FEATURE_SIZE}")

        target = _micro_target_index(row, loadout, mask_bits)
        if mask_arr[target] <= 0.0:
            target = int(legal_indices[0])

        features.append(feature)
        targets.append(target)
        masks.append(mask_arr)
        rewards.append(float(row.get("reward", 0.0)))
        terminal.append(1.0 if str(row.get("terminal", "false")).lower() == "true" else 0.0)

    if not features:
        raise ValueError(f"micro CSV has no trainable rows after filtering: {path}")

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
            "legal_mask_layout_version": LAYOUT_VERSION,
        },
    )
