class_name WizardController
extends RefCounted

## Presentation-only wizard controller. Does not mutate GameState directly.

var sync: SyncController


func _init(p_sync: SyncController) -> void:
	sync = p_sync


func request_move_action(state: GameState, hero_id: int, target: BoardNode) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind != ActionKind.Kind.MOVE_HERO:
			continue
		if action.hero_id != hero_id:
			continue
		if action.target_node != null and action.target_node.equals(target):
			return action
	return null
