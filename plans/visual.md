# Visual Design

## Style: "Cozy Mischief"
Mischief sim + Studio Ghibli = warm, hand-crafted stealth comedy

### Core Look
- **No Outlines**: Clean pastel aesthetic without harsh edges
- **Shading**: Soft cel/toon with gentle shadow transitions
- **Colors**: Warm, slightly desaturated, nostalgic pastels
- **Skies**: Painterly gradients, brushstroke clouds
- **Shadows**: Soft, diffused (25% darkening only)

### References
Untitled Goose Game (mischief) + Ghibli (warmth) + Animal Crossing (pastel)

---

## Color Palette

| Element | Hex | Use |
|---------|-----|-----|
| Grass | #8BC34A | Environment |
| Path | #D7CCC8 | Ground |
| Wood | #BCAAA4 | Props |
| Walls | #FFF8E1 | Buildings |
| Accent | #1565C0 | Doors, details |

---

## Day/Night Cycle

**Duration:** 10 min total (2.5 min each period)
**Transitions:** 30 sec gradual blend
**Pauses:** Menus + dialogue

| Time | Light Color | Intensity | Sky | Mood |
|------|-------------|-----------|-----|------|
| Morning | #FFD700 gold | 0.7 | Pink→orange→blue | Fresh, misty |
| Afternoon | #FFFEF0 white | 1.0 | Clear blue | Bright, alert |
| Evening | #FF7F50 amber | 0.6 | Orange→purple | Golden hour |
| Night | #6495ED blue | 0.25 | Navy, stars | Sneaky |

**TOD Change Cue:** Subtle UI + soft chime + brief text ("Evening...")

---

## NPC Vision Indicators

| State | Ground Effect | Target Marker |
|-------|---------------|---------------|
| Idle | None | None |
| Suspicious | Amber glow #FFB300 @20% | Yellow ring |
| Chasing | Orange cone #FF6600 @40% | Red ring |

---

## NPC Floating Icons

| State | Symbol | Color |
|-------|--------|-------|
| Alert | ! | #FFCC00 |
| Suspicious | ? | #4D9EFF |
| Chasing | !! | #FF3333 |
| Tired | zzz | #999999 |
| Calm | ♪ | #66CC66 |

Pop-in animation, gentle bob, billboard to camera.

---

## Player Creature

**Status:** TBD, swappable

| Trait | Value |
|-------|-------|
| Type | Fantasy/Ghibli creature (raccoon valid) |
| Size | Small, knee-height |
| Shape | Round, chubby, Totoro-like |
| Carrying | Backpack (items poke out) |

---

## Tech Implementation

### Shaders
- `shaders/toon.gdshader` - Soft cel shading with gentle shadows
- `shaders/selection_ring.gdshader` - Crisp cyan circle for selected NPCs
- `scripts/ghibli_shader_applier.gd` - Auto-applies toon shader to meshes

**Toon Shader Settings:**
- `shadow_strength = 0.25` - Shadows only 25% darker than lit areas
- `shadow_threshold = 0.4` - Where shadow edge falls
- Soft, readable shadows - pastel aesthetic without outlines

**Design Decision:** Outlines were tested (inverted hull + post-process) but dropped in favor of clean pastel look. The soft cel shading provides enough definition without harsh edges.

**Scene-Wide Application:**
- `SceneShaderApplier` node in main.tscn with `scene_wide = true`
- `watch_for_new = true` - Auto-applies to newly generated meshes
- Excludes: floor, ground, terrain, selection, vision, water, particles

### Day/Night Cycle (DONE)
- `systems/day_night_cycle.gd` - 10 min cycle, 4 periods, 30s transitions
- `ui/tod_notification.gd` - Subtle "Morning..." fade text on period change
- `ui/tod_clock_widget.gd` - Bottom-left widget with period buttons + auto toggle
- Pauses via `DayNightCycle.pause()` / `resume()`

### Vision Indicator (DONE)
- `shaders/vision_cone.gdshader` - Radial cone glow with pulse
- `npcs/vision_indicator.gd` - Amber/orange color by state
- Immediately hides when returning to idle

### Selection Ring (DONE)
- `shaders/selection_ring.gdshader` - Crisp cyan circle outline
- `npcs/selection_ring.gd` - Show/hide with fade animation
- Only visible for selected NPCs
