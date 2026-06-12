class_name StrategicCardDisplayPresenter
extends RefCounted


static func format_card_line(card_id: String) -> String:
	var card := DevelopmentCatalog.get_card(card_id)
	if card == null:
		return card_id
	var cost_parts: PackedStringArray = []
	for key in card.cost.keys():
		cost_parts.append("%s:%d" % [key, int(card.cost[key])])
	var cost_text := ", ".join(cost_parts) if not cost_parts.is_empty() else "free"
	return "%s | age %d | %s | cost %s" % [card.name, card.age, card.category, cost_text]


static func format_hand_lines(card_ids: Array) -> PackedStringArray:
	var lines: PackedStringArray = []
	for card_id in card_ids:
		lines.append(format_card_line(str(card_id)))
	return lines
