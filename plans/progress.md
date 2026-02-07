# Progress

## Current State: Core Loop Complete ✅

Shopkeeper wanders → Sees raccoon with item → Chases → Catch/Escape → Repeat

---

## Systems Status

| System | Status | Key Files |
|--------|--------|-----------|
| BT AI | ✅ | `ai/tasks/*.gd`, `ai/trees/shopkeeper_ai.tres` |
| Emotional State | ✅ | `systems/npc_emotional_state.gd` (3 meters) |
| Perception | ✅ | `systems/npc_perception.gd` |
| Theft Detection | ✅ | Player pickup + NPC sees item = chase |
| Animation | ✅ | `npcs/shopkeeper_animator.gd` |
| UI (Info Panel) | ✅ | `ui/npc_info_panel.gd` |
| Day/Night | ✅ | `systems/day_night_cycle.gd` |
| Save System | ✅ | `systems/simulation_save_manager.gd` |
| Footsteps | ✅ | `systems/footstep_audio.gd` (notify-based) |

---

## Footstep System

**Notify-based** via Animation Method Calls (not timers):
- Walk_Loop and Sprint_Loop call `_on_footstep()` at keyframes
- Calls `FootstepAudio.step()` which plays sound + spawns dust
- CPUParticles3D dust puffs (web-compatible)
- Distance check: dust only shows within 15m of camera
- Surface types: grass (player) vs concrete (NPCs)
- Pitch variation: player 1.4 (high), NPCs 0.8-0.95 (low)

Files: `systems/footstep_audio.gd`, `player/Character_AnimationLibrary.tres`

---

## 3 Meters

| Meter | Trigger | Decay |
|-------|---------|-------|
| Stamina | Drains during chase | Recovers when idle |
| Suspicion | Seeing player | 5/sec toward 10 |
| Temper | Failed chases | 1.5/sec (slow) |

---

## Chase Trigger

- `witnessed_theft = true` (NPC must have seen stealing)
- Stamina > 20 → `will_chase = true`
- Seeing raccoon alone: awareness only, NO chase
- Seeing raccoon + item: `witnessed_theft = true` → CHASE

---

## Key Architecture

### Component Pattern
```
ShopkeeperNPC
├── NPCEmotionalState    # Meters: stamina, suspicion, temper
├── NPCPerception        # Sight, detection
├── ShopkeeperAnimator   # Animation state machine
└── FootstepAudio        # Notify-based audio + dust
```

### Static Singleton (No Autoloads)
```gdscript
static var _instance: ClassName = null
static func get_instance() -> ClassName
```

### NPC Movement
All NPCs extend `BaseNPC` - single `move_and_slide()` per frame.

---

## File Structure
```
ai/tasks/         # BT actions (chase, idle, move, wait)
npcs/             # base_npc.gd, shopkeeper_npc.gd, generic_npc.gd
systems/          # emotional, perception, footstep_audio, day_night
player/           # controller, Character_AnimationLibrary.tres
ui/               # info panel, speech bubble, selection
```

---

## Debug Keys

| Key | Action |
|-----|--------|
| T | Toggle debug item in hand |
| N | Expand NPC info panel |
| 1-4 | Game speed (0.25x to 4x) |
