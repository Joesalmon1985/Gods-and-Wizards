class_name CombatPresenter
extends RefCounted

## Presentation-only combat UI adapter over headless combat resolver.

static func preview_outcome(att_move: StringName, def_move: StringName) -> Dictionary:
	return CombatRules.outcome(att_move, def_move)
