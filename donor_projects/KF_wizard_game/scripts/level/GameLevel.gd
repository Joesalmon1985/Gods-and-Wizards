extends Node

const AbstractWorld   := preload("res://scripts/game/AbstractWorld.gd")
const Economy         := preload("res://scripts/econ/Economy.gd")
const HumanEcoPlayer  := preload("res://scripts/econ/HumanEconomyPlayer.gd")
const MapHud          := preload("res://scripts/ui/MapHud.gd")


var eco: Economy
var _abs: AbstractWorld
var debug_verbose = true
var hide_2Dmap = false
var FactionCount = 6

## --- TEMP: brute wander toggle ---
#@export var force_brute_move: bool = true   # flip to true to ignore physics and see motion
#@export var move_speed: float = 3.5         # reuse if you already have it
#var _wander_timer: float = 0.0
#const WANDER_INTERVAL := 2.5
#const WANDER_RADIUS   := 22.0
#var debug_verbose: bool = true


@onready var world2d: Node2D = $World2D if has_node("World2D") else null
@onready var world3d: Node3D = $World3D if has_node("World3D") else null

func _ready() -> void:
	_spawn_encounter_manager()
	_ensure_input_actions()

	# Hide raw 2D board so it doesn't flash in top-left
	if hide_2Dmap:
		if world2d:
			world2d.visible = false

	# 1) Read options
	var radius: int
	var ratios: Dictionary
	var opts: Array = _read_options()      # <-- get the array
	radius = int(opts[0])                  # <-- unpack manually
	ratios = opts[1] as Dictionary

	# 2) Build abstract first (no dependency on nodes)
	_abs = AbstractWorld.new()
	_abs.hex_size = 64.0
	_abs.hex_height_3d = 0.5
	_abs.ground_y = 0.0
	_abs.build_hex_ring(radius, ratios)
	_abs._assign_chits_for_radius2()
	_ensure_world_nodes()

	# 3) Attach views AFTER building abstract (this renders everything)
	_abs.attach_views(world2d, world3d)
	_ensure_characters_root()
#
	## connect signals as needed for HUD/text log
	#if debug_verbose:
		#eco.dice_rolled.connect(func(total:int): print("Dice:", total))
		#eco.phase_changed.connect(func(p:String): print("Phase:", p))

	## 4) floor, light
	#_spawn_floor_with_collision()
	#_spawn_player()
	_add_light_and_failsafe_camera()
	_add_hud()
	if debug_verbose:print("[GameLevel] ready; abstract=", _abs.hexes.size(), " hexes")
		# 5) START ECONOMY (places all setup pieces now)
	eco = Economy.new()
	add_child(eco)
	eco.start(_abs, FactionCount)  # 6 AI players
	# (optional) connect to see what's happening
	eco.setup_placed.connect(func(pid:int,_v:Vector2i,_e:Vector2i):
		if debug_verbose: print("[GameLevel] setup placed by P", pid))
		
		## Debugging inventories
	#eco.inventory_changed.connect(func(pid:int, inv:Dictionary):
		#if debug_verbose:
			#print("[GameLevel INV] P%d -> WOOD:%d BRICK:%d WHEAT:%d SHEEP:%d ORE:%d" % [
				#pid, inv["WOOD"], inv["BRICK"], inv["WHEAT"], inv["SHEEP"], inv["ORE"]
			#])
		#)

	if debug_verbose:print("[GameLevel] reached end of Game Level Set up")



func _read_options() -> Array:
	var cfg := ConfigFile.new()
	#var err := cfg.load("user://game_options.cfg")   # <-- use a real variable (or just call)
	## you can print err if you want: print("cfg load err=", err)
	if debug_verbose: print("[GameLevel] ", cfg, cfg.get_value("board", "hex_radius"))

	var radius := int(cfg.get_value("board","hex_radius", 4))
	var raw := {
		"WOOD":  float(cfg.get_value("ratios","WOOD",  4.0)),
		"BRICK": float(cfg.get_value("ratios","BRICK", 3.0)),
		"ORE":   float(cfg.get_value("ratios","ORE",   3.0)),
		"WHEAT": float(cfg.get_value("ratios","WHEAT", 4.0)),
		"SHEEP": float(cfg.get_value("ratios","SHEEP", 4.0)),
		"DESERT":float(cfg.get_value("ratios","DESERT",0.5))
	}
	var total := 0.0
	for v in raw.values():
		total += v
	var ratios: Dictionary = {}
	if total <= 0.0:
		var keys := raw.keys()
		var eq := 1.0 / float(keys.size())
		for k in keys:
			ratios[k] = eq
	else:
		for k in raw.keys():
			ratios[k] = raw[k] / total
	if debug_verbose: print("[GameLevel] options read", [max(1, radius), ratios])
	return [max(1, radius), ratios]

func _ensure_world_nodes() -> void:
	if world2d == null:
		world2d = Node2D.new()
		world2d.name = "World2D"
		add_child(world2d)
	if world3d == null:
		world3d = Node3D.new()
		world3d.name = "World3D"
		add_child(world3d)
	if not world3d.has_node("NavigationManager"):
		var nav := preload("res://scripts/nav/NavigationManager.gd").new()
		nav.name = "NavigationManager"
		nav.ground_y = 0.41  # match your settlement Y from logs
		world3d.add_child(nav)

# ---------- input ----------
func _ensure_input_actions() -> void:

	_add_action_once("toggle_hud", KEY_H)
	

func _add_action_once(name: String, key_a: int, key_b: int = -1) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
		var ev1 := InputEventKey.new()
		ev1.keycode = key_a
		InputMap.action_add_event(name, ev1)
		if key_b != -1:
			var ev2 := InputEventKey.new()
			ev2.keycode = key_b
			InputMap.action_add_event(name, ev2)

# ---------- world content ----------
func _spawn_floor_with_collision() -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.24, 0.26)
	mesh.material_override = mat
	world3d.add_child(mesh)

	var body := StaticBody3D.new()
	body.name = "FloorBody"
	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 0.5, 60)
	shape_node.shape = box
	body.add_child(shape_node)
	world3d.add_child(body)


func _add_light_and_failsafe_camera() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 45, 0)
	world3d.add_child(sun)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 6, 10)
	cam.look_at(Vector3(0, 0, 0), Vector3.UP)
	add_child(cam)
	cam.current = false

func _add_hud() -> void:
	var hud := MapHud.new()
	hud.name = "MapHud"
	add_child(hud)
	hud.capture_board(world2d)    # ← tell HUD exactly which Node2D to use
	hud.set_enabled(true)        # optional: keep locked until you unlock later


func _ensure_characters_root() -> void:
	if world3d == null:
		return
	if not world3d.has_node("CharactersRoot"):
		var chars := Node3D.new()
		chars.name = "CharactersRoot"
		world3d.add_child(chars)

func _spawn_encounter_manager() -> void:
	var packed := load("res://scenes/encounter_manager.tscn") as PackedScene
	var inst := packed.instantiate()
	add_child(inst)
	var player_node := get_tree().get_first_node_in_group("player")
	if player_node:
		inst.human_player_path = inst.get_path_to(player_node)
