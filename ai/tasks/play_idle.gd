@tool
extends BTAction
## Plays idle animation and returns SUCCESS immediately.

@export var idle_animation: StringName = &"default/Idle"

func _generate_name() -> String:
	return "PlayIdle"

func _enter() -> void:
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
	return SUCCESS
