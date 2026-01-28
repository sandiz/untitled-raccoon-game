# Claude Notes

Quick-start guide for AI agents working on this project. Read this first, then follow links for details.

---

## Project Overview

**Untitled Raccoon Game** - A stealth/chaos game where you play as a raccoon stealing from a grumpy shopkeeper. Inspired by Untitled Goose Game but with dynamic emotional meters.

**Engine:** Godot 4.5 with LimboAI for behavior trees

---

## Documentation Index

### Current State & Roadmap
| Doc | Purpose |
|-----|---------|
| `plans/progress.md` | **START HERE** - Current state, what's working, next steps |

### Design Documents
| Doc | Purpose |
|-----|---------|
| `plans/meters_design.md` | 3-meter emotional system (Stamina, Suspicion, Temper) |
| `plans/emotional_system.md` | Emotional state architecture |
| `plans/shopkeeper_ai.md` | Shopkeeper AI behavior design |
| `plans/competitive_analysis.md` | Comparison with Untitled Goose Game |

### Technical Guides
| Doc | Purpose |
|-----|---------|
| `plans/limboai_bt_guide.md` | **IMPORTANT** - BT best practices and gotchas |
| `plans/selection_system.md` | NPC selection and camera system |

### UI/Visual Design
| Doc | Purpose |
|-----|---------|
| `plans/visual.md` | Ghibli-style visual design |
| `plans/ui_design.md` | UI architecture and components |
| `plans/ui_features.md` | UI feature specifications |

---

## Directory Structure

```
untitled-raccoon-game/
├── ai/                     # LimboAI behavior trees and tasks
│   ├── tasks/              # BTAction scripts (chase, idle, move, etc)
│   └── trees/              # .tres behavior tree resources
├── data/personalities/     # NPCPersonality .tres files
├── items/                  # Stealable item scripts
├── npcs/                   # NPC scenes and scripts (shopkeeper)
├── plans/                  # Design docs (see index above)
├── player/                 # Player controller and pickup system
├── scenes/                 # Main game scene
├── shaders/                # Toon shader, outline shader
├── systems/                # Core systems (emotional, perception, etc)
├── ui/                     # UI components (info panel, speech bubble)
└── CLAUDE.md               # This file
```

---

## Essential Gotchas

### Animation Names
Animation library has `_Loop` suffix in .tres but loads WITHOUT it:
```gdscript
anim_player.play("default/Idle")  # Not "default/Idle_Loop"
```

### Character Rotation
Use `atan2(direction.x, direction.z)` - NOT `Basis.looking_at()` which flips 180 degrees:
```gdscript
var target_angle = atan2(direction.x, direction.z)
agent.rotation.y = lerp_angle(agent.rotation.y, target_angle, delta * 10.0)
```

### BT Blackboard
Access emotional_state via blackboard, not agent:
```gdscript
var emotional_state = blackboard.get_var(&"emotional_state")  # CORRECT
```

### Stopping Movement
Always call move_and_slide() after setting velocity to zero:
```gdscript
agent.velocity = Vector3.ZERO
agent.move_and_slide()  # Required to actually stop!
```

### NPC Movement (IMPORTANT - Prevents Sliding!)
All NPCs should extend `BaseNPC` which handles movement correctly:
```gdscript
extends BaseNPC  # NOT CharacterBody3D!
```

**Rules:**
- `BaseNPC._physics_process()` calls `move_and_slide()` ONCE per frame
- BT tasks only set `velocity` - NEVER call `move_and_slide()` from BT tasks
- Override `_npc_physics_process(delta)` for custom NPC behavior
- Use `stop_movement()` helper to safely zero velocity

**Why?** Calling `move_and_slide()` multiple times per frame causes physics instability and sliding.

### No Autoloads - Use Static Singletons
**NEVER use Godot autoloads** - they tie code to Godot's project settings and make testing harder.

Use the static singleton pattern instead:
```gdscript
class_name GameTime
extends Node

static var _instance: GameTime = null

static func get_instance() -> GameTime:
    if _instance == null:
        _instance = GameTime.new()
        # Add to tree so _process runs
        if Engine.get_main_loop():
            Engine.get_main_loop().root.call_deferred("add_child", _instance)
    return _instance
```

**Usage:** `GameTime.get_instance().game_hour`

**Examples:** `GameTime`, `NPCDataStore`

### Save System - Never Save Combat/Active State
**NEVER save transient runtime values** like emotional state, alert levels, or mid-action data.

**Rules:**
- Only save when game is in safe/idle state (no combat, no chase)
- Don't save: suspicion, alertness, temper, stamina, chase state
- DO save: positions, time of day, camera, persistent progress
- On load: always restore NPCs to calm/idle state

**Why?** No game allows saving during combat. Restoring transient state causes bugs like:
- NPC chasing player immediately on load
- Broken AI state machines
- Confusing player experience

**Current implementation:** `SimulationSaveManager` (v2)
- Won't save if any NPC has alertness > 0.3
- Won't save if any NPC is in active state (chasing, alerted)
- Emotional state is NOT restored - each session starts calm

### Collision Layers
| Layer | Purpose |
|-------|---------|
| 1 | Environment (walls, floor) |
| 2 | NPCs |
| 4 | Player |
| 8 | Items (stealable) |

### Floor is Y = 0
All characters stand at Y = 0. Objects need y = height/2 to sit flush.

---

## Key Systems

| System | File | Notes |
|--------|------|-------|
| Emotional State | `systems/npc_emotional_state.gd` | Stamina, Suspicion, Temper meters |
| Perception | `systems/npc_perception.gd` | 90 deg FOV, 10m range, target_is_holding_item |
| Shop Items | `systems/shop_item.gd` | Stealable items with is_held property |
| Player Pickup | `player/player_controller.gd` | E key to pick up/drop |
| Day/Night | `systems/day_night_cycle.gd` | 10 min cycle, 4 periods |
| Game Time | `systems/game_time.gd` | Static singleton - `GameTime.get_instance()` |
| NPC Data Store | `ui/npc_data_store.gd` | Static singleton - `NPCDataStore.get_instance()` |

---

## Current Gameplay Flow

```
Raccoon wanders -> Picks up item (E) -> Shopkeeper SEES theft ->
Suspicion = 100 -> CHASE! -> Catch or Escape -> Cooldown -> Repeat
```

**Key threshold:** Shopkeeper only chases when suspicion >= 70. Seeing raccoon WITH item triggers on_saw_stealing() which sets suspicion to 100.

---

## For More Details

1. **What's done/next?** -> `plans/progress.md`
2. **BT issues?** -> `plans/limboai_bt_guide.md`
3. **Meter system?** -> `plans/meters_design.md`
4. **UI components?** -> `plans/ui_design.md`
