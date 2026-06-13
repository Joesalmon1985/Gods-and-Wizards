class_name TestAuditExport
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_audit_rows_include_provenance(test_assert)
	_test_audit_manifest_round_trip(test_assert)
	_test_audit_csv_columns(test_assert)


static func _test_audit_rows_include_provenance(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(77)
	session.run_until_finished(12)
	var rows := AuditCsvExporter.build_rows(session, "test_sha")
	test_assert.check(not rows.is_empty(), "audit export should produce rows")
	var row: Dictionary = rows[0]
	test_assert.eq(str(row.get("rules_version", "")), AuditCsvExporter.RULES_VERSION, "rules_version column")
	test_assert.eq(str(row.get("catalog_version", "")), AuditCsvExporter.CATALOG_VERSION, "catalog_version column")
	test_assert.eq(str(row.get("git_sha", "")), "test_sha", "git_sha column")


static func _test_audit_manifest_round_trip(test_assert: TestAssert) -> void:
	var manifest_path := "user://test_audit_manifest_run_k.json"
	var entries := [{
		"path": "/tmp/example.csv",
		"seed": 42,
		"rules_version": AuditCsvExporter.RULES_VERSION,
	}]
	var written := AuditCsvExporter.write_manifest(manifest_path, entries)
	test_assert.check(written != "", "manifest write should succeed")
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	test_assert.check(file != null, "manifest file should exist")
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	test_assert.check(typeof(parsed) == TYPE_DICTIONARY, "manifest should parse as JSON object")
	test_assert.check(parsed.get("entries", []).size() == 1, "manifest should store entries")


static func _test_audit_csv_columns(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(88)
	session.run_until_finished(6)
	var csv := AuditCsvExporter.render_csv(AuditCsvExporter.build_rows(session))
	var header := csv.split("\n")[0]
	for column in AuditCsvExporter.AUDIT_COLUMNS:
		test_assert.check(header.find(column) >= 0, "audit CSV header should include %s" % column)
