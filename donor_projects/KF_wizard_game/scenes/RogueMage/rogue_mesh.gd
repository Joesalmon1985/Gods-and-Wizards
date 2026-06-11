extends MeshInstance3D
class_name rogue_mesh
# --- Animation speeds you can tweak in the Inspector ---
@export var fps_idle: int = 6        # Idle 3-frame loop
@export var fps_walk: int = 10       # Walk 5-frame loop

# --- Folders (using your exact structure) ---
const PATH_IDLE      := "res://assets/Rogue/Idle"
const PATH_WALK      := "res://assets/Rogue/Walk"
const PATH_ROTATION  := "res://assets/Rogue/Rotation"

# --- File name patterns (your exact names) ---
const NAME_IDLE_PREFIX       := "Idle"              # Idle1.png..Idle3.png
const NAME_WALK_PREFIX       := "Roguewalking"      # Roguewalking1.png..5.png
const NAME_ROTATE_PREFIX     := "Roguespinning"     # Roguespinning1.png..25.png

# --- Counts (your exact counts) ---
const COUNT_IDLE     := 3
const COUNT_WALK     := 5
const COUNT_ROTATION := 25

# --- State ---
enum AnimState { IDLE, WALK }
var state: int = AnimState.IDLE

# --- Storage for textures ---
var idle_frames: Array[Texture2D] = []
var walk_frames: Array[Texture2D] = []
var rotation_frames: Array[Texture2D] = []

# --- Time counters ---
var t_idle: float = 0.0
var t_walk: float = 0.0

# --- Convenience: the material we’ll swap textures on ---
var mat: StandardMaterial3D

func _ready():
	if mesh is PlaneMesh:
		(mesh as PlaneMesh).size = Vector2(6, 6)  # width = 2 units, height = 3 units
	# Grab (or create) our StandardMaterial3D
	mat = material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material_override = mat

	# Load textures once
	idle_frames     = _load_sequence(PATH_IDLE, NAME_IDLE_PREFIX, COUNT_IDLE)
	walk_frames     = _load_sequence(PATH_WALK, NAME_WALK_PREFIX, COUNT_WALK)
	rotation_frames = _load_sequence(PATH_ROTATION, NAME_ROTATE_PREFIX, COUNT_ROTATION)

	# Safety: show something even if a folder is empty
	if rotation_frames.size() > 0:
		mat.albedo_texture = rotation_frames[0]
	elif idle_frames.size() > 0:
		mat.albedo_texture = idle_frames[0]
	elif walk_frames.size() > 0:
		mat.albedo_texture = walk_frames[0]

func _process(delta: float) -> void:
	var cam = get_viewport().get_camera_3d()
	if cam:
		var dir = cam.global_transform.origin - global_transform.origin
		dir.y = 0  # ignore vertical difference
		if dir.length() > 0.001:
			look_at(global_transform.origin + dir, Vector3.UP)
			rotate_x(deg_to_rad(90)) # force it to stand up

	# Decide what to show
	match state:
		AnimState.WALK:
			if walk_frames.is_empty():
				_show_rotation_to_fake_3d(cam) # fallback
			else:
				t_walk += delta
				var i := int(t_walk * fps_walk) % walk_frames.size()
				mat.albedo_texture = walk_frames[i]
		AnimState.IDLE:
			# For best “3D look” while idle, use the 25 rotation stills
			if not rotation_frames.is_empty():
				_show_rotation_to_fake_3d(cam)
			elif not idle_frames.is_empty():
				t_idle += delta
				var j := int(t_idle * fps_idle) % idle_frames.size()
				mat.albedo_texture = idle_frames[j]

# --- Public API so other scripts can switch animations ---
@warning_ignore("shadowed_variable_base_class")
func _set_state_name(name: String) -> void:
	name = name.to_lower()
	if name == "walk":
		state = AnimState.WALK
	else:
		state = AnimState.IDLE

# --- Helpers ---
func _load_sequence(base_path: String, prefix: String, count: int) -> Array[Texture2D]:
	var arr: Array[Texture2D] = []
	for i in range(1, count + 1):
		var path := "%s/%s%d.png" % [base_path, prefix, i]
		var tex := load(path)
		if tex is Texture2D:
			arr.append(tex)
		else:
			push_warning("Missing or failed to load: " + path)
	return arr

func _show_rotation_to_fake_3d(camera: Camera3D) -> void:
	if rotation_frames.is_empty():
		return
	var idx := _get_angle_index(camera, COUNT_ROTATION)
	mat.albedo_texture = rotation_frames[idx]

func _get_angle_index(camera: Camera3D, slices: int) -> int:
	var to_cam := camera.global_transform.origin - global_transform.origin
	to_cam.y = 0.0
	if to_cam.length() == 0.0:
		return 0
	to_cam = to_cam.normalized()
	var angle := atan2(to_cam.x, to_cam.z) # radians
	var deg := rad_to_deg(angle)
	if deg < 0.0:
		deg += 360.0
	return int(round(deg / (360.0 / float(slices)))) % slices
