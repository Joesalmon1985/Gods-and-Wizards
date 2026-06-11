class_name TestActionSpace
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state_a := SetupRules.create_game(42)
	var state_b := SetupRules.create_game(42)
	var state_c := SetupRules.create_game(99)

	test_assert.check(state_a.action_space != null, "create_game should attach an action space")
	test_assert.eq(state_a.action_space.size(), state_b.action_space.size(), "same seed should yield same action space size")
	test_assert.check(
		state_a.action_space.size() > 1,
		"action space should include END_TURN plus build slots"
	)

	var end_turn := state_a.action_space.get_action(0)
	test_assert.check(end_turn != null, "action_id 0 should exist")
	test_assert.eq(end_turn.action_id, 0, "END_TURN should be action_id 0")
	test_assert.eq(end_turn.kind, ActionKind.Kind.END_TURN, "action_id 0 should be END_TURN")

	var build_count := 0
	for action in state_a.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_CITY:
			build_count += 1
			test_assert.check(action.vertex != null, "BUILD_CITY actions should carry a vertex payload")

	var vertex_count := state_a.board.get_all_vertices_sorted().size()
	test_assert.eq(build_count, vertex_count, "each board vertex should have one BUILD_CITY slot")

	var build_ids: Array[int] = []
	for action in state_a.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_CITY:
			build_ids.append(action.action_id)
	for i in range(build_ids.size() - 1):
		test_assert.check(
			build_ids[i] < build_ids[i + 1],
			"BUILD_CITY action_ids should be strictly increasing"
		)

	var action := state_a.action_space.get_action(build_ids[0])
	var roundtrip := GameAction.from_dict(action.to_dict())
	test_assert.check(roundtrip.equals(action), "GameAction.to_dict should round-trip")

	test_assert.eq(
		state_a.action_space.to_layout_key(),
		state_b.action_space.to_layout_key(),
		"same seed should produce identical action space layout"
	)
	test_assert.check(
		state_a.action_space.to_layout_key() != state_c.action_space.to_layout_key()
		or state_a.action_space.size() == state_c.action_space.size(),
		"different seeds should be comparable without crashing"
	)

	var view := LegalActionView.new(state_a.action_space)
	test_assert.eq(view.action_ids.size(), state_a.action_space.size(), "legal view should mirror action space size")
	test_assert.eq(view.legal_mask.size(), state_a.action_space.size(), "legal view mask should mirror action space size")

	var layout_a := ActionSpace.from_board(state_a.board).to_layout_key()
	var layout_b := ActionSpace.from_board(state_a.board).to_layout_key()
	test_assert.eq(layout_a, layout_b, "action space layout should be independent of RNG")

