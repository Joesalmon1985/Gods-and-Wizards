@tool
extends Node3D
class_name HexTile3D_Base

@export var radius: float = 64.0
@export var height: float = 0.4

@export_enum("WOOD","BRICK","ORE","WHEAT","SHEEP","DESERT") var resource: String = "DESERT"
@export var axial_q: int = 0
@export var axial_r: int = 0
@export var seed_offset: int = 0

@export_group("Props")
@export var prop_scenes: Array[PackedScene] = []
@export var min_count: int = 2
@export var max_count: int = 4
@export var min_scale: float = 0.9
@export var max_scale: float = 1.2
@export_range(0.0, 1.0, 0.01) var fill: float = 0.82

@export_group("Editor")
@export var show_outline: bool = false
@export var regenerate_now: bool:
	set(value):
		if value:
			call_deferred("_rebuild")
	get:
		return false

var _rng := RandomNumberGenerator.new()
var _ground: MeshInstance3D
var _collider: StaticBody3D
var _props_root: Node3D
var _outline: MeshInstance3D

func _ready() -> void:
	_ensure_nodes()
	_rebuild()

func _ensure_nodes() -> void:
	_ground = get_node_or_null("Ground") as MeshInstance3D
	if _ground == null:
		_ground = MeshInstance3D.new()
		_ground.name = "Ground"
		add_child(_ground)

	_collider = get_node_or_null("Collider") as StaticBody3D
	if _collider == null:
		_collider = StaticBody3D.new()
		_collider.name = "Collider"
		var cs := CollisionShape3D.new()
		cs.name = "Shape"
		_collider.add_child(cs)
		add_child(_collider)

	_props_root = get_node_or_null("Props") as Node3D
	if _props_root == null:
		_props_root = Node3D.new()
		_props_root.name = "Props"
		add_child(_props_root)

	_outline = get_node_or_null("Outline") as MeshInstance3D
	if _outline == null:
		_outline = MeshInstance3D.new()
		_outline.name = "Outline"
		add_child(_outline)

func _rebuild() -> void:
	_update_seed()
	_build_hex_mesh()
	_build_collider()
	_scatter_props()
	_draw_outline()

func _update_seed() -> void:
	var s := str(axial_q, ":", axial_r, ":", resource, ":", seed_offset)
	var h := 1469598103934665603
	for i in s.length():
		h = int((h ^ s.unicode_at(i)) * 1099511628211) & 0x7FFFFFFFFFFFFFFF
	_rng.seed = h

func _build_hex_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var top: Array[Vector3] = []
	var bot: Array[Vector3] = []
	for i in range(6):
		var a := PI/6.0 + i * PI/3.0
		var x := cos(a) * radius
		var z := sin(a) * radius
		top.append(Vector3(x, height, z))
		bot.append(Vector3(x, 0.0, z))

	for i in range(1, 5):
		st.add_vertex(top[0]); st.add_vertex(top[i]); st.add_vertex(top[i+1])
	for i in range(1, 5):
		st.add_vertex(bot[0]); st.add_vertex(bot[i+1]); st.add_vertex(bot[i])

	for i in range(6):
		var j := (i + 1) % 6
		st.add_vertex(top[i]); st.add_vertex(bot[i]); st.add_vertex(top[j])
		st.add_vertex(top[j]); st.add_vertex(bot[i]); st.add_vertex(bot[j])

	st.generate_normals()
	var mesh := st.commit()

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _resource_color(resource)
	mesh.surface_set_material(0, mat)

	_ground.mesh = mesh

func _build_collider() -> void:
	var cs := _collider.get_node("Shape") as CollisionShape3D
	var cyl := CylinderShape3D.new()
	cyl.height = height
	cyl.radius = radius * 0.9
	cs.shape = cyl
	_collider.position = Vector3(0.0, height * 0.5, 0.0)

func _scatter_props() -> void:
	for c in _props_root.get_children():
		c.queue_free()

	var n := 0
	if min_count <= max_count:
		n = _rng.randi_range(min_count, max_count)
	if n <= 0 and prop_scenes.is_empty():
		return

	var r_in: float = radius * 0.8660254 * clamp(fill, 0.0, 1.0)
	var placed_pts: Array[Vector2] = []
	var min_sep := radius * 0.18

	for i in range(n):
		var tries := 0
		var p2 := Vector2.ZERO
		while true:
			tries += 1
			p2 = _rand_point_in_disc(r_in)
			var ok := true
			for q in placed_pts:
				if q.distance_to(p2) < min_sep:
					ok = false
					break
			if ok or tries > 20:
				break
		placed_pts.append(p2)

		var scene: PackedScene = null
		if prop_scenes.size() > 0:
			scene = prop_scenes[_rng.randi_range(0, prop_scenes.size() - 1)]

		var node: Node3D = null
		if scene:
			node = scene.instantiate() as Node3D
		else:
			node = _make_placeholder_prop()

		node.position = Vector3(p2.x, height + 0.02, p2.y)
		node.rotation.y = _rng.randf_range(-PI, PI)
		var s := _rng.randf_range(min_scale, max_scale)
		node.scale = Vector3.ONE * s
		_props_root.add_child(node)

func _draw_outline() -> void:
	if not show_outline:
		_outline.mesh = null
		return
	var li := ImmediateMesh.new()
	li.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(7):
		var a := PI/6.0 + (i % 6) * PI/3.0
		var x := cos(a) * radius
		var z := sin(a) * radius
		li.surface_add_vertex(Vector3(x, height + 0.01, z))
	li.surface_end()
	_outline.mesh = li

func _resource_color(res: String) -> Color:
	match res:
		"WOOD":  return Color(0.18, 0.55, 0.24)
		"BRICK": return Color(0.7, 0.25, 0.2)
		"ORE":   return Color(0.35, 0.35, 0.45)
		"WHEAT": return Color(0.95, 0.85, 0.35)
		"SHEEP": return Color(0.80, 0.95, 0.80)
		"DESERT":return Color(0.75, 0.65, 0.45)
		_:       return Color(0.6, 0.6, 0.6)

func _rand_point_in_disc(r: float) -> Vector2:
	var t := _rng.randf_range(0.0, TAU)
	var u := _rng.randf()
	var rr := r * sqrt(u)
	return Vector2(cos(t) * rr, sin(t) * rr)

func _make_placeholder_prop() -> Node3D:
	var n := Node3D.new()
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = 0.15
	cyl.height = 1.2
	trunk.mesh = cyl
	trunk.position = Vector3(0, cyl.height * 0.5, 0)
	var canopy := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.5
	canopy.mesh = sph
	canopy.position = Vector3(0, cyl.height + 0.4, 0)
	n.add_child(trunk)
	n.add_child(canopy)
	return n
