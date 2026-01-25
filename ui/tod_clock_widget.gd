extends BaseWidget
## Time of Day clock widget - extends BaseWidget for shared styling.

signal period_selected(period_index: int)

const PERIOD_ICONS := ["🌅", "☀", "🌆", "🌙"]
const PERIOD_NAMES := ["Morning", "Afternoon", "Evening", "Night"]
const PERIOD_COLORS := [
	Color("#FFECD2"),  # Morning - Soft peach
	Color("#FFF8E7"),  # Afternoon - Soft ivory
	Color("#FFB5A7"),  # Evening - Soft coral pink
	Color("#B8C5D6")   # Night - Soft periwinkle
]

# Speed options
const SPEED_VALUES := [0.1, 0.25, 0.5, 1.0, 2.0, 4.0]
const SPEED_LABELS := ["⅒x", "¼x", "½x", "1x", "2x", "4x"]

@export var day_night_cycle_path: NodePath

var _day_night: DayNightCycle = null
var _speed_index: int = 3  # Default to 1x

# UI elements specific to this widget
var _container: PanelContainer
var _main_vbox: VBoxContainer
var _collapsed_row: HBoxContainer
var _icon_label: Label
var _time_label: Label
var _period_label: Label
var _progress_bar: ProgressBar
var _period_buttons: Array[Button] = []
var _pause_btn: Button
var _speed_label: Label
var _collapsed_speed_label: Label


func _ready() -> void:
	_expand_keybind = KEY_V
	super._ready()
	call_deferred("_connect_day_night")


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


func _build_ui() -> void:
	# Main container
	_container = PanelContainer.new()
	_container.custom_minimum_size = Vector2(_s(220), 0)
	_container.add_theme_stylebox_override("panel", _create_panel_style())
	add_child(_container)
	
	# Main VBox
	_main_vbox = VBoxContainer.new()
	_main_vbox.add_theme_constant_override("separation", _s(10))
	_container.add_child(_main_vbox)
	
	# === COLLAPSED ROW ===
	_collapsed_row = HBoxContainer.new()
	_collapsed_row.add_theme_constant_override("separation", _s(12))
	_main_vbox.add_child(_collapsed_row)
	
	# Icon (sun/moon emoji)
	_icon_label = _create_label("☀", 28)
	_icon_label.custom_minimum_size = Vector2(_s(36), 0)
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_collapsed_row.add_child(_icon_label)
	
	# Time + Period info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", _s(4))
	_collapsed_row.add_child(info_vbox)
	
	# Time row (time + speed/ratio stack)
	var time_row = HBoxContainer.new()
	time_row.add_theme_constant_override("separation", _s(8))
	info_vbox.add_child(time_row)
	
	# Time label
	_time_label = _create_label("08:00", 24)
	time_row.add_child(_time_label)
	
	# Speed + Ratio stacked
	var speed_ratio_vbox = VBoxContainer.new()
	speed_ratio_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_ratio_vbox.add_theme_constant_override("separation", 0)
	time_row.add_child(speed_ratio_vbox)
	
	# Speed indicator
	_collapsed_speed_label = _create_label("1x", 12, MUTED_COLOR)
	_collapsed_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speed_ratio_vbox.add_child(_collapsed_speed_label)
	
	# Time ratio
	var ratio_label = _create_label("10m=24h", 10, Color(0.4, 0.4, 0.45))
	ratio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speed_ratio_vbox.add_child(ratio_label)
	
	# Period name
	_period_label = _create_label("Morning", 14, SUBTITLE_COLOR)
	info_vbox.add_child(_period_label)
	
	# Progress bar
	_progress_bar = _create_progress_bar(_s(140), _s(6))
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(_progress_bar)
	
	# Expand button
	_collapsed_row.add_child(_create_expand_button())
	
	# === EXPANDED BOX ===
	_expanded_box = VBoxContainer.new()
	_expanded_box.add_theme_constant_override("separation", _s(12))
	_expanded_box.visible = false
	_main_vbox.add_child(_expanded_box)
	
	_expanded_box.add_child(HSeparator.new())
	
	# Period buttons
	_expanded_box.add_child(_create_label("Jump to period:", 12, Color(0.6, 0.6, 0.65)))
	
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", _s(8))
	_expanded_box.add_child(btn_row)
	
	for i in range(4):
		var btn = _create_button(PERIOD_ICONS[i], _on_period_button_pressed.bind(i), 20)
		btn.tooltip_text = PERIOD_NAMES[i]
		btn.custom_minimum_size = Vector2(_s(48), _s(40))
		btn_row.add_child(btn)
		_period_buttons.append(btn)
	
	_expanded_box.add_child(HSeparator.new())
	
	# Controls row
	var controls_row = HBoxContainer.new()
	controls_row.add_theme_constant_override("separation", _s(12))
	_expanded_box.add_child(controls_row)
	
	# Pause button
	_pause_btn = _create_button("⏸ Pause", _on_pause_pressed, 14)
	_pause_btn.custom_minimum_size = Vector2(_s(90), _s(36))
	controls_row.add_child(_pause_btn)
	
	# Speed controls
	var speed_box = HBoxContainer.new()
	speed_box.add_theme_constant_override("separation", _s(6))
	controls_row.add_child(speed_box)
	
	_speed_label = _create_label("1x", 14)
	_speed_label.custom_minimum_size = Vector2(_s(36), 0)
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_box.add_child(_speed_label)
	
	var speed_up = _create_button("▲", _on_speed_up, 12)
	speed_up.custom_minimum_size = Vector2(_s(32), _s(36))
	speed_box.add_child(speed_up)
	
	var speed_down = _create_button("▼", _on_speed_down, 12)
	speed_down.custom_minimum_size = Vector2(_s(32), _s(36))
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
			_collapsed_speed_label.text = SPEED_LABELS[_speed_index]
		else:
			_day_night.pause()
			_pause_btn.text = "▶ Play"
			_collapsed_speed_label.text = "⏸"


func _on_speed_up() -> void:
	_speed_index = mini(_speed_index + 1, SPEED_VALUES.size() - 1)
	_apply_speed()


func _on_speed_down() -> void:
	_speed_index = maxi(_speed_index - 1, 0)
	_apply_speed()


func _apply_speed() -> void:
	var label = SPEED_LABELS[_speed_index]
	_speed_label.text = label
	_collapsed_speed_label.text = label
	Engine.time_scale = SPEED_VALUES[_speed_index]


func _on_period_changed(_new_period: String, _old_period: String) -> void:
	_update_display()


func _on_time_updated(normalized: float) -> void:
	var period_progress = fmod(normalized * 4.0, 1.0)
	_progress_bar.value = period_progress
	
	# Update time label using DayNightCycle's time string
	if _day_night:
		_time_label.text = _day_night.get_game_time_string()


func _update_display() -> void:
	if not _day_night:
		return
	
	var period_name = _day_night.get_current_period()
	var period_index = PERIOD_NAMES.find(period_name)
	if period_index < 0:
		period_index = 0
	
	var color = PERIOD_COLORS[period_index]
	
	_icon_label.text = PERIOD_ICONS[period_index]
	_time_label.text = _day_night.get_game_time_string()
	_time_label.add_theme_color_override("font_color", color)
	_period_label.text = period_name
	
	# Update progress bar
	var normalized = _day_night.get_normalized_time()
	_progress_bar.value = fmod(normalized * 4.0, 1.0)
	
	var fill = _progress_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	fill.bg_color = color
	_progress_bar.add_theme_stylebox_override("fill", fill)
	
	for i in range(_period_buttons.size()):
		_period_buttons[i].modulate = color if i == period_index else Color.WHITE
