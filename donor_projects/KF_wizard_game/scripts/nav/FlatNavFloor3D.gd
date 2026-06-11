extends Node3D
class_name FlatNavFloor3D

@export var size_x: float = 800.0
@export var size_z: float = 800.0
@export var y: float = 0.0
@export var mesh_visible: bool = false  # don't shadow Node3D.visible

func _ready() -> void:
	# Visual mesh (optional)
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size_x, size_z)
	mesh_instance.mesh = plane
	mesh_instance.visible = mesh_visible
	mesh_instance.global_position = Vector3(0.0, y, 0.0)
	add_child(mesh_instance)

	# Navigation region + mesh created from the plane mesh
	var region := NavigationRegion3D.new()
	var navmesh := NavigationMesh.new()

	# Godot 4.4: create navmesh directly from a Mesh
	# (this avoids the NavigationServer3D parsing flags entirely)
	navmesh.create_from_mesh(plane)

	region.navigation_mesh = navmesh
	region.global_position = Vector3(0.0, y, 0.0)
	add_child(region)

	# Optional: add a collider so characters stand on it
	var sb := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size_x, 0.2, size_z)
	col.shape = shape
	sb.add_child(col)
	sb.global_position = Vector3(0.0, y, 0.0)
	add_child(sb)
	
	# --- DEBUG: navmesh sanity ---
	await get_tree().process_frame

	var world_map: RID = get_world_3d().navigation_map
	var vtx_count := 0
	var poly_count := 0
	if region.navigation_mesh:
		vtx_count = region.navigation_mesh.get_vertices().size()
	# In 4.x, this exists; if not, keep just vertices:
		if region.navigation_mesh.has_method("get_polygon_count"):
			poly_count = region.navigation_mesh.get_polygon_count()

	print("[NavFloor] y=%.2f size=(%.0f,%.0f) verts=%d polys=%d" % [y, size_x, size_z, vtx_count, poly_count])

# Try a synthetic path across the plane to prove the map is actually routing.
	var from_p := Vector3(-size_x * 0.25, y, -size_z * 0.25)
	var to_p   := Vector3( size_x * 0.25, y,  size_z * 0.25)
	var path: PackedVector3Array = NavigationServer3D.map_get_path(world_map, from_p, to_p, true)
	print("[NavFloor] test path len=", path.size(), " from=", from_p, " to=", to_p)
