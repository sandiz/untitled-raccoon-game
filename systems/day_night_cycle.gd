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
		# Start at 3 AM for night testing (0.875 normalized)
		_current_time = 0.875 * settings.cycle_duration
		_update_lighting()
		# Debug output
		print("[DayNightCycle] Ready - Period: ", PERIOD_NAMES[_current_period])
		print("[DayNightCycle] DirectionalLight: ", directional_light)
		print("[DayNightCycle] WorldEnvironment: ", world_environment)
	
	# Cache materials after other scripts have run (use timer to ensure GhibliShaderApplier finishes)
	get_tree().create_timer(0.1).timeout.connect(_cache_shader_materials)


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
	
	# Calculate blend factor for transitions
	var blend = 1.0
	if time_in_period < settings.transition_duration:
		blend = time_in_period / settings.transition_duration
	elif time_in_period > period_duration - settings.transition_duration:
		blend = 1.0 - (time_in_period - (period_duration - settings.transition_duration)) / settings.transition_duration
	
	var current = _get_period_settings(_current_period)
	var next_period = ((_current_period as int) + 1) % 4 as TimePeriod
	var prev_period = ((_current_period as int) + 3) % 4 as TimePeriod
	
	if time_in_period < settings.transition_duration:
		var prev = _get_period_settings(prev_period)
		_apply_blended_settings(prev, current, blend)
	elif time_in_period > period_duration - settings.transition_duration:
		var next = _get_period_settings(next_period)
		_apply_blended_settings(current, next, 1.0 - blend)
	else:
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
			}
		TimePeriod.AFTERNOON:
			return {
				"light_color": settings.afternoon_light_color,
				"light_intensity": settings.afternoon_light_intensity,
				"ambient_color": settings.afternoon_ambient_color,
				"ambient_energy": settings.afternoon_ambient_energy,
				"brightness": settings.afternoon_brightness,
			}
		TimePeriod.EVENING:
			return {
				"light_color": settings.evening_light_color,
				"light_intensity": settings.evening_light_intensity,
				"ambient_color": settings.evening_ambient_color,
				"ambient_energy": settings.evening_ambient_energy,
				"brightness": settings.evening_brightness,
			}
		TimePeriod.NIGHT:
			return {
				"light_color": settings.night_light_color,
				"light_intensity": settings.night_light_intensity,
				"ambient_color": settings.night_ambient_color,
				"ambient_energy": settings.night_ambient_energy,
				"brightness": settings.night_brightness,
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
		
		# Darken the sky at night
		if env.sky and env.sky.sky_material:
			var sky_mat = env.sky.sky_material
			if sky_mat is PanoramaSkyMaterial:
				# Reduce sky brightness based on overall brightness
				sky_mat.energy_multiplier = s.brightness
	else:
		push_warning("[DayNightCycle] No world_environment!")
	
	# Debug: print settings once per period change
	if Engine.get_process_frames() % 120 == 0:
		print("[TOD] light_energy=", s.light_intensity, " ambient_energy=", s.ambient_energy, " brightness=", s.brightness)
	
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
	print("[DayNightCycle] Cached ", _cached_materials.size(), " shader materials")
	
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
				print("[DayNightCycle] Found material on: ", node.name, " (override)")
		# Check mesh materials
		if mesh_instance.mesh:
			for i in range(mesh_instance.mesh.get_surface_count()):
				var mat = mesh_instance.mesh.surface_get_material(i)
				if mat is ShaderMaterial and mat not in _cached_materials:
					_cached_materials.append(mat)
					print("[DayNightCycle] Found material on: ", node.name, " (mesh)")
	
	for child in node.get_children():
		_find_shader_materials_recursive(child)


# === Public API ===

func get_current_period() -> String:
	return PERIOD_NAMES[_current_period]


func get_current_period_enum() -> TimePeriod:
	return _current_period


func get_normalized_time() -> float:
	return _current_time / settings.cycle_duration


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
