extends BTCondition
## Checks if NPC should give up chase (stamina too low or search timed out).

func _check() -> bool:
	var emo = blackboard.get_var(&"emotional_state")
	if emo and emo.will_give_up:
		return true
	
	# Also give up if search time exceeded
	var search_time = blackboard.get_var(&"search_time", 0.0)
	var max_search_time = 8.0
	if emo:
		max_search_time = emo.chase_give_up_time  # Temper extends search time
	
	if search_time >= max_search_time:
		return true
	
	return false
