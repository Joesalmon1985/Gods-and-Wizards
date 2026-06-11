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


static func place_city(state: GameState, player_id: int, vertex: VertexCoord) -> City:
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


static func _player_exists(state: GameState, player_id: int) -> bool:
	for player in state.players:
		if player.id == player_id:
			return true
	return false
