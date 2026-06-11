class_name TestHeuristicBot
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	_test_prefers_road_before_connected_city(test_assert, state)
	_test_prefers_best_connected_city(test_assert)
	_test_deterministic_choices(test_assert)
	_test_resolver_emits_events(test_assert)


static func _test_prefers_road_before_connected_city(test_assert: TestAssert, state: GameState) -> void:
	var choice := HeuristicBotPolicy.choose_action(state)
	test_assert.check(
		choice.kind == ActionKind.Kind.BUILD_ROAD,
		"heuristic should build a road when no connected city sites are legal yet"
	)


static func _test_prefers_best_connected_city(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var build_action := TestScenario.prepare_first_legal_city_build(state)
	test_assert.check(build_action != null, "fixture should expose at least one connected legal city build")

	var builds := _legal_builds(state)

	var best_score := -1
	var best_action: GameAction = null
	for action in builds:
		var score := _vertex_score(state, action.vertex)
		if score > best_score:
			best_score = score
			best_action = action

	var choice := HeuristicBotPolicy.choose_action(state)
	test_assert.eq(choice.action_id, best_action.action_id, "heuristic should pick highest production connected vertex")


static func _test_deterministic_choices(test_assert: TestAssert) -> void:
	var seq_a := _collect_choice_sequence(42, 5, BotTurnResolver.POLICY_HEURISTIC)
	var seq_b := _collect_choice_sequence(42, 5, BotTurnResolver.POLICY_HEURISTIC)
	test_assert.eq(seq_a, seq_b, "heuristic choices should be deterministic")

	var random_seq := _collect_choice_sequence(42, 5, BotTurnResolver.POLICY_RANDOM)
	test_assert.check(
		random_seq != seq_a,
		"heuristic should differ from random bot on fixed scenario"
	)


static func _test_resolver_emits_events(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var events := BotTurnResolver.resolve_player_turn(state, null, BotTurnResolver.POLICY_HEURISTIC)
	test_assert.check(not events.is_empty(), "heuristic resolver should emit events")


static func _legal_builds(state: GameState) -> Array[GameAction]:
	var legal := LegalActionQuery.get_legal_actions_sorted(state)
	var builds: Array[GameAction] = []
	for action in legal:
		if action.kind == ActionKind.Kind.BUILD_CITY:
			builds.append(action)
	return builds


static func _first_legal_road(state: GameState) -> GameAction:
	for action in LegalActionQuery.get_legal_actions_sorted(state):
		if action.kind == ActionKind.Kind.BUILD_ROAD:
			return action
	return null


static func _vertex_score(state: GameState, vertex: BoardNode) -> int:
	var total := 0
	for hex in state.board.get_hexes_for_vertex(vertex):
		var tile := state.board.get_tile(hex)
		for resource in ResourceType.all():
			total += tile.get_production_chance(resource)
	return total


static func _collect_choice_sequence(game_seed: int, max_choices: int, policy_name: String) -> Array[int]:
	var state := ScenarioBuilder.build_bot_ready_game(game_seed)
	var ids: Array[int] = []
	for _i in range(max_choices):
		var choice: GameAction
		if policy_name == BotTurnResolver.POLICY_RANDOM:
			choice = RandomBotPolicy.choose_action(state)
		else:
			choice = HeuristicBotPolicy.choose_action(state)
		ids.append(choice.action_id)
		if choice.kind == ActionKind.Kind.END_TURN:
			break
		ActionRules.apply(state, choice)
	return ids
