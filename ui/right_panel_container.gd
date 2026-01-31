class_name RightPanelContainer
extends VBoxContainer
## Container for right-side UI widgets.
## Fixed width, positioned at top-right.

const MARGIN := 20
const SPACING := 10
const WIDTH := 400


func _ready() -> void:
	add_theme_constant_override("separation", SPACING)
	custom_minimum_size.x = WIDTH
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func _process(_delta: float) -> void:
	var viewport_size = get_viewport_rect().size
	# Position at top-right with margin
	var content_size = get_combined_minimum_size()
	size = content_size
	position.x = viewport_size.x - size.x - MARGIN
	position.y = MARGIN
