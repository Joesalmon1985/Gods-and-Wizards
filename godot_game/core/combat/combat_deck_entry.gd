class_name CombatDeckEntry
extends RefCounted

var card: CombatCardDef
var count: int = 1


func _init(p_card: CombatCardDef, p_count: int = 1) -> void:
	card = p_card
	count = p_count
