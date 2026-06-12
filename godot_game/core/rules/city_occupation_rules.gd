class_name CityOccupationRules
extends RefCounted

static func on_demon_count_changed(
	state: GameState,
	node: BoardNode,
	old_count: int,
	new_count: int
) -> void:
	if not state.cities_by_vertex.has(node.to_key()):
		return
	var key := node.to_key()
	if old_count <= 0 and new_count > 0:
		state.city_demon_occupied_since_round[key] = state.round_number
	elif new_count <= 0:
		state.city_demon_occupied_since_round.erase(key)


static func is_city_suppressed(state: GameState, vertex: BoardNode) -> bool:
	return SetupRules.get_demon_count(state, vertex) > 0


static func evaluate_round_start_purges(state: GameState) -> Array:
	var events: Array = []
	for key in state.city_demon_occupied_since_round.keys():
		if not state.cities_by_vertex.has(key):
			state.city_demon_occupied_since_round.erase(key)
			continue
		var occupied_since: int = int(state.city_demon_occupied_since_round[key])
		if state.round_number <= occupied_since:
			continue
		var vertex: BoardNode = state.cities_by_vertex[key].vertex
		if SetupRules.get_demon_count(state, vertex) <= 0:
			state.city_demon_occupied_since_round.erase(key)
			continue
		events.append_array(_purge_city_development(state, state.cities_by_vertex[key]))
	return events


static func _purge_city_development(state: GameState, city: City) -> Array:
	if city.developments.is_empty():
		return []
	var events: Array = []
	var player := _player(state, city.player_id)
	for purged_id in city.developments:
		events.append(
			CityDevelopmentPurgedEvent.new(
				state.round_number,
				city.player_id,
				city.vertex,
				purged_id
			)
		)
		var bonus := DevelopmentCatalog.victory_points_bonus(purged_id)
		if bonus > 0 and player != null:
			player.victory_points = maxi(0, player.victory_points - bonus)
			events.append(
				VictoryPointsChangedEvent.new(
					city.player_id,
					-bonus,
					player.victory_points,
					"development_purged"
				)
			)
	city.developments.clear()
	return events


static func _player(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null
