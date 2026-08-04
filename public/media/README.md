# Media slots

Drop files here with these exact names and they appear on the site. Anything missing shows a
labelled placeholder instead of breaking the layout, so you can fill them in any order.

| File | Where it shows | Ideal size |
|------|----------------|-----------|
| `hero.jpg` | full-bleed behind the title | 2400x1350, landscape, keep the centre uncluttered — text sits over the lower left |
| `trailer.mp4` | gameplay video section | 1920x1080, H.264, under ~20 MB |
| `trailer-poster.jpg` | still shown before the video plays | 1920x1080 |
| `shot-01.jpg` … `shot-04.jpg` | screenshot grid | 1920x1080 |
| `shot-05.jpg` | beside "The rest of it" | 1920x1080 |
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
