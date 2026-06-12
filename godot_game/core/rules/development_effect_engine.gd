class_name DevelopmentEffectEngine
extends RefCounted

static func apply_on_build(
	state: GameState,
	player_id: int,
	city: City,
	effects: Array
) -> Array:
	var events: Array = []
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		events.append_array(_apply_one(state, player_id, city, effect, null))
	return events


static func apply_card_on_build(state: GameState, player_id: int, city: City, card_id: String) -> Array:
	var card: DevelopmentCardDefinition = DevelopmentCatalog.get_card(card_id)
	if card == null:
		return []
	var events: Array = []
	for effect in card.effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		events.append_array(_apply_one(state, player_id, city, effect, card))
	return events


static func production_bonus_for_city(city: City, resource: ResourceType.Type) -> int:
	var bonus := 0
	for card_id in city.developments:
		var card: DevelopmentCardDefinition = DevelopmentCatalog.get_card(card_id)
		if card == null:
			continue
		for effect in card.effects:
			if typeof(effect) != TYPE_DICTIONARY:
				continue
			var effect_type := str(effect.get("type", ""))
			if effect_type == DevelopmentEffectType.PRODUCTION_FLAT:
				if _resource_from_key(str(effect.get("resource", ""))) == resource:
					bonus += int(effect.get("amount", 0))
			elif effect_type == DevelopmentEffectType.PRODUCTION_BONUS_BY_RESOURCE:
				if _resource_from_key(str(effect.get("resource", ""))) == resource:
					bonus += int(effect.get("amount", 0))
	return bonus


static func city_demon_protection_bonus(city: City) -> int:
	var bonus := 0
	for card_id in city.developments:
		var card: DevelopmentCardDefinition = DevelopmentCatalog.get_card(card_id)
		if card == null:
			continue
		for effect in card.effects:
			if typeof(effect) != TYPE_DICTIONARY:
				continue
			if str(effect.get("type", "")) == DevelopmentEffectType.CITY_DEMON_PROTECTION:
				bonus += int(effect.get("amount", 0))
	return bonus


static func hero_actions_bonus_for_player(state: GameState, player_id: int) -> int:
	var bonus := 0
	for city in state.cities:
		if city.player_id != player_id:
			continue
		for card_id in city.developments:
			var card: DevelopmentCardDefinition = DevelopmentCatalog.get_card(card_id)
			if card == null:
				continue
			for effect in card.effects:
				if typeof(effect) != TYPE_DICTIONARY:
					continue
				if str(effect.get("type", "")) == DevelopmentEffectType.HERO_ACTIONS_BONUS:
					bonus += int(effect.get("amount", 0))
	return bonus


static func trade_bonus_for_player(state: GameState, player_id: int) -> int:
	return _sum_built_effect_amount(state, player_id, DevelopmentEffectType.TRADE_BONUS)


static func draft_bonus_for_player(state: GameState, player_id: int) -> int:
	return _sum_built_effect_amount(state, player_id, DevelopmentEffectType.DRAFT_BONUS)


static func production_discount_for_player(state: GameState, player_id: int) -> int:
	return _sum_built_effect_amount(state, player_id, DevelopmentEffectType.PRODUCTION_DISCOUNT)


static func apply_build_cost_discount(base_cost: Dictionary, discount: int) -> Dictionary:
	if discount <= 0:
		return base_cost.duplicate()
	var adjusted := base_cost.duplicate()
	var remaining := discount
	for resource in ResourceType.all():
		var key := ResourceType.to_key(resource)
		if not adjusted.has(key):
			continue
		var take := mini(int(adjusted[key]), remaining)
		adjusted[key] = int(adjusted[key]) - take
		remaining -= take
		if remaining <= 0:
			break
	return adjusted


static func append_draft_peek_events(state: GameState) -> Array:
	var events: Array = []
	for player in state.players:
		if draft_bonus_for_player(state, player.id) <= 0:
			continue
		var pack: Array = state.draft_packs_by_player.get(player.id, [])
		if pack.is_empty():
			continue
		events.append(DraftPackPeekEvent.new(state.round_number, player.id, str(pack[0])))
	return events


static func _sum_built_effect_amount(state: GameState, player_id: int, effect_type: String) -> int:
	var total := 0
	for city in state.cities:
		if city.player_id != player_id:
			continue
		for card_id in city.developments:
			var card: DevelopmentCardDefinition = DevelopmentCatalog.get_card(card_id)
			if card == null:
				continue
			for effect in card.effects:
				if typeof(effect) != TYPE_DICTIONARY:
					continue
				if str(effect.get("type", "")) == effect_type:
					total += int(effect.get("amount", 0))
	return total


static func _apply_wizard_access(player: Player, card: DevelopmentCardDefinition) -> void:
	for tag in card.tags:
		var tag_str := str(tag)
		if tag_str == "wizard_encounter_unlock":
			player.wizard_encounter_unlock = true
		if tag_str == "wizard_trade_unlock":
			player.wizard_trade_unlock = true
	if not player.wizard_encounter_unlock and not player.wizard_trade_unlock:
		player.wizard_encounter_unlock = true


static func refresh_player_wizard_flags(state: GameState, player_id: int) -> void:
	var player := _player(state, player_id)
	if player == null:
		return
	player.wizard_encounter_unlock = false
	player.wizard_trade_unlock = false
	for city in state.cities:
		if city.player_id != player_id:
			continue
		for card_id in city.developments:
			var card: DevelopmentCardDefinition = DevelopmentCatalog.get_card(card_id)
			if card == null:
				continue
			for effect in card.effects:
				if typeof(effect) != TYPE_DICTIONARY:
					continue
				if str(effect.get("type", "")) == DevelopmentEffectType.WIZARD_ACCESS:
					_apply_wizard_access(player, card)


static func _player(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null


static func refresh_hero_action_budgets(state: GameState) -> void:
	for hero in state.heroes:
		var bonus := hero_actions_bonus_for_player(state, hero.player_id)
		state.hero_actions_remaining[hero.id] = GameConstants.HERO_ACTIONS_PER_TURN + bonus


static func end_game_vp_bonus(state: GameState, player_id: int) -> int:
	var bonus := 0
	var city_count := _city_count(state, player_id)
	var hero_count := _hero_count(state, player_id)
	var development_count := _development_count(state, player_id)
	for city in state.cities:
		if city.player_id != player_id:
			continue
		for card_id in city.developments:
			var card: DevelopmentCardDefinition = DevelopmentCatalog.get_card(card_id)
			if card == null:
				continue
			for effect in card.effects:
				if typeof(effect) != TYPE_DICTIONARY:
					continue
				var effect_type := str(effect.get("type", ""))
				var amount := int(effect.get("amount", 0))
				match effect_type:
					DevelopmentEffectType.END_GAME_VP_PER_CITY:
						bonus += amount * city_count
					DevelopmentEffectType.END_GAME_VP_PER_HERO:
						bonus += amount * hero_count
					DevelopmentEffectType.END_GAME_VP_PER_DEVELOPMENT:
						bonus += amount * development_count
	return bonus


static func _apply_one(
	state: GameState,
	player_id: int,
	city: City,
	effect: Dictionary,
	card: DevelopmentCardDefinition
) -> Array:
	var effect_type := str(effect.get("type", ""))
	var amount := int(effect.get("amount", 0))
	match effect_type:
		DevelopmentEffectType.VP_FLAT:
			return ScoreRules.grant_victory_points(state, player_id, amount, "development_built")
		DevelopmentEffectType.WIZARD_ACCESS:
			var player := _player(state, player_id)
			if card != null and player != null:
				_apply_wizard_access(player, card)
			return []
		DevelopmentEffectType.TRADE_BONUS, DevelopmentEffectType.DRAFT_BONUS, DevelopmentEffectType.PRODUCTION_DISCOUNT:
			return []
		DevelopmentEffectType.DEMON_CLEAR_ON_PLAY:
			var current := SetupRules.get_demon_count(state, city.vertex)
			if current > 0:
				SetupRules.set_demon_count(state, city.vertex, maxi(0, current - amount))
				return [DemonsClearedEvent.new(state.round_number, city.vertex, amount)]
			return []
		DevelopmentEffectType.HERO_SPAWN:
			if state.heroes_by_node.has(city.vertex.to_key()):
				return []
			var hero := SetupRules.place_hero(state, player_id, city.vertex)
			if hero == null:
				return []
			SetupRules.rebuild_action_space(state)
			return []
		_:
			return []


static func _city_count(state: GameState, player_id: int) -> int:
	var count := 0
	for city in state.cities:
		if city.player_id == player_id:
			count += 1
	return count


static func _hero_count(state: GameState, player_id: int) -> int:
	var count := 0
	for hero in state.heroes:
		if hero.player_id == player_id:
			count += 1
	return count


static func _development_count(state: GameState, player_id: int) -> int:
	var count := 0
	for city in state.cities:
		if city.player_id != player_id:
			continue
		count += city.developments.size()
	return count


static func _resource_from_key(key: String) -> ResourceType.Type:
	match key:
		"wood":
			return ResourceType.Type.WOOD
		"brick":
			return ResourceType.Type.BRICK
		"wheat":
			return ResourceType.Type.WHEAT
		"sheep":
			return ResourceType.Type.SHEEP
		"ore":
			return ResourceType.Type.ORE
		_:
			return ResourceType.Type.WOOD
