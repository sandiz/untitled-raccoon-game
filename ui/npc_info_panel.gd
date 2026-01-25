class_name NPCInfoPanel
extends Control
## Wildlife documentary style info panel for NPCs.
## Built programmatically with editor scale support.

@export var panel_color: Color = Color(0.06, 0.06, 0.08, 0.92)
@export var border_color: Color = Color(0.25, 0.25, 0.3, 0.9)
@export var text_color: Color = Color(0.95, 0.95, 0.9)
@export var subtitle_color: Color = Color(0.7, 0.65, 0.6)

var _current_npc: Node3D = null
var _tween: Tween
var _last_state: String = ""
var _editor_scale: float = 1.0
var _expanded: bool = true

# UI Elements (built in _ready)
var _container: PanelContainer
var _portrait_container: PanelContainer
var _portrait: TextureRect
var _name_label: Label
var _title_label: Label
var _narrator_label: RichTextLabel
var _dialogue_label: RichTextLabel
var _state_label: Label
var _stats_box: VBoxContainer
var _expanded_box: VBoxContainer
var _expand_btn: Button

# Stat bars
var _alertness_bar: ProgressBar
var _annoyance_bar: ProgressBar
var _exhaustion_bar: ProgressBar
var _suspicion_bar: ProgressBar


func _ready() -> void:
	_editor_scale = _get_editor_scale()
	_build_ui()
	visible = false
	modulate.a = 0.0


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_N:
			_toggle_expanded()
			get_viewport().set_input_as_handled()


func _get_editor_scale() -> float:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_scale()
	return 2.0


func _s(val: int) -> int:
	return int(val * _editor_scale)


func _toggle_expanded() -> void:
	_expanded = not _expanded
	_expanded_box.visible = _expanded
	_expand_btn.text = "▲" if _expanded else "▼"


func _build_ui() -> void:
	var font = load("res://assets/fonts/JetBrainsMono.ttf")
	
	# Main container
	_container = PanelContainer.new()
	_container.custom_minimum_size = Vector2(_s(300), 0)
	add_child(_container)
	
	# Panel style - dark translucent (matches TOD widget)
	var style = StyleBoxFlat.new()
	style.bg_color = panel_color
	style.set_border_width_all(2)
	style.border_color = border_color
	style.set_corner_radius_all(_s(10))
	style.set_content_margin_all(_s(16))
	_container.add_theme_stylebox_override("panel", style)
	
	# Main VBox
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", _s(12))
	_container.add_child(main_vbox)
	
	# === TOP ROW: Portrait + Name/Title ===
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", _s(16))
	main_vbox.add_child(top_row)
	
	# Portrait with rounded corners (wrap in clipping container)
	var portrait_container = PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(_s(70), _s(70))
	portrait_container.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var portrait_style = StyleBoxFlat.new()
	portrait_style.bg_color = Color(1, 1, 1, 1)  # White opaque - image covers it, defines clip shape
	portrait_style.set_corner_radius_all(_s(10))
	portrait_container.add_theme_stylebox_override("panel", portrait_style)
	top_row.add_child(portrait_container)
	
	_portrait = TextureRect.new()
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_container.add_child(_portrait)
	
	_portrait_container = portrait_container
	_portrait_container.visible = false  # Hidden until we have a portrait
	
	# Name/Title column
	var header_vbox = VBoxContainer.new()
	header_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_vbox.add_theme_constant_override("separation", _s(4))
	top_row.add_child(header_vbox)
	
	# Name row with expand button
	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", _s(8))
	header_vbox.add_child(name_row)
	
	_name_label = Label.new()
	_name_label.add_theme_font_override("font", font)
	_name_label.add_theme_font_size_override("font_size", _s(22))
	_name_label.add_theme_color_override("font_color", text_color)
	_name_label.text = "Bernard"
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_name_label)
	
	# Expand/collapse button
	_expand_btn = Button.new()
	_expand_btn.text = "▲"
	_expand_btn.add_theme_font_override("font", font)
	_expand_btn.add_theme_font_size_override("font_size", _s(14))
	_expand_btn.custom_minimum_size = Vector2(_s(32), _s(28))
	_expand_btn.pressed.connect(_toggle_expanded)
	name_row.add_child(_expand_btn)
	
	# Title + State row (compact)
	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", _s(8))
	header_vbox.add_child(title_row)
	
	_title_label = Label.new()
	_title_label.add_theme_font_override("font", font)
	_title_label.add_theme_font_size_override("font_size", _s(14))
	_title_label.add_theme_color_override("font_color", subtitle_color)
	_title_label.text = "The Grumpy Shopkeeper"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	title_row.add_child(_title_label)
	
	# State label (always visible, in header)
	_state_label = Label.new()
	_state_label.add_theme_font_override("font", font)
	_state_label.add_theme_font_size_override("font_size", _s(14))
	_state_label.add_theme_color_override("font_color", text_color)
	_state_label.text = "● Idle"
	title_row.add_child(_state_label)
	
	# === EXPANDED CONTENT ===
	_expanded_box = VBoxContainer.new()
	_expanded_box.add_theme_constant_override("separation", _s(12))
	main_vbox.add_child(_expanded_box)
	
	# Separator
	_expanded_box.add_child(HSeparator.new())
	
	# === NARRATOR TEXT === (fixed height to prevent layout shift)
	_narrator_label = RichTextLabel.new()
	_narrator_label.bbcode_enabled = true
	_narrator_label.fit_content = false
	_narrator_label.scroll_active = false
	_narrator_label.custom_minimum_size = Vector2(0, _s(50))
	_narrator_label.clip_contents = true
	_narrator_label.add_theme_font_override("normal_font", font)
	_narrator_label.add_theme_font_override("italics_font", font)
	_narrator_label.add_theme_font_size_override("normal_font_size", _s(14))
	_narrator_label.add_theme_font_size_override("italics_font_size", _s(14))
	_narrator_label.add_theme_color_override("default_color", subtitle_color)
	_narrator_label.text = "[i]A quiet moment...[/i]"
	_expanded_box.add_child(_narrator_label)
	
	# Separator
	_expanded_box.add_child(HSeparator.new())
	
	# === DIALOGUE TEXT === (fixed height to prevent layout shift)
	_dialogue_label = RichTextLabel.new()
	_dialogue_label.bbcode_enabled = true
	_dialogue_label.fit_content = false
	_dialogue_label.scroll_active = false
	_dialogue_label.custom_minimum_size = Vector2(0, _s(50))
	_dialogue_label.clip_contents = true
	_dialogue_label.add_theme_font_override("normal_font", font)
	_dialogue_label.add_theme_font_size_override("normal_font_size", _s(16))
	_dialogue_label.add_theme_color_override("default_color", text_color)
	_dialogue_label.text = "\"Another quiet day...\""
	_expanded_box.add_child(_dialogue_label)
	
	# === STAT BARS === (in expanded box)
	_stats_box = VBoxContainer.new()
	_stats_box.add_theme_constant_override("separation", _s(8))
	_expanded_box.add_child(_stats_box)
	
	_alertness_bar = _create_stat_bar("👁 Alert", Color(1.0, 0.9, 0.2))
	_annoyance_bar = _create_stat_bar("😤 Annoyed", Color(1.0, 0.4, 0.3))
	_exhaustion_bar = _create_stat_bar("💤 Tired", Color(0.6, 0.5, 0.8))
	_suspicion_bar = _create_stat_bar("🔍 Suspicious", Color(0.3, 0.7, 1.0))


func _create_stat_bar(label_text: String, color: Color) -> ProgressBar:
	var font = load("res://assets/fonts/JetBrainsMono.ttf")
	
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", _s(10))
	_stats_box.add_child(row)
	
	var label = Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", _s(13))
	label.add_theme_color_override("font_color", subtitle_color)
	label.text = label_text
	label.custom_minimum_size.x = _s(100)
	row.add_child(label)
	
	var bar = ProgressBar.new()
	bar.max_value = 1.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(_s(120), _s(14))
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(_s(4))
	bar.add_theme_stylebox_override("fill", fill)
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.2)
	bg.set_corner_radius_all(_s(4))
	bar.add_theme_stylebox_override("background", bg)
	
	row.add_child(bar)
	return bar


func _process(_delta: float) -> void:
	if visible and _current_npc and is_instance_valid(_current_npc):
		_update_stats()


func show_npc(npc: Node3D) -> void:
	if _current_npc == npc and visible:
		return
	
	_current_npc = npc
	_last_state = ""
	
	if not npc:
		hide_panel()
		return
	
	var personality = npc.get("personality")
	
	if personality:
		_name_label.text = personality.display_name
		_title_label.text = personality.title
		if personality.portrait:
			_portrait.texture = personality.portrait
			_portrait_container.visible = true
		else:
			_portrait_container.visible = false
	else:
		_name_label.text = npc.name
		_title_label.text = "Unknown"
		_portrait_container.visible = false
	
	var state = npc.get("current_state")
	if state == null:
		state = "idle"
	
	_last_state = state
	_update_narrator_text(personality, state)
	_update_dialogue_text(personality, state)
	_update_state_label(state)
	
	visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)


func hide_panel() -> void:
	_current_npc = null
	
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	_tween.tween_callback(func(): visible = false)


func _update_narrator_text(personality, state: String) -> void:
	var text = ""
	if personality and personality.has_method("get_narrator_line"):
		text = personality.get_narrator_line(state)
	
	if text.is_empty():
		match state:
			"idle": text = "The creature rests, unaware..."
			"alert": text = "Something has caught its attention."
			"investigating": text = "A curious glance."
			"chasing": text = "The chase is ON!"
			"frustrated": text = "Defeat weighs heavy."
			_: text = "Observe closely..."
	
	_narrator_label.text = "[i]%s[/i]" % text


func _update_dialogue_text(personality, state: String) -> void:
	var text = ""
	
	# Use NPC's stored current_dialogue if available (syncs with speech bubble)
	if _current_npc and _current_npc.get("current_dialogue"):
		text = _current_npc.current_dialogue
	elif personality and personality.has_method("get_dialogue"):
		text = personality.get_dialogue(state)
	
	if text.is_empty() or text == "...":
		match state:
			"idle": text = "...Why are you watching me?"
			"alert": text = "Did you hear that?"
			"investigating": text = "I know someone is there!"
			"chasing": text = "GET BACK HERE!"
			"frustrated": text = "This isn't over..."
			_: text = "Stop staring."
	
	_dialogue_label.text = "\"%s\"" % text


func _update_state_label(state: String) -> void:
	# Match symbols from NPCStateIndicator - plain ASCII
	var state_symbols = {
		"idle": "~",
		"calm": "~",
		"alert": "!",
		"suspicious": "?",
		"investigating": "?",
		"searching": "?",
		"angry": "!!",
		"chasing": "!!",
		"tired": "zzz",
		"frustrated": "zzz",
		"caught": "!"
	}
	var state_colors = {
		"idle": Color(0.3, 0.7, 0.3),
		"calm": Color(0.3, 0.7, 0.3),
		"alert": Color(0.9, 0.7, 0.0),
		"suspicious": Color(0.2, 0.5, 0.9),
		"investigating": Color(0.4, 0.6, 0.9),
		"searching": Color(0.4, 0.6, 0.9),
		"angry": Color(0.9, 0.2, 0.2),
		"chasing": Color(0.9, 0.1, 0.1),
		"tired": Color(0.5, 0.5, 0.5),
		"frustrated": Color(0.5, 0.5, 0.5),
		"caught": Color(0.9, 0.8, 0.2)
	}
	var symbol = state_symbols.get(state, "-")
	var color = state_colors.get(state, text_color)
	_state_label.text = symbol + " " + state.capitalize()
	_state_label.add_theme_color_override("font_color", color)


func _update_stats() -> void:
	if not _current_npc:
		return
	
	var emo = _current_npc.get("emotional_state")
	if not emo:
		return
	
	_alertness_bar.value = emo.alertness
	_annoyance_bar.value = emo.annoyance
	_exhaustion_bar.value = emo.exhaustion
	_suspicion_bar.value = emo.suspicion
	
	var state = _current_npc.get("current_state")
	if state and state != _last_state:
		_last_state = state
		_update_state_label(state)
		var personality = _current_npc.get("personality")
		_update_narrator_text(personality, state)
		_update_dialogue_text(personality, state)
