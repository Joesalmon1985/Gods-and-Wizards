class_name MacroLegalActionLayout
extends RefCounted

## Compact legal-action head aligned with MacroFeatureFeaturizer.MAX_LEGAL_ACTIONS.

const MAX_COMPACT_SLOTS := 64
const LAYOUT_VERSION := "compact_global_index_v1"


static func build_compact(view: LegalActionView) -> Dictionary:
	var global_indices: Array[int] = []
	for i in range(view.action_ids.size()):
		if view.legal_mask[i]:
			global_indices.append(i)
	if global_indices.size() > MAX_COMPACT_SLOTS:
		global_indices = global_indices.slice(0, MAX_COMPACT_SLOTS)
	var mask: Array = []
	for _i in global_indices.size():
		mask.append(1)
	while mask.size() < MAX_COMPACT_SLOTS:
		mask.append(0)
	return {
		"global_indices": global_indices,
		"mask": mask,
		"slot_count": global_indices.size(),
	}


static func action_from_compact_slot(
	view: LegalActionView,
	state: GameState,
	compact_index: int,
	compact: Dictionary
) -> GameAction:
	var global_indices: Array = compact.get("global_indices", [])
	if compact_index < 0 or compact_index >= global_indices.size():
		return null
	var global_i: int = int(global_indices[compact_index])
	if global_i < 0 or global_i >= view.action_ids.size():
		return null
	if not view.legal_mask[global_i]:
		return null
	return state.action_space.get_action(view.action_ids[global_i])
