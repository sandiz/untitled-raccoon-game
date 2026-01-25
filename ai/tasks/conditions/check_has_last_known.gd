extends BTCondition
## Checks if NPC has a recent last known position to search.

@export var max_search_age: float = 10.0  # Seconds since last seen

func _check() -> bool:
	var last_pos = blackboard.get_var(&"last_known_position", Vector3.ZERO)
	if last_pos == Vector3.ZERO:
		return false
	
	var last_seen_time = blackboard.get_var(&"last_seen_time", 0.0)
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_seen = current_time - last_seen_time
	
	return time_since_seen < max_search_age
