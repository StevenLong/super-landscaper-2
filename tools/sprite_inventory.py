"""Every sprite the game draws, for a redraw pass in Aseprite (NOTES 137): what each PNG
is, its size, its frame grid and cell size (what Aseprite's File > Import Sprite Sheet
wants), what makes it and what draws it, grouped by kind. Plus what's drawn in code with
no PNG at all. Writes docs/SPRITES.md. Stdlib only.

Run from the repo root: python tools/sprite_inventory.py
It fails if a PNG in art/ isn't listed here, or a listed one is missing, so the list
can't quietly go stale.
"""
import os
import struct
import sys

ART = os.path.join(os.path.dirname(__file__), "..", "art")
OUT = os.path.join(os.path.dirname(__file__), "..", "docs", "SPRITES.md")

FACINGS = "8 rows, one per facing: row 0 faces east, each row down turns 45 degrees clockwise (row 2 faces you)"
KEYS = "drawn in key colours that face.gd swaps per customer (skin, hair, shirt): keep those exact colours"

# name: (group, columns, rows, made by, drawn by, what the grid holds)
SPRITES = {
    # Things that turn: voxel models (tools/voxel.py), rendered at 8 facings. The sprite never
    # rotates; the facing picks the row (facing.gd).
    "walker": ("turn", 2, 8, "voxel.py walker()", "walker.gd", "2 walking frames"),
    "client": ("turn", 3, 8, "voxel.py client()", "client.gd, house.gd (head at a window)", "standing, arms up, knocked out; " + KEYS),
    "dog": ("turn", 2, 8, "voxel.py dog()", "dog.gd, walker.gd (carried)", "2 running frames"),
    "hedgehog": ("turn", 2, 8, "voxel.py hedgehog()", "animal.gd (also on its back as a body)", "2 walking frames"),
    "squirrel": ("turn", 2, 8, "voxel.py squirrel()", "animal.gd (also on its back as a body)", "2 running frames"),
    "mower_push": ("turn", 3, 8, "voxel.py push()", "mower.gd, attract.gd", "2 frames pushed, 1 left standing empty"),
    "mower_petrol": ("turn", 3, 8, "voxel.py petrol()", "mower.gd, attract.gd", "2 frames pushed, 1 left standing empty"),
    "mower_rideon": ("turn", 3, 8, "voxel.py rideon()", "mower.gd, attract.gd", "2 frames ridden, 1 left standing empty"),
    "car": ("turn", 4, 8, "voxel.py car()", "main.gd _park_car", "a column per paint colour"),
    # Buildings and vehicles: one image each, standing up from the foot of the front wall.
    "house": ("building", 1, 1, "art_sprites.py house()", "house.gd", "the whole front, roof to paving; the wall's foot is at y 348"),
    "garage": ("building", 1, 1, "art_sprites.py garage()", "house.gd", "the garage beside the house"),
    "mansion": ("building", 1, 1, "art_sprites.py mansion()", "house.gd", "the manor's front; same foot and window heights as the house"),
    "coachhouse": ("building", 1, 1, "art_sprites.py coachhouse()", "house.gd", "the manor's garage"),
    "church": ("building", 1, 1, "art_sprites.py church()", "house.gd", "the church front"),
    "vestry": ("building", 1, 1, "art_sprites.py vestry()", "house.gd", "the church's garage"),
    "lychgate": ("building", 1, 1, "art_sprites.py lychgate()", "main.gd _build_borders", "the churchyard's gate over the path"),
    "truck": ("building", 1, 1, "art_sprites.py truck()", "main.tscn (Truck)", "your truck, parked side-on"),
    "trailer": ("building", 1, 1, "art_sprites.py trailer()", "main.tscn (Truck/Trailer)", "hitched behind the truck"),
    # Boundaries: strips that tile along a side. _h runs along the top and bottom (its face
    # seen), _v up the sides (seen from above).
    "hedge_h": ("border", 1, 1, "art_sprites.py hedge_h()", "main.gd _build_borders", "tiles sideways"),
    "hedge_v": ("border", 1, 1, "art_sprites.py hedge_v()", "main.gd _build_borders", "tiles up and down"),
    "fence_h": ("border", 1, 1, "art_sprites.py fence_h()", "main.gd _build_borders, beyond.gd", "tiles sideways"),
    "fence_v": ("border", 1, 1, "art_sprites.py fence_v()", "main.gd _build_borders, beyond.gd", "tiles up and down"),
    "wall_h": ("border", 1, 1, "art_sprites.py wall_h()", "main.gd _build_borders", "the churchyard wall, tiles sideways"),
    "wall_v": ("border", 1, 1, "art_sprites.py wall_v()", "main.gd _build_borders", "tiles up and down"),
    "railings_h": ("border", 1, 1, "art_sprites.py railings_h()", "main.gd _build_borders", "the manor's railings on the road, tiles sideways"),
    "pier": ("border", 1, 1, "art_sprites.py pier()", "main.gd _build_borders", "a stone gate pier"),
    # Ground: seamless tiles.
    "grass_light": ("ground", 1, 1, "make_art.py grass_tile()", "lawn.gd, beyond.gd, main.gd", "mown stripe; tiles seamlessly"),
    "grass_dark": ("ground", 1, 1, "make_art.py grass_tile()", "lawn.gd, beyond.gd", "the other mown stripe; tiles seamlessly"),
    "grass_long": ("ground", 1, 1, "make_art.py grass_tile()", "lawn.gd", "uncut grass; tiles seamlessly"),
    "soil": ("ground", 1, 1, "make_art.py speckle_tile()", "flowerbed.gd", "bed soil; tiles seamlessly"),
    "gravel": ("ground", 1, 1, "make_art.py speckle_tile()", "main.gd, main.tscn, beyond.gd (drives, paths)", "tiles seamlessly (tinted in code)"),
    "paving": ("ground", 1, 1, "make_art.py paving_tile()", "main.gd, beyond.gd (patios, pavement)", "tiles seamlessly"),
    "asphalt": ("ground", 1, 1, "make_art.py speckle_tile()", "main.gd (the road)", "tiles seamlessly"),
    # Scenery with variants: a strip of cells, one picked per thing.
    "tree_52": ("scenery", 3, 1, "make_art.py canopy()", "tree.gd", "3 canopy variants, 52 px across"),
    "tree_68": ("scenery", 3, 1, "make_art.py canopy()", "tree.gd", "3 canopy variants, 68 px across"),
    "tree_84": ("scenery", 3, 1, "make_art.py canopy()", "tree.gd", "3 canopy variants, 84 px across"),
    "tree_100": ("scenery", 3, 1, "make_art.py canopy()", "tree.gd", "3 canopy variants, 100 px across"),
    "topiary": ("scenery", 6, 1, "art_sprites.py topiary()", "rock.gd via main.gd _manor", "a cone, a ball on a stem, a peacock; then each with a chunk bitten out"),
    "gravestone": ("scenery", 2, 1, "art_sprites.py gravestone()", "rock.gd via main.gd", "2 headstone shapes (the lean is a rotation in code)"),
    "rock": ("scenery", 1, 1, "art_sprites.py rock()", "rock.gd", "a boulder"),
    "pond": ("scenery", 2, 1, "art_sprites.py pond()", "pond.gd", "2 frames of rippling water"),
    "flowers": ("scenery", 6, 2, "art_sprites.py flowers()", "flowerbed.gd", "6 flowers; row 2 the same, flattened"),
    # Props: small things on the lawn, one image each, standing on their foot.
    "stone": ("prop", 1, 1, "art_sprites.py stone()", "stone.gd, flying_stone.gd, beyond.gd", ""),
    "jerrycan": ("prop", 1, 1, "art_sprites.py jerrycan()", "stone.gd", "the petrol can"),
    "gnome": ("prop", 1, 1, "art_sprites.py gnome()", "stone.gd", ""),
    "flamingo": ("prop", 1, 1, "art_sprites.py flamingo()", "stone.gd", ""),
    "cone": ("prop", 1, 1, "art_sprites.py cone()", "stone.gd", ""),
    "ball": ("prop", 1, 1, "art_sprites.py ball()", "stone.gd, dog.gd", "the tennis ball"),
    "urn": ("prop", 1, 1, "art_sprites.py urn()", "stone.gd", "the manor's urns"),
    "splat": ("prop", 1, 1, "art_sprites.py splat()", "main.gd (decals)", "what's left of a critter"),
    # The HUD.
    "faces": ("ui", 22, 5, "make_faces.py", "face.gd", "rows: 5 hair styles; columns: 11 expressions with the mouth shut, then the same 11 open; " + KEYS),
    "font": ("ui", 1, 1, "make_font.py", "pixel_font.gd", "the pixel font's glyphs"),
}

# Drawn in code: no PNG to redraw, each would need one making (and the code pointing at it).
IN_CODE = [
    ("The hose, its reel and the tap", "hose.gd _draw, _draw_reel"),
    ("The ha-ha", "main.gd _add_haha"),
    ("A smashed window's hole and shards, the open front door", "house.gd _draw_house"),
    ("The loop drive's gravel ring", "main.gd _loop_drive (uses gravel.png)"),
    ("Rustling leaves when a critter pushes through a hedge", "main.gd _rustle"),
    ("Grit, blood and clipping bursts; the mower's blood track", "main.gd _burst, _lay_track"),
    ("Puddles and spills", "main.gd _draw_decals"),
    ("Stars round a dazed head, a knocked-out critter or a limping dog", "walker.gd, animal.gd, dog.gd"),
    ("The dog's lead, its sulking rain cloud", "dog.gd _draw"),
    ("The throw's arc and ring, the interact brackets, the window's sight cone", "walker.gd, main.gd"),
    ("Next door's gardens, parkland, the playground", "beyond.gd (partly from the tiles above)"),
    ("The fuel gauge and other HUD bars", "fuel_gauge.gd, hud.gd"),
]

GROUPS = [
    ("turn", "Things that turn (8 facings)",
     "Voxel models in tools/voxel.py, rendered once per facing so every facing agrees. Each sheet has "
     + FACINGS + ", and a column per frame. Redrawing these by hand means 8 facings per frame; see the "
     "art-pipeline notes (NOTES 137) before starting."),
    ("building", "Buildings and vehicles", "One image each. Buildings stand up from the foot of their front wall."),
    ("border", "Boundaries", "Strips that repeat along a side of the garden."),
    ("ground", "Ground tiles", "Seamless tiles: the right edge must meet the left, the top the bottom."),
    ("scenery", "Scenery with variants", "A strip of equal cells; the game picks one per thing."),
    ("prop", "Props", "Small things on the lawn, one image each, drawn standing on their foot."),
    ("ui", "The HUD", ""),
]


def png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
    return struct.unpack(">II", head[16:24])


def main():
    files = sorted(n[:-4] for n in os.listdir(ART) if n.endswith(".png"))
    unlisted = [n for n in files if n not in SPRITES]
    missing = [n for n in SPRITES if n not in files]
    if unlisted or missing:
        sys.exit("sprite_inventory: add %s to SPRITES, drop %s" % (unlisted, missing))
    out = ["# Sprites", "",
           "Every PNG the game draws, generated by `python tools/sprite_inventory.py` (don't edit by hand).",
           "",
           "Scale: 1 pixel is 1 world pixel; the camera shows the garden at 2x. To use one as a",
           "reference in Aseprite: a single image opens as it is; a sheet (more than one cell) goes",
           "through File > Import Sprite Sheet, type By Rows, with the cell size below, which gives a",
           "frame per cell. Save your version over the PNG (same size and grid) and stop regenerating",
           "that file (CLAUDE.md: once a PNG is hand-edited, its tool would overwrite it).",
           ""]
    for key, title, blurb in GROUPS:
        out += ["## " + title, ""]
        if blurb:
            out += [blurb, ""]
        out += ["| Sprite | Size | Grid (cols x rows) | Cell | Made by | Drawn by | Notes |",
                "|---|---|---|---|---|---|---|"]
        for name, (group, cols, rows, made, drawn, note) in SPRITES.items():
            if group != key:
                continue
            w, h = png_size(os.path.join(ART, name + ".png"))
            cell = "%d x %d" % (w // cols, h // rows)
            if w % cols or h % rows:
                sys.exit("sprite_inventory: %s is %dx%d, not a %dx%d grid" % (name, w, h, cols, rows))
            out.append("| `art/%s.png` | %d x %d | %d x %d | %s | %s | %s | %s |" % (name, w, h, cols, rows, cell, made, drawn, note))
        out.append("")
    out += ["## Drawn in code (no PNG yet)", "",
            "These have no image to redraw; each would need a PNG making and the code pointing at it.", "",
            "| What | Where |", "|---|---|"]
    out += ["| %s | %s |" % row for row in IN_CODE]
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")
    print("wrote %s: %d sprites, %d drawn in code" % (os.path.normpath(OUT), len(SPRITES), len(IN_CODE)))


if __name__ == "__main__":
    main()
