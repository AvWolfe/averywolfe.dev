# Media slots

Drop files here with these exact names and they appear on the site. Anything missing shows a
labelled placeholder instead of breaking the layout, so you can fill them in any order.

| File | Where it shows | Ideal size |
|------|----------------|-----------|
| `hero.jpg` | full-bleed behind the title | 2400x1350, landscape, keep the centre uncluttered — text sits over the lower left |
| `trailer.mp4` | gameplay video section | 1920x1080, H.264, under ~20 MB |
| `trailer-poster.jpg` | still shown before the video plays | 1920x1080 |
| `clip-augment-naming.mp4` | clip grid — mods in/out, name rebuilding | 720p, ~5-8s |
| `clip-ability.mp4` | clip grid — an ability resolving | 720p, ~5-8s |
| `clip-colliders.mp4` | clip grid — walking with collision shapes shown | 720p, ~5-8s |
| `clip-*.jpg` | poster frame for each clip (made automatically) | 720p |
| `shot-05.jpg` | beside "The rest of it" | 1920x1080 |

Clips are cut with `tools/make-clip.sh`, which also writes the poster:

```bash
tools/make-clip.sh media-src/battle.avi 00:01:12 6 augment-naming
```

They play muted and looped like a GIF. Don't use actual .gif — a 5s 720p GIF of game footage is
20-50 MB against roughly 0.9 MB for the same thing as MP4, and GIF is capped at 256 colours.
| `system-ai.jpg` | beside the enemy AI section | 1920x1080 |
| `system-mods.jpg` | beside the modding section | 1920x1080 |
| `system-augments.jpg` | beside the augment section — a loadout/inventory screen works well | 1920x1080 |

All slots are 16:9. Other ratios get cropped to fill, centred.

Keep each image under ~400 KB if you can — `sips -Z 1920 shot.png --out shot.jpg` on macOS, or any
exporter at ~80% JPEG quality. The whole page should stay light enough to load fast on a phone.

To use a video as the hero instead of an image, swap the `<img>` inside `.hero .bg` for:

```html
<video autoplay muted loop playsinline poster="media/hero.jpg">
  <source src="media/hero.mp4" type="video/mp4">
</video>
```
