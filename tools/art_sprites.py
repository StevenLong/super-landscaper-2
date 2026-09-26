"""Sprite drawings for make_art.py for things that don't turn: vehicles, flowers,
house, borders, pond and props, drawn 3/4. Things that turn (mowers, the player on
foot, critters, the customer) are voxel models in voxel.py."""
import random

from canvas import Canvas, hexc
from make_art import (INK, STEEL, RED, YELLOW, BLUE, GLASS, WOOD, BRICK, CREAM, ROOF, STONE, LEAF,
                      lit, shaded_ellipse, shaded_rect)


# ---------------------------------------------------------------- vehicles

TRUCK_FOOT = 90  # art y of the truck's near side at ground; main.tscn offsets the sprite to it


def box34(c, x, foot, w, depth, height, ramp, top=None):
    """A box seen 3/4: its near side (height tall, standing on foot) under its top
    (depth tall). Returns the top's y."""
    side_top = foot - height
    shaded_rect(c, x, foot - height, w, height, ramp)
    shaded_rect(c, x, side_top - depth, w, depth, top or ramp[1:])
    return side_top - depth


def truck():
    """The pickup parked facing right, seen 3/4: the open bed with the fuel can in
    it, the cab, the bonnet, wheels on the near side."""
    W, H = 132, 96
    c = Canvas(W, H)
    F = TRUCK_FOOT - 4                                       # bottom of the body, above the wheels
    D = 34                                                   # 56 px deep, seen at 0.6
    box34(c, 4, F, 78, D, 24, BLUE[1:5], BLUE[2:])           # the bed
    c.rect(8, F - 24 - D + 4, 70, D - 7, BLUE[0])            # inside it
    for i in range(6):
        c.rect(12 + i * 11, F - 24 - D + 5, 1, D - 9, BLUE[1])
    shaded_rect(c, 16, F - 24 - 24, 16, 20, YELLOW)          # the fuel can
    c.rect(20, F - 24 - 26, 8, 3, YELLOW[1])
    c.rect(30, F - 24 - 22, 3, 4, STEEL[1])
    box34(c, 80, F, 34, D, 50, BLUE[2:5], BLUE[4:])          # the cab
    c.rect(86, F - 44, 24, 18, GLASS[2])                     # side window
    c.rect(86, F - 44, 24, 3, GLASS[4])
    c.rect(88, F - 41, 2, 12, GLASS[3])
    c.rect(104, F - 50 - D + 2, 9, D - 3, GLASS[3])         # the windscreen, sloping to the bonnet
    c.rect(104, F - 50 - D + 2, 2, D - 3, GLASS[4])
    c.rect(96, F - 22, 6, 2, STEEL[2])                       # door handle
    c.rect(96, F - 50, 1, 50, BLUE[1])                       # door seam
    box34(c, 114, F, 16, D, 28, BLUE[2:5], BLUE[4:])         # the bonnet
    c.rect(126, F - 22, 3, 6, hexc("fff8c0"))                # headlight
    c.rect(4, F - 2, 126, 3, STEEL[1])                       # sill
    for wx in (22, 106):
        c.ellipse(wx, F + 1, 10, 9, STEEL[0])
        c.ellipse(wx, F + 1, 4.5, 4, STEEL[3])
        c.ellipse(wx - 1, F, 1.5, 1.5, STEEL[5])
    c.outline(INK)
    return c


def trailer():
    """The flatbed trailer hitched behind, seen 3/4, drawbar to the right."""
    W, H = 70, 48
    c = Canvas(W, H)
    F = 40
    box34(c, 4, F, 56, 24, 8, STEEL[1:5])
    for i in range(7):
        c.rect(8 + i * 7, F - 8 - 22, 2, 20, STEEL[2])
    c.rect(60, F - 8, 10, 3, STEEL[2])                       # drawbar
    c.ellipse(26, F + 1, 7, 6.5, STEEL[0])
    c.ellipse(26, F + 1, 3, 2.5, STEEL[3])
    c.outline(INK)
    return c


# ---------------------------------------------------------------- flowers

FLOWER_COLS = [("f070a8", "b03870"), ("f8d848", "c09018"), ("e84040", "a01818"),
               ("b070e8", "7038a8"), ("f8f8f0", "c0c0b8"), ("f89838", "c05c10")]


def flowers():
    """Row 0: six flowers (8x8). Row 1: the same, flattened."""
    c = Canvas(8 * len(FLOWER_COLS), 16)
    for i, (hi, lo) in enumerate(FLOWER_COLS):
        x = i * 8
        c.stamp(x, 0, [
            "...a....",
            "..bab...",
            ".ab.ba..",
            "..bab.l.",
            "...a.ll.",
            "..lg....",
            ".ll.g...",
            "....g...",
        ], {"a": hexc(hi), "b": hexc(lo), "l": LEAF[3], "g": LEAF[2]})
        c.set(x + 3, 2, YELLOW[4] if hi != "f8d848" else RED[3])
        c.stamp(x, 8, [
            "........",
            "........",
            "..g.....",
            ".lbg.a..",
            "gbaabgl.",
            ".lgbl...",
            "........",
            "........",
        ], {"a": hexc(lo), "b": hexc("6a4a30"), "l": LEAF[1], "g": LEAF[2]})
    return c


# ---------------------------------------------------------------- house

HOUSE_BASE = 348   # art y of the house's front wall foot; house.gd draws it at WALL_H
GARAGE_ROOF = 100  # the garage roof's depth: a car (66 deep on screen) fits under it with room
GARAGE_BASE = 80 + GARAGE_ROOF + 4  # the same for the garage art (wall, roof, ridge)
WINDOWS = (40, 120, 290, 370)  # window x, 30 wide; main.gd WINDOWS matches


def roof(c, x, y0, w, h, rng):
    """A tiled roof slope from y0 (ridge) down h rows to the gutter, seen 3/4."""
    for y in range(y0, y0 + h):
        row = (y - y0) // 7
        for x_ in range(x, x + w):
            col = ROOF[2] if (y - y0) < h * 0.35 else ROOF[3]
            if (y - y0) % 7 == 6:
                col = ROOF[1]
            elif (x_ + row * 6) % 12 == 0:
                col = ROOF[1]
            elif rng.random() < 0.03:
                col = ROOF[4]
            c.px[y][x_] = col
    c.rect(x, y0, w, 3, ROOF[0])                         # ridge tiles
    c.rect(x, y0 + 1, w, 1, ROOF[1])
    c.rect(x, y0 + h, w, 4, STONE[1])                    # gutter and fascia
    c.rect(x, y0 + h, w, 1, STONE[3])


def facade(c, x, y0, w, h):
    """Cream render with faint courses and a brick plinth, y0 top to y0 + h foot."""
    for y in range(y0, y0 + h):
        for x_ in range(x, x + w):
            c.px[y][x_] = CREAM[2] if (y - y0) % 9 == 8 else (CREAM[3] if (x_ + y) % 17 else CREAM[2])
    for y in range(y0 + h - 10, y0 + h):
        for x_ in range(x, x + w):
            c.px[y][x_] = BRICK[2] if ((x_ + (4 if (y // 3) % 2 else 0)) % 8) and y % 3 else BRICK[1]


def window(c, wx, top, h):
    c.rect(wx - 3, top - 3, 36, h + 6, CREAM[0])          # frame
    c.rect(wx, top, 30, h, GLASS[2])
    c.rect(wx, top, 30, 4, GLASS[4])
    c.rect(wx + 2, top + 4, 3, h - 8, GLASS[3])
    c.rect(wx + 14, top, 2, h, CREAM[4])
    c.rect(wx, top + h // 2 - 1, 30, 2, CREAM[4])
    c.rect(wx - 8, top, 6, h, hexc("c86070"))           # shutters
    c.rect(wx + 32, top, 6, h, hexc("c86070"))
    c.rect(wx - 8, top, 6, 1, hexc("e08898"))
    c.rect(wx + 32, top, 6, 1, hexc("e08898"))
    c.rect(wx - 5, top + h + 3, 40, 4, STONE[3])          # sill
    c.rect(wx - 5, top + h + 6, 40, 1, STONE[1])


def house():
    """Two storeys seen 3/4: roof, upstairs, ground floor, then the patio. The front
    wall's foot is HOUSE_BASE; only ground-floor windows are low enough to hit."""
    W, B = 440, HOUSE_BASE
    c = Canvas(W, B + 24)
    r = random.Random(7)
    wall_top = B - 158
    ridge = wall_top - 154
    roof(c, 0, ridge, W, 154, r)
    # The chimney stands up through the slope just in front of the ridge: a brick front
    # face, the top of its stack seen from above, a stone cap and two pots, and its
    # shadow falling down the tiles to the right.
    cx, foot = 330, ridge + 34
    for y in range(foot - 30, foot + 6):
        for x in range(cx + 24, cx + 30):
            if y - (foot - 30) > (x - cx - 24) * 2:
                c.px[y][x] = ROOF[1]
    top = box34(c, cx, foot, 24, 8, 34, BRICK, BRICK[2:])
    for y in range(foot - 32, foot, 4):                    # brick courses
        c.rect(cx + 1, y, 22, 1, BRICK[1])
        for x in range(cx + (3 if (y // 4) % 2 else 7), cx + 23, 8):
            c.rect(x, y - 3, 1, 3, BRICK[1])
    c.rect(cx - 2, top - 2, 28, 4, STONE[3])               # the cap
    c.rect(cx - 2, top - 2, 28, 1, STONE[4])
    c.rect(cx - 2, top + 2, 28, 1, STONE[1])
    for px_ in (cx + 4, cx + 14):                          # chimney pots
        shaded_rect(c, px_, top - 9, 6, 8, BRICK[1:])
        c.rect(px_ - 1, top - 10, 8, 2, BRICK[3])
        c.rect(px_ + 1, top - 10, 4, 1, INK)
    facade(c, 0, wall_top + 4, W, 154)
    for wx in WINDOWS:
        window(c, wx, B - 141, 36)                       # upstairs
        window(c, wx, B - 62, 36)                        # ground floor
    window(c, 205, B - 141, 36)                          # over the door
    c.rect(196, B - 76, 48, 8, ROOF[2])                  # porch hood
    c.rect(196, B - 76, 48, 2, ROOF[4])
    c.rect(196, B - 69, 48, 1, ROOF[0])
    c.rect(203, B - 66, 34, 66, CREAM[0])                # the door
    shaded_rect(c, 205, B - 64, 30, 64, WOOD)
    for py in (B - 58, B - 30):
        c.rect(209, py, 22, 22, WOOD[2])
        c.rect(209, py, 22, 1, WOOD[1])
    c.rect(229, B - 34, 3, 3, YELLOW[3])
    c.rect(213, B - 56, 14, 10, GLASS[2])
    c.rect(213, B - 56, 14, 2, GLASS[4])
    c.rect(196, B - 1, 48, 5, STONE[3])                  # step
    c.rect(0, B - 1, W, 1, INK)
    for y in range(B, B + 24):                           # patio slabs
        for x in range(W):
            edge = (y - B) % 12 == 0 or (x + (6 if ((y - B) // 12) % 2 else 0)) % 24 == 0
            c.px[y][x] = STONE[1] if edge else (STONE[3] if r.random() > 0.08 else STONE[2])
    for px_ in (176, 254):                               # pots by the door
        shaded_rect(c, px_, B - 8, 12, 12, BRICK)
        shaded_ellipse(c, px_ + 6, B - 14, 9, 9, LEAF)
    return c


def garage():
    """One storey with an up-and-over door; its foot is GARAGE_BASE."""
    W, B = 120, GARAGE_BASE
    c = Canvas(W, B)
    r = random.Random(8)
    wall_top = B - 80
    roof(c, 0, wall_top - GARAGE_ROOF, W, GARAGE_ROOF, r)  # deep enough to hold the car
    facade(c, 0, wall_top + 4, W, 76)
    door = (12, B - 62, W - 24, 62)
    c.rect(door[0] - 3, door[1] - 3, door[2] + 6, door[3] + 3, CREAM[0])
    c.rect(*door, hexc("d8d2c2"))
    for y in range(door[1] + 5, B, 7):
        c.rect(door[0], y, door[2], 1, hexc("aaa498"))
        c.rect(door[0], y + 1, door[2], 1, hexc("ece6d8"))
    c.rect(W // 2 - 6, B - 12, 12, 3, STEEL[2])          # handle
    c.rect(0, B - 1, W, 1, INK)
    return c


# ---------------------------------------------------------------- animals

def splat():
    c = Canvas(24, 20)
    r = random.Random(9)
    BL = [hexc(h) for h in ("3a0808", "6a1010", "902018")]
    c.ellipse(12, 10, 10, 7, BL[1])
    for _ in range(9):
        c.ellipse(r.uniform(2, 22), r.uniform(2, 18), r.uniform(1, 2.5), r.uniform(1, 2.5), BL[r.randrange(3)])
    c.ellipse(12, 10, 6, 4, hexc("4a3222"))
    c.stamp(9, 8, ["x.x", ".x.", "x.x"], {"x": INK})
    return c


# ---------------------------------------------------------------- borders

PALE = [hexc(h) for h in ("6a5a44", "9a8870", "c8b898", "e8dcc0", "fcf4e0")]


def leaves(c, n, x0, y0, w, h, ramp, seed, wrap):
    """Leaf clumps over a box, lit from the top-left, wrapping every `wrap` px in x."""
    r = random.Random(seed)
    for _ in range(n):
        x, y = r.uniform(x0, x0 + w), r.uniform(y0, y0 + h)
        rr = r.uniform(2.5, 4.5)
        for ox in (-wrap, 0, wrap):
            shaded_ellipse(c, x + ox, y, rr, rr, ramp, bias=r.uniform(-0.15, 0.1))


def hedge_h():
    """A 24x44 run of hedge for the top and bottom edges, seen 3/4: a bumpy top
    (y 2..16) over a darker front face (y 15..43). The ground line is the bottom row."""
    c = Canvas(24, 44)
    c.rect(0, 16, 24, 28, LEAF[1])
    leaves(c, 26, 0, 17, 24, 25, LEAF[0:4], 32, 24)          # the face, in shade
    c.rect(0, 8, 24, 9, LEAF[2])
    leaves(c, 30, 0, 5, 24, 11, LEAF[2:], 31, 24)            # the top, in the light
    c.rect(0, 42, 24, 2, LEAF[0])
    return c


def hedge_v():
    """A 24x24 run of hedge for the side edges: its top from above, with bumpy
    edges so it doesn't read as a strip. Tiles vertically."""
    c = Canvas(24, 24)
    c.rect(4, 0, 16, 24, LEAF[2])
    r = random.Random(33)
    for _ in range(34):
        x, y = r.uniform(4, 20), r.uniform(0, 24)
        rr = r.uniform(2.5, 4.5)
        for oy in (-24, 0, 24):
            shaded_ellipse(c, x, y + oy, rr, rr, LEAF[1:], bias=r.uniform(-0.15, 0.1))
    return c


def fence_h():
    """A 16x32 run of picket fence for the top and bottom edges, seen 3/4: pickets
    29 px tall in front of two rails. The ground line is the bottom row."""
    c = Canvas(16, 32)
    for y in (9, 22):                                        # rails, behind the pickets
        c.rect(0, y, 16, 3, PALE[1])
        c.rect(0, y, 16, 1, PALE[2])
    for x in (1, 5, 9, 13):
        c.rect(x, 3, 3, 28, PALE[3])
        c.rect(x, 3, 1, 28, PALE[4])
        c.rect(x + 2, 3, 1, 28, PALE[2])
        c.set(x + 1, 2, PALE[4])                             # pointed top
        c.rect(x, 30, 3, 1, PALE[1])
    c.rect(0, 31, 16, 1, hexc("0c200c", 110))                # the foot on the grass
    return c


def fence_v():
    """A 24x32 run of fence for the side edges: seen 3/4, pickets running away from
    us stack into a thin wall; a post every tile."""
    c = Canvas(24, 32)
    c.rect(10, 0, 4, 32, PALE[3])
    c.rect(10, 0, 1, 32, PALE[4])
    c.rect(13, 0, 1, 32, PALE[1])
    c.rect(14, 0, 3, 32, hexc("0c200c", 80))                 # shadow on the grass
    c.rect(9, 12, 6, 20, PALE[2])                            # post
    c.rect(9, 12, 6, 2, PALE[4])
    c.rect(9, 12, 1, 20, PALE[3])
    c.rect(14, 12, 1, 20, PALE[0])
    return c


# ---------------------------------------------------------------- the pond

def pond(frame):
    """An oval garden pond, 132x92: a ring of rim stones, deep-to-shallow water, lily
    pads, and ripples that shift between the two frames."""
    import math
    W, H = 132, 92
    c = Canvas(W, H)
    cx, cy = W / 2, H / 2
    WATER = [hexc(h) for h in ("10283e", "183a58", "225070", "30688c", "5890b8", "a0d0f0")]
    # Rim stones, each with a darker front face so it stands up in 3/4. The far ones sit
    # behind the water, the near ones in front of its edge.
    r = random.Random(21)
    stones = []
    for i in range(34):
        a = i / 34 * 6.283
        x = cx + math.cos(a) * 60 + r.uniform(-1.5, 1.5)
        y = cy + math.sin(a) * 40 + r.uniform(-1.5, 1.5)
        stones.append((y, x, r.uniform(4.5, 6.5), r.uniform(3.5, 5)))
    stones.sort()

    def rim(front):
        for y, x, rx, ry in stones:
            if (y > cy) == front:
                shaded_ellipse(c, x, y + 2, rx, ry, STONE[:3])  # its face
                shaded_ellipse(c, x, y, rx, ry, STONE[1:])      # its top
    rim(False)
    # The bank: the water sits below the rim, so its far side shows as a dark earth wall.
    c.ellipse(cx, cy, 56, 36, hexc("2a2014"))
    # Water: darker in the middle (deeper), lighter at the edges.
    c.ellipse(cx, cy + 3, 55, 33, None, lambda nx, ny: WATER[max(0, min(3, int((nx * nx + ny * ny) * 4)))])
    # Ripples.
    for (rx, ry, rr) in ((cx - 18, cy - 8, 9), (cx + 16, cy + 6, 12), (cx + 2, cy - 14, 6)):
        rr2 = rr + frame * 3
        for k in range(24):
            a = k / 24 * 6.283
            if k % 3:
                c.set(int(rx + math.cos(a) * rr2), int(ry + math.sin(a) * rr2 * 0.55), WATER[4])
    # Lily pads with a notch, one with a flower.
    for (x, y) in ((cx + 26, cy - 14), (cx - 30, cy + 12), (cx + 12, cy + 18)):
        shaded_ellipse(c, x, y, 6, 4, LEAF[2:])
        c.set(int(x) + 3, int(y), WATER[1])
        c.set(int(x) + 4, int(y), WATER[1])
    c.stamp(int(cx - 32), int(cy + 9), [".a.", "aya", ".a."], {"a": hexc("f8b8d0"), "y": YELLOW[4]})
    rim(True)
    c.outline(INK)
    return c


# ---------------------------------------------------------------- props

def stone():
    c = Canvas(12, 10)
    shaded_ellipse(c, 6, 5, 5, 4, STONE)
    c.set(4, 3, STONE[4])
    c.set(7, 6, STONE[1])
    c.outline(INK)
    return c


PINK = [hexc(h) for h in ("5a1830", "983058", "d05888", "f088b0", "f8c0d8")]
ORANGE = [hexc(h) for h in ("5a2008", "a04010", "e06820", "f89040", "f8c080")]
HOSE = [hexc(h) for h in ("12301a", "1e5a2a", "2c7a38", "44a050", "68c070")]
FUZZ = [hexc(h) for h in ("6a7a10", "a8c020", "d0e040", "e8f070")]


def gnome():
    """A garden gnome: red pointed hat, white beard, blue coat. Small: carry it, throw it,
    or mow it to bits."""
    c = Canvas(12, 18)
    shaded_ellipse(c, 6, 15, 4.5, 2.5, STEEL[:3])         # boots on the ground
    shaded_ellipse(c, 6, 12, 4.5, 4, BLUE)                # coat
    shaded_ellipse(c, 6, 8, 3, 2.5, [hexc("c08060"), hexc("e8b088"), hexc("f8d0a8")])  # face
    for y in range(9, 13):
        c.rect(6 - (13 - y) // 2 - 1, y, (13 - y) + 2, 1, [hexc("d8d8d0"), hexc("f4f0e6")][y % 2])  # beard
    for y in range(0, 7):                                 # the hat, a tall cone
        w = 1 + y
        c.rect(6 - w // 2, y, w, 1, RED[2] if y > 1 else RED[3])
    c.rect(6 - 4, 6, 8, 1, RED[1])
    c.outline(INK)
    return c


def flamingo():
    """A plastic lawn flamingo on wire legs."""
    c = Canvas(14, 22)
    for x in (5, 8):
        c.rect(x, 13, 1, 9, STEEL[3])                     # wire legs, pushed into the lawn
    shaded_ellipse(c, 7, 11, 5, 3, PINK)                  # body
    for i, (x, y) in enumerate(((10, 8), (11, 6), (11, 4), (10, 3), (9, 2))):
        c.rect(x, y, 2, 2, PINK[3 if i % 2 else 2])        # the S of its neck
    c.rect(7, 2, 2, 1, PINK[4])                           # head
    c.rect(6, 3, 2, 1, INK)                               # black-tipped beak
    c.outline(INK)
    return c


def cone():
    """A traffic cone: not theirs, nobody minds where it ends up."""
    c = Canvas(12, 16)
    c.rect(0, 13, 12, 3, STEEL[1])                        # the square foot
    for y in range(1, 13):
        w = 2 + (y * 8) // 12
        col = [hexc("e8e8e0"), hexc("f8f8f0")][y % 2] if 5 <= y <= 7 else ORANGE[2 if y % 3 else 3]
        c.rect(6 - w // 2, y, w, 1, col)
    c.outline(INK)
    return c


def hose():
    """A coiled garden hose with a brass nozzle. Mowed, it leaks."""
    c = Canvas(18, 12)
    for r in (7.5, 5.5, 3.5):
        shaded_ellipse(c, 9, 6, r, r * 0.62, HOSE)
        shaded_ellipse(c, 9, 6, r - 1.2, (r - 1.2) * 0.62, HOSE[:2])
    c.rect(14, 2, 3, 2, YELLOW[3])                        # nozzle
    c.outline(INK)
    return c


def ball():
    """A tennis ball: the dog fetches it."""
    c = Canvas(7, 7)
    shaded_ellipse(c, 3.5, 3.5, 3, 3, FUZZ)
    c.set(2, 2, hexc("f8f8f0"))
    c.set(3, 3, hexc("f8f8f0"))
    c.set(4, 4, hexc("f8f8f0"))
    c.outline(INK)
    return c


def rock():
    """A decorative boulder, big and solid, standing up from the lawn in 3/4."""
    c = Canvas(34, 26)
    shaded_ellipse(c, 17, 17, 15, 8, STONE[:3])           # its near face, in shadow
    shaded_ellipse(c, 16, 12, 14, 10, STONE)              # the lit top
    c.set(10, 8, STONE[4])
    c.set(22, 14, STONE[1])
    c.set(20, 9, STONE[3])
    c.outline(INK)
    return c


def jerrycan():
    c = Canvas(12, 14)
    shaded_rect(c, 1, 3, 10, 11, RED)
    c.rect(3, 0, 6, 3, RED[1])
    c.rect(4, 1, 4, 1, (0, 0, 0, 0))
    c.rect(8, 1, 2, 3, STEEL[3])
    c.rect(3, 6, 6, 1, RED[4])
    c.rect(3, 9, 6, 1, RED[1])
    c.outline(INK)
    return c
