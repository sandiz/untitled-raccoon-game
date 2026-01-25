class_name DayNightCycle
extends Node
## Manages the day/night cycle with smooth transitions between time periods.
## Controls WorldEnvironment and DirectionalLight3D settings.

signal time_of_day_changed(new_period: String, old_period: String)
signal time_updated(normalized_time: float)  # 0.0 to 1.0

enum TimePeriod { MORNING, AFTERNOON, EVENING, NIGHT }

const PERIOD_NAMES := ["Morning", "Afternoon", "Evening", "Night"]

## Full day cycle duration in seconds (default 10 minutes)
@export var cycle_duration: float = 600.0
## Transition blend time in seconds
@export var transition_duration: float = 30.0
## Auto-start the cycle
@export var auto_start: bool = true

@export_group("References")
@export var world_environment: WorldEnvironment
@export var directional_light: DirectionalLight3D

@export_group("Morning")
@export var morning_light_color: Color = Color("#FFD700")
@export var morning_light_intensity: float = 0.7
@export var morning_ambient_color: Color = Color(0.9, 0.85, 0.8)
@export var morning_ambient_energy: float = 0.3
@export var morning_fog_color: Color = Color(0.85, 0.75, 0.7)
@export var morning_sky_rotation: float = -30.0  # Degrees

@export_group("Afternoon")
@export var afternoon_light_color: Color = Color("#FFFEF0")
@export var afternoon_light_intensity: float = 1.0
@export var afternoon_ambient_color: Color = Color(0.9, 0.88, 0.82)
@export var afternoon_ambient_energy: float = 0.35
@export var afternoon_fog_color: Color = Color(0.52, 0.55, 0.55)
@export var afternoon_sky_rotation: float = 0.0

@export_group("Evening")
@export var evening_light_color: Color = Color("#FF7F50")
@export var evening_light_intensity: float = 0.6
@export var evening_ambient_color: Color = Color(0.9, 0.7, 0.5)
@export var evening_ambient_energy: float = 0.25
@export var evening_fog_color: Color = Color(0.7, 0.5, 0.4)
@export var evening_sky_rotation: float = 30.0

@export_group("Night")
@export var night_light_color: Color = Color("#6495ED")
@export var night_light_intensity: float = 0.25
@export var night_ambient_color: Color = Color(0.3, 0.35, 0.5)
@export var night_ambient_energy: float = 0.15
@export var night_fog_color: Color = Color(0.15, 0.15, 0.25)
@export var night_sky_rotation: float = 60.0

var _current_time: float = 0.0  # Seconds into the cycle
var _paused: bool = false
var _current_period: TimePeriod = TimePeriod.MORNING


func _ready() -> void:
	if auto_start:
		_apply_period_settings(TimePeriod.MORNING, 1.0)


func pause() -> void:
	_paused = true
	Engine.time_scale = 0.0


func resume() -> void:
	_paused = false
	Engine.time_scale = 1.0


func is_paused() -> bool:
	return _paused


func _process(delta: float) -> void:
	if _paused:
		return
	
	_current_time += delta
	if _current_time >= cycle_duration:
		_current_time = fmod(_current_time, cycle_duration)
	
	var normalized = _current_time / cycle_duration
	time_updated.emit(normalized)
	
	_update_lighting()


func _update_lighting() -> void:
	var period_duration = cycle_duration / 4.0
	var time_in_period = fmod(_current_time, period_duration)
	var period_index = int(_current_time / period_duration) % 4
	var new_period = period_index as TimePeriod
	
	# Check for period change
	if new_period != _current_period:
		var old_name = PERIOD_NAMES[_current_period]
		var new_name = PERIOD_NAMES[new_period]
		_current_period = new_period
		time_of_day_changed.emit(new_name, old_name)
	
	# Calculate blend factor for transitions
	var blend = 1.0
	if time_in_period < transition_duration:
		# Transitioning from previous period
		blend = time_in_period / transition_duration
	elif time_in_period > period_duration - transition_duration:
		# Transitioning to next period
		blend = 1.0 - (time_in_period - (period_duration - transition_duration)) / transition_duration
	
	# Apply blended settings
	var current = _get_period_settings(_current_period)
	var next_period = ((_current_period as int) + 1) % 4 as TimePeriod
	var prev_period = ((_current_period as int) + 3) % 4 as TimePeriod
	
	if time_in_period < transition_duration:
		# Blend from previous
		var prev = _get_period_settings(prev_period)
		_apply_blended_settings(prev, current, blend)
	elif time_in_period > period_duration - transition_duration:
		# Blend to next
		var next = _get_period_settings(next_period)
		var reverse_blend = 1.0 - blend
		_apply_blended_settings(current, next, reverse_blend)
	else:
		# Full current period
		_apply_period_settings(_current_period, 1.0)


func _get_period_settings(period: TimePeriod) -> Dictionary:
	match period:
		TimePeriod.MORNING:
			return {
				"light_color": morning_light_color,
				"light_intensity": morning_light_intensity,
				"ambient_color": morning_ambient_color,
				"ambient_energy": morning_ambient_energy,
				"fog_color": morning_fog_color,
				"sky_rotation": morning_sky_rotation
			}
		TimePeriod.AFTERNOON:
			return {
				"light_color": afternoon_light_color,
				"light_intensity": afternoon_light_intensity,
				"ambient_color": afternoon_ambient_color,
				"ambient_energy": afternoon_ambient_energy,
				"fog_color": afternoon_fog_color,
				"sky_rotation": afternoon_sky_rotation
			}
		TimePeriod.EVENING:
			return {
				"light_color": evening_light_color,
				"light_intensity": evening_light_intensity,
				"ambient_color": evening_ambient_color,
				"ambient_energy": evening_ambient_energy,
				"fog_color": evening_fog_color,
				"sky_rotation": evening_sky_rotation
			}
		TimePeriod.NIGHT:
			return {
				"light_color": night_light_color,
				"light_intensity": night_light_intensity,
				"ambient_color": night_ambient_color,
				"ambient_energy": night_ambient_energy,
				"fog_color": night_fog_color,
				"sky_rotation": night_sky_rotation
			}
	return {}


func _apply_period_settings(period: TimePeriod, _blend: float) -> void:
	var settings = _get_period_settings(period)
	_apply_settings(settings)


func _apply_blended_settings(from: Dictionary, to: Dictionary, blend: float) -> void:
	var blended := {
		"light_color": from.light_color.lerp(to.light_color, blend),
		"light_intensity": lerpf(from.light_intensity, to.light_intensity, blend),
		"ambient_color": from.ambient_color.lerp(to.ambient_color, blend),
		"ambient_energy": lerpf(from.ambient_energy, to.ambient_energy, blend),
		"fog_color": from.fog_color.lerp(to.fog_color, blend),
		"sky_rotation": lerpf(from.sky_rotation, to.sky_rotation, blend)
	}
	_apply_settings(blended)


func _apply_settings(settings: Dictionary) -> void:
	if directional_light:
		directional_light.light_color = settings.light_color
		directional_light.light_energy = settings.light_intensity
		# Rotate light for sun position
		var base_rotation = Vector3(deg_to_rad(-45), deg_to_rad(30), 0)
		var sun_angle = deg_to_rad(settings.sky_rotation)
		directional_light.rotation = Vector3(base_rotation.x + sun_angle * 0.5, base_rotation.y, base_rotation.z)
	
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.ambient_light_color = settings.ambient_color
		env.ambient_light_energy = settings.ambient_energy
		if env.fog_enabled:
			env.fog_light_color = settings.fog_color


# Public API


func get_current_period() -> String:
	return PERIOD_NAMES[_current_period]


func get_current_period_enum() -> TimePeriod:
	return _current_period


func get_normalized_time() -> float:
	return _current_time / cycle_duration


func set_time(normalized: float) -> void:
	## Set time as 0.0-1.0 (0 = start of morning, 0.25 = start of afternoon, etc)
	_current_time = clampf(normalized, 0.0, 1.0) * cycle_duration
	_update_lighting()


func set_period(period: TimePeriod, instant: bool = false) -> void:
	## Jump to a specific time period
	var period_duration = cycle_duration / 4.0
	_current_time = (period as int) * period_duration + period_duration * 0.5
	
	if instant:
		_current_period = period
		_apply_period_settings(period, 1.0)
	else:
		_update_lighting()


func skip_to_next_period() -> void:
	## Skip to the start of the next time period
	var period_duration = cycle_duration / 4.0
	var current_period_index = int(_current_time / period_duration)
	_current_time = ((current_period_index + 1) % 4) * period_duration
	_update_lighting()
