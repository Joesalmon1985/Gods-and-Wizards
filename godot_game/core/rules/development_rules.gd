class_name DevelopmentRules
extends RefCounted

const DEFAULT_DEVELOPMENT_ID := DevelopmentCatalog.WATCHTOWER_ID


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
	if city.development_id != "":
		return false
	var resolved_id := DevelopmentCatalog.resolve_build_id(development_id)
	if not DevelopmentCatalog.has_id(resolved_id):
		return false
	return BuildCosts.can_afford(_player(state, player_id), BuildCosts.BUILD_DEVELOPMENT)


static func apply(
	state: GameState,
	player_id: int,
	vertex: BoardNode,
	development_id: String = ""
) -> Array:
	var player := _player(state, player_id)
	var resolved_id := DevelopmentCatalog.resolve_build_id(development_id)
	player.pay_cost(BuildCosts.BUILD_DEVELOPMENT)
	var city: City = state.cities_by_vertex[vertex.to_key()]
	city.development_id = resolved_id

	var events: Array = [
		DevelopmentBuiltEvent.new(state.round_number, player_id, vertex, resolved_id),
	]
	var bonus := DevelopmentCatalog.victory_points_bonus(resolved_id)
	if bonus > 0:
		events.append_array(ScoreRules.grant_victory_points(state, player_id, bonus, "development_built"))
	return events


static func _player(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null
