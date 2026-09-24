"""Sprite drawings for make_art.py: people, mowers, vehicles, flowers, house,
animals and the customer. Sprites face RIGHT (+x); mower canvases are centred on
the collision body so the game needs no sprite offset."""
import random

from canvas import Canvas, hexc
from make_art import (INK, STEEL, RED, YELLOW, BLUE, GLASS, WOOD, BRICK, CREAM, ROOF, STONE, LEAF,
                      P_SHIRT, P_SKIN, P_CAP, K_SKIN, K_HAIR, K_SHIRT, lit, shaded_ellipse, shaded_rect)


# ---------------------------------------------------------------- people

def player_topdown(c, cx, cy, step, arms_to=None):
    """The player seen from above: shoulders, capped head, arms reaching forward
    to arms_to (a pair of points) and feet showing behind on alternate steps."""
    fy = (-3, 3)
    for k, dy in enumerate(fy):
        c.ellipse(cx - 6 + (1 if k == step else -1), cy + dy, 2.2, 1.8, STEEL[1])
    c.ellipse(cx, cy, 4.5, 7.5, None, lambda nx, ny: lit(P_SHIRT, nx, ny))
    if arms_to:
        for (ax, ay), sy in zip(arms_to, (-5, 5)):
            steps = 8
            for i in range(steps + 1):
                t = i / steps
                x = cx + 1 + (ax - cx - 1) * t
                y = cy + sy + (ay - cy - sy) * t
                c.rect(int(x), int(y), 2, 2, P_SHIRT[1] if t < 0.7 else P_SKIN[1])
    c.ellipse(cx + 0.5, cy, 3.6, 3.6, None, lambda nx, ny: lit(P_CAP, nx, ny))
    c.rect(int(cx + 3), int(cy - 2), 2, 4, P_CAP[0])  # brim


def wheel(c, x, y, w, h, phase=0):
    c.rect(x, y, w, h, STEEL[0])
    for i in range(x + phase, x + w, 2):
        c.set(i, y, STEEL[2])
        c.set(i, y + h - 1, STEEL[2])


# ---------------------------------------------------------------- mowers

def petrol(step, rider=True):
    W, H = 92, 40
    c = Canvas(W, H)
    cx, cy = W // 2, H // 2          # body 36x28
    x0, y0 = cx - 18, cy - 14
    for wx, wy in ((x0 + 2, y0 - 2), (x0 + 26, y0 - 2), (x0 + 2, y0 + 25), (x0 + 26, y0 + 25)):
        wheel(c, wx, wy, 8, 5, step)
    shaded_rect(c, x0, y0, 36, 28, RED)
    c.rect(x0 + 2, y0 + 2, 32, 2, RED[4])
    shaded_ellipse(c, cx + 2, cy, 9, 9, STEEL)
    shaded_ellipse(c, cx + 2, cy, 4, 4, STEEL[1:5])
    c.rect(cx + 8, cy - 7, 3, 3, YELLOW[3])       # fuel cap
    c.rect(cx - 4, cy + 5, 2, 2, STEEL[5])         # pull cord handle
    hx = x0 - 16
    for yy in (y0 + 5, y0 + 22):
        c.rect(hx, yy, 17, 2, STEEL[2])
        c.rect(hx, yy, 17, 1, STEEL[4])
    c.rect(hx, y0 + 5, 2, 19, STEEL[3])
    if rider:
        player_topdown(c, hx - 7, cy, step, arms_to=((hx, y0 + 5), (hx, y0 + 22)))
    c.outline(INK)
    return c


def push(step, rider=True):
    W, H = 80, 36
    c = Canvas(W, H)
    cx, cy = W // 2, H // 2          # body 30x22
    x0, y0 = cx - 15, cy - 11
    for wy in (y0 - 2, y0 + 19):
        wheel(c, x0 + 8, wy, 14, 5, step)
    GREEN = [hexc(h) for h in ("123a1c", "1e5a2a", "2c7a38", "44a050", "68c070")]
    shaded_rect(c, x0 + 4, y0 + 2, 22, 18, GREEN)
    # The reel: spiral blades as diagonal steel strokes that roll with the step.
    for i in range(6):
        for j in range(16):
            c.set(x0 + 6 + i * 3 + (j + step * 2) % 3, y0 + 3 + j, STEEL[4] if j % 4 else STEEL[5])
    c.rect(x0 + 22, y0 + 3, 4, 16, STEEL[2])      # rear roller
    hx = x0 - 12
    for yy in (y0 + 5, y0 + 15):
        c.rect(hx, yy, 17, 2, WOOD[3])
    c.rect(hx, y0 + 5, 2, 12, WOOD[4])
    if rider:
        player_topdown(c, hx - 7, cy, step, arms_to=((hx, y0 + 5), (hx, y0 + 16)))
    c.outline(INK)
    return c


def rideon(step, rider=True):
    W, H = 76, 64
    c = Canvas(W, H)
    cx, cy = W // 2, H // 2          # body 52x40
    x0, y0 = cx - 26, cy - 20
    # Cutting deck underneath, wider than the body.
    shaded_rect(c, cx - 14, cy - 27, 26, 54, STEEL[1:5])
    for yy in (cy - 25, cy + 22):
        c.rect(cx - 12, yy, 22, 2, STEEL[4])
    for wy in (y0 - 3, y0 + 34):
        wheel(c, x0 + 1, wy, 16, 9, step)
    for wy in (y0 + 1, y0 + 32):
        wheel(c, x0 + 40, wy, 10, 7, step)
    shaded_rect(c, x0 + 2, y0 + 6, 48, 28, YELLOW)
    shaded_rect(c, x0 + 32, y0 + 9, 18, 22, YELLOW[1:])
    for i in range(4):
        c.rect(x0 + 47, y0 + 12 + i * 5, 2, 3, STEEL[1])   # grille
    c.rect(x0 + 49, y0 + 9, 2, 3, hexc("fff8c0"))
    c.rect(x0 + 49, y0 + 28, 2, 3, hexc("fff8c0"))
    shaded_rect(c, x0 + 8, y0 + 11, 12, 18, STEEL[:4])
    c.ellipse(x0 + 27, cy, 3.5, 5, STEEL[1])
    c.ellipse(x0 + 27, cy, 2, 3.5, YELLOW[3])
    if rider:
        player_topdown(c, x0 + 15, cy, 0, arms_to=((x0 + 26, cy - 4), (x0 + 26, cy + 4)))
    c.outline(INK)
    return c


# ---------------------------------------------------------------- vehicles

def truck():
    W, H = 132, 68
    c = Canvas(W, H)
    x0, y0 = 6, 6                     # body 120x56
    for wx in (x0 + 12, x0 + 84):
        wheel(c, wx, y0 - 3, 16, 5)
        wheel(c, wx, y0 + 54, 16, 5)
    shaded_rect(c, x0, y0, 120, 56, BLUE)
    c.rect(x0 + 3, y0 + 4, 70, 48, BLUE[1])
    for i in range(6):
        c.rect(x0 + 6 + i * 11, y0 + 5, 1, 46, BLUE[0])
    shaded_rect(c, x0 + 62, y0 + 5, 10, 46, STEEL[1:5])
    shaded_rect(c, x0 + 8, y0 + 18, 16, 20, YELLOW)      # the fuel can
    c.rect(x0 + 12, y0 + 16, 8, 3, YELLOW[1])
    c.rect(x0 + 22, y0 + 20, 3, 4, STEEL[1])
    shaded_rect(c, x0 + 76, y0 + 5, 26, 46, BLUE[2:])
    c.rect(x0 + 100, y0 + 7, 5, 42, GLASS[3])
    c.rect(x0 + 101, y0 + 9, 1, 12, GLASS[4])
    shaded_rect(c, x0 + 105, y0 + 6, 14, 44, BLUE[1:5])
    c.rect(x0 + 117, y0 + 8, 2, 6, hexc("fff8c0"))
    c.rect(x0 + 117, y0 + 42, 2, 6, hexc("fff8c0"))
    c.rect(x0 + 96, y0 - 2, 4, 2, STEEL[2])
    c.rect(x0 + 96, y0 + 56, 4, 2, STEEL[2])
    c.outline(INK)
    return c


def trailer():
    W, H = 70, 50
    c = Canvas(W, H)
    wheel(c, 24, 1, 14, 5)
    wheel(c, 24, 44, 14, 5)
    shaded_rect(c, 4, 5, 56, 40, STEEL[1:5])
    for i in range(7):
        c.rect(7 + i * 7, 7, 2, 36, STEEL[2])
    c.rect(60, 23, 10, 4, STEEL[2])
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

def house():
    W, H = 440, 130
    c = Canvas(W, H)
    r = random.Random(7)
    for y in range(0, 62):
        ramp_i = 3 if y < 30 else 2
        for x in range(W):
            col = ROOF[ramp_i]
            if y % 6 == 5 or (x + (y // 6) * 5) % 10 == 0:
                col = ROOF[ramp_i - 1]
            c.px[y][x] = col
    c.rect(0, 29, W, 2, ROOF[4])
    c.rect(0, 0, W, 1, ROOF[0])
    shaded_rect(c, 332, 6, 22, 26, BRICK)         # chimney
    c.rect(330, 4, 26, 4, STONE[2])
    c.rect(0, 60, W, 3, STONE[1])                 # gutter
    c.rect(0, 60, W, 1, STONE[3])
    for y in range(63, 106):
        for x in range(W):
            c.px[y][x] = CREAM[3] if (x + y) % 17 else CREAM[2]
    for y in range(98, 106):
        for x in range(W):
            c.px[y][x] = BRICK[2] if ((x + (4 if (y // 4) % 2 else 0)) % 8) else BRICK[1]
    for wx in (40, 120, 290, 370):
        c.rect(wx - 2, 69, 34, 26, CREAM[0])
        c.rect(wx, 71, 30, 22, GLASS[2])
        c.rect(wx, 71, 30, 3, GLASS[4])
        c.rect(wx + 14, 71, 2, 22, CREAM[4])
        c.rect(wx, 81, 30, 2, CREAM[4])
        c.rect(wx, 71, 5, 22, hexc("c86070"))
        c.rect(wx + 25, 71, 5, 22, hexc("c86070"))
        c.rect(wx - 4, 94, 38, 3, STONE[3])
    c.rect(204, 66, 32, 34, CREAM[0])             # door
    shaded_rect(c, 206, 68, 28, 32, WOOD)
    c.rect(228, 84, 3, 3, YELLOW[3])
    c.rect(214, 72, 12, 8, GLASS[2])
    c.rect(214, 72, 12, 2, GLASS[4])
    c.rect(196, 100, 48, 6, STONE[3])
    for y in range(106, H):                       # patio slabs
        for x in range(W):
            edge = (y - 106) % 12 == 0 or (x + (6 if ((y - 106) // 12) % 2 else 0)) % 24 == 0
            c.px[y][x] = STONE[1] if edge else (STONE[3] if r.random() > 0.08 else STONE[2])
    for px_ in (182, 250):                        # pots by the door
        shaded_rect(c, px_, 104, 10, 10, BRICK)
        shaded_ellipse(c, px_ + 5, 101, 7, 6, LEAF)
    return c


# ---------------------------------------------------------------- animals

def hedgehog(step):
    c = Canvas(22, 16)
    SP = [hexc(h) for h in ("2a1c14", "4a3222", "6a4a30", "8a6844", "b08c60")]
    c.ellipse(9, 8, 8, 6, None, lambda nx, ny: lit(SP, nx, ny))
    r = random.Random(3)
    for _ in range(26):
        x, y = r.randint(3, 15), r.randint(3, 13)
        if (x - 9) ** 2 / 64 + (y - 8) ** 2 / 36 < 0.9:
            c.set(x, y, SP[0])
            c.set(x + 1, y - 1, SP[4])
    FACE = [hexc("a07858"), hexc("d0a880"), hexc("f0d0a8")]
    c.ellipse(17, 8, 3.5, 3, None, lambda nx, ny: lit(FACE, nx, ny))
    c.set(20, 8, INK)
    c.set(17, 7, INK)
    for fx in ((6, 12) if step == 0 else (8, 14)):
        c.set(fx, 14, SP[0])
        c.set(fx + 1, 2, SP[0])
    c.outline(INK)
    return c


def squirrel(step):
    """Side-on grey squirrel: a big question-mark tail drawn as its own outlined
    shape so it reads separately from the body."""
    FUR = [hexc(h) for h in ("2e2e34", "4e4e58", "74747e", "9a9aa4", "c8c8d0")]
    BELLY = hexc("e8e0d0")
    tail = Canvas(28, 20)
    tail.ellipse(7, 7 - step, 6, 6.5, None, lambda nx, ny: lit(FUR, nx, ny, 0.25))
    tail.ellipse(6, 13, 4, 3.5, None, lambda nx, ny: lit(FUR, nx, ny, 0.2))
    tail.ellipse(8.5, 6 - step, 2.5, 3, FUR[1])  # the curl's shadowed inside
    tail.outline(INK)
    body = Canvas(28, 20)
    body.ellipse(16, 13, 6, 4.5, None, lambda nx, ny: BELLY if ny > 0.45 else lit(FUR, nx, ny))
    body.ellipse(22.5, 9.5, 3.8, 3.4, None, lambda nx, ny: lit(FUR, nx, ny))
    body.set(21, 5, FUR[2])
    body.set(21, 6, FUR[2])
    body.set(23, 9, INK)
    body.set(26, 10, INK)
    for fx in ((13, 18) if step == 0 else (15, 20)):
        body.rect(fx, 17, 2, 1, FUR[0])
    body.outline(INK)
    tail.blit(body, 0, 0)
    return tail


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


# ---------------------------------------------------------------- the pond

def pond(frame):
    """An oval garden pond, 132x92: a ring of rim stones, deep-to-shallow water, lily
    pads, and ripples that shift between the two frames."""
    import math
    W, H = 132, 92
    c = Canvas(W, H)
    cx, cy = W / 2, H / 2
    WATER = [hexc(h) for h in ("10283e", "183a58", "225070", "30688c", "5890b8", "a0d0f0")]
    # Rim stones.
    r = random.Random(21)
    for i in range(34):
        a = i / 34 * 6.283
        x = cx + math.cos(a) * 60 + r.uniform(-1.5, 1.5)
        y = cy + math.sin(a) * 40 + r.uniform(-1.5, 1.5)
        shaded_ellipse(c, x, y, r.uniform(4.5, 6.5), r.uniform(3.5, 5), STONE)
    # Water: darker in the middle (deeper), lighter at the edges.
    c.ellipse(cx, cy, 56, 36, None, lambda nx, ny: WATER[max(0, min(3, int((nx * nx + ny * ny) * 4)))])
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
    c.outline(INK)
    return c


# ---------------------------------------------------------------- props and the player on foot

def stone():
    c = Canvas(12, 10)
    shaded_ellipse(c, 6, 5, 5, 4, STONE)
    c.set(4, 3, STONE[4])
    c.set(7, 6, STONE[1])
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


def walker(step):
    """The player on foot, from above, facing right: arms swing as they walk."""
    c = Canvas(22, 22)
    cx, cy = 10, 11
    for k, dy in enumerate((-3, 3)):
        fwd = 3 if k == step else -3
        c.ellipse(cx + fwd, cy + dy, 2.4, 1.8, STEEL[1])
    for k, sy in enumerate((-7, 7)):
        fwd = -3 if k == step else 3
        c.ellipse(cx + fwd, cy + sy, 1.8, 1.8, P_SKIN[1])
    c.ellipse(cx, cy, 4.5, 7.5, None, lambda nx, ny: lit(P_SHIRT, nx, ny))
    c.ellipse(cx + 0.5, cy, 3.6, 3.6, None, lambda nx, ny: lit(P_CAP, nx, ny))
    c.rect(cx + 3, cy - 2, 2, 4, P_CAP[0])
    c.outline(INK)
    return c


def dog(step):
    """The customer's dog, side-on and bouncy: golden, floppy-eared, waggy."""
    c = Canvas(28, 20)
    FUR = [hexc(h) for h in ("5a3410", "8a5820", "c08a38", "e0b058", "f8d890")]
    c.ellipse(13, 11, 8, 5, None, lambda nx, ny: lit(FUR, nx, ny))
    c.ellipse(22, 7, 4.5, 4, None, lambda nx, ny: lit(FUR, nx, ny))
    c.rect(25, 7, 3, 3, FUR[3])                   # snout
    c.set(27, 7, INK)
    c.set(23, 6, INK)
    c.rect(20, 6, 2, 5, FUR[1])                   # ear
    tail_y = 5 if step == 0 else 7
    c.rect(2, tail_y, 4, 2, FUR[2])
    c.rect(4, tail_y + 1, 2, 3, FUR[2])
    for fx in ((8, 17) if step == 0 else (10, 15)):
        c.rect(fx, 15, 2, 4, FUR[1])
    c.rect(19, 10, 3, 2, RED[3])                  # collar
    c.outline(INK)
    return c


# ---------------------------------------------------------------- the customer, standing

def client(frame):
    """The customer on their patio, facing us (3/4 SNES RPG view). Key-coloured
    skin/hair/shirt so client.gd can swap them to match the portrait.
    Frames: 0 idle, 1 arms up in outrage, 2 knocked flat."""
    if frame == 2:
        return client_flat()
    c = Canvas(30, 30)
    c.blit(client_upright(frame), 6, 0)
    return c


def client_flat():
    c = Canvas(30, 30)
    TROUSER = [hexc(h) for h in ("1c1c28", "2c2c40", "40405a")]
    c.rect(2, 22, 9, 3, TROUSER[1])
    c.rect(2, 26, 9, 3, TROUSER[1])
    c.ellipse(15, 24, 6.5, 5, None, lambda nx, ny: K_SHIRT[1] if ny < 0.3 else K_SHIRT[0])
    c.ellipse(24, 24, 4.5, 4.5, None, lambda nx, ny: K_SKIN[1] if ny < 0.4 else K_SKIN[0])
    c.ellipse(26, 22, 3, 4, None, lambda nx, ny: K_HAIR[1])
    c.stamp(21, 23, ["x.x", ".x.", "x.x"], {"x": INK})
    for x, y in ((18, 13), (24, 11), (29, 15)):
        c.stamp(x - 1, y - 1, [".y.", "yyy", ".y."], {"y": hexc("f8e070")})
    c.outline(INK)
    return c


def client_upright(frame):
    c = Canvas(18, 30)
    TROUSER = [hexc(h) for h in ("1c1c28", "2c2c40", "40405a")]
    c.rect(5, 21, 3, 7, TROUSER[1])
    c.rect(10, 21, 3, 7, TROUSER[1])
    c.rect(5, 21, 1, 7, TROUSER[2])
    c.rect(4, 28, 4, 2, INK)
    c.rect(10, 28, 4, 2, INK)
    c.ellipse(9, 16, 5.5, 6.5, None, lambda nx, ny: K_SHIRT[1] if nx < 0.4 else K_SHIRT[0])
    if frame == 0:
        c.rect(2, 12, 2, 8, K_SHIRT[0])
        c.rect(14, 12, 2, 8, K_SHIRT[0])
        c.rect(2, 20, 2, 2, K_SKIN[1])
        c.rect(14, 20, 2, 2, K_SKIN[1])
    else:
        c.rect(1, 4, 2, 8, K_SHIRT[0])
        c.rect(15, 4, 2, 8, K_SHIRT[0])
        c.rect(1, 2, 2, 2, K_SKIN[1])
        c.rect(15, 2, 2, 2, K_SKIN[1])
    c.ellipse(9, 6.5, 5, 5.5, None,
              lambda nx, ny: K_SKIN[2] if nx < -0.2 and ny < 0 else (K_SKIN[0] if nx > 0.5 else K_SKIN[1]))
    c.ellipse(9, 3.5, 5.2, 3.2, None,
              lambda nx, ny: K_HAIR[2] if nx < -0.3 else (K_HAIR[0] if nx > 0.4 else K_HAIR[1]))
    c.set(7, 7, INK)
    c.set(11, 7, INK)
    if frame == 1:
        c.rect(8, 9, 3, 2, hexc("6e1e28"))
    else:
        c.rect(8, 9, 3, 1, K_SKIN[0])
    c.outline(INK)
    return c
