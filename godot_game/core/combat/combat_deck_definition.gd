class_name CombatDeckDefinition
extends RefCounted

var entries: Array[CombatDeckEntry] = []
var hand_size: int = 3


func add_entry(entry: CombatDeckEntry) -> void:
	if entry != null:
		entries.append(entry)
