extends BTCondition
## Checks if NPC can see the player (uses perception system).

func _check() -> bool:
	var perception = agent.get("perception")
	if perception:
		return perception.can_see_target
	
	# Fallback: simple distance + raycast check
	var player = _get_player()
	if not player:
		return false
	
	var dist = agent.global_position.distance_to(player.global_position)
	if dist > 12.0:  # Max sight range
		return false
	
	# Could add raycast LOS check here
	return true

func _get_player() -> Node3D:
	var players = agent.get_tree().get_nodes_in_group("player")
	return players[0] if not players.is_empty() else null
