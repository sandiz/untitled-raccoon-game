class_name PlayerInfoPanel
extends BaseWidget
## Player (Rascal) info panel - always visible at bottom left.
## Matches NPC info panel style exactly.

const PLAYER_NAME: String = "Rascal"
const PLAYER_TITLE: String = "The Sneaky Raccoon"

# FPS thresholds
const FPS_HIGH := 55  # Green
const FPS_MED := 30   # Yellow
# Below FPS_MED = Red

var _container: PanelContainer
var _portrait_container: PanelContainer
var _portrait: TextureRect
var _name_label: Label
var _title_label: Label
var _state_label: Label
var _fps_label: Label
var _current_state: String = "idle"


func _ready() -> void:
	super._ready()
	# Show immediately
	visible = true
	modulate.a = 1.0
	
	# Connect to player state changes
	call_deferred("_connect_to_player")


func _process(_delta: float) -> void:
	_update_fps()


func _connect_to_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("state_changed"):
		player.state_changed.connect(_on_player_state_changed)


func _on_player_state_changed(state: String) -> void:
	set_state(state)


func _update_fps() -> void:
	if not _fps_label:
		return
	
	var fps := int(Engine.get_frames_per_second())
	_fps_label.text = "%d FPS" % fps
	
	# Color based on performance
	var color: Color
	if fps >= FPS_HIGH:
		color = Color(0.3, 0.9, 0.3)  # Green
	elif fps >= FPS_MED:
		color = Color(0.95, 0.8, 0.2)  # Yellow
	else:
		color = Color(1.0, 0.3, 0.3)  # Red
	
	_fps_label.add_theme_color_override("font_color", color)


func _build_ui() -> void:
	# Position at bottom-left
	anchor_left = 0.0
	anchor_top = 1.0
	anchor_right = 0.0
	anchor_bottom = 1.0
	offset_left = _s(10)
	offset_top = -_s(130)  # Extra space for FPS label
	offset_right = _s(310)
	offset_bottom = -_s(20)
	
	# FPS label above the panel
	_fps_label = Label.new()
	_fps_label.text = "60 FPS"
	_fps_label.position.x = _s(8)  # Left padding to align with panel content
	_fps_label.add_theme_font_size_override("font_size", _s(14))
	_fps_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	_fps_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_fps_label.add_theme_constant_override("outline_size", _s(2))
	var font = load("res://assets/fonts/JetBrainsMono.ttf")
	if font:
		_fps_label.add_theme_font_override("font", font)
	add_child(_fps_label)
	
	# Main container - same width as NPC panel
	_container = PanelContainer.new()
	_container.position.y = _s(18)  # Below FPS label
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
	_state_label = _create_label("😌 Idle", 14)
	_state_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.3))
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_vbox.add_child(_state_label)


func set_state(state: String) -> void:
	_current_state = state
	var emoji = NPCUIUtils.get_status_emoji(state)
	var color = NPCUIUtils.get_status_color(state)
	_state_label.text = "%s %s" % [emoji, state.capitalize()]
	_state_label.add_theme_color_override("font_color", color)
