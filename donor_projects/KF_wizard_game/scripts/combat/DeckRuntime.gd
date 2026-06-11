extends RefCounted
class_name DeckRuntime

var debug_verbose = false

var draw_pile: Array[CardDef] = []
var discard_pile: Array[CardDef] = []
var hand: Array[CardDef] = []
var hand_size: int = 3

func init_from(def: DeckDefinition, rng: RandomNumberGenerator) -> void:
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()

	if def != null:
		hand_size = clamp(int(def.hand_size), 1, 5)
		# Flatten entries -> draw_pile
		for e in def.entries:
			if e == null or e.card == null:
				continue
			var cnt: int = int(e.count)
			for i in range(cnt):
				draw_pile.append(e.card)

	_shuffle(rng)

	# Debug summary
	if draw_pile.is_empty():
		var entry_count: int = def.entries.size() if def != null else -1
		if debug_verbose: print("[DeckRuntime] init_from: draw_pile EMPTY (entries=", entry_count, ", hand_size=", hand_size, ")")
	else:
		if debug_verbose: print("[DeckRuntime] init_from: draw_pile size=", draw_pile.size(), " unique_cards=", _count_unique(), " hand_size=", hand_size)

func _card_key(c: CardDef) -> String:
	if c == null:
		return ""
	var n: String = c.name
	if n == "":
		n = c.get_class()
	return n

func _count_unique() -> int:
	var seen: Dictionary = {} # String -> bool
	for c in draw_pile:
		if c == null:
			continue
		var k: String = _card_key(c)   # <<< this must be inside the loop
		seen[k] = true
	return seen.size()

func _shuffle(rng: RandomNumberGenerator) -> void:
	if draw_pile.size() <= 1:
		return
	var n: int = draw_pile.size()
	for i in range(n - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: CardDef = draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = tmp

func draw_until(target: int, rng: RandomNumberGenerator) -> void:
	target = clamp(target, 1, 5)
	while hand.size() < target:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			# Manual copy to keep typing happy in 4.4
			var new_pile: Array[CardDef] = []
			for c in discard_pile:
				new_pile.append(c)
			draw_pile = new_pile
			discard_pile.clear()
			_shuffle(rng)
		if draw_pile.is_empty():
			break

		var next_card: CardDef = draw_pile.pop_back()

		# Draw-smoothing: avoid duplicate names in hand if possible
		var key_next: String = _card_key(next_card)
		var has_dup := false
		for c in hand:
			var key: String = _card_key(c)
			if key == key_next:
				has_dup = true
				break
		if has_dup and draw_pile.size() > 0:
			var alt_idx: int = rng.randi_range(0, draw_pile.size() - 1)
			var alt: CardDef = draw_pile[alt_idx]
			draw_pile[alt_idx] = next_card
			next_card = alt

		hand.append(next_card)

func play_index(ix: int) -> CardDef:
	if ix < 0 or ix >= hand.size():
		return null
	var c: CardDef = hand[ix]
	hand.remove_at(ix)
	discard_pile.append(c)
	return c
