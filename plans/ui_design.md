# UI Design Plan - Game HUD

## Status: ✅ Implemented

Chose **Style 2: Minimal Dark** with **Full info density**.

---

## Implemented Style

### Colors
- **Background:** `rgba(15, 15, 20, 0.92)` - Dark translucent
- **Border:** `rgba(65, 65, 75, 0.9)` - Subtle gray
- **Text:** `#F5F5F0` - Cream white
- **Subtitle:** `rgba(180, 170, 160)` - Muted
- **Corners:** 10px radius (scaled)

### Components

**TOD Widget (top-left):**
```
Collapsed:
┌──────────────────────────┐
│ ☀  08:19           1x  ▼│
│               10m=24h    │
│    Morning               │
│    ████████░░░░░░░       │
└──────────────────────────┘

Expanded (V key):
┌──────────────────────────┐
│ ☀  08:19           1x  ▲│
│               10m=24h    │
│    Morning               │
│    ████████░░░░░░░       │
├──────────────────────────┤
│ Jump to period:          │
│ [🌅][☀][🌆][🌙]         │
├──────────────────────────┤
│ [⏸ Pause]  1x [▲▼]      │
└──────────────────────────┘

Speed shows "⏸" when paused.
1x/10m=24h stacked vertically, right-aligned.
```

**NPC Info Panel (top-right):**
```
Collapsed (default):
┌──────────────────────────────┐
│ ┌────┐ Bernard         [▼]  │
│ │IMG │ The Grumpy           │
│ └────┘ Shopkeeper  ● Idle   │
└──────────────────────────────┘

Expanded (N key):
┌──────────────────────────────┐
│ ┌────┐ Bernard         [▲]  │
│ │IMG │ The Grumpy           │
│ └────┘ Shopkeeper  ● Idle   │
├──────────────────────────────┤
│ 🤔 A quiet moment...         │  ← Narrator
├──────────────────────────────┤
│ 💬 Another quiet day...      │  ← Dialogue (typewriter)
├──────────────────────────────┤
│ 👁 Alert    ████░░░░         │
│ 😤 Annoyed  ██░░░░░░         │
│ 💤 Tired    █░░░░░░░         │
│ 🔍 Suspicious ░░░░░░░░       │
└──────────────────────────────┘

- Starts collapsed by default
- Typewriter effect on narrator/dialogue text
- Expand button is flat style, releases focus
```

---

## Layout Positions

```
┌─────────────────────────────────────────────────────────┐
│ [TOD Widget]                          [NPC Info Panel]  │
│ Top-left                                     Top-right  │
│ ~220px wide                                  ~280px wide│
│                                                         │
│                     GAME VIEW                           │
│                                                         │
│ [Period Toast]                                          │
│ Bottom-left                                             │
└─────────────────────────────────────────────────────────┘
```

---

## Sizing (with 2x scale)

| Element | Base | Scaled |
|---------|------|--------|
| TOD Widget | 220px | 440px |
| NPC Panel | 300px | 600px |
| Font (primary) | 22px | 44px |
| Font (secondary) | 14px | 28px |
| Portrait | 70px | 140px |
| Corner radius | 10px | 20px |
| Padding | 16px | 32px |

---

## Fixed Issues

- [x] Icon layout shift (fixed width)
- [x] Text layout shift (fixed height, clip_contents)
- [x] Portrait rounded corners (clip container with white bg)
- [x] Portrait dimming (use opaque white bg, not transparent)
- [x] Pause pauses world (Engine.time_scale)
- [x] Editor scale support
- [x] NPC panel fold/expand (N key or button)
- [x] Title word wrap instead of ellipsis truncation
- [x] Button focus release (all buttons release_focus after click)
- [x] State label layout shift (fixed minimum width)
- [x] Dialogue state mapping ("alert" → "spotted", "searching" → "lost")
- [x] TOD collapsed view shows speed (1x/2x/⏸) and ratio (10m=24h)
- [x] Speed controls support sub-1x speeds (0.1x, 0.25x, 0.5x)
- [x] Speech bubble tail renders behind panel (no transparency artifacts)
- [x] Widget sync via NPCDataStore (static singleton, no autoload)
- [x] BaseWidget base class for shared styling
