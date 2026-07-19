"""Generates the game icon: the grey fortress under a night sky,
with a subtle lightning bolt striking behind the keep.

Writes, in the project root:
  icon.png  - 256x256, the project/window icon (project.godot)
  icon.ico  - multi-size (256/128/64/48/32/16), used by the Windows
              export preset to brand the exported EXE

Run from anywhere:  python tools/make_icon.py
Public domain (CC0), like the rest of the generated assets.
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
S = 4          # supersampling factor: draw at 1024, ship at 256
SIZE = 256 * S


def p(*coords):
    """Scale a list of (x, y) points from 256-space to canvas space."""
    return [(x * S, y * S) for x, y in coords]


def r(x0, y0, x1, y1):
    """Scale a rectangle from 256-space to canvas space."""
    return [x0 * S, y0 * S, x1 * S, y1 * S]


img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# --- night sky: vertical gradient, deep black-blue to blue ---
top, bottom = (5, 8, 20), (18, 23, 51)
for y in range(SIZE):
    f = y / SIZE
    col = tuple(int(a + (b - a) * f) for a, b in zip(top, bottom))
    d.line([(0, y), (SIZE, y)], fill=col + (255,))

# --- stars (deterministic scatter, denser near the top) ---
seed = 1234567
for i in range(46):
    seed = (seed * 1103515245 + 12345) % (1 << 31)
    sx = (seed >> 8) % 256
    seed = (seed * 1103515245 + 12345) % (1 << 31)
    sy = ((seed >> 8) % 150) ** 2 // 150            # bias upward
    seed = (seed * 1103515245 + 12345) % (1 << 31)
    alpha = 90 + (seed >> 8) % 130
    rad = S * (1 if i % 3 else 2) // 2
    d.ellipse(r(sx - 0.5, sy - 0.5, sx + 0.5, sy + 0.5),
              fill=(230, 235, 255, alpha))
    if rad:
        pass  # radius folded into the half-unit ellipse above

# --- crescent moon, small and high ---
d.ellipse(r(178, 22, 216, 60), fill=(238, 233, 205, 255))
d.ellipse(r(170, 16, 208, 54), fill=(7, 10, 26, 255))

# --- the lightning bolt: subtle, mostly behind the keep ---
bolt = p((74, 2), (96, 44), (82, 48), (110, 96), (98, 98), (124, 142))
d.line(bolt, fill=(150, 185, 255, 60), width=int(2.6 * S), joint="curve")
d.line(bolt, fill=(205, 225, 255, 170), width=int(1.1 * S), joint="curve")

# --- ground: a dark hill the fortress stands on ---
d.polygon(p((0, 230), (40, 214), (216, 214), (256, 232), (256, 256), (0, 256)),
          fill=(13, 17, 14, 255))

# --- fortress silhouette, three shades of grey ---
wall = (74, 76, 86, 255)
tower = (94, 96, 106, 255)
keep = (108, 110, 121, 255)
window = (245, 205, 90, 255)

# curtain wall with crenellations
d.rectangle(r(28, 152, 228, 218), fill=wall)
for i in range(10):
    x = 28 + i * 21
    d.rectangle(r(x, 141, x + 12, 152), fill=wall)
# side towers, slightly lighter, with their own crenellations
for tx in (18, 192):
    d.rectangle(r(tx, 112, tx + 46, 218), fill=tower)
    for j in range(3):
        mx = tx - 2 + j * 18
        d.rectangle(r(mx, 100, mx + 12, 112), fill=tower)
    d.rectangle(r(tx + 19, 136, tx + 27, 150), fill=window)
# central keep, tallest and lightest
d.rectangle(r(96, 68, 160, 218), fill=keep)
for j in range(4):
    mx = 96 + j * 18
    d.rectangle(r(mx, 54, mx + 10, 68), fill=keep)
d.rectangle(r(114, 96, 122, 110), fill=window)
d.rectangle(r(136, 126, 144, 140), fill=window)
# gate: an arch in the curtain wall
d.rectangle(r(116, 186, 140, 218), fill=(8, 8, 14, 255))
d.ellipse(r(116, 174, 140, 198), fill=(8, 8, 14, 255))

# --- rounded corners (transparent outside the radius) ---
mask = Image.new("L", (SIZE, SIZE), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, SIZE - 1, SIZE - 1],
                                       radius=30 * S, fill=255)
img.putalpha(mask)

final = img.resize((256, 256), Image.LANCZOS)
final.save(ROOT / "icon.png")
final.save(ROOT / "icon.ico",
           sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])
print("wrote", ROOT / "icon.png", "and", ROOT / "icon.ico")
