@tool
extends BTAction
## Ensures velocity is zeroed for a couple frames before proceeding.
## This prevents sliding from residual movement.
##
## RESPONSIBILITY: Sets velocity to zero only. NPC handles animation.

var _frames_waited: int = 0

func _generate_name() -> String:
	return "PlayIdle"

func _enter() -> void:
	_frames_waited = 0
	agent.velocity = Vector3.ZERO

func _tick(_delta: float) -> Status:
	# Abort check for responsiveness - check if we should chase
	var emo = blackboard.get_var(&"emotional_state")
	if not emo:
		emo = agent.get("emotional_state")
	if emo and emo.will_chase:
		return FAILURE
	
	agent.velocity = Vector3.ZERO
	_frames_waited += 1
	if _frames_waited >= 2:
		return SUCCESS
	return RUNNING

func _exit() -> void:
	agent.velocity = Vector3.ZERO
