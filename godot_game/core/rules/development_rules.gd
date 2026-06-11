class_name DevelopmentRules
extends RefCounted

const DEFAULT_DEVELOPMENT_ID := "watchtower"


static func can_build(state: GameState, player_id: int, vertex: BoardNode) -> bool:
	var city: City = state.cities_by_vertex.get(vertex.to_key())
	if city == null:
		return false
	if city.player_id != player_id:
		return false
	if city.development_id != "":
		return false
	return BuildCosts.can_afford(_player(state, player_id), BuildCosts.BUILD_DEVELOPMENT)


static func apply(state: GameState, player_id: int, vertex: BoardNode) -> Array:
	var player := _player(state, player_id)
	player.pay_cost(BuildCosts.BUILD_DEVELOPMENT)
	var city: City = state.cities_by_vertex[vertex.to_key()]
	city.development_id = DEFAULT_DEVELOPMENT_ID
	return [DevelopmentBuiltEvent.new(state.round_number, player_id, vertex, DEFAULT_DEVELOPMENT_ID)]


static func _player(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null
