class_name SpellCombatStatusRules
extends RefCounted

const KIND_DOT := "dot"
const KIND_BARRIER := "barrier"
const KIND_SHIELD := "shield"
const KIND_SILENCE := "silence"
const KIND_BUFF := "buff"
const KIND_DEBUFF := "debuff"


static func ensure_statuses(combatant: Dictionary) -> void:
	if not combatant.has("statuses"):
		combatant["statuses"] = []


static func apply_spell_statuses(
	spell: SpellDefinition,
	caster: Dictionary,
	target: Dictionary,
	sim_time: float
) -> Array:
	ensure_statuses(caster)
	ensure_statuses(target)
	var events: Array = []
	if spell.dot_dps > 0.0 and spell.dot_duration > 0.0:
		_add_status(target, {
			"kind": KIND_DOT,
			"dps": spell.dot_dps,
			"expires_at": sim_time + spell.dot_duration,
			"spell_id": spell.spell_id,
		})
		events.append(_status_event("status_applied", target, spell.spell_id, KIND_DOT, sim_time))
	if spell.barrier_absorb_amount > 0.0 and spell.barrier_duration > 0.0:
		_add_status(caster if spell.target_self_ok else target, {
			"kind": KIND_BARRIER,
			"absorb": spell.barrier_absorb_amount,
			"expires_at": sim_time + spell.barrier_duration,
			"spell_id": spell.spell_id,
		})
		events.append(_status_event("status_applied", caster if spell.target_self_ok else target, spell.spell_id, KIND_BARRIER, sim_time))
	if spell.shield_block_charges > 0.0 and spell.shield_duration > 0.0:
		_add_status(caster if spell.target_self_ok else target, {
			"kind": KIND_SHIELD,
			"charges": int(spell.shield_block_charges),
			"expires_at": sim_time + spell.shield_duration,
			"spell_id": spell.spell_id,
		})
		events.append(_status_event("status_applied", caster if spell.target_self_ok else target, spell.spell_id, KIND_SHIELD, sim_time))
	if spell.silence_all_duration > 0.0:
		_add_status(target, {
			"kind": KIND_SILENCE,
			"expires_at": sim_time + spell.silence_all_duration,
			"spell_id": spell.spell_id,
		})
		events.append(_status_event("status_applied", target, spell.spell_id, KIND_SILENCE, sim_time))
	if spell.buff_duration > 0.0 and _has_buff_modifiers(spell):
		_add_status(caster, {
			"kind": KIND_BUFF,
			"cast_rate_mult": spell.buff_cast_rate_mult,
			"cd_rate_mult": spell.buff_cooldown_rate_mult,
			"hp_regen_delta": spell.buff_hp_regen_delta,
			"mana_regen_delta": spell.buff_mana_regen_delta,
			"expires_at": sim_time + spell.buff_duration,
			"spell_id": spell.spell_id,
		})
		events.append(_status_event("status_applied", caster, spell.spell_id, KIND_BUFF, sim_time))
	if spell.debuff_duration > 0.0 and _has_debuff_modifiers(spell):
		_add_status(target, {
			"kind": KIND_DEBUFF,
			"cast_rate_mult": spell.debuff_opp_cast_rate_mult,
			"cd_rate_mult": spell.debuff_opp_cooldown_rate_mult,
			"hp_regen_delta": spell.debuff_opp_hp_regen_delta,
			"mana_regen_delta": spell.debuff_opp_mana_regen_delta,
			"expires_at": sim_time + spell.debuff_duration,
			"spell_id": spell.spell_id,
		})
		events.append(_status_event("status_applied", target, spell.spell_id, KIND_DEBUFF, sim_time))
	return events


static func tick_statuses(combatant: Dictionary, sim_time: float) -> Array:
	ensure_statuses(combatant)
	var events: Array = []
	var remaining: Array = []
	for status in combatant["statuses"]:
		if float(status.get("expires_at", 0.0)) <= sim_time:
			events.append(_status_event("status_expired", combatant, str(status.get("spell_id", "")), str(status.get("kind", "")), sim_time))
			continue
		if str(status.get("kind", "")) == KIND_DOT:
			var dps := float(status.get("dps", 0.0))
			if dps > 0.0:
				combatant["health"] = maxf(0.0, float(combatant["health"]) - dps)
				events.append({
					"type": "dot_tick",
					"combatant_id": combatant["id"],
					"damage": dps,
					"sim_time": sim_time,
					"spell_id": status.get("spell_id", ""),
				})
		remaining.append(status)
	combatant["statuses"] = remaining
	return events


static func resolve_incoming_damage(target: Dictionary, damage: float, sim_time: float) -> Dictionary:
	ensure_statuses(target)
	var remaining := damage
	var events: Array = []
	var kept: Array = []
	for status in target["statuses"]:
		if float(status.get("expires_at", 0.0)) <= sim_time:
			continue
		var kind := str(status.get("kind", ""))
		if kind == KIND_BARRIER and remaining > 0.0:
			var absorb := float(status.get("absorb", 0.0))
			var used := minf(absorb, remaining)
			remaining -= used
			status["absorb"] = absorb - used
			events.append({"type": "barrier_absorbed", "combatant_id": target["id"], "amount": used, "sim_time": sim_time})
			if float(status["absorb"]) <= 0.0:
				continue
		elif kind == KIND_SHIELD and remaining > 0.0 and int(status.get("charges", 0)) > 0:
			status["charges"] = int(status.get("charges", 0)) - 1
			remaining = 0.0
			events.append({"type": "shield_blocked", "combatant_id": target["id"], "sim_time": sim_time})
			if int(status.get("charges", 0)) <= 0:
				continue
		kept.append(status)
	target["statuses"] = kept
	return {"damage": remaining, "events": events}


static func is_silenced(combatant: Dictionary, sim_time: float) -> bool:
	ensure_statuses(combatant)
	for status in combatant["statuses"]:
		if str(status.get("kind", "")) == KIND_SILENCE and float(status.get("expires_at", 0.0)) > sim_time:
			return true
	return false


static func effective_cast_time(spell: SpellDefinition, caster: Dictionary, sim_time: float) -> float:
	var mult := _aggregate_multiplier(caster, sim_time, "cast_rate_mult")
	if mult <= 0.0:
		return INF
	return spell.cast_time / mult


static func effective_cooldown_duration(spell: SpellDefinition, caster: Dictionary, sim_time: float) -> float:
	var mult := _aggregate_multiplier(caster, sim_time, "cd_rate_mult")
	if mult <= 0.0:
		return INF
	return spell.cooldown / mult


static func regen_deltas(combatant: Dictionary, sim_time: float) -> Dictionary:
	ensure_statuses(combatant)
	var hp_delta := 0.0
	var mana_delta := 0.0
	for status in combatant["statuses"]:
		if float(status.get("expires_at", 0.0)) <= sim_time:
			continue
		var kind := str(status.get("kind", ""))
		if kind in [KIND_BUFF, KIND_DEBUFF]:
			hp_delta += float(status.get("hp_regen_delta", 0.0))
			mana_delta += float(status.get("mana_regen_delta", 0.0))
	return {"hp": hp_delta, "mana": mana_delta}


static func statuses_summary(combatant: Dictionary, sim_time: float) -> Array:
	ensure_statuses(combatant)
	var summary: Array = []
	for status in combatant["statuses"]:
		if float(status.get("expires_at", 0.0)) <= sim_time:
			continue
		summary.append({
			"kind": status.get("kind", ""),
			"expires_at": status.get("expires_at", 0.0),
			"spell_id": status.get("spell_id", ""),
		})
	return summary


static func _has_buff_modifiers(spell: SpellDefinition) -> bool:
	return (
		spell.buff_cast_rate_mult != 1.0
		or spell.buff_cooldown_rate_mult != 1.0
		or spell.buff_hp_regen_delta != 0.0
		or spell.buff_mana_regen_delta != 0.0
		or spell.heal > 0.0
	)


static func _has_debuff_modifiers(spell: SpellDefinition) -> bool:
	return (
		spell.debuff_opp_cast_rate_mult != 1.0
		or spell.debuff_opp_cooldown_rate_mult != 1.0
		or spell.debuff_opp_hp_regen_delta != 0.0
		or spell.debuff_opp_mana_regen_delta != 0.0
	)


static func _aggregate_multiplier(combatant: Dictionary, sim_time: float, field: String) -> float:
	ensure_statuses(combatant)
	var mult := 1.0
	for status in combatant["statuses"]:
		if float(status.get("expires_at", 0.0)) <= sim_time:
			continue
		if status.has(field):
			mult *= float(status.get(field, 1.0))
	return mult


static func _add_status(combatant: Dictionary, status: Dictionary) -> void:
	combatant["statuses"].append(status)


static func _status_event(
	event_type: String,
	combatant: Dictionary,
	spell_id: String,
	kind: String,
	sim_time: float
) -> Dictionary:
	return {
		"type": event_type,
		"combatant_id": combatant["id"],
		"spell_id": spell_id,
		"status_kind": kind,
		"sim_time": sim_time,
	}
