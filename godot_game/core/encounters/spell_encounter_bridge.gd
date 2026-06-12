class_name SpellEncounterBridge
extends RefCounted


static func create_session(state: GameState, node_key: String, hero_id: int) -> SpellCombatSession:
	var encounter_id := EncounterSessionRules.derive_encounter_id(state, node_key, hero_id)
	var combat_seed := EncounterSessionRules.derive_combat_seed(state, encounter_id)
	var loadouts := EncounterSessionRules.derive_loadouts(state, _hero_player_id(state, hero_id))
	return SpellCombatSession.start_duel(
		combat_seed,
		str(loadouts.get("hero_loadout_id", EncounterSessionRules.HERO_LOADOUT)),
		str(loadouts.get("demon_loadout_id", EncounterSessionRules.DEMON_LOADOUT))
	)


static func run_to_completion(session: SpellCombatSession, max_steps: int = 120) -> SpellCombatSession:
	var steps := 0
	while not session.finished and steps < max_steps:
		session.step_deterministic_policy()
		steps += 1
	return session


static func apply_outcome(
	state: GameState,
	combat_session: SpellCombatSession,
	hero_id: int,
	node_key: String
) -> Array:
	if not combat_session.finished:
		return []
	var hero_player_id := _hero_player_id(state, hero_id)
	var hero_won := combat_session.winner_id == EncounterSessionRules.HERO_LOADOUT
	if not hero_won:
		return []
	var node := _node_from_key(state, node_key)
	if node == null:
		return []
	return ContactResolutionRules.resolve_after_hero_enters(state, node, hero_id)


static func _hero_player_id(state: GameState, hero_id: int) -> int:
	var hero: Hero = state.heroes_by_id.get(hero_id)
	if hero == null:
		return -1
	return hero.player_id


static func _node_from_key(state: GameState, node_key: String) -> BoardNode:
	for node in state.board.get_all_nodes_sorted():
		if node.to_key() == node_key:
			return node
	return null
