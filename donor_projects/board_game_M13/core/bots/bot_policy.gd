class_name BotPolicy
extends RefCounted

static func choose_action(state: GameState) -> GameAction:
	return RandomBotPolicy.choose_action(state)
