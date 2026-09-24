"""World art for Super Landscaper: SNES-style pixel sprites authored in code.

Run from the repo root: python tools/make_art.py
Writes PNGs into art/. PREVIEW_DIR=<dir> also writes enlarged previews there.
Everything is deterministic (seeded), so re-running reproduces the same art.
Sprites face RIGHT (+x); the game rotates them.
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from canvas import Canvas, sheet, hexc, CLEAR  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "art")
INK = hexc("201818")

# Palette ramps (dark -> light).
GRASS = [hexc(h) for h in ("1a3e18", "25561f", "2f6c27", "3b8230", "4e9a3a", "68b048", "86c85a")]
SOIL = [hexc(h) for h in ("2e1c10", "4a2e1a", "603c22", "7a4e2e", "94643c")]
STONE = [hexc(h) for h in ("3a3a40", "56565e", "74747c", "92929a", "b4b4b8")]
LEAF = [hexc(h) for h in ("12301a", "1c4a24", "286030", "387a3a", "4e9448", "72b058")]
RED = [hexc(h) for h in ("4a1010", "7a1a18", "a82a22", "d04430", "f07050")]
STEEL = [hexc(h) for h in ("18181c", "34343c", "54545e", "7a7a86", "a8a8b4", "d8d8e0")]
BLUE = [hexc(h) for h in ("101c3a", "1c3060", "2c4c8c", "4070b8", "68a0e0", "a0d0f8")]
YELLOW = [hexc(h) for h in ("4a3408", "7a5a10", "b08818", "e0b830", "f8e070")]
BRICK = [hexc(h) for h in ("3a1c14", "5e2c1e", "84402a", "a85a3a", "c87c54")]
CREAM = [hexc(h) for h in ("6a6050", "948a74", "bcb296", "dcd4b8", "f4eed8")]
ROOF = [hexc(h) for h in ("241418", "3c2028", "58303a", "784450", "985c66")]
GLASS = [hexc(h) for h in ("1a2c40", "2c4a68", "4a7098", "78a8d0", "c0e0f8")]
WOOD = [hexc(h) for h in ("2a1a0e", "442a16", "5e3c20", "7c522e", "9c6c40")]

# Key colours for per-customer palette swaps (match face.gd / client.gd).
K_SKIN = [(253, 3, 3, 255), (254, 2, 2, 255), (255, 1, 1, 255)]
K_HAIR = [(3, 253, 3, 255), (2, 254, 2, 255), (1, 255, 1, 255)]
K_SHIRT = [(2, 2, 254, 255), (1, 1, 255, 255)]

# The player's own look (not swapped).
P_SKIN = [hexc(h) for h in ("a06840", "d09868", "f0c090")]
P_HAIR = [hexc(h) for h in ("2a1a10", "4a2c14", "704820")]
P_SHIRT = [hexc(h) for h in ("1c5030", "2c7848", "44a060")]  # green work shirt
P_CAP = [hexc(h) for h in ("7a1a18", "b02a22", "e04a38")]


def lit(ramp, nx, ny, bias=0.0):
    """Pick a ramp colour for a surface point lit from the top-left."""
    d = -(nx * 0.6 + ny * 0.8) * 0.5 + 0.5 + bias  # 0 dark .. 1 light
    i = int(max(0, min(len(ramp) - 1, round(d * (len(ramp) - 1)))))
    return ramp[i]


def shaded_ellipse(c, cx, cy, rx, ry, ramp, bias=0.0):
    c.ellipse(cx, cy, rx, ry, None, lambda nx, ny: lit(ramp, nx, ny, bias))


def shaded_rect(c, x, y, w, h, ramp, rim=True):
    """A box lit from the top-left: light top/left edge, dark bottom/right edge."""
    mid = ramp[len(ramp) // 2]
    c.rect(x, y, w, h, mid)
    if rim:
        c.rect(x, y, w, 1, ramp[-1])
        c.rect(x, y, 1, h, ramp[-2])
        c.rect(x, y + h - 1, w, 1, ramp[1])
        c.rect(x + w - 1, y, 1, h, ramp[1])


# ---------------------------------------------------------------- tiles

def grass_tile(kind, seed):
    """32x32 tileable grass. kind: long | light | dark."""
    r = random.Random(seed)
    base = {"long": GRASS[3], "light": GRASS[5], "dark": GRASS[4]}[kind]
    c = Canvas(32, 32, base)

    def wset(x, y, col):
        c.px[y % 32][x % 32] = col

    if kind == "long":
        # Dense blade tufts: dark stem, lighter tip, leaning a little.
        for _ in range(95):
            x, y = r.randrange(32), r.randrange(32)
            h = r.randint(2, 4)
            lean = r.choice((-1, 0, 0, 1))
            for k in range(h):
                wset(x + (lean if k == h - 1 else 0), y - k, GRASS[1] if k == 0 else (GRASS[2] if k < h - 1 else GRASS[4]))
        for _ in range(26):
            wset(r.randrange(32), r.randrange(32), GRASS[5])
    else:
        # Short clipped turf: faint flecks only, so stripes read as flat bands.
        hi, lo = (GRASS[6], GRASS[4]) if kind == "light" else (GRASS[5], GRASS[3])
        for _ in range(40):
            wset(r.randrange(32), r.randrange(32), lo)
        for _ in range(22):
            wset(r.randrange(32), r.randrange(32), hi)
    return c


def speckle_tile(ramp, seed, size=16, base_i=2, n=60):
    r = random.Random(seed)
    c = Canvas(size, size, ramp[base_i])
    for _ in range(n):
        x, y = r.randrange(size), r.randrange(size)
        c.px[y][x] = ramp[r.choice((base_i - 1, base_i + 1, base_i + 1, base_i - 2 if base_i >= 2 else 0))]
    return c


# ---------------------------------------------------------------- trees

def canopy(d, seed):
    """Round tree canopy seen from above, d px across, built from leaf clumps,
    with a soft shadow falling down-right onto the grass."""
    import math
    r = random.Random(seed)
    pad = 8
    c = Canvas(d + pad, d + pad)
    cx = cy = (d + 4) / 2
    R = d / 2
    shadow = hexc("0c200c", 110)
    c.ellipse(cx + 4, cy + 5, R, R, shadow)
    c.ellipse(cx, cy, R, R, LEAF[1])
    clumps = []
    for _ in range(int(d * 2.2)):
        a = r.random() * 6.283
        dist = (r.random() ** 0.5) * (R - 3.5)
        clumps.append((cx + math.cos(a) * dist, cy + math.sin(a) * dist, r.uniform(3.5, 6.5) * d / 72))
    # Paint back-to-front: lower-right (shadowed) clumps first, top-left last.
    clumps.sort(key=lambda t: -(t[0] + t[1]))
    for x, y, rr in clumps:
        up = (-(x - cx) * 0.6 - (y - cy) * 0.8) / R
        shaded_ellipse(c, x, y, rr, rr, LEAF, bias=up * 0.3 - 0.05)
    # Outline only the canopy, not the shadow.
    edge = []
    for y in range(c.h):
        for x in range(c.w):
            if c.px[y][x] == shadow or c.px[y][x][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    n = c.get(x + dx, y + dy)
                    if n[3] == 255 and n != shadow:
                        edge.append((x, y))
                        break
    for x, y in edge:
        c.px[y][x] = LEAF[0]
    return c


# ---------------------------------------------------------------- run

def save(name, canvas, preview_scale=4):
    os.makedirs(OUT, exist_ok=True)
    canvas.save(os.path.join(OUT, name + ".png"))
    pv = os.environ.get("PREVIEW_DIR")
    if pv:
        bg = Canvas(canvas.w, canvas.h, hexc("30503a"))
        bg.blit(canvas, 0, 0)
        bg.scaled(preview_scale).save(os.path.join(pv, "pv_" + name + ".png"))


def main(only=None):
    jobs = {
        "tiles": lambda: [
            save("grass_long", grass_tile("long", 1)),
            save("grass_light", grass_tile("light", 2)),
            save("grass_dark", grass_tile("dark", 3)),
            save("soil", speckle_tile(SOIL, 4)),
            save("gravel", speckle_tile(STONE, 5, base_i=1, n=36)),
        ],
        "trees": lambda: [save("tree_%d" % d, sheet([canopy(d, s) for s in (11, 12, 13)]), 3) for d in (52, 68, 84)],
    }
    import art_sprites as a
    jobs.update({
        "mowers": lambda: [
            # Frames: two while ridden/pushed, then the mower left standing empty.
            save("mower_petrol", sheet([a.petrol(0), a.petrol(1), a.petrol(0, False)])),
            save("mower_push", sheet([a.push(0), a.push(1), a.push(0, False)])),
            save("mower_rideon", sheet([a.rideon(0), a.rideon(1), a.rideon(0, False)])),
        ],
        "vehicles": lambda: [save("truck", a.truck(), 3), save("trailer", a.trailer(), 3)],
        "flowers": lambda: [save("flowers", a.flowers(), 6)],
        "house": lambda: [save("house", a.house(), 2)],
        "animals": lambda: [
            save("hedgehog", sheet([a.hedgehog(0), a.hedgehog(1)]), 6),
            save("squirrel", sheet([a.squirrel(0), a.squirrel(1)]), 6),
            save("splat", a.splat(), 6),
        ],
        "client": lambda: [save("client", sheet([a.client(0), a.client(1), a.client(2)]), 6)],
        "props": lambda: [
            save("stone", a.stone(), 6),
            save("jerrycan", a.jerrycan(), 6),
            save("walker", sheet([a.walker(0), a.walker(1)]), 6),
            save("dog", sheet([a.dog(0), a.dog(1)]), 6),
        ],
    })
    for k, fn in jobs.items():
        if only is None or k in only:
            fn()


if __name__ == "__main__":
    main(sys.argv[1:] or None)
