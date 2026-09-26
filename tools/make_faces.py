"""Customer portrait sheet: one 40x40 frame per expression, drawn in KEY colours
that face.gd swaps at runtime for each customer's skin, hair and shirt.

Run from the repo root: python tools/make_faces.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from canvas import Canvas, sheet, hexc  # noqa: E402

# Key colours (swapped per customer in face.gd). Keep in sync with face.gd KEYS.
SKIN_HI, SKIN, SKIN_SH = (255, 1, 1, 255), (254, 2, 2, 255), (253, 3, 3, 255)
HAIR_HI, HAIR, HAIR_SH = (1, 255, 1, 255), (2, 254, 2, 255), (3, 253, 3, 255)
SHIRT, SHIRT_SH = (1, 1, 255, 255), (2, 2, 254, 255)
# Angry skin: same shading ramp, swapped to a red-shifted skin.
ANG_HI, ANG, ANG_SH = (255, 1, 255, 255), (254, 2, 254, 255), (253, 3, 253, 255)

INK = hexc("281820")
WHITE = hexc("f4f0e6")
PUPIL = hexc("1e2040")
MOUTH = hexc("6e1e28")
TEETH = hexc("f6f2e8")
TONGUE = hexc("d85a64")
BLUSH = hexc("e88080")
SWEAT = hexc("7cc8f8")
STEAM = hexc("e8e8e8", 230)
STEAM_SH = hexc("b8b8c0", 230)
VEIN = hexc("c01830")

W = H = 40
FRAMES = ["delighted", "happy", "neutral", "annoyed", "furious", "horrified", "laughing", "fired", "hurt", "ko", "watch"]


def base(hair_style, angry=False):
    c = Canvas(W, H)
    hi, mid, sh = (ANG_HI, ANG, ANG_SH) if angry else (SKIN_HI, SKIN, SKIN_SH)

    # Shoulders and shirt.
    c.ellipse(20, 41, 17, 8, None, lambda nx, ny: SHIRT_SH if nx > 0.45 else SHIRT)
    # Neck.
    c.rect(16, 30, 8, 5, sh)
    # Ears.
    c.ellipse(8, 21, 2.2, 3.2, None, lambda nx, ny: sh if nx < 0 else mid)
    c.ellipse(32, 21, 2.2, 3.2, None, lambda nx, ny: sh)

    def skin(nx, ny):
        d = nx * 0.65 + ny * 0.45
        if d < -0.42:
            return hi
        if d > 0.5 or nx > 0.78:
            return sh
        return mid

    c.ellipse(20, 19.5, 12, 13.5, None, skin)

    # Hair styles, all in hair key colours.
    def hair(nx, ny):
        return HAIR_HI if (nx < -0.3 and ny < -0.2) else (HAIR_SH if nx > 0.5 else HAIR)

    if hair_style == 0:  # short
        c.ellipse(20, 11, 13, 7.5, None, hair)
        c.rect(8, 11, 3, 6, HAIR_SH)
        c.rect(29, 11, 3, 6, HAIR_SH)
    elif hair_style == 1:  # bald with sides
        c.rect(7, 15, 4, 7, HAIR)
        c.rect(29, 15, 4, 7, HAIR_SH)
        c.set(15, 8, SKIN_HI if not angry else ANG_HI)
    elif hair_style == 2:  # long
        c.ellipse(20, 10, 14, 6.5, None, hair)
        c.rect(6, 12, 5, 20, HAIR)
        c.rect(29, 12, 5, 20, HAIR_SH)
        c.rect(6, 12, 1, 20, HAIR_HI)
    elif hair_style == 3:  # bun
        c.ellipse(20, 11, 13, 6.5, None, hair)
        c.ellipse(20, 4, 5, 4, None, hair)
    else:  # curly
        for cx, cy in ((10, 11), (15, 7), (21, 6), (27, 8), (31, 13), (8, 16), (32, 18)):
            c.ellipse(cx, cy, 4.2, 4.2, None, hair)
    return c


PAL = {
    "k": INK, "w": WHITE, "p": PUPIL, "m": MOUTH, "t": TEETH, "g": TONGUE,
    "r": BLUSH, "d": SWEAT, "b": HAIR_SH, "s": SKIN_SH, "a": ANG_SH, "v": VEIN,
}

EYE_OPEN = ["kkkk", "wwpk", "wwpk", ".kk."]
EYE_WIDE = ["kkkk", "wwww", "wwpw", "wwww", "kkkk"]
EYE_HALF = ["kkkk", "wwpk", ".kk."]
EYE_ARC = [".kk.", "k..k"]            # ^ closed happy
EYE_SQUINT = ["kkkk", ".kk."]         # closed, laughing / furious
EYE_DOWN = ["kkkk", "wwwk", "ppwk", ".kk."]  # glancing down and left, at the watch


def eyes(c, rows, y, mirror_pupil=True):
    c.stamp(13, y, rows, PAL)
    right = [r[::-1] for r in rows] if mirror_pupil else rows
    c.stamp(23, y, right, PAL)


def brows(c, left, right, y):
    c.stamp(12, y, left, PAL)
    c.stamp(23, y, right, PAL)


# Each expression's mouth (x, y, rows), and the one it flaps to while talking: two
# frames per expression, alternated as the words come out.
MOUTH_ROWS = {
    "delighted": (15, 25, ["kkkkkkkkkk", "kttttttttk", ".kmmggmmk.", "..kkkkkk.."]),
    "happy": (15, 26, ["k......k", ".kkkkkk."]),
    "neutral": (16, 26, ["kkkkkk"]),
    "annoyed": (16, 26, [".kkkk.", "k....k"]),
    "furious": (14, 25, ["kkkkkkkkkkkk", "ktktktktktk.", "kkkkkkkkkkkk"]),
    "fired": (14, 25, ["kkkkkkkkkkkk", "kmmmmmmmmmmk", "kttttttttttk", "kkkkkkkkkkkk"]),
    "horrified": (17, 24, [".kkkk.", "kmmmmk", "kmggmk", "kmmmmk", ".kkkk."]),
    "laughing": (14, 24, ["kkkkkkkkkkkk", "kttttttttttk", "kmmmmggmmmmk", ".kmmmmmmmmk.", "..kkkkkkkk.."]),
    "hurt": (14, 25, ["kkkkkkkkkkkk", "ktktktktktkk", "kkkkkkkkkkkk"]),
    "ko": (16, 25, [".kkkkk.", "kgggggk", ".kkkkk."]),
    "watch": (16, 26, ["kkkkk."]),
}
TALK_ROWS = {  # open where the resting mouth is shut and shut where it's open, so it reads
    "delighted": (15, 26, ["k........k", ".kkkkkkkk."]),
    "happy": (15, 24, ["kkkkkkkk", "kttttttk", "kmmggmmk", "kmmmmmmk", ".kkkkkk."]),
    "neutral": (16, 24, [".kkkk.", "kmmmmk", "kmggmk", "kmmmmk", ".kkkk."]),
    "annoyed": (16, 24, ["kkkkkk", "kmmmmk", "kmggmk", ".kkkk."]),
    "furious": (14, 23, ["kkkkkkkkkkkk", "kttttttttttk", "kmmmmmmmmmmk", "kmmmggggmmmk", "kttttttttttk", "kkkkkkkkkkkk"]),
    "fired": (14, 26, ["kkkkkkkkkkkk", "ktktktktktkk", "kkkkkkkkkkkk"]),
    "horrified": (16, 26, [".kkkkk.", "kmmmmmk", ".kkkkk."]),
    "laughing": (14, 26, ["kkkkkkkkkkkk", "kttttttttttk", "kkkkkkkkkkkk"]),
    "hurt": (14, 24, ["kkkkkkkkkkkk", "kttttttttttk", "kmmmmmmmmmmk", "kmmmggggmmmk", "kkkkkkkkkkkk"]),
    "ko": (16, 25, [".kkkkk.", "kgggggk", ".kkkkk."]),  # out cold: no talking
    "watch": (16, 24, [".kkkk.", "kmmmmk", "kmggmk", ".kkkk."]),
}


def draw(name, style, talk=False):
    angry = name in ("furious", "fired")
    c = base(style, angry)
    skin_sh = "a" if angry else "s"
    # Nose.
    c.stamp(19, 21, [skin_sh, skin_sh + skin_sh], {**PAL})

    if name == "delighted":
        brows(c, ["bbbb"], ["bbbb"], 15)
        eyes(c, EYE_ARC, 18)
        c.stamp(10, 23, ["rr"], PAL)
        c.stamp(28, 23, ["rr"], PAL)
    elif name == "happy":
        brows(c, ["bbbb"], ["bbbb"], 15)
        eyes(c, EYE_OPEN, 17)
    elif name == "neutral":
        brows(c, ["bbbb"], ["bbbb"], 15)
        eyes(c, EYE_OPEN, 17)
    elif name == "annoyed":
        brows(c, ["bb..", "..bb"], ["bb..", "..bb"][::-1], 14)
        brows(c, ["bb..", "..bb"], ["..bb", "bb.."], 14)
        eyes(c, EYE_HALF, 18)
    elif name in ("furious", "fired"):
        brows(c, ["b...", "bb..", ".bbb"], ["...b", "..bb", "bbb."], 13)
        eyes(c, EYE_HALF, 17)
        # Anger vein.
        c.stamp(27, 9, ["v.v", ".v.", "v.v"], PAL)
        # Steam puffs from the ears.
        for (x, y, r) in ((3, 12, 3.2), (1, 7, 2.6), (37, 12, 3.2), (39, 7, 2.6)):
            c.ellipse(x, y, r, r, None, lambda nx, ny: STEAM_SH if ny > 0.3 else STEAM)
        if name == "fired":
            for (x, y, r) in ((4, 3, 2.4), (36, 3, 2.4), (20, 1, 2.0)):
                c.ellipse(x, y, r, r, None, lambda nx, ny: STEAM_SH if ny > 0.3 else STEAM)
    elif name == "horrified":
        brows(c, ["..bb", "bb.."], ["bb..", "..bb"], 12)
        c.stamp(12, 16, EYE_WIDE, PAL)
        c.stamp(23, 16, EYE_WIDE, PAL)
        c.stamp(31, 12, [".d.", "ddd", "ddd", ".d."], PAL)
    elif name == "laughing":
        brows(c, ["bbbb"], ["bbbb"], 14)
        eyes(c, EYE_SQUINT, 18)
        c.stamp(11, 20, ["d", "d"], PAL)
        c.stamp(28, 20, ["d", "d"], PAL)
    elif name == "hurt":
        # The Doom-guy special: a black eye, a bloody brow and nose, gritted pain.
        brows(c, ["b...", ".bbb"], ["bb..", "..bb"], 14)
        c.stamp(13, 17, ["kkkk", "wwpk", ".kk."], PAL)
        c.stamp(22, 16, [".uuuu.", "uukkuu", "uukkuu", ".uuuu."], {**PAL, "u": hexc("5a3a6a")})
        c.stamp(15, 8, ["...v", "..vv", ".vv.", "vv..", "v..."], PAL)
        c.stamp(19, 22, ["v", "v", "vv"], PAL)
        c.stamp(29, 22, ["v", "vv"], PAL)
    elif name == "ko":
        c.stamp(13, 17, ["k..k", ".kk.", ".kk.", "k..k"], PAL)
        c.stamp(23, 17, ["k..k", ".kk.", ".kk.", "k..k"], PAL)
        c.stamp(22, 12, ["vvv", "v.v"], PAL)
        for (x, y) in ((5, 5), (17, 1), (31, 4)):
            c.stamp(x, y, [".y.", "yyy", ".y."], {"y": hexc("f8e070")})
    elif name == "watch":
        # Patience running low: a glance down at the watch on a raised wrist.
        brows(c, ["bbbb"], ["bbbb"], 16)
        eyes(c, EYE_DOWN, 18, mirror_pupil=False)
        c.ellipse(3, 38, 7, 6, None, lambda nx, ny: SHIRT_SH if ny > 0.4 else SHIRT)  # sleeve
        for i in range(10):                                                        # forearm, raised
            c.rect(3 + i, 33 - i, 4, 4, SKIN_SH if i < 2 else SKIN)
        c.ellipse(15, 24, 3, 2.8, None, lambda nx, ny: SKIN_SH if ny > 0.3 else SKIN)  # fist
        c.rect(7, 25, 6, 6, INK)                                                   # strap
        c.rect(7, 26, 5, 4, hexc("d8b048"))                                        # the watch
        c.rect(8, 27, 3, 2, WHITE)
    mx, my, rows = (TALK_ROWS if talk else MOUTH_ROWS)[name]
    c.stamp(mx, my, rows, PAL)
    c.outline(INK)
    return c


def main():
    out = os.path.join(os.path.dirname(__file__), "..", "art")
    os.makedirs(out, exist_ok=True)
    # Per hair style: every expression, then every expression mid-word (face.gd FRAMES).
    rows = [sheet([draw(n, style) for n in FRAMES] + [draw(n, style, True) for n in FRAMES]) for style in range(5)]
    full = Canvas(rows[0].w, H * len(rows))
    for i, r in enumerate(rows):
        full.blit(r, 0, i * H)
    full.save(os.path.join(out, "faces.png"))
    preview = os.environ.get("PREVIEW")
    if preview:
        swap = {
            SKIN_HI: hexc("f8d0a8"), SKIN: hexc("e8b088"), SKIN_SH: hexc("c08060"),
            ANG_HI: hexc("f8a088"), ANG: hexc("e87060"), ANG_SH: hexc("b04038"),
            HAIR_HI: hexc("a07040"), HAIR: hexc("704820"), HAIR_SH: hexc("4a2c14"),
            SHIRT: hexc("4878c8"), SHIRT_SH: hexc("305090"),
        }
        pv = Canvas(full.w, full.h, hexc("406030"))
        for y in range(full.h):
            for x in range(full.w):
                c = full.px[y][x]
                if c[3]:
                    pv.px[y][x] = swap.get(c, c)
        pv.scaled(3).save(preview)


if __name__ == "__main__":
    main()
