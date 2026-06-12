class_name MicroCombatTelemetrySchema
extends RefCounted

const SCHEMA_VERSION := "micro_combat_v2"
const SPELL_CATALOG_VERSION := "spell_catalog_v1"

const STEP_COLUMNS: Array[String] = [
	"telemetry_schema_version",
	"episode_id",
	"encounter_id",
	"combat_step_index",
	"seed",
	"step_index",
	"spell_catalog_version",
	"loadout_a_id",
	"loadout_b_id",
	"sim_time",
	"active_combatant_id",
	"combatant_id",
	"actor_id",
	"health",
	"mana",
	"opponent_id",
	"opponent_health",
	"opponent_mana",
	"loadout_spell_ids_json",
	"legal_spell_ids_json",
	"legal_mask_json",
	"selected_action",
	"pre_observation_json",
	"post_observation_json",
	"reward",
	"reward_components_json",
	"terminal",
	"winner_id",
	"timeline_events_json",
]
