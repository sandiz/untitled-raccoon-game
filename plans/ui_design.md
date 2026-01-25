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
┌─────────────────────┐
│ ☀  08:19           │
│    Morning          │
│    ████████░░░░░░░  │
│              [▼]    │
├─────────────────────┤  ← Expanded (V key)
│ Jump to period:     │
│ [🌅][☀][🌆][🌙]    │
├─────────────────────┤
│ [⏸ Pause]  1x [▲▼] │
└─────────────────────┘
```

**NPC Info Panel (top-right):**
```
┌─────────────────────────┐
│ ┌────┐ Bernard          │
│ │IMG │ The Grumpy       │
│ └────┘ Shopkeeper       │
├─────────────────────────┤
│ A quiet moment...       │
├─────────────────────────┤
│ "Another quiet day..."  │
├─────────────────────────┤
│ ● Idle                  │
│ 👁 Alert    ████░░░░    │
│ 😤 Annoyed  ██░░░░░░    │
│ 💤 Tired    █░░░░░░░    │
│ 🔍 Suspicious ░░░░░░░░  │
└─────────────────────────┘
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
| NPC Panel | 280px | 560px |
| Font (primary) | 22px | 44px |
| Font (secondary) | 14px | 28px |
| Portrait | 70px | 140px |
| Corner radius | 10px | 20px |
| Padding | 16px | 32px |

---

## Fixed Issues

- [x] Icon layout shift (fixed width)
- [x] Text layout shift (fixed height, clip_contents)
- [x] Portrait rounded corners (clip container)
- [x] Pause pauses world (Engine.time_scale)
- [x] Editor scale support
