"""Tiny voxel renderer for things that turn: each is modelled once in 3D (1 voxel =
1 world px) and rendered at 8 facings in the game's 3/4 projection, so every facing
agrees. Pure stdlib.

Model axes: x forward, y to the right, z up; the origin is the body's centre on the
ground. Facing k turns the model k * 45 degrees clockwise on screen (0 east, 2 south).
Sheets: one row per facing, one column per animation frame. Cells are sized so the
origin is the cell's centre: the game's centred Sprite2D needs no offset.
"""
import math
import random

from canvas import Canvas, hexc
from make_art import INK, STEEL, RED, YELLOW, BLUE, WOOD, LEAF, P_SKIN, P_SHIRT, P_CAP, K_SKIN, K_HAIR, K_SHIRT

F, G = 0.9, 0.6          # height -> screen px, depth -> screen px (as the house art)
LIGHT = (-0.45, 0.35, 0.82)
FACES = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1))
S3 = (0.17, 0.5, 0.83)


class Model:
    def __init__(self):
        self.v = {}

    def put(self, x, y, z, ramp):
        self.v[(x, y, z)] = ramp

    def box(self, x0, x1, y0, y1, z0, z1, ramp):
        """Fill [x0,x1) x [y0,y1) x [z0,z1)."""
        for x in range(math.floor(x0), math.ceil(x1)):
            for y in range(math.floor(y0), math.ceil(y1)):
                for z in range(math.floor(z0), math.ceil(z1)):
                    self.v[(x, y, z)] = ramp

    def ellipsoid(self, cx, cy, cz, rx, ry, rz, ramp, zmin=-1e9, paint=None):
        for x in range(math.floor(cx - rx), math.ceil(cx + rx) + 1):
            for y in range(math.floor(cy - ry), math.ceil(cy + ry) + 1):
                for z in range(max(math.floor(cz - rz), math.floor(zmin)), math.ceil(cz + rz) + 1):
                    nx, ny, nz = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry, (z + 0.5 - cz) / rz
                    if nx * nx + ny * ny + nz * nz <= 1.0:
                        self.v[(x, y, z)] = paint(nx, ny, nz) if paint else ramp

    def wheel(self, cx, cy, cz, r, y0, y1, tyre, hub, phase=0):
        """A wheel on an axle across y, from y0 to y1; tread blocks roll with phase."""
        for x in range(math.floor(cx - r), math.ceil(cx + r) + 1):
            for z in range(max(0, math.floor(cz - r)), math.ceil(cz + r) + 1):
                dx, dz = x + 0.5 - cx, z + 0.5 - cz
                d = math.hypot(dx, dz)
                if d > r:
                    continue
                ramp = hub if d < r * 0.45 else tyre
                if d > r - 1.2 and int((math.atan2(dz, dx) / 6.283 * 10 + phase * 0.5) % 2):
                    ramp = tyre[:-1]
                for y in range(math.floor(y0), math.ceil(y1)):
                    self.v[(x, y, z)] = ramp

    def line(self, a, b, r, ramp):
        """A rod from a to b, r thick."""
        n = int(max(abs(b[i] - a[i]) for i in range(3)) * 2) + 1
        for i in range(n + 1):
            t = i / n
            p = [a[k] + (b[k] - a[k]) * t for k in range(3)]
            self.ellipsoid(p[0], p[1], p[2], r, r, r, ramp)

    def extent(self):
        R = max(math.hypot(x + 0.5, y + 0.5) for x, y, _ in self.v) + 1.5
        top = max(z for _, _, z in self.v) + 1
        return R, top


def render(m, facing, W, H):
    """Render m turned to facing (0..7) into a W x H canvas, origin at its centre."""
    a = math.radians(facing * 45)
    ca, sa = math.cos(a), math.sin(a)
    ox, oy = W / 2, H / 2
    c = Canvas(W, H)
    zbuf = {}
    for (x, y, z), ramp in m.v.items():
        for n in FACES:
            if (x + n[0], y + n[1], z + n[2]) in m.v:
                continue
            nx, ny, nz = n[0] * ca - n[1] * sa, n[0] * sa + n[1] * ca, n[2]
            if ny * F + nz * G <= 0.0:
                continue                                   # faces away from us
            lam = nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]
            t = max(0.0, min(1.0, 0.5 + lam * 0.6))
            col = ramp[min(len(ramp) - 1, int(t * len(ramp)))]
            for u in S3:
                for w in S3:
                    if n[2]:
                        px, py, pz = x + u, y + w, z + 1
                    elif n[0]:
                        px, py, pz = x + (n[0] > 0), y + u, z + w
                    else:
                        px, py, pz = x + u, y + (n[1] > 0), z + w
                    rx, ry = px * ca - py * sa, px * sa + py * ca
                    ix, iy = math.floor(ox + rx), math.floor(oy + ry * G - pz * F)
                    d = ry * F + pz * G
                    if 0 <= ix < W and 0 <= iy < H and d > zbuf.get((ix, iy), -1e9):
                        zbuf[(ix, iy)] = d
                        c.px[iy][ix] = col
    c.outline(INK)
    return c


def sheet(frames):
    """frames: models, one per animation frame. Returns the 8-facing sheet."""
    R = top = 0
    for m in frames:
        r, t = m.extent()
        R, top = max(R, r), max(top, t)
    W = math.ceil(R) * 2 + 4
    H = math.ceil(max(top * F + R * G, R * G)) * 2 + 4
    out = Canvas(W * len(frames), H * 8)
    for k in range(8):
        for i, m in enumerate(frames):
            out.blit(render(m, k, W, H), i * W, k * H)
    return out


# ---------------------------------------------------------------- people

TROUSER = [hexc(h) for h in ("1c2438", "2a3858", "3c5078", "5068a0")]
SHOE = STEEL[:3]
SKIN = P_SKIN
SHIRT = [P_SHIRT[0], P_SHIRT[1], P_SHIRT[2], hexc("64c080")]
CAP = [P_CAP[0], P_CAP[1], P_CAP[2], hexc("f07058")]
EYE = [INK]


def person(m, x, step, arms_to=None, seated=False, z0=0, shirt=SHIRT, skin=SKIN, hair=None):
    """A person facing +x, standing at (x, 0, z0): legs stride with step (0/1, or None
    standing still); arms reach to arms_to (two points) or swing. The player by
    default (the red cap); pass shirt/skin/hair ramps for anyone else."""
    if seated:
        for s in (-1, 1):
            m.box(x - 2, x + 9, s * 4 - 2, s * 4 + 2, z0, z0 + 4, TROUSER)       # thighs
            m.box(x + 7, x + 10, s * 4 - 2, s * 4 + 2, z0 - 9, z0 + 1, TROUSER)  # shins
        hip = z0 + 3
    else:
        for s, fwd in ((-1, 2), (1, -2)):
            dx = 0 if step is None else (fwd if step == 0 else -fwd)
            m.box(x - 2 + dx, x + 2 + dx, s * 3 - 2, s * 3 + 2, z0 + 2, z0 + 11, TROUSER)
            m.box(x - 2 + dx, x + 3 + dx, s * 3 - 2, s * 3 + 2, z0, z0 + 2, SHOE)
        hip = z0 + 11
    m.box(x - 4, x + 4, -6, 6, hip, hip + 12, shirt)
    for s, fwd in ((-1, -3), (1, 3)):
        sh = (x, s * 7, hip + 10)
        if arms_to:
            hand = arms_to[0 if s < 0 else 1]
        else:
            dx = 0 if step is None else (fwd if step == 0 else -fwd)
            hand = (x + dx, s * 7.5, hip + 3)
        m.line(sh, hand, 1.3, shirt)
        m.ellipsoid(hand[0], hand[1], hand[2], 1.4, 1.4, 1.4, skin)
    hz = hip + 17
    m.ellipsoid(x, 0, hz, 4.6, 4.6, 4.6, skin)
    if hair:
        m.ellipsoid(x - 1.6, 0, hz + 1.6, 4.6, 5, 3.6, hair, zmin=hz + 2)
        m.ellipsoid(x - 1.8, 0, hz, 3.6, 4.9, 4.4, hair, zmin=hz - 3)          # the back of the head
    else:
        m.ellipsoid(x - 0.3, 0, hz + 1.5, 5, 5, 3.4, CAP, zmin=hz + 1)
        m.box(x + 3, x + 7, -3, 3, hz + 1, hz + 2, CAP[:2])                      # the peak
    for s in (-2, 1):
        m.put(math.floor(x + 4), s, math.floor(hz), EYE)


def client(frame):
    """The customer, in the portrait's key colours (Face.swapped recolours them).
    Frames: 0 standing, 1 arms up in outrage, 2 knocked flat, seeing stars."""
    m = Model()
    if frame == 2:
        for s in (-3, 3):
            m.box(-14, -3, s - 2, s + 2, 0, 3, TROUSER)
        m.box(-3, 9, -6, 6, 0, 4, K_SHIRT)
        for s in (-8, 8):
            m.box(-1, 7, s - 1, s + 1, 0, 2, K_SHIRT)
        m.ellipsoid(13, 0, 3, 4.4, 4.4, 3.4, K_SKIN)
        m.ellipsoid(15.5, 0, 3, 2.4, 4.6, 3.2, K_HAIR)
        for sx, sy, sz in ((10, -6, 11), (14, 5, 12), (18, -1, 13)):
            m.box(sx, sx + 2, sy, sy + 2, sz, sz + 2, YELLOW[3:])
        return m
    up = ((0, -8, 34), (0, 8, 34)) if frame == 1 else None
    person(m, 0, None, arms_to=up, shirt=K_SHIRT, skin=K_SKIN, hair=K_HAIR)
    return m


# ---------------------------------------------------------------- mowers

def petrol(step, rider=True):
    m = Model()
    for wx in (-10, 10):
        m.wheel(wx, 0, 4, 4, -15, -12, STEEL[:3], STEEL[2:5], step)
        m.wheel(wx, 0, 4, 4, 12, 15, STEEL[:3], STEEL[2:5], step)
    m.box(-15, 15, -12, 12, 2, 8, RED)
    m.box(-15, 15, -12, 12, 7, 8, RED[1:])                                     # the deck's lip
    m.ellipsoid(2, 0, 11, 7, 7, 4, STEEL[1:], zmin=8)                          # engine
    m.box(6, 9, -5, -2, 13, 16, YELLOW)                                        # fuel cap
    m.box(-4, -2, 3, 5, 14, 16, STEEL[3:])                                     # pull cord
    for s in (-9, 9):
        m.line((-14, s, 8), (-29, s, 22), 0.8, STEEL[1:])
    m.box(-31, -28, -10, 10, 22, 24, STEEL[1:])
    if rider:
        person(m, -35, step, arms_to=((-30, -9, 23), (-30, 9, 23)))
    return m


def push(step, rider=True):
    GREEN = [hexc(h) for h in ("123a1c", "1e5a2a", "2c7a38", "44a050", "68c070")]
    m = Model()
    for s in (-1, 1):
        m.wheel(0, 0, 6, 6, s * 11 - 1.5, s * 11 + 1.5, STEEL[:3], GREEN[2:], step)
        m.box(-9, 6, s * 9 - 1, s * 9 + 1, 2, 9, GREEN)                          # side plates
    for x in range(-4, 5):                                                     # the reel's blades
        for z in range(2, 11):
            if math.hypot(x + 0.5, z + 0.5 - 6) <= 4.5:
                lit = (int(math.atan2(z - 5.5, x + 0.5) / 6.283 * 6 + step * 0.5)) % 2
                m.box(x, x + 1, -8, 8, z, z + 1, STEEL[3:] if lit else STEEL[1:4])
    m.box(-11, -8, -8, 8, 1, 4, STEEL[1:])                                     # rear roller
    for s in (-5, 5):
        m.line((-9, s, 7), (-24, s, 22), 0.8, WOOD[1:])
    m.box(-26, -23, -6, 6, 22, 24, WOOD[1:])
    if rider:
        person(m, -29, step, arms_to=((-24, -5, 23), (-24, 5, 23)))
    return m


def rideon(step, rider=True):
    m = Model()
    m.box(-10, 13, -21, 21, 2, 5, STEEL[:4])                                   # cutting deck
    for s in (-1, 1):
        m.wheel(-14, 0, 8, 8, s * 17 - 3, s * 17 + 3, STEEL[:3], YELLOW[1:4], step)
        m.wheel(17, 0, 5, 5, s * 15 - 2, s * 15 + 2, STEEL[:3], YELLOW[1:4], step)
    m.box(-24, 24, -13, 13, 6, 15, YELLOW)                                     # body
    m.box(6, 25, -11, 11, 15, 20, YELLOW)                                      # bonnet
    m.box(24, 26, -8, 8, 8, 18, STEEL[:3])                                     # grille
    for s in (-9, 7):
        m.box(24, 26, s, s + 2, 15, 18, [hexc("fff8c0")])                      # lamps
    m.box(-14, -4, -8, 8, 15, 18, STEEL[:4])                                   # seat
    m.box(-16, -13, -8, 8, 18, 27, STEEL[:4])
    m.line((5, 0, 20), (1, 0, 27), 0.8, STEEL[1:])                             # steering
    m.ellipsoid(1, 0, 27.5, 1.5, 4, 0.8, STEEL[1:4])
    if rider:
        person(m, -9, None, arms_to=((1, -3, 27), (1, 3, 27)), seated=True, z0=18)
    return m


def walker(step):
    m = Model()
    person(m, 0, step)
    return m


# ---------------------------------------------------------------- critters

def hedgehog(step):
    SP = [hexc(h) for h in ("2a1c14", "4a3222", "6a4a30", "8a6844", "b08c60")]
    FACE = [hexc("a07858"), hexc("d0a880"), hexc("f0d0a8")]
    m = Model()
    r = random.Random(3)
    m.ellipsoid(-1, 0, 5, 8, 6, 5, SP, paint=lambda nx, ny, nz: SP[1:] if r.random() < 0.3 else SP)
    m.ellipsoid(7, 0, 3.5, 3.5, 2.8, 2.6, FACE)
    m.put(10, 0, 3, EYE)
    for s in (-2, 1):
        m.put(8, s, 5, EYE)
    for fx, fy in ((-4, -4), (3, 3)) if step == 0 else ((-2, 3), (5, -4)):
        m.box(fx, fx + 2, fy, fy + 2, 0, 1, FACE[:2])
    return m


def squirrel(step):
    FUR = [hexc(h) for h in ("2e2e34", "4e4e58", "74747e", "9a9aa4", "c8c8d0")]
    BELLY = [hexc("b8b0a0"), hexc("e8e0d0")]
    m = Model()
    m.ellipsoid(0, 0, 5, 6, 3.5, 4.5, FUR, paint=lambda nx, ny, nz: BELLY if nz < -0.3 else FUR)
    m.ellipsoid(6, 0, 9, 3.6, 3.2, 3.4, FUR)
    for s in (-2, 1):
        m.box(5, 6, s, s + 1, 12, 14, FUR[2:])                                 # ears
        m.put(8, s, 10, EYE)
    bob = 1 if step else 0
    for (x, z, rr) in ((-6, 7, 2.8), (-8.5, 11 + bob, 3.6), (-7, 16 + bob, 3.6), (-4.5, 18 + bob, 2.6)):
        m.ellipsoid(x, 0, z, rr, 2.6, rr, FUR[1:])
    for fx in ((-3, 3) if step == 0 else (-1, 5)):
        m.box(fx, fx + 2, -2, 2, 0, 1, FUR[:2])
    return m


def dog(step):
    FUR = [hexc(h) for h in ("5a3410", "8a5820", "c08a38", "e0b058", "f8d890")]
    m = Model()
    for (lx, ly), fwd in (((-6, -4), 1), ((-6, 2), -1), ((5, -4), -1), ((5, 2), 1)):
        dx = fwd if step == 0 else -fwd
        m.box(lx + dx, lx + dx + 2, ly, ly + 2, 0, 7, FUR[:4])
    m.ellipsoid(0, 0, 9, 9, 4.5, 4.5, FUR)
    m.ellipsoid(9, 0, 14, 4.2, 3.8, 4, FUR)
    m.ellipsoid(13, 0, 13, 2.6, 2, 2, FUR[1:])
    m.put(15, 0, 13, EYE)
    for s in (-1, 1):
        m.put(11, s * 2 - (1 if s < 0 else 0), 15, EYE)
        m.box(7, 9, s * 4 - 1, s * 4 + 1, 10, 15, FUR[:3])                     # floppy ears
    m.box(5, 7, -4, 4, 10, 12, RED[1:4])                                       # collar
    m.line((-9, 0, 11), (-13, 3 if step == 0 else -3, 14), 1, FUR[1:])         # wagging
    return m
