class_name ShopkeeperAnimator
extends RefCounted
## Handles all animation logic for the shopkeeper NPC.
## Extracted from shopkeeper_npc.gd for cleaner separation.

# ═══════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════

## States that override velocity-based animation
const DOMINATED_STATES = ["chasing", "frustrated", "caught"]

## Animation mappings per state
const STATE_ANIMATIONS = {
	"idle": ["default/Idle"],
	"alert": ["default/Idle_LookAround", "default/Idle"],
	"investigating": ["default/Walk", "default/Jog_Fwd"],
	"chasing": ["default/Sprint", "default/Jog_Fwd"],
	"returning": ["default/Walk", "default/Jog_Fwd"],
	"frustrated": ["default/Idle_Tired", "default/Idle"],
	"caught": ["default/Celebration", "default/Idle"],
	"searching": ["default/Walk", "default/Jog_Fwd"],
}

const WALK_ANIMATIONS = ["default/Walk", "default/Jog_Fwd"]
const IDLE_ANIMATIONS = ["default/Idle"]

# ═══════════════════════════════════════
# STATE
# ═══════════════════════════════════════

var _npc: Node3D
var _anim_player: AnimationPlayer
var _last_anim_state: String = ""
var _last_was_moving: bool = false

# ═══════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════

func setup(npc: Node3D) -> void:
	_npc = npc
	_anim_player = npc.get_node_or_null("AnimationPlayer")

# ═══════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════

## Call every physics frame to update animation based on state and velocity
func update(current_state: String, velocity: Vector3) -> void:
	if not _anim_player:
		return
	
	var is_moving = velocity.length() > 0.1
	
	# Determine what animation state we should be in
	var anim_state: String
	if current_state in DOMINATED_STATES:
		anim_state = current_state
	elif is_moving:
		anim_state = "_moving"
	else:
		anim_state = "_idle"
	
	# Only change animation if state changed
	if anim_state == _last_anim_state and is_moving == _last_was_moving:
		return
	
	_last_anim_state = anim_state
	_last_was_moving = is_moving
	
	# Play appropriate animation
	if current_state in DOMINATED_STATES:
		_play_state_animation(current_state)
	elif is_moving:
		_try_play_animation(WALK_ANIMATIONS)
	else:
		_try_play_animation(IDLE_ANIMATIONS)

## Play idle animation (for startup/reset)
func play_idle() -> void:
	_try_play_animation(IDLE_ANIMATIONS)

## Play animation for editor preview
func play_editor_preview() -> void:
	if _anim_player:
		_anim_player.play("default/Idle")

## Force play a specific state animation
func play_state(state: String) -> void:
	_play_state_animation(state)

# ═══════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════

func _play_state_animation(state: String) -> void:
	if state in STATE_ANIMATIONS:
		_try_play_animation(STATE_ANIMATIONS[state])
	else:
		_try_play_animation(IDLE_ANIMATIONS)

func _try_play_animation(anim_names: Array) -> void:
	if not _anim_player:
		return
	for anim_name in anim_names:
		if _anim_player.has_animation(anim_name):
			_anim_player.play(anim_name)
			return

func _play_animation(anim_name: String) -> void:
	if _anim_player and _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name)
