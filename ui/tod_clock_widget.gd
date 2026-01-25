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
var _row: HBoxContainer
var _icon_label: Label
var _time_label: Label
var _period_buttons: Array[Button] = []
var _pause_btn: Button
var _speed_label: Label


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
	# Sleek single-row container
	_container = PanelContainer.new()
	var style = _create_panel_style(6, 6)
	style.content_margin_left = _s(10)  # Extra left padding
	_container.add_theme_stylebox_override("panel", style)
	add_child(_container)
	
	# Main VBox for collapsed + expanded
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", _s(6))
	_container.add_child(main_vbox)
	
	# === COLLAPSED: Single compact row ===
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", _s(6))
	main_vbox.add_child(_row)
	
	# Icon
	_icon_label = _create_label("☀", 14)
	_row.add_child(_icon_label)
	
	# Time label (bigger)
	_time_label = _create_label("8:00 AM", 16)
	_row.add_child(_time_label)
	
	# Expand button (smaller)
	var expand_btn = _create_expand_button()
	expand_btn.custom_minimum_size = Vector2(_s(20), _s(20))
	_row.add_child(expand_btn)
	
	# === EXPANDED BOX ===
	_expanded_box = HBoxContainer.new()
	_expanded_box.add_theme_constant_override("separation", _s(4))
	_expanded_box.visible = false
	main_vbox.add_child(_expanded_box)
	
	# Period buttons
	for i in range(4):
		var btn = _create_button(PERIOD_ICONS[i], _on_period_button_pressed.bind(i), 12)
		btn.tooltip_text = PERIOD_NAMES[i]
		btn.custom_minimum_size = Vector2(_s(24), _s(20))
		_expanded_box.add_child(btn)
		_period_buttons.append(btn)
	
	# Pause button
	_pause_btn = _create_button("⏸", _on_pause_pressed, 10)
	_pause_btn.custom_minimum_size = Vector2(_s(22), _s(20))
	_expanded_box.add_child(_pause_btn)
	
	# Speed controls
	_speed_label = _create_label("1x", 10)
	_expanded_box.add_child(_speed_label)
	
	var speed_up = _create_button("+", _on_speed_up, 10)
	speed_up.custom_minimum_size = Vector2(_s(18), _s(20))
	_expanded_box.add_child(speed_up)
	
	var speed_down = _create_button("-", _on_speed_down, 10)
	speed_down.custom_minimum_size = Vector2(_s(18), _s(20))
	_expanded_box.add_child(speed_down)



func _on_period_button_pressed(index: int) -> void:
	if _day_night:
		_day_night.set_period(index as DayNightCycle.TimePeriod, false)
	period_selected.emit(index)


func _on_pause_pressed() -> void:
	if _day_night:
		if _day_night.is_paused():
			_day_night.resume()
			_pause_btn.text = "⏸"
		else:
			_day_night.pause()
			_pause_btn.text = "▶"


func _on_speed_up() -> void:
	_speed_index = mini(_speed_index + 1, SPEED_VALUES.size() - 1)
	_apply_speed()


func _on_speed_down() -> void:
	_speed_index = maxi(_speed_index - 1, 0)
	_apply_speed()


func _apply_speed() -> void:
	_speed_label.text = SPEED_LABELS[_speed_index]
	Engine.time_scale = SPEED_VALUES[_speed_index]


func _on_period_changed(_new_period: String, _old_period: String) -> void:
	_update_display()


func _on_time_updated(_normalized: float) -> void:
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
	
	for i in range(_period_buttons.size()):
		_period_buttons[i].modulate = color if i == period_index else Color.WHITE
