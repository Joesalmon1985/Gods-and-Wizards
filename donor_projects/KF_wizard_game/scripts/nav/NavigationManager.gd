extends Node3D
class_name NavigationManager

@export var ground_y: float = 0.0
@export var ground_size_x: float = 800.0
@export var ground_size_z: float = 800.0
@export var show_floor_mesh: bool = false
@export var debug_verbose: bool = true

func _ready() -> void:
	if debug_verbose:
		print("[NavMgr] Creating flat navmesh plane at y=", ground_y)

	if not has_node("FlatNavFloor3D"):
		var floor := preload("res://scripts/nav/FlatNavFloor3D.gd").new()
		floor.name = "FlatNavFloor3D"
		floor.y = ground_y
		floor.size_x = ground_size_x
		floor.size_z = ground_size_z
		floor.mesh_visible = show_floor_mesh
		add_child(floor)
