class_name MacroFeatureFeaturizer
extends RefCounted

const SCALAR_FEATURE_SIZE := 16
const BOARD_FEATURE_SIZE := MacroBoardFeaturizer.BOARD_FEATURE_SIZE
const FEATURE_SIZE := SCALAR_FEATURE_SIZE + BOARD_FEATURE_SIZE
const MAX_LEGAL_ACTIONS := 64
const FEATURIZER_VERSION := "macro_policy_v2"


static func extract(observation: Dictionary) -> PackedFloat32Array:
	var scalars := _extract_scalars(observation)
	var board := _extract_board(observation)
	var packed := PackedFloat32Array()
	packed.resize(FEATURE_SIZE)
	for i in range(scalars.size()):
		packed[i] = scalars[i]
	for i in range(board.size()):
		packed[SCALAR_FEATURE_SIZE + i] = board[i]
	return packed


static func _extract_scalars(observation: Dictionary) -> PackedFloat32Array:
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


static func _extract_board(observation: Dictionary) -> PackedFloat32Array:
	var values := PackedFloat32Array()
	values.resize(BOARD_FEATURE_SIZE)
	for i in range(BOARD_FEATURE_SIZE):
		values[i] = 0.0
	var raw: Variant = observation.get("board_features_json", "")
	if typeof(raw) == TYPE_ARRAY:
		for i in range(mini(raw.size(), BOARD_FEATURE_SIZE)):
			values[i] = float(raw[i])
		return values
	if typeof(raw) != TYPE_STRING or str(raw) == "":
		return values
	var parsed = JSON.parse_string(str(raw))
	if typeof(parsed) != TYPE_ARRAY:
		return values
	for i in range(mini(parsed.size(), BOARD_FEATURE_SIZE)):
		values[i] = float(parsed[i])
	return values


static func action_space_layout_key(state: GameState) -> String:
	if state == null or state.action_space == null:
		return "empty"
	return "actions_%d" % state.action_space.all_actions_sorted().size()
