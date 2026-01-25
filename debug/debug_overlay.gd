extends CanvasLayer
## Debug Overlay - Toggle with F3
## Minimal debug info. Time is shown in TOD widget.

var enabled: bool = false  # Start hidden by default


# ═══════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════

func _ready() -> void:
	add_to_group("debug_overlay")
	visible = enabled


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		toggle()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		toggle()


func toggle() -> void:
	enabled = not enabled
	visible = enabled
