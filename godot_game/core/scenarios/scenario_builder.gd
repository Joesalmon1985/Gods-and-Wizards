class_name ScenarioBuilder
extends RefCounted

const STARTING_RESOURCES := {
	ResourceType.Type.WOOD: 4,
	ResourceType.Type.BRICK: 2,
	ResourceType.Type.WHEAT: 2,
	ResourceType.Type.SHEEP: 0,
	ResourceType.Type.ORE: 0,
}


static func build_standard_game(game_seed: int) -> GameState:
	return _create_players_and_cities(game_seed)


static func build_bot_ready_game(game_seed: int) -> GameState:
	var state := _create_players_and_cities(game_seed)
	for player in state.players:
		SetupRules.grant_resources(state, player.id, STARTING_RESOURCES)
	return state


static func build_four_player_bot_game(game_seed: int) -> GameState:
	var state := SetupRules.create_game(game_seed)
	var player_names: Array[String] = ["Alice", "Bob", "Charlie", "Dana"]
	for player_name in player_names:
		SetupRules.add_player(state, player_name)

	var city_vertices: Array[BoardNode] = [
		BoardNode.from_hex_corner(HexCoord.new(0, 0), 0),
		BoardNode.from_hex_corner(HexCoord.new(1, 0), 2),
		BoardNode.from_hex_corner(HexCoord.new(-1, 0), 4),
		BoardNode.from_hex_corner(HexCoord.new(0, -1), 1),
	]
	for player_id in range(player_names.size()):
		SetupRules.place_city(state, player_id, city_vertices[player_id])

	for player in state.players:
		SetupRules.grant_resources(state, player.id, STARTING_RESOURCES)
	return state


static func build_underworld_pressure_game(game_seed: int) -> GameState:
	var state := build_four_player_bot_game(game_seed)
	_seed_underworld_pressure(state)
	return state


static func _seed_underworld_pressure(state: GameState) -> void:
	var candidates: Array[BoardNode] = []
	for node in state.board.get_all_nodes_sorted():
		if state.cities_by_vertex.has(node.to_key()):
			continue
		if state.heroes_by_node.has(node.to_key()):
			continue
		candidates.append(node)

	if candidates.is_empty():
		return

	var slots := mini(4, candidates.size())
	var start_index := state.rng.randi_range(0, candidates.size() - 1)
	for offset in range(slots):
		var node := candidates[(start_index + offset) % candidates.size()]
		SetupRules.set_demon_count(state, node, 2)


static func _create_players_and_cities(game_seed: int) -> GameState:
	var state := SetupRules.create_game(game_seed)
	SetupRules.add_player(state, "Alice")
	SetupRules.add_player(state, "Bob")

	var alice_vertex := BoardNode.from_hex_corner(HexCoord.new(0, 0), 0)
	var bob_vertex := BoardNode.from_hex_corner(HexCoord.new(1, 0), 2)
	SetupRules.place_city(state, 0, alice_vertex)
	SetupRules.place_city(state, 1, bob_vertex)
	return state
