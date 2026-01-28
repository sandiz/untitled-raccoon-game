# LimboAI BT Best Practices

## Critical Rules

### 1. Blackboard Variables Must Be Declared
Declare in `.tres` BlackboardPlan or get runtime errors:
```
var/chase_on_cooldown/type = 1  # bool
var/chase_cooldown_timer/type = 3  # float
```
Types: 1=bool, 2=int, 3=float, 4=String, 9=Vector3

### 2. NPC Movement - Use BaseNPC
```gdscript
extends BaseNPC  # NOT CharacterBody3D
```
- BaseNPC calls `move_and_slide()` ONCE per frame
- BT tasks only SET velocity, never call `move_and_slide()`
- Prevents sliding from multiple physics calls

### 3. Prevent Double-Triggering
Set cooldown IMMEDIATELY on catch, not after celebration:
```gdscript
if distance < stop_distance:
    blackboard.set_var(&"chase_on_cooldown", true)  # FIRST
    _caught_player = true
```

### 4. Long-Running Tasks Check Abort Conditions
BTSelector doesn't re-evaluate during RUNNING. Check internally:
```gdscript
func _tick(delta: float) -> Status:
    if emo and emo.will_chase:
        return FAILURE  # Abort to let chase run
```

### 5. Rotation Before Movement
Face target first, then move:
```gdscript
var angle_diff = abs(wrapf(target_angle - agent.rotation.y, -PI, PI))
if angle_diff > deg_to_rad(45):
    agent.velocity = Vector3.ZERO  # Rotate in place
else:
    agent.velocity = direction * speed  # Move
```

## Current BT Structure
```
BTRepeat (forever)
└── BTSelector
    ├── ChasePlayer       ← checks will_chase internally
    └── BTSequence
        ├── SelectRandomPosition
        ├── MoveToPosition
        ├── PlayIdle
        └── InterruptibleWait
```

## Common Gotchas
- Animation names: `"default/Idle"` not `"default/Idle_Loop"`
- Rotation: `atan2(dir.x, dir.z)` not `Basis.looking_at()`
- Blackboard access: `blackboard.get_var()` not `agent.emotional_state`
