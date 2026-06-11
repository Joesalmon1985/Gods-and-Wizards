class_name BalanceConfig
extends RefCounted

const DEFAULT_PATH := "res://data/balance/default_balance.json"

static var _loaded: Dictionary = {}


static func reset_cache() -> void:
	_loaded = {}


static func get_config(path: String = DEFAULT_PATH) -> Dictionary:
	if not _loaded.is_empty():
		return _loaded.duplicate(true)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_loaded = defaults()
		return _loaded.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_loaded = _merge_with_defaults(parsed)
	else:
		_loaded = defaults()
	return _loaded.duplicate(true)


static func load_from_path(path: String) -> Dictionary:
	reset_cache()
	return get_config(path)


static func defaults() -> Dictionary:
	return {
		"vp_to_win": GameConstants.VP_TO_WIN,
		"breach_limit": GameConstants.BREACH_LIMIT,
		"vp_per_city": GameConstants.VP_PER_CITY,
		"max_turns_default": BotGameSession.DEFAULT_MAX_PLAYER_TURNS,
		"build_city": _costs_to_dict(BuildCosts.BUILD_CITY),
		"build_road": _costs_to_dict(BuildCosts.BUILD_ROAD),
	}


static func max_turns_default() -> int:
	return int(get_config().get("max_turns_default", BotGameSession.DEFAULT_MAX_PLAYER_TURNS))


static func vp_to_win() -> int:
	return int(get_config().get("vp_to_win", GameConstants.VP_TO_WIN))


static func breach_limit() -> int:
	return int(get_config().get("breach_limit", GameConstants.BREACH_LIMIT))


static func vp_per_city() -> int:
	return int(get_config().get("vp_per_city", GameConstants.VP_PER_CITY))


static func build_city_costs() -> Dictionary:
	return _dict_to_costs(get_config().get("build_city", {}), BuildCosts.BUILD_CITY)


static func build_road_costs() -> Dictionary:
	return _dict_to_costs(get_config().get("build_road", {}), BuildCosts.BUILD_ROAD)


static func _merge_with_defaults(overrides: Dictionary) -> Dictionary:
	var merged := defaults()
	for key in overrides.keys():
		if overrides[key] is Dictionary and merged.get(key) is Dictionary:
			var nested: Dictionary = merged[key].duplicate(true)
			for nested_key in overrides[key].keys():
				nested[nested_key] = overrides[key][nested_key]
			merged[key] = nested
		else:
			merged[key] = overrides[key]
	return merged


static func _costs_to_dict(costs: Dictionary) -> Dictionary:
	var result := {}
	for resource in costs.keys():
		result[ResourceType.to_key(resource)] = costs[resource]
	return result


static func _dict_to_costs(data, fallback: Dictionary) -> Dictionary:
	if not data is Dictionary:
		return fallback.duplicate()
	var costs := fallback.duplicate()
	for resource in ResourceType.all():
		var key := ResourceType.to_key(resource)
		if data.has(key):
			costs[resource] = int(data[key])
	return costs
