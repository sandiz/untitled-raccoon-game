# Claude Notes

Quick-start for AI agents. **Start with `plans/progress.md`** for current state.

## Project Overview

**Untitled Raccoon Game** - Stealth/chaos game: raccoon steals from grumpy shopkeeper.

**Engine:** Godot 4.5 + LimboAI behavior trees

## Docs

| Doc | Purpose |
|-----|---------|
| `plans/progress.md` | **START HERE** - Status, what works |
| `plans/meters_design.md` | 3-meter system (Stamina, Suspicion, Temper) |
| `plans/shopkeeper_ai.md` | BT structure, chase/search logic |
| `plans/limboai_bt_guide.md` | BT best practices and gotchas |
| `plans/ui_features.md` | Info panel, speech bubbles, widgets |

## Directory Structure

```
ai/tasks/       # BT actions (chase, idle, move, wait)
ai/trees/       # .tres behavior tree resources
npcs/           # base_npc.gd, shopkeeper_npc.gd, generic_npc.gd
systems/        # emotional, perception, footstep_audio, day_night
player/         # controller, Character_AnimationLibrary.tres
ui/             # info panel, speech bubble
```

## Critical Rules

### Always Make Todo List First
**Before starting any multi-step task, create a todo list.**

### Code Reuse First
**MAXIM: Don't add new code unless you have to.**
- Search codebase before writing new functions
- Reuse existing patterns, extract shared logic

### NPC Movement - Use BaseNPC
```gdscript
extends BaseNPC  # NOT CharacterBody3D!
```
- `BaseNPC._physics_process()` calls `move_and_slide()` ONCE per frame
- BT tasks only set `velocity` - NEVER call `move_and_slide()` from tasks

### No Autoloads - Static Singletons
```gdscript
GameTime.get_instance().game_hour  # NOT $"/root/GameTime"
```

### Save System - Never Save Combat State
- Only save when idle
- Don't save: suspicion, temper, stamina

### Common Gotchas
```gdscript
# Animation names - no _Loop suffix at runtime
anim_player.play("default/Idle")  # Not "default/Idle_Loop"

# Rotation
var target_angle = atan2(direction.x, direction.z)

# Blackboard access
var emo = blackboard.get_var(&"emotional_state")

# Stopping movement
agent.velocity = Vector3.ZERO
agent.move_and_slide()
```

### BT Interrupt Pattern
Add abort checks in long-running tasks:
```gdscript
func _tick(delta: float) -> Status:
    if _should_abort():
        return FAILURE
    # normal tick logic
```

## Animation Method Calls (Footsteps)

Footsteps use Godot's Animation Method Call tracks, not timers:
- `player/Character_AnimationLibrary.tres` has method tracks on Walk_Loop/Sprint_Loop
- Calls `_on_footstep()` on the AnimationPlayer's root_node parent
- Both player and NPCs implement `_on_footstep()` → `FootstepAudio.step()`

## Debug Keys

| Key | Action |
|-----|--------|
| T | Toggle debug item |
| N | Expand NPC info |
| 1-4 | Game speed |
