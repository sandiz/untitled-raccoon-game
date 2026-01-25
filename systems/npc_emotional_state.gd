class_name NPCEmotionalState
extends RefCounted
## Manages NPC emotional variables with forgiving tuning.
## Attach to NPC and call update() each frame.

signal state_changed(state_name: String, old_value: float, new_value: float)
signal threshold_crossed(state_name: String, threshold: String, crossed_up: bool)

# ═══════════════════════════════════════
# CORE EMOTIONAL STATES (0.0 - 1.0)
# ═══════════════════════════════════════

var alertness: float = 0.2:
	set(v):
		var old = alertness
		alertness = clampf(v, 0.0, 1.0)
		if abs(old - alertness) > 0.01:
			state_changed.emit("alertness", old, alertness)
			_check_thresholds("alertness", old, alertness)

var annoyance: float = 0.0:
	set(v):
		var old = annoyance
		annoyance = clampf(v, 0.0, 1.0)
		if abs(old - annoyance) > 0.01:
			state_changed.emit("annoyance", old, annoyance)
			_check_thresholds("annoyance", old, annoyance)

var exhaustion: float = 0.0:
	set(v):
		var old = exhaustion
		exhaustion = clampf(v, 0.0, 1.0)
		if abs(old - exhaustion) > 0.01:
			state_changed.emit("exhaustion", old, exhaustion)
			_check_thresholds("exhaustion", old, exhaustion)

var suspicion: float = 0.0:
	set(v):
		var old = suspicion
		suspicion = clampf(v, 0.0, 1.0)
		if abs(old - suspicion) > 0.01:
			state_changed.emit("suspicion", old, suspicion)
			_check_thresholds("suspicion", old, suspicion)

# ═══════════════════════════════════════
# DECAY RATES (per real second) - FORGIVING
# ═══════════════════════════════════════

const ALERTNESS_DECAY = 0.08      # Calms in ~12 seconds
const ANNOYANCE_DECAY = 0.04      # Cools off in ~25 seconds
const EXHAUSTION_DECAY = 0.05     # Recovers in ~20 seconds
const SUSPICION_DECAY = 0.04      # Forgets in ~25 seconds

# Baseline values (what they decay toward)
var base_alertness: float = 0.2
var base_annoyance: float = 0.0
var base_exhaustion: float = 0.0
var base_suspicion: float = 0.0

# Rate modifiers (from personality, 1.0 = normal)
var alertness_rate_modifier: float = 1.0
var annoyance_rate_modifier: float = 1.0
var exhaustion_rate_modifier: float = 1.0
var suspicion_rate_modifier: float = 1.0

# ═══════════════════════════════════════
# EVENT IMPACTS - FORGIVING (slower buildup)
# ═══════════════════════════════════════

# Sounds
const HONK_ALERTNESS = 0.2
const HONK_ANNOYANCE = 0.05
const HONK_SUSPICION = 0.15
const NOISE_ALERTNESS = 0.15
const NOISE_SUSPICION = 0.1

# Sightings
const SAW_TARGET_ALERTNESS = 0.8
const SAW_TARGET_SUSPICION = 0.3
const SAW_STEALING_ANNOYANCE = 0.2
const SAW_STEALING_ALERTNESS = 1.0
const LOST_SIGHT_SUSPICION = 0.2

# Chase events
const CHASE_EXHAUSTION_RATE = 0.04  # per second while chasing
const CHASE_FAIL_ANNOYANCE = 0.1
const CHASE_FAIL_EXHAUSTION = 0.15
const CHASE_FAIL_SUSPICION = 0.15
const CHASE_SUCCESS_ANNOYANCE = -0.15
const CHASE_SUCCESS_EXHAUSTION = 0.1

# Recovery / positive events
const ITEM_RECOVERED_ANNOYANCE = -0.15
const SHOO_SUCCESS_ANNOYANCE = -0.1
const RETURNED_HOME_ALERTNESS = -0.3
const RETURNED_HOME_EXHAUSTION = -0.1
const TASK_COMPLETE_EXHAUSTION = -0.1
const FALSE_ALARM_SUSPICION = -0.15
const FALSE_ALARM_ALERTNESS = -0.1

# ═══════════════════════════════════════
# THRESHOLDS - FORGIVING
# ═══════════════════════════════════════

const THRESHOLD_LOW = 0.3
const THRESHOLD_MEDIUM = 0.5
const THRESHOLD_HIGH = 0.7
const THRESHOLD_EXTREME = 0.9

const GIVE_UP_EXHAUSTION = 0.7
const CALL_HELP_ANNOYANCE = 0.8
const CHASE_MIN_ALERTNESS = 0.3

# ═══════════════════════════════════════
# DERIVED STATES
# ═══════════════════════════════════════

var mood: String:
	get:
		if exhaustion > THRESHOLD_HIGH:
			return "exhausted"
		if annoyance > THRESHOLD_HIGH:
			return "angry"
		if annoyance > THRESHOLD_MEDIUM:
			return "annoyed"
		if alertness > THRESHOLD_HIGH:
			return "alarmed"
		if alertness > THRESHOLD_MEDIUM:
			return "alert"
		if suspicion > THRESHOLD_MEDIUM:
			return "wary"
		return "calm"

var will_chase: bool:
	# Only chase if raccoon did something wrong (annoyed or suspicious) AND alert
	get: return alertness >= CHASE_MIN_ALERTNESS and (annoyance >= 0.1 or suspicion >= 0.3) and exhaustion < GIVE_UP_EXHAUSTION

var will_give_up: bool:
	get: return exhaustion >= GIVE_UP_EXHAUSTION

var will_call_help: bool:
	get: return annoyance >= CALL_HELP_ANNOYANCE or (exhaustion > 0.5 and suspicion > 0.5)

var threat_response_multiplier: float:
	get: return (1.0 + alertness * 0.5) * (1.0 - exhaustion * 0.5)

var detection_range_multiplier: float:
	get: return 0.7 + alertness * 0.6  # 70% to 130%

var chase_give_up_time: float:
	get: return 10.0 + (annoyance * 10.0) - (exhaustion * 15.0)

# ═══════════════════════════════════════
# UPDATE (call every frame)
# ═══════════════════════════════════════

func update(delta: float) -> void:
	# Decay toward baseline
	alertness = move_toward(alertness, base_alertness, ALERTNESS_DECAY * delta)
	annoyance = move_toward(annoyance, base_annoyance, ANNOYANCE_DECAY * delta)
	exhaustion = move_toward(exhaustion, base_exhaustion, EXHAUSTION_DECAY * delta)
	suspicion = move_toward(suspicion, base_suspicion, SUSPICION_DECAY * delta)

# ═══════════════════════════════════════
# EVENT HANDLERS
# ═══════════════════════════════════════

func on_heard_honk() -> void:
	alertness += HONK_ALERTNESS
	annoyance += HONK_ANNOYANCE
	suspicion += HONK_SUSPICION

func on_heard_noise() -> void:
	alertness += NOISE_ALERTNESS
	suspicion += NOISE_SUSPICION

func on_saw_target() -> void:
	alertness += SAW_TARGET_ALERTNESS
	suspicion += SAW_TARGET_SUSPICION

func on_saw_stealing() -> void:
	alertness = 1.0
	annoyance += SAW_STEALING_ANNOYANCE
	suspicion = 1.0

func on_lost_sight() -> void:
	suspicion += LOST_SIGHT_SUSPICION

func on_chasing(delta: float) -> void:
	exhaustion += CHASE_EXHAUSTION_RATE * delta

func on_chase_failed() -> void:
	annoyance += CHASE_FAIL_ANNOYANCE
	exhaustion += CHASE_FAIL_EXHAUSTION
	suspicion += CHASE_FAIL_SUSPICION

func on_chase_success() -> void:
	# Caught the player - feel satisfied, calm down
	annoyance = maxf(annoyance + CHASE_SUCCESS_ANNOYANCE, 0.0)
	exhaustion += CHASE_SUCCESS_EXHAUSTION
	alertness = base_alertness  # Reset to baseline
	suspicion = 0.0  # No longer suspicious

func on_item_recovered() -> void:
	annoyance += ITEM_RECOVERED_ANNOYANCE

func on_shoo_success() -> void:
	annoyance += SHOO_SUCCESS_ANNOYANCE

func on_returned_home() -> void:
	alertness += RETURNED_HOME_ALERTNESS
	exhaustion += RETURNED_HOME_EXHAUSTION

func on_task_complete() -> void:
	exhaustion += TASK_COMPLETE_EXHAUSTION

func on_false_alarm() -> void:
	suspicion += FALSE_ALARM_SUSPICION
	alertness += FALSE_ALARM_ALERTNESS

## Alias for on_lost_sight (for easier API usage)
func on_target_lost() -> void:
	on_lost_sight()

## Heard a warning from another NPC
func on_heard_warning() -> void:
	alertness += 0.4
	suspicion += 0.3

# ═══════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════

func _check_thresholds(state_name: String, old_val: float, new_val: float) -> void:
	for threshold in [THRESHOLD_LOW, THRESHOLD_MEDIUM, THRESHOLD_HIGH, THRESHOLD_EXTREME]:
		if old_val < threshold and new_val >= threshold:
			var t_name = _threshold_name(threshold)
			threshold_crossed.emit(state_name, t_name, true)
		elif old_val >= threshold and new_val < threshold:
			var t_name = _threshold_name(threshold)
			threshold_crossed.emit(state_name, t_name, false)

func _threshold_name(t: float) -> String:
	if t == THRESHOLD_LOW: return "low"
	if t == THRESHOLD_MEDIUM: return "medium"
	if t == THRESHOLD_HIGH: return "high"
	return "extreme"

func reset() -> void:
	alertness = base_alertness
	annoyance = base_annoyance
	exhaustion = base_exhaustion
	suspicion = base_suspicion

func get_debug_dict() -> Dictionary:
	return {
		"alertness": alertness,
		"annoyance": annoyance,
		"exhaustion": exhaustion,
		"suspicion": suspicion,
		"mood": mood,
		"will_chase": will_chase,
		"will_give_up": will_give_up,
		"will_call_help": will_call_help
	}
