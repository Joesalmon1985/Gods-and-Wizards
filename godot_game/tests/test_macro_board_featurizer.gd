class_name TestMacroBoardFeaturizer
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_feature_size(test_assert)
	_test_deterministic_from_seed(test_assert)
	_test_observation_includes_board_features(test_assert)
	_test_demon_feature_normalized(test_assert)


static func _test_feature_size(test_assert: TestAssert) -> void:
	test_assert.eq(
		MacroBoardFeaturizer.BOARD_FEATURE_SIZE,
		MacroBoardFeaturizer.MAX_NODES * MacroBoardFeaturizer.PER_NODE_FEATURES,
		"board feature size constant"
	)
	var session := BotGameSession.start_four_player(5)
	var packed := MacroBoardFeaturizer.extract(session.state)
	test_assert.eq(packed.size(), MacroBoardFeaturizer.BOARD_FEATURE_SIZE, "extracted vector length")


static func _test_deterministic_from_seed(test_assert: TestAssert) -> void:
	var session_a := BotGameSession.start_four_player(123)
	var session_b := BotGameSession.start_four_player(123)
	var packed_a := MacroBoardFeaturizer.extract(session_a.state)
	var packed_b := MacroBoardFeaturizer.extract(session_b.state)
	for i in range(packed_a.size()):
		test_assert.eq(packed_a[i], packed_b[i], "board features should match for same seed at index %d" % i)


static func _test_observation_includes_board_features(test_assert: TestAssert) -> void:
	var env := MacroTrainingEnv.new()
	env.reset(9, BotTurnResolver.POLICY_HEURISTIC)
	var obs := env.get_observation(0)
	test_assert.check(obs.has("board_features_json"), "macro observation should include board_features_json")
	var parsed = JSON.parse_string(str(obs.get("board_features_json", "[]")))
	test_assert.check(typeof(parsed) == TYPE_ARRAY, "board_features_json should parse as array")
	test_assert.eq(parsed.size(), MacroBoardFeaturizer.BOARD_FEATURE_SIZE, "observation board feature count")


static func _test_demon_feature_normalized(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(15)
	var state := session.state
	var nodes := state.board.get_all_nodes_sorted()
	if nodes.is_empty():
		return
	var node := nodes[0]
	SpreadRules.try_add_demon(state, node)
	var packed := MacroBoardFeaturizer.extract(state)
	var demon_value := packed[0]
	var expected := 1.0 / float(SpreadRules.MAX_DEMONS_PER_NODE)
	test_assert.check(absf(demon_value - expected) < 0.0001, "one demon should normalize on first node")
