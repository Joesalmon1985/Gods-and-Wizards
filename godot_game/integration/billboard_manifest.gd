class_name BillboardManifest
extends RefCounted

const MANIFEST_PATH := "res://assets/billboards/manifest.json"
const ASSET_ROOT := "res://assets/billboards/"

static var _cached: Dictionary = {}


static func load_manifest() -> Dictionary:
	if not _cached.is_empty():
		return _cached
	var text := FileAccess.get_file_as_string(MANIFEST_PATH)
	if text.is_empty():
		_cached = {}
		return _cached
	var parsed = JSON.parse_string(text)
	_cached = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	return _cached


static func entries() -> Array:
	return load_manifest().get("entries", [])


static func has_entry(id: String) -> bool:
	return not get_entry(id).is_empty()


static func get_entry(id: String) -> Dictionary:
	for entry in entries():
		if str(entry.get("id", "")) == id:
			return entry
	return {}


static func resolved_path(id: String) -> String:
	var entry := get_entry(id)
	if entry.is_empty():
		return ""
	var rel: String = entry.get("path", "")
	if rel == "":
		return ""
	return "%s%s" % [ASSET_ROOT, rel]


static func donor_source(id: String) -> String:
	return str(get_entry(id).get("donor_source", ""))


static func load_texture(id: String) -> Texture2D:
	var path := resolved_path(id)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func reset_cache() -> void:
	_cached = {}
