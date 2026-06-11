class_name TestBoardGeneration
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var rng := GameRng.new()
	rng.seed(7)
	var board := BoardGenerator.generate(rng, 3)

	test_assert.eq(board.tiles.size(), 37, "radius-3 board should have 37 hexes")
	test_assert.eq(HexBoard.coords_for_radius(3).size(), 37, "coords_for_radius should return 37 hexes")

	var coords := board.get_all_coords_sorted()
	for i in range(coords.size() - 1):
		test_assert.check(
			coords[i].sort_key() < coords[i + 1].sort_key(),
			"hex coords should be sorted"
		)

	for coord in coords:
		var tile := board.get_tile(coord)
		for resource in ResourceType.all():
			var value: int = tile.get_production_chance(resource)
			test_assert.check(value >= 0 and value <= 9, "production chance out of range")

	var rng_repeat := GameRng.new()
	rng_repeat.seed(7)
	var board_repeat := BoardGenerator.generate(rng_repeat, 3)
	for coord in coords:
		var tile_a := board.get_tile(coord)
		var tile_b := board_repeat.get_tile(coord)
		for resource in ResourceType.all():
			test_assert.eq(
				tile_a.get_production_chance(resource),
				tile_b.get_production_chance(resource),
				"same seed should produce same production chances"
			)
