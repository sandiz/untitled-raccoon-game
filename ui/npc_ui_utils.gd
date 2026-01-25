class_name NPCUIUtils
## Shared utilities for NPC UI components (speech bubble, info panel)

## Status emoji mapping - used by both speech bubble and info panel
static func get_status_emoji(state: String) -> String:
	match state:
		"idle", "calm", "returning":
			return "😌"  # Relaxed/content
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
