extends Node3D
class_name Hex3D

@export var radius: float = 64.0
@export var height: float = 0.4
@export var color: Color = Color(0.7, 0.7, 0.7)

var _mesh_instance: MeshInstance3D
var _static_body: StaticBody3D

func _ready() -> void:
	if Engine.is_editor_hint():
		# Generate editor for visualization of runtime object
		_generate_runtime_objects()
	else:
		# Your existing game logic for runtime
		_generate_runtime_objects()

func _generate_runtime_objects() -> void:
	# ---- visual mesh ----
	_mesh_instance = MeshInstance3D.new()
	var arr_mesh: ArrayMesh = _hex_prism_mesh(radius, height)
	_mesh_instance.mesh = arr_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

	# ---- collision (solid) ----
	_static_body = StaticBody3D.new()
	_static_body.name = "HexBody"
	var col := CollisionShape3D.new()

	# Prefer a convex shape for performance; fall back to trimesh if needed.
	var shape: Shape3D = arr_mesh.create_convex_shape()
	if shape == null:
		shape = arr_mesh.create_trimesh_shape()
	col.shape = shape

	_static_body.add_child(col)
	add_child(_static_body)
	

func _hex_prism_mesh(r: float, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var top: float = h * 0.5
	var bot: float = -top
	var topv: Array[Vector3] = []
	var botv: Array[Vector3] = []

	# hex ring vertices
	for i in range(6):
		var a: float = PI / 6.0 + float(i) * PI / 3.0
		var x: float = cos(a) * r
		var z: float = sin(a) * r
		topv.append(Vector3(x, top, z))
		botv.append(Vector3(x, bot, z))

	# top face (fan)
	for i in range(1, 5):
		st.add_vertex(topv[0]); st.add_vertex(topv[i]); st.add_vertex(topv[i + 1])

	# bottom face (fan, flipped)
	for i in range(1, 5):
		st.add_vertex(botv[0]); st.add_vertex(botv[i + 1]); st.add_vertex(botv[i])

	# side quads (two triangles each)
	for i in range(6):
		var j: int = (i + 1) % 6
		var a1 := topv[i]; var a2 := topv[j]
		var b1 := botv[i]; var b2 := botv[j]
		st.add_vertex(a1); st.add_vertex(b1); st.add_vertex(a2)
		st.add_vertex(a2); st.add_vertex(b1); st.add_vertex(b2)

	# normals for proper lighting
	st.generate_normals()
	return st.commit()
