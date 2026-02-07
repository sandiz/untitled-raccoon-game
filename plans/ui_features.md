# UI Features

## NPC Info Panel

`ui/npc_info_panel.gd` - Wildlife documentary style

- Narrator describes NPC (🤔 emoji)
- NPC dialogue with typewriter effect (💬 emoji)
- 3 emotion meters (stamina, suspicion, temper)
- Current state with status emoji
- Auto-shows when near NPC, N to expand

## NPC Speech Bubble

`ui/npc_state_indicator.gd` - 3D billboard above NPC

- SubViewport renders 2D UI as Sprite3D
- Status emoji + dialogue text
- Pop-in animation, typewriter effect

### Status Emoji

| State | Emoji |
|-------|-------|
| idle, calm | 😌 |
| alert | 👀 |
| suspicious | 🤨 |
| chasing | 😠 |
| searching | ❓ |
| tired, gave_up | 😮‍💨 |
| caught | 😤 |

## Game Speed

`systems/game_speed_manager.gd` - Keys 1-4

| Key | Speed |
|-----|-------|
| 1 | 0.25x |
| 2 | 1x |
| 3 | 2x |
| 4 | 4x |

## Widget Architecture

### BaseWidget (`ui/base_widget.gd`)
- Shared style constants
- Expand/collapse with keybind
- Scale-aware sizing via `_s(val)`

### NPCDataStore (`ui/npc_data_store.gd`)
Static singleton (no autoload) - single source of truth for NPC state.
Both speech bubble and info panel listen to same signal.

```gdscript
static var _instance: NPCDataStore = null
static func get_instance() -> NPCDataStore
```

### ScrollableWidgetContainer (`ui/scrollable_widget_container.gd`)
Manual layout with scroll support for dynamic content.
