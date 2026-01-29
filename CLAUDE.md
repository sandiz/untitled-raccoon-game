# Claude Notes

Quick-start for AI agents. **Start with `plans/progress.md`** for current state.

## Project Overview

**Untitled Raccoon Game** - Stealth/chaos game: raccoon steals from grumpy shopkeeper. Inspired by Untitled Goose Game with dynamic emotional meters.

**Engine:** Godot 4.5 + LimboAI behavior trees

## Docs

| Doc | Purpose |
|-----|---------|
| `plans/progress.md` | **START HERE** - Status, what works, next steps |
| `plans/limboai_bt_guide.md` | BT best practices and gotchas |
| `plans/meters_design.md` | 3-meter system (Stamina, Suspicion, Temper) |
| `plans/ui_design.md` | UI layout and components |
| `plans/visual.md` | Ghibli-style visual design |
| `plans/competitive_analysis.md` | Game comparisons |

## Directory Structure

```
ai/tasks/       # BT actions (chase, idle, move, wait)
ai/trees/       # .tres behavior tree resources
npcs/           # base_npc.gd, shopkeeper_npc.gd
systems/        # emotional, perception, save, time
player/         # controller + pickup (E key)
ui/             # info panel, speech bubble
```

## Critical Rules

### Code Reuse First
**MAXIM: Don't add new code unless you have to.**
- Always check if exact or nearby implementation exists first
- Search codebase before writing new functions
- Reuse existing patterns, extract shared logic
- Copy-paste with modification > new abstraction (for small code)
- If similar code exists in 2+ places, consider extracting to shared function

### NPC Movement - Use BaseNPC
```gdscript
extends BaseNPC  # NOT CharacterBody3D!
```
- `BaseNPC._physics_process()` calls `move_and_slide()` ONCE per frame
- BT tasks only set `velocity` - NEVER call `move_and_slide()` from tasks
- Override `_npc_physics_process(delta)` for custom behavior

### No Autoloads - Static Singletons
```gdscript
GameTime.get_instance().game_hour  # NOT $"/root/GameTime"
NPCDataStore.get_instance()
```

### Save System - Never Save Combat State
- Only save when idle (no chase, alertness < 0.3)
- Don't save: suspicion, alertness, temper, stamina
- On load: NPCs always start calm/idle
- See: `systems/simulation_save_manager.gd` (v2)

### Common Gotchas
```gdscript
# Animation names - no _Loop suffix at runtime
anim_player.play("default/Idle")  # Not "default/Idle_Loop"

# Rotation - use atan2, not Basis.looking_at()
var target_angle = atan2(direction.x, direction.z)

# Blackboard access
var emo = blackboard.get_var(&"emotional_state")  # Not agent.emotional_state

# Stopping movement - must call move_and_slide after
agent.velocity = Vector3.ZERO
agent.move_and_slide()

# Triangle winding for ImmediateMesh (CCW = faces up when viewed from +Y)
# For ground indicators: vertex order matters!
mesh.surface_add_vertex(center)
mesh.surface_add_vertex(edge1)  # First edge (smaller angle)
mesh.surface_add_vertex(edge2)  # Second edge (larger angle)
# NOT center -> edge2 -> edge1 (that faces DOWN)
```

### BT Interrupt Pattern
**Problem:** BTSelector doesn't re-evaluate earlier children when a lower-priority child is RUNNING. If Wander is running and a sound is heard, Investigate won't run until Wander completes.

**Solution:** Add abort checks in long-running tasks (MoveToPosition, InterruptibleWait):
```gdscript
func _tick(delta: float) -> Status:
    # Abort if higher-priority action needed
    var investigate_pos = blackboard.get_var(&"investigate_position", Vector3.INF)
    if investigate_pos != Vector3.INF:
        agent.velocity = Vector3.ZERO
        return FAILURE  # Allows selector to re-evaluate
    
    # ... rest of task logic
```
This pattern makes BT responsive to events even during long-running sequences.

### Collision Layers
| Layer | Purpose |
|-------|---------|
| 1 | Environment |
| 2 | NPCs |
| 4 | Player |
| 8 | Items |

## Key Systems

| System | File |
|--------|------|
| Emotional State | `systems/npc_emotional_state.gd` |
| Perception | `systems/npc_perception.gd` |
| Day/Night | `systems/day_night_cycle.gd` |
| Game Time | `systems/game_time.gd` (static singleton) |
| Save Manager | `systems/simulation_save_manager.gd` |

## Gameplay Flow

```
Raccoon picks up item → Shopkeeper SEES → Suspicion=100 → CHASE → Catch/Escape → Repeat
```

**Chase threshold:** Suspicion ≥ 70 AND Stamina > 20
