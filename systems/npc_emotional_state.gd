class_name NPCEmotionalState
extends RefCounted
## 3-Meter Emotional System: Stamina, Suspicion, Temper
## Each meter = one clear player strategy

signal state_changed(meter_name: String, old_value: float, new_value: float)
signal threshold_crossed(meter_name: String, threshold: String, crossed_up: bool)

# ═══════════════════════════════════════
# THE 3 METERS (0 - 100)
# ═══════════════════════════════════════

## ⚡ STAMINA: Physical energy. Low = gives up, must rest.
## Player strategy: "Tire them out"
var stamina: float = 100.0:
	set(v):
		var old = stamina
		stamina = clampf(v, 0.0, 100.0)
		if abs(old - stamina) > 0.5:
			state_changed.emit("stamina", old, stamina)
			_check_thresholds("stamina", old, stamina)

## 👀 SUSPICION: Mental alertness. High = wider FOV, faster reactions.
## Player strategy: "Stay hidden"
var suspicion: float = 10.0:
	set(v):
		var old = suspicion
		suspicion = clampf(v, 0.0, 100.0)
		if abs(old - suspicion) > 0.5:
			state_changed.emit("suspicion", old, suspicion)
			_check_thresholds("suspicion", old, suspicion)

## 🔥 TEMPER: Anger level. High = faster, won't give up, remembers.
## Player strategy: "Don't push too hard"
var temper: float = 0.0:
	set(v):
		var old = temper
		temper = clampf(v, 0.0, 100.0)
		if abs(old - temper) > 0.5:
			state_changed.emit("temper", old, temper)
			_check_thresholds("temper", old, temper)

# ═══════════════════════════════════════
# DECAY/RECOVERY RATES (per second)
# ═══════════════════════════════════════

const STAMINA_RECOVERY = 5.0       # Recovers ~20 sec from 0 to 100
const STAMINA_DRAIN_CHASE = 15.0  # Drains while chasing (~6-7 sec to exhaust)
const STAMINA_DRAIN_RUN = 8.0     # Drains while running/searching

const SUSPICION_DECAY = 5.0       # Calms in ~20 sec from 100 to 0
const TEMPER_DECAY = 1.5          # Slow decay - anger persists (~65 sec)

# Baseline values (what they decay toward)
var base_stamina: float = 100.0
var base_suspicion: float = 10.0   # Slight baseline awareness
var base_temper: float = 0.0

# Rate modifiers (from personality, 1.0 = normal)
var stamina_rate_modifier: float = 1.0
var suspicion_rate_modifier: float = 1.0
var temper_rate_modifier: float = 1.0

# ═══════════════════════════════════════
# EVENT IMPACTS
# ═══════════════════════════════════════

# Sounds
const HONK_SUSPICION = 20.0
const HONK_TEMPER = 5.0
const NOISE_SUSPICION = 15.0

# Sightings
const SAW_PLAYER_SUSPICION = 40.0
const SAW_PLAYER_TEMPER = 10.0
const SAW_STEALING_SUSPICION = 60.0
const SAW_STEALING_TEMPER = 25.0
const LOST_SIGHT_SUSPICION = 15.0
const LOST_SIGHT_TEMPER = 10.0

# Chase events
const CHASE_FAIL_TEMPER = 15.0
const CHASE_FAIL_SUSPICION = 20.0
const CHASE_SUCCESS_TEMPER = -50.0  # Catching player calms anger significantly

# Item events
const ITEM_STOLEN_TEMPER = 25.0
const ITEM_STOLEN_SUSPICION = 30.0
const ITEM_RECOVERED_TEMPER = -15.0

# ═══════════════════════════════════════
# THRESHOLDS
# ═══════════════════════════════════════

const EXHAUSTED_THRESHOLD = 20.0     # Stamina below this = exhausted
const SUSPICIOUS_THRESHOLD = 40.0    # Suspicion above this = alert
const HUNTING_THRESHOLD = 70.0       # Suspicion above this = hunting mode
const ANGRY_THRESHOLD = 50.0         # Temper above this = aggressive
const FURIOUS_THRESHOLD = 80.0       # Temper above this = won't give up

# ═══════════════════════════════════════
# DERIVED STATES (for BT and display)
# ═══════════════════════════════════════

## Overall mood for display
var mood: String:
	get:
		if stamina < EXHAUSTED_THRESHOLD:
			return "exhausted"
		if temper >= FURIOUS_THRESHOLD:
			return "furious"
		if temper >= ANGRY_THRESHOLD:
			return "angry"
		if suspicion >= HUNTING_THRESHOLD:
			return "hunting"
		if suspicion >= SUSPICIOUS_THRESHOLD:
			return "suspicious"
		return "calm"

## Should NPC chase? Need HIGH suspicion (caught stealing) AND stamina
var will_chase: bool:
	get: return suspicion >= HUNTING_THRESHOLD and stamina > EXHAUSTED_THRESHOLD

## Should NPC give up? Too tired
var will_give_up: bool:
	get: return stamina <= EXHAUSTED_THRESHOLD

## Is NPC in hunting mode? High suspicion, searching actively
var is_hunting: bool:
	get: return suspicion >= HUNTING_THRESHOLD and stamina > EXHAUSTED_THRESHOLD

## Is NPC furious? Won't give up easily
var is_furious: bool:
	get: return temper >= FURIOUS_THRESHOLD

## Should NPC call for help? Very angry or tired but suspicious
var will_call_help: bool:
	get: return temper >= ANGRY_THRESHOLD or (stamina < 50.0 and suspicion > 50.0)

## Chase speed multiplier (temper makes them faster)
var chase_speed_multiplier: float:
	get: return 1.0 + (temper / 100.0) * 0.3  # Up to 30% faster when furious

## Detection range multiplier (suspicion widens FOV)
var detection_range_multiplier: float:
	get: return 0.8 + (suspicion / 100.0) * 0.4  # 80% to 120%

## FOV multiplier (suspicion widens cone)
var fov_multiplier: float:
	get: return 0.7 + (suspicion / 100.0) * 0.6  # 70% to 130% of base FOV

## How long before giving up chase (temper extends it)
var chase_give_up_time: float:
	get: 
		var base_time = 8.0
		var temper_bonus = (temper / 100.0) * 12.0  # Up to +12 sec when furious
		var stamina_penalty = ((100.0 - stamina) / 100.0) * 6.0  # Up to -6 sec when tired
		return maxf(base_time + temper_bonus - stamina_penalty, 3.0)

# ═══════════════════════════════════════
# UPDATE (call every frame)
# ═══════════════════════════════════════

func update(delta: float, is_chasing: bool = false, is_running: bool = false) -> void:
	# Stamina: drain when active, recover when idle
	if is_chasing:
		stamina -= STAMINA_DRAIN_CHASE * stamina_rate_modifier * delta
	elif is_running:
		stamina -= STAMINA_DRAIN_RUN * stamina_rate_modifier * delta
	else:
		stamina = move_toward(stamina, base_stamina, STAMINA_RECOVERY * stamina_rate_modifier * delta)
	
	# Suspicion: decay toward baseline
	suspicion = move_toward(suspicion, base_suspicion, SUSPICION_DECAY * suspicion_rate_modifier * delta)
	
	# Temper: decay very slowly (anger persists)
	temper = move_toward(temper, base_temper, TEMPER_DECAY * temper_rate_modifier * delta)

# ═══════════════════════════════════════
# EVENT HANDLERS
# ═══════════════════════════════════════

func on_heard_honk() -> void:
	suspicion += HONK_SUSPICION
	temper += HONK_TEMPER

func on_heard_noise() -> void:
	suspicion += NOISE_SUSPICION

func on_saw_player() -> void:
	suspicion += SAW_PLAYER_SUSPICION
	temper += SAW_PLAYER_TEMPER

func on_saw_stealing() -> void:
	suspicion = 100.0  # Max alert
	temper += SAW_STEALING_TEMPER

func on_lost_sight() -> void:
	suspicion += LOST_SIGHT_SUSPICION
	temper += LOST_SIGHT_TEMPER

func on_chase_failed() -> void:
	temper += CHASE_FAIL_TEMPER
	suspicion += CHASE_FAIL_SUSPICION

func on_chase_success() -> void:
	temper += CHASE_SUCCESS_TEMPER  # Negative = calms down

func on_item_stolen() -> void:
	temper += ITEM_STOLEN_TEMPER
	suspicion += ITEM_STOLEN_SUSPICION

func on_item_recovered() -> void:
	temper += ITEM_RECOVERED_TEMPER  # Negative = calms down

func on_distraction() -> void:
	suspicion -= 10.0

func on_returned_home() -> void:
	suspicion -= 15.0
	stamina += 10.0  # Brief rest

# ═══════════════════════════════════════
# LEGACY COMPATIBILITY (map old calls to new)
# ═══════════════════════════════════════

## Old alertness mapped to suspicion
var alertness: float:
	get: return suspicion / 100.0
	set(v): suspicion = v * 100.0

## Old annoyance mapped to temper
var annoyance: float:
	get: return temper / 100.0
	set(v): temper = v * 100.0

## Old exhaustion mapped to inverse stamina
var exhaustion: float:
	get: return (100.0 - stamina) / 100.0
	set(v): stamina = (1.0 - v) * 100.0

## Legacy event handlers
func on_saw_target() -> void:
	on_saw_player()

func on_target_lost() -> void:
	on_lost_sight()

func on_chasing(delta: float) -> void:
	stamina -= STAMINA_DRAIN_CHASE * delta

func on_heard_warning() -> void:
	suspicion += 25.0  # Another NPC warned us
	temper += 5.0

# ═══════════════════════════════════════
# UTILITY
# ═══════════════════════════════════════

func _check_thresholds(meter: String, old_val: float, new_val: float) -> void:
	var thresholds = {
		"stamina": [EXHAUSTED_THRESHOLD],
		"suspicion": [SUSPICIOUS_THRESHOLD, HUNTING_THRESHOLD],
		"temper": [ANGRY_THRESHOLD, FURIOUS_THRESHOLD]
	}
	
	if not thresholds.has(meter):
		return
	
	for threshold in thresholds[meter]:
		var crossed_up = old_val < threshold and new_val >= threshold
		var crossed_down = old_val >= threshold and new_val < threshold
		if crossed_up or crossed_down:
			var name = _threshold_name(meter, threshold)
			threshold_crossed.emit(meter, name, crossed_up)

func _threshold_name(meter: String, value: float) -> String:
	match meter:
		"stamina":
			if value == EXHAUSTED_THRESHOLD: return "exhausted"
		"suspicion":
			if value == SUSPICIOUS_THRESHOLD: return "suspicious"
			if value == HUNTING_THRESHOLD: return "hunting"
		"temper":
			if value == ANGRY_THRESHOLD: return "angry"
			if value == FURIOUS_THRESHOLD: return "furious"
	return "unknown"

func get_meter_values() -> Dictionary:
	return {
		"stamina": stamina,
		"suspicion": suspicion,
		"temper": temper
	}

func get_normalized_meters() -> Dictionary:
	return {
		"stamina": stamina / 100.0,
		"suspicion": suspicion / 100.0,
		"temper": temper / 100.0
	}

## Reset to calm baseline
func reset() -> void:
	stamina = base_stamina
	suspicion = base_suspicion
	temper = base_temper

## Get debug string
func get_debug_string() -> String:
	return "⚡%.0f 👀%.0f 🔥%.0f [%s]" % [stamina, suspicion, temper, mood]
