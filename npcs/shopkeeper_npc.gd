@tool
extends CharacterBody3D
## Shopkeeper NPC with full emotional state, perception, and social systems.

# Using global classes: NPCEmotionalState, NPCPerception, NPCSocial

# ═══════════════════════════════════════
# SYSTEMS
# ═══════════════════════════════════════

## Emotional state component
var emotional_state: NPCEmotionalState = NPCEmotionalState.new()

## Perception component (sight, hearing)
var perception: NPCPerception = NPCPerception.new()

## Social component (communication with other NPCs)
var social: NPCSocial = NPCSocial.new()

# ═══════════════════════════════════════
# STATE
# ═══════════════════════════════════════

## Current behavior state
var current_state: String = "idle"

## Current dialogue text (shared between bubble and info panel)
var current_dialogue: String = "Hmm..."

## Cached reference to player (if any)
var _player: Node3D = null

## Floating state indicator above head
var _state_indicator: NPCStateIndicator = null

## Vision indicator on ground
var _vision_indicator: VisionIndicator = null

# ═══════════════════════════════════════
# EXPORTS
# ═══════════════════════════════════════

## NPC Personality (data-driven names, dialogue, modifiers)
@export var personality: NPCPersonality

## Editor animation preview
@export var play_in_editor: bool = true:
	set(value):
		play_in_editor = value
		_update_editor_animation()

# ═══════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════

func _ready() -> void:
	add_to_group("npc")
	
	if Engine.is_editor_hint():
		_update_editor_animation()
		return
	
	# Load default personality if none assigned
	if not personality:
		personality = load("res://data/personalities/bernard.tres")
	
	# Apply personality stat modifiers to emotional state
	if personality:
		emotional_state.alertness_rate_modifier = personality.alertness_modifier
		emotional_state.annoyance_rate_modifier = personality.annoyance_modifier
		emotional_state.exhaustion_rate_modifier = personality.exhaustion_modifier
		emotional_state.suspicion_rate_modifier = personality.suspicion_modifier
	
	# Initialize systems
	perception.setup(self)
	social.setup(self)
	
	# Connect system signals
	_connect_signals()
	
	# Setup behavior tree
	_setup_behavior_tree()
	_play_idle_animation()
	
	# Find player reference
	_player = get_tree().get_first_node_in_group("player")
	
	# Create floating state indicator
	_state_indicator = NPCStateIndicator.new()
	add_child(_state_indicator)
	
	# Show initial idle dialogue
	_update_state_indicator("idle")
	
	# Get vision indicator (added in scene)
	_vision_indicator = get_node_or_null("VisionIndicator")

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		social.cleanup()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# Update all systems
	emotional_state.update(delta)
	perception.update(delta)
	social.update(delta)
	
	# Check for player visibility
	_update_player_perception(delta)
	
	# Update exhaustion if currently chasing
	if current_state == "chasing":
		emotional_state.on_chasing(delta)
	
	# Update chase cooldown timer
	_update_chase_cooldown(delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		move_and_slide()

# ═══════════════════════════════════════
# PERCEPTION UPDATES
# ═══════════════════════════════════════

func _update_player_perception(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if not _player:
			return
	
	# Check visibility to player
	var visibility = perception.check_target_visibility(_player)
	if visibility.visible:
		perception.process_visible_target(_player, visibility, delta)

# ═══════════════════════════════════════
# SIGNAL CONNECTIONS
# ═══════════════════════════════════════

func _connect_signals() -> void:
	# Emotional state signals
	emotional_state.state_changed.connect(_on_emotional_state_changed)
	emotional_state.threshold_crossed.connect(_on_threshold_crossed)
	
	# Perception signals
	perception.target_spotted.connect(_on_target_spotted)
	perception.target_lost.connect(_on_target_lost)
	perception.sound_heard.connect(_on_sound_heard)
	
	# Social signals
	social.alert_received.connect(_on_alert_received)
	social.help_requested.connect(_on_help_requested)

# ═══════════════════════════════════════
# PERCEPTION CALLBACKS
# ═══════════════════════════════════════

func _on_target_spotted(target: Node3D, spot_type: String) -> void:
	# Don't downgrade from chasing state
	if current_state == "chasing":
		# Just update blackboard, don't change state or animation
		_update_blackboard("target", target)
		_update_blackboard("target_last_position", target.global_position)
		return
	
	match spot_type:
		"glimpse":
			emotional_state.on_heard_noise()
			_update_state_indicator("suspicious")
		"noticed":
			emotional_state.on_saw_target()
			set_current_state("alert")
		"confirmed":
			emotional_state.on_saw_target()
			set_current_state("investigating")
	
	# Update blackboard for behavior tree
	_update_blackboard("target", target)
	_update_blackboard("target_last_position", target.global_position)

func _on_target_lost(_target: Node3D) -> void:
	emotional_state.on_target_lost()
	_update_blackboard("target", null)

func _on_sound_heard(source_position: Vector3, sound_type: String, loudness: float) -> void:
	# Don't interrupt chase with investigation
	if current_state == "chasing":
		return
	
	match sound_type:
		"honk":
			emotional_state.on_heard_honk()
			set_current_state("investigating")
		"crash", "loud":
			emotional_state.on_heard_noise()
		_:
			if loudness > 0.5:
				emotional_state.on_heard_noise()
	
	_update_blackboard("investigate_position", source_position)

# ═══════════════════════════════════════
# SOCIAL CALLBACKS
# ═══════════════════════════════════════

func _on_alert_received(_from_npc: Node3D, alert_type: String, target_position: Vector3) -> void:
	match alert_type:
		"thief_spotted":
			emotional_state.on_heard_warning()
			_update_blackboard("investigate_position", target_position)
			set_current_state("responding_to_alert")
		"help_needed":
			emotional_state.on_heard_warning()
			emotional_state.alertness = 1.0  # Fully alert when help is needed
			_update_blackboard("help_position", target_position)
			set_current_state("helping")
		"suspicious":
			emotional_state.on_heard_noise()
			_update_blackboard("investigate_position", target_position)
		"all_clear":
			pass

func _on_help_requested(_from_npc: Node3D, _reason: String) -> void:
	pass

# ═══════════════════════════════════════
# EMOTIONAL STATE CALLBACKS
# ═══════════════════════════════════════

func _on_emotional_state_changed(_state_name: String, _old_val: float, _new_val: float) -> void:
	# Could trigger animations or sounds here
	pass

func _on_threshold_crossed(state_name: String, threshold: String, crossed_up: bool) -> void:
	if state_name == "annoyance" and threshold == "high" and crossed_up:
		# Consider calling for help
		if emotional_state.will_call_help:
			var target_pos = perception.get_last_known_position(perception.get_primary_target())
			if target_pos != Vector3.ZERO:
				social.call_for_help("thief", target_pos)
	elif state_name == "exhaustion" and threshold == "high" and crossed_up:
		pass  # Could trigger exhaustion effects

# ═══════════════════════════════════════
# EVENT HANDLERS (called by BT or external systems)
# ═══════════════════════════════════════

func on_heard_honk(from_position: Vector3) -> void:
	perception.hear_sound(from_position, "honk", 1.0)

func on_heard_noise(from_position: Vector3) -> void:
	perception.hear_sound(from_position, "noise", 0.5)

func on_saw_player(_seen_player: Node3D) -> void:
	emotional_state.on_saw_target()
	set_current_state("alert")

func on_item_stolen(_item: Node3D) -> void:
	emotional_state.on_saw_stealing()
	set_current_state("chasing")
	
	# Alert other NPCs
	if _player:
		social.send_alert("thief_spotted", _player.global_position)

func on_chase_started() -> void:
	set_current_state("chasing")
	_try_play_animation(["default/Sprint_Loop", "default/Jog_Fwd_Loop"])
	# Note: on_chasing(delta) should be called each frame during chase via _physics_process

func on_chase_ended(success: bool) -> void:
	if success:
		emotional_state.on_chase_success()
		set_current_state("caught")
		_try_play_animation(["default/Celebration", "default/Idle_Loop"])
		social.signal_all_clear()
		# After celebration, return to idle
		await get_tree().create_timer(2.0).timeout
		if current_state == "caught":
			set_current_state("idle")
	else:
		emotional_state.on_chase_failed()
		set_current_state("frustrated")
		_try_play_animation(["default/Idle_Tired_Loop", "default/Idle_Loop"])

func on_returned_home() -> void:
	emotional_state.on_returned_home()
	set_current_state("idle")
	_try_play_animation(["default/Idle_Loop", "default/Idle"])

func on_item_recovered() -> void:
	emotional_state.on_item_recovered()
	social.signal_all_clear()

func set_current_state(state: String) -> void:
	var old_state = current_state
	current_state = state
	# Play animation based on new state
	if state != old_state:
		_play_state_animation(state)
		_update_state_indicator(state)
		_update_vision_indicator(state)

func _update_state_indicator(state: String) -> void:
	# Get dialogue text from personality and store it
	var dialogue: String = ""
	if personality:
		match state:
			"idle":
				dialogue = personality.get_dialogue("idle")
				if dialogue.is_empty():
					dialogue = "Hmph."
			"alert":
				dialogue = personality.get_dialogue("alert")
				if dialogue.is_empty():
					dialogue = "Hm?"
			"investigating", "responding_to_alert":
				dialogue = personality.get_dialogue("suspicious")
				if dialogue.is_empty():
					dialogue = "Who's there?"
			"chasing", "helping":
				dialogue = personality.get_dialogue("chasing")
				if dialogue.is_empty():
					dialogue = "GET BACK HERE!"
			"searching":
				dialogue = personality.get_dialogue("searching")
				if dialogue.is_empty():
					dialogue = "Where'd you go?"
			"frustrated":
				dialogue = personality.get_dialogue("gave_up")
				if dialogue.is_empty():
					dialogue = "*wheeze*"
			"caught":
				dialogue = personality.get_dialogue("caught")
				if dialogue.is_empty():
					dialogue = "Got you!"
			"returning":
				dialogue = "Back to work..."
			_:
				dialogue = "Hmm..."  # Default for unknown states
	
	if dialogue.is_empty():
		dialogue = "Hmm..."
	
	# Store for info panel to use
	current_dialogue = dialogue
	
	# Show on bubble with state for contextual emoji
	if _state_indicator:
		_state_indicator.show_dialogue(dialogue, 0.0, state)


func _update_vision_indicator(state: String) -> void:
	if not _vision_indicator:
		return
	
	# Map current_state to vision indicator
	match state:
		"idle", "returning", "caught":
			_vision_indicator.set_state_idle()
		"alert", "investigating", "responding_to_alert", "searching":
			_vision_indicator.set_state_suspicious()
		"chasing", "helping":
			_vision_indicator.set_state_chasing()
		"frustrated":
			_vision_indicator.set_state_suspicious()  # Still watching
		_:
			_vision_indicator.set_state_idle()

# ═══════════════════════════════════════
# BLACKBOARD HELPERS
# ═══════════════════════════════════════
# CHASE COOLDOWN
# ═══════════════════════════════════════

func _update_chase_cooldown(delta: float) -> void:
	var bt_player: BTPlayer = get_node_or_null("BTPlayer")
	if not bt_player:
		return
	
	var bb = bt_player.get_blackboard()
	if not bb.has_var(&"chase_on_cooldown"):
		return  # Variable not in this BT's blackboard plan
	
	var on_cooldown = bb.get_var(&"chase_on_cooldown", false)
	if not on_cooldown:
		return
	
	var timer = bb.get_var(&"chase_cooldown_timer", 0.0)
	timer -= delta
	if timer <= 0:
		bb.set_var(&"chase_on_cooldown", false)
		bb.set_var(&"chase_cooldown_timer", 0.0)
	else:
		bb.set_var(&"chase_cooldown_timer", timer)

# ═══════════════════════════════════════
# BLACKBOARD HELPERS
# ═══════════════════════════════════════

func _setup_behavior_tree() -> void:
	var bt_player: BTPlayer = get_node_or_null("BTPlayer")
	if bt_player:
		var bb = bt_player.get_blackboard()
		bb.set_var(&"home_position", global_position)
		bb.set_var(&"emotional_state", emotional_state)
		bb.set_var(&"perception", perception)
		bb.set_var(&"social", social)

func _update_blackboard(key: StringName, value: Variant) -> void:
	var bt_player: BTPlayer = get_node_or_null("BTPlayer")
	if bt_player:
		bt_player.get_blackboard().set_var(key, value)

# ═══════════════════════════════════════
# ANIMATION HELPERS
# ═══════════════════════════════════════

func _play_animation(anim_name: String) -> void:
	var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if anim and anim.has_animation(anim_name):
		anim.play(anim_name)

func _try_play_animation(anim_names: Array) -> void:
	var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if not anim:
		return
	for anim_name in anim_names:
		if anim.has_animation(anim_name):
			anim.play(anim_name)
			return
	# Animation not found - silent fallback
	pass

func _play_idle_animation() -> void:
	_try_play_animation(["default/Idle"])

func _play_state_animation(state: String) -> void:
	match state:
		"idle":
			_try_play_animation(["default/Idle"])
		"alert":
			_try_play_animation(["default/Idle_LookAround", "default/Idle"])
		"investigating":
			_try_play_animation(["default/Walk", "default/Jog_Fwd"])
		"chasing":
			_try_play_animation(["default/Sprint", "default/Jog_Fwd"])
		"returning":
			_try_play_animation(["default/Walk", "default/Jog_Fwd"])
		"frustrated":
			_try_play_animation(["default/Idle_Tired", "default/Idle"])

func _update_editor_animation() -> void:
	if not is_inside_tree():
		return
	var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if anim and play_in_editor:
		anim.play("default/Idle")

# ═══════════════════════════════════════
# PUBLIC API (for BT conditions)
# ═══════════════════════════════════════

func get_emotional_state() -> NPCEmotionalState:
	return emotional_state

func get_perception() -> NPCPerception:
	return perception

func get_social() -> NPCSocial:
	return social

func is_willing_to_chase() -> bool:
	return emotional_state.will_chase

func should_give_up() -> bool:
	return emotional_state.will_give_up

func should_call_for_help() -> bool:
	return emotional_state.will_call_help

func get_mood() -> String:
	return emotional_state.mood

func get_awareness_of_player() -> float:
	if _player:
		return perception.get_awareness(_player)
	return 0.0

# ═══════════════════════════════════════
# PERSONALITY HELPERS
# ═══════════════════════════════════════

func get_display_name() -> String:
	if personality:
		return personality.display_name
	return "Unknown"

func get_title() -> String:
	if personality:
		return personality.title
	return "NPC"

func get_full_name() -> String:
	if personality:
		return personality.get_full_name()
	return "Unknown NPC"

func get_dialogue(event: String) -> String:
	if personality:
		return personality.get_dialogue(event)
	return "Hmm..."

func get_narrator_line() -> String:
	if personality:
		return personality.get_narrator_line(current_state)
	return "The subject remains under observation."

func has_recent_alerts() -> bool:
	return social.has_recent_alerts()
