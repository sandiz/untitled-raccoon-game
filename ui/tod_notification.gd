class_name TODNotification
extends Control
## Shows a subtle notification when the time of day changes.
## Displays brief text with fade in/out animation.

@export var display_duration: float = 2.5
@export var fade_duration: float = 0.5

@onready var label: Label = $Label
@onready var icon: Label = $Icon  # Emoji/symbol

var _tween: Tween

const PERIOD_ICONS := {
	"Morning": "~",      # Sunrise
	"Afternoon": "*",    # Sun 
	"Evening": "+",      # Sunset
	"Night": "."         # Moon/stars
}

const PERIOD_COLORS := {
	"Morning": Color("#FFD700"),     # Gold
	"Afternoon": Color("#FFFEF0"),   # White
	"Evening": Color("#FF7F50"),     # Coral
	"Night": Color("#6495ED")        # Blue
}


func _ready() -> void:
	modulate.a = 0.0
	visible = false
	_apply_fonts()


func _apply_fonts() -> void:
	if not label or not icon:
		return
	var font = load("res://assets/fonts/JetBrainsMono.ttf")
	if font:
		label.add_theme_font_override("font", font)
		icon.add_theme_font_override("font", font)


func show_notification(period_name: String, _old_period: String = "") -> void:
	# Guard against missing nodes
	if not label or not icon:
		return
	
	# Cancel any existing animation
	if _tween:
		_tween.kill()
	
	# Set text and icon
	label.text = period_name + "..."
	icon.text = PERIOD_ICONS.get(period_name, "*")
	
	# Set color
	var color = PERIOD_COLORS.get(period_name, Color.WHITE)
	label.modulate = color
	icon.modulate = color
	
	visible = true
	
	# Animate
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)
	
	# Fade in
	_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	
	# Hold
	_tween.tween_interval(display_duration)
	
	# Fade out
	_tween.set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	
	# Hide when done
	_tween.tween_callback(func(): visible = false)
