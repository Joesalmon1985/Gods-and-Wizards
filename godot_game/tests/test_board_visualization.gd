class_name TestBoardVisualization
extends RefCounted

const INTEGRATION_ROOT := "res://integration"
const RUN_MODES_ROOT := "res://run_modes"

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
	_scan_paths_for_mutations(test_assert, ArchitectureScanner.list_gd_files(INTEGRATION_ROOT))
	_scan_paths_for_mutations(test_assert, ArchitectureScanner.list_gd_files(RUN_MODES_ROOT))
	_test_wizard_mode_uses_session(test_assert)
	_test_wizard_mode_uses_reporting(test_assert)
	_test_mapper_read_only(test_assert)


static func _scan_paths_for_mutations(test_assert: TestAssert, paths: Array[String]) -> void:
	for path in paths:
		if path.ends_with("board_world_mapper.gd"):
			continue
		for line in ArchitectureScanner.read_code_lines(path):
			if ArchitectureScanner.is_comment_only_line(line):
				continue
			for token in FORBIDDEN_MUTATION_TOKENS:
				test_assert.check(
					not ArchitectureScanner.line_contains_token(line, token),
					"visual layer must not mutate GameState (%s) in %s" % [token, path]
				)


static func _test_wizard_mode_uses_session(test_assert: TestAssert) -> void:
	var lines := ArchitectureScanner.read_code_lines("res://run_modes/wizard_world_mode.gd")
	var uses_session := false
	var creates_state := false
	for line in lines:
		if ArchitectureScanner.is_comment_only_line(line):
			continue
		if "BotGameSession" in line:
			uses_session = true
		if "GameState.new" in line:
			creates_state = true
	test_assert.check(uses_session, "wizard world mode should use BotGameSession")
	test_assert.check(not creates_state, "wizard world mode must not create a second GameState")


static func _test_wizard_mode_uses_reporting(test_assert: TestAssert) -> void:
	var lines := ArchitectureScanner.read_code_lines("res://run_modes/wizard_world_mode.gd")
	var uses_summary := false
	var uses_turn_report := false
	for line in lines:
		if "GameStateSummary" in line:
			uses_summary = true
		if "TurnReport" in line:
			uses_turn_report = true
	test_assert.check(uses_summary, "wizard world mode should render GameStateSummary")
	test_assert.check(uses_turn_report, "wizard world mode should render TurnReport")


static func _test_mapper_read_only(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(11)
	var cities_before := session.state.cities.size()
	var roads_before := session.state.roads.size()
	BoardWorldMapper.build_snapshot(session.state, session.events)
	test_assert.eq(session.state.cities.size(), cities_before, "mapper should not change city count")
	test_assert.eq(session.state.roads.size(), roads_before, "mapper should not change road count")
