class_name ProductionCheckEvent
extends GameEvent

const SCHEMA_VERSION := 1

var turn: int
var hex: HexCoord
var resource: ResourceType.Type
var production_chance: int
var roll: int
var produced: bool


func _init(
	p_turn: int,
	p_hex: HexCoord,
	p_resource: ResourceType.Type,
	p_production_chance: int,
	p_roll: int,
	p_produced: bool
) -> void:
	event_type = "production_check"
	turn = p_turn
	hex = p_hex
	resource = p_resource
	production_chance = p_production_chance
	roll = p_roll
	produced = p_produced


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"type": event_type,
		"turn": turn,
		"hex": hex.to_dict(),
		"resource": ResourceType.to_key(resource),
		"production_chance": production_chance,
		"roll": roll,
		"produced": produced,
	}
