class_name CombatantState
extends RefCounted

var id: String
var health: int
var deck: CombatDeckRuntime


func _init(p_id: String, p_health: int, p_deck: CombatDeckRuntime) -> void:
	id = p_id
	health = p_health
	deck = p_deck
