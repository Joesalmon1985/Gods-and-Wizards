class_name EncounterProximity
extends RefCounted

static func check(snapshot: Dictionary, marker_world: Dictionary, radius: float = -1.0) -> Dictionary:
	var effective_radius := radius if radius >= 0.0 else WorldPresentationScale.encounter_radius()
	var marker := Vector3(
		float(marker_world.get("x", 0.0)),
		float(marker_world.get("y", 0.0)),
		float(marker_world.get("z", 0.0))
	)
	var node_worlds := _node_world_lookup(snapshot)
	var best := {"in_range": false, "distance": INF, "target_type": "", "target_id": "", "node_id": ""}

	for entry in snapshot.get("cities", []):
		_consider_target(best, marker, entry, "city", effective_radius, node_worlds)
	for entry in snapshot.get("heroes", []):
		_consider_target(best, marker, entry, "hero", effective_radius, node_worlds)
	for entry in snapshot.get("demons", []):
		_consider_target(best, marker, entry, "demon", effective_radius, node_worlds)

	return best


static func _node_world_lookup(snapshot: Dictionary) -> Dictionary:
	var lookup := {}
	for entry in snapshot.get("nodes", []):
		lookup[str(entry.get("id", ""))] = entry.get("world", {})
	return lookup


static func _consider_target(
	best: Dictionary,
	marker: Vector3,
	entry: Dictionary,
	target_type: String,
	radius: float,
	node_worlds: Dictionary
) -> void:
	var node_id: String = str(entry.get("node_id", ""))
	var world: Dictionary = entry.get("world", node_worlds.get(node_id, {}))
	if world.is_empty():
		return
	var target := Vector3(float(world.get("x", 0.0)), 0.0, float(world.get("z", 0.0)))
	var distance := marker.distance_to(target)
	if distance > radius:
		return
	if distance >= float(best.get("distance", INF)):
		return
	best["in_range"] = true
	best["distance"] = distance
	best["target_type"] = target_type
	best["target_id"] = str(entry.get("id", node_id))
	best["node_id"] = node_id
