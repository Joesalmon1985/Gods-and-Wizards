class_name TestMacroLegalActionLayout
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_compact_mask_matches_training_layout(test_assert)
	_test_compact_action_is_legal(test_assert)
	_test_evaluator_zero_illegal_with_heuristic_teacher(test_assert)


static func _test_compact_mask_matches_training_layout(test_assert: TestAssert) -> void:
	var env := MacroTrainingEnv.new()
	env.reset(42, BotTurnResolver.POLICY_HEURISTIC)
	var player_id := env.session.get_active_player_id()
	var view := env.get_legal_action_view(player_id)
	var compact := MacroLegalActionLayout.build_compact(view)
	test_assert.eq(compact["mask"].size(), MacroLegalActionLayout.MAX_COMPACT_SLOTS, "compact mask width")
	var legal_count := 0
	for bit in compact["mask"]:
		if bool(bit):
			legal_count += 1
	test_assert.eq(legal_count, int(compact["slot_count"]), "compact legal count matches mask bits")


static func _test_compact_action_is_legal(test_assert: TestAssert) -> void:
	var env := MacroTrainingEnv.new()
	env.reset(7, BotTurnResolver.POLICY_HEURISTIC)
	var player_id := env.session.get_active_player_id()
	var view := env.get_legal_action_view(player_id)
	var compact := MacroLegalActionLayout.build_compact(view)
	for slot in range(int(compact["slot_count"])):
		var action := MacroLegalActionLayout.action_from_compact_slot(
			view,
			env.session.state,
			slot,
			compact
		)
		test_assert.check(action != null, "compact slot should map to legal action")
		var legal := env.get_legal_actions(player_id)
		test_assert.check(_contains_action(legal, action), "mapped action should be legal")


static func _test_evaluator_zero_illegal_with_heuristic_teacher(test_assert: TestAssert) -> void:
	var net := TinyNeuralNetwork.from_seed(
		MacroFeatureFeaturizer.FEATURE_SIZE,
		MacroLegalActionLayout.MAX_COMPACT_SLOTS,
		99
	)
	var env := MacroTrainingEnv.new()
	env.reset(11, BotTurnResolver.POLICY_HEURISTIC)
	var illegal := 0
	var steps := 0
	while not env.is_game_over() and steps < 12:
		var player_id := env.session.get_active_player_id()
		var view := env.get_legal_action_view(player_id)
		var teacher := env.choose_policy_action()
		var compact := MacroLegalActionLayout.build_compact(view)
		var target := _compact_index_for_action(view, compact, teacher)
		if target >= 0:
			net.train_supervised_step(
				MacroFeatureFeaturizer.extract(env.get_observation(player_id)),
				target,
				0.2
			)
		var logits := net.forward(MacroFeatureFeaturizer.extract(env.get_observation(player_id)))
		var pick := net.choose_action_index(logits, compact["mask"])
		var action := MacroLegalActionLayout.action_from_compact_slot(
			view,
			env.session.state,
			pick,
			compact
		)
		if action == null:
			illegal += 1
			action = env.get_legal_actions(player_id)[0]
		env.step(action)
		steps += 1
	test_assert.eq(illegal, 0, "compact layout inference should not produce illegal picks")


static func _compact_index_for_action(
	view: LegalActionView,
	compact: Dictionary,
	action: GameAction
) -> int:
	if action == null:
		return -1
	var global_indices: Array = compact.get("global_indices", [])
	for slot in range(global_indices.size()):
		var global_i: int = int(global_indices[slot])
		if view.action_ids[global_i] == action.action_id:
			return slot
	return -1


static func _contains_action(legal: Array, action: GameAction) -> bool:
	for candidate in legal:
		if candidate.action_id == action.action_id:
			return true
	return false
