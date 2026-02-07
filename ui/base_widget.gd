class_name BaseWidget
extends Control
## Base class for game UI widgets with shared styling and expand/collapse.
## Uses UIUtils for shared constants and helpers.

# Backward-compatible aliases for subclasses (delegate to UIUtils)
const PANEL_BG_COLOR := UIUtils.PANEL_BG_COLOR
const PANEL_BORDER_COLOR := UIUtils.PANEL_BORDER_COLOR
const TEXT_COLOR := UIUtils.TEXT_COLOR
const SUBTITLE_COLOR := UIUtils.SUBTITLE_COLOR
const MUTED_COLOR := UIUtils.MUTED_COLOR

# Expand/collapse state
var _expanded: bool = false
var _expand_btn: Button
var _expanded_box: Container
var _expand_keybind: Key = KEY_NONE

# Font (loaded once via UIUtils, cached for subclass convenience)
var _font: Font


func _ready() -> void:
	_font = UIUtils.get_font()
	# Don't catch mouse events on the widget container itself - let them pass
	# through to actual UI elements (panels, buttons) or the 3D scene.
	# This fixes web builds where Control defaults blocking all clicks.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = true
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
func _create_panel_style(corner_radius: int = 10, padding: int = 10) -> StyleBoxFlat:
	return UIUtils.create_panel_style(corner_radius, padding)


## Create a flat expand/collapse button
func _create_expand_button() -> Button:
	var btn := Button.new()
	btn.text = "▼"
	btn.flat = true
	UIUtils.style_button(btn, 14)
	btn.add_theme_color_override("font_color", UIUtils.TEXT_COLOR)
	btn.custom_minimum_size = Vector2(_s(32), _s(32))
	btn.pressed.connect(_toggle_expanded)
	_expand_btn = btn
	return btn


## Create a standard label with font
func _create_label(text: String, font_size: int = 14, color: Color = UIUtils.TEXT_COLOR) -> Label:
	var label := Label.new()
	label.text = text
	UIUtils.style_label(label, font_size, color)
	return label


## Create a button that releases focus after press
func _create_button(text: String, callback: Callable, font_size: int = 14) -> Button:
	var btn := Button.new()
	btn.text = text
	UIUtils.style_button(btn, font_size)
	btn.pressed.connect(func():
		callback.call()
		get_viewport().gui_release_focus()
	)
	return btn


## Scale value by display scale (delegates to UIUtils)
func _s(val: int) -> int:
	return UIUtils.scale(val)
