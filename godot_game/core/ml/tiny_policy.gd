class_name TinyPolicy
extends RefCounted

var weights: PackedFloat32Array = PackedFloat32Array([0.1, 0.2, 0.05, 0.15, 0.1, 0.3, 0.1])


static func default_policy() -> TinyPolicy:
	return TinyPolicy.new()


func forward(observation: Dictionary) -> float:
	var features := PackedFloat32Array([
		float(observation.get("victory_points", 0)),
		float(observation.get("city_count", 0)),
		float(observation.get("road_count", 0)),
		float(observation.get("breach_count", 0)),
		float(observation.get("total_demons", 0)),
		float(observation.get("round_number", 0)),
		1.0 if bool(observation.get("is_active_player", false)) else 0.0,
	])
	var score := 0.0
	for i in range(mini(features.size(), weights.size())):
		score += features[i] * weights[i]
	return score


func choose_action_index(legal_mask: Array) -> int:
	var best_index := -1
	var best_score := -INF
	for i in range(legal_mask.size()):
		if not bool(legal_mask[i]):
			continue
		var pseudo_score := float(i) * 0.01 + weights[i % weights.size()]
		if pseudo_score > best_score:
			best_score = pseudo_score
			best_index = i
	return best_index
