class_name EncounterRules
extends RefCounted

static func resolve_hero_vs_demon(
	state: GameState,
	hero: Hero,
	node: BoardNode,
	hero_moves: Array[StringName],
	demon_moves: Array[StringName]
) -> Array:
	var demon_count := SetupRules.get_demon_count(state, node)
	if demon_count <= 0:
		return []

	var hero_deck := CombatDeckRuntime.new()
	hero_deck.init_from(CombatResolver.default_warrior_deck(), state.rng)
	var demon_deck := CombatDeckRuntime.new()
	demon_deck.init_from(CombatResolver.default_warrior_deck(), state.rng)

	var hero_state := CombatantState.new("hero_%d" % hero.id, hero.health, hero_deck)
	var demon_state := CombatantState.new("demon", demon_count * 3, demon_deck)

	var result := CombatResolver.resolve_encounter(
		state.rng,
		hero_state,
		demon_state,
		hero_moves,
		demon_moves
	)

	var events: Array = []
	hero.health = hero_state.health
	if result["winner_id"].begins_with("hero"):
		SetupRules.set_demon_count(state, node, 0)
		events.append(EncounterCombatEvent.new(result["winner_id"], "demon", node.to_key()))
	else:
		SetupRules.set_demon_count(state, node, demon_count)
		events.append(EncounterCombatEvent.new("demon", result["winner_id"], node.to_key()))

	return events
