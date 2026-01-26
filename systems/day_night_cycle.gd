class_name DayNightCycle
extends Node
## Manages the day/night cycle with smooth transitions between time periods.
## Settings loaded from TODSettings resource file for easy tweaking.

signal time_of_day_changed(new_period: String, old_period: String)
signal time_updated(normalized_time: float)  # 0.0 to 1.0

enum TimePeriod { MORNING, AFTERNOON, EVENING, NIGHT }

const PERIOD_NAMES := ["Morning", "Afternoon", "Evening", "Night"]
const DEFAULT_SETTINGS_PATH := "res://systems/default_tod_settings.tres"

@export var settings: TODSettings  ## Assign a TODSettings resource or uses default
@export var auto_start: bool = true
@export var auto_cycle: bool = true  ## False = manual control only

@export_group("References")
@export var world_environment: WorldEnvironment
@export var directional_light: DirectionalLight3D

@export_group("Skyboxes")
@export var day_skybox: Texture2D
@export var night_skybox: Texture2D

# Fog colors per period
const FOG_COLORS := {
	"morning": Color(0.9, 0.75, 0.55),    # Golden sunrise haze
	"afternoon": Color(0.85, 0.88, 0.92), # Clear bright blue-white
	"evening": Color(0.75, 0.55, 0.5),    # Warm coral
	"night": Color(0.25, 0.3, 0.4),       # Cool blue
}

var _current_time: float = 0.0
var _paused: bool = false
var _current_period: TimePeriod = TimePeriod.MORNING
var _cached_materials: Array[ShaderMaterial] = []  # Cached for brightness updates
var _materials_cached: bool = false


func _ready() -> void:
	add_to_group("day_night_cycle")
	_load_settings()
	_auto_find_references()
	if auto_start:
		# Start at 9 AM (0.125 normalized: 0.125 * 24 + 6 = 9)
		_current_time = 0.125 * settings.cycle_duration
		_update_lighting()

	
	# Cache materials after other scripts have run (use timer to ensure GhibliShaderApplier finishes)
	get_tree().create_timer(0.1).timeout.connect(_cache_shader_materials)
	
	# Initialize save manager (ensures it's ready for F5/F9/Shift+R hotkeys)
	SimulationSaveManager.get_instance()


func _load_settings() -> void:
	if not settings:
		settings = load(DEFAULT_SETTINGS_PATH) as TODSettings
	if not settings:
		push_warning("DayNightCycle: No settings found, using defaults")
		settings = TODSettings.new()


func _auto_find_references() -> void:
	var scene_root = get_tree().current_scene
	if not scene_root:
		scene_root = get_parent()
	
	if not world_environment:
		world_environment = _find_node_of_type(scene_root, "WorldEnvironment") as WorldEnvironment
	
	if not directional_light:
		directional_light = _find_node_of_type(scene_root, "DirectionalLight3D") as DirectionalLight3D
	
	if not world_environment:
		push_warning("DayNightCycle: WorldEnvironment not found")
	if not directional_light:
		push_warning("DayNightCycle: DirectionalLight3D not found")


func _find_node_of_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var result = _find_node_of_type(child, type_name)
		if result:
			return result
	return null


func pause() -> void:
	_paused = true


func resume() -> void:
	_paused = false


func is_paused() -> bool:
	return _paused


func _process(delta: float) -> void:
	if _paused or not auto_cycle:
		return
	
	_current_time += delta
	if _current_time >= settings.cycle_duration:
		_current_time = fmod(_current_time, settings.cycle_duration)
	
	var normalized = _current_time / settings.cycle_duration
	time_updated.emit(normalized)
	
	_update_lighting()


func _update_lighting() -> void:
	var period_duration = settings.cycle_duration / 4.0
	var time_in_period = fmod(_current_time, period_duration)
	var period_index = int(_current_time / period_duration) % 4
	var new_period = period_index as TimePeriod
	
	if new_period != _current_period:
		var old_name = PERIOD_NAMES[_current_period]
		var new_name = PERIOD_NAMES[new_period]
		_current_period = new_period
		time_of_day_changed.emit(new_name, old_name)
	
	# Only blend at END of each period (approaching next period)
	# This prevents the "reset" bug where start-of-period blending undoes end-of-period blending
	var current = _get_period_settings(_current_period)
	var next_period = ((_current_period as int) + 1) % 4 as TimePeriod
	
	if time_in_period > period_duration - settings.transition_duration:
		# Approaching next period - blend from current to next
		var blend = (time_in_period - (period_duration - settings.transition_duration)) / settings.transition_duration
		var next = _get_period_settings(next_period)
		_apply_blended_settings(current, next, blend)
	else:
		# Not in transition - apply current period settings
		_apply_period_settings(_current_period)


func _get_period_settings(period: TimePeriod) -> Dictionary:
	match period:
		TimePeriod.MORNING:
			return {
				"light_color": settings.morning_light_color,
				"light_intensity": settings.morning_light_intensity,
				"ambient_color": settings.morning_ambient_color,
				"ambient_energy": settings.morning_ambient_energy,
				"brightness": settings.morning_brightness,
				"fog_color": FOG_COLORS.morning,
				"use_night_sky": false,
			}
		TimePeriod.AFTERNOON:
			return {
				"light_color": settings.afternoon_light_color,
				"light_intensity": settings.afternoon_light_intensity,
				"ambient_color": settings.afternoon_ambient_color,
				"ambient_energy": settings.afternoon_ambient_energy,
				"brightness": settings.afternoon_brightness,
				"fog_color": FOG_COLORS.afternoon,
				"use_night_sky": false,
			}
		TimePeriod.EVENING:
			return {
				"light_color": settings.evening_light_color,
				"light_intensity": settings.evening_light_intensity,
				"ambient_color": settings.evening_ambient_color,
				"ambient_energy": settings.evening_ambient_energy,
				"brightness": settings.evening_brightness,
				"fog_color": FOG_COLORS.evening,
				"use_night_sky": false,
			}
		TimePeriod.NIGHT:
			return {
				"light_color": settings.night_light_color,
				"light_intensity": settings.night_light_intensity,
				"ambient_color": settings.night_ambient_color,
				"ambient_energy": settings.night_ambient_energy,
				"brightness": settings.night_brightness,
				"fog_color": FOG_COLORS.night,
				"use_night_sky": true,
			}
	return {}


func _apply_period_settings(period: TimePeriod) -> void:
	var s = _get_period_settings(period)
	_apply_settings(s)


func _apply_blended_settings(from: Dictionary, to: Dictionary, blend: float) -> void:
	var blended := {
		"light_color": from.light_color.lerp(to.light_color, blend),
		"light_intensity": lerpf(from.light_intensity, to.light_intensity, blend),
		"ambient_color": from.ambient_color.lerp(to.ambient_color, blend),
		"ambient_energy": lerpf(from.ambient_energy, to.ambient_energy, blend),
		"brightness": lerpf(from.brightness, to.brightness, blend),
		"fog_color": from.fog_color.lerp(to.fog_color, blend),
		"use_night_sky": to.use_night_sky if blend > 0.5 else from.use_night_sky,
	}
	_apply_settings(blended)


func _apply_settings(s: Dictionary) -> void:
	if directional_light:
		directional_light.light_color = s.light_color
		directional_light.light_energy = s.light_intensity
	else:
		push_warning("[DayNightCycle] No directional_light!")
	
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = s.ambient_color
		env.ambient_light_energy = s.ambient_energy
		
		# Fog color
		if s.has("fog_color"):
			env.fog_light_color = s.fog_color
		
		# Switch skybox
		if s.has("use_night_sky") and env.sky and env.sky.sky_material:
			var sky_mat = env.sky.sky_material
			if sky_mat is PanoramaSkyMaterial:
				var target_sky = night_skybox if s.use_night_sky else day_skybox
				if target_sky and sky_mat.panorama != target_sky:
					sky_mat.panorama = target_sky
				sky_mat.energy_multiplier = s.brightness
	else:
		push_warning("[DayNightCycle] No world_environment!")
	
	# Set brightness on all shader materials
	_update_shader_brightness(s.brightness)


func _update_shader_brightness(brightness_value: float) -> void:
	# Cache materials if not done yet
	if not _materials_cached:
		_cache_shader_materials()
	
	# Update all cached materials
	for mat in _cached_materials:
		if is_instance_valid(mat):
			mat.set_shader_parameter("brightness", brightness_value)


func _cache_shader_materials() -> void:
	_cached_materials.clear()
	var scene_root = get_tree().current_scene
	if scene_root:
		_find_shader_materials_recursive(scene_root)
	_materials_cached = true

	
	# Apply current brightness immediately
	var s = _get_period_settings(_current_period)
	for mat in _cached_materials:
		mat.set_shader_parameter("brightness", s.brightness)


func _find_shader_materials_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		# Check material overrides
		for i in range(mesh_instance.get_surface_override_material_count()):
			var mat = mesh_instance.get_surface_override_material(i)
			if mat is ShaderMaterial and mat not in _cached_materials:
				_cached_materials.append(mat)

		# Check mesh materials
		if mesh_instance.mesh:
			for i in range(mesh_instance.mesh.get_surface_count()):
				var mat = mesh_instance.mesh.surface_get_material(i)
				if mat is ShaderMaterial and mat not in _cached_materials:
					_cached_materials.append(mat)
	
	for child in node.get_children():
		_find_shader_materials_recursive(child)


# === Public API ===

func get_current_period() -> String:
	return PERIOD_NAMES[_current_period]


func get_current_period_enum() -> TimePeriod:
	return _current_period


func get_normalized_time() -> float:
	return _current_time / settings.cycle_duration


func set_normalized_time(normalized: float) -> void:
	_current_time = clamp(normalized, 0.0, 1.0) * settings.cycle_duration
	_update_lighting()


func get_game_hour() -> int:
	var normalized = get_normalized_time()
	var hour = int(normalized * 24.0 + 6) % 24
	return hour


func get_game_time_string() -> String:
	var normalized = get_normalized_time()
	var total_minutes = int(normalized * 24.0 * 60.0 + 6 * 60) % (24 * 60)
	@warning_ignore("integer_division")
	var hour = total_minutes / 60
	var minute = total_minutes % 60
	var am_pm = "AM" if hour < 12 else "PM"
	var display_hour = hour % 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, minute, am_pm]


func set_time(normalized: float) -> void:
	_current_time = clampf(normalized, 0.0, 1.0) * settings.cycle_duration
	_update_lighting()
	time_updated.emit(normalized)


func set_period(period: TimePeriod, instant: bool = false) -> void:
	var period_duration = settings.cycle_duration / 4.0
	_current_time = (period as int) * period_duration + period_duration * 0.5
	
	if instant:
		_current_period = period
		_apply_period_settings(period)
	else:
		_update_lighting()
	
	time_updated.emit(get_normalized_time())


func skip_to_next_period() -> void:
	var period_duration = settings.cycle_duration / 4.0
	var current_period_index = int(_current_time / period_duration)
	_current_time = ((current_period_index + 1) % 4) * period_duration
	_update_lighting()
	time_updated.emit(get_normalized_time())
