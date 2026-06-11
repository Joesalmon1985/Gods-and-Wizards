extends Node
class_name GameDirector

var faction_counts := {}

func register_spawn(faction: int) -> void:
	faction_counts[faction] = (faction_counts.get(faction, 0) + 1)

func register_death(faction: int) -> void:
	faction_counts[faction] = max(faction_counts.get(faction, 0) - 1, 0)

func get_alive_count(faction: int) -> int:
	return faction_counts.get(faction, 0)
