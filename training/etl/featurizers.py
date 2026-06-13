"""Feature extraction matching Godot MacroFeatureFeaturizer / MicroCombatFeatureFeaturizer."""

from __future__ import annotations

from typing import Any

import numpy as np

MACRO_SCALAR_FEATURE_SIZE = 16
MACRO_BOARD_FEATURE_SIZE = 240
MACRO_FEATURE_SIZE = MACRO_SCALAR_FEATURE_SIZE + MACRO_BOARD_FEATURE_SIZE
MICRO_FEATURE_SIZE = 10
MACRO_FEATURIZER_VERSION = "macro_policy_v2"
MICRO_FEATURIZER_VERSION = "micro_combat_feature_v1"
COMPACT_MACRO_ACTION_SLOTS = 64
MICRO_POLICY_ACTION_SLOTS = 6  # five loadout spells + pass


def featurize_macro_observation(observation: dict[str, Any]) -> np.ndarray:
    scalars = _macro_scalars(observation)
    board = _macro_board(observation)
    return np.concatenate([scalars, board])


def _macro_scalars(observation: dict[str, Any]) -> np.ndarray:
    resources = observation.get("resources", {})
    if isinstance(resources, str):
        import json

        resources = json.loads(resources) if resources else {}
    return np.asarray(
        [
            float(observation.get("victory_points", 0)),
            float(observation.get("city_count", 0)),
            float(observation.get("road_count", 0)),
            float(observation.get("breach_count", 0)),
            float(observation.get("total_demons", 0)),
            float(observation.get("round_number", 0)),
            float(observation.get("infection_rate", 0)),
            float(observation.get("draft_age", 1)),
            float(observation.get("draft_pack_size", 0)),
            float(resources.get("wood", 0)),
            float(resources.get("brick", 0)),
            float(resources.get("wheat", 0)),
            float(resources.get("sheep", 0)),
            float(resources.get("ore", 0)),
            1.0 if bool(observation.get("is_active_player", False)) else 0.0,
            1.0 if bool(observation.get("waiting_for_draft", False)) else 0.0,
        ],
        dtype=np.float32,
    )


def _macro_board(observation: dict[str, Any]) -> np.ndarray:
    values = np.zeros(MACRO_BOARD_FEATURE_SIZE, dtype=np.float32)
    raw = observation.get("board_features_json", [])
    if isinstance(raw, str):
        import json

        raw = json.loads(raw) if raw else []
    if isinstance(raw, list):
        for i, value in enumerate(raw[:MACRO_BOARD_FEATURE_SIZE]):
            values[i] = float(value)
    return values


def featurize_micro_observation(observation: dict[str, Any]) -> np.ndarray:
    loadout = observation.get("loadout_spell_ids", [])
    if isinstance(loadout, str):
        import json

        loadout = json.loads(loadout) if loadout else []
    health = float(observation.get("health", 0.0))
    mana = float(observation.get("mana", 0.0))
    active_id = str(observation.get("active_combatant_id", ""))
    combatant_id = str(observation.get("combatant_id", ""))
    return np.asarray(
        [
            health,
            mana,
            float(observation.get("opponent_health", 0.0)),
            float(observation.get("opponent_mana", 0.0)),
            float(observation.get("sim_time", 0.0)),
            float(len(loadout)),
            float(observation.get("legal_spell_count", 0)),
            1.0 if active_id == combatant_id else 0.0,
            1.0 if health < 40.0 else 0.0,
            1.0 if mana < 10.0 else 0.0,
        ],
        dtype=np.float32,
    )
