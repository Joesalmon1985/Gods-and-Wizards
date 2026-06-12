class_name SpellCombatSession
extends RefCounted

const TERMINAL_WIN_REWARD := 10.0

var seed: int = 0
var catalog: SpellCatalog = null
var combatants: Array = []
var active_index: int = 0
var sim_time: float = 0.0
var timeline: Array = []
var finished: bool = false
var winner_id: String = ""
var _cooldowns_by_combatant: Array = [{}, {}]


static func start_duel(
	game_seed: int,
	loadout_a_id: String,
	loadout_b_id: String,
	catalog: SpellCatalog = null
) -> SpellCombatSession:
	var session := SpellCombatSession.new()
	session.seed = game_seed
	session.catalog = catalog if catalog != null else SpellCatalog.load_default()
	var loadouts := CombatantSpellLoadout.load_all_default()
	session._init_combatant(0, loadout_a_id, loadouts)
	session._init_combatant(1, loadout_b_id, loadouts)
	session._append_event("combat_start", {
		"seed": game_seed,
		"combatant_ids": [session.combatants[0]["id"], session.combatants[1]["id"]],
	})
	return session


func get_active_combatant() -> Dictionary:
	return combatants[active_index]


func get_opponent() -> Dictionary:
	return combatants[1 - active_index]


func get_legal_spell_ids() -> Array[String]:
	var caster: Dictionary = get_active_combatant()
	var loadout: CombatantSpellLoadout = caster["loadout"]
	var cooldowns: Dictionary = _cooldowns_by_combatant[active_index]
	return SpellCombatRules.legal_spell_ids(
		loadout,
		catalog,
		caster,
		float(caster["mana"]),
		sim_time,
		cooldowns
	)


func step(spell_id: String) -> Dictionary:
	if finished:
		return _step_result([])

	var caster: Dictionary = get_active_combatant()
	var opponent: Dictionary = get_opponent()
	var events: Array = []
	events.append_array(_tick_all_combatants())

	if SpellCombatRules.is_pass(spell_id):
		sim_time += 1.0
		_apply_regen(caster, 8.0)
		events.append(_append_event("pass", {"combatant_id": caster["id"], "sim_time": sim_time}))
	else:
		var spell := catalog.get_spell(spell_id)
		var legal := get_legal_spell_ids()
		if spell == null or not legal.has(spell_id):
			return _step_result([])

		var cast_time := SpellCombatStatusRules.effective_cast_time(spell, caster, sim_time)
		if cast_time == INF:
			return _step_result([])

		events.append(_append_event("cast_start", {
			"combatant_id": caster["id"],
			"spell_id": spell_id,
			"sim_time": sim_time,
			"cast_time": cast_time,
			"hit_time": spell.hit_time,
		}))

		sim_time += cast_time + spell.hit_time
		var cd_duration := SpellCombatStatusRules.effective_cooldown_duration(spell, caster, sim_time)
		_cooldowns_by_combatant[active_index][spell_id] = sim_time + cd_duration

		var outcome := SpellCombatRules.apply_spell_effects(spell, caster, opponent, sim_time)
		for status_event in outcome.get("status_events", []):
			events.append(_append_event(str(status_event.get("type", "status")), status_event))
		if float(outcome["damage_to_target"]) > 0.0:
			events.append(_append_event("spell_hit", {
				"caster_id": caster["id"],
				"target_id": opponent["id"],
				"spell_id": spell_id,
				"damage": outcome["damage_to_target"],
				"sim_time": sim_time,
			}))
		if float(outcome["heal_to_caster"]) > 0.0:
			events.append(_append_event("heal_applied", {
				"combatant_id": caster["id"],
				"spell_id": spell_id,
				"heal": outcome["heal_to_caster"],
				"sim_time": sim_time,
			}))
		_apply_regen(caster, 2.0)

	_evaluate_terminal(events)
	if not finished:
		active_index = 1 - active_index

	return _step_result(events)


func step_deterministic_policy() -> Dictionary:
	var legal := get_legal_spell_ids()
	var spell_id := legal[0] if not legal.is_empty() else SpellCombatRules.PASS_SPELL_ID
	return step(spell_id)


func observe(combatant_index: int = -1) -> Dictionary:
	var index := combatant_index if combatant_index >= 0 else active_index
	var combatant: Dictionary = combatants[index]
	var opponent: Dictionary = combatants[1 - index]
	var cooldowns: Dictionary = _cooldowns_by_combatant[index]
	return {
		"seed": seed,
		"sim_time": sim_time,
		"active_combatant_id": get_active_combatant()["id"],
		"combatant_id": combatant["id"],
		"health": combatant["health"],
		"mana": combatant["mana"],
		"opponent_id": opponent["id"],
		"opponent_health": opponent["health"],
		"opponent_mana": opponent["mana"],
		"loadout_spell_ids": combatant["loadout"].spell_ids.duplicate(),
		"cooldowns_by_spell_id": cooldowns.duplicate(),
		"statuses": SpellCombatStatusRules.statuses_summary(combatant, sim_time),
		"opponent_statuses": SpellCombatStatusRules.statuses_summary(opponent, sim_time),
		"finished": finished,
		"winner_id": winner_id,
	}


func get_rewards(for_combatant_id: String, events: Array) -> float:
	var reward := 0.0
	for event in events:
		match str(event.get("type", "")):
			"spell_hit":
				if str(event.get("caster_id", "")) == for_combatant_id:
					reward += float(event.get("damage", 0.0)) * 0.1
				if str(event.get("target_id", "")) == for_combatant_id:
					reward -= float(event.get("damage", 0.0)) * 0.1
			"heal_applied":
				if str(event.get("combatant_id", "")) == for_combatant_id:
					reward += float(event.get("heal", 0.0)) * 0.05
	if finished and winner_id == for_combatant_id:
		reward += TERMINAL_WIN_REWARD
	return reward


func _init_combatant(index: int, loadout_id: String, loadouts: Dictionary) -> void:
	if not loadouts.has(loadout_id):
		push_error("Unknown loadout id: %s" % loadout_id)
		return
	var loadout: CombatantSpellLoadout = loadouts[loadout_id]
	combatants.append({
		"id": loadout.combatant_id,
		"health": loadout.base_health,
		"max_health": loadout.base_health,
		"mana": loadout.base_mana,
		"max_mana": loadout.base_mana,
		"loadout": loadout,
		"statuses": [],
	})


func _tick_all_combatants() -> Array:
	var events: Array = []
	for combatant in combatants:
		events.append_array(SpellCombatStatusRules.tick_statuses(combatant, sim_time))
	return events


func _apply_regen(combatant: Dictionary, base_mana: float) -> void:
	var deltas := SpellCombatStatusRules.regen_deltas(combatant, sim_time)
	combatant["health"] = minf(
		float(combatant.get("max_health", combatant["health"])),
		float(combatant["health"]) + float(deltas.get("hp", 0.0))
	)
	var max_mana := float(combatant.get("max_mana", 0.0))
	combatant["mana"] = minf(max_mana, float(combatant["mana"]) + base_mana + float(deltas.get("mana", 0.0)))


func _evaluate_terminal(events: Array) -> void:
	for i in range(combatants.size()):
		var combatant: Dictionary = combatants[i]
		if float(combatant["health"]) <= 0.0:
			finished = true
			var other_index := 1 - i
			var other: Dictionary = combatants[other_index]
			if float(other["health"]) > 0.0:
				winner_id = str(other["id"])
			else:
				winner_id = str(combatants[0]["id"])
			events.append(_append_event("combatant_defeated", {
				"combatant_id": combatant["id"],
				"sim_time": sim_time,
			}))
			events.append(_append_event("combat_end", {
				"winner_id": winner_id,
				"sim_time": sim_time,
			}))
			return


func _append_event(event_type: String, payload: Dictionary) -> Dictionary:
	var event := {"type": event_type}
	for key in payload.keys():
		event[key] = payload[key]
	timeline.append(event)
	return event


func _step_result(events: Array) -> Dictionary:
	return {
		"events": events,
		"done": finished,
		"winner_id": winner_id,
		"observation": observe(),
		"timeline": timeline.duplicate(),
	}
