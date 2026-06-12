class_name TestBillboardManifest
extends RefCounted

const ALLOWED_PREFIXES: Array[String] = [
	"res://assets/billboards/wizards/",
	"res://assets/billboards/demons/",
	"res://assets/billboards/heroes/",
	"res://assets/billboards/props/",
	"res://assets/billboards/ui_status/",
]


static func run(test_assert: TestAssert) -> void:
	_test_manifest_entries_exist(test_assert)
	_test_textures_load(test_assert)
	_test_paths_under_target_folders(test_assert)
	_test_donor_sources_recorded(test_assert)


static func _test_manifest_entries_exist(test_assert: TestAssert) -> void:
	var entries := BillboardManifest.entries()
	test_assert.check(entries.size() >= 10, "manifest should include Run J shortlist entries")
	for entry in entries:
		var id: String = str(entry.get("id", ""))
		test_assert.check(id != "", "manifest entry should have id")
		test_assert.check(BillboardManifest.has_entry(id), "manifest should resolve entry %s" % id)


static func _test_textures_load(test_assert: TestAssert) -> void:
	for entry in BillboardManifest.entries():
		var id: String = str(entry.get("id", ""))
		var texture := BillboardManifest.load_texture(id)
		test_assert.check(texture != null, "texture should load for manifest id %s" % id)


static func _test_paths_under_target_folders(test_assert: TestAssert) -> void:
	for entry in BillboardManifest.entries():
		var id: String = str(entry.get("id", ""))
		var path := BillboardManifest.resolved_path(id)
		var allowed := false
		for prefix in ALLOWED_PREFIXES:
			if path.begins_with(prefix):
				allowed = true
				break
		test_assert.check(allowed, "asset path should be under billboards target folders: %s" % path)


static func _test_donor_sources_recorded(test_assert: TestAssert) -> void:
	for entry in BillboardManifest.entries():
		var id: String = str(entry.get("id", ""))
		var donor := BillboardManifest.donor_source(id)
		test_assert.check(donor != "", "manifest entry %s should record donor source" % id)
