class_name SpellDefinition
extends RefCounted

var spell_id: String = ""
var display_name: String = ""
var source_class: String = ""
var cast_time: float = 0.0
var cooldown: float = 0.0
var mana_cost: float = 0.0
var damage: float = 0.0
var heal: float = 0.0
var lifesteal_frac: float = 0.0
var is_counter_spell: bool = false
var target_self_ok: bool = false
var buff_duration: float = 0.0
var dot_dps: float = 0.0
var dot_duration: float = 0.0
var barrier_absorb_amount: float = 0.0
var barrier_duration: float = 0.0
var buff_cast_rate_mult: float = 1.0
var buff_cooldown_rate_mult: float = 1.0
var buff_hp_regen_delta: float = 0.0
var buff_mana_regen_delta: float = 0.0
var debuff_duration: float = 0.0
var debuff_opp_cast_rate_mult: float = 1.0
var debuff_opp_cooldown_rate_mult: float = 1.0
var debuff_opp_hp_regen_delta: float = 0.0
var debuff_opp_mana_regen_delta: float = 0.0
var delta_hp_caster: float = 0.0
var delta_mana_caster: float = 0.0
var dual_cast: bool = false
var hit_time: float = 0.0
var shield_block_charges: float = 0.0
var shield_duration: float = 0.0
var silence_all_duration: float = 0.0
var silence_random_duration: float = 0.0
var silence_random_n: float = 0.0


static func from_dict(data: Dictionary) -> SpellDefinition:
	var spell := SpellDefinition.new()
	spell.spell_id = str(data.get("spell_id", ""))
	spell.display_name = str(data.get("display_name", spell.spell_id))
	spell.source_class = str(data.get("source_class", ""))
	spell.cast_time = float(data.get("cast_time", 0.0))
	spell.cooldown = float(data.get("cooldown", 0.0))
	spell.mana_cost = float(data.get("mana_cost", 0.0))
	spell.damage = float(data.get("damage", 0.0))
	spell.heal = float(data.get("heal", 0.0))
	spell.lifesteal_frac = float(data.get("lifesteal_frac", 0.0))
	spell.is_counter_spell = bool(data.get("is_counter_spell", false))
	spell.target_self_ok = bool(data.get("target_self_ok", false))
	spell.buff_duration = float(data.get("buff_duration", 0.0))
	spell.dot_dps = float(data.get("dot_dps", 0.0))
	spell.dot_duration = float(data.get("dot_duration", 0.0))
	spell.barrier_absorb_amount = float(data.get("barrier_absorb_amount", 0.0))
	spell.barrier_duration = float(data.get("barrier_duration", 0.0))
	spell.buff_cast_rate_mult = float(data.get("buff_cast_rate_mult", 1.0))
	spell.buff_cooldown_rate_mult = float(data.get("buff_cooldown_rate_mult", 1.0))
	spell.buff_hp_regen_delta = float(data.get("buff_hp_regen_delta", 0.0))
	spell.buff_mana_regen_delta = float(data.get("buff_mana_regen_delta", 0.0))
	spell.debuff_duration = float(data.get("debuff_duration", 0.0))
	spell.debuff_opp_cast_rate_mult = float(data.get("debuff_opp_cast_rate_mult", 1.0))
	spell.debuff_opp_cooldown_rate_mult = float(data.get("debuff_opp_cooldown_rate_mult", 1.0))
	spell.debuff_opp_hp_regen_delta = float(data.get("debuff_opp_hp_regen_delta", 0.0))
	spell.debuff_opp_mana_regen_delta = float(data.get("debuff_opp_mana_regen_delta", 0.0))
	spell.delta_hp_caster = float(data.get("delta_hp_caster", 0.0))
	spell.delta_mana_caster = float(data.get("delta_mana_caster", 0.0))
	spell.dual_cast = bool(data.get("dual_cast", false))
	spell.hit_time = float(data.get("hit_time", 0.0))
	spell.shield_block_charges = float(data.get("shield_block_charges", 0.0))
	spell.shield_duration = float(data.get("shield_duration", 0.0))
	spell.silence_all_duration = float(data.get("silence_all_duration", 0.0))
	spell.silence_random_duration = float(data.get("silence_random_duration", 0.0))
	spell.silence_random_n = float(data.get("silence_random_n", 0.0))
	return spell


func to_dict() -> Dictionary:
	return {
		"spell_id": spell_id,
		"display_name": display_name,
		"source_class": source_class,
		"cast_time": cast_time,
		"cooldown": cooldown,
		"mana_cost": mana_cost,
		"damage": damage,
		"heal": heal,
		"lifesteal_frac": lifesteal_frac,
		"is_counter_spell": is_counter_spell,
		"target_self_ok": target_self_ok,
		"buff_duration": buff_duration,
		"dot_dps": dot_dps,
		"dot_duration": dot_duration,
		"barrier_absorb_amount": barrier_absorb_amount,
		"barrier_duration": barrier_duration,
		"buff_cast_rate_mult": buff_cast_rate_mult,
		"buff_cooldown_rate_mult": buff_cooldown_rate_mult,
		"buff_hp_regen_delta": buff_hp_regen_delta,
		"buff_mana_regen_delta": buff_mana_regen_delta,
		"debuff_duration": debuff_duration,
		"debuff_opp_cast_rate_mult": debuff_opp_cast_rate_mult,
		"debuff_opp_cooldown_rate_mult": debuff_opp_cooldown_rate_mult,
		"debuff_opp_hp_regen_delta": debuff_opp_hp_regen_delta,
		"debuff_opp_mana_regen_delta": debuff_opp_mana_regen_delta,
		"delta_hp_caster": delta_hp_caster,
		"delta_mana_caster": delta_mana_caster,
		"dual_cast": dual_cast,
		"hit_time": hit_time,
		"shield_block_charges": shield_block_charges,
		"shield_duration": shield_duration,
		"silence_all_duration": silence_all_duration,
		"silence_random_duration": silence_random_duration,
		"silence_random_n": silence_random_n,
	}
