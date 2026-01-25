class_name NPCStateIndicator
extends Node3D
## Floating icon above NPC head showing emotional state.
## Uses text symbols for UGG-style clarity.

# State symbols and colors
const STATES = {
	"calm": { "symbol": "♪", "color": Color(0.4, 0.8, 0.4) },      # Green
	"alert": { "symbol": "!", "color": Color(1.0, 0.8, 0.0) },     # Yellow
	"suspicious": { "symbol": "?", "color": Color(0.3, 0.6, 1.0) }, # Blue
	"angry": { "symbol": "!!", "color": Color(1.0, 0.3, 0.3) },    # Red
	"chasing": { "symbol": "!!", "color": Color(1.0, 0.2, 0.2) },  # Bright red
	"searching": { "symbol": "?", "color": Color(0.5, 0.7, 1.0) }, # Light blue
	"tired": { "symbol": "zzz", "color": Color(0.6, 0.6, 0.6) },   # Gray
	"caught": { "symbol": "★", "color": Color(1.0, 0.9, 0.3) },    # Gold
	"none": { "symbol": "", "color": Color.WHITE },
}

@export var height_offset: float = 2.2  # Above NPC head
@export var bob_amount: float = 0.1
@export var bob_speed: float = 2.0

var _label: Label3D
var _current_state: String = "none"
var _tween: Tween
var _time: float = 0.0

func _ready() -> void:
	_create_label()
	hide_indicator()

func _process(delta: float) -> void:
	# Gentle bob animation
	_time += delta
	if _label and _label.visible:
		_label.position.y = height_offset + sin(_time * bob_speed) * bob_amount
	
	# Always face camera (billboard)
	var camera = get_viewport().get_camera_3d()
	if camera and _label:
		_label.global_transform = _label.global_transform.looking_at(
			camera.global_position, Vector3.UP
		)
		# Flip to face camera correctly
		_label.rotate_y(PI)

func _create_label() -> void:
	_label = Label3D.new()
	_label.name = "StateLabel"
	_label.pixel_size = 0.01
	_label.font_size = 64
	_label.outline_size = 8
	_label.modulate = Color.WHITE
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true  # Always visible
	_label.position = Vector3(0, height_offset, 0)
	add_child(_label)

func show_state(state_name: String) -> void:
	if state_name == _current_state:
		return
	
	_current_state = state_name
	var state_data = STATES.get(state_name, STATES["none"])
	
	if state_data.symbol == "":
		hide_indicator()
		return
	
	_label.text = state_data.symbol
	_label.modulate = state_data.color
	_label.outline_modulate = Color(0, 0, 0, 0.5)
	
	# Pop-in animation
	_animate_pop_in()

func hide_indicator() -> void:
	_current_state = "none"
	if _tween:
		_tween.kill()
	_label.visible = false

func _animate_pop_in() -> void:
	if _tween:
		_tween.kill()
	
	_label.visible = true
	_label.scale = Vector3.ZERO
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BACK)  # Overshoot for "pop" effect
	_tween.tween_property(_label, "scale", Vector3.ONE, 0.3)

func _animate_pop_out() -> void:
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.tween_property(_label, "scale", Vector3.ZERO, 0.2)
	_tween.tween_callback(func(): _label.visible = false)
