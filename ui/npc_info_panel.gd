class_name NPCInfoPanel
extends BaseWidget
## Wildlife documentary style info panel - extends BaseWidget.
## Shows info for selected NPC only (hidden when no NPC selected).
## Reads NPC state from NPCDataStore for sync with speech bubble.

var _current_npc: Node3D = null

var _tween: Tween
var _last_state: String = ""
var _data_store: NPCDataStore

# Typewriter effect
var _narrator_tween: Tween
var _dialogue_tween: Tween
var _narrator_full_text: String = ""
var _dialogue_full_text: String = ""
const TYPEWRITER_SPEED: float = 0.02

# UI Elements
var _container: PanelContainer
var _portrait_container: PanelContainer
var _portrait: TextureRect
var _name_label: Label
var _title_label: Label
var _narrator_label: RichTextLabel
var _dialogue_label: RichTextLabel
var _state_label: Label
var _stats_box: VBoxContainer

# Stat bars (3-meter system)
var _stamina_bar: ProgressBar
var _suspicion_bar: ProgressBar
var _temper_bar: ProgressBar


func _ready() -> void:
	_expand_keybind = KEY_N
	_expanded = false  # Start collapsed
	super._ready()
	visible = false
	modulate.a = 0.0
	
	# Connect to data store
	_data_store = NPCDataStore.get_instance()
	_data_store.state_changed.connect(_on_npc_state_changed)
	_data_store.selection_changed.connect(_on_selection_changed)
	
	# Panel stays hidden until an NPC is selected


func _input(event: InputEvent) -> void:
	if not visible:
		return
	super._input(event)


func _process(_delta: float) -> void:
	# Update our minimum size for VBoxContainer parent
	_update_size()
	
	# Update NPC stats if visible
	if visible and _current_npc and is_instance_valid(_current_npc):
		_update_stats()


func _update_size() -> void:
	if _container:
		var c_size = _container.get_combined_minimum_size()
		custom_minimum_size = c_size
		size = c_size
		# Also constrain the internal container to its minimum
		_container.size = c_size


func _build_ui() -> void:
	# Container - don't let it expand to fill parent
	_container = PanelContainer.new()
	_container.custom_minimum_size.x = _s(340)
	_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_container.add_theme_stylebox_override("panel", _create_panel_style())
	add_child(_container)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", _s(12))
	_container.add_child(main_vbox)
	
	# === TOP ROW: Portrait + Name/Title ===
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", _s(16))
	main_vbox.add_child(top_row)
	
	# Portrait with rounded corners
	_portrait_container = PanelContainer.new()
	_portrait_container.custom_minimum_size = Vector2(_s(70), _s(70))
	_portrait_container.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var portrait_style = StyleBoxFlat.new()
	portrait_style.bg_color = Color(1, 1, 1, 1)
	portrait_style.set_corner_radius_all(_s(10))
	_portrait_container.add_theme_stylebox_override("panel", portrait_style)
	_portrait_container.visible = false
	top_row.add_child(_portrait_container)
	
	_portrait = TextureRect.new()
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait_container.add_child(_portrait)
	
	# Name/Title column
	var header_vbox = VBoxContainer.new()
	header_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_vbox.add_theme_constant_override("separation", _s(4))
	top_row.add_child(header_vbox)
	
	# Name row with expand button
	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", _s(8))
	header_vbox.add_child(name_row)
	
	_name_label = _create_label("Bernard", 22)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_name_label)
	name_row.add_child(_create_expand_button())
	
	# Title row (just title now)
	_title_label = _create_label("The Grumpy Shopkeeper", 14, SUBTITLE_COLOR)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	header_vbox.add_child(_title_label)
	
	# State row at bottom (aligned with title baseline area)
	_state_label = _create_label("😌 Idle", 14)
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_vbox.add_child(_state_label)
	
	# === EXPANDED CONTENT ===
	_expanded_box = VBoxContainer.new()
	_expanded_box.add_theme_constant_override("separation", _s(12))
	_expanded_box.visible = false
	main_vbox.add_child(_expanded_box)
	
	_expanded_box.add_child(HSeparator.new())
	
	# Narrator text
	var narrator_row = HBoxContainer.new()
	narrator_row.add_theme_constant_override("separation", _s(4))
	_expanded_box.add_child(narrator_row)
	
	var narrator_emoji = _create_label("🤔", 16)
	narrator_emoji.custom_minimum_size = Vector2(_s(22), 0)
	narrator_emoji.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	narrator_row.add_child(narrator_emoji)
	
	_narrator_label = RichTextLabel.new()
	_narrator_label.bbcode_enabled = true
	_narrator_label.fit_content = false
	_narrator_label.scroll_active = false
	_narrator_label.custom_minimum_size = Vector2(0, _s(42))
	_narrator_label.clip_contents = true
	_narrator_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_narrator_label.add_theme_font_override("normal_font", _font)
	_narrator_label.add_theme_font_override("italics_font", _font)
	_narrator_label.add_theme_font_size_override("normal_font_size", _s(14))
	_narrator_label.add_theme_font_size_override("italics_font_size", _s(14))
	_narrator_label.add_theme_color_override("default_color", SUBTITLE_COLOR)
	_narrator_label.text = "[i]A quiet moment...[/i]"
	narrator_row.add_child(_narrator_label)
	
	_expanded_box.add_child(HSeparator.new())
	
	# Dialogue text
	var dialogue_row = HBoxContainer.new()
	dialogue_row.add_theme_constant_override("separation", _s(4))
	_expanded_box.add_child(dialogue_row)
	
	var dialogue_emoji = _create_label("💬", 16)
	dialogue_emoji.custom_minimum_size = Vector2(_s(22), 0)
	dialogue_emoji.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dialogue_row.add_child(dialogue_emoji)
	
	_dialogue_label = RichTextLabel.new()
	_dialogue_label.bbcode_enabled = true
	_dialogue_label.fit_content = false
	_dialogue_label.scroll_active = false
	_dialogue_label.custom_minimum_size = Vector2(0, _s(42))
	_dialogue_label.clip_contents = true
	_dialogue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_label.add_theme_font_override("normal_font", _font)
	_dialogue_label.add_theme_font_size_override("normal_font_size", _s(16))
	_dialogue_label.add_theme_color_override("default_color", TEXT_COLOR)
	_dialogue_label.text = "Another quiet day..."
	dialogue_row.add_child(_dialogue_label)
	
	_expanded_box.add_child(HSeparator.new())
	
	# Stat bars
	_stats_box = VBoxContainer.new()
	_stats_box.add_theme_constant_override("separation", _s(8))
	_expanded_box.add_child(_stats_box)
	
	_stamina_bar = _create_stat_bar("⚡", "Stamina", Color(0.3, 0.8, 0.4))
	_suspicion_bar = _create_stat_bar("👀", "Suspicion", Color(0.9, 0.7, 0.2))
	_temper_bar = _create_stat_bar("🔥", "Temper", Color(1.0, 0.4, 0.3))


func _create_stat_bar(emoji: String, label_text: String, color: Color) -> ProgressBar:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", _s(6))
	_stats_box.add_child(row)
	
	# Emoji in fixed-width container for alignment
	var emoji_label = _create_label(emoji, 13, SUBTITLE_COLOR)
	emoji_label.custom_minimum_size.x = _s(24)
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(emoji_label)
	
	# Text label with fixed width
	var label = _create_label(label_text, 13, SUBTITLE_COLOR)
	label.custom_minimum_size.x = _s(80)
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


func _on_npc_state_changed(npc_id: String, data: Dictionary) -> void:
	# Update if this is the currently displayed NPC
	if _current_npc and _current_npc.get("npc_id") == npc_id:
		var state = data.get("state", "idle")
		var dialogue = data.get("dialogue", "")
		if state != _last_state:
			_last_state = state
			_update_state_label(state)
			_update_narrator_text(_current_npc.get("personality"), state)
		if not dialogue.is_empty():
			_show_dialogue_text(dialogue)


func show_npc(npc: Node3D) -> void:
	if _current_npc == npc and visible:
		return
	
	_current_npc = npc
	_last_state = ""
	
	# Re-show stat bars for NPC
	if _stats_box:
		_stats_box.visible = true
	
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
	
	# Force immediate size recalculation after portrait change
	_update_size()
	
	# Get initial state from data store (single source of truth)
	var npc_id_str = npc.get("npc_id") if npc.get("npc_id") else ""
	var state = "idle"
	var dialogue = ""
	if not npc_id_str.is_empty() and _data_store:
		state = _data_store.get_npc_state(npc_id_str)
		dialogue = _data_store.get_npc_dialogue(npc_id_str)
	
	_last_state = state
	_update_narrator_text(personality, state)
	_update_state_label(state)
	if not dialogue.is_empty():
		_show_dialogue_text(dialogue)
	else:
		_update_dialogue_from_npc(npc, personality, state)
	
	visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BACK)
	# Slide in from right + fade in
	_container.position.x = 50
	_tween.set_parallel(true)
	_tween.tween_property(_container, "position:x", 0.0, 0.3)
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)


func hide_panel() -> void:
	_current_npc = null
	
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUAD)
	# Slide out to right + fade out
	_tween.set_parallel(true)
	_tween.tween_property(_container, "position:x", 50.0, 0.2)
	_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	_tween.chain().tween_callback(func(): 
		visible = false
		_container.position.x = 0  # Reset for next show
	)


func _on_selection_changed(selected_ids: Array) -> void:
	if selected_ids.is_empty():
		# No NPC selected - hide panel
		hide_panel()
	else:
		# NPC selected - show that NPC's info
		var npc_node = _data_store.get_npc_node(selected_ids[0])
		if npc_node:
			show_npc(npc_node)


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
	
	_narrator_full_text = text
	if _narrator_tween:
		_narrator_tween.kill()
	_narrator_label.text = ""
	_narrator_tween = create_tween()
	for i in range(text.length()):
		_narrator_tween.tween_callback(_add_narrator_char.bind(i))
		_narrator_tween.tween_interval(TYPEWRITER_SPEED)


func _add_narrator_char(index: int) -> void:
	_narrator_label.text = "[i]%s[/i]" % _narrator_full_text.substr(0, index + 1)


func _update_dialogue_from_npc(npc: Node3D, personality, state: String) -> void:
	var text = ""
	
	# First try data store
	var npc_id = npc.get("npc_id") if npc.get("npc_id") else ""
	if not npc_id.is_empty():
		text = _data_store.get_npc_dialogue(npc_id)
	
	# Fallback to NPC's current_dialogue
	if text.is_empty() and npc.get("current_dialogue"):
		text = npc.current_dialogue
	
	# Fallback to personality
	if text.is_empty() and personality and personality.has_method("get_dialogue"):
		text = personality.get_dialogue(state)
	
	# Final fallback
	if text.is_empty() or text == "...":
		match state:
			"idle": text = "...Why are you watching me?"
			"alert": text = "Did you hear that?"
			"investigating": text = "I know someone is there!"
			"chasing": text = "GET BACK HERE!"
			"frustrated": text = "This isn't over..."
			_: text = "Stop staring."
	
	_show_dialogue_text(text)


func _show_dialogue_text(text: String) -> void:
	var clean_text = text.trim_prefix("\"").trim_suffix("\"")
	
	_dialogue_full_text = clean_text
	if _dialogue_tween:
		_dialogue_tween.kill()
	_dialogue_label.text = ""
	_dialogue_tween = create_tween()
	for i in range(clean_text.length()):
		_dialogue_tween.tween_callback(_add_dialogue_char.bind(i))
		_dialogue_tween.tween_interval(TYPEWRITER_SPEED)


func _add_dialogue_char(index: int) -> void:
	_dialogue_label.text = _dialogue_full_text.substr(0, index + 1)


func _update_state_label(state: String) -> void:
	var emoji = NPCUIUtils.get_status_emoji(state)
	var color = NPCUIUtils.get_status_color(state)
	_state_label.text = emoji + " " + state.capitalize()
	_state_label.add_theme_color_override("font_color", color)


func _update_stats() -> void:
	if not _current_npc:
		return
	
	var emo = _current_npc.get("emotional_state")
	if not emo:
		return
	
	# Smoothly interpolate progress bars
	var delta = get_process_delta_time()
	var target_stamina = emo.stamina / 100.0
	var target_suspicion = emo.suspicion / 100.0
	var target_temper = emo.temper / 100.0
	
	# Faster lerp for decrease, normal for increase
	var up_speed = 10.0 * delta
	var down_speed = 15.0 * delta
	
	_stamina_bar.value = lerpf(_stamina_bar.value, target_stamina, down_speed if target_stamina < _stamina_bar.value else up_speed)
	_suspicion_bar.value = lerpf(_suspicion_bar.value, target_suspicion, down_speed if target_suspicion < _suspicion_bar.value else up_speed)
	_temper_bar.value = lerpf(_temper_bar.value, target_temper, down_speed if target_temper < _temper_bar.value else up_speed)
