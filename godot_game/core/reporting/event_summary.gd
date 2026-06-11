class_name EventSummary
extends RefCounted

const RESOURCE_LABELS := {
	ResourceType.Type.WOOD: "Wood",
	ResourceType.Type.BRICK: "Brick",
	ResourceType.Type.WHEAT: "Wheat",
	ResourceType.Type.SHEEP: "Sheep",
	ResourceType.Type.ORE: "Ore",
}


static func summarize_events(events: Array, state: GameState) -> Array[String]:
	var lines: Array[String] = []
	var production_line := _summarize_production(events, state)
	if production_line != "":
		lines.append(production_line)

	for event in events:
		var line := _summarize_single(event, state)
		if line != "":
			lines.append(line)

	if lines.is_empty():
		lines.append("No major events this turn.")
	return lines


static func summarize_event_entry(entry_type: String, payload: Dictionary, state: GameState) -> String:
	match entry_type:
		"production_check":
			return _production_check_line(payload)
		"action_mask_recorded":
			return ""
		"resource_gained":
			return _resource_gained_line(payload, state)
		"city_built":
			return "%s built a city." % _player_name(state, int(payload.get("player_id", -1)))
		"road_built":
			return "%s built a road." % _player_name(state, int(payload.get("player_id", -1)))
		"turn_ended":
			return "%s ended their turn." % _player_name(state, int(payload.get("player_id", -1)))
		"round_started":
			return "Round %d began." % int(payload.get("round", payload.get("round_number", 0)))
		"hero_moved":
			return "Hero %d moved." % int(payload.get("hero_id", -1))
		"demon_spread":
			return "A demon appeared at node %s." % _short_node_ref(payload.get("to_node", {}))
		"encounter_combat":
			return "Combat encounter occurred."
		"breach":
			return "An underworld breach occurred (total breaches: %d)." % int(payload.get("breach_count", 0))
		"development_built":
			return "%s built a development." % _player_name(state, int(payload.get("player_id", -1)))
		"victory_points_changed":
			return "%s now has %d victory points." % [
				_player_name(state, int(payload.get("player_id", -1))),
				int(payload.get("total", 0)),
			]
		"game_over":
			return _game_over_line(payload, state)
		_:
			return "Event: %s." % entry_type if entry_type != "" else ""


static func summarize_log_entry(entry: Dictionary, state: GameState) -> String:
	return summarize_event_entry(str(entry.get("type", "")), entry.get("payload", {}), state)


static func _summarize_single(event, state: GameState) -> String:
	if event == null:
		return ""
	if event is ProductionCheckEvent:
		return ""
	if event is ResourceGainedEvent:
		return ""
	if event.has_method("to_dict"):
		var data: Dictionary = event.to_dict()
		return summarize_event_entry(str(data.get("type", "")), data, state)
	return ""


static func _summarize_production(events: Array, state: GameState) -> String:
	var totals := {}
	var had_checks := false
	for event in events:
		if event is ProductionCheckEvent:
			had_checks = true
		if event is ResourceGainedEvent:
			var key := "%d:%d" % [event.player_id, event.resource]
			totals[key] = int(totals.get(key, 0)) + event.amount

	if totals.is_empty():
		if had_checks:
			return "Production: no resources were gained."
		return ""

	var by_player := {}
	for key in totals.keys():
		var split := str(key).split(":")
		var player_id := int(split[0])
		var resource := int(split[1])
		if not by_player.has(player_id):
			by_player[player_id] = []
		by_player[player_id].append("%d %s" % [int(totals[key]), _resource_label(resource)])

	var player_ids: Array = by_player.keys()
	player_ids.sort()
	var player_parts: Array[String] = []
	for player_id in player_ids:
		player_parts.append("%s gained %s" % [_player_name(state, player_id), ", ".join(by_player[player_id])])
	return "Production: %s." % ", ".join(player_parts)


static func _resource_gained_line(payload: Dictionary, state: GameState) -> String:
	var resource_key: String = str(payload.get("resource", ""))
	var amount := int(payload.get("amount", 0))
	return "%s gained %d %s from production." % [
		_player_name(state, int(payload.get("player_id", -1))),
		amount,
		_resource_label_from_key(resource_key),
	]


static func _game_over_line(payload: Dictionary, state: GameState) -> String:
	var winner_id := int(payload.get("winner_id", -1))
	var reason := str(payload.get("reason", ""))
	if winner_id < 0:
		return "Game over (%s)." % reason
	return "%s wins the game (%s)." % [_player_name(state, winner_id), reason]


static func _player_name(state: GameState, player_id: int) -> String:
	for player in state.players:
		if player.id == player_id:
			return player.display_name
	return "Player %d" % player_id


static func _resource_label(resource: ResourceType.Type) -> String:
	return RESOURCE_LABELS.get(resource, ResourceType.to_key(resource).capitalize())


static func _resource_label_from_key(key: String) -> String:
	match key:
		"wood":
			return "Wood"
		"brick":
			return "Brick"
		"wheat":
			return "Wheat"
		"sheep":
			return "Sheep"
		"ore":
			return "Ore"
		_:
			return key.capitalize()


static func _production_check_line(payload: Dictionary) -> String:
	var resource_key := str(payload.get("resource", ""))
	var resource_label := _resource_label_from_key(resource_key)
	var hex_data: Dictionary = payload.get("hex", {})
	var hex_ref := "%d,%d" % [hex_data.get("q", 0), hex_data.get("r", 0)]
	var roll := int(payload.get("roll", -1))
	var produced: bool = payload.get("produced", false)
	if produced:
		return "Production check: %s on hex %s — roll %d, produced." % [resource_label, hex_ref, roll]
	return "Production check: %s on hex %s — roll %d, no production." % [resource_label, hex_ref, roll]


static func _short_node_ref(node_data) -> String:
	if node_data is Dictionary:
		var keys: Array = node_data.get("geometric_hexes", [])
		if keys.is_empty():
			return "?"
		return str(keys[0])
	if node_data is String:
		return node_data.split("|")[0]
	return "?"
