class_name Stone
extends Area2D
## A small thing lying on the lawn: a stone, a gnome, the petrol can. Mow over it and
## something happens (KINDS, main.gd _on_stone_mowed); or get off, pick it up, carry it
## away or throw it.

signal mowed_over(stone: Stone, mower: Node2D)

const LAUNCH_CHANCE := 0.7
## What mowing each kind does: "fling" launches it (sometimes, or "always"), "shatter"
## bursts it into "bits", "spill" leaves a stain. "damage" hurts the mower; "theirs" names
## it to the customer, who takes "mood" off for it.
const KINDS := {
	"stone": {"mowed": "fling", "damage": 12.0},
	"cone": {"mowed": "fling", "always": true},
	"gnome": {"mowed": "shatter", "damage": 8.0, "theirs": "gnome", "mood": -15.0, "bits": ["d04430", "f4f0e6", "4070b8", "e8b088"]},
	"flamingo": {"mowed": "shatter", "bits": ["f088b0", "d05888", "f8c0d8"]},
	"ball": {"mowed": "shatter", "bits": ["d0e040", "a8c020", "f8f8f0"]},
	"hose": {"mowed": "spill", "damage": 2.0, "theirs": "hose", "mood": -8.0, "spill": Color(0.4, 0.6, 0.9, 0.45)},
	"jerrycan": {"mowed": "spill", "damage": 4.0, "theirs": "lawn", "mood": -12.0, "spill": Color(0.42, 0.33, 0.12, 0.8)},
}

var kind := "stone"

static var _textures := {}


## A kind's sprite, kept loaded: a texture load()ed in _draw and dropped after it is freed
## while the canvas still points at it, and draws as a white box.
static func texture(of: String) -> Texture2D:
	if not _textures.has(of):
		_textures[of] = load("res://art/%s.png" % of)
	return _textures[of]


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	cs.shape = shape
	add_child(cs)
	body_entered.connect(func(b: Node2D) -> void:
		if "cut_radius" in b and (b.velocity as Vector2).length() > 15.0:
			mowed_over.emit(self, b))


## Standing on its foot, so the tall ones (a gnome, the flamingo) stand up in 3/4.
func _draw() -> void:
	var t := Stone.texture(kind)
	draw_texture(t, Vector2(-t.get_width() / 2.0, 4.0 - t.get_height()))
