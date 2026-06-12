class_name WizardWorldDevelopmentPresenter
extends RefCounted

const GENERIC_SLOT_ICON := "generic_development_slot"
const SLOT_OFFSET_RADIUS := 0.22


static func build_from_session(session: BotGameSession) -> Array:
	if session == null:
		return []
	var snapshot := BoardWorldMapper.build_snapshot(session.state, session.events)
	return build_from_snapshot(snapshot)


static func build_from_snapshot(snapshot: Dictionary) -> Array:
	var indicators: Array = []
	var node_positions := _index_node_positions(snapshot.get("nodes", []))
	for city in snapshot.get("cities", []):
		_append_city_indicators(indicators, city, node_positions)
	return indicators


static func build_from_development_model(model: Dictionary, node_positions: Dictionary) -> Array:
	var indicators: Array = []
	for slot_row in model.get("city_slots", []):
		var node_id: String = str(slot_row.get("node_id", ""))
		if not node_positions.has(node_id):
			continue
		var base_pos: Vector3 = node_positions[node_id]
		var developments: Array = slot_row.get("developments", [])
		for slot_index in developments.size():
			var dev: Dictionary = developments[slot_index]
			indicators.append(_indicator_entry(node_id, slot_index, str(dev.get("id", "")), base_pos))
	return indicators


static func icon_id_for_card(card_id: String) -> String:
	var manifest_id := "dev_%s" % card_id
	if BillboardManifest.has_entry(manifest_id):
		return manifest_id
	var card := DevelopmentCatalog.get_card(card_id)
	if card != null:
		for tag in card.tags:
			var tag_icon := "dev_tag_%s" % str(tag)
			if BillboardManifest.has_entry(tag_icon):
				return tag_icon
	return GENERIC_SLOT_ICON


static func _append_city_indicators(indicators: Array, city: Dictionary, node_positions: Dictionary) -> void:
	var node_id: String = str(city.get("node_id", ""))
	var development_ids: Array = city.get("development_ids", [])
	if development_ids.is_empty() or not node_positions.has(node_id):
		return
	var base_pos: Vector3 = node_positions[node_id]
	for slot_index in development_ids.size():
		indicators.append(_indicator_entry(node_id, slot_index, str(development_ids[slot_index]), base_pos))


static func _indicator_entry(node_id: String, slot_index: int, card_id: String, base_pos: Vector3) -> Dictionary:
	var icon_id := icon_id_for_card(card_id)
	var has_icon := BillboardManifest.has_entry(icon_id) and icon_id != GENERIC_SLOT_ICON or icon_id == GENERIC_SLOT_ICON
	return {
		"node_id": node_id,
		"slot_index": slot_index,
		"card_id": card_id,
		"icon_id": icon_id,
		"has_icon": has_icon,
		"uses_generic_fallback": icon_id == GENERIC_SLOT_ICON,
		"position": _slot_offset(base_pos, slot_index),
	}


static func _slot_offset(base_pos: Vector3, slot_index: int) -> Vector3:
	var radius := SLOT_OFFSET_RADIUS * WorldPresentationScale.SCALE_FACTOR
	var angle := float(slot_index) * (TAU / 3.0)
	return base_pos + Vector3(cos(angle) * radius, WorldPresentationScale.city_height(), sin(angle) * radius)


static func _index_node_positions(nodes: Array) -> Dictionary:
	var lookup := {}
	for entry in nodes:
		var world: Dictionary = entry.get("world", {})
		lookup[str(entry.get("id", ""))] = Vector3(
			float(world.get("x", 0.0)),
			float(world.get("y", 0.0)),
			float(world.get("z", 0.0))
		)
	return lookup
