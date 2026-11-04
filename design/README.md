# Design sources

## App icon

A white globe with a play sign in its centre, on the app's cinema background. The drawing comes
from an image model, from Martín's brief: [`app-icon-original.png`](app-icon-original.png) (on
blue, as it was drawn) and its traced SVG export [`app-icon-original.svg`](app-icon-original.svg).

The app builds from the Icon Composer document
[`StreamIn/Resources/AppIcon.icon`](../StreamIn/Resources/AppIcon.icon), which rebuilds the
original in layers so iOS can make the dark, clear and tinted appearances:

- **Background:** the cinema look of every screen (`CinemaBackground`): the document's gradient
  fill, warm near-black from `#302115` at the top to `#0E0B0A`, under `spotlight.png`, accent
  gold at 38 % fading out from the top centre (`scripts/make-icon-spotlight.swift`). Change the
  colours in `icon.json` → `fill`.
- **The spotlight is a PNG on purpose.** As an SVG radial gradient it looked right in Icon
  Composer and `ictool`, but Xcode's icon compiler ignored its centre and drew a disc in the
  middle of the icon on the device. Check icon changes on the simulator, not only in renders.
- **Plain white, flat:** no glass, specular highlights, translucency or shadows on any layer
  (Martín's call), so the artwork stays exactly as drawn.
- **`globe.svg`** (back group) and **`play.svg`** (front group): vector layers split out of the
  traced SVG by `scripts/split-icon-svg.py`. The trace draws the globe as a white disc under dark
  patches, so the splitter turns the patches into a mask: the lines alone, on transparency.
  The trace's background paths are dropped for the gradient fill. To recolour the lines or the
  play sign, change `fill` in their SVG.

Render every appearance (Default, Dark, Tinted, Clear) to PNGs without a device:

```bash
scripts/render-app-icon.sh
```

## Launch screen

The landing page's background colour and nothing else (`UILaunchScreen` in
`StreamIn/Info.plist`). Its `LaunchBackground` colour set must match DesignSystem's
`background`.
