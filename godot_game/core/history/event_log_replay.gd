class_name EventLogReplay
extends RefCounted

const SCHEMA_VERSION := 1


static func capture_baseline(state: GameState) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"round_number": state.round_number,
		"active_player_index": state.active_player_index,
		"players": _players_data(state),
		"cities": _cities_data(state),
		"roads": _roads_data(state),
	}


static func build_view_at_step(baseline: Dictionary, log: EventLog, step: int) -> Dictionary:
	var view := _duplicate_baseline(baseline)
	var clamped_step := clampi(step, 0, log.entries.size())
	var events_text_lines: PackedStringArray = []

	for i in range(clamped_step):
		var entry: Dictionary = log.entries[i]
		_apply_entry(view, entry)
		events_text_lines.append(_format_event_line(entry))

	view["step"] = clamped_step
	view["total_steps"] = log.entries.size()
	view["events_text"] = "\n".join(events_text_lines)
	view["last_event_detail"] = _last_event_detail(log, clamped_step)
	return view


static func _players_data(state: GameState) -> Array:
	var players_data: Array = []
	for player in state.players:
		var resources := {}
		for resource in ResourceType.all():
			resources[ResourceType.to_key(resource)] = player.get_resource(resource)
		players_data.append({
			"id": player.id,
			"name": player.display_name,
			"resources": resources,
			"victory_points": player.victory_points,
		})
	return players_data


static func _cities_data(state: GameState) -> Array:
	var cities_data: Array = []
	for city in state.cities:
		cities_data.append({
			"player_id": city.player_id,
			"vertex_key": city.vertex.to_key(),
		})
	return cities_data


static func _roads_data(state: GameState) -> Array:
	var roads_data: Array = []
	for road in state.roads:
		roads_data.append({
			"player_id": road.player_id,
			"edge_key": road.edge.to_key(),
		})
	return roads_data


static func _duplicate_baseline(baseline: Dictionary) -> Dictionary:
	var players_copy: Array = []
	for player in baseline["players"]:
		players_copy.append({
			"id": player["id"],
			"name": player["name"],
			"resources": player["resources"].duplicate(),
			"victory_points": player.get("victory_points", 0),
		})

	var cities_copy: Array = []
	for city in baseline["cities"]:
		cities_copy.append(city.duplicate())

	var roads_copy: Array = []
	for road in baseline.get("roads", []):
		roads_copy.append(road.duplicate())

	return {
		"schema_version": baseline.get("schema_version", SCHEMA_VERSION),
		"round_number": baseline["round_number"],
		"active_player_index": baseline["active_player_index"],
		"players": players_copy,
		"cities": cities_copy,
		"roads": roads_copy,
	}


static func _apply_entry(view: Dictionary, entry: Dictionary) -> void:
	var entry_type: String = entry["type"]
	var payload: Dictionary = entry.get("payload", {})

	match entry_type:
		"city_built":
			_apply_city_built(view, payload)
		"road_built":
			_apply_road_built(view, payload)
		"resource_gained":
			_apply_resource_gained(view, payload)
		"turn_ended":
			_apply_turn_ended(view)
		"round_started":
			view["round_number"] = payload.get("round", view["round_number"])
		"victory_points_changed":
			_apply_victory_points_changed(view, payload)
		_:
			pass


static func _apply_city_built(view: Dictionary, payload: Dictionary) -> void:
	var player_id: int = payload.get("player_id", -1)
	_deduct_cost(view, player_id, BuildCosts.BUILD_CITY)
	var vertex := BoardNode.from_dict(payload.get("vertex", {}))
	view["cities"].append({
		"player_id": player_id,
		"vertex_key": vertex.to_key(),
	})


static func _apply_road_built(view: Dictionary, payload: Dictionary) -> void:
	var player_id: int = payload.get("player_id", -1)
	_deduct_cost(view, player_id, BuildCosts.BUILD_ROAD)
	var edge := EdgeCoord.from_dict(payload.get("edge", {}))
	view["roads"].append({
		"player_id": player_id,
		"edge_key": edge.to_key(),
	})


static func _apply_resource_gained(view: Dictionary, payload: Dictionary) -> void:
	var player_id: int = payload.get("player_id", -1)
	var resource_key: String = payload.get("resource", "")
	var amount: int = payload.get("amount", 0)
	for player in view["players"]:
		if player["id"] != player_id:
			continue
		player["resources"][resource_key] = player["resources"].get(resource_key, 0) + amount
		return


static func _apply_victory_points_changed(view: Dictionary, payload: Dictionary) -> void:
	var player_id: int = payload.get("player_id", -1)
	var total: int = payload.get("total", 0)
	for player in view["players"]:
		if player["id"] == player_id:
			player["victory_points"] = total
			return


static func _apply_turn_ended(view: Dictionary) -> void:
	var player_count: int = view["players"].size()
	if player_count <= 0:
		return
	view["active_player_index"] = (view["active_player_index"] + 1) % player_count


static func _deduct_cost(view: Dictionary, player_id: int, costs: Dictionary) -> void:
	for player in view["players"]:
		if player["id"] != player_id:
			continue
		for resource in costs.keys():
			var key := ResourceType.to_key(resource)
			player["resources"][key] = player["resources"].get(key, 0) - costs[resource]
		return


static func _format_event_line(entry: Dictionary) -> String:
	var summary := summarize_entry(entry)
	if summary.is_empty():
		return "#%d %s" % [entry["sequence_id"], entry["type"]]
	return "#%d %s — %s" % [entry["sequence_id"], entry["type"], summary]


static func summarize_entry(entry: Dictionary) -> String:
	var entry_type: String = entry["type"]
	var payload: Dictionary = entry.get("payload", {})

	match entry_type:
		"city_built":
			return "P%d built at %s" % [
				payload.get("player_id", -1),
				_vertex_summary(payload.get("vertex", {})),
			]
		"road_built":
			return "P%d built road" % payload.get("player_id", -1)
		"resource_gained":
			return "P%d +%d %s" % [
				payload.get("player_id", -1),
				payload.get("amount", 0),
				payload.get("resource", ""),
			]
		"turn_ended":
			return "P%d ended turn" % payload.get("player_id", -1)
		"round_started":
			return "round %d" % payload.get("round", 0)
		"production_check":
			return "%s on %s roll %d -> %s" % [
				payload.get("resource", ""),
				_hex_summary(payload.get("hex", {})),
				payload.get("roll", -1),
				"produced" if payload.get("produced", false) else "miss",
			]
		"action_mask_recorded":
			return "P%d mask" % payload.get("player_id", -1)
		"victory_points_changed":
			return "P%d %+d VP -> %d (%s)" % [
				payload.get("player_id", -1),
				payload.get("delta", 0),
				payload.get("total", 0),
				payload.get("reason", ""),
			]
		"game_over":
			return "winner P%d (%s)" % [payload.get("winner_id", -1), payload.get("reason", "")]
		_:
			return ""


static func _last_event_detail(log: EventLog, step: int) -> String:
	if step <= 0 or step > log.entries.size():
		return ""
	return summarize_entry(log.entries[step - 1])


static func _vertex_summary(vertex_data: Dictionary) -> String:
	var keys: Array = vertex_data.get("geometric_hexes", [])
	if keys.is_empty():
		return "?"
	return str(keys[0])


static func _hex_summary(hex_data: Dictionary) -> String:
	return "%d,%d" % [hex_data.get("q", 0), hex_data.get("r", 0)]
