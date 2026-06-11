@tool
extends Node3D
class_name ForestOctagon

## Builds a solid octagon collider and 8 visual panels around it.
## Drop this as a child of your Hex3D_Wood root (which uses HexTile3D_Base).

@export_range(0.30, 0.90, 0.01) var radius_ratio: float = 0.60  # relative to parent hex radius
@export var collider_height: float = 2.0                         # how tall the solid octagon is
@export var panel_height: float = 2.5                            # height of each forest panel
@export var panel_oversize: float = 1.10                         # make panels slightly wider than each side
@export var panel_alpha: float = 1.0                             # 0..1 transparency for panels
@export var show_collider_mesh: bool = false                     # show CSG in editor for debugging
@export var textures: Array[Texture2D] = []                      # up to 8 textures (one per side)

@export var regenerate_now: bool:
	set(value):
		if value:
			call_deferred("_build")
	get:
		return false

var _collider: CSGPolygon3D
var _panels: Node3D

func _ready() -> void:
	_ensure_nodes()
	_build()

func _ensure_nodes() -> void:
	_collider = get_node_or_null("Collider") as CSGPolygon3D
	if _collider == null:
		_collider = CSGPolygon3D.new()
		_collider.name = "Collider"
		_collider.operation = CSGShape3D.OPERATION_UNION
		_collider.use_collision = true
		add_child(_collider)

	_panels = get_node_or_null("Panels") as Node3D
	if _panels == null:
		_panels = Node3D.new()
		_panels.name = "Panels"
		add_child(_panels)

func _build() -> void:
	# Get parent hex dimensions (fallbacks if not under HexTile3D_Base)
	var parent_hex := get_parent() as HexTile3D_Base
	var R: float = 64.0 * radius_ratio
	var top_y: float = 0.4
	if parent_hex:
		R = parent_hex.radius * radius_ratio
		top_y = parent_hex.height

	# --- Collider: regular octagon extruded upward ---
	var pts: PackedVector2Array = []
	for i in range(8):
		var a := PI / 8.0 + i * PI / 4.0  # 22.5°, 67.5°, ...
		pts.append(Vector2(cos(a) * R, sin(a) * R))

	_collider.polygon = pts
	_collider.depth = collider_height
	_collider.rotation_degrees = Vector3(90, 0, 0)  # extrude vertically
	_collider.position = Vector3(0, top_y + collider_height * 0.5, 0)
	_collider.visible = show_collider_mesh  # collider is usually invisible

	# --- Visual panels: 8 quads around the octagon ---
	for c in _panels.get_children():
		c.queue_free()

	# side length of regular octagon
	var side_len := 2.0 * R * sin(PI / 8.0)
	var z_offset := R + 0.01   # tiny offset outward to avoid z-fighting with collider

	for i in range(8):
		var mi := MeshInstance3D.new()
		mi.name = "Panel_%d" % i
		var quad := QuadMesh.new()
		quad.size = Vector2(side_len * panel_oversize, panel_height)
		mi.mesh = quad

		# simple material (use texture[i] if provided)
		var mat := StandardMaterial3D.new()
		mat.flags_transparent = panel_alpha < 1.0
		mat.albedo_color = Color(1, 1, 1, panel_alpha)
		if i < textures.size() and textures[i] != null:
			mat.albedo_texture = textures[i]
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
			mat.texture_repeat = BaseMaterial3D.TEXTURE_REPEAT_ENABLED
		mi.material_override = mat

		# Place the quad upright, facing outward.
		# QuadMesh faces +Z. Rotate around Y, then push along local +Z.
		var angle := float(i) * PI / 4.0
		mi.rotation.y = angle
		mi.position = Vector3(0, top_y + panel_height * 0.5, z_offset)
		_panels.add_child(mi)
