# Meter System Design

## Three Meters

| Meter | Player Strategy | Range |
|-------|-----------------|-------|
| ⚡ Stamina | "Tire them out" | 100→0 |
| 👀 Suspicion | "Stay hidden" | 0→100 |
| 🔥 Temper | "Don't push too hard" | 0→100 |

## Thresholds

| Condition | Threshold | Effect |
|-----------|-----------|--------|
| `will_chase` | Suspicion ≥ 70 AND Stamina > 20 | Start chase |
| `will_give_up` | Stamina ≤ 20 | Stop chase, rest |
| `is_furious` | Temper ≥ 80 | Won't give up easily |

## Decay Rates (per second)
- Stamina recovery: +5 (idle), -15 (chasing)
- Suspicion decay: -5 toward baseline (10)
- Temper decay: -1.5 (slow - anger persists)

## Event Impacts
| Event | Suspicion | Temper |
|-------|-----------|--------|
| See player | +40 | +10 |
| See player + item | =100 | +25 |
| Hear noise | +15 | - |
| Chase failed | +20 | +15 |
| Catch player | - | -50 |

## Emergent Combos
| State | Meaning |
|-------|---------|
| High Sus + High Stam | DANGER - will chase hard |
| High Sus + Low Stam | Frustrated - knows but can't chase |
| Low Sus + Low Stam | Nap time - easy to sneak |
