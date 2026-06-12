class_name MicroCombatFeatureFeaturizer
extends RefCounted

const FEATURE_SIZE := 10
const MAX_SPELL_ACTIONS := 16


static func extract(observation: Dictionary) -> PackedFloat32Array:
	return PackedFloat32Array([
		float(observation.get("health", 0.0)),
		float(observation.get("mana", 0.0)),
		float(observation.get("opponent_health", 0.0)),
		float(observation.get("opponent_mana", 0.0)),
		float(observation.get("sim_time", 0.0)),
		float(observation.get("loadout_spell_ids", []).size()),
		float(observation.get("legal_spell_count", 0)),
		1.0 if str(observation.get("active_combatant_id", "")) == str(observation.get("combatant_id", "")) else 0.0,
		1.0 if float(observation.get("health", 0.0)) < 40.0 else 0.0,
		1.0 if float(observation.get("mana", 0.0)) < 10.0 else 0.0,
	])
