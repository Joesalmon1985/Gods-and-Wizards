class_name WizardWorldController
extends RefCounted

var camera_mode: WizardCameraRig.Mode = WizardCameraRig.Mode.BOARD_OVERVIEW
var marker_position := Vector3.ZERO
var marker_yaw_rad := 0.0
var board_center := Vector3.ZERO
var board_radius := 12.0
var encounter_prompt := ""


func toggle_camera() -> void:
	camera_mode = WizardCameraRig.toggle_mode(camera_mode)


func get_camera_transform() -> Dictionary:
	return WizardCameraRig.compute_transform(
		camera_mode,
		marker_position,
		marker_yaw_rad,
		board_center,
		board_radius
	)


func apply_movement(keys: Dictionary, delta: float) -> void:
	var move := WizardMovementInput.compute_move_delta(keys, delta, -1.0, marker_yaw_rad)
	if move != Vector3.ZERO:
		marker_position += move
	var yaw_delta := WizardMovementInput.compute_yaw_delta(keys, delta)
	if yaw_delta != 0.0:
		marker_yaw_rad += yaw_delta


func sync_board_bounds(snapshot: Dictionary) -> void:
	var nodes: Array = snapshot.get("nodes", [])
	if nodes.is_empty():
		return
	var sum := Vector3.ZERO
	for entry in nodes:
		var world: Dictionary = entry.get("world", {})
		sum += Vector3(float(world.get("x", 0.0)), 0.0, float(world.get("z", 0.0)))
	board_center = sum / float(nodes.size())
	var max_dist := 0.0
	for entry in nodes:
		var world: Dictionary = entry.get("world", {})
		var pos := Vector3(float(world.get("x", 0.0)), 0.0, float(world.get("z", 0.0)))
		max_dist = maxf(max_dist, board_center.distance_to(pos))
	board_radius = max_dist


func update_encounter_prompt(snapshot: Dictionary) -> void:
	var marker_world := {"x": marker_position.x, "y": marker_position.y, "z": marker_position.z}
	var proximity := EncounterProximity.check(snapshot, marker_world)
	if not bool(proximity.get("in_range", false)):
		encounter_prompt = ""
		return
	encounter_prompt = "Encounter near %s (%s, %.1fm)" % [
		proximity.get("node_id", "?"),
		proximity.get("target_type", "?"),
		float(proximity.get("distance", 0.0)),
	]
