class_name ProductionFixtures
extends RefCounted

static func build_minimal_production_state(chance_by_resource: Dictionary) -> GameState:
	var state := GameState.new()
	state.seed = 1
	state.rng = GameRng.new()
	state.rng.seed(1)

	var board := HexBoard.new(0)
	var coord := HexCoord.new(0, 0)
	var tile := HexTile.new(coord)
	for resource in ResourceType.all():
		tile.production[resource] = chance_by_resource.get(resource, 0)
	board.add_tile(tile)
	board.build_vertex_index()

	state.board = board
	state.action_space = ActionSpace.from_board(board)
	return state
