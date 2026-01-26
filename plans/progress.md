# Progress

## Current State: Theft Detection Complete ✅

The idle/chase cycle is **bulletproof** and now includes **theft detection** - shopkeeper only chases when seeing the raccoon holding a stolen item.

---

## Behavior Tree (LimboAI) ✅

### Active Tasks (5 files)
| Task | Purpose |
|------|---------|
| `chase_player.gd` | Chase → catch → celebrate → cooldown |
| `play_idle.gd` | Play idle anim, wait 2 frames for physics |
| `move_to_position.gd` | Navigate to wander target with rotation |
| `select_random_position.gd` | Pick random point in radius |
| `interruptible_wait.gd` | Wait 2-5s, abort if will_chase |

### BT Structure
```
BTRepeat (forever)
└── BTSelector
    ├── ChasePlayer (speed: 5.0)
    └── BTSequence (wander)
        ├── SelectRandomPosition
        ├── MoveToPosition
        ├── PlayIdle
        └── InterruptibleWait
```

### Fixed Issues ✅
- Double celebration: Cooldown set IMMEDIATELY on catch
- Velocity sliding: All tasks call move_and_slide() in _exit()
- Walk-on-spot: Rotate first, move when within 45°
- UI status stuck: Clear priority lock when celebration ends

---

## 3-Meter Emotional System ✅

| Meter | Range | Effect |
|-------|-------|--------|
| Stamina | 100→0 | Drains while chasing, triggers give-up |
| Suspicion | 0→100 | Builds from seeing player, triggers chase |
| Temper | 0→100 | Builds from failed chases, speeds pursuit |

### Thresholds
- `will_chase`: Suspicion ≥ 70 (HUNTING_THRESHOLD)
- `will_give_up`: Stamina ≤ 20
- Chase speed multiplier: 1.0 + (temper * 0.005)

### Theft Detection ✅
- Seeing raccoon alone: Suspicion +40 (alert but NO chase)
- Seeing raccoon with item: `on_saw_stealing()` → Suspicion = 100 → CHASE!

---

## Perception System ✅

- Vision: 10m range, 90° FOV
- Hearing: 10m range (full circle)
- Visual indicator: Truncated cone starting 1m ahead of feet
- Detection line: Single orange line at body height (0.9m)
- **Fade in/out on NPC selection**

---

## UI System ✅

### NPC Info Panel
- Shows selected NPC stats (Stamina, Suspicion, Temper)
- State label with emoji indicator
- Progress bars with proper alignment

### Speech Bubble
- SubViewport rendering for crisp 2D in 3D
- Typewriter effect
- Priority system (LOW → CRITICAL)
- Extra padding for descenders (q, g, y, p, j)

### Selection System
- Click to select NPC
- Selection ring visual
- Vision/hearing indicators fade in on select

---

## Day/Night Cycle ✅

- 4 TOD periods: Morning, Afternoon, Evening, Night
- Skybox switching with smooth transitions
- TOD clock widget (expandable)
- Fog color matches sky

---

## Camera ✅

- Follow camera with zoom (default 1.0 shows full 10m hearing range)
- Smooth tracking

---

## Files Structure

```
ai/
├── tasks/
│   ├── chase_player.gd
│   ├── play_idle.gd
│   ├── move_to_position.gd
│   ├── select_random_position.gd
│   └── interruptible_wait.gd
└── trees/
    └── shopkeeper_ai.tres

npcs/
├── shopkeeper_npc.gd      # Main NPC controller
├── shopkeeper.tscn
├── head_look_at.gd        # Head tracking + debug line
└── perception_range.gd    # Vision/hearing visualization

systems/
├── npc_emotional_state.gd # 3-meter system
├── npc_perception.gd      # Sight/hearing + target_is_holding_item
├── npc_personality.gd     # Data-driven traits
├── shop_item.gd           # Stealable items (is_held, pickup)
└── simulation_save_manager.gd

items/
└── stealable_item.gd      # Base class (alternative to ShopItem)

player/
└── player_controller.gd   # WASD + E pickup/drop system

ui/
├── npc_info_panel.gd
├── npc_state_indicator.gd # Speech bubble
├── npc_data_store.gd      # Centralized state
└── npc_ui_utils.gd

plans/
├── limboai_bt_guide.md    # BT best practices
├── meters_design.md
├── competitive_analysis.md
└── progress.md            # This file
```

---

## Theft/Pickup System ✅ (NEW)

### Player Pickup
- Press **E** to pick up / drop items
- `is_holding_item()` method for detection
- Pickup prompt appears near items
- Items reparent to player when held

### ShopItem Integration
- Added `is_held` computed property
- Added to `stealable_items` group
- `pickup()` wrapper for compatibility

### Detection Flow
```
Raccoon exists → Shopkeeper sees → Suspicion ~50 → Alert, NO CHASE
Raccoon + Item → Shopkeeper sees → on_saw_stealing() → Suspicion 100 → CHASE!
```

---

## Next Steps

1. **Gameplay**: Item drop on catch, item return behavior
2. **AI**: Search behavior when player escapes  
3. **Audio**: Footsteps, alert sounds, honk
4. **Polish**: More NPC dialogue variety, catch animation
5. **Juice**: Screen shake on catch, particle effects
