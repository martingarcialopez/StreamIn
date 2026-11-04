"""Splits the image model's traced SVG into Icon Composer layers.

The trace draws the globe as a white disc (path 2) with dark patches over it
(paths 3, 4, 6–9); the lines are the white left between them. Using the
patches as a mask on the disc gives the lines alone, on transparency. The
play sign is path 5. The background paths (0, 1, 10–15) are trace artefacts
and are dropped: the icon's gradient fill replaces them.

    python3 -I scripts/split-icon-svg.py design/app-icon-original.svg StreamIn/Resources/AppIcon.icon/Assets
"""
import re
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()
paths = [m.group(1) for m in re.finditer(r'<path\b[^>]*\bd="([^"]*)"', s)]

DISC, PLAY = 2, 5
PATCHES = [3, 4, 6, 7, 8, 9]

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">\n'
patches = "\n".join(f'      <path fill="#000" d="{paths[i]}"/>' for i in PATCHES)
globe = (
    HEAD
    + "  <defs>\n"
    + '    <mask id="m" maskUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024">\n'
    + '      <rect width="1024" height="1024" fill="#fff"/>\n'
    + patches
    + "\n    </mask>\n  </defs>\n"
    + f'  <path fill="#FFFFFF" mask="url(#m)" d="{paths[DISC]}"/>\n</svg>\n'
)
play = HEAD + f'  <path fill="#FFFFFF" d="{paths[PLAY]}"/>\n</svg>\n'
open(f"{out}/globe.svg", "w").write(globe)
open(f"{out}/play.svg", "w").write(play)
print("ok")
