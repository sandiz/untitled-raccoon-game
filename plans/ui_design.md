# UI Design Plan - Game HUD

## Problem
The TOD widget and NPC info panel have inconsistent styles - they look like they're from different games.

## Goal
Create a cohesive visual language for all UI elements that fits the **Ghibli-style raccoon game** aesthetic.

---

## Style Options

### Style 1: "Parchment/Storybook" 📜
Warm, hand-drawn feel like a nature documentary or children's book.

**Colors:**
- Background: Cream/parchment `#FFF8E7`
- Border: Warm brown `#8B7355`
- Text: Dark brown `#3E2723`
- Accent: Period-colored highlights

**TOD Widget:**
```
╭─────────────────────╮
│  ☀ 08:19            │
│  Morning            │
│  ▓▓▓▓▓▓░░░░░░░░░░░  │
├─────────────────────┤
│ ◉Mor ○Aft ○Eve ○Nig │
│ [▶ Pause]   [1x ▼]  │
╰─────────────────────╯
```

**NPC Info Panel:**
```
╭───────────────────────────╮
│ ┌────┐  Bernard           │
│ │ 😠 │  The Grumpy        │
│ └────┘  Shopkeeper        │
├───────────────────────────┤
│ ❝ Another quiet day... ❞  │
├───────────────────────────┤
│ Mood: 😤 Annoyed          │
│ Alert ▓▓▓░░░  Tired ▓░░░░ │
╰───────────────────────────╯
```

---

### Style 2: "Minimal Dark" 🌑
Clean, modern, semi-transparent dark panels. Like Zelda BOTW / modern indie games.

**Colors:**
- Background: Dark translucent `rgba(20,20,25,0.85)`
- Border: Subtle gray `#444`
- Text: White/cream `#F5F5F0`
- Accent: Period colors (gold, white, coral, blue)

**TOD Widget:**
```
┌───────────────────┐
│ ☀ 08:19  Morning  │
│ ████████░░░░░░░░░ │
├───────────────────┤
│ [🌅][☀][🌆][🌙]   │
│ ⏸ Pause   1x ▾    │
└───────────────────┘
```

**NPC Info Panel:**
```
┌─────────────────────────┐
│ BERNARD                 │
│ The Grumpy Shopkeeper   │
├─────────────────────────┤
│ "Another quiet day..."  │
├─────────────────────────┤
│ ● IDLE                  │
│ 👁 ████░░  😤 ██░░░░    │
│ 💤 █░░░░░  🔍 ░░░░░░    │
└─────────────────────────┘
```

---

### Style 3: "Ghibli Watercolor" 🎨
Soft edges, muted colors, hand-painted feel. Most thematic but hardest to implement.

**Colors:**
- Background: Soft sage green `#E8F0E8` or sky blue `#E8F4F8`
- Border: Soft brown with rounded corners `#A89080`
- Text: Charcoal `#4A4A4A`
- Shadows: Soft drop shadows

**TOD Widget:**
```
  ╭───────────────────╮
 ╱  ☀  08:19          │
│   Morning           │
│   ═══════════░░░░░  │
│─────────────────────│
│  🌅  ☀  🌆  🌙      │
│      ▲              │
│  ▷ Play    ×1       │
 ╲____________________╯
```

**NPC Info Panel:**
```
  ╭─────────────────────────╮
 ╱  Bernard                 │
│   ~ The Grumpy Shopkeeper │
│───────────────────────────│
│   𝘈 𝘲𝘶𝘪𝘦𝘵 𝘮𝘰𝘮𝘦𝘯𝘵...       │
│                           │
│   "Why are you staring?"  │
│───────────────────────────│
│   😤 Annoyed              │
│   ════════░░░░ Alert      │
 ╲__________________________╯
```

---

### Style 4: "Retro Pixel" 👾
Chunky, pixel-art inspired. Fun but may clash with Ghibli 3D style.

**Colors:**
- Background: Dark blue `#1a1a2e`
- Border: Bright accent `#e94560`
- Text: White `#fff`

*(Probably skip this one for Ghibli aesthetic)*

---

## Recommended: Style 2 (Minimal Dark)

**Why:**
1. **Readable** - High contrast, easy to read at a glance
2. **Non-intrusive** - Dark panels don't distract from gameplay
3. **Scalable** - Works at different resolutions
4. **Easy to implement** - Simple StyleBoxFlat, no custom textures
5. **Professional** - Clean, modern look

---

## Layout Positions

```
┌─────────────────────────────────────────────────────────┐
│ [TOD Widget]                          [NPC Info Panel]  │
│ Top-left                                     Top-right  │
│ ~200px wide                                  ~350px wide│
│                                                         │
│                                                         │
│                     GAME VIEW                           │
│                                                         │
│                                                         │
│                                                         │
│ [Period Toast]              [Game Speed] Bottom-right   │
│ Bottom-left                                             │
└─────────────────────────────────────────────────────────┘
```

---

## Sizing Guidelines

| Element | Width | Notes |
|---------|-------|-------|
| TOD Widget (collapsed) | 180-200px | Time + period + progress |
| TOD Widget (expanded) | 200-220px | + controls |
| NPC Info Panel | 320-380px | Name, dialogue, stats |
| Font size (primary) | 18-24px | Names, time |
| Font size (secondary) | 14-16px | Labels, subtitles |
| Font size (small) | 12px | Stat labels |
| Padding | 12-16px | Consistent margins |
| Border radius | 6-8px | Soft corners |
| Border width | 1-2px | Subtle frame |

---

## Decision Needed

**Pick a style:**
- [ ] Style 1: Parchment/Storybook
- [x] Style 2: Minimal Dark ✅ CHOSEN
- [ ] Style 3: Ghibli Watercolor
- [ ] Mix: (describe)

**Pick NPC panel info density:**
- [x] A: Full (portrait + narrator + dialogue + all 4 stat bars) ✅ CHOSEN
- [ ] B: Medium (name/title + dialogue + mood indicator + 2 main stats)
- [ ] C: Minimal (name + state + single mood bar)

---

## Next Steps
1. Pick style
2. Pick info density
3. I'll implement both widgets with consistent styling
