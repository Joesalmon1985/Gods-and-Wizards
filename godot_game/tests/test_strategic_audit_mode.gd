class_name TestStrategicAuditMode
extends RefCounted

const AUDIT_VIEW_MODEL := "res://ui/board/strategic_audit_view_model.gd"
const AUDIT_CONTROLLER := "res://ui/board/strategic_audit_controller.gd"
const AUDIT_RUN_MODE := "res://run_modes/strategic_audit_2d_mode.gd"
const AUDIT_SCENE := "res://run_modes/strategic_audit_2d_mode.tscn"

const FORBIDDEN_MUTATION_TOKENS: Array[String] = [
	"GameState.new",
	"ActionRules.apply",
	"submit_human_action",
	"state.cities.append",
	"state.roads.append",
	"state.players[",
	".resources[",
]


static func run(test_assert: TestAssert) -> void:
	_test_view_model_includes_legal_actions(test_assert)
	_test_view_model_includes_recent_events(test_assert)
	_test_view_model_includes_pressure_fields(test_assert)
	_test_advance_n_steps_deterministic(test_assert)
	_test_audit_scripts_read_only(test_assert)
	_test_audit_scene_instantiates(test_assert)


static func _test_view_model_includes_legal_actions(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(42)
	var model := StrategicAuditViewModel.build(session)
	var legal: Array = model.get("legal_action_labels", [])
	test_assert.check(legal.size() >= 1, "audit view-model should list legal actions")
	var has_end_turn := false
	for label in legal:
		if str(label).contains("end_turn"):
			has_end_turn = true
	test_assert.check(has_end_turn, "legal actions should include end_turn")


static func _test_view_model_includes_recent_events(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(7)
	session.advance_one_player_turn()
	var model := StrategicAuditViewModel.build(session)
	var events: Array = model.get("recent_event_lines", [])
	test_assert.check(events.size() >= 1, "audit view-model should include recent event lines after a turn")


static func _test_view_model_includes_pressure_fields(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(11)
	var snapshot := BoardWorldMapper.build_snapshot(session.state, session.events)
	var model := StrategicAuditViewModel.build(session)
	test_assert.eq(
		int(model.get("breach_count", -1)),
		int(snapshot.get("breach_count", -2)),
		"audit breach count should match board snapshot"
	)
	test_assert.eq(
		int(model.get("total_demons", -1)),
		int(snapshot.get("total_demons", -2)),
		"audit demon count should match board snapshot"
	)


static func _test_advance_n_steps_deterministic(test_assert: TestAssert) -> void:
	var session_a := BotGameSession.start_four_player(99)
	var session_b := BotGameSession.start_four_player(99)
	var added_a := StrategicAuditController.advance_n_bot_steps(session_a, 3)
	var added_b := StrategicAuditController.advance_n_bot_steps(session_b, 3)
	test_assert.eq(added_a, added_b, "same seed should add same number of events")
	test_assert.check(added_a > 0, "advancing bot steps should append events")
	test_assert.eq(session_a.events.size(), session_b.events.size(), "event logs should stay deterministic")


static func _test_audit_scripts_read_only(test_assert: TestAssert) -> void:
	for path in [AUDIT_VIEW_MODEL, AUDIT_CONTROLLER, AUDIT_RUN_MODE]:
		for line in ArchitectureScanner.read_code_lines(path):
			if ArchitectureScanner.is_comment_only_line(line):
				continue
			for token in FORBIDDEN_MUTATION_TOKENS:
				test_assert.check(
					not ArchitectureScanner.line_contains_token(line, token),
					"audit layer must stay read-only (%s) in %s" % [token, path]
				)


static func _test_audit_scene_instantiates(test_assert: TestAssert) -> void:
	var scene: PackedScene = load(AUDIT_SCENE)
	test_assert.check(scene != null, "audit scene should load")
	var node := scene.instantiate()
	test_assert.check(node != null, "audit scene should instantiate")
	if node != null:
		node.free()
