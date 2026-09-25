"""Chiptune-ish sound effects and music for Super Landscaper, synthesised with the
standard library only. Run from the repo root: python tools/make_audio.py

Writes 16-bit mono WAVs into audio/. Loops carry a 'smpl' chunk so Godot's
importer loops them automatically (loop mode "Detect From WAV").
"""
import math
import os
import random
import struct

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
rng = random.Random(1)


def write(name, samples, loop=False):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = min(1.0, 0.9 / peak)
    data = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32767)) for s in samples)
    chunks = b"fmt " + struct.pack("<IHHIIHH", 16, 1, 1, RATE, RATE * 2, 2, 16)
    chunks += b"data" + struct.pack("<I", len(data)) + data
    if loop:
        smpl = struct.pack("<IIIIIIIII", 0, 0, int(1e9 / RATE), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<IIIIII", 0, 0, 0, len(samples) - 1, 0, 0)
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    with open(os.path.join(OUT, name + ".wav"), "wb") as f:
        f.write(b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks)


def n(seconds):
    return int(seconds * RATE)


def square(ph, duty=0.5):
    return 1.0 if (ph % 1.0) < duty else -1.0


def tri(ph):
    p = ph % 1.0
    return 4 * p - 1 if p < 0.5 else 3 - 4 * p


def noise():
    return rng.uniform(-1, 1)


def env(i, total, attack=0.005, release=0.1):
    t = i / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    rem = (total - i) / RATE
    r = min(1.0, rem / release) if release > 0 else 1.0
    return a * r


def lowpass(samples, k):
    out, y = [], 0.0
    for s in samples:
        y += k * (s - y)
        out.append(y)
    return out


# ---------------------------------------------------------------- engines (loops)

def engine(base_hz, cycles, roughness, name):
    """A putter: a pulse per engine firing with a little noise, a whole number
    of cycles long so the loop point is seamless."""
    total = int(RATE * cycles / base_hz)
    out = []
    for i in range(total):
        ph = i * base_hz / RATE
        p = ph % 1.0
        thump = math.exp(-p * 7.0) * (1.0 if int(ph) % 2 == 0 else 0.75)
        s = thump * math.sin(p * 6.283 * 2.0) * 0.8 + square(ph * 4, 0.3) * 0.08 + noise() * roughness * thump
        out.append(s)
    write(name, lowpass(out, 0.35), loop=True)


def reel():
    """The push mower: a ratcheting whirr of reel blades."""
    total = n(1.0)
    out = []
    for i in range(total):
        ph = i * 14.0 / RATE
        p = ph % 1.0
        click = math.exp(-p * 30.0)
        out.append(noise() * click * 0.8 + math.sin(i * 6.283 * 900 / RATE) * click * 0.2)
    write("reel", lowpass(out, 0.5), loop=True)


# ---------------------------------------------------------------- one-shots

def squash():
    total = n(0.35)
    out = []
    for i in range(total):
        t = i / RATE
        f = 180 * (1 - t * 2.2)
        out.append((noise() * 0.7 + math.sin(t * 6.283 * max(40, f)) * 0.6) * env(i, total, 0.002, 0.2))
    write("squash", lowpass(out, 0.25))


def squeak(base, name):
    total = n(0.18)
    out = []
    ph = 0.0
    for i in range(total):
        t = i / RATE
        f = base * (1 + 0.6 * math.sin(t * 60))
        ph += f / RATE
        out.append(square(ph, 0.25) * env(i, total, 0.005, 0.08) * 0.6)
    write(name, out)


def crunch():
    total = n(0.22)
    out = [noise() * env(i, total, 0.001, 0.15) * (0.5 + 0.5 * (i % 300 < 120)) for i in range(total)]
    write("crunch", lowpass(out, 0.4))


def voice(notes, name, duty=0.5, rough=0.0):
    """Animal-Crossing-style gibberish: a quick run of blips at given pitches."""
    out = []
    for hz in notes:
        total = n(0.07)
        ph = 0.0
        for i in range(total):
            ph += hz / RATE
            out.append((square(ph, duty) * 0.5 + noise() * rough) * env(i, total, 0.004, 0.03))
        out.extend([0.0] * n(0.015))
    write(name, lowpass(out, 0.6))


def glug():
    total = n(0.9)
    out = []
    ph = 0.0
    for i in range(total):
        t = i / RATE
        bub = (t * 7.0) % 1.0
        f = 140 + 220 * bub
        ph += f / RATE
        out.append(math.sin(ph * 6.283) * math.exp(-bub * 5.0) * 0.7)
    write("glug", lowpass(out, 0.3), loop=True)


def splash():
    """A stone into a pond: a bloop dropping in pitch, then a hiss of spray."""
    total = n(0.5)
    out = []
    ph = 0.0
    y = 0.0
    for i in range(total):
        t = i / RATE
        ph += (900 * math.exp(-t * 18) + 180) / RATE
        s = math.sin(ph * 6.283) * math.exp(-t * 14) * 0.6
        y += 0.25 * (noise() - y)
        s += y * math.exp(-t * 7) * min(1.0, t / 0.03) * 0.8
        out.append(s)
    write("splash", lowpass(out, 0.5))


def cash():
    total = n(0.9)
    out = []
    for i in range(total):
        t = i / RATE
        s = noise() * math.exp(-t * 40) * 0.4
        for f, delay in ((1318.5, 0.05), (1760.0, 0.12)):
            if t > delay:
                s += square((t - delay) * f, 0.5) * math.exp(-(t - delay) * 6) * 0.25
        out.append(s)
    write("cash", out)


def fired():
    total = n(1.0)
    out = []
    ph = 0.0
    for i in range(total):
        t = i / RATE
        f = 220 * (1 - t * 0.55)
        ph += f / RATE
        out.append((square(ph, 0.5) * 0.4 + square(ph * 1.01, 0.3) * 0.3) * env(i, total, 0.01, 0.2))
    write("fired", out)


def beep(hz, dur, name, duty=0.5, vol=0.5):
    total = n(dur)
    write(name, [square(i * hz / RATE, duty) * vol * env(i, total, 0.002, dur * 0.4) for i in range(total)])


def clonk():
    """Metal on stone: a bright ringing hit."""
    total = n(0.3)
    out = []
    for i in range(total):
        t = i / RATE
        s = sum(math.sin(t * 6.283 * f) * a for f, a in ((620, 0.5), (1480, 0.3), (2330, 0.2)))
        out.append((s * math.exp(-t * 14) + noise() * math.exp(-t * 80) * 0.6))
    write("clonk", out)


def thud():
    total = n(0.2)
    write("thud", lowpass([(math.sin(i * 6.283 * 90 / RATE * (1 - i / total * 0.5)) + noise() * 0.4)
                           * env(i, total, 0.001, 0.15) for i in range(total)], 0.15))


def glass():
    """A window going: a burst of noise and a scatter of high tinkles."""
    total = n(0.9)
    out = [noise() * math.exp(-i / RATE * 18) * 0.8 for i in range(total)]
    for _ in range(22):
        start = rng.randrange(n(0.03), n(0.7))
        f = rng.uniform(2400, 5200)
        for k in range(n(0.08)):
            if start + k < total:
                t = k / RATE
                out[start + k] += math.sin(t * 6.283 * f) * math.exp(-t * 45) * 0.35
    write("glass", out)


def yelp():
    total = n(0.25)
    out = []
    ph = 0.0
    for i in range(total):
        t = i / RATE
        f = 900 + 700 * math.sin(min(1.0, t * 8) * 3.14)
        ph += f / RATE
        out.append(square(ph, 0.35) * env(i, total, 0.005, 0.1) * 0.5)
    write("yelp", lowpass(out, 0.5))


def bump():
    total = n(0.15)
    write("bump", lowpass([(noise() * 0.6 + math.sin(i * 6.283 * 70 / RATE)) * env(i, total, 0.001, 0.1) for i in range(total)], 0.2))


# ---------------------------------------------------------------- music

NOTE = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def hz(name):
    """'A4' -> 440."""
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((NOTE[pitch] + (octave - 4) * 12 - 9) / 12)


def song(bpm, lead, bass, drums, name, lead_duty=0.25):
    """Each part is a list of (note or None, length in 16ths). drums: a string per
    16th: k kick, s snare, h hat, . rest. Parts loop to the lead's length."""
    step = 60.0 / bpm / 4
    total_steps = sum(l for _, l in lead)
    total = n(total_steps * step)
    buf = [0.0] * total

    def render(part, fn, vol):
        pos = 0
        for note, length in part:
            start, end = n(pos * step), n((pos + length) * step)
            if note:
                f = hz(note)
                for i in range(start, min(end, total)):
                    k = i - start
                    buf[i] += fn(k * f / RATE) * vol * env(k, end - start, 0.004, min(0.08, (end - start) / RATE * 0.5))
            pos += length
    render(lead, lambda ph: square(ph, lead_duty), 0.22)
    render(bass, tri, 0.35)
    for i_step in range(total_steps):
        d = drums[i_step % len(drums)]
        start = n(i_step * step)
        length = n(0.12)
        for k in range(length):
            if start + k >= total:
                break
            t = k / RATE
            if d == "k":
                buf[start + k] += math.sin(6.283 * 60 * t * (1 - t * 3)) * math.exp(-t * 25) * 0.5
            elif d == "s":
                buf[start + k] += noise() * math.exp(-t * 30) * 0.25
            elif d == "h":
                buf[start + k] += noise() * math.exp(-t * 90) * 0.1
    write(name, buf, loop=True)


def mowing_song():
    # A bouncy 8-bar tune in C major, 132 bpm.
    lead = []
    phrase_a = [("E5", 2), ("G5", 2), ("C6", 2), ("G5", 2), ("A5", 3), ("G5", 1), ("E5", 2), ("D5", 2),
                ("C5", 2), ("D5", 2), ("E5", 2), ("G5", 2), ("D5", 6), (None, 2)]
    phrase_b = [("E5", 2), ("G5", 2), ("C6", 2), ("D6", 2), ("E6", 3), ("D6", 1), ("C6", 2), ("A5", 2),
                ("G5", 2), ("E5", 2), ("D5", 2), ("E5", 2), ("C5", 6), (None, 2)]
    lead = phrase_a + phrase_b + phrase_a + phrase_b
    bass = []
    for root in ["C3", "A2", "F2", "G2", "C3", "A2", "G2", "C3"] * 2:
        bass += [(root, 2), (None, 2), (root, 2), (None, 2)]
    song(132, lead, bass, "k.h.s.h.k.k.s.h.", "music_mowing")


def menu_song():
    # A relaxed 8-bar tune in F, 96 bpm.
    lead = [("A4", 4), ("C5", 4), ("F5", 6), ("E5", 2), ("D5", 4), ("C5", 4), ("A4", 8),
            ("G4", 4), ("A4", 4), ("A#4", 6), ("C5", 2), ("A4", 8), (None, 8),
            ("A4", 4), ("C5", 4), ("F5", 6), ("G5", 2), ("A5", 4), ("G5", 4), ("F5", 8),
            ("E5", 4), ("D5", 4), ("C5", 4), ("E5", 4), ("F5", 12), (None, 4)]
    bass = []
    for root in ["F2", "D2", "A#2", "C3", "F2", "D2", "G2", "C3"]:
        bass += [(root, 4), (None, 2), (root, 2), (root, 4), (None, 4)]
    song(96, lead, bass, "k...h...s...h...", "music_menu", lead_duty=0.5)


def main():
    engine(28.0, 28, 0.35, "engine_petrol")
    engine(20.0, 20, 0.5, "engine_rideon")
    reel()
    squash()
    squeak(1400, "squeak_hedgehog")
    squeak(2200, "squeak_squirrel")
    crunch()
    voice([520, 660, 780, 880], "voice_happy")
    voice([700, 820, 700, 980, 1100], "voice_laugh", duty=0.3)
    voice([240, 200, 220, 170], "voice_angry", duty=0.5, rough=0.15)
    voice([1200, 1100, 1300, 900, 1250, 800], "voice_horrified", duty=0.25, rough=0.05)
    glug()
    cash()
    fired()
    beep(1760, 0.12, "fuel_low", 0.5, 0.35)
    beep(880, 0.05, "ui_move", 0.25, 0.3)
    beep(1320, 0.08, "ui_select", 0.5, 0.35)
    bump()
    clonk()
    thud()
    glass()
    yelp()
    mowing_song()
    menu_song()
    splash()  # last, so its noise doesn't shift the sounds made before it


if __name__ == "__main__":
    main()
