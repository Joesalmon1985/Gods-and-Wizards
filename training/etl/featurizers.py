"""Feature extraction matching Godot MacroFeatureFeaturizer / MicroCombatFeatureFeaturizer."""

from __future__ import annotations

from typing import Any

import numpy as np

MACRO_FEATURE_SIZE = 16
MICRO_FEATURE_SIZE = 10
MACRO_FEATURIZER_VERSION = "macro_feature_v1"
MICRO_FEATURIZER_VERSION = "micro_combat_feature_v1"


def featurize_macro_observation(observation: dict[str, Any]) -> np.ndarray:
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
