# UI Features

## NPC Info Panel (DONE)

`ui/npc_info_panel.gd` + `ui/npc_info_manager.gd` (extends `ui/base_widget.gd`)

**Style:** Wildlife documentary + 4th wall breaking

**Shows:**
- Narrator describes NPC like nature documentary (🤔 emoji)
- NPC dialogue with 💬 emoji, typewriter effect
- Emotion stats (alertness, annoyance, exhaustion, suspicion)
- Current state with status emoji (matches speech bubble)

**State emoji** (same as speech bubble for consistency):
- 😌 Idle, 👀 Alert, 🤨 Suspicious, ❓ Searching
- 😠 Chasing, 😮‍💨 Tired, 😤 Caught

Auto-shows when player near NPC. Starts collapsed (N to expand).

---

## NPCPersonality Resource (.tres)

**Fields:**
- npc_id, display_name, title
- personality (grumpy/nervous/lazy/cheerful)
- alertness_modifier, annoyance_modifier (0.5-2.0)
- dialogue dict (keyed by event)
- narrator_lines dict (keyed by state)

**Bernard:** Grumpy, annoyance 1.3x, "MY CABBAGES! I mean- APPLES!"

---

## Game Speed Controls (DONE)

`systems/game_speed_manager.gd` - Press 1-4 for speed

| Key | Speed |
|-----|-------|
| 1 | 0.25x |
| 2 | 1x |
| 3 | 2x |
| 4 | 4x |

Shows brief indicator on change. Use `pause_for_menu()` / `resume_from_menu()` for pausing.

---

## NPC Speech Bubble (DONE)

`ui/npc_state_indicator.gd`

**Synced with NPC Info Panel** via `ui/npc_data_store.gd` (static singleton pattern).

**Style:** Dark translucent panel with status emoji + dialogue text

**Features:**
- SubViewport renders 2D UI as billboard Sprite3D above NPC
- Status-based emoji on left (😌 idle, 👀 alert, 😠 chasing, etc.)
- Typewriter effect for text
- Pop-in animation

### Status Emoji Mapping

| State | Emoji | Meaning |
|-------|-------|---------|
| idle, calm, returning | 😌 | Relaxed |
| alert | 👀 | Watching |
| suspicious, investigating | 🤨 | Suspicious |
| chasing, angry | 😠 | Angry |
| searching | ❓ | Confused |
| tired, frustrated, gave_up | 😮‍💨 | Exhausted |
| caught | 😤 | Triumphant |
| _(unknown)_ | 💭 | Default |

---

## Widget Architecture

### BaseWidget (`ui/base_widget.gd`)
Shared base class for TOD and NPC widgets:
- Shared style constants (colors, fonts)
- Expand/collapse with keybind support
- Helper methods: `_create_panel_style()`, `_create_label()`, `_create_button()`
- Scale-aware sizing via `_s(val)`

### NPCDataStore (`ui/npc_data_store.gd`)
Centralized NPC state - **no autoload** (spoils undo history), uses static singleton:
```gdscript
static var _instance: NPCDataStore = null
static func get_instance() -> NPCDataStore
```
- Emits `state_changed(npc_id, data)` signal
- Both speech bubble and info panel listen to same signal
- Single source of truth prevents desync

### NPCUIUtils (`ui/npc_ui_utils.gd`)
Shared emoji/color mappings:
- `get_status_emoji(state) -> String`
- `get_status_color(state) -> Color`

---

### Message Priority System (TODO)

**Problem:** Rapid state transitions can replace important messages before player reads them.

**Solution:** Priority-based minimum display time.

#### Priority Levels
```
3 (Critical):  chasing, caught, angry
2 (Alert):     alert, suspicious, investigating, searching
1 (Passive):   idle, calm, returning
0 (Default):   unknown states
```

#### Rules
| Incoming vs Current | Action |
|---------------------|--------|
| Higher or equal priority | Replace immediately |
| Lower priority + min_time passed | Replace |
| Lower priority + min_time NOT passed | Queue (show after timer) |

#### Implementation
```gdscript
var _current_priority: int = 0
var _message_shown_at: float = 0.0
var _min_display_time: float = 2.0  # seconds
var _queued_message: Dictionary = {}  # {text, state, priority}
```

---

## Time of Day Clock Widget (DONE)

`ui/tod_clock_widget.gd`

**Collapsed view shows:**
- Period icon (🌅☀🌆🌙)
- Time (HH:MM)
- Speed indicator (1x, 2x, ⏸)
- Time ratio (10m=24h)
- Progress bar

**Expanded view adds:**
- Period jump buttons
- Pause/Play button
- Speed up/down controls

**Keybind:** V to toggle expand/collapse

---

## Debug Overlay (TAB)

- NPC emotional bars
- Current state
- Target info
- FPS counter
