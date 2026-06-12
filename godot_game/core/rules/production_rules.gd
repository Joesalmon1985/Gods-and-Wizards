class_name ProductionRules
extends RefCounted

static func resolve_active_player_turn_start_production(state: GameState) -> Array:
	var player := TurnRules.get_active_player(state)
	if player == null:
		return []
	state.current_phase = TurnPhase.Phase.PRODUCTION
	var events: Array = [ProductionPhaseEvent.new(state.turn_number, player.id)]
	events.append_array(_resolve_production(state, state.turn_number, player.id))
	state.current_phase = TurnPhase.Phase.ACTIVE_PLAYER
	return events


static func resolve_round_production(state: GameState) -> Array:
	return _resolve_production(state, state.round_number, -1)


static func resolve_start_of_turn_production(state: GameState) -> Array:
	return resolve_active_player_turn_start_production(state)


static func _resolve_production(state: GameState, event_turn: int, active_player_id: int) -> Array:
	var events: Array = []
	var turn := event_turn

	for coord in state.board.get_all_coords_sorted():
		var tile := state.board.get_tile(coord)
		for resource in ResourceType.all():
			var production_chance: int = tile.get_production_chance(resource)
			if production_chance <= 0:
				continue

			var roll := _roll_production_d10(state.rng)
			var produced := roll < production_chance
			events.append(ProductionCheckEvent.new(
				turn,
				coord,
				resource,
				production_chance,
				roll,
				produced
			))

			if not produced:
				continue

			for vertex in state.board.get_vertices_for_hex(coord):
				var vertex_key := vertex.to_key()
				if not state.cities_by_vertex.has(vertex_key):
					continue

				var city: City = state.cities_by_vertex[vertex_key]
				if CityOccupationRules.is_city_suppressed(state, vertex):
					continue
				if active_player_id >= 0 and city.player_id != active_player_id:
					continue
				var player := _get_player(state, city.player_id)
				if player == null:
					continue

				var amount := 1 + DevelopmentEffectEngine.production_bonus_for_city(city, resource)
				player.add_resource(resource, amount)
				events.append(ResourceGainedEvent.new(
					turn,
					player.id,
					resource,
					amount,
					coord,
					vertex
				))

	return events


static func _roll_production_d10(rng: GameRng) -> int:
	if rng.fixed_rolls_remaining() > 0:
		return rng.roll_d10()
	return rng.randi_range(0, 9)


static func _get_player(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null
