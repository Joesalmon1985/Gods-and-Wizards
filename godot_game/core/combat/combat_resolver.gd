class_name CombatResolver
extends RefCounted

static func default_warrior_deck() -> CombatDeckDefinition:
	var deck := CombatDeckDefinition.new()
	deck.hand_size = 3
	deck.add_entry(CombatDeckEntry.new(CombatCardDef.new("Thrust", &"thrust"), 34))
	deck.add_entry(CombatDeckEntry.new(CombatCardDef.new("Parry", &"parry"), 33))
	deck.add_entry(CombatDeckEntry.new(CombatCardDef.new("Swing", &"swing"), 33))
	return deck


static func resolve_encounter(
	rng: GameRng,
	attacker: CombatantState,
	defender: CombatantState,
	attacker_picks: Array[StringName],
	defender_picks: Array[StringName]
) -> Dictionary:
	var round_index := 0
	var log: Array = []
	var winner_id := ""

	while attacker.health > 0 and defender.health > 0:
		attacker.deck.draw_until(attacker.deck.hand_size, rng)
		defender.deck.draw_until(defender.deck.hand_size, rng)

		var att_move := _pick_move(attacker, attacker_picks, round_index, rng)
		var def_move := _pick_move(defender, defender_picks, round_index, rng)
		var outcome := CombatRules.outcome(att_move, def_move)
		var att_damage := CombatRules.roll_damage(int(outcome["a_die"]), rng)
		var def_damage := CombatRules.roll_damage(int(outcome["b_die"]), rng)
		defender.health = maxi(0, defender.health - att_damage)
		attacker.health = maxi(0, attacker.health - def_damage)
		log.append({
			"round": round_index,
			"att_move": String(att_move),
			"def_move": String(def_move),
			"att_damage": att_damage,
			"def_damage": def_damage,
		})
		round_index += 1
		if round_index > 100:
			break

	if attacker.health > 0 and defender.health <= 0:
		winner_id = attacker.id
	elif defender.health > 0 and attacker.health <= 0:
		winner_id = defender.id
	else:
		winner_id = attacker.id

	return {
		"winner_id": winner_id,
		"attacker_health": attacker.health,
		"defender_health": defender.health,
		"log": log,
	}


static func _pick_move(
	combatant: CombatantState,
	scripted: Array[StringName],
	round_index: int,
	rng: GameRng
) -> StringName:
	if round_index < scripted.size():
		return scripted[round_index]
	if combatant.deck.hand.is_empty():
		return &"block"
	var index := rng.randi_range(0, combatant.deck.hand.size() - 1)
	var card := combatant.deck.play_index(index)
	return card.move_id if card != null else &"block"
