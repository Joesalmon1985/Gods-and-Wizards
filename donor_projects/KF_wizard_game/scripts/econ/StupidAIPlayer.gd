## StupidAIEconomyPlayer.gd
#extends EconomyPlayer
#class_name StupidAIEconomyPlayer
#
#func _init(id:int, pname:String="Stupid AI") -> void:
	#super(id, pname)
#
#func request_setup_action(eco, world) -> void:
	#if debug_verbose: print("[StupidAIEconomyPlayer] request setup action")
	### Use basic settlement placement
	##var v_key: Vector2i = choose_settlement_vertex(world)
	##if v_key != Vector2i.ZERO and world.can_place_settlement(player_id, v_key, true):
		##world.place_settlement(player_id, v_key, true)
		##var new_vp: int = int(eco.vp_by_pid.get(player_id, 0)) + 1
		##eco.vp_by_pid[player_id] = new_vp
		##eco.vp_changed.emit(player_id, new_vp)
##
		##var e_key: Vector2i = choose_road_from_vertex(world, v_key)
		##if e_key != Vector2i.ZERO and world.can_place_road(player_id, e_key, true):
			##world.place_road(player_id, e_key, true)
		##eco.setup_placed.emit(player_id, v_key, e_key)
#
#func request_turn_action(eco, world) -> void:
	#take_one_action(eco, world)
#
## Stupid AI accepts any trade offer
#func consider_trade_offer(eco, world, offer: Dictionary, request: Dictionary) -> bool:
	#return true
#
## Stupid AI never initiates trades
#func consider_bank_trade(eco, world) -> Dictionary:
	#return {}
