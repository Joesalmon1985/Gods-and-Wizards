@tool
extends Node3D
class_name ImpassableSpriteFill

# --- Blocker (solid center) ---
@export_range(0.10, 0.95, 0.01) var collider_radius_ratio: float = 0.62
@export var collider_height: float = 2.0
@export var show_blocker_mesh: bool = true
@export var blocker_mesh_height: float = 0.08
@export var blocker_color: Color = Color(0.1, 0.4, 0.2, 0.55) # translucent green, editor-visible
@export var add_navigation_obstacle: bool = false

# ---- Optional big center feature ----
@export var centerpiece_enabled: bool = false
@export var centerpiece_texture: Texture2D
@export var centerpiece_pixel_size: float = 0.03   # smaller number = bigger on screen
@export var centerpiece_scale: float = 1.8
@export var centerpiece_offset_y: float = 1.1      # height above the hex top
@export var centerpiece_scene: PackedScene         # alternative to texture: instance this scene
@export var centerpiece_face_camera_y: bool = true # make center face camera around Y (billboard/scene)


# --- Sprite scatter (INSIDE the blocker circle) ---
@export var count_min: int = 30
@export var count_max: int = 40
@export_range(0.02, 0.40, 0.01) var min_separation_ratio: float = 0.10
@export var y_center: float = 1.0
@export var pixel_size: float = 0.045
@export var min_scale: float = 0.90
@export var max_scale: float = 1.30
@export var vertical_jitter: float = 0.10

# Textures (auto-load from a folder if 'textures' empty)
@export var textures: Array[Texture2D] = []
@export var textures_dir: String = "res://resources"   # change if yours live elsewhere
@export var filename_contains: String = "tree"         # case-insensitive

# ---- Centerpiece visual offset (planar) ----
@export_group("Centerpiece Offset")
@export var centerpiece_offset_xz: Vector2 = Vector2.ZERO
@export var centerpiece_use_polar: bool = false
@export_range(0.0, 1.0, 0.01) var centerpiece_radius_ratio: float = 0.0  # fraction of blocker radius
@export var centerpiece_angle_deg: float = 0.0
@export var centerpiece_random_jitter: float = 0.0  # world units of random nudge
@export var centerpiece_yaw_offset_deg: float = 0.0 # extra yaw added after face-camera


# Editor control
@export var regenerate_now: bool:
	set(value):
		if value:
			call_deferred("_rebuild")
	get:
		return false

# Deterministic randomness per hex
@export var seed_offset: int = 0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _blocker: StaticBody3D
var _shape: CollisionShape3D
var _blocker_vis: MeshInstance3D
var _sprites_root: Node3D
var _nav_obstacle: NavigationObstacle3D
var _centerpiece_node: Node3D

# ---- Debug ----
@export var debug_log: bool = false


func _ready() -> void:
	_ensure_nodes()
	_rebuild()
	set_process(false) # no per-frame work needed
	set_process(centerpiece_face_camera_y) # rotate centerpiece toward camera if requested

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

	_blocker_vis = get_node_or_null("BlockerVis") as MeshInstance3D
	if _blocker_vis == null:
		_blocker_vis = MeshInstance3D.new()
		_blocker_vis.name = "BlockerVis"
		add_child(_blocker_vis)

	_sprites_root = get_node_or_null("Sprites") as Node3D
	if _sprites_root == null:
		_sprites_root = Node3D.new()
		_sprites_root.name = "Sprites"
		add_child(_sprites_root)

	_nav_obstacle = get_node_or_null("NavObstacle") as NavigationObstacle3D

func _rebuild() -> void:
	# Base hex for size/height and deterministic seed
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

	# Load textures automatically if none set
	if textures.is_empty() and textures_dir != "":
		textures = _load_textures_from_dir(textures_dir, filename_contains)

	# --- Build the solid blocker (cylinder) ---
	var block_r: float = R * clamp(collider_radius_ratio, 0.10, 0.95)

	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = block_r
	cyl.height = collider_height
	_shape.shape = cyl
	_blocker.position = Vector3(0.0, top_y + collider_height * 0.5, 0.0)

	# Optional navigation obstacle (for navmesh-only AI planning)
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

	# --- Visible top disk (editor-visible) ---
	var vis_mesh: CylinderMesh = CylinderMesh.new()
	vis_mesh.top_radius = block_r
	vis_mesh.bottom_radius = block_r
	vis_mesh.height = max(0.002, blocker_mesh_height)
	vis_mesh.radial_segments = 48

	var vis_mat: StandardMaterial3D = StandardMaterial3D.new()
	vis_mat.albedo_color = blocker_color
	vis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vis_mat.flags_transparent = blocker_color.a < 1.0
	vis_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_blocker_vis.mesh = vis_mesh
	_blocker_vis.material_override = vis_mat
	_blocker_vis.visible = show_blocker_mesh
	_blocker_vis.position = Vector3(0.0, top_y + vis_mesh.height * 0.5 + 0.01, 0.0)

	# --- Scatter sprites INSIDE the blocker circle ---
	for child in _sprites_root.get_children():
		(child as Node).queue_free()

	var n: int = _rng.randi_range(count_min, count_max)
	if n <= 0 or textures.is_empty():
		return

	var r_in: float = block_r * 0.98  # a tiny margin inside the collider
	var min_sep: float = block_r * clamp(min_separation_ratio, 0.02, 0.40)
	var placed: Array[Vector2] = []

	for i in range(n):
		var ok: bool = false
		var p: Vector2 = Vector2.ZERO
		var tries: int = 0
		while not ok and tries < 32:
			tries += 1
			p = _rand_point_in_disc(r_in)
			ok = true
			for qv in placed:
				if qv.distance_to(p) < min_sep:
					ok = false
					break
		placed.append(p)

		var s: Sprite3D = Sprite3D.new()
		s.name = "Tree_%02d" % i
		s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		s.pixel_size = pixel_size
		var sc: float = _rng.randf_range(min_scale, max_scale)
		s.scale = Vector3(sc, sc, sc)
		s.position = Vector3(p.x, top_y + y_center + _rng.randf_range(-vertical_jitter, vertical_jitter), p.y)

		# Pick a random tree sprite
		var tex: Texture2D = textures[_rng.randi_range(0, textures.size() - 1)]
		s.texture = tex

		_sprites_root.add_child(s)
			# --- Centerpiece (unique central feature) ---
	# Remove old centerpiece if it exists
	var old_center: Node = get_node_or_null("Centerpiece")
	if old_center:
		old_center.queue_free()
		_centerpiece_node = null

	# --- compute visual center offset on the XZ plane ---
	var cp_pos2: Vector2 = Vector2.ZERO
	if centerpiece_use_polar:
		var rr: float = block_r * clamp(centerpiece_radius_ratio, 0.0, 1.0)
		var aa: float = deg_to_rad(centerpiece_angle_deg)
		cp_pos2 = Vector2(cos(aa), sin(aa)) * rr
	else:
		cp_pos2 = centerpiece_offset_xz

	if centerpiece_random_jitter > 0.0:
		var j_ang: float = _rng.randf_range(0.0, TAU)
		var j_rad: float = min(centerpiece_random_jitter, block_r) * sqrt(_rng.randf())
		cp_pos2 += Vector2(cos(j_ang) * j_rad, sin(j_ang) * j_rad)
	if centerpiece_enabled:
		if centerpiece_scene != null:
			# Instance a scene as the centerpiece (e.g., a farm)
			var nn: Node = centerpiece_scene.instantiate()
			_centerpiece_node = nn as Node3D
			if _centerpiece_node == null:
				# if the scene isn't Node3D, wrap it
				_centerpiece_node = Node3D.new()
				_centerpiece_node.add_child(nn)
			_centerpiece_node.name = "Centerpiece"
			_centerpiece_node.position = Vector3(0.0, top_y + centerpiece_offset_y, 0.0)
			_centerpiece_node.scale = Vector3.ONE * max(0.01, centerpiece_scale)
			add_child(_centerpiece_node)
		else:
			# Use a billboarded Sprite3D from a texture (fallback to first tree/ sheep texture)
			var s_center: Sprite3D = Sprite3D.new()
			s_center.name = "Centerpiece"
			s_center.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			s_center.pixel_size = centerpiece_pixel_size
			var ctex: Texture2D = centerpiece_texture
			if ctex == null and textures.size() > 0:
				ctex = textures[0]
			if ctex != null:
				s_center.texture = ctex
			s_center.scale = Vector3.ONE * max(0.01, centerpiece_scale)
			s_center.position = Vector3(0.0, top_y + centerpiece_offset_y, 0.0)
			add_child(s_center)
			_centerpiece_node = s_center



# Helpers ------------------------------------------------------------

func _rand_point_in_disc(r: float) -> Vector2:
	var t: float = _rng.randf_range(0.0, TAU)
	var u: float = _rng.randf()
	var rr: float = r * sqrt(u)
	return Vector2(cos(t) * rr, sin(t) * rr)

func _hash_seed(q: int, r: int, off: int) -> int:
	var s := str(q, ":", r, ":", off)
	var h := 1469598103934665603
	for i in s.length():
		h = int((h ^ s.unicode_at(i)) * 1099511628211) & 0x7FFFFFFFFFFFFFFF
	return h

func _load_textures_from_dir(dir_path: String, needle: String) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if not dir_path.begins_with("res://"):
		return out
	var d := DirAccess.open(dir_path)
	if d == null:
		return out
	var files: PackedStringArray = d.get_files()
	var lower_needle: String = needle.to_lower()
	for f in files:
		var ext: String = f.get_extension().to_lower()
		if ext != "png" and ext != "jpg" and ext != "jpeg" and ext != "webp":
			continue
		if lower_needle != "" and f.to_lower().find(lower_needle) == -1:
			continue
		var p: String
		if dir_path.ends_with("/"):
			p = dir_path + f
		else:
			p = dir_path + "/" + f
		var res: Resource = ResourceLoader.load(p)
		var tex: Texture2D = res as Texture2D
		if tex:
			out.append(tex)
	return out

func _process(_dt: float) -> void:
	if not centerpiece_face_camera_y:
		return
	if _centerpiece_node == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var cpos: Vector3 = _centerpiece_node.global_transform.origin
	var dir: Vector3 = cam.global_transform.origin - cpos
	dir.y = 0.0
	if dir.length_squared() > 0.0001:
		dir = dir.normalized()
		# yaw so +Z of node points toward camera; adjust if your art faces +X
		var yaw: float = atan2(dir.x, dir.z)
		_centerpiece_node.rotation.y = yaw
