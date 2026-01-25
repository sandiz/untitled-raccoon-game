# Claude Notes

Project-specific gotchas and conventions to avoid repeating mistakes.

---

## Directory Structure

```
test-5/
├── ai/                     # LimboAI behavior trees & tasks
│   ├── tasks/              # BTAction/BTCondition scripts
│   │   └── conditions/     # BTCondition checks
│   └── trees/              # .tres behavior tree resources
│       └── subtrees/       # Reusable BT fragments
├── data/                   # Data resources
│   └── personalities/      # NPCPersonality .tres files
├── debug/                  # Debug tools (F3 overlay, visualizers)
├── items/                  # Item scenes
├── npcs/                   # NPC scenes & scripts
├── plans/                  # Design docs (visual.md, ui_features.md, etc)
├── player/                 # Player scene, controller, animations
├── scenes/                 # Main scene(s)
├── scripts/                # Shared utility scripts
├── shaders/                # .gdshader files + material .tres
├── systems/                # Core game systems (emotional, perception, etc)
├── tests/                  # Test scripts
├── ui/                     # UI scenes & scripts
├── CLAUDE.md               # This file - gotchas & conventions
└── PROGRESS.md             # Current state & roadmap
```

---

## Scene Setup

### Floor is at Y = 0
- **NavigationRegion3D** transform should be `y = 0`
- **Floor surface** is at `y = 0`
- All characters (Player, NPCs) stand at `y = 0`

### Placing Objects on Ground
Objects need Y position = **half their height** to sit flush:

| Object Type | Formula | Example |
|-------------|---------|---------|
| Sphere | `y = radius` | radius 0.12 → y = 0.12 |
| Cylinder | `y = height / 2` | height 0.3 → y = 0.15 |
| Box | `y = height / 2` | height 0.25 → y = 0.125 |

### Collision Layers
| Layer | Purpose |
|-------|---------|
| 1 | Environment (walls, floor) |
| 2 | NPCs |
| 4 | Player |
| 8 | Items |

---

## Animation Names
Animation library `.tres` has names WITH `_Loop` suffix in resource_name, but when loaded via AnimationPlayer they appear **WITHOUT** the suffix.

Access as:
- `default/Idle` (not Idle_Loop)
- `default/Walk` (not Walk_Loop)
- `default/Sprint` (not Sprint_Loop)
- `default/Jog_Fwd` (not Jog_Fwd_Loop)
- `default/Celebration` (no suffix in .tres either)

**To verify available animations at runtime:**
```gdscript
var anim: AnimationPlayer = get_node("AnimationPlayer")
print(anim.get_animation_list())
```

---

## Common Gotchas

1. **GameTime autoload** - Use `get_node_or_null("/root/GameTime")` not global reference
2. **will_chase threshold** - Uses `>=` not `>` (suspicion adds exactly 0.3)
3. **BT blackboard vs agent.get()** - Use `blackboard.get_var(&"emotional_state")` NOT `agent.get("emotional_state")`. The emotional_state is stored in blackboard by shopkeeper_npc.gd.
4. **Perception (UGG-style)** - Single FOV cone only (120°, 8m). No peripheral vision. Detection only happens when target is inside the visible cone.
5. **Character rotation** - Use `atan2(direction.x, direction.z)` for facing direction. Do NOT use `Basis.looking_at()` as it assumes -Z forward which flips the model 180°:
   ```gdscript
   var target_angle = atan2(direction.x, direction.z)
   agent.rotation.y = lerp_angle(agent.rotation.y, target_angle, delta * 10.0)
   ```
6. **BT state transitions** - If a task has post-action state (like celebration after catch), check that state FIRST in `_tick()` before any guard conditions. Otherwise the guard (e.g., `will_chase`) may fail after state change and skip the post-action.
7. **State vs Animation conflict** - `set_current_state()` triggers `_play_state_animation()`. Perception callbacks (like `_on_target_spotted`) can fire during BT tasks and override animations. Solution: Guard callbacks to skip state changes when in higher-priority states like "chasing":
   ```gdscript
   func _on_target_spotted(target, spot_type):
       if current_state == "chasing":
           return  # Don't downgrade from chase
   ```

---

## Key Systems

| System | Files | Notes |
|--------|-------|-------|
| Emotional State | `systems/npc_emotional_state.gd` | alertness, annoyance, exhaustion, suspicion |
| Perception | `systems/npc_perception.gd` | 120° FOV, 8m range, sound detection |
| Social | `systems/npc_social.gd` | NPC-to-NPC alerts |
| Day/Night | `systems/day_night_cycle.gd` | 10 min cycle, 4 periods |
| Game Speed | `systems/game_speed_manager.gd` | Keys 1-4 for 0.25x-4x |
| Toon Shading | `shaders/toon.gdshader`, `outline.gdshader` | Ghibli style |
| NPC Info Panel | `ui/npc_info_panel.gd` | Wildlife documentary style |
| Vision Indicator | `npcs/vision_indicator.gd` | Ground glow on alert/chase |

---

## Behavior Tree Architecture

### Current Working BT (Simplified)
```
BTRepeat (forever)
└── BTSelector
    ├── chase_player   ← checks will_chase internally, catches at 1.5m
    └── Seq_Wander     ← select → move → idle → wait
```

**Key insight:** BTCondition scripts were not loading properly. Solution: put the will_chase check inside chase_player._tick() instead of using a separate BTCondition.

### BT Best Practices
- **BTRepeat with times=0** wraps the root for infinite loop
- **BTSelector** tries children in order until one succeeds
- **Long-running tasks** should check abort conditions (like will_chase) internally since BTSelector doesn't re-evaluate during RUNNING
- **Build incrementally** - test each step before adding complexity

### Future: Full Priority Structure
```
BTSelector [ROOT]
├── [P1: CHASE]       ← guard: will_chase
├── [P2: RESTORE]     ← guard: has_displaced_items
├── [P3: INVESTIGATE] ← guard: has_sound
├── [P4: TASK]        ← guard: has_active_task
└── [P5: IDLE]        ← fallback
```
