class_name RightPanelContainer
extends ScrollableWidgetContainer
## Right-side widget container anchored to top-right of screen.

const MARGIN := 20
const BOTTOM_MARGIN := 40


func _ready() -> void:
	alignment = Alignment.RIGHT
	spacing = 10
	super._ready()


func _get_max_height() -> float:
	var viewport_size = get_viewport_rect().size
	# Fallback for web where viewport size might be zero initially
	if viewport_size.y <= 0:
		viewport_size.y = 720.0
	return viewport_size.y - MARGIN * 2 - BOTTOM_MARGIN


func _get_anchor_position(container_size: Vector2) -> Vector2:
	var viewport_size = get_viewport_rect().size
	# Fallback for web where viewport size might be zero initially
	if viewport_size.x <= 0:
		viewport_size.x = 1280.0
	return Vector2(
		viewport_size.x - container_size.x - MARGIN,
		MARGIN
	)
