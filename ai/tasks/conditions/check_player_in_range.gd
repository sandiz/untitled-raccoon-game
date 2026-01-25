extends BTCondition
## Checks if player is within catch range.

@export var catch_distance: float = 1.5

func _check() -> bool:
	var player = _get_player()
	if not player:
		return false
	
	var dist = agent.global_position.distance_to(player.global_position)
	return dist < catch_distance

func _get_player() -> Node3D:
	var players = agent.get_tree().get_nodes_in_group("player")
	return players[0] if not players.is_empty() else null
