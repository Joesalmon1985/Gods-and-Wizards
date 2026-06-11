class_name MicroCombatTelemetrySchema
extends RefCounted

const SCHEMA_VERSION := "micro_combat_v1"

const STEP_COLUMNS: Array[String] = [
	"telemetry_schema_version",
	"seed",
	"step_index",
	"sim_time",
	"active_combatant_id",
	"combatant_id",
	"health",
	"mana",
	"opponent_id",
	"opponent_health",
	"opponent_mana",
	"loadout_spell_ids_json",
	"legal_spell_ids_json",
	"legal_mask_json",
	"selected_spell_id",
	"reward",
	"terminal",
	"winner_id",
	"timeline_event_summary",
]
