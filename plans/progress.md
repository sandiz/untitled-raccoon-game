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
| UI (Info Panel) | ✅ | `ui/npc_info_panel.gd` |
| Day/Night | ✅ | `systems/day_night_cycle.gd` |
| Save System | ✅ | `systems/simulation_save_manager.gd` (v2) |

---

## Key Mechanics

### Chase Trigger
- Suspicion ≥ 70 AND stamina > 20 → `will_chase = true`
- Seeing raccoon alone: +40 suspicion (max 65, NO chase)
- Seeing raccoon + item: suspicion = 100 → CHASE

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
npcs/             # base_npc.gd, shopkeeper_npc.gd
systems/          # emotional, perception, save, time
player/           # controller + pickup (E key)
ui/               # info panel, speech bubble, selection
```

---

## Next Steps
1. Item drop on catch, return behavior
2. Search behavior when player escapes
3. Audio (footsteps, alerts, honk)
4. Polish (animations, particles)
