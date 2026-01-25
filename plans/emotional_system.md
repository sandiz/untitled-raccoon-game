# Emotional State System

## Current Implementation (4 meters)

| Meter | Icon | Drives | Issues |
|-------|------|--------|--------|
| Alertness | 👁 | Detection speed | Overlaps with Suspicion |
| Annoyance | 😤 | Aggression | OK |
| Exhaustion | 💤 | Give up behavior | OK |
| Suspicion | 🔍 | Investigation | Overlaps with Alertness |

## Proposed System (3 meters)

Simpler, more emergent:

| Meter | Icon | Drives | Player manipulates by |
|-------|------|--------|----------------------|
| **Energy** | ⚡ | Chase duration, give up threshold | Making them run/tire out |
| **Agitation** | 🔥 | Aggression, detection speed, chase speed | Mischief, being spotted, stealing |
| **Awareness** | 👀 | FOV size, reaction time, search thoroughness | Distractions, hiding, sneaking |

## Emergent Combinations

| Energy | Agitation | Awareness | Result |
|--------|-----------|-----------|--------|
| High | High | High | **Dangerous** - Fast, aggressive, hard to escape |
| High | Low | Low | **Oblivious** - Has stamina but won't notice you |
| Low | High | High | **Frustrated** - Wants to chase but can't, gives up angry |
| Low | Low | Low | **Exhausted** - Easy target, slow reactions |
| Mid | High | Low | **Reckless** - Charges blindly, easy to evade |
| Mid | Low | High | **Vigilant** - Watches carefully but won't chase hard |

## State Thresholds

```
if agitation > 0.7 and awareness > 0.5:
    state = "chasing"
elif agitation > 0.5 and awareness > 0.3:
    state = "investigating"  
elif awareness > 0.6:
    state = "alert"
elif energy < 0.2:
    state = "exhausted"
else:
    state = "idle"
```

## Decay/Growth Rates

| Meter | Grows when | Decays when |
|-------|------------|-------------|
| Energy | Resting, idle | Chasing, running |
| Agitation | Seeing player, items stolen, hearing sounds | Time passes, nothing happens |
| Awareness | Sounds, movement in periphery, suspicion | Time passes, distracted |

## Decision Needed

Switch from 4 meters to 3 meters?
- [ ] Yes - Implement 3-meter system
- [ ] No - Keep current 4 meters
- [ ] Other - (describe)
