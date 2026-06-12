class_name DraftRules
extends RefCounted

const PACK_SIZE := 8
const MAX_AGES := 3


static func initialize_for_game(state: GameState) -> void:
	state.draft_packs_by_player.clear()
	state.draft_age = 1
	state.draft_rounds_in_age = 0
	for player in state.players:
		player.development_hand.clear()
		state.draft_packs_by_player[player.id] = _build_pack(state, player.id)


static func advance_round_end(state: GameState) -> Array:
	var events: Array = []
	if state.draft_packs_by_player.is_empty():
		return events

	for player in state.players:
		var pack: Array = state.draft_packs_by_player.get(player.id, [])
		if pack.is_empty():
			continue
		var card_id: String = pack.pop_front()
		player.development_hand.append(card_id)
		events.append(
			DraftCardPickedEvent.new(state.round_number, player.id, card_id, state.draft_age)
		)

	_pass_packs_left(state)
	state.draft_rounds_in_age += 1

	if state.draft_rounds_in_age >= PACK_SIZE:
		_advance_age(state)
		events.append(DraftAgeAdvancedEvent.new(state.round_number, state.draft_age))

	return events


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
		for player in state.players:
			state.draft_packs_by_player[player.id] = _build_pack(state, player.id)


static func _build_pack(state: GameState, player_id: int) -> Array[String]:
	var catalog := DevelopmentCatalog.all_ids_sorted()
	var pack: Array[String] = []
	for i in PACK_SIZE:
		var index := (player_id + i + state.draft_age) % catalog.size()
		pack.append(catalog[index])
	return pack
