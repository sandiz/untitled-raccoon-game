# Progress

## Current State: Core Loop Complete ✅

Shopkeeper wanders → Sees raccoon with item → Chases → Catch/Escape → Repeat

---

## Systems Status

| System | Status | Key Files |
|--------|--------|-----------|
| BT AI | ✅ | `ai/tasks/*.gd`, `ai/trees/shopkeeper_ai.tres` |
| Emotional State | ✅ | `systems/npc_emotional_state.gd` |
| Perception | ✅ | `systems/npc_perception.gd` |
| Theft Detection | ✅ | Player pickup + NPC sees item = chase |
| Animation | ✅ | `npcs/shopkeeper_animator.gd` (extracted) |
| UI (Info Panel) | ✅ | `ui/npc_info_panel.gd` |
| Day/Night | ✅ | `systems/day_night_cycle.gd` |
| Save System | ✅ | `systems/simulation_save_manager.gd` (v2) |

---

## Recent Changes (Session)

### UI Improvements
- **ScrollableWidgetContainer** - Base class for manual layout with scroll support
  - Solves VBoxContainer sizing issues with dynamic content
  - Auto-scroll when content exceeds viewport height
  - See `ui/scrollable_widget_container.gd`
- **RightPanelContainer** - Now extends ScrollableWidgetContainer, right-aligned
- **Speech bubble fixes**:
  - Tightened padding (top 8, bottom 10)
  - Removed border for cleaner look
  - Fixed tail artifact with `TEXTURE_FILTER_NEAREST` (no edge interpolation)
  - Tail extends past viewport to avoid edge sampling

### Animation Extraction
- Extracted 80+ lines of animation logic to `ShopkeeperAnimator` component
- Clean separation: NPC handles state, Animator handles visuals
- Same pattern can be reused for other NPCs

### Chase Bug Fixes
- Added `witnessed_theft` flag - chase ONLY triggers when NPC saw stealing
- Fixed post-catch infinite loop with cooldown check
- Fixed blackboard access pattern in BT abort checks (fallback to agent)
- Fixed method name mismatches (`on_saw_player`, `on_lost_sight`)

### Debug Tools
- `T` key toggles debug item in raccoon's hand for testing theft detection

---

## Key Mechanics

### Chase Trigger
- `witnessed_theft = true` (NPC must have seen stealing)
- Stamina > 20 → `will_chase = true`
- Seeing raccoon alone: awareness only, NO chase
- Seeing raccoon + item: `witnessed_theft = true` → CHASE

### 3 Meters
| Meter | Trigger | Decay |
|-------|---------|-------|
| Stamina | Drains during chase | Recovers when idle |
| Suspicion | Seeing player | 5/sec toward 10 |
| Temper | Failed chases | 1.5/sec (slow) |

### NPC Movement
All NPCs extend `BaseNPC` - single `move_and_slide()` per frame.

---

## File Structure
```
ai/tasks/         # BT actions (chase, idle, move, wait)
npcs/             # base_npc.gd, shopkeeper_npc.gd, shopkeeper_animator.gd
systems/          # emotional, perception, save, time
player/           # controller + pickup (E key), T for debug item
ui/               # info panel, speech bubble, selection
```

---

## Architecture

### Component Pattern
```
ShopkeeperNPC
├── NPCEmotionalState    # Meters: stamina, suspicion, temper
├── NPCPerception        # Sight, detection, awareness tracking
├── NPCSocial            # NPC-to-NPC communication (planned)
└── ShopkeeperAnimator   # Animation state machine (extracted)
```

All systems stored in blackboard for BT access with fallback pattern.

---

## Next Steps
1. ~~Extract animation logic~~ ✅ Done
2. Search behavior when player escapes (hold for now)
3. Give Up behavior after long chase (hold for now)
4. Item drop on catch, return behavior
5. Audio (footsteps, alerts, honk)
6. Polish (animations, particles)
