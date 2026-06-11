extends Node3D
class_name GameRoot

@export var level_scene: PackedScene
@export var player_scene: PackedScene
@export var spectator_scene: PackedScene

# --- Spawn tuning ---
@export var player_clearance_radius: float = 0.45    # match your player collider radius
@export var spawn_search_limit_ratio: float = 0.95   # how far from marker to search (as % of hex radius)
@export var spawn_block_mask: int = 0x7FFFFFFF       # layers that BLOCK the player (used by shape probe)
@export var spawn_floor_mask: int = 0x7FFFFFFF       # layers considered FLOOR for the raycast
@export var ray_up: float = 6.0                      # how far above we start the floor ray
@export var ray_down: float = 24.0                   # how far down we search for the floor

const SpawnUtils = preload("res://scripts/characters/SpawnUtils.gd") # keep this path if that's where you put it

var _level: Node = null
var _actor: Node = null

func _ready() -> void:
	# Instance level
	if level_scene != null:
		_level = level_scene.instantiate()
		add_child(_level)

	# Spawn actor: prefer player_scene if set, otherwise spectator_scene
	var to_spawn: PackedScene = null
	if player_scene != null:
		to_spawn = player_scene
	elif spectator_scene != null:
		to_spawn = spectator_scene

	if to_spawn != null:
		_actor = to_spawn.instantiate()
		add_child(_actor)
		_spawn_actor_at_marker(_actor, "PlayerSpawn")

func _spawn_actor_at_marker(actor: Node, marker_name: String) -> void:
	if _level == null or actor == null:
		return

	# 1) Find a marker by name or by "player_spawn" group
	var marker: Node = _level.get_node_or_null(marker_name)
	if marker == null:
		var group_nodes: Array = get_tree().get_nodes_in_group("player_spawn")
		if group_nodes.size() > 0:
			marker = group_nodes[0] as Node

	# 2) Compute an origin & hex context
	var origin: Vector3 = global_transform.origin
	var top_y_guess: float = origin.y
	var hex_radius: float = 64.0
	if marker is Node3D:
		var m3: Node3D = marker as Node3D
		origin = m3.global_transform.origin
		top_y_guess = origin.y

	var hex: HexTile3D_Base = _find_hex_ancestor(marker) if marker != null else null
	if hex:
		hex_radius = hex.radius
		# Prefer exact hex top if available
		top_y_guess = hex.global_transform.origin.y + hex.height

	# 3) Use physics shape probe to find nearest free XZ around the marker
	if actor is Node3D:
		var a3: Node3D = actor as Node3D
		var clearance: float = _infer_clearance_from_actor(actor)
		var search_limit: float = hex_radius * spawn_search_limit_ratio

		var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var spawn_xz: Vector3 = SpawnUtils.find_free_spawn(
			origin,
			top_y_guess,
			search_limit,
			clearance,
			space,
			spawn_block_mask
		)

		# 4) Raycast down to snap to the actual floor, then lift by feet offset
		var feet_offset: float = _infer_feet_offset_from_actor(actor) # distance from origin to soles
		var snapped_y: float = _raycast_floor_y(spawn_xz, feet_offset, space)
		a3.global_transform.origin = Vector3(spawn_xz.x, snapped_y, spawn_xz.z)

# ---- helpers -------------------------------------------------------

func _find_hex_ancestor(n: Node) -> HexTile3D_Base:
	var cur: Node = n
	while cur:
		if cur is HexTile3D_Base:
			return cur as HexTile3D_Base
		cur = cur.get_parent()
	return null

func _infer_clearance_from_actor(actor: Node) -> float:
	# Radius used for the horizontal clearance probe
	return _scan_radius_recursive(actor, player_clearance_radius)

func _scan_radius_recursive(n: Node, current: float) -> float:
	var cs: CollisionShape3D = n as CollisionShape3D
	if cs and cs.shape:
		if cs.shape is CapsuleShape3D:
			current = max(current, (cs.shape as CapsuleShape3D).radius)
		elif cs.shape is CylinderShape3D:
			current = max(current, (cs.shape as CylinderShape3D).radius)
		elif cs.shape is BoxShape3D:
			current = max(current, (cs.shape as BoxShape3D).size.x * 0.5) # use half-width as clearance
	for c in n.get_children():
		current = _scan_radius_recursive(c, current)
	return current

func _infer_feet_offset_from_actor(actor: Node) -> float:
	# Distance from actor's origin to where the FEET should be on the floor.
	# We try to derive this from shapes; fallback to something sensible.
	var result: float = 1.0
	_infer_feet_offset_scan(actor, result)
	return result

func _infer_feet_offset_scan(n: Node, result: float) -> void:
	var cs: CollisionShape3D = n as CollisionShape3D
	if cs and cs.shape:
		if cs.shape is CapsuleShape3D:
			var cap: CapsuleShape3D = cs.shape as CapsuleShape3D
			# Center-to-bottom for a capsule is height/2 + radius
			var off: float = (cap.height * 0.5) + cap.radius
			result = max(result, off)
		elif cs.shape is CylinderShape3D:
			var cyl: CylinderShape3D = cs.shape as CylinderShape3D
			var offc: float = cyl.height * 0.5
			result = max(result, offc)
		elif cs.shape is BoxShape3D:
			var box: BoxShape3D = cs.shape as BoxShape3D
			result = max(result, box.size.y * 0.5)
	for c in n.get_children():
		_infer_feet_offset_scan(c, result)

func _raycast_floor_y(pos: Vector3, feet_offset: float, space: PhysicsDirectSpaceState3D) -> float:
	# Cast from above downwards to find floor, then add feet_offset and a tiny epsilon.
	var from: Vector3 = pos + Vector3(0.0, ray_up, 0.0)
	var to: Vector3 = pos - Vector3(0.0, ray_down, 0.0)
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, spawn_floor_mask)
	ray.collide_with_areas = false
	ray.collide_with_bodies = true
	var hit: Dictionary = space.intersect_ray(ray)
	if hit.is_empty():
		# No hit; keep the guess but lift slightly
		return pos.y + feet_offset + 0.02
	var floor_y: float = (hit["position"] as Vector3).y
	return floor_y + feet_offset + 0.02
