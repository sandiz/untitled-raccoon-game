class_name NPCPersonality
extends Resource
## Data-driven NPC personality - names, dialogue, stat modifiers.
## Create .tres files in res://data/personalities/

# ═══════════════════════════════════════
# IDENTITY
# ═══════════════════════════════════════

@export var npc_id: String = "shopkeeper_01"
@export var display_name: String = "Bernard"
@export var title: String = "The Shopkeeper"
@export var portrait: Texture2D  ## Optional portrait image for info panel

## Personality type affects dialogue selection
@export_enum("grumpy", "nervous", "lazy", "cheerful", "strict") var personality: String = "grumpy"

# ═══════════════════════════════════════
# STAT MODIFIERS (multipliers on base rates)
# ═══════════════════════════════════════

@export_group("Stat Modifiers")
@export_range(0.5, 2.0) var alertness_modifier: float = 1.0
@export_range(0.5, 2.0) var annoyance_modifier: float = 1.0
@export_range(0.5, 2.0) var exhaustion_modifier: float = 1.0
@export_range(0.5, 2.0) var suspicion_modifier: float = 1.0

# ═══════════════════════════════════════
# DIALOGUE LINES (per event)
# ═══════════════════════════════════════

@export_group("Dialogue")
@export var dialogue_idle: Array[String] = ["Another quiet day...", "Hmm, where did I put that..."]
@export var dialogue_spotted: Array[String] = ["Hm? What's that?", "Did I see something?"]
@export var dialogue_suspicious: Array[String] = ["Wait a minute...", "Something's not right..."]
@export var dialogue_chasing: Array[String] = ["GET BACK HERE!", "Stop, thief!"]
@export var dialogue_lost: Array[String] = ["Where'd they go?!", "Blast it..."]
@export var dialogue_caught: Array[String] = ["Got you!", "Ha! Not so fast!"]
@export var dialogue_gave_up: Array[String] = ["Forget it...", "*wheeze* Too old for this..."]
@export var dialogue_item_stolen: Array[String] = ["MY APPLES!", "That's MINE!"]
@export var dialogue_item_recovered: Array[String] = ["Back where it belongs.", "Hmph."]

# ═══════════════════════════════════════
# NARRATOR LINES (for info panel)
# ═══════════════════════════════════════

@export_group("Narrator")
@export var narrator_idle: Array[String] = [
	"The shopkeeper tends to his wares. All is calm.",
	"A quiet moment. Suspiciously quiet.",
]
@export var narrator_suspicious: Array[String] = [
	"Something has caught his attention.",
	"His eyes narrow. He senses mischief.",
]
@export var narrator_chasing: Array[String] = [
	"The chase is ON. He means business.",
	"Remarkable speed for his age.",
]
@export var narrator_searching: Array[String] = [
	"He's lost sight of his quarry.",
	"Confusion sets in. Where did they go?",
]
@export var narrator_tired: Array[String] = [
	"Exhaustion takes hold. He wheezes.",
	"Age catches up. The hunt is abandoned.",
]
@export var narrator_caught: Array[String] = [
	"Victory! The shopkeeper stands triumphant.",
	"Justice has been served. For now.",
]

# ═══════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════

func get_dialogue(event: String) -> String:
	var lines: Array[String] = []
	match event:
		"idle": lines = dialogue_idle
		"spotted": lines = dialogue_spotted
		"suspicious": lines = dialogue_suspicious
		"chasing": lines = dialogue_chasing
		"lost": lines = dialogue_lost
		"caught": lines = dialogue_caught
		"gave_up": lines = dialogue_gave_up
		"item_stolen": lines = dialogue_item_stolen
		"item_recovered": lines = dialogue_item_recovered
	
	if lines.size() > 0:
		return lines.pick_random()
	return "..."

func get_narrator_line(state: String) -> String:
	var lines: Array[String] = []
	match state:
		"idle": lines = narrator_idle
		"suspicious", "alert", "investigating": lines = narrator_suspicious
		"chasing": lines = narrator_chasing
		"searching": lines = narrator_searching
		"tired", "frustrated": lines = narrator_tired
		"caught": lines = narrator_caught
	
	if lines.size() > 0:
		return lines.pick_random()
	return "The subject remains under observation."

func get_full_name() -> String:
	return "%s, %s" % [display_name, title]
