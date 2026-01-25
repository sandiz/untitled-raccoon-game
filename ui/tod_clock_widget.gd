class_name TODClockWidget
extends Control
## Time of Day clock widget - Option A style (minimal with period buttons + controls)
## Designed for top-left positioning with downward expansion.

signal period_selected(period_index: int)
signal auto_advance_toggled(enabled: bool)

const PERIOD_ICONS := ["🌅", "☀", "🌆", "🌙"]  # Morning, Afternoon, Evening, Night
const PERIOD_NAMES := ["Morning", "Afternoon", "Evening", "Night"]
const PERIOD_COLORS := [
	Color("#FFD700"),  # Morning - Gold
	Color("#FFFACD"),  # Afternoon - Lemon
	Color("#FF7F50"),  # Evening - Coral
	Color("#6495ED")   # Night - Blue
]

@export var day_night_cycle_path: NodePath

var _day_night: DayNightCycle = null
var _expanded: bool = false
var _auto_advance: bool = true
var _current_speed: int = 1

# UI elements
var _container: PanelContainer
var _main_vbox: VBoxContainer
var _collapsed_row: HBoxContainer
var _expanded_box: VBoxContainer
var _icon_label: Label
var _time_label: Label
var _period_label: Label
var _progress_bar: ProgressBar
var _period_buttons: Array[Button] = []
var _pause_btn: Button
var _speed_label: Label
var _expand_btn: Button
var _editor_scale: float = 1.0


func _ready() -> void:
	_editor_scale = _get_editor_scale()
	_setup_ui()
	call_deferred("_connect_day_night")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V:
			_toggle_expanded()
			get_viewport().set_input_as_handled()


func _connect_day_night() -> void:
	if day_night_cycle_path:
		_day_night = get_node_or_null(day_night_cycle_path)
	
	if not _day_night:
		_day_night = get_tree().get_first_node_in_group("day_night_cycle")
	
	if not _day_night:
		for node in get_tree().root.get_children():
			_day_night = _find_day_night_recursive(node)
			if _day_night:
				break
	
	if _day_night:
		_day_night.time_of_day_changed.connect(_on_period_changed)
		_day_night.time_updated.connect(_on_time_updated)
		_update_display()


func _find_day_night_recursive(node: Node) -> DayNightCycle:
	if node is DayNightCycle:
		return node
	for child in node.get_children():
		var result = _find_day_night_recursive(child)
		if result:
			return result
	return null


func _setup_ui() -> void:
	var font = load("res://assets/fonts/JetBrainsMono.ttf")
	
	# Main container - BIGGER base size
	_container = PanelContainer.new()
	_container.custom_minimum_size = Vector2(_s(220), 0)
	add_child(_container)
	
	# Panel style - dark translucent
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08, 0.92)
	style.set_border_width_all(2)
	style.border_color = Color(0.25, 0.25, 0.3, 0.9)
	style.set_corner_radius_all(_s(10))
	style.set_content_margin_all(_s(14))
	_container.add_theme_stylebox_override("panel", style)
	
	# Main VBox
	_main_vbox = VBoxContainer.new()
	_main_vbox.add_theme_constant_override("separation", _s(10))
	_container.add_child(_main_vbox)
	
	# === COLLAPSED ROW ===
	_collapsed_row = HBoxContainer.new()
	_collapsed_row.add_theme_constant_override("separation", _s(12))
	_main_vbox.add_child(_collapsed_row)
	
	# Icon (sun/moon emoji) - FIXED WIDTH to prevent layout shift
	_icon_label = Label.new()
	_icon_label.add_theme_font_override("font", font)
	_icon_label.add_theme_font_size_override("font_size", _s(28))
	_icon_label.custom_minimum_size = Vector2(_s(36), 0)
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.text = "☀"
	_collapsed_row.add_child(_icon_label)
	
	# Time + Period info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", _s(4))
	_collapsed_row.add_child(info_vbox)
	
	# Time label (HH:MM) - BIG
	_time_label = Label.new()
	_time_label.add_theme_font_override("font", font)
	_time_label.add_theme_font_size_override("font_size", _s(24))
	_time_label.text = "08:00"
	info_vbox.add_child(_time_label)
	
	# Period name
	_period_label = Label.new()
	_period_label.add_theme_font_override("font", font)
	_period_label.add_theme_font_size_override("font_size", _s(14))
	_period_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	_period_label.text = "Morning"
	info_vbox.add_child(_period_label)
	
	# Progress bar
	_progress_bar = _create_progress_bar(_s(140), _s(6))
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(_progress_bar)
	
	# Expand button
	_expand_btn = Button.new()
	_expand_btn.text = "▼"
	_expand_btn.add_theme_font_override("font", font)
	_expand_btn.add_theme_font_size_override("font_size", _s(14))
	_expand_btn.custom_minimum_size = Vector2(_s(32), _s(32))
	_expand_btn.pressed.connect(_toggle_expanded)
	_collapsed_row.add_child(_expand_btn)
	
	# === EXPANDED BOX ===
	_expanded_box = VBoxContainer.new()
	_expanded_box.add_theme_constant_override("separation", _s(12))
	_expanded_box.visible = false
	_main_vbox.add_child(_expanded_box)
	
	# Separator
	var sep = HSeparator.new()
	_expanded_box.add_child(sep)
	
	# Period buttons row - BIGGER
	var period_label = Label.new()
	period_label.add_theme_font_override("font", font)
	period_label.add_theme_font_size_override("font_size", _s(12))
	period_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	period_label.text = "Jump to period:"
	_expanded_box.add_child(period_label)
	
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", _s(8))
	_expanded_box.add_child(btn_row)
	
	for i in range(4):
		var btn = Button.new()
		btn.text = PERIOD_ICONS[i]
		btn.tooltip_text = PERIOD_NAMES[i]
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", _s(20))
		btn.custom_minimum_size = Vector2(_s(48), _s(40))
		btn.pressed.connect(_on_period_button_pressed.bind(i))
		btn_row.add_child(btn)
		_period_buttons.append(btn)
	
	# Controls row (Pause + Speed)
	var sep2 = HSeparator.new()
	_expanded_box.add_child(sep2)
	
	var controls_row = HBoxContainer.new()
	controls_row.add_theme_constant_override("separation", _s(12))
	_expanded_box.add_child(controls_row)
	
	# Pause button
	_pause_btn = Button.new()
	_pause_btn.text = "⏸ Pause"
	_pause_btn.add_theme_font_override("font", font)
	_pause_btn.add_theme_font_size_override("font_size", _s(14))
	_pause_btn.custom_minimum_size = Vector2(_s(90), _s(36))
	_pause_btn.pressed.connect(_on_pause_pressed)
	controls_row.add_child(_pause_btn)
	
	# Speed label + buttons
	var speed_box = HBoxContainer.new()
	speed_box.add_theme_constant_override("separation", _s(6))
	controls_row.add_child(speed_box)
	
	_speed_label = Label.new()
	_speed_label.add_theme_font_override("font", font)
	_speed_label.add_theme_font_size_override("font_size", _s(14))
	_speed_label.text = "1x"
	_speed_label.custom_minimum_size = Vector2(_s(36), 0)
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_box.add_child(_speed_label)
	
	var speed_up = Button.new()
	speed_up.text = "▲"
	speed_up.add_theme_font_override("font", font)
	speed_up.add_theme_font_size_override("font_size", _s(12))
	speed_up.custom_minimum_size = Vector2(_s(32), _s(36))
	speed_up.pressed.connect(_on_speed_up)
	speed_box.add_child(speed_up)
	
	var speed_down = Button.new()
	speed_down.text = "▼"
	speed_down.add_theme_font_override("font", font)
	speed_down.add_theme_font_size_override("font_size", _s(12))
	speed_down.custom_minimum_size = Vector2(_s(32), _s(36))
	speed_down.pressed.connect(_on_speed_down)
	speed_box.add_child(speed_down)
	
	# Make collapsed row clickable
	_collapsed_row.mouse_filter = Control.MOUSE_FILTER_STOP
	_collapsed_row.gui_input.connect(_on_collapsed_input)


func _create_progress_bar(width: int, height: int) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.max_value = 1.0
	bar.value = 0.5
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, height)
	
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.7, 0.3)
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.2)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	
	return bar


func _toggle_expanded() -> void:
	_expanded = not _expanded
	_expanded_box.visible = _expanded
	_expand_btn.text = "▲" if _expanded else "▼"


func _on_collapsed_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle_expanded()


func _on_period_button_pressed(index: int) -> void:
	if _day_night:
		_day_night.set_period(index as DayNightCycle.TimePeriod, false)
	period_selected.emit(index)


func _on_pause_pressed() -> void:
	if _day_night:
		if _day_night.is_paused():
			_day_night.resume()
			_pause_btn.text = "⏸ Pause"
		else:
			_day_night.pause()
			_pause_btn.text = "▶ Play"


func _on_speed_up() -> void:
	_current_speed = mini(_current_speed + 1, 4)
	_apply_speed()


func _on_speed_down() -> void:
	_current_speed = maxi(_current_speed - 1, 1)
	_apply_speed()


func _apply_speed() -> void:
	_speed_label.text = "%dx" % _current_speed
	Engine.time_scale = float(_current_speed)


func _on_auto_toggled(enabled: bool) -> void:
	_auto_advance = enabled
	if _day_night:
		if enabled:
			_day_night.resume()
		else:
			_day_night.pause()
	auto_advance_toggled.emit(enabled)


func _on_period_changed(_new_period: String, _old_period: String) -> void:
	_update_display()


func _on_time_updated(normalized: float) -> void:
	# Update period progress (progress within current period)
	var period_progress = fmod(normalized * 4.0, 1.0)
	_progress_bar.value = period_progress
	
	# Update time display from GameTime autoload
	var game_time = get_node_or_null("/root/GameTime")
	if game_time:
		_time_label.text = game_time.game_time_string


func _update_display() -> void:
	if not _day_night:
		return
	
	var period_name = _day_night.get_current_period()
	var period_index = PERIOD_NAMES.find(period_name)
	if period_index < 0:
		period_index = 0
	
	var color = PERIOD_COLORS[period_index]
	
	# Update icon
	_icon_label.text = PERIOD_ICONS[period_index]
	
	# Update time color
	_time_label.add_theme_color_override("font_color", color)
	
	# Update period name
	_period_label.text = period_name
	
	# Update progress bar color
	var fill = _progress_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	fill.bg_color = color
	_progress_bar.add_theme_stylebox_override("fill", fill)
	
	# Highlight current period button
	for i in range(_period_buttons.size()):
		var btn = _period_buttons[i]
		if i == period_index:
			btn.modulate = color
		else:
			btn.modulate = Color.WHITE


func _get_editor_scale() -> float:
	if Engine.is_editor_hint():
		var ei = EditorInterface.get_editor_settings()
		if ei:
			return EditorInterface.get_editor_scale()
	return 2.0


# Shorthand for scaling
func _s(val: int) -> int:
	return int(val * _editor_scale)
