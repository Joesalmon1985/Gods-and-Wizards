# res://scripts/ui/MainMenuBuilder.gd
extends Control
## Godot 4.4.1 — programmatic menu with clean alignment + big Start button.
var debug_verbose = true


@export var game_scene_path: String = "res://scenes/GameLevel.tscn"  # change to your level scene
#@export var game_scene_path: String = "res://scenes/main.tscn"  # change to your level scene

# Defaults
@export var default_hex_radius := 2
@export var default_factions  := 4
@export var default_ratios := {
	"WOOD": 4.0, "BRICK": 3.0, "ORE": 3.0, "WHEAT": 4.0, "SHEEP": 4.0, "DESERT": 1.0
}

# Runtime refs
var _spins := {}     # name -> SpinBox
var _error: Label
var _start_btn: Button
var _rand_btn: Button

func _ready() -> void:
	randomize()
	_build_ui()
	_start_btn.grab_focus()

# ---------- small helpers ----------
func _add_row(vlabels: VBoxContainer, vinputs: VBoxContainer, label_text:String, name:String, min_val:float, max_val:float, step:float, value:float) -> void:
	var lab := Label.new()
	lab.text = label_text
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.custom_minimum_size = Vector2(260, 0)  # keep labels aligned
	vlabels.add_child(lab)

	var sp := SpinBox.new()
	sp.name = name
	sp.min_value = min_val
	sp.max_value = max_val
	sp.step = step
	sp.value = value
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.custom_minimum_size = Vector2(180, 0)
	vinputs.add_child(sp)
	_spins[name] = sp

# ---------------- UI builder ----------------
func _build_ui() -> void:
	# Make sure we don't accumulate duplicate UI if this is re-run
	for c in get_children():
		c.queue_free()

	# Fullscreen centering container
	var center := CenterContainer.new()
	center.anchor_left = 0; center.anchor_top = 0; center.anchor_right = 1; center.anchor_bottom = 1
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(center)

	# Panel + margin
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(640, 560)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 18)
	margin.add_child(root_vbox)

	# Title
	var title := Label.new()
	title.text = "New Game Setup"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root_vbox.add_child(title)

	# Form (two columns)
	var form := HBoxContainer.new()
	form.add_theme_constant_override("separation", 16)
	root_vbox.add_child(form)

	var vlabels := VBoxContainer.new()
	var vinputs := VBoxContainer.new()
	vlabels.add_theme_constant_override("separation", 10)
	vinputs.add_theme_constant_override("separation", 10)
	vlabels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vinputs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(vlabels)
	form.add_child(vinputs)

	# Core settings
	_add_row(vlabels, vinputs, "Hex Radius (2 = 19 tiles)", "RadiusSpin", 1, 10, 1, default_hex_radius)
	_add_row(vlabels, vinputs, "Number of Factions (2–6)", "FactionsSpin", 2, 6, 1, default_factions)

	# Ratios
	_add_row(vlabels, vinputs, "Wood weight",  "WoodSpin",   0, 10, 1, float(default_ratios.get("WOOD",  4.0)))
	_add_row(vlabels, vinputs, "Brick weight", "BrickSpin",  0, 10, 1, float(default_ratios.get("BRICK", 3.0)))
	_add_row(vlabels, vinputs, "Ore weight",   "OreSpin",    0, 10, 1, float(default_ratios.get("ORE",   3.0)))
	_add_row(vlabels, vinputs, "Wheat weight", "WheatSpin",  0, 10, 1, float(default_ratios.get("WHEAT", 4.0)))
	_add_row(vlabels, vinputs, "Sheep weight", "SheepSpin",  0, 10, 1, float(default_ratios.get("SHEEP", 4.0)))
	_add_row(vlabels, vinputs, "Desert weight","DesertSpin", 0, 10, 1, float(default_ratios.get("DESERT",1.0)))

	# Buttons row
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_child(buttons)

	_rand_btn = Button.new()
	_rand_btn.text = "Randomize Ratios"
	_rand_btn.custom_minimum_size = Vector2(180, 44)
	buttons.add_child(_rand_btn)

	_start_btn = Button.new()
	_start_btn.text = "▶ Start Game"
	_start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_start_btn.custom_minimum_size = Vector2(260, 48)
	buttons.add_child(_start_btn)

	# Status line
	_error = Label.new()
	_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error.add_theme_font_size_override("font_size", 16)
	_error.modulate = Color(1, 0.3, 0.3, 1)
	_error.text = ""
	root_vbox.add_child(_error)

	# Connect
	_rand_btn.pressed.connect(_on_randomize)
	_start_btn.pressed.connect(_on_start)

# ---------------- Actions ----------------
func _on_randomize() -> void:
	var keys := ["WoodSpin","BrickSpin","OreSpin","WheatSpin","SheepSpin","DesertSpin"]
	var all_zero := true
	for k in keys:
		var v := randi_range(0, 10)
		_spins[k].value = v
		if v != 0:
			all_zero = false
	if all_zero:
		_spins["WoodSpin"].value = 1

func _on_start() -> void:
	_error.text = ""
	print("[Menu] Start pressed")

	var r := int(_spins["RadiusSpin"].value)
	var f := int(_spins["FactionsSpin"].value)

	if f < 2 or f > 6:
		_error.text = "Factions must be between 2 and 6."
		print("[Menu] Invalid factions:", f)
		return

	var ratios := {
		"WOOD":  float(_spins["WoodSpin"].value),
		"BRICK": float(_spins["BrickSpin"].value),
		"ORE":   float(_spins["OreSpin"].value),
		"WHEAT": float(_spins["WheatSpin"].value),
		"SHEEP": float(_spins["SheepSpin"].value),
		"DESERT":float(_spins["DesertSpin"].value)
	}

	# Write config
	var cfg := ConfigFile.new()
	cfg.set_value("board", "hex_radius", r)
	cfg.set_value("board", "factions", f)
	for k in ratios.keys():
		cfg.set_value("ratios", k, ratios[k])

	var err := cfg.save("user://game_options.cfg")
	print("[Menu] Save cfg ->", OS.get_user_data_dir(), "err=", err)
	if err != OK:
		_error.text = "Failed to write user://game_options.cfg"
		return

	# Load level
	print("[Menu] Loading:", game_scene_path)
	if not ResourceLoader.exists(game_scene_path):
		_error.text = "Game scene not found: " + game_scene_path
		print("[Menu] Scene missing at path")
		return

	get_tree().change_scene_to_file(game_scene_path)

# ---------------- Config I/O ----------------
func _write_config(radius:int, factions:int, ratios:Dictionary) -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("board", "hex_radius", radius)
	cfg.set_value("board", "factions", factions)
	for k in ratios.keys():
		cfg.set_value("ratios", k, float(ratios[k]))
	return cfg.save("user://game_options.cfg") == OK
