class_name SetupRules
extends RefCounted

static func create_game(game_seed: int) -> GameState:
	var state := GameState.new()
	state.seed = game_seed
	state.rng = GameRng.new()
	state.rng.seed(game_seed)
	state.board = BoardGenerator.generate(state.rng)
	state.action_space = ActionSpace.from_board(state.board)
	return state


static func rebuild_action_space(state: GameState) -> void:
	state.action_space = ActionSpace.from_state(state)


static func add_player(state: GameState, display_name: String) -> Player:
	var player := Player.new(state.players.size(), display_name)
	state.players.append(player)
	return player


static func grant_resources(state: GameState, player_id: int, amounts: Dictionary) -> void:
	for player in state.players:
		if player.id != player_id:
			continue
		for resource in amounts.keys():
			player.resources[resource] = amounts[resource]
		return


static func place_city(state: GameState, player_id: int, vertex: BoardNode) -> City:
	if not _player_exists(state, player_id):
		push_error("Player %d does not exist" % player_id)
		return null

	if not state.board.has_vertex(vertex):
		push_error("Vertex %s is not on the board" % vertex.to_key())
		return null

	var vertex_key := vertex.to_key()
	if state.cities_by_vertex.has(vertex_key):
		push_error("City already exists at vertex %s" % vertex_key)
		return null

	var city := City.new(player_id, vertex)
	state.cities.append(city)
	state.cities_by_vertex[vertex_key] = city
	return city


static func place_road(state: GameState, player_id: int, edge: EdgeCoord) -> Road:
	if not _player_exists(state, player_id):
		return null
	if not state.board.has_edge(edge):
		return null
	var edge_key := edge.to_key()
	if state.roads_by_edge.has(edge_key):
		return null
	var road := Road.new(player_id, edge)
	state.roads.append(road)
	state.roads_by_edge[edge_key] = road
	return road


static func place_hero(state: GameState, player_id: int, node: BoardNode, health: int = 10) -> Hero:
	if not _player_exists(state, player_id):
		return null
	if not state.board.has_node(node):
		return null
	if state.heroes_by_node.has(node.to_key()):
		return null
	var hero := Hero.new(state.heroes.size(), player_id, node, health)
	state.heroes.append(hero)
	state.heroes_by_id[hero.id] = hero
	state.heroes_by_node[node.to_key()] = hero
	return hero


static func set_demon_count(state: GameState, node: BoardNode, count: int) -> void:
	var old_count := get_demon_count(state, node)
	var new_count := maxi(0, count)
	state.demon_counts_by_node[node.to_key()] = new_count
	CityOccupationRules.on_demon_count_changed(state, node, old_count, new_count)


static func get_demon_count(state: GameState, node: BoardNode) -> int:
	return state.demon_counts_by_node.get(node.to_key(), 0)


static func _player_exists(state: GameState, player_id: int) -> bool:
	for player in state.players:
		if player.id == player_id:
			return true
	return false
