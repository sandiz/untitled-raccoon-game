class_name GameNotification
extends Control
## General-purpose notification system - follows BaseWidget style.
## Shows brief text with icon and fade animation.
## Singleton pattern - access via GameNotification.get_instance()

static var _instance: GameNotification = null

# Style constants (matching BaseWidget)
const PANEL_BG_COLOR := Color(0.06, 0.06, 0.08, 0.92)
const PANEL_BORDER_COLOR := Color(0.25, 0.25, 0.3, 0.9)
const TEXT_COLOR := Color(0.95, 0.95, 0.9)

# UI elements
var _panel: PanelContainer
var _icon_label: Label
var _text_label: Label
var _font: Font
var _editor_scale: float = 1.0

var _tween: Tween
var _queue: Array[Dictionary] = []
var _is_showing: bool = false

# Preset notification types
const PRESETS := {
	"save": {"icon": "💾", "color": Color(0.6, 0.85, 0.6), "text": "Game Saved", "duration": 4.0},
	"load": {"icon": "📂", "color": Color(0.6, 0.75, 0.9), "text": "Game Loaded", "duration": 4.0},
	"reset": {"icon": "🔄", "color": Color(0.95, 0.75, 0.5), "text": "Simulation Reset", "duration": 4.0},
	"morning": {"icon": "🌅", "color": Color(1.0, 0.85, 0.4), "text": "Morning", "duration": 4.0},
	"afternoon": {"icon": "☀️", "color": Color(1.0, 0.95, 0.6), "text": "Afternoon", "duration": 4.0},
	"evening": {"icon": "🌆", "color": Color(1.0, 0.6, 0.4), "text": "Evening", "duration": 4.0},
	"night": {"icon": "🌙", "color": Color(0.6, 0.75, 0.95), "text": "Night", "duration": 4.0},
	"info": {"icon": "ℹ", "color": Color(0.7, 0.8, 0.9), "duration": 2.0},
	"warning": {"icon": "⚠", "color": Color(0.95, 0.8, 0.4), "duration": 3.0},
	"error": {"icon": "✕", "color": Color(0.9, 0.5, 0.5), "duration": 4.0},
}

const FADE_DURATION := 0.4


static func get_instance() -> GameNotification:
	return _instance


func _ready() -> void:
	_instance = self
	_editor_scale = _get_editor_scale()
	_font = load("res://assets/fonts/JetBrainsMono.ttf")
	_build_ui()
	
	# Start hidden
	_panel.modulate.a = 0.0
	_panel.visible = false
	
	# Connect to systems
	call_deferred("_connect_systems")
	call_deferred("_show_startup_tod")


## Scale value by editor scale
func _s(val: int) -> int:
	return int(val * _editor_scale)


## Get editor scale factor
func _get_editor_scale() -> float:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_scale()
	return 2.0  # Runtime default


func _build_ui() -> void:
	# Panel container with dark style - aligned to right
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _create_panel_style())
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_panel)
	
	# Content row
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", _s(10))
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(hbox)
	
	# Icon - use same font size as text for alignment
	_icon_label = Label.new()
	_icon_label.add_theme_font_override("font", _font)
	_icon_label.add_theme_font_size_override("font_size", _s(18))
	_icon_label.add_theme_color_override("font_color", TEXT_COLOR)
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.custom_minimum_size = Vector2(_s(24), _s(24))
	hbox.add_child(_icon_label)
	
	# Text
	_text_label = Label.new()
	_text_label.add_theme_font_override("font", _font)
	_text_label.add_theme_font_size_override("font_size", _s(18))
	_text_label.add_theme_color_override("font_color", TEXT_COLOR)
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_text_label)


func _create_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = PANEL_BG_COLOR
	style.set_border_width_all(2)
	style.border_color = PANEL_BORDER_COLOR
	style.set_corner_radius_all(_s(6))
	style.set_content_margin_all(_s(10))
	style.content_margin_left = _s(14)
	style.content_margin_right = _s(14)
	return style


func _connect_systems() -> void:
	var save_manager = SimulationSaveManager.get_instance()
	if save_manager:
		save_manager.save_completed.connect(_on_save_completed)
		save_manager.load_completed.connect(_on_load_completed)


func _show_startup_tod() -> void:
	await get_tree().create_timer(0.5).timeout
	
	var day_night = get_tree().get_first_node_in_group("day_night_cycle") as DayNightCycle
	if day_night:
		var period = day_night.get_current_period()
		show_notification(period, "")


func _on_save_completed(_slot: String) -> void:
	notify("", "save")


func _on_load_completed(_slot: String) -> void:
	notify("", "load")


## Show a notification with preset type
func notify(text: String, preset: String = "info") -> void:
	var data = PRESETS.get(preset, PRESETS["info"])
	var display_text = text if not text.is_empty() else data.get("text", preset.capitalize())
	var duration = data.get("duration", 2.0)
	_show(display_text, data["icon"], data["color"], duration)


## Backwards compatible - called by DayNightCycle signal
func show_notification(period_name: String, _old_period: String = "") -> void:
	var preset_key = period_name.to_lower()
	if PRESETS.has(preset_key):
		var data = PRESETS[preset_key]
		var duration = data.get("duration", 3.0)
		var display_text = data.get("text", period_name)
		_show(display_text, data["icon"], data["color"], duration)
	else:
		_show(period_name, "•", TEXT_COLOR, 2.0)


func _show(text: String, icon_text: String, color: Color, duration: float = 2.0) -> void:
	var notif := {"text": text, "icon": icon_text, "color": color, "duration": duration}
	
	if _is_showing:
		_queue.append(notif)
		return
	
	_display(notif)


func _display(notif: Dictionary) -> void:
	if not _panel or not _text_label or not _icon_label:
		return
	
	_is_showing = true
	
	if _tween:
		_tween.kill()
	
	# Set content
	_text_label.text = notif["text"]
	_icon_label.text = notif["icon"]
	
	# Apply color to icon only (text stays white for readability)
	_icon_label.add_theme_color_override("font_color", notif["color"])
	
	_panel.visible = true
	
	var duration: float = notif.get("duration", 2.0)
	
	# Animate - slide up from bottom
	_panel.position.y = _s(30)
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BACK)
	
	# Slide up + fade in
	_tween.set_parallel(true)
	_tween.tween_property(_panel, "modulate:a", 1.0, FADE_DURATION)
	_tween.tween_property(_panel, "position:y", 0.0, FADE_DURATION)
	
	_tween.set_parallel(false)
	
	# Hold
	_tween.tween_interval(duration)
	
	# Fade out
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(_panel, "modulate:a", 0.0, FADE_DURATION)
	
	# Done
	_tween.tween_callback(_on_display_complete)


func _on_display_complete() -> void:
	_is_showing = false
	_panel.visible = false
	
	if _queue.size() > 0:
		var next = _queue.pop_front()
		_display(next)
