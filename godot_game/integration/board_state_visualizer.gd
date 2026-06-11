class_name BoardStateVisualizer
extends Node3D

const HEX_RADIUS := 0.42
const NODE_MARKER_HEIGHT := 0.12
const CITY_HEIGHT := 0.55
const HERO_HEIGHT := 0.45
const DEMON_HEIGHT := 0.35

var _node_positions: Dictionary = {}


func sync_from_session(session: BotGameSession) -> void:
	if session == null:
		return
	var snapshot := BoardWorldMapper.build_snapshot(session.state, session.events)
	_rebuild(snapshot)


func _rebuild(snapshot: Dictionary) -> void:
	_clear_generated()
	_node_positions = _index_node_positions(snapshot.get("nodes", []))
	_build_hexes(snapshot.get("hexes", []))
	_build_edges(snapshot.get("edges", []))
	_build_node_markers(snapshot.get("nodes", []), snapshot.get("cities", []))
	_build_cities(snapshot.get("cities", []))
	_build_heroes(snapshot.get("heroes", []))
	_build_demons(snapshot.get("demons", []))


func _index_node_positions(nodes: Array) -> Dictionary:
	var lookup := {}
	for entry in nodes:
		lookup[entry.get("id", "")] = _vec3_from_dict(entry.get("world", {}))
	return lookup


func _clear_generated() -> void:
	for child in get_children():
		child.queue_free()


func _build_hexes(hexes: Array) -> void:
	for entry in hexes:
		var world := _vec3_from_dict(entry.get("world", {}))
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Hex_%s" % entry.get("id", "")
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = HEX_RADIUS
		cylinder.bottom_radius = HEX_RADIUS
		cylinder.height = 0.08
		var material := StandardMaterial3D.new()
		var chance: int = entry.get("max_production_chance", 0)
		material.albedo_color = Color(0.35, 0.45 + chance * 0.02, 0.25, 1.0)
		cylinder.material = material
		mesh_instance.mesh = cylinder
		mesh_instance.position = world + Vector3(0, 0.04, 0)
		add_child(mesh_instance)


func _build_edges(edges: Array) -> void:
	for entry in edges:
		var from_pos := _vec3_from_dict(entry.get("world_a", {})) + Vector3(0, 0.1, 0)
		var to_pos := _vec3_from_dict(entry.get("world_b", {})) + Vector3(0, 0.1, 0)
		var has_road: bool = entry.get("has_road", false)
		var owner_id: int = entry.get("road_owner_id", -1)
		var mesh_instance := _make_edge_bar(from_pos, to_pos, has_road, owner_id)
		mesh_instance.name = "Edge_%s" % entry.get("id", "")
		add_child(mesh_instance)


func _build_node_markers(nodes: Array, cities: Array) -> void:
	var city_nodes := {}
	for city in cities:
		city_nodes[city.get("node_id", "")] = true
	for entry in nodes:
		var node_id: String = entry.get("id", "")
		if city_nodes.has(node_id):
			continue
		var world := _vec3_from_dict(entry.get("world", {}))
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Node_%s" % node_id
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.08
		cylinder.bottom_radius = 0.08
		cylinder.height = NODE_MARKER_HEIGHT
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.75, 0.75, 0.75, 1.0)
		cylinder.material = material
		mesh_instance.mesh = cylinder
		mesh_instance.position = world + Vector3(0, NODE_MARKER_HEIGHT * 0.5 + 0.08, 0)
		add_child(mesh_instance)


func _build_cities(cities: Array) -> void:
	for entry in cities:
		var node_id: String = entry.get("node_id", "")
		if not _node_positions.has(node_id):
			continue
		var world: Vector3 = _node_positions[node_id]
		var player_id: int = entry.get("player_id", -1)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = entry.get("id", "City")
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.16
		cylinder.bottom_radius = 0.2
		cylinder.height = CITY_HEIGHT
		var material := StandardMaterial3D.new()
		material.albedo_color = BoardWorldMapper.player_color(player_id)
		cylinder.material = material
		mesh_instance.mesh = cylinder
		mesh_instance.position = world + Vector3(0, CITY_HEIGHT * 0.5 + 0.08, 0)
		add_child(mesh_instance)


func _build_heroes(heroes: Array) -> void:
	for entry in heroes:
		var node_id: String = entry.get("node_id", "")
		if not _node_positions.has(node_id):
			continue
		var world: Vector3 = _node_positions[node_id]
		var player_id: int = entry.get("player_id", -1)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = entry.get("id", "Hero")
		var box := BoxMesh.new()
		box.size = Vector3(0.22, HERO_HEIGHT, 0.22)
		var material := StandardMaterial3D.new()
		material.albedo_color = BoardWorldMapper.player_color(player_id).lightened(0.15)
		box.material = material
		mesh_instance.mesh = box
		mesh_instance.position = world + Vector3(0.18, HERO_HEIGHT * 0.5 + 0.12, 0.18)
		add_child(mesh_instance)


func _build_demons(demons: Array) -> void:
	for entry in demons:
		var node_id: String = entry.get("node_id", "")
		if not _node_positions.has(node_id):
			continue
		var world: Vector3 = _node_positions[node_id]
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = entry.get("id", "Demon")
		var sphere := SphereMesh.new()
		sphere.radius = 0.12 + 0.02 * float(entry.get("count", 1))
		sphere.height = sphere.radius * 2.0
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.45, 0.05, 0.08, 1.0)
		sphere.material = material
		mesh_instance.mesh = sphere
		mesh_instance.position = world + Vector3(-0.18, DEMON_HEIGHT + 0.12, -0.18)
		add_child(mesh_instance)


func _make_edge_bar(from_pos: Vector3, to_pos: Vector3, has_road: bool, owner_id: int) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var direction := to_pos - from_pos
	var length := direction.length()
	if length <= 0.001:
		return mesh_instance
	var box := BoxMesh.new()
	box.size = Vector3(0.05 if not has_road else 0.08, 0.04, length)
	var material := StandardMaterial3D.new()
	if has_road:
		material.albedo_color = BoardWorldMapper.player_color(owner_id)
	else:
		material.albedo_color = Color(0.35, 0.35, 0.35, 0.8)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if not has_road else BaseMaterial3D.TRANSPARENCY_DISABLED
	box.material = material
	mesh_instance.mesh = box
	mesh_instance.position = from_pos.lerp(to_pos, 0.5)
	mesh_instance.look_at(to_pos, Vector3.UP)
	return mesh_instance


func _vec3_from_dict(data: Dictionary) -> Vector3:
	return Vector3(float(data.get("x", 0.0)), float(data.get("y", 0.0)), float(data.get("z", 0.0)))
