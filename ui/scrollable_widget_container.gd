class_name ScrollableWidgetContainer
extends Control
## Base class for scrollable widget containers with manual layout.
##
## Solves Godot's VBoxContainer sizing issues where children with dynamic content
## (e.g., expandable panels) don't report correct sizes via get_combined_minimum_size().
##
## Key features:
## - Manual vertical layout using get_combined_minimum_size() per-frame
## - ScrollContainer wrapper with auto-scroll when content exceeds max height
## - Automatic reparenting of scene children to internal content container
## - Configurable alignment (left/right) and spacing
##
## Usage:
##   1. Extend this class
##   2. Override _get_max_height() if custom height limit needed
##   3. Override _get_anchor_position() to position the container
##   4. Add children in scene - they auto-reparent to scroll content
##
## Why manual layout?
##   Godot's built-in containers rely on minimum_size propagation which breaks when:
##   - Child content changes dynamically (expand/collapse)
##   - Children have internal containers that resize
##   - Size needs to shrink back down after expansion
##   By calling get_combined_minimum_size() each frame and setting size explicitly,
##   we ensure layout always matches actual content.

enum Alignment { LEFT, RIGHT, CENTER }

## Spacing between child widgets
@export var spacing := 10
## Horizontal alignment of children within container
@export var alignment := Alignment.LEFT
## Extra width for scrollbar
@export var scrollbar_width := 12

var _scroll_container: ScrollContainer
var _content_container: Control
var _children_reparented := false


func _ready() -> void:
	_setup_scroll_container()


func _setup_scroll_container() -> void:
	_scroll_container = ScrollContainer.new()
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	# Style scrollbar
	var scrollbar = _scroll_container.get_v_scroll_bar()
	scrollbar.custom_minimum_size.x = 8
	
	_content_container = Control.new()
	_content_container.name = "ScrollContent"
	
	add_child(_scroll_container)
	_scroll_container.add_child(_content_container)


func _process(_delta: float) -> void:
	if not _children_reparented:
		_reparent_children()
		_children_reparented = true
	
	_update_layout()


func _update_layout() -> void:
	var max_height := _get_max_height()
	
	# First pass: measure
	var max_width := 0.0
	var total_height := 0.0
	for child in _content_container.get_children():
		if child is Control and child.visible:
			var child_size = child.get_combined_minimum_size()
			max_width = max(max_width, child_size.x)
			total_height += child_size.y + spacing
	
	if total_height > 0:
		total_height -= spacing
	
	# Second pass: position
	var y_offset := 0.0
	for child in _content_container.get_children():
		if child is Control and child.visible:
			var child_size = child.get_combined_minimum_size()
			var x_pos := _get_child_x_position(child_size.x, max_width)
			child.position = Vector2(x_pos, y_offset)
			child.size = child_size
			y_offset += child_size.y + spacing
	
	# Apply sizes
	_content_container.custom_minimum_size = Vector2(max_width, total_height)
	_content_container.size = Vector2(max_width, total_height)
	
	var scroll_height = min(total_height, max_height)
	var full_width = max_width + scrollbar_width
	_scroll_container.size = Vector2(full_width, scroll_height)
	_scroll_container.position = Vector2.ZERO
	
	size = Vector2(full_width, scroll_height)
	position = _get_anchor_position(size)


func _get_child_x_position(child_width: float, container_width: float) -> float:
	match alignment:
		Alignment.RIGHT:
			return container_width - child_width
		Alignment.CENTER:
			return (container_width - child_width) / 2.0
		_:
			return 0.0


## Override to set max height before scrolling kicks in
func _get_max_height() -> float:
	return get_viewport_rect().size.y - 80.0


## Override to position the container (called each frame with current size)
func _get_anchor_position(_container_size: Vector2) -> Vector2:
	return Vector2.ZERO


func _reparent_children() -> void:
	var children_to_move: Array[Node] = []
	for child in get_children():
		if child != _scroll_container:
			children_to_move.append(child)
	
	for child in children_to_move:
		remove_child(child)
		_content_container.add_child(child)
