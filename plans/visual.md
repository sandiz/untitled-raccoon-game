# Visual Design

## Style: "Cozy Mischief"
Ghibli warmth + Untitled Goose Game mischief

- No harsh outlines, soft cel shading
- Warm desaturated pastels
- Soft shadows (25% darkening)

## Day/Night Cycle (10 min total)

| Period | Light | Sky | Mood |
|--------|-------|-----|------|
| Morning | Gold 0.7 | Pink→blue | Fresh |
| Afternoon | White 1.0 | Clear blue | Alert |
| Evening | Amber 0.6 | Orange→purple | Golden |
| Night | Blue 0.5 | Moonlit | Sneaky |

Transitions: 60 sec blend

## Night Settings
```gdscript
# TODSettings resource
night_light_color = Color(0.4, 0.5, 0.75)  # Blue moonlight
night_light_intensity = 0.5
night_ambient_color = Color(0.1, 0.15, 0.25)
```

## NPC State Indicators

| State | Icon | Color |
|-------|------|-------|
| Alert | ! | #FFCC00 |
| Suspicious | ? | #4D9EFF |
| Chasing | !! | #FF3333 |
| Tired | zzz | #999999 |

## Vision Cone
- 90° FOV, 10m range
- Fades in on NPC selection
- Orange when chasing, amber when suspicious
