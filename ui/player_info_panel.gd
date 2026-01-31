class_name PlayerInfoPanel
extends BaseWidget
## Player (Rascal) info panel - always visible at bottom left.
## Matches NPC info panel style exactly.

const PLAYER_NAME: String = "Rascal"
const PLAYER_TITLE: String = "The Sneaky Raccoon"

var _container: PanelContainer
var _portrait_container: PanelContainer
var _portrait: TextureRect
var _name_label: Label
var _title_label: Label
var _state_label: Label
var _current_state: String = "exploring"


func _ready() -> void:
	super._ready()
	# Show immediately
	visible = true
	modulate.a = 1.0


func _build_ui() -> void:
	# Position at bottom-left
	anchor_left = 0.0
	anchor_top = 1.0
	anchor_right = 0.0
	anchor_bottom = 1.0
	offset_left = _s(10)
	offset_top = -_s(110)
	offset_right = _s(310)
	offset_bottom = -_s(20)
	
	# Main container - same width as NPC panel
	_container = PanelContainer.new()
	_container.custom_minimum_size = Vector2(_s(300), 0)
	_container.add_theme_stylebox_override("panel", _create_panel_style())
	add_child(_container)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", _s(8))
	_container.add_child(main_vbox)
	
	# === TOP ROW: Portrait + Name/Title ===
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", _s(12))
	main_vbox.add_child(top_row)
	
	# Portrait with rounded corners - same size as NPC
	_portrait_container = PanelContainer.new()
	_portrait_container.custom_minimum_size = Vector2(_s(70), _s(70))
	_portrait_container.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var portrait_style = StyleBoxFlat.new()
	portrait_style.bg_color = Color(1, 1, 1, 1)
	portrait_style.set_corner_radius_all(_s(10))
	_portrait_container.add_theme_stylebox_override("panel", portrait_style)
	top_row.add_child(_portrait_container)
	
	_portrait = TextureRect.new()
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var portrait_tex = load("res://assets/portraits/rascal_portrait.png")
	if portrait_tex:
		_portrait.texture = portrait_tex
	_portrait_container.add_child(_portrait)
	
	# Name/Title column
	var header_vbox = VBoxContainer.new()
	header_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_vbox.add_theme_constant_override("separation", _s(4))
	top_row.add_child(header_vbox)
	
	# Name row (no expand button for player)
	_name_label = _create_label(PLAYER_NAME, 22)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_vbox.add_child(_name_label)
	
	# Title
	_title_label = _create_label(PLAYER_TITLE, 14, SUBTITLE_COLOR)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	header_vbox.add_child(_title_label)
	
	# State row (emoji + state text together like NPC panel)
	_state_label = _create_label("🦝 Exploring", 14)
	_state_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_vbox.add_child(_state_label)


func set_state(state: String) -> void:
	_current_state = state
	var emoji = NPCUIUtils.get_status_emoji(state)
	var color = NPCUIUtils.get_status_color(state)
	_state_label.text = "%s %s" % [emoji, state.capitalize()]
	_state_label.add_theme_color_override("font_color", color)
