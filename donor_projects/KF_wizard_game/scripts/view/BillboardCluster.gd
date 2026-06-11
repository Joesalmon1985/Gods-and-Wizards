@tool
extends Node3D
class_name BillboardCluster

## Doom-style layered billboards around an impassable circular core.
## Can auto-hide billboards on the camera-facing half so they are always "behind" the blocker.

# --- Blocker (solid center) ---
@export_range(0.10, 0.95, 0.01) var collider_radius_ratio: float = 0.58
@export var collider_height: float = 2.0
@export var add_navigation_obstacle: bool = false   # if your AI plans only on navmesh

# --- Billboard rings ---
@export var rings: int = 2
@export var sprites_per_ring: int = 8
@export_range(0.10, 0.98, 0.01) var ring_inner_ratio: float = 0.62
@export_range(0.12, 1.10, 0.01) var ring_outer_ratio: float = 0.92
@export var angle_jitter_deg: float = 10.0
@export var vertical_jitter: float = 0.15
@export var min_scale: float = 0.9
@export var max_scale: float = 1.2
@export var pixel_size: float = 0.04
@export var y_center: float = 1.1

# Textures pool (drag your tree/mountain sprites here)
@export var textures: Array[Texture2D] = []

# Visual tweaks
@export_range(0.0, 1.0, 0.01) var alpha: float = 1.0  # 1=opaque

# Rebuild in editor
@export var regenerate_now: bool:
	set(value):
		if value:
			call_deferred("_rebuild")
	get:
		return false

# Randomness control
@export var seed_offset: int = 0

# --- keep billboards behind the blocker relative to camera ---
@export_enum("FULL_RING", "BACK_HALF_HIDE") var placement_mode: String = "BACK_HALF_HIDE"
@export_range(0.0, 80.0, 1.0) var back_margin_degrees: float = 12.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _blocker: StaticBody3D
var _shape: CollisionShape3D
var _sprites_root: Node3D
var _nav_obstacle: NavigationObstacle3D

func _ready() -> void:
	_ensure_nodes()
	_rebuild()
	set_process(true) # update behind-camera visibility

func _process(_delta: float) -> void:
	_update_behind_visibility()

func _ensure_nodes() -> void:
	_blocker = get_node_or_null("Blocker") as StaticBody3D
	if _blocker == null:
		_blocker = StaticBody3D.new()
		_blocker.name = "Blocker"
		add_child(_blocker)
	_shape = _blocker.get_node_or_null("Shape") as CollisionShape3D
	if _shape == null:
		_shape = CollisionShape3D.new()
		_shape.name = "Shape"
		_blocker.add_child(_shape)

	_sprites_root = get_node_or_null("Sprites") as Node3D
	if _sprites_root == null:
		_sprites_root = Node3D.new()
		_sprites_root.name = "Sprites"
		add_child(_sprites_root)

	_nav_obstacle = get_node_or_null("NavObstacle") as NavigationObstacle3D

func _rebuild() -> void:
	# Parent hex sizing
	var hex: HexTile3D_Base = get_parent() as HexTile3D_Base
	var R: float = 64.0
	var top_y: float = 0.4
	var q: int = 0
	var r: int = 0
	if hex:
		R = hex.radius
		top_y = hex.height
		q = hex.axial_q
		r = hex.axial_r

	_rng.seed = _hash_seed(q, r, seed_offset)

	# --- Solid circular blocker (cylinder) ---
	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = R * clamp(collider_radius_ratio, 0.10, 0.95)
	cyl.height = collider_height
	_shape.shape = cyl
	_blocker.position = Vector3(0.0, top_y + collider_height * 0.5, 0.0)

	# Optional nav obstacle
	if add_navigation_obstacle:
		if _nav_obstacle == null:
			_nav_obstacle = NavigationObstacle3D.new()
			_nav_obstacle.name = "NavObstacle"
			add_child(_nav_obstacle)
		_nav_obstacle.position = Vector3(0.0, top_y, 0.0)
	else:
		if _nav_obstacle:
			_nav_obstacle.queue_free()
			_nav_obstacle = null

	# --- Billboards ---
	for child in _sprites_root.get_children():
		var n: Node = child
		n.queue_free()

	var inner: float = R * clamp(ring_inner_ratio, 0.10, 0.98)
	var outer: float = R * clamp(ring_outer_ratio, inner + 0.01, 1.10)
	var steps: int = max(1, rings)
	var ring_step: float = ((outer - inner) / float(steps - 1)) if steps > 1 else 0.0

	for j in range(steps):
		var rr: float = inner + float(j) * ring_step
		var count: int = max(1, sprites_per_ring)
		for i in range(count):
			var base_angle: float = TAU * float(i) / float(count)
			var angle: float = base_angle + deg_to_rad(_rng.randf_range(-angle_jitter_deg, angle_jitter_deg))
			var pos2: Vector2 = Vector2(cos(angle), sin(angle)) * rr

			var s: Sprite3D = Sprite3D.new()
			s.name = "S_%d_%d" % [j, i]

			if textures.size() > 0:
				var tex: Texture2D = textures[_rng.randi_range(0, textures.size() - 1)]
				s.texture = tex

			s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			s.pixel_size = pixel_size

			var sc: float = _rng.randf_range(min_scale, max_scale)
			s.scale = Vector3(sc, sc, sc)
			s.position = Vector3(
				pos2.x,
				top_y + y_center + _rng.randf_range(-vertical_jitter, vertical_jitter),
				pos2.y
			)

			if alpha < 1.0:
				var mat: StandardMaterial3D = StandardMaterial3D.new()
				mat.flags_transparent = true
				mat.albedo_color = Color(1, 1, 1, alpha)
				s.material_override = mat

			_sprites_root.add_child(s)

func _update_behind_visibility() -> void:
	if placement_mode == "FULL_RING":
		for child in _sprites_root.get_children():
			var s: Sprite3D = child as Sprite3D
			if s:
				s.visible = true
		return

	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		for child in _sprites_root.get_children():
			var s2: Sprite3D = child as Sprite3D
			if s2:
				s2.visible = true
		return

	var center: Vector3 = global_transform.origin
	var cam_vec: Vector3 = cam.global_transform.origin - center
	var cam_dir2: Vector2 = Vector2(cam_vec.x, cam_vec.z)
	if cam_dir2.length_squared() == 0.0:
		for child in _sprites_root.get_children():
			var s3: Sprite3D = child as Sprite3D
			if s3:
				s3.visible = true
		return
	cam_dir2 = cam_dir2.normalized()

	# Visible only if angle > 90° + margin -> dot < cos(90°+margin) = -sin(margin)
	var thresh: float = -sin(deg_to_rad(back_margin_degrees))

	for child in _sprites_root.get_children():
		var s: Sprite3D = child as Sprite3D
		if s == null:
			continue
		var v: Vector3 = s.global_transform.origin - center
		var v2: Vector2 = Vector2(v.x, v.z)
		if v2.length_squared() == 0.0:
			s.visible = false
			continue
		v2 = v2.normalized()
		var d: float = v2.dot(cam_dir2)
		s.visible = (d < thresh)

# FNV-ish hash for stable randomness per hex
func _hash_seed(q: int, r: int, off: int) -> int:
	var s := str(q, ":", r, ":", off)
	var h := 1469598103934665603
	for i in s.length():
		h = int((h ^ s.unicode_at(i)) * 1099511628211) & 0x7FFFFFFFFFFFFFFF
	return h
