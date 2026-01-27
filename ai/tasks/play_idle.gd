@tool
extends BTAction
## Plays idle animation and ensures velocity is zeroed before returning SUCCESS.

@export var idle_animation: StringName = &"default/Idle"

var _frames_waited: int = 0

func _generate_name() -> String:
	return "PlayIdle"

func _enter() -> void:
	_frames_waited = 0
	# Stop movement (shopkeeper's _physics_process will call move_and_slide)
	agent.velocity = Vector3.ZERO
	
	# Set idle state
	if agent.has_method("set_current_state"):
		agent.set_current_state("idle")
	
	var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
	if anim:
		for anim_name in ["default/Idle", "default/Idle_LookAround"]:
			if anim.has_animation(anim_name):
				anim.play(anim_name)
				break

func _tick(_delta: float) -> Status:
	# Ensure velocity stays zero for at least 2 frames to prevent sliding
	agent.velocity = Vector3.ZERO
	_frames_waited += 1
	if _frames_waited >= 2:
		return SUCCESS
	return RUNNING

func _exit() -> void:
	agent.velocity = Vector3.ZERO
