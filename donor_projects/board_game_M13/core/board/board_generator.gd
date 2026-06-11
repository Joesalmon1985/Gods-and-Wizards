class_name BoardGenerator
extends RefCounted

const DEFAULT_RADIUS := 3


static func generate(rng: GameRng, board_radius: int = DEFAULT_RADIUS) -> HexBoard:
	var board := HexBoard.new(board_radius)

	for coord in HexBoard.coords_for_radius(board_radius):
		var tile := HexTile.new(coord)
		for resource in ResourceType.all():
			tile.production[resource] = rng.randi_range(0, 9)
		board.add_tile(tile)

	board.build_vertex_index()
	return board
