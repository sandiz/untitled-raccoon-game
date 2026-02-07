class_name UIUtils
## Shared utilities, constants, and helpers for all UI components.
## Consolidates common patterns: colors, fonts, scaling, and styling.

# ============================================================================
# STYLE CONSTANTS
# ============================================================================

## Panel background color (dark, semi-transparent)
const PANEL_BG_COLOR := Color(0.06, 0.06, 0.08, 0.92)
## Opaque panel background (for 3D indicators)
const PANEL_BG_COLOR_OPAQUE := Color(0.06, 0.06, 0.08, 1.0)
## Panel border color
const PANEL_BORDER_COLOR := Color(0.25, 0.25, 0.3, 0.9)
## Primary text color
const TEXT_COLOR := Color(0.95, 0.95, 0.9)
## Subtitle/secondary text color
const SUBTITLE_COLOR := Color(0.7, 0.65, 0.6)
## Muted/disabled text color
const MUTED_COLOR := Color(0.5, 0.5, 0.55)

## Font resource path
const FONT_PATH := "res://assets/fonts/ui_font.tres"

# Cached font to avoid repeated loads
static var _cached_font: Font = null

# ============================================================================
# SCALING
# ============================================================================

## Get display DPI scale factor (works on all platforms including web)
static func get_display_scale() -> float:
	var dpi_scale := DisplayServer.screen_get_scale()
	return dpi_scale if dpi_scale > 0 else 1.0


## Scale an integer value by display scale
static func scale(val: int) -> int:
	return int(val * get_display_scale())


## Scale a float value by display scale
static func scale_f(val: float) -> float:
	return val * get_display_scale()


# ============================================================================
# FONTS
# ============================================================================

## Get the shared UI font (cached)
static func get_font() -> Font:
	if _cached_font == null:
		_cached_font = load(FONT_PATH)
	return _cached_font


## Apply standard font styling to a label
static func style_label(label: Label, font_size: int = 14, color: Color = TEXT_COLOR) -> void:
	var font := get_font()
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", scale(font_size))
	label.add_theme_color_override("font_color", color)


## Apply standard font styling to a button
static func style_button(button: Button, font_size: int = 14) -> void:
	var font := get_font()
	if font:
		button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", scale(font_size))


# ============================================================================
# PANEL STYLING
# ============================================================================

## Create the standard dark panel StyleBox
static func create_panel_style(corner_radius: int = 10, padding: int = 10, use_border: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG_COLOR
	if use_border:
		style.set_border_width_all(2)
		style.border_color = PANEL_BORDER_COLOR
	style.set_corner_radius_all(scale(corner_radius))
	style.set_content_margin_all(scale(padding))
	return style


## Create a minimal panel style (no border, small radius)
static func create_minimal_panel_style(corner_radius: int = 4, padding: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG_COLOR
	style.set_border_width_all(1)
	style.border_color = PANEL_BORDER_COLOR
	style.set_corner_radius_all(scale(corner_radius))
	style.set_content_margin_all(scale(padding))
	return style


# ============================================================================
# NODE FINDING UTILITIES
# ============================================================================

## Find the DayNightCycle node in the scene tree
static func find_day_night_cycle(tree: SceneTree) -> DayNightCycle:
	# Try group first (fastest)
	var day_night := tree.get_first_node_in_group("day_night_cycle") as DayNightCycle
	if day_night:
		return day_night
	
	# Search recursively from root
	for node in tree.root.get_children():
		var result := _find_node_of_type_recursive(node, "DayNightCycle")
		if result:
			return result as DayNightCycle
	return null


static func _find_node_of_type_recursive(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name or (node is DayNightCycle if type_name == "DayNightCycle" else false):
		return node
	for child in node.get_children():
		var result := _find_node_of_type_recursive(child, type_name)
		if result:
			return result
	return null


# ============================================================================
# NPC STATUS UTILITIES
# ============================================================================

## Status emoji mapping - used by both speech bubble and info panel
static func get_status_emoji(state: String) -> String:
	match state:
		"idle", "calm", "returning":
			return "😌"  # Relaxed/content
		"exploring":
			return "🦝"  # Raccoon exploring
		"alert":
			return "👀"  # Alert/watching
		"suspicious", "investigating":
			return "🤨"  # Suspicious
		"chasing", "angry":
			return "😠"  # Angry/chasing
		"searching":
			return "❓"  # Searching/confused
		"tired", "frustrated", "gave_up":
			return "😮‍💨"  # Exhausted
		"caught":
			return "😤"  # Triumphant
		_:
			return "💭"  # Default thought


## Status colors - used by info panel state label
static func get_status_color(state: String) -> Color:
	match state:
		"idle", "calm", "returning":
			return Color(0.3, 0.7, 0.3)  # Green
		"exploring":
			return Color(0.4, 0.8, 0.9)  # Cyan/teal
		"alert":
			return Color(0.9, 0.7, 0.0)  # Yellow
		"suspicious", "investigating", "searching":
			return Color(0.4, 0.6, 0.9)  # Blue
		"angry", "chasing":
			return Color(0.9, 0.1, 0.1)  # Red
		"tired", "frustrated", "gave_up":
			return Color(0.5, 0.5, 0.5)  # Gray
		"caught":
			return Color(0.9, 0.8, 0.2)  # Gold
		_:
			return Color(0.95, 0.95, 0.9)  # Default white
