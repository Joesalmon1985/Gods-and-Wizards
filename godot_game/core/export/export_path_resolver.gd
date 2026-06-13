class_name ExportPathResolver
extends RefCounted

## Resolve CLI output paths for headless exporters.
## Relative paths are rooted at the repository parent of godot_game/ (workspace root).


static func resolve(path: String) -> String:
	if path.begins_with("user://") or path.begins_with("res://"):
		return path
	if path.begins_with("/"):
		return path
	var godot_root := ProjectSettings.globalize_path("res://").replace("\\", "/")
	if godot_root.ends_with("/"):
		godot_root = godot_root.substr(0, godot_root.length() - 1)
	return godot_root.path_join("../").path_join(path).simplify_path()


static func ensure_parent_dir(path: String) -> bool:
	var resolved := resolve(path)
	var parent := resolved.get_base_dir()
	if parent == "" or parent == resolved:
		return true
	if DirAccess.dir_exists_absolute(parent):
		return true
	var err := DirAccess.make_dir_recursive_absolute(parent)
	return err == OK


static func write_text(path: String, text: String) -> bool:
	var resolved := resolve(path)
	if not ensure_parent_dir(resolved):
		push_error("Failed to create parent directory for: %s" % resolved)
		return false
	var file := FileAccess.open(resolved, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open output path: %s" % resolved)
		return false
	file.store_string(text)
	file.close()
	return true


static func globalized(path: String) -> String:
	return ProjectSettings.globalize_path(resolve(path))
