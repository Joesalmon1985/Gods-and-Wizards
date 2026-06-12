class_name EncounterSessionRules
extends RefCounted

const HERO_LOADOUT := "hero_patrol"
const DEMON_LOADOUT := "demon_breach"


static func derive_encounter_id(state: GameState, node_key: String, hero_id: int) -> String:
	return "enc_%d_%s_h%d" % [state.seed, node_key.replace("|", "_"), hero_id]


static func derive_combat_seed(state: GameState, encounter_id: String) -> int:
	var combined := "%d:%s" % [state.seed, encounter_id]
	var hash := combined.hash()
	return absi(hash % 1_000_000) + 1


static func derive_loadouts(_state: GameState, _hero_player_id: int) -> Dictionary:
	return {
		"hero_loadout_id": HERO_LOADOUT,
		"demon_loadout_id": DEMON_LOADOUT,
	}
