extends BTCondition
## Guards P2: Restore Order branch. Checks for displaced items AND is_calm.

func _check() -> bool:
	var items = blackboard.get_var(&"displaced_items", [])
	if items.is_empty():
		return false
	
	var emo = blackboard.get_var(&"emotional_state")
	if emo and emo.will_chase:
		return false  # Don't restore while wanting to chase
	
	return true
