class_name MacroTrainingTelemetrySchema
extends RefCounted

const SCHEMA_VERSION := "macro_training_v2"
const LEGACY_V1_COLUMN_COUNT := 23

const STEP_COLUMNS: Array[String] = [
	"telemetry_schema_version",
	"seed",
	"step_index",
	"player_id",
	"round_number",
	"active_player_id",
	"policy_name",
	"victory_points",
	"resources_json",
	"city_count",
	"road_count",
	"breach_count",
	"total_demons",
	"game_finished",
	"winner_id",
	"legal_action_ids_json",
	"legal_mask_json",
	"selected_action_id",
	"selected_action_kind",
	"reward",
	"terminal",
	"event_summaries",
	"phase",
	"episode_id",
	"rules_version",
	"draft_age",
	"infection_rate",
	"development_hand_json",
	"draft_pack_size",
	"waiting_for_draft",
	"action_params_json",
	"structured_events_json",
]
