# UI Features

## NPC Info Panel (DONE)

`ui/npc_info_panel.gd` + `ui/npc_info_manager.gd`

**Style:** Wildlife documentary + 4th wall breaking

**Shows:**
- Narrator describes NPC like nature documentary
- NPC breaks 4th wall, annoyed at being observed
- Emotion stats (alertness, annoyance, exhaustion, suspicion)
- Current state

Auto-shows when player near NPC or looking at one. Colors: BG #FFF8E1, Border #795548

---

## NPCPersonality Resource (.tres)

**Fields:**
- npc_id, display_name, title
- personality (grumpy/nervous/lazy/cheerful)
- alertness_modifier, annoyance_modifier (0.5-2.0)
- dialogue dict (keyed by event)
- narrator_lines dict (keyed by state)

**Bernard:** Grumpy, annoyance 1.3x, "MY CABBAGES! I mean- APPLES!"

---

## Game Speed Controls (DONE)

`systems/game_speed_manager.gd` - Press 1-4 for speed

| Key | Speed |
|-----|-------|
| 1 | 0.25x |
| 2 | 1x |
| 3 | 2x |
| 4 | 4x |

Shows brief indicator on change. Use `pause_for_menu()` / `resume_from_menu()` for pausing.

---

## Debug Overlay (TAB)

- NPC emotional bars
- Current state
- Target info
- FPS counter
