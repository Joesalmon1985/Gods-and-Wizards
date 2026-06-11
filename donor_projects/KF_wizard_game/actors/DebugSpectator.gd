extends Node3D
class_name DebugSpectator

@onready var cam: Camera3D = $Camera3D

@export var look_sens: float = 0.1
@export var speed: float = 12.0
@export var fast_mult: float = 3.0
@export var slow_mult: float = 0.3

var _yaw: float = 0.0
var _pitch: float = 0.0

func _ready() -> void:
	add_to_group("spectator")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_yaw -= ev.relative.x * look_sens * 0.01
		_pitch -= ev.relative.y * look_sens * 0.01
		_pitch = clampf(_pitch, -1.2, 1.2)
		rotation.y = _yaw
		if cam:
			cam.rotation.x = _pitch

	if ev.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(
			Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

func _process(delta: float) -> void:
	var move := Vector3.ZERO
	var basis := global_transform.basis
	var f := -basis.z
	var r := basis.x
	var u := basis.y

	if Input.is_action_pressed("move_forward"):  move += f
	if Input.is_action_pressed("move_backward"): move -= f
	if Input.is_action_pressed("move_left"):     move -= r
	if Input.is_action_pressed("move_right"):    move += r
	if Input.is_action_pressed("move_up"):       move += u
	if Input.is_action_pressed("move_down"):     move -= u

	if move != Vector3.ZERO:
		move = move.normalized()

	var mult := speed
	if Input.is_action_pressed("sprint"): mult *= fast_mult
	if Input.is_action_pressed("crouch"): mult *= slow_mult

	global_position += move * mult * delta
