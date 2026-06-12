class_name DraftBotPolicy
extends RefCounted

static func choose_card_id(state: GameState, player_id: int) -> String:
	var pack: Array = state.draft_packs_by_player.get(player_id, [])
	if pack.is_empty():
		return ""
	var best_id := ""
	var best_score := -999999
	for card_id in pack:
		var score := _score_card(state, str(card_id), player_id)
		if score > best_score or (score == best_score and (best_id == "" or str(card_id) < best_id)):
			best_score = score
			best_id = str(card_id)
	return best_id


static func _score_card(state: GameState, card_id: String, player_id: int) -> int:
	var card: DevelopmentCardDefinition = DevelopmentCatalog.get_card(card_id)
	if card == null:
		return -1000
	var score := 0
	for effect in card.effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		score += _score_effect(state, card, effect)
	score -= _build_cost_penalty(card)
	return score


static func _score_effect(_state: GameState, card: DevelopmentCardDefinition, effect: Dictionary) -> int:
	var effect_type := str(effect.get("type", ""))
	var amount := int(effect.get("amount", 0))
	match card.age:
		1:
			if effect_type in [DevelopmentEffectType.PRODUCTION_FLAT, DevelopmentEffectType.TRADE_BONUS]:
				return 10 + amount
			if effect_type == DevelopmentEffectType.VP_FLAT:
				return 4 + amount
		2:
			if effect_type in [
				DevelopmentEffectType.HERO_ACTIONS_BONUS,
				DevelopmentEffectType.CITY_DEMON_PROTECTION,
				DevelopmentEffectType.TRADE_BONUS,
				DevelopmentEffectType.HERO_SPAWN,
			]:
				return 12 + amount
			if effect_type == DevelopmentEffectType.PRODUCTION_FLAT:
				return 8 + amount
		3:
			if effect_type in [
				DevelopmentEffectType.VP_FLAT,
				DevelopmentEffectType.END_GAME_VP_PER_CITY,
				DevelopmentEffectType.END_GAME_VP_PER_HERO,
				DevelopmentEffectType.DEMON_CLEAR_ON_PLAY,
			]:
				return 15 + amount
			if effect_type == DevelopmentEffectType.WIZARD_ACCESS:
				return 10
	return 2


static func _build_cost_penalty(card: DevelopmentCardDefinition) -> int:
	var total := 0
	for resource_key in card.cost.keys():
		total += int(card.cost[resource_key])
	return total * 2
