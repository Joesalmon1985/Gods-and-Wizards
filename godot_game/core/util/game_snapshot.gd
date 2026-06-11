class_name GameSnapshot
extends RefCounted

static func snapshot(state: GameState, events: Array, event_log: EventLog = null) -> Dictionary:
	var players_data: Array = []
	for player in state.players:
		var resources := {}
		for resource in ResourceType.all():
			resources[ResourceType.to_key(resource)] = player.get_resource(resource)
		players_data.append({
			"id": player.id,
			"name": player.display_name,
			"resources": resources,
		})

	var events_data: Array = []
	for event in events:
		if event is GameEvent:
			events_data.append(event.to_dict())

	var cities_data: Array = []
	for city in state.cities:
		cities_data.append({
			"player_id": city.player_id,
			"vertex": city.vertex.to_dict(),
		})

	var result := {
		"seed": state.seed,
		"turn_number": state.turn_number,
		"round_number": state.round_number,
		"active_player_index": state.active_player_index,
		"players": players_data,
		"cities": cities_data,
		"events": events_data,
	}
	if event_log != null:
		result["history"] = event_log.to_dict()
	return result
