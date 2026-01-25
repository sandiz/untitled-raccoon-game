# NPC Selection System

## Overview
Click-to-select system for NPCs with visual feedback and UI integration.

## Features

### Selection Mechanics
- **Click NPC** → Select (shows ring + speech bubble + info panel)
- **Click selected NPC** → Deselect
- **Click empty 3D space** → Deselect all
- **Click on UI** → No effect (preserves selection)
- **Max 3 NPCs** selectable at once (oldest removed when exceeded)
- **Auto-select** closest NPC to player after 2 seconds on game start

### Visual Indicators
- **Selection Ring**: Crisp cyan circle outline under selected NPC's feet
  - Shader: `shaders/selection_ring.gdshader`
  - Component: `npcs/selection_ring.gd`
  - No pulse, static size, thin outline

### Data Flow
```
NPCDataStore (singleton pattern)
    ├── _selected_npc_ids: Array[String]
    ├── _npc_nodes: Dictionary (npc_id -> Node3D)
    ├── selection_changed signal
    │
    ├── select_npc(npc_id)
    ├── deselect_npc(npc_id)
    ├── deselect_all()
    └── is_selected(npc_id) -> bool
```

### Components
1. **NPCDataStore** (`ui/npc_data_store.gd`)
   - Centralized selection state
   - NPC node registration
   - Selection signals

2. **NPCInfoManager** (`ui/npc_info_manager.gd`)
   - Handles click input
   - Raycasts to detect NPC clicks
   - Ignores UI clicks via `gui_get_hovered_control()`
   - Auto-selects closest NPC on start

3. **SelectionRing** (`npcs/selection_ring.gd`)
   - Visual ring indicator
   - show_ring() / hide_ring() with fade animation

4. **NPCStateIndicator** (`ui/npc_state_indicator.gd`)
   - Speech bubble only shows for selected NPCs
   - Stores pending dialogue to show when selected

5. **Shopkeeper NPC** (`npcs/shopkeeper_npc.gd`)
   - Registers with data store
   - Creates selection ring
   - Responds to selection_changed signal

## Files Modified
- `ui/npc_data_store.gd` - Added selection tracking
- `ui/npc_info_manager.gd` - Click-based selection
- `ui/npc_state_indicator.gd` - Selection-aware visibility
- `npcs/shopkeeper_npc.gd` - Selection ring + registration
- `npcs/selection_ring.gd` - New component
- `shaders/selection_ring.gdshader` - New shader
