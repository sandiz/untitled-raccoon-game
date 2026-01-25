extends BTAction
## Catches the player: knockback, stun, drop item, play celebration.

const KNOCKBACK_FORCE: float = 5.0
const STUN_DURATION: float = 1.5
const CELEBRATION_DURATION: float = 2.0

var _celebration_timer: float = 0.0
var _caught: bool = false

func _enter() -> void:
	_celebration_timer = 0.0
	_caught = false

func _tick(delta: float) -> Status:
	if not _caught:
		_caught = true
		_catch_player()
	
	# Play celebration for a bit
	_celebration_timer += delta
	if _celebration_timer >= CELEBRATION_DURATION:
		_finish_catch()
		return SUCCESS
	
	return RUNNING

func _catch_player() -> void:
	var player = _get_player()
	if not player:
		return
	
	# Apply knockback
	var knockback_dir = (player.global_position - agent.global_position).normalized()
	if player.has_method("apply_knockback"):
		player.apply_knockback(knockback_dir, KNOCKBACK_FORCE)
	
	# Stun player
	if player.has_method("stun"):
		player.stun(STUN_DURATION)
	
	# Force drop any held item
	if player.has_method("drop_held_item"):
		player.drop_held_item()
	
	# Play celebration animation
	var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
	if anim and anim.has_animation("default/Celebration"):
		anim.play("default/Celebration")
	
	# Update NPC state
	if agent.has_method("set_state"):
		agent.set_state("caught_player")
	agent.current_state = "caught_player"
	
	# Emotional feedback
	var emo = blackboard.get_var(&"emotional_state")
	if emo and emo.has_method("add_event"):
		emo.add_event("chase_success")

func _finish_catch() -> void:
	# Set cooldown so NPC doesn't immediately chase again
	blackboard.set_var(&"chase_on_cooldown", true)
	blackboard.set_var(&"chase_cooldown_timer", 5.0)
	
	# Clear chase state
	blackboard.set_var(&"last_known_position", Vector3.ZERO)
	
	# Reset to idle animation
	var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
	if anim and anim.has_animation("default/Idle_Loop"):
		anim.play("default/Idle_Loop")
	
	agent.current_state = "idle"

func _get_player() -> Node3D:
	var players = agent.get_tree().get_nodes_in_group("player")
	return players[0] if not players.is_empty() else null
