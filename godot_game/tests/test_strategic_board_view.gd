class_name TestStrategicBoardView
extends RefCounted

const UI_BOARD_ROOT := "res://ui/board"
const RUN_MODE_SCRIPT := "res://run_modes/strategic_2d_mode.gd"

const FORBIDDEN_MUTATION_TOKENS: Array[String] = [
	"GameState.new",
	"SetupRules.place_city",
	"SetupRules.place_road",
	"SetupRules.place_hero",
	"ActionRules.apply",
	"state.cities.append",
	"state.roads.append",
	"state.players[",
	".resources[",
]


static func run(test_assert: TestAssert) -> void:
	_test_snapshot_render_deterministic(test_assert)
	_test_board_view_does_not_mutate_state(test_assert)
	_test_ui_board_scripts_read_only(test_assert)
	_test_run_mode_uses_session(test_assert)


static func _test_snapshot_render_deterministic(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(11)
	var snapshot := BoardWorldMapper.build_snapshot(session.state, session.events)
	var view_a := StrategicBoardView.new()
	var view_b := StrategicBoardView.new()
	view_a.sync_from_snapshot(snapshot)
	view_b.sync_from_snapshot(snapshot)
	test_assert.eq(JSON.stringify(view_a.get_snapshot()), JSON.stringify(view_b.get_snapshot()), "same snapshot should produce identical view data")


static func _test_board_view_does_not_mutate_state(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(5)
	var cities_before := session.state.cities.size()
	var roads_before := session.state.roads.size()
	var view := StrategicBoardView.new()
	view.sync_from_snapshot(BoardWorldMapper.build_snapshot(session.state, session.events))
	test_assert.eq(session.state.cities.size(), cities_before, "2D view should not change city count")
	test_assert.eq(session.state.roads.size(), roads_before, "2D view should not change road count")


static func _test_ui_board_scripts_read_only(test_assert: TestAssert) -> void:
	for path in ArchitectureScanner.list_gd_files(UI_BOARD_ROOT):
		for line in ArchitectureScanner.read_code_lines(path):
			if ArchitectureScanner.is_comment_only_line(line):
				continue
			for token in FORBIDDEN_MUTATION_TOKENS:
				test_assert.check(
					not ArchitectureScanner.line_contains_token(line, token),
					"2D board UI must not mutate GameState (%s) in %s" % [token, path]
				)


static func _test_run_mode_uses_session(test_assert: TestAssert) -> void:
	var lines := ArchitectureScanner.read_code_lines(RUN_MODE_SCRIPT)
	var uses_session := false
	var creates_state := false
	for line in lines:
		if ArchitectureScanner.is_comment_only_line(line):
			continue
		if "BotGameSession" in line:
			uses_session = true
		if "GameState.new" in line:
			creates_state = true
	test_assert.check(uses_session, "2D strategic mode should use BotGameSession")
	test_assert.check(not creates_state, "2D strategic mode must not create a second GameState")
