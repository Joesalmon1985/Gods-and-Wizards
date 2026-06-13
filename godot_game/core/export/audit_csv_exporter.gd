class_name AuditCsvExporter
extends RefCounted

const RULES_VERSION := "run_k_v1"
const CATALOG_VERSION := "development_cards_v1"

const AUDIT_COLUMNS: Array[String] = [
	"rules_version",
	"catalog_version",
	"git_sha",
	"seed",
	"turn_number",
	"round_number",
	"event_type",
	"event_details_json",
	"event_summary",
	"legal_mask_json",
	"road_count",
	"city_count",
]


static func build_rows(session: BotGameSession, git_sha: String = "") -> Array:
	var rows: Array = []
	var playthrough := PlaythroughCsvExporter.build_rows(session)
	for row in playthrough:
		var audit_row := {
			"rules_version": RULES_VERSION,
			"catalog_version": CATALOG_VERSION,
			"git_sha": git_sha,
			"seed": row.get("seed", ""),
			"turn_number": row.get("turn_number", ""),
			"round_number": row.get("round_number", ""),
			"event_type": row.get("event_type", ""),
			"event_details_json": row.get("event_details", ""),
			"event_summary": row.get("event_summary", ""),
			"legal_mask_json": "",
			"road_count": row.get("road_count", ""),
			"city_count": row.get("city_count", ""),
		}
		rows.append(audit_row)
	return rows


static func render_csv(rows: Array) -> String:
	var lines: PackedStringArray = []
	lines.append(",".join(AUDIT_COLUMNS))
	for row in rows:
		var values: PackedStringArray = []
		for column in AUDIT_COLUMNS:
			values.append(_escape(str(row.get(column, ""))))
		lines.append(",".join(values))
	return "\n".join(lines) + "\n"


static func write_manifest(manifest_path: String, entries: Array) -> String:
	var payload := {
		"generated_at": Time.get_datetime_string_from_system(),
		"entries": entries,
	}
	if not ExportPathResolver.write_text(manifest_path, JSON.stringify(payload, "\t")):
		return ""
	return ExportPathResolver.globalized(manifest_path)


static func _escape(value: String) -> String:
	if value.find(",") == -1 and value.find("\"") == -1:
		return value
	return "\"%s\"" % value.replace("\"", "\"\"")
