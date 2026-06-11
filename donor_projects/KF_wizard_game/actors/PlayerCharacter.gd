extends Character3D
class_name PlayerCharacter

var _input_enabled: bool = true

func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if enabled:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



func face_target(target: Node3D, duration: float = 0.4) -> void:
	if target == null:
		return
	var to := target.global_transform.origin - global_transform.origin
	to.y = 0.0
	if to.length() < 0.001:
		return
	var desired_yaw := atan2(to.x, to.z)

	# tween player yaw smoothly
	var tw := create_tween()
	tw.tween_property(self, "rotation:y", desired_yaw, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

@onready var cam: Camera3D = $Camera3D

@onready var colshape: CollisionShape3D = get_node_or_null("CollisionShape3D")

@export_group("Move")
@export var walk_speed: float = 10.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var air_control: float = 0.3

@export_group("Look")
@export var look_sens: float = 0.12
@export var min_pitch_rad: float = deg_to_rad(-85.0)
@export var max_pitch_rad: float = deg_to_rad(85.0)

const CAP_RADIUS := 0.45
const CAP_HEIGHT := 1.30   # total height = CAP_HEIGHT + 2*CAP_RADIUS
const FOOT := (CAP_HEIGHT * 0.5) + CAP_RADIUS

var _yaw: float = 0.0
var _pitch: float = 0.0

func _ready() -> void:
	self.debug_verbose = true ##setting debug verbose for PlayerCharacter
	# groups
	if not is_in_group("player"): add_to_group("player")
	if not is_in_group("encounter_participant"): add_to_group("encounter_participant")
	if not is_in_group("player"): add_to_group("player")
	if is_in_group("npc"): remove_from_group("npc")
	# ensure collision exists
	_ensure_collision()

	# sensible spawn height just above ground
	if global_position.y < FOOT + 0.1:
		global_position.y = FOOT + 0.1

	# camera at eye height
	if cam and cam.position.y < FOOT * 0.9:
		cam.position.y = FOOT * 0.9

	# mouse-lock for mouselook
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if debug_verbose: print("[PlayerCharacter] Creating character")
	get_tree().call_group_flags(
		SceneTree.GROUP_CALL_DEFERRED,
		"encounter_manager",
		"register_human_player",
		self
	)


func _ensure_collision() -> void:
	if colshape == null:
		colshape = CollisionShape3D.new()
		colshape.name = "CollisionShape3D"
		add_child(colshape)

	if colshape.shape == null or not (colshape.shape is CapsuleShape3D):
		var cap := CapsuleShape3D.new()
		cap.radius = CAP_RADIUS
		cap.height = CAP_HEIGHT
		colshape.shape = cap

	# make sure we collide with the ground (usually on layer 1)
	collision_layer = 1
	collision_mask = 1

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_yaw -= ev.relative.x * look_sens * 0.01
		_pitch -= ev.relative.y * look_sens * 0.01
		_pitch = clampf(_pitch, min_pitch_rad, max_pitch_rad)
		rotation.y = _yaw
		if cam: cam.rotation.x = _pitch

	if ev.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

func _physics_process(delta: float) -> void:
	if not _input_enabled:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	# gravity
	var g := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	if not is_on_floor():
		velocity.y -= g * delta

	# input vector (WASD) on XZ plane
	var iv := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back")  - Input.get_action_strength("move_forward")
	)
	if iv.length() > 1.0:
		iv = iv.normalized()

	# move in local space (respect current yaw)
	var dir := (transform.basis * Vector3(iv.x, 0.0, iv.y))
	dir.y = 0.0
	if dir.length() > 0.0:
		dir = dir.normalized()

	var speed := (sprint_speed if Input.is_action_pressed("sprint") else walk_speed)
	var wish := dir * speed

	if is_on_floor():
		velocity.x = wish.x
		velocity.z = wish.z
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		velocity.x = lerp(velocity.x, wish.x, air_control)
		velocity.z = lerp(velocity.z, wish.z, air_control)

	move_and_slide()
