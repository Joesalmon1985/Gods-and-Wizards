extends Node3D
class_name City3D

@export var spawn_center_offset: Vector3 = Vector3.ZERO
@export var body_size: Vector3 = Vector3(12, 12, 12)  # house body
@export var roof_height: float = 30.5              # cone height
@export var roof_radius_factor: float = 0.5        # cone base vs body width
@export var outline_darkening: float = 0.9         # roof slightly darker
@export var faction: int = 0
@export var spawn_jitter_radius: float = 2.0

var _body: MeshInstance3D
var _roof: MeshInstance3D
var _mat_body: StandardMaterial3D
var _mat_roof: StandardMaterial3D
var debug_verbose: bool = false   # typed to avoid Variant warning
var spawn_interval_sec: float = 1         # spawn_interval
var audit_interval_sec: float = 2         # audit_interval
var min_population: int = 10            # min_pop
var max_population: int = 20             # max_pop
var spawn_class: String = 'warrior'                # spawn_cls

func _dbg_id(node: Node) -> String:
	return "%s#%d" % [node.name, node.get_instance_id()]
	
func _ready() -> void:
	# ---- body (box) ----
	_body = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = body_size
	_body.mesh = box
	_mat_body = StandardMaterial3D.new()
	_mat_body.metallic = 0.0
	_mat_body.roughness = 1.0
	_body.material_override = _mat_body
	add_child(_body)

	# add a direct child CollisionShape3D the spawner can “see”
	_add_radius_probe()

	_add_nav_obstacle()

	# ---- roof (cone via CylinderMesh) ----
	_roof = MeshInstance3D.new()
	var cone: CylinderMesh = CylinderMesh.new()
	var base_radius: float = maxf(body_size.x, body_size.z) * roof_radius_factor
	cone.top_radius = 0.0
	cone.bottom_radius = base_radius
	cone.height = roof_height
	cone.radial_segments = 16
	_roof.mesh = cone
	_mat_roof = StandardMaterial3D.new()
	_mat_roof.metallic = 0.0
	_mat_roof.roughness = 1.0
	_roof.material_override = _mat_roof
	# sit roof on top of body
	_roof.position = Vector3(0.0, body_size.y * 0.5 + roof_height * 0.5, 0.0)
	add_child(_roof)

	# --- Spawner: add first, then setup, then set position ---
	var spawner := Spawner.new()
	add_child(spawner)

	# Compute spawn center and log it
	var center := global_transform.origin + spawn_center_offset
	print("[Settlement3D] ready faction=", faction, " center=", center)

	# Pass the logical center into setup and position the spawner there
	spawner.configure(
		faction,                    # fac
		spawn_interval_sec,         # spawn_interval
		audit_interval_sec,         # audit_interval
		min_population,             # min_pop
		max_population,             # max_pop
		spawn_class,                # spawn_cls
		spawn_jitter_radius         # jitter
	)
	spawner.global_position = center

	if debug_verbose:
		print("[Settlement3D] footprint_r≈", get_footprint_radius())

	add_to_group("Buildings")
	add_to_group("Faction_%d" % faction)

func get_footprint_radius() -> float:
	# Try collision first (now we have a RadiusProbe as a direct child)
	var r: float = 1.0
	for child in get_children():
		if child is CollisionShape3D:
			var shape: Shape3D = (child as CollisionShape3D).shape
			if shape is BoxShape3D:
				var b: BoxShape3D = shape as BoxShape3D
				r = maxf(r, maxf(b.size.x, b.size.z) * 0.5)
			elif shape is SphereShape3D:
				r = maxf(r, (shape as SphereShape3D).radius)
			elif shape is CapsuleShape3D:
				r = maxf(r, (shape as CapsuleShape3D).radius)
			elif shape is CylinderShape3D:
				r = maxf(r, (shape as CylinderShape3D).radius)

	# Fallback to body_size if no collision shapes are found
	r = maxf(r, maxf(body_size.x, body_size.z) * 0.5)
	return r

func get_spawn_center() -> Vector3:
	return global_position + spawn_center_offset

func apply_owner(owner_color: Color) -> void:
	_mat_body.albedo_color = owner_color
	var d: float = outline_darkening
	_mat_roof.albedo_color = Color(owner_color.r * d, owner_color.g * d, owner_color.b * d, 1.0)

func _exit_tree() -> void:
	_remove_nav_obstacle()

func _add_radius_probe() -> void:
	# A light-weight shape used only for footprint queries (by the Spawner).
	# It doesn’t participate in physics, but it lets scripts read an accurate size.
	if get_node_or_null("RadiusProbe") != null:
		return
	var probe: CollisionShape3D = CollisionShape3D.new()
	probe.name = "RadiusProbe"
	var s: BoxShape3D = BoxShape3D.new()
	s.size = body_size
	probe.shape = s
	add_child(probe)

func _add_nav_obstacle() -> void:
	if get_node_or_null("NavObstacle") != null:
		return
	var obst: NavigationObstacle3D = NavigationObstacle3D.new()
	obst.name = "NavObstacle"
	obst.avoidance_enabled = true

	# Explicitly typed floats to avoid Variant inference warnings-as-errors
	var body_x: float = body_size.x
	var body_z: float = body_size.z
	var body_y: float = body_size.y
	var radius: float = maxf(body_x, body_z) * 0.6   # maxf

	obst.radius = radius
	obst.height = body_y * 1.2
	add_child(obst)

func _remove_nav_obstacle() -> void:
	if has_node("NavObstacle"):
		get_node("NavObstacle").queue_free()
