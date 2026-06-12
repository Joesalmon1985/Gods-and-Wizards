class_name TestDevelopmentEffectEngine
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_vp_flat(test_assert)
	_test_production_flat_bonus(test_assert)
	_test_hero_actions_bonus(test_assert)
	_test_demon_clear_on_play(test_assert)


static func _test_vp_flat(test_assert: TestAssert) -> void:
	var events := DevelopmentEffectEngine.apply_on_build(
		_make_state(),
		0,
		_make_city(),
		[{"type": DevelopmentEffectType.VP_FLAT, "amount": 2}]
	)
	test_assert.check(events.size() >= 1, "vp_flat should emit scoring event")


static func _test_production_flat_bonus(test_assert: TestAssert) -> void:
	var amount := DevelopmentEffectEngine.production_bonus_for_city(
		_make_city_with_card("lumber_camp_a1"),
		ResourceType.Type.WOOD
	)
	test_assert.eq(amount, 1, "lumber camp should grant +1 wood production")


static func _test_hero_actions_bonus(test_assert: TestAssert) -> void:
	var state := _make_state()
	var hero := SetupRules.place_hero(state, 0, state.cities[0].vertex)
	state.cities[0].developments.append("ranger_post_a1")
	DevelopmentEffectEngine.refresh_hero_action_budgets(state)
	test_assert.eq(
		int(state.hero_actions_remaining.get(hero.id, 0)),
		GameConstants.HERO_ACTIONS_PER_TURN + 1,
		"hero actions bonus should increase budget"
	)


static func _test_demon_clear_on_play(test_assert: TestAssert) -> void:
	var state := _make_state()
	SetupRules.set_demon_count(state, state.cities[0].vertex, 2)
	DevelopmentEffectEngine.apply_on_build(
		state,
		0,
		state.cities[0],
		[{"type": DevelopmentEffectType.DEMON_CLEAR_ON_PLAY, "amount": 1}]
	)
	test_assert.eq(SetupRules.get_demon_count(state, state.cities[0].vertex), 1, "should clear one demon")


static func _make_state() -> GameState:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	GameStartRules.start_game(state)
	return state


static func _make_city() -> City:
	var state := _make_state()
	return state.cities[0]


static func _make_city_with_card(card_id: String) -> City:
	var city := _make_city()
	city.developments.append(card_id)
	return city
