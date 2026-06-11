extends Node3D
class_name Spawner

##Default values - can be overriden when called using the configure function
@export var faction: int = 0
@export var spawn_interval_sec: float = 10.0
@export var audit_interval_sec: float = 5.0
@export var min_population: int = 1
@export var max_population: int = 2
@export var spawn_class: String = "warrior"

@export var character_scene_path: String = "res://scenes/Character3D.tscn"



# Donut around the building (tweak these in the inspector)
@export var spawn_inner_margin: float = 3.0      # extra clearance beyond settlement radius
@export var spawn_band_width: float  = 5.0       # ring thickness
@export var spawn_height_above_nav: float = 0.0  # y offset above navmesh y (0 = on the mesh)
@export var max_spawn_tries: int = 16

@export var debug_verbose: bool = false

var _spawn_timer: Timer
var _audit_timer: Timer
var _characters: Array[Character3D] = []

# New function to allow external configuration
func configure(
	fac: int, 
	spawn_interval: float = 10.0, 
	audit_interval: float = 5.0, 
	min_pop: int = 1, 
	max_pop: int = 2, 
	spawn_cls: String = "warrior",
	jitter: float = 0.6
) -> void:
	faction = fac
	spawn_interval_sec = spawn_interval
	audit_interval_sec = audit_interval
	min_population = min_pop
	max_population = max_pop
	spawn_class = spawn_cls
#
#func setup(fac: int, pos: Vector3, jitter: float = 0.6) -> void:
	#faction = fac
	## allow caller to narrow/widen the ring a bit
	#var ring: float = maxf(0.1, jitter)
	#spawn_inner_margin = maxf(0.1, ring * 2.0)
	#spawn_band_width   = maxf(0.1, ring * 3.0)

func _ready() -> void:
	# If faction wasn’t set, try inherit from parent Settlement3D
	if faction == 0 and get_parent() and get_parent().has_method("get"):
		var pf: Variant = get_parent().get("faction")
		if pf is int:
			faction = int(pf)

	if debug_verbose:
		print("[Spawner] start @", global_position, " faction=", faction)

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval_sec
	_spawn_timer.autostart = true
	_spawn_timer.timeout.connect(_on_spawn_timer)
	add_child(_spawn_timer)

	_audit_timer = Timer.new()
	_audit_timer.wait_time = audit_interval_sec
	_audit_timer.autostart = true
	_audit_timer.timeout.connect(_on_audit_timer)
	add_child(_audit_timer)

func _on_spawn_timer() -> void:
	var cleaned: Array[Character3D] = []
	for c in _characters:
		if is_instance_valid(c):
			cleaned.append(c)
	_characters = cleaned

	if _characters.size() >= max_population:
		return
	_try_spawn()

func _on_audit_timer() -> void:
	var cleaned: Array[Character3D] = []
	for c in _characters:
		if is_instance_valid(c):
			cleaned.append(c)
	_characters = cleaned

	if _characters.size() < min_population and _characters.size() < max_population:
		if debug_verbose:
			print("[Spawner] audit -> below min (", _characters.size(), "/", max_population, "), spawning one")
		_try_spawn()

func _try_spawn() -> void:
	if _characters.size() >= max_population:
		return

	var ps := load(character_scene_path) as PackedScene
	if ps == null:
		if debug_verbose:
			push_error("[Spawner] Missing character scene at " + character_scene_path)
		return

	# 1) Pick a spawn near this spawner (already snapped to navmesh + offset)
	var spawn_pos: Vector3 = _pick_spawn_point(global_position)

	# 1b) FINAL safety clamp to navmesh Y (protects against any accidental drift)
	var nav_map: RID = get_world_3d().navigation_map
	var on_nav: Vector3 = NavigationServer3D.map_get_closest_point(nav_map, spawn_pos)
	if on_nav != Vector3.INF:
		spawn_pos = on_nav + Vector3(0.0, spawn_height_above_nav, 0.0)

	# 2) Instantiate
	var ch := ps.instantiate() as Character3D
	ch.setup_combat_profile_from_class(spawn_class)
	ch.faction = faction
	ch.global_position = spawn_pos
	ch.name = "Char_%s" % str(Time.get_ticks_msec())
	ch.add_to_group("characters")

	if debug_verbose:
		print("[Spawner] spawned @", spawn_pos, " on_nav_closest=", on_nav)

	# 3) Parent
	var parent_root: Node3D = _get_characters_root()
	parent_root.add_child(ch)

	# 4) Track
	_characters.append(ch)

	if debug_verbose:
		print("[Spawner] spawned OK (faction=", faction, ")")




# --- helpers ---

func _estimate_settlement_radius() -> float:
	# Best: ask the parent Settlement3D if it exposes its radius
	var parent_node: Node = get_parent()
	if parent_node != null:
		if parent_node.has_method("get_footprint_radius"):
			var r_val: Variant = parent_node.call("get_footprint_radius")
			if r_val is float and float(r_val) > 0.0:
				return float(r_val)
		# legacy support if you had `body_size: Vector3` on the parent
		if parent_node.has_method("get"):
			var bs: Variant = parent_node.get("body_size")
			if bs is Vector3:
				var bs_v: Vector3 = bs
				return maxf(1.0, maxf(bs_v.x, bs_v.z) * 0.5)

	# Fallback: scan direct children for collision shapes (simple but safe)
	var base: float = 1.0
	if parent_node != null:
		for child in parent_node.get_children():
			if child is CollisionShape3D:
				var shape: Shape3D = (child as CollisionShape3D).shape
				if shape is BoxShape3D:
					var box: BoxShape3D = shape
					base = maxf(base, maxf(box.size.x, box.size.z) * 0.5)
				elif shape is SphereShape3D:
					base = maxf(base, (shape as SphereShape3D).radius)
				elif shape is CapsuleShape3D:
					base = maxf(base, (shape as CapsuleShape3D).radius)
				elif shape is CylinderShape3D:
					base = maxf(base, (shape as CylinderShape3D).radius)
	return base

func _get_world3d() -> Node3D:
	var n: Node = self
	while n != null:
		if n is Node3D and n.name == "World3D":
			return n as Node3D
		n = n.get_parent()
	return null

func _get_characters_root() -> Node3D:
	var world3d: Node3D = _get_world3d()
	if world3d and world3d.has_node("CharactersRoot"):
		return world3d.get_node("CharactersRoot") as Node3D
	return self

func _pick_spawn_point(center: Vector3) -> Vector3:
	var nav_map: RID = get_world_3d().navigation_map

	var settlement_r: float = _estimate_settlement_radius()
	var inner: float = settlement_r + spawn_inner_margin
	var outer: float = inner + spawn_band_width

	if debug_verbose:
		print("[Spawner] using settlement_r=", settlement_r, " inner=", inner, " outer=", outer)

	for i in range(max_spawn_tries):
		# random direction on XZ
		var dir: Vector3 = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
		dir = dir.normalized() if dir.length_squared() >= 0.0001 else Vector3.FORWARD

		# distance in the donut [inner, outer]
		var r: float = randf_range(inner, outer)
		var p: Vector3 = center + dir * r

		# snap to navmesh and set height
		var nav_p: Vector3 = NavigationServer3D.map_get_closest_point(nav_map, p)
		if nav_p == Vector3.INF:
			continue
		var candidate: Vector3 = nav_p + Vector3(0.0, spawn_height_above_nav, 0.0)

		# quick physics overlap so we don't spawn inside stuff
		var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var sphere := SphereShape3D.new()
		sphere.radius = 0.6
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = sphere
		q.transform = Transform3D(Basis(), candidate)
		q.collide_with_areas = true
		q.collide_with_bodies = true
		q.collision_mask = 0xFFFFFFFF

		var hits: Array = space.intersect_shape(q, 1)
		if hits.is_empty():
			return candidate

	# fallback: snap the center to navmesh too
	var center_nav := NavigationServer3D.map_get_closest_point(nav_map, center)
	if center_nav != Vector3.INF:
		return center_nav + Vector3(0.0, spawn_height_above_nav, 0.0)
	return center  # last resort
