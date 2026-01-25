class_name GameSpeedManager
extends Node
## Manages game time scale with keyboard shortcuts.
## Press 1-4 to change speed (0.25x, 1x, 2x, 4x).

signal speed_changed(new_speed: float)

const SPEEDS := [0.25, 1.0, 2.0, 4.0]
const SPEED_LABELS := ["0.25x", "1x", "2x", "4x"]

var current_speed_index: int = 1  # Default to 1x
var _paused_by_menu: bool = false
var _day_night_cycle: DayNightCycle = null

@export var show_speed_indicator: bool = true
@export var indicator_display_time: float = 1.5

var _speed_label: Label = null
var _label_tween: Tween = null


func _ready() -> void:
	# Create speed indicator label
	if show_speed_indicator:
		_create_speed_label()
	
	# Find day/night cycle to pause it too
	await get_tree().process_frame
	_day_night_cycle = get_tree().get_first_node_in_group("day_night_cycle")
	if not _day_night_cycle:
		# Try finding by type
		for node in get_tree().get_nodes_in_group(""):
			if node is DayNightCycle:
				_day_night_cycle = node
				break


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_1:
			set_speed_index(0)
		KEY_2:
			set_speed_index(1)
		KEY_3:
			set_speed_index(2)
		KEY_4:
			set_speed_index(3)


func _create_speed_label() -> void:
	var scale = _get_editor_scale()
	
	_speed_label = Label.new()
	_speed_label.name = "SpeedIndicator"
	_speed_label.text = "1x"
	
	# Load JetBrains Mono font
	var font = load("res://assets/fonts/JetBrainsMono.ttf")
	if font:
		_speed_label.add_theme_font_override("font", font)
	_speed_label.add_theme_font_size_override("font_size", int(32 * scale))
	_speed_label.modulate.a = 0.0
	
	# Position bottom-right
	_speed_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_speed_label.offset_left = -120
	_speed_label.offset_top = -70
	_speed_label.offset_right = -20
	_speed_label.offset_bottom = -20
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	# Add to canvas layer for UI
	var canvas = CanvasLayer.new()
	canvas.name = "SpeedIndicatorLayer"
	canvas.layer = 100
	add_child(canvas)
	canvas.add_child(_speed_label)


func _get_editor_scale() -> float:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_scale()
	return 2.0  # Default scale


func set_speed_index(index: int) -> void:
	index = clamp(index, 0, SPEEDS.size() - 1)
	if index == current_speed_index:
		return
	
	current_speed_index = index
	var speed = SPEEDS[index]
	
	# Apply time scale
	Engine.time_scale = speed
	
	# Emit signal
	speed_changed.emit(speed)
	
	# Show indicator
	_show_speed_indicator(SPEED_LABELS[index])


func get_current_speed() -> float:
	return SPEEDS[current_speed_index]


func pause_for_menu() -> void:
	_paused_by_menu = true
	Engine.time_scale = 0.0
	if _day_night_cycle:
		_day_night_cycle.pause()


func resume_from_menu() -> void:
	_paused_by_menu = false
	Engine.time_scale = SPEEDS[current_speed_index]
	if _day_night_cycle:
		_day_night_cycle.resume()


func pause_for_dialogue() -> void:
	# Similar to menu pause
	pause_for_menu()


func resume_from_dialogue() -> void:
	resume_from_menu()


func _show_speed_indicator(text: String) -> void:
	if not _speed_label:
		return
	
	_speed_label.text = text
	
	if _label_tween:
		_label_tween.kill()
	
	_label_tween = create_tween()
	_label_tween.set_ease(Tween.EASE_OUT)
	_label_tween.tween_property(_speed_label, "modulate:a", 1.0, 0.1)
	_label_tween.tween_interval(indicator_display_time)
	_label_tween.set_ease(Tween.EASE_IN)
	_label_tween.tween_property(_speed_label, "modulate:a", 0.0, 0.3)
