class_name TestBotPolicy
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := TestScenario.build_bot_ready_game(42)

	_test_prefers_build_over_pass(test_assert, state)
	_test_pass_when_only_option(test_assert)
	_test_deterministic_choice(test_assert)
	_test_bot_choice_sequence(test_assert)
	_test_turn_resolver_builds_before_pass(test_assert)


static func _test_prefers_build_over_pass(test_assert: TestAssert, state: GameState) -> void:
	var choice := BotPolicy.choose_action(state)
	test_assert.check(choice.kind != ActionKind.Kind.END_TURN, "bot should prefer BUILD_CITY when available")


static func _test_pass_when_only_option(test_assert: TestAssert) -> void:
	var state := TestScenario.build_bot_ready_game(42)
	for action in LegalActionQuery.get_legal_actions_sorted(state):
		if action.kind == ActionKind.Kind.BUILD_CITY:
			ActionRules.apply(state, action)

	var choice := BotPolicy.choose_action(state)
	test_assert.eq(choice.kind, ActionKind.Kind.END_TURN, "bot should END_TURN when no build remains")


static func _test_deterministic_choice(test_assert: TestAssert) -> void:
	var state_a := TestScenario.build_bot_ready_game(42)
	var state_b := TestScenario.build_bot_ready_game(42)
	var choice_a := BotPolicy.choose_action(state_a)
	var choice_b := BotPolicy.choose_action(state_b)
	test_assert.eq(choice_a.action_id, choice_b.action_id, "same seed should pick same action")


static func _test_bot_choice_sequence(test_assert: TestAssert) -> void:
	var first := _collect_bot_choice_sequence(42, 5)
	var second := _collect_bot_choice_sequence(42, 5)
	test_assert.eq(first, second, "same seed should produce identical bot choice sequence")


static func _test_turn_resolver_builds_before_pass(test_assert: TestAssert) -> void:
	var state := TestScenario.build_bot_ready_game(42)
	var city_count_before := state.cities.size()
	var events := BotTurnResolver.resolve_player_turn(state)

	var built := false
	var ended := false
	for event in events:
		if event is CityBuiltEvent:
			built = true
		if event is TurnEndedEvent:
			ended = true

	test_assert.check(built, "bot turn should build at least once before ending")
	test_assert.check(ended, "bot turn should end with END_TURN")
	test_assert.check(state.cities.size() > city_count_before, "bot turn should increase city count")


static func _collect_bot_choice_sequence(game_seed: int, max_choices: int) -> Array[int]:
	var state := TestScenario.build_bot_ready_game(game_seed)
	var ids: Array[int] = []
	for _i in range(max_choices):
		var choice := BotPolicy.choose_action(state)
		ids.append(choice.action_id)
		if choice.kind == ActionKind.Kind.END_TURN:
			break
		ActionRules.apply(state, choice)
	return ids
