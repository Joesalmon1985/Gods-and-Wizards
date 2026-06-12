class_name StrategicDevelopmentViewModel
extends RefCounted


static func build(session: BotGameSession, human_player_id: int = -1) -> Dictionary:
	var state := session.state
	var player_id := _resolve_player_id(session, human_player_id)
	var city_slots: Array = []
	for city in state.cities:
		if city.player_id != player_id:
			continue
		var developments: Array = []
		for card_id in city.developments:
			developments.append(_card_entry(str(card_id)))
		city_slots.append({
			"node_id": city.vertex.to_key(),
			"slot_count": city.developments.size(),
			"max_slots": DevelopmentRules.MAX_DEVELOPMENTS_PER_CITY,
			"slots_free": DevelopmentRules.MAX_DEVELOPMENTS_PER_CITY - city.developments.size(),
			"developments": developments,
			"occupied": CityOccupationRules.is_city_suppressed(state, city.vertex),
		})

	var hand_rules: Array[String] = []
	var player := _player(state, player_id)
	if player != null:
		for card_id in player.development_hand:
			var entry := _card_entry(str(card_id))
			var rules_text: String = entry.get("rules_text", "")
			if rules_text != "":
				hand_rules.append("%s — %s" % [entry.get("label", card_id), rules_text])

	return {
		"human_player_id": player_id,
		"city_slots": city_slots,
		"hand_rules_text": hand_rules,
	}


static func format_city_slots(model: Dictionary) -> String:
	var slots: Array = model.get("city_slots", [])
	if slots.is_empty():
		return "City development slots: (no cities)"
	var lines: PackedStringArray = ["City development slots:"]
	for entry in slots:
		var occupied: String = " OCCUPIED" if entry.get("occupied", false) else ""
		lines.append(
			"  %s — %d/%d built%s" % [
				entry.get("node_id", "?"),
				int(entry.get("slot_count", 0)),
				int(entry.get("max_slots", DevelopmentRules.MAX_DEVELOPMENTS_PER_CITY)),
				occupied,
			]
		)
		for dev in entry.get("developments", []):
			lines.append("    • %s" % dev.get("label", "?"))
	return "\n".join(lines)


static func format_hand_rules(model: Dictionary) -> String:
	var rules: Array = model.get("hand_rules_text", [])
	if rules.is_empty():
		return "Card rules: (none in hand)"
	var lines: PackedStringArray = ["Card rules:"]
	for line in rules:
		lines.append("  • %s" % line)
	return "\n".join(lines)


static func _card_entry(card_id: String) -> Dictionary:
	var card := DevelopmentCatalog.get_card(card_id)
	if card == null:
		return {"id": card_id, "label": card_id, "rules_text": ""}
	return {
		"id": card_id,
		"label": "%s (%d VP)" % [card.name, card.vp],
		"rules_text": card.rules_text,
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
