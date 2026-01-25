class_name NPCStateIndicator
extends Node3D
## Speech bubble using SubViewport for clean 2D rendering in 3D.
## Listens to NPCDataStore for state/dialogue updates.
## Supports message priority - high priority messages can't be replaced by lower ones.

# Message priority levels
enum Priority { LOW = 0, NORMAL = 1, HIGH = 2, CRITICAL = 3 }

# Minimum display times per priority (seconds)
const PRIORITY_MIN_TIMES := {
	Priority.LOW: 0.0,       # Can be replaced immediately
	Priority.NORMAL: 1.0,    # At least 1 second
	Priority.HIGH: 2.5,      # Important messages stay 2.5s
	Priority.CRITICAL: 4.0,  # Critical stays 4s
}

# State to priority mapping
const STATE_PRIORITIES := {
	"idle": Priority.LOW,
	"calm": Priority.LOW,
	"returning": Priority.LOW,
	"alert": Priority.NORMAL,
	"suspicious": Priority.NORMAL,
	"investigating": Priority.NORMAL,
	"searching": Priority.HIGH,
	"chasing": Priority.HIGH,
	"angry": Priority.HIGH,
	"tired": Priority.NORMAL,
	"frustrated": Priority.NORMAL,
	"gave_up": Priority.NORMAL,
	"caught": Priority.CRITICAL,
}

@export var npc_id: String = ""  # Set by shopkeeper to identify which NPC this belongs to
@export var height_offset: float = 3.3
@export var bob_amount: float = 0.05
@export var bob_speed: float = 2.0
@export var max_bubble_width: float = 1200.0
@export var max_chars_per_line: int = 28  # Slightly less to account for emoji
@export var min_lines: int = 1  # Shrink to fit content
@export var max_lines: int = 5
@export var typewriter_speed: float = 0.03  # Seconds per character

var _viewport: SubViewport
var _panel: PanelContainer
var _hbox: HBoxContainer
var _emoji_label: Label
var _label: Label
var _sprite: Sprite3D
var _tail: Polygon2D
var _tail_outline: Line2D
var _full_text: String = ""
var _typewriter_tween: Tween
var _popin_tween: Tween
var _scale: float = 5.0
var _time: float = 0.0

# Priority system
var _current_priority: int = Priority.LOW
var _message_time: float = 0.0  # How long current message has been shown
var _message_locked: bool = false  # True while min display time hasn't elapsed


var _data_store: NPCDataStore
var _is_selected: bool = false
var _pending_dialogue: Dictionary = {}  # Store dialogue to show when selected


func _ready() -> void:
	_scale = _get_editor_scale()
	_setup_viewport()
	_setup_sprite()
	_sprite.visible = false
	
	# Connect to data store for reactive updates
	_data_store = NPCDataStore.get_instance()
	_data_store.state_changed.connect(_on_state_changed)
	_data_store.selection_changed.connect(_on_selection_changed)


func _get_editor_scale() -> float:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_scale()
	return 5.0  # Runtime default - large for readability


func _s(val: int) -> int:
	return int(val * _scale)


func _setup_viewport() -> void:
	# Create SubViewport to render 2D UI
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.size = Vector2i(_s(600), _s(120))
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	
	# Container for panel + tail
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_viewport.add_child(container)
	
	# Create panel with styling
	_panel = PanelContainer.new()
	_panel.position = Vector2(0, 0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.13, 0.15, 1.0)  # Solid dark background
	style.border_color = Color(0.3, 0.32, 0.35, 1.0)
	# Border on all sides
	style.border_width_left = _s(2)
	style.border_width_right = _s(2)
	style.border_width_top = _s(2)
	style.border_width_bottom = _s(2)
	# Round all corners
	style.set_corner_radius_all(_s(10))
	# Padding on all sides
	style.content_margin_left = _s(14)
	style.content_margin_right = _s(14)
	style.content_margin_top = _s(12)
	style.content_margin_bottom = _s(12)
	_panel.add_theme_stylebox_override("panel", style)
	container.add_child(_panel)
	
	# Load font once for all labels
	var font = load("res://assets/fonts/JetBrainsMono.ttf")
	
	# HBox for icon + text
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", _s(4))
	_panel.add_child(_hbox)
	
	# Emoji indicator
	_emoji_label = Label.new()
	_emoji_label.text = "💬"
	_emoji_label.add_theme_font_size_override("font_size", _s(20))
	_emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_emoji_label.custom_minimum_size = Vector2(_s(28), 0)  # Fixed width to prevent layout shift
	_hbox.add_child(_emoji_label)
	
	# Create text label
	_label = Label.new()
	_label.text = "Hello!"
	if font:
		_label.add_theme_font_override("font", font)
	_label.add_theme_font_size_override("font_size", _s(18))
	_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.custom_minimum_size = Vector2(_s(150), 0)  # Min width only, height fits content
	_hbox.add_child(_label)
	
	# Create tail (triangle pointing down) - rendered ON TOP to cover bottom border
	var tail = Polygon2D.new()
	tail.color = Color(0.12, 0.13, 0.15, 1.0)  # Match panel bg
	tail.polygon = PackedVector2Array([
		Vector2(-_s(15), -_s(2)),  # Start slightly above to cover border
		Vector2(_s(15), -_s(2)),   # Start slightly above to cover border
		Vector2(0, _s(20))    # Point down
	])
	tail.z_index = 1  # Render on top to cover bottom border
	container.add_child(tail)
	
	# Tail outline (only the V shape, not the top)
	var tail_outline = Line2D.new()
	tail_outline.points = PackedVector2Array([
		Vector2(-_s(15), 0),
		Vector2(0, _s(20)),
		Vector2(_s(15), 0)
	])
	tail_outline.width = _s(2)
	tail_outline.default_color = Color(0.3, 0.32, 0.35, 1.0)  # Match panel border
	tail_outline.z_index = 2  # On top of tail fill
	container.add_child(tail_outline)
	
	# Store tail refs for positioning
	_tail = tail
	_tail_outline = tail_outline


func _setup_sprite() -> void:
	_sprite = Sprite3D.new()
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.no_depth_test = true
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sprite.pixel_size = 0.004
	_sprite.position = Vector3(0, height_offset, 0)
	add_child(_sprite)


func _process(delta: float) -> void:
	_time += delta
	
	# Track message display time for priority system
	if _sprite.visible and _message_locked:
		_message_time += delta
		var min_time = PRIORITY_MIN_TIMES.get(_current_priority, 0.0)
		if _message_time >= min_time:
			_message_locked = false
	
	# Update sprite texture from viewport
	if _viewport and _sprite:
		_sprite.texture = _viewport.get_texture()
	
	# Subtle bob animation
	if _sprite and _sprite.visible:
		var bob = sin(_time * bob_speed) * bob_amount
		_sprite.position.y = height_offset + bob


func show_dialogue(text: String, _duration: float = 3.0, state: String = "idle", priority: int = -1) -> void:
	if text.is_empty():
		hide_indicator()
		return
	
	# Determine priority from state if not explicitly provided
	var msg_priority = priority if priority >= 0 else STATE_PRIORITIES.get(state, Priority.NORMAL)
	
	# Check if current message is locked (min display time not elapsed)
	if _message_locked and msg_priority < _current_priority:
		# Can't replace - current message has higher priority and is still locked
		return
	
	# Same or lower priority can't replace if locked
	if _message_locked and msg_priority <= _current_priority:
		return
	
	# Stop any existing tweens
	if _typewriter_tween:
		_typewriter_tween.kill()
	if _popin_tween:
		_popin_tween.kill()
	
	# Set priority tracking
	_current_priority = msg_priority
	_message_time = 0.0
	_message_locked = PRIORITY_MIN_TIMES.get(msg_priority, 0.0) > 0.0
	
	# Status-based emoji (from shared utility)
	_emoji_label.text = NPCUIUtils.get_status_emoji(state)
	
	# Strip quotes if present
	var display_text = text.trim_prefix("\"").trim_suffix("\"")
	
	# Insert newlines after max_chars_per_line
	_full_text = _wrap_text(display_text, max_chars_per_line)
	_label.text = _full_text  # Set full text first for sizing
	
	# Resize viewport to fit text
	await get_tree().process_frame
	_resize_to_fit()
	
	_sprite.visible = true
	
	# Pop-in animation
	_sprite.scale = Vector3.ZERO
	_popin_tween = create_tween()
	_popin_tween.tween_property(_sprite, "scale", Vector3.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Start typewriter effect after pop-in
	_label.text = ""
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_interval(0.15)  # Wait for pop-in to start
	var char_count = _full_text.length()
	
	for i in range(char_count):
		_typewriter_tween.tween_callback(_add_char.bind(i))
		_typewriter_tween.tween_interval(typewriter_speed)


func _add_char(index: int) -> void:
	_label.text = _full_text.substr(0, index + 1)


func _wrap_text(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	
	var result = ""
	var words = text.split(" ")
	var line = ""
	
	for word in words:
		if line.length() + word.length() + 1 <= max_chars:
			if line.length() > 0:
				line += " "
			line += word
		else:
			if result.length() > 0:
				result += "\n"
			result += line
			line = word
	
	if line.length() > 0:
		if result.length() > 0:
			result += "\n"
		result += line
	
	return result


func _resize_to_fit() -> void:
	var min_size = _panel.get_combined_minimum_size()
	var tail_height = _s(20)
	
	# Position tail at panel bottom (tail renders behind, no overlap needed)
	var tail_x = min_size.x / 2
	var tail_y = min_size.y  # Exactly at panel bottom edge
	_tail.position = Vector2(tail_x, tail_y)
	_tail_outline.position = Vector2(tail_x, tail_y)
	
	_viewport.size = Vector2i(int(min_size.x) + _s(4), int(min_size.y) + tail_height)
	_panel.size = min_size


func hide_indicator() -> void:
	_sprite.visible = false
	_current_priority = Priority.LOW
	_message_locked = false
	_message_time = 0.0


func _on_state_changed(changed_npc_id: String, data: Dictionary) -> void:
	# Only respond to our NPC's updates
	if npc_id.is_empty() or changed_npc_id != npc_id:
		return
	
	var state = data.get("state", "idle")
	var dialogue = data.get("dialogue", "")
	
	# Store dialogue for when selected
	_pending_dialogue = {"state": state, "dialogue": dialogue}
	
	# Only show if selected
	if not _is_selected:
		return
	
	if not dialogue.is_empty():
		show_dialogue(dialogue, 0.0, state)


func _on_selection_changed(selected_ids: Array) -> void:
	var was_selected = _is_selected
	_is_selected = npc_id in selected_ids
	
	if _is_selected and not was_selected:
		# Just got selected - show pending dialogue if any
		if not _pending_dialogue.is_empty():
			var state = _pending_dialogue.get("state", "idle")
			var dialogue = _pending_dialogue.get("dialogue", "")
			if not dialogue.is_empty():
				show_dialogue(dialogue, 0.0, state)
	elif not _is_selected and was_selected:
		# Got deselected - hide indicator
		hide_indicator()
