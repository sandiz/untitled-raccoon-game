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
var _progress_bar: ProgressBar
var _period_buttons: Array[Button] = []
var _pause_btn: Button
var _speed_label: Label

func _ready() -> void:
	_expand_keybind = KEY_V
	super._ready()
	call_deferred("_connect_day_night")
	call_deferred("_slide_in")


func _slide_in() -> void:
	# Slide in from right on startup
	modulate.a = 0.0
	_container.position.x = 50
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	tween.tween_property(_container, "position:x", 0.0, 0.3)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)



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
	# Container - sized to content
	_container = PanelContainer.new()
	var style = _create_panel_style(6, 6)
	style.content_margin_left = _s(10)
	style.content_margin_right = _s(16)
	_container.add_theme_stylebox_override("panel", style)
	add_child(_container)
	
	# Right-align within parent VBoxContainer
	size_flags_horizontal = Control.SIZE_SHRINK_END
	
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
	
	# Spacer to push expand button to right
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row.add_child(spacer)
	
	# Expand button (smaller) - fixed on right
	var expand_btn = _create_expand_button()
	expand_btn.custom_minimum_size = Vector2(_s(28), _s(20))
	_row.add_child(expand_btn)
	
	# === 24h PROGRESS BAR (clickable) ===
	_progress_bar = ProgressBar.new()
	_progress_bar.max_value = 1.0
	_progress_bar.value = 0.5
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, _s(8))
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_progress_bar.gui_input.connect(_on_progress_bar_input)
	
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.35, 0.35, 0.4)  # Muted gray
	fill.set_corner_radius_all(_s(4))
	_progress_bar.add_theme_stylebox_override("fill", fill)
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.12, 0.15)  # Dark subtle bg
	bg.set_corner_radius_all(_s(4))
	_progress_bar.add_theme_stylebox_override("background", bg)
	
	main_vbox.add_child(_progress_bar)
	
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


func _process(_delta: float) -> void:
	# Update our minimum size to match container for VBoxContainer parent
	if _container:
		var c_size = _container.get_combined_minimum_size()
		if c_size != custom_minimum_size:
			custom_minimum_size = c_size



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


func _on_time_updated(normalized: float) -> void:
	if _day_night:
		_time_label.text = _day_night.get_game_time_string()
		_progress_bar.value = normalized


func _on_progress_bar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Calculate normalized time from click position
		var click_x = event.position.x
		var bar_width = _progress_bar.size.x
		var normalized = clamp(click_x / bar_width, 0.0, 1.0)
		
		# Set the time
		if _day_night:
			_day_night.set_normalized_time(normalized)


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
	
	# Update progress bar
	var normalized = _day_night.get_normalized_time()
	_progress_bar.value = normalized
	
	for i in range(_period_buttons.size()):
		_period_buttons[i].modulate = color if i == period_index else Color.WHITE
