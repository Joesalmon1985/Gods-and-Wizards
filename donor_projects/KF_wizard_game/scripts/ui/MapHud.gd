extends CanvasLayer
class_name MapHud
## Toggleable, centered overlay for World2D (press H by default).

@export var toggle_action := "toggle_hud"
@export var hud_scale := 0.8                   # overall scale for the 2D board in HUD
@export var dim_background := true
@export var dim_color := Color(0,0,0,0.35)

var _world2d: Node2D            # your existing World2D (reparented into HUD)
var _holder: Node2D             # positioned at the center of the screen
var _root: Control              # full-screen control, just to host the dimmer
var _dimmer: ColorRect

var _enabled := true

func set_enabled(v: bool) -> void:
	_enabled = v
	visible = false

func capture_board(w2d: Node2D) -> void:
	_world2d = w2d
	if _world2d == null:
		push_warning("[MapHud] capture_board got null World2D"); return
	if _world2d.get_parent(): _world2d.get_parent().remove_child(_world2d)
	if _holder == null:
		_holder = Node2D.new(); add_child(_holder)
	_holder.add_child(_world2d)
	_world2d.visible = true
	visible = false
	_recenter_content(); _update_layout()

func _unhandled_input(e: InputEvent) -> void:
	if not _enabled: return
	if e.is_action_pressed(toggle_action):
		visible = not visible
		if visible: _recenter_content(); _update_layout()


func _ready() -> void:
	layer = 50

	# Fullscreen root control (for dimmer)
	_root = Control.new()
	add_child(_root)
	_root.anchor_left = 0; _root.anchor_top = 0; _root.anchor_right = 1; _root.anchor_bottom = 1
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if dim_background:
		_dimmer = ColorRect.new()
		_dimmer.color = dim_color
		_dimmer.anchor_left = 0; _dimmer.anchor_top = 0; _dimmer.anchor_right = 1; _dimmer.anchor_bottom = 1
		_root.add_child(_dimmer)

	# Holder is a Node2D we will place at the viewport center
	_holder = Node2D.new()
	_holder.name = "HudMapHolder"
	add_child(_holder)

	# Find + reparent the level's World2D under the holder
	var level := get_tree().current_scene
	_world2d = level.get_node_or_null("World2D")
	if _world2d == null:
		push_warning("[MapHud] No World2D found; HUD disabled.")
		visible = false
		return

	if _world2d.get_parent():
		_world2d.get_parent().remove_child(_world2d)
	_holder.add_child(_world2d)

	visible = false          # start hidden; press H to show
	_recenter_content()      # center board around its own content
	_update_layout()         # center on screen
	get_viewport().size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	if visible:
		_update_layout()

# -------- layout helpers --------
func _update_layout() -> void:
	# Put holder at the exact viewport center; World2D itself is already
	# offset so its content center is at (0,0), so this combo centers it on screen.
	var vp := get_viewport().get_visible_rect().size
	_holder.position = vp * 0.5
	_world2d.scale = Vector2(hud_scale, hud_scale)

func _recenter_content() -> void:
	# Compute a loose AABB over Node2D children and shift so its center is (0,0)
	if _world2d == null:
		return
	var has_any := false
	var minv := Vector2(INF, INF)
	var maxv := Vector2(-INF, -INF)

	for n in _world2d.get_children():
		if n is Node2D:
			var p: Vector2 = (n as Node2D).position
			var r := 16.0
			if "size" in n:
				r = float(n.get("size"))
			minv.x = min(minv.x, p.x - r); minv.y = min(minv.y, p.y - r)
			maxv.x = max(maxv.x, p.x + r); maxv.y = max(maxv.y, p.y + r)
			has_any = true

	if not has_any:
		_world2d.position = Vector2.ZERO
		return

	var center := (minv + maxv) * 0.5
	_world2d.position = -center
