class_name BaseWidget
extends Control
## Base class for game UI widgets with shared styling and expand/collapse.

# Style constants
const PANEL_BG_COLOR := Color(0.06, 0.06, 0.08, 0.92)
const PANEL_BORDER_COLOR := Color(0.25, 0.25, 0.3, 0.9)
const TEXT_COLOR := Color(0.95, 0.95, 0.9)
const SUBTITLE_COLOR := Color(0.7, 0.65, 0.6)
const MUTED_COLOR := Color(0.5, 0.5, 0.55)

# Expand/collapse state
var _expanded: bool = false
var _expand_btn: Button
var _expanded_box: Container
var _expand_keybind: Key = KEY_NONE

# Scaling
var _editor_scale: float = 1.0

# Font (loaded once)
var _font: Font


func _ready() -> void:
	_editor_scale = _get_editor_scale()
	_font = load("res://assets/fonts/JetBrainsMono.ttf")
	_build_ui()


func _input(event: InputEvent) -> void:
	if _expand_keybind != KEY_NONE and event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == _expand_keybind:
			_toggle_expanded()
			get_viewport().set_input_as_handled()


## Override in derived class to build the widget UI
func _build_ui() -> void:
	pass


## Toggle expand/collapse state
func _toggle_expanded() -> void:
	_expanded = not _expanded
	if _expanded_box:
		_expanded_box.visible = _expanded
	if _expand_btn:
		_expand_btn.text = "▲" if _expanded else "▼"
		_expand_btn.release_focus()


## Create the standard dark panel style
func _create_panel_style(corner_radius: int = 10, padding: int = 14) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = PANEL_BG_COLOR
	style.set_border_width_all(2)
	style.border_color = PANEL_BORDER_COLOR
	style.set_corner_radius_all(_s(corner_radius))
	style.set_content_margin_all(_s(padding))
	return style


## Create a flat expand/collapse button
func _create_expand_button() -> Button:
	var btn = Button.new()
	btn.text = "▼"
	btn.flat = true
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", _s(14))
	btn.add_theme_color_override("font_color", TEXT_COLOR)
	btn.custom_minimum_size = Vector2(_s(32), _s(32))
	btn.pressed.connect(_toggle_expanded)
	_expand_btn = btn
	return btn


## Create a standard label with font
func _create_label(text: String, font_size: int = 14, color: Color = TEXT_COLOR) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", _s(font_size))
	label.add_theme_color_override("font_color", color)
	return label


## Create a button that releases focus after press
func _create_button(text: String, callback: Callable, font_size: int = 14) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", _s(font_size))
	btn.pressed.connect(func():
		callback.call()
		get_viewport().gui_release_focus()
	)
	return btn


## Scale value by editor scale
func _s(val: int) -> int:
	return int(val * _editor_scale)


## Get editor scale factor
func _get_editor_scale() -> float:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_scale()
	return 2.0  # Runtime default
