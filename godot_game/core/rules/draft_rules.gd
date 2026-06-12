class_name DraftRules
extends RefCounted

const PACK_SIZE := 8
const MAX_AGES := 3
const CARDS_PER_AGE := 32


static func initialize_for_game(state: GameState) -> void:
	state.draft_packs_by_player.clear()
	state.draft_age = 1
	state.draft_rounds_in_age = 0
	for player in state.players:
		player.development_hand.clear()
	_deal_packs_for_current_age(state)


static func advance_round_end(state: GameState) -> Array:
	return advance_round_end_with_picks(state, _default_picks_for_step(state))


static func advance_round_end_with_picks(state: GameState, picks_by_player: Dictionary) -> Array:
	var events: Array = []
	if state.draft_packs_by_player.is_empty():
		return events
	if picks_by_player.is_empty():
		return events

	var resolved := _resolve_picks_or_empty(state, picks_by_player)
	if resolved.is_empty():
		return events

	for player_id in resolved.keys():
		var card_id: String = resolved[player_id]
		var player := _player(state, int(player_id))
		if player == null:
			continue
		player.development_hand.append(card_id)
		events.append(
			DraftCardPickedEvent.new(state.round_number, player.id, card_id, state.draft_age)
		)

	_pass_packs_left(state)
	state.draft_rounds_in_age += 1

	if state.draft_rounds_in_age >= PACK_SIZE:
		var previous_age := state.draft_age
		_advance_age(state)
		if state.draft_age != previous_age:
			events.append(DraftAgeAdvancedEvent.new(state.round_number, state.draft_age))

	return events


static func build_shuffled_age_deck(state: GameState, age: int) -> Array[String]:
	var cards := DevelopmentCatalog.ids_for_age(age)
	return _shuffle_copy(cards, _shuffle_seed(state, age))


static func apply_draft_pick(state: GameState, player_id: int, card_id: String) -> bool:
	var picks := _default_picks_for_step(state)
	if not _is_legal_pick(state, player_id, card_id):
		return false
	picks[player_id] = card_id
	return not advance_round_end_with_picks(state, picks).is_empty()


static func _deal_packs_for_current_age(state: GameState) -> void:
	var deck := build_shuffled_age_deck(state, state.draft_age)
	var player_count := state.players.size()
	for player_index in player_count:
		var start := player_index * PACK_SIZE
		var pack: Array[String] = []
		for i in PACK_SIZE:
			pack.append(deck[start + i])
		var player := state.players[player_index]
		state.draft_packs_by_player[player.id] = pack


static func _resolve_picks_or_empty(state: GameState, picks_by_player: Dictionary) -> Dictionary:
	var player_count := state.players.size()
	if picks_by_player.size() != player_count:
		return {}

	var resolved: Dictionary = {}
	for player in state.players:
		if not picks_by_player.has(player.id):
			return {}
		var card_id: String = str(picks_by_player[player.id])
		if not _is_legal_pick(state, player.id, card_id):
			return {}
		resolved[player.id] = card_id

	for player_id in resolved.keys():
		var pack: Array = state.draft_packs_by_player.get(int(player_id), [])
		pack.erase(resolved[player_id])
		state.draft_packs_by_player[int(player_id)] = pack

	return resolved


static func _default_picks_for_step(state: GameState) -> Dictionary:
	var picks: Dictionary = {}
	for player in state.players:
		var pack: Array = state.draft_packs_by_player.get(player.id, [])
		if pack.is_empty():
			continue
		picks[player.id] = str(pack[0])
	return picks


static func _is_legal_pick(state: GameState, player_id: int, card_id: String) -> bool:
	var pack: Array = state.draft_packs_by_player.get(player_id, [])
	return card_id in pack


static func _pass_packs_left(state: GameState) -> void:
	var player_count := state.players.size()
	if player_count <= 0:
		return
	var new_packs: Dictionary = {}
	for player in state.players:
		var source_id := (player.id - 1 + player_count) % player_count
		new_packs[player.id] = state.draft_packs_by_player.get(source_id, []).duplicate()
	state.draft_packs_by_player = new_packs


static func _advance_age(state: GameState) -> void:
	state.draft_rounds_in_age = 0
	if state.draft_age < MAX_AGES:
		state.draft_age += 1
		state.infection_rate += 1
		_deal_packs_for_current_age(state)


static func _shuffle_copy(items: Array[String], shuffle_seed: int) -> Array[String]:
	var copy := items.duplicate()
	var rng := GameRng.new()
	rng.seed(shuffle_seed)
	for i in range(copy.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: String = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy


static func _shuffle_seed(state: GameState, age: int) -> int:
	return int(state.seed) * 1009 + age * 9176


static func _player(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null
