class_name GameNotification
extends Control
## General-purpose notification system - uses UIUtils for shared styling.
## Supports stacking multiple notifications, same type replaces existing.
## Singleton pattern - access via GameNotification.get_instance()

static var _instance: GameNotification = null

# UI elements
var _container: VBoxContainer  # Stacks notifications vertically

# Track active notifications by type
var _active_notifs: Dictionary = {}  # type -> {panel, tween}

var _load_happened: bool = false  # Skip startup TOD if save was loaded
var _suppress_external_tod: bool = true  # Start suppressed, enable after startup/load

# Preset notification types
const PRESETS := {
	"save": {"icon": "💾", "color": Color(0.6, 0.85, 0.6), "text": "Game Saved", "duration": 4.0},
	"load": {"icon": "📂", "color": Color(0.6, 0.75, 0.9), "text": "Game Loaded", "duration": 4.0},
	"reset": {"icon": "🔄", "color": Color(0.95, 0.75, 0.5), "text": "Simulation Reset", "duration": 4.0},
	"morning": {"icon": "🌅", "color": Color(1.0, 0.85, 0.4), "text": "Morning", "duration": 4.0, "group": "tod"},
	"afternoon": {"icon": "☀️", "color": Color(1.0, 0.95, 0.6), "text": "Afternoon", "duration": 4.0, "group": "tod"},
	"evening": {"icon": "🌆", "color": Color(1.0, 0.6, 0.4), "text": "Evening", "duration": 4.0, "group": "tod"},
	"night": {"icon": "🌙", "color": Color(0.6, 0.75, 0.95), "text": "Night", "duration": 4.0, "group": "tod"},
	"info": {"icon": "ℹ", "color": Color(0.7, 0.8, 0.9), "duration": 2.0},
	"warning": {"icon": "⚠", "color": Color(0.95, 0.8, 0.4), "duration": 3.0},
	"error": {"icon": "✕", "color": Color(0.9, 0.5, 0.5), "duration": 4.0},
}

const FADE_DURATION := 0.4
const NOTIF_SPACING := 8


static func get_instance() -> GameNotification:
	return _instance


func _ready() -> void:
	_instance = self
	_build_ui()
	call_deferred("_connect_systems")
	call_deferred("_show_startup_tod")


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.name = "CenterContainer"
	add_child(center)
	
	_container = VBoxContainer.new()
	_container.add_theme_constant_override("separation", UIUtils.scale(NOTIF_SPACING))
	_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	center.add_child(_container)


func _process(_delta: float) -> void:
	var center := get_node_or_null("CenterContainer")
	if center:
		var viewport_size := get_viewport_rect().size
		if viewport_size.x > 0:
			center.position = Vector2(0, UIUtils.scale(10))
			center.size = Vector2(viewport_size.x, UIUtils.scale(50))


func _connect_systems() -> void:
	var save_manager := SimulationSaveManager.get_instance()
	if save_manager:
		save_manager.save_completed.connect(_on_save_completed)
		save_manager.load_completed.connect(_on_load_completed)


func _show_startup_tod() -> void:
	await get_tree().create_timer(0.5).timeout
	
	if _load_happened:
		_suppress_external_tod = false
		return
	
	var day_night := UIUtils.find_day_night_cycle(get_tree())
	if day_night:
		var period := day_night.get_current_period()
		var preset_key := period.to_lower()
		if PRESETS.has(preset_key):
			var data: Dictionary = PRESETS[preset_key]
			var notif_type: String = data.get("group", preset_key)
			_show(data.get("text", period), data["icon"], data["color"], data.get("duration", 3.0), notif_type)
	
	_suppress_external_tod = false


func _on_save_completed(_slot: String) -> void:
	notify("", "save")


func _on_load_completed(_slot: String) -> void:
	_load_happened = true
	_suppress_external_tod = true
	notify("", "load")
	call_deferred("_queue_current_tod")


func _queue_current_tod() -> void:
	var day_night := UIUtils.find_day_night_cycle(get_tree())
	if day_night:
		var period := day_night.get_current_period()
		var preset_key := period.to_lower()
		if PRESETS.has(preset_key):
			var data: Dictionary = PRESETS[preset_key]
			var notif_type: String = data.get("group", preset_key)
			_show(data.get("text", period), data["icon"], data["color"], data.get("duration", 3.0), notif_type)
	_suppress_external_tod = false


## Show a notification with preset type
func notify(text: String, preset: String = "info") -> void:
	var data: Dictionary = PRESETS.get(preset, PRESETS["info"])
	var display_text: String = text if not text.is_empty() else str(data.get("text", preset.capitalize()))
	var duration: float = data.get("duration", 2.0)
	var notif_type: String = str(data.get("group", preset))
	_show(display_text, str(data["icon"]), data["color"], duration, notif_type)


## Backwards compatible - called by DayNightCycle signal
func show_notification(period_name: String, _old_period: String = "") -> void:
	if _suppress_external_tod:
		return
	
	var preset_key := period_name.to_lower()
	if PRESETS.has(preset_key):
		var data: Dictionary = PRESETS[preset_key]
		var notif_type: String = str(data.get("group", preset_key))
		_show(str(data.get("text", period_name)), str(data["icon"]), data["color"], data.get("duration", 3.0), notif_type)
	else:
		_show(period_name, "•", UIUtils.TEXT_COLOR, 2.0, "custom_" + period_name)


func _show(text: String, icon_text: String, color: Color, duration: float = 2.0, type: String = "custom") -> void:
	if _active_notifs.has(type):
		var existing: Dictionary = _active_notifs[type]
		if existing.tween:
			existing.tween.kill()
		_update_panel(existing.panel, text, icon_text, color)
		_animate_panel(existing.panel, duration, type)
		return
	
	var panel := _create_notif_panel(text, icon_text, color)
	_container.add_child(panel)
	_active_notifs[type] = {"panel": panel, "tween": null}
	_animate_panel(panel, duration, type)


func _create_notif_panel(text: String, icon_text: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIUtils.create_minimal_panel_style())
	panel.modulate.a = 0.0
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", UIUtils.scale(5))
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)
	
	var icon_label := Label.new()
	icon_label.name = "Icon"
	icon_label.text = icon_text
	UIUtils.style_label(icon_label, 11, color)
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.custom_minimum_size = Vector2(UIUtils.scale(14), UIUtils.scale(14))
	hbox.add_child(icon_label)
	
	var text_label := Label.new()
	text_label.name = "Text"
	text_label.text = text
	UIUtils.style_label(text_label, 11, UIUtils.TEXT_COLOR)
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(text_label)
	
	return panel


func _update_panel(panel: PanelContainer, text: String, icon_text: String, color: Color) -> void:
	var hbox := panel.get_child(0) as HBoxContainer
	if not hbox:
		return
	
	var icon_label := hbox.get_node_or_null("Icon") as Label
	var text_label := hbox.get_node_or_null("Text") as Label
	
	if icon_label:
		icon_label.text = icon_text
		icon_label.add_theme_color_override("font_color", color)
	if text_label:
		text_label.text = text


func _animate_panel(panel: PanelContainer, duration: float, type: String) -> void:
	var tween := create_tween()
	_active_notifs[type].tween = tween
	
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_interval(duration)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(_remove_notif.bind(type))


func _remove_notif(type: String) -> void:
	if not _active_notifs.has(type):
		return
	
	var data: Dictionary = _active_notifs[type]
	if is_instance_valid(data.panel):
		data.panel.queue_free()
	_active_notifs.erase(type)
