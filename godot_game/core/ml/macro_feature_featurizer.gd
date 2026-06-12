class_name MacroFeatureFeaturizer
extends RefCounted

const FEATURE_SIZE := 16
const MAX_LEGAL_ACTIONS := 64


static func extract(observation: Dictionary) -> PackedFloat32Array:
	var resources: Dictionary = observation.get("resources", {})
	return PackedFloat32Array([
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
		1.0 if bool(observation.get("is_active_player", false)) else 0.0,
		1.0 if bool(observation.get("waiting_for_draft", false)) else 0.0,
	])


static func action_space_layout_key(state: GameState) -> String:
	if state == null or state.action_space == null:
		return "empty"
	return "actions_%d" % state.action_space.all_actions_sorted().size()
