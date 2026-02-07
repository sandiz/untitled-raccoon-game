# Emotional State System

## Current: 3 Meters

| Meter | Icon | Drives | Player Manipulates By |
|-------|------|--------|----------------------|
| **Stamina** | ⚡ | Chase duration, give up | Making them run/tire out |
| **Suspicion** | 🔍 | Detection, investigation | Being spotted, stealing |
| **Temper** | 🔥 | Aggression, chase speed | Failed chases, mischief |

## Decay/Growth

| Meter | Grows When | Decays When |
|-------|------------|-------------|
| Stamina | Idle, resting | Chasing, running |
| Suspicion | Seeing player, sounds | Time passes (5/sec toward 10) |
| Temper | Failed catches, theft | Time passes (1.5/sec, slow) |

## Emergent Combinations

| Stamina | Suspicion | Temper | Result |
|---------|-----------|--------|--------|
| High | High | High | **Dangerous** - Fast, aggressive, persistent |
| High | Low | Low | **Oblivious** - Has stamina but won't notice |
| Low | High | High | **Frustrated** - Wants to chase but can't |
| Low | Low | Low | **Exhausted** - Easy target |

## Thresholds

```gdscript
will_chase = witnessed_theft AND stamina > 20
will_give_up = stamina < 10
```

## Implementation

`systems/npc_emotional_state.gd` - Attached to each NPC
