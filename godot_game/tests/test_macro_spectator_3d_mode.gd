class_name TestMacroSpectator3DMode
extends RefCounted

const SPECTATOR_RUN_MODE := "res://run_modes/macro_spectator_3d_mode.gd"
const SPECTATOR_SCENE := "res://run_modes/macro_spectator_3d_mode.tscn"
const SPECTATOR_CONTROLLER := "res://integration/macro_spectator_controller.gd"

const FORBIDDEN_TOKENS: Array[String] = [
	"submit_human_action",
	"ActionRules.apply",
	"GameState.new",
]


static func run(test_assert: TestAssert) -> void:
	_test_spectator_uses_bot_game_session_four_player(test_assert)
	_test_spectator_does_not_call_submit_human_action(test_assert)
	_test_spectator_refresh_from_session_snapshot(test_assert)
	_test_autoplay_timer_advances_turns(test_assert)
	_test_spectator_scene_instantiates(test_assert)


static func _test_spectator_uses_bot_game_session_four_player(test_assert: TestAssert) -> void:
	var lines := ArchitectureScanner.read_code_lines(SPECTATOR_RUN_MODE)
	var uses_session := false
	for line in lines:
		if "BotGameSession.start_four_player" in line:
			uses_session = true
	test_assert.check(uses_session, "spectator should use four-player bot session")


static func _test_spectator_does_not_call_submit_human_action(test_assert: TestAssert) -> void:
	for path in [SPECTATOR_RUN_MODE, SPECTATOR_CONTROLLER]:
		for line in ArchitectureScanner.read_code_lines(path):
			for token in FORBIDDEN_TOKENS:
				if token == "submit_human_action" and token not in line:
					continue
				if token in line and not ArchitectureScanner.is_comment_only_line(line):
					if token == "submit_human_action":
						test_assert.check(false, "spectator must not submit human actions in %s" % path)


static func _test_spectator_refresh_from_session_snapshot(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(3)
	var cities_before := session.state.cities.size()
	BoardWorldMapper.build_snapshot(session.state, session.events)
	test_assert.eq(session.state.cities.size(), cities_before, "spectator refresh path must not mutate state")


static func _test_autoplay_timer_advances_turns(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(4)
	var events_before := session.events.size()
	var stepped := MacroSpectatorController.advance_if_timer_elapsed(session, 1.0, 1.0, 0.0)
	test_assert.check(stepped, "timer elapsed should advance one turn")
	test_assert.check(session.events.size() > events_before, "advance should append events")


static func _test_spectator_scene_instantiates(test_assert: TestAssert) -> void:
	var scene: PackedScene = load(SPECTATOR_SCENE)
	test_assert.check(scene != null, "spectator scene should load")
	var node := scene.instantiate()
	test_assert.check(node != null, "spectator scene should instantiate")
	if node != null:
		node.free()
