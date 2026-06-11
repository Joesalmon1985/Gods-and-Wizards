class_name CombatDeckRuntime
extends RefCounted

var draw_pile: Array[CombatCardDef] = []
var discard_pile: Array[CombatCardDef] = []
var hand: Array[CombatCardDef] = []
var hand_size: int = 3


func init_from(definition: CombatDeckDefinition, rng: GameRng) -> void:
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	if definition != null:
		hand_size = clampi(definition.hand_size, 1, 5)
		for entry in definition.entries:
			if entry == null or entry.card == null:
				continue
			for _i in range(entry.count):
				draw_pile.append(entry.card)
	_shuffle(rng)


func _shuffle(rng: GameRng) -> void:
	if draw_pile.size() <= 1:
		return
	for i in range(draw_pile.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = tmp


func draw_until(target: int, rng: GameRng) -> void:
	target = clampi(target, 1, 5)
	while hand.size() < target:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			_shuffle(rng)
		if draw_pile.is_empty():
			break
		hand.append(draw_pile.pop_back())


func play_index(index: int) -> CombatCardDef:
	if index < 0 or index >= hand.size():
		return null
	var card := hand[index]
	hand.remove_at(index)
	discard_pile.append(card)
	return card
