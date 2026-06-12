class_name TestHumanMacro2DMode
extends RefCounted

const PLAY_RUN_MODE := "res://run_modes/strategic_play_2d_mode.gd"
const PLAY_SCENE := "res://run_modes/strategic_play_2d_mode.tscn"
const PICKER_SCRIPT := "res://integration/strategic_action_picker.gd"

const FORBIDDEN_MUTATION_TOKENS: Array[String] = [
	"ActionRules.apply",
	"GameState.new",
	"state.cities.append",
	"state.roads.append",
	".resources[",
]


static func run(test_assert: TestAssert) -> void:
	_test_play_mode_uses_one_human_three_bots(test_assert)
	_test_picker_lists_only_legal_actions(test_assert)
	_test_submit_goes_through_session_not_action_rules(test_assert)
	_test_bot_advance_until_human(test_assert)
	_test_bank_trade_selectable_when_legal(test_assert)
	_test_full_game_human_end_turn_only_to_finish(test_assert)
	_test_play_scene_instantiates(test_assert)


static func _test_play_mode_uses_one_human_three_bots(test_assert: TestAssert) -> void:
	var lines := ArchitectureScanner.read_code_lines(PLAY_RUN_MODE)
	var uses_human := false
	var uses_four_bot := false
	for line in lines:
		if ArchitectureScanner.is_comment_only_line(line):
			continue
		if "start_one_human_three_bots" in line:
			uses_human = true
		if "start_four_player" in line:
			uses_four_bot = true
	test_assert.check(uses_human, "play mode should use one human and three bots")
	test_assert.check(not uses_four_bot, "play mode must not use start_four_player")


static func _test_picker_lists_only_legal_actions(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(3, 0)
	var legal := session.get_legal_human_actions()
	var options := StrategicActionPicker.build_options(legal)
	test_assert.eq(options.size(), legal.size(), "picker option count should match legal actions")
	for i in options.size():
		test_assert.eq(int(options[i].get("action_id", -1)), legal[i].action_id, "picker should preserve action ids")


static func _test_submit_goes_through_session_not_action_rules(test_assert: TestAssert) -> void:
	for path in [PLAY_RUN_MODE, PICKER_SCRIPT]:
		for line in ArchitectureScanner.read_code_lines(path):
			if ArchitectureScanner.is_comment_only_line(line):
				continue
			for token in FORBIDDEN_MUTATION_TOKENS:
				test_assert.check(
					not ArchitectureScanner.line_contains_token(line, token),
					"play mode must submit via session (%s) in %s" % [token, path]
				)


static func _test_bot_advance_until_human(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(8, 0)
	StrategicPlayController.advance_until_human_or_stopped(session)
	test_assert.check(session.is_waiting_for_human(), "controller should pause on human turn")


static func _test_bank_trade_selectable_when_legal(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(9, 0)
	session.state.players[0].resources[ResourceType.Type.WOOD] = 4
	var options := StrategicActionPicker.build_options(session.get_legal_human_actions())
	var has_bank := false
	for option in options:
		if str(option.get("label", "")).contains("bank_trade") and str(option.get("label", "")).contains("wood"):
			has_bank = true
	test_assert.check(has_bank, "picker should include legal bank trade when affordable")


static func _test_full_game_human_end_turn_only_to_finish(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_one_human_three_bots(10, 0)
	var turns := 0
	while not session.finished and turns < 400:
		StrategicPlayController.advance_until_human_or_stopped(session)
		if session.is_waiting_for_human():
			var legal := session.get_legal_human_actions()
			test_assert.check(not legal.is_empty(), "human should have a legal action")
			var chosen: GameAction = legal[0]
			if not session.waiting_for_draft:
				var end_action: GameAction = null
				for action in legal:
					if action.kind == ActionKind.Kind.END_TURN:
						end_action = action
						break
				test_assert.check(end_action != null, "human should always have END_TURN outside draft")
				chosen = end_action
			session.submit_human_action(chosen)
		turns += 1
	test_assert.check(session.finished or turns < 400, "game should finish or stay within turn budget")


static func _test_play_scene_instantiates(test_assert: TestAssert) -> void:
	var scene: PackedScene = load(PLAY_SCENE)
	test_assert.check(scene != null, "play scene should load")
	var node := scene.instantiate()
	test_assert.check(node != null, "play scene should instantiate")
	if node != null:
		node.free()
