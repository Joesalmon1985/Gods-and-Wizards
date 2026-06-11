class_name DevelopmentCatalog
extends RefCounted

const WATCHTOWER_ID := "watchtower"
const GRANARY_ID := "granary"
const SHRINE_ID := "shrine"


static func all_ids_sorted() -> Array[String]:
	return [WATCHTOWER_ID, GRANARY_ID, SHRINE_ID]


static func has_id(development_id: String) -> bool:
	return development_id in all_ids_sorted()


static func display_name(development_id: String) -> String:
	match development_id:
		WATCHTOWER_ID:
			return "Watchtower"
		GRANARY_ID:
			return "Granary"
		SHRINE_ID:
			return "Shrine"
		_:
			return development_id.capitalize()


static func victory_points_bonus(development_id: String) -> int:
	match development_id:
		SHRINE_ID:
			return 1
		_:
			return 0


static func resolve_build_id(requested_id: String) -> String:
	if requested_id != "" and has_id(requested_id):
		return requested_id
	return WATCHTOWER_ID
