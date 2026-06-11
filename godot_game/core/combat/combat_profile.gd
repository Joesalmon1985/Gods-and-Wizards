class_name CombatProfile
extends RefCounted

var base_health: int = 10
var base_strength: int = 5
var base_skill: int = 5
var deck: CombatDeckDefinition


func _init(
	p_health: int = 10,
	p_strength: int = 5,
	p_skill: int = 5,
	p_deck: CombatDeckDefinition = null
) -> void:
	base_health = p_health
	base_strength = p_strength
	base_skill = p_skill
	deck = p_deck
