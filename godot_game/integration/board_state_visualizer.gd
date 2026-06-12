class_name BoardStateVisualizer
extends Node3D

var _node_positions: Dictionary = {}


func sync_from_session(session: BotGameSession) -> void:
	if session == null:
		return
	var snapshot := BoardWorldMapper.build_snapshot(session.state, session.events)
	_rebuild(snapshot, session)


func _rebuild(snapshot: Dictionary, session: BotGameSession) -> void:
	_clear_generated()
	_node_positions = _index_node_positions(snapshot.get("nodes", []))
	_build_hexes(snapshot.get("hexes", []))
	_build_edges(snapshot.get("edges", []))
	_build_node_markers(snapshot.get("nodes", []), snapshot.get("cities", []))
	_build_cities(snapshot.get("cities", []))
	_build_heroes(snapshot.get("heroes", []))
	_build_demons(snapshot.get("demons", []))
	_build_development_indicators(session)


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
		cylinder.top_radius = WorldPresentationScale.hex_radius()
		cylinder.bottom_radius = WorldPresentationScale.hex_radius()
		cylinder.height = WorldPresentationScale.HEX_SIZE * 0.005
		var material := StandardMaterial3D.new()
		var chance: int = entry.get("max_production_chance", 0)
		material.albedo_color = Color(0.35, 0.45 + chance * 0.02, 0.25, 1.0)
		cylinder.material = material
		mesh_instance.mesh = cylinder
		mesh_instance.position = world + Vector3(0, cylinder.height * 0.5, 0)
		add_child(mesh_instance)
		if entry.get("dominant_resource", "") == "wood":
			_add_prop_billboard(world, _forest_prop_id(entry), "Prop_%s" % entry.get("id", ""))


func _forest_prop_id(entry: Dictionary) -> String:
	var hex_id: String = str(entry.get("id", "0"))
	var props := [
		"forest_cairn_t1_c1",
		"forest_cairn_t1_c2",
		"forest_cairn_t2_c1",
		"forest_cairn_t2_c3",
	]
	return props[abs(hex_id.hash()) % props.size()]


func _build_edges(edges: Array) -> void:
	for entry in edges:
		var from_pos := _vec3_from_dict(entry.get("world_a", {})) + Vector3(0, WorldPresentationScale.HEX_SIZE * 0.006, 0)
		var to_pos := _vec3_from_dict(entry.get("world_b", {})) + Vector3(0, WorldPresentationScale.HEX_SIZE * 0.006, 0)
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
		cylinder.top_radius = WorldPresentationScale.HEX_SIZE * 0.005
		cylinder.bottom_radius = WorldPresentationScale.HEX_SIZE * 0.005
		cylinder.height = WorldPresentationScale.node_marker_height()
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.75, 0.75, 0.75, 1.0)
		cylinder.material = material
		mesh_instance.mesh = cylinder
		mesh_instance.position = world + Vector3(0, cylinder.height * 0.5 + WorldPresentationScale.HEX_SIZE * 0.005, 0)
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
		cylinder.top_radius = WorldPresentationScale.HEX_SIZE * 0.01
		cylinder.bottom_radius = WorldPresentationScale.HEX_SIZE * 0.0125
		cylinder.height = WorldPresentationScale.city_height()
		var material := StandardMaterial3D.new()
		material.albedo_color = BoardWorldMapper.player_color(player_id)
		cylinder.material = material
		mesh_instance.mesh = cylinder
		mesh_instance.position = world + Vector3(0, cylinder.height * 0.5 + WorldPresentationScale.HEX_SIZE * 0.005, 0)
		add_child(mesh_instance)


func _build_heroes(heroes: Array) -> void:
	for entry in heroes:
		var node_id: String = entry.get("node_id", "")
		if not _node_positions.has(node_id):
			continue
		var world: Vector3 = _node_positions[node_id]
		var offset := Vector3(
			WorldPresentationScale.HEX_SIZE * 0.011,
			WorldPresentationScale.hero_height() * 0.5 + WorldPresentationScale.HEX_SIZE * 0.0075,
			WorldPresentationScale.HEX_SIZE * 0.011
		)
		_add_entity_billboard(world + offset, "hero_default", entry.get("id", "Hero"))


func _build_demons(demons: Array) -> void:
	for entry in demons:
		var node_id: String = entry.get("node_id", "")
		if not _node_positions.has(node_id):
			continue
		var world: Vector3 = _node_positions[node_id]
		var offset := Vector3(
			-WorldPresentationScale.HEX_SIZE * 0.011,
			WorldPresentationScale.demon_height() + WorldPresentationScale.HEX_SIZE * 0.0075,
			-WorldPresentationScale.HEX_SIZE * 0.011
		)
		_add_entity_billboard(world + offset, "demon_default", entry.get("id", "Demon"))


func _build_development_indicators(session: BotGameSession) -> void:
	var indicators := WizardWorldDevelopmentPresenter.build_from_session(session)
	for entry in indicators:
		var icon_id: String = entry.get("icon_id", WizardWorldDevelopmentPresenter.GENERIC_SLOT_ICON)
		var position: Vector3 = entry.get("position", Vector3.ZERO)
		var name := "Dev_%s_%d" % [entry.get("node_id", ""), int(entry.get("slot_index", 0))]
		_add_entity_billboard(position, icon_id, name)


func _add_entity_billboard(world: Vector3, manifest_id: String, node_name: String) -> void:
	var sprite := _make_billboard_sprite(manifest_id)
	if sprite == null:
		return
	sprite.name = node_name
	sprite.position = world
	add_child(sprite)


func _add_prop_billboard(world: Vector3, manifest_id: String, node_name: String) -> void:
	var sprite := _make_billboard_sprite(manifest_id)
	if sprite == null:
		return
	sprite.name = node_name
	sprite.position = world + Vector3(0, WorldPresentationScale.HEX_SIZE * 0.02, 0)
	sprite.scale *= 0.8
	add_child(sprite)


func _make_billboard_sprite(manifest_id: String) -> Sprite3D:
	var entry := BillboardManifest.get_entry(manifest_id)
	if entry.is_empty():
		return null
	var texture := BillboardManifest.load_texture(manifest_id)
	if texture == null:
		return null
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = float(entry.get("scale", 0.03))
	sprite.axis = Vector3.AXIS_Y
	return sprite


func _make_edge_bar(from_pos: Vector3, to_pos: Vector3, has_road: bool, owner_id: int) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var direction := to_pos - from_pos
	var length := direction.length()
	if length <= 0.001:
		return mesh_instance
	var box := BoxMesh.new()
	var thickness := WorldPresentationScale.HEX_SIZE * (0.005 if not has_road else 0.008)
	box.size = Vector3(thickness, WorldPresentationScale.HEX_SIZE * 0.0025, length)
	var material := StandardMaterial3D.new()
	if has_road:
		material.albedo_color = BoardWorldMapper.player_color(owner_id)
	else:
		material.albedo_color = Color(0.35, 0.35, 0.35, 0.8)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if not has_road else BaseMaterial3D.TRANSPARENCY_DISABLED
	box.material = material
	mesh_instance.mesh = box
	mesh_instance.position = from_pos.lerp(to_pos, 0.5)
	if direction.length_squared() > 0.0001:
		mesh_instance.rotation.y = atan2(direction.x, direction.z)
	return mesh_instance


func _vec3_from_dict(data: Dictionary) -> Vector3:
	return Vector3(float(data.get("x", 0.0)), float(data.get("y", 0.0)), float(data.get("z", 0.0)))
