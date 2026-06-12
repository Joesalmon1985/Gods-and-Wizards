class_name StrategicDraftViewModel
extends RefCounted


static func build(session: BotGameSession, human_player_id: int = -1) -> Dictionary:
	var state := session.state
	var player_id := _resolve_player_id(session, human_player_id)
	var player := _player(state, player_id)
	var pack: Array = state.draft_packs_by_player.get(player_id, [])
	var pack_cards: Array = []
	for card_id in pack:
		pack_cards.append(_card_entry(str(card_id)))

	var hand_cards: Array = []
	if player != null:
		for card_id in player.development_hand:
			hand_cards.append(_card_entry(str(card_id)))

	return {
		"human_player_id": player_id,
		"waiting_for_draft": session.waiting_for_draft,
		"draft_age": state.draft_age,
		"draft_round_in_age": state.draft_rounds_in_age,
		"phase": TurnPhase.to_key(state.current_phase),
		"pack_cards": pack_cards,
		"pack_size": pack_cards.size(),
		"hand_cards": hand_cards,
		"hand_size": hand_cards.size(),
		"pending_pick": state.draft_pending_picks.has(player_id),
		"infection_rate": state.infection_rate,
		"hero_actions_remaining": state.hero_actions_remaining.duplicate(),
	}


static func format_pack_summary(model: Dictionary) -> String:
	var cards: Array = model.get("pack_cards", [])
	if cards.is_empty():
		return "Draft pack: (empty)"
	var lines: PackedStringArray = [
		"Draft pack (age %d, %d cards):" % [int(model.get("draft_age", 1)), cards.size()],
	]
	for entry in cards:
		lines.append("  • %s" % entry.get("label", "?"))
	return "\n".join(lines)


static func format_hand_summary(model: Dictionary) -> String:
	var cards: Array = model.get("hand_cards", [])
	if cards.is_empty():
		return "Development hand: (empty)"
	var lines: PackedStringArray = ["Development hand (%d):" % cards.size()]
	for entry in cards:
		lines.append("  • %s" % entry.get("label", "?"))
	return "\n".join(lines)


static func _card_entry(card_id: String) -> Dictionary:
	var card := DevelopmentCatalog.get_card(card_id)
	if card == null:
		return {"id": card_id, "label": card_id, "rules_text": ""}
	return {
		"id": card_id,
		"label": "%s (%d VP)" % [card.name, card.vp],
		"rules_text": card.rules_text,
		"age": card.age,
		"category": card.category,
	}


static func _resolve_player_id(session: BotGameSession, human_player_id: int) -> int:
	if human_player_id >= 0:
		return human_player_id
	if not session.human_player_ids.is_empty():
		return int(session.human_player_ids[0])
	return TurnRules.get_active_player_id(session.state)


static func _player(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null
