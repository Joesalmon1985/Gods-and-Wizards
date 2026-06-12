class_name TurnLifecycleRules
extends RefCounted

static func begin_game(state: GameState) -> void:
	state.turn_number = 1
	state.current_phase = TurnPhase.Phase.ACTIVE_PLAYER
	on_turn_start(state)


static func on_turn_start(state: GameState) -> void:
	if state.game_finished:
		state.current_phase = TurnPhase.Phase.GAME_OVER
		return
	state.current_phase = TurnPhase.Phase.ACTIVE_PLAYER
	state.turn_scope_flags.clear()
	_reset_hero_action_budgets(state)


static func _reset_hero_action_budgets(state: GameState) -> void:
	state.hero_actions_remaining.clear()
	var active := TurnRules.get_active_player(state)
	if active == null:
		return
	var bonus := DevelopmentEffectEngine.hero_actions_bonus_for_player(state, active.id)
	for hero in state.heroes:
		if hero.player_id == active.id:
			state.hero_actions_remaining[hero.id] = GameConstants.HERO_ACTIONS_PER_TURN + bonus


static func on_turn_end(state: GameState, _ending_player_id: int) -> void:
	TradeOfferRules.clear_turn_trade_state(state)


static func on_round_start(state: GameState) -> void:
	state.current_phase = TurnPhase.Phase.ROUND_START
