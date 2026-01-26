@tool
extends BTAction
## Plays idle animation and ensures velocity is zeroed before returning SUCCESS.

@export var idle_animation: StringName = &"default/Idle"

var _frames_waited: int = 0

func _generate_name() -> String:
	return "PlayIdle"

func _enter() -> void:
	_frames_waited = 0
	# Stop movement
	agent.velocity = Vector3.ZERO
	agent.move_and_slide()
	
	var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
	if anim:
		for anim_name in ["default/Idle", "default/Idle_LookAround"]:
			if anim.has_animation(anim_name):
				anim.play(anim_name)
				break

func _tick(_delta: float) -> Status:
	# Ensure velocity stays zero for at least 2 frames to prevent sliding
	agent.velocity = Vector3.ZERO
	agent.move_and_slide()
	_frames_waited += 1
	if _frames_waited >= 2:
		return SUCCESS
	return RUNNING
