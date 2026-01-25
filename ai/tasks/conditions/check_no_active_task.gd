extends BTCondition
## Guards P5: Select Task branch.

func _check() -> bool:
	var has_task = blackboard.get_var(&"has_active_task", false)
	if has_task:
		print("[BT] check_no_active_task: FAIL (has_active_task=true)")
		return false
	
	var emo = blackboard.get_var(&"emotional_state")
	if emo and emo.will_chase:
		print("[BT] check_no_active_task: FAIL (will_chase=true)")
		return false  # Don't select new task while wanting to chase
	
	print("[BT] check_no_active_task: PASS")
	return true
