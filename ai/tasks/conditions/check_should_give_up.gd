extends BTCondition
## Checks if NPC should give up chase (exhaustion >= 0.7 or search timed out).

func _check() -> bool:
	var emo = blackboard.get_var(&"emotional_state")
	if emo and emo.exhaustion >= 0.7:
		return true
	
	# Also give up if search time exceeded
	var search_time = blackboard.get_var(&"search_time", 0.0)
	if search_time >= 8.0:
		return true
	
	return false
