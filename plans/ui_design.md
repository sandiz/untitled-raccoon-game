# UI Design

## Style: Minimal Dark
- Background: `rgba(15, 15, 20, 0.92)`
- Text: `#F5F5F0` (cream white)
- Corners: 10px radius

## Layout
```
┌─────────────────────────────────────┐
│ [TOD Widget]      [NPC Info Panel]  │
│ top-left              top-right     │
│                                     │
│            GAME VIEW                │
│                                     │
│ [Period Toast]                      │
│ bottom-left                         │
└─────────────────────────────────────┘
```

## Components

### TOD Widget (V to expand)
- Clock + period name + progress bar
- Speed controls when expanded
- Jump to period buttons

### NPC Info Panel (N to expand)
- Portrait + name + state indicator
- Dialogue with typewriter effect
- 3 meter bars (Stamina, Suspicion, Temper)

### Speech Bubble (3D)
- SubViewport for crisp 2D text
- Priority system (LOW→CRITICAL)
- Floats above NPC head

## Key Files
- `ui/npc_info_panel.gd`
- `ui/tod_clock_widget.gd`
- `ui/npc_state_indicator.gd` (speech bubble)
