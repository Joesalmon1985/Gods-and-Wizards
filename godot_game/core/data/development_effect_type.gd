class_name DevelopmentEffectType
extends RefCounted

const VP_FLAT := "vp_flat"
const PRODUCTION_FLAT := "production_flat"
const PRODUCTION_BONUS_BY_RESOURCE := "production_bonus_by_resource"
const PRODUCTION_DISCOUNT := "production_discount"
const HERO_ACTIONS_BONUS := "hero_actions_bonus"
const HERO_SPAWN := "hero_spawn"
const CITY_DEMON_PROTECTION := "city_demon_protection"
const DEMON_CLEAR_ON_PLAY := "demon_clear_on_play"
const TRADE_BONUS := "trade_bonus"
const DRAFT_BONUS := "draft_bonus"
const END_GAME_VP_PER_CITY := "end_game_vp_per_city"
const END_GAME_VP_PER_HERO := "end_game_vp_per_hero"
const END_GAME_VP_PER_DEVELOPMENT := "end_game_vp_per_development"
const WIZARD_ACCESS := "wizard_access"


static func all_known() -> Array[String]:
	return [
		VP_FLAT,
		PRODUCTION_FLAT,
		PRODUCTION_BONUS_BY_RESOURCE,
		PRODUCTION_DISCOUNT,
		HERO_ACTIONS_BONUS,
		HERO_SPAWN,
		CITY_DEMON_PROTECTION,
		DEMON_CLEAR_ON_PLAY,
		TRADE_BONUS,
		DRAFT_BONUS,
		END_GAME_VP_PER_CITY,
		END_GAME_VP_PER_HERO,
		END_GAME_VP_PER_DEVELOPMENT,
		WIZARD_ACCESS,
	]


static func is_known(effect_type: String) -> bool:
	return effect_type in all_known()
