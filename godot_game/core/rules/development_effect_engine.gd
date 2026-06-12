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
		events.append_array(_apply_one(state, player_id, city, effect))
	return events


static func apply_card_on_build(state: GameState, player_id: int, city: City, card_id: String) -> Array:
	var card: DevelopmentCardDefinition = DevelopmentCatalog.get_card(card_id)
	if card == null:
		return []
	return apply_on_build(state, player_id, city, card.effects)


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
	effect: Dictionary
) -> Array:
	var effect_type := str(effect.get("type", ""))
	var amount := int(effect.get("amount", 0))
	match effect_type:
		DevelopmentEffectType.VP_FLAT:
			return ScoreRules.grant_victory_points(state, player_id, amount, "development_built")
		DevelopmentEffectType.WIZARD_ACCESS, DevelopmentEffectType.TRADE_BONUS, DevelopmentEffectType.DRAFT_BONUS, DevelopmentEffectType.PRODUCTION_DISCOUNT:
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
