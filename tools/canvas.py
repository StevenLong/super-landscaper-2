"""Tiny stdlib-only pixel canvas and PNG writer for authoring pixel art in code.

Colours are (r, g, b, a) tuples. Nothing here needs Pillow.
"""
import struct
import zlib

CLEAR = (0, 0, 0, 0)


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


class Canvas:
    def __init__(self, w, h, fill=CLEAR):
        self.w, self.h = w, h
        self.px = [[fill for _ in range(w)] for _ in range(h)]

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y][x]
        return CLEAR

    def set(self, x, y, c):
        if c is None:
            return
        if 0 <= x < self.w and 0 <= y < self.h:
            if len(c) == 4 and c[3] == 0:
                return
            self.px[y][x] = c

    def rect(self, x, y, w, h, c):
        for j in range(y, y + h):
            for i in range(x, x + w):
                self.set(i, j, c)

    def ellipse(self, cx, cy, rx, ry, c, shade=None):
        """Filled ellipse. shade(nx, ny) -> colour overrides c per pixel, where
        nx, ny are -1..1 normalised offsets from the centre."""
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                nx = (x + 0.5 - cx) / rx
                ny = (y + 0.5 - cy) / ry
                if nx * nx + ny * ny <= 1.0:
                    self.set(x, y, shade(nx, ny) if shade else c)

    def stamp(self, x, y, rows, pal):
        """Draw ASCII rows; each char looks up pal, '.' or ' ' is transparent."""
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in ". ":
                    continue
                self.set(x + i, y + j, pal[ch])

    def outline(self, c, only_into_clear=True):
        """Add a 1px outline around every opaque pixel."""
        add = []
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x][3] != 0:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if self.get(x + dx, y + dy)[3] != 0 and self.get(x + dx, y + dy) != c:
                        add.append((x, y))
                        break
        for x, y in add:
            self.px[y][x] = c

    def blit(self, other, ox, oy):
        for y in range(other.h):
            for x in range(other.w):
                self.set(ox + x, oy + y, other.px[y][x])

    def scaled(self, k):
        out = Canvas(self.w * k, self.h * k)
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[y][x]
                for j in range(k):
                    for i in range(k):
                        out.px[y * k + j][x * k + i] = c
        return out

    def flipped_h(self):
        out = Canvas(self.w, self.h)
        for y in range(self.h):
            out.px[y] = list(reversed(self.px[y]))
        return out

    def save(self, path):
        raw = b"".join(b"\x00" + bytes(v for c in row for v in c) for row in self.px)

        def chunk(tag, data):
            return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

        png = b"\x89PNG\r\n\x1a\n"
        png += chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0))
        png += chunk(b"IDAT", zlib.compress(raw, 9))
        png += chunk(b"IEND", b"")
        with open(path, "wb") as f:
            f.write(png)


def sheet(frames):
    """Lay canvases out left to right in one strip."""
    w = sum(f.w for f in frames)
    h = max(f.h for f in frames)
    out = Canvas(w, h)
    x = 0
    for f in frames:
        out.blit(f, x, 0)
        x += f.w
    return out
