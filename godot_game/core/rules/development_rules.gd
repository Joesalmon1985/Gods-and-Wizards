class_name DevelopmentRules
extends RefCounted

const MAX_DEVELOPMENTS_PER_CITY := 3


static func can_build(
	state: GameState,
	player_id: int,
	vertex: BoardNode,
	development_id: String = ""
) -> bool:
	var city: City = state.cities_by_vertex.get(vertex.to_key())
	if city == null:
		return false
	if city.player_id != player_id:
		return false
	if city.developments.size() >= MAX_DEVELOPMENTS_PER_CITY:
		return false
	if CityOccupationRules.is_city_suppressed(state, vertex):
		return false
	var resolved_id := DevelopmentCatalog.resolve_build_id(development_id)
	if not DevelopmentCatalog.has_id(resolved_id):
		return false
	var player := _player(state, player_id)
	if player == null or resolved_id not in player.development_hand:
		return false
	return BuildCosts.can_afford(
		player,
		_build_cost_for_player(state, player_id, resolved_id)
	)


static func _build_cost_for_player(state: GameState, player_id: int, development_id: String) -> Dictionary:
	var base := DevelopmentCatalog.build_cost_as_resources(development_id)
	var discount := DevelopmentEffectEngine.production_discount_for_player(state, player_id)
	return DevelopmentEffectEngine.apply_build_cost_discount(base, discount)


static func apply(
	state: GameState,
	player_id: int,
	vertex: BoardNode,
	development_id: String = ""
) -> Array:
	var player := _player(state, player_id)
	var resolved_id := DevelopmentCatalog.resolve_build_id(development_id)
	if not can_build(state, player_id, vertex, resolved_id):
		return []
	player.pay_cost(_build_cost_for_player(state, player_id, resolved_id))
	player.development_hand.erase(resolved_id)
	var city: City = state.cities_by_vertex[vertex.to_key()]
	city.developments.append(resolved_id)

	var events: Array = [
		DevelopmentBuiltEvent.new(state.round_number, player_id, vertex, resolved_id),
	]
	events.append_array(DevelopmentEffectEngine.apply_card_on_build(state, player_id, city, resolved_id))
	DevelopmentEffectEngine.refresh_hero_action_budgets(state)
	return events


static func _player(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null
