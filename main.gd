extends Node2D

@export var hedgehog_every := 7.0 ## seconds between hedgehogs, roughly
@export var squirrel_every := 13.0
@export var max_animals := 5

var hits := {}

var _next_hedgehog := 3.0
var _next_squirrel := 8.0


func _ready() -> void:
	var lawn: Lawn = $Lawn
	lawn.cut_changed.connect(func(f: float) -> void: $HUD/Percent.text = "%d%%" % floori(f * 100.0))
	$Mower.fuel_changed.connect(func(f: float) -> void: $HUD/Fuel.value = f)

	# Things that aren't grass draw themselves; the lawn just stops counting those cells.
	var drive: ColorRect = $Driveway
	lawn.exclude_rect(Rect2(drive.position - lawn.global_position, drive.size))
	var bed: Node2D = $Flowerbed
	lawn.exclude_rect(Rect2(bed.rect().position - lawn.global_position, bed.size))
	var tree: Node2D = $Tree
	lawn.exclude_circle(tree.global_position - lawn.global_position, tree.radius)

	# Keep the camera inside the lawn so nothing beyond its edge is ever shown.
	var cam: Camera2D = $Mower/Camera
	cam.limit_left = int(lawn.global_position.x)
	cam.limit_top = int(lawn.global_position.y)
	cam.limit_right = int(lawn.global_position.x) + lawn.size_px.x
	cam.limit_bottom = int(lawn.global_position.y) + lawn.size_px.y


func _physics_process(delta: float) -> void:
	_next_hedgehog -= delta
	_next_squirrel -= delta
	if _next_hedgehog <= 0.0:
		_next_hedgehog = hedgehog_every * randf_range(0.6, 1.4)
		spawn_animal("hedgehog")
	if _next_squirrel <= 0.0:
		_next_squirrel = squirrel_every * randf_range(0.6, 1.4)
		spawn_animal("squirrel")


## Spawn an animal just outside a random lawn edge, heading for a random point
## on the lawn so it crosses it.
func spawn_animal(kind: String, at := Vector2.INF, toward := Vector2.INF) -> Animal:
	if $Animals.get_child_count() >= max_animals and at == Vector2.INF:
		return null
	var lawn: Lawn = $Lawn
	var r := Rect2(lawn.global_position, Vector2(lawn.size_px))
	if at == Vector2.INF:
		match randi() % 4:
			0: at = Vector2(randf_range(r.position.x, r.end.x), r.position.y - 20)
			1: at = Vector2(randf_range(r.position.x, r.end.x), r.end.y + 20)
			2: at = Vector2(r.position.x - 20, randf_range(r.position.y, r.end.y))
			_: at = Vector2(r.end.x + 20, randf_range(r.position.y, r.end.y))
	if toward == Vector2.INF:
		toward = Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y))
	var a := Animal.new()
	a.kind = kind
	a.position = at
	a.heading = (toward - at).normalized()
	a.lawn_rect = r
	a.squashed.connect(_on_squashed)
	$Animals.add_child(a)
	return a


func _on_squashed(a: Animal) -> void:
	hits[a.kind] = hits.get(a.kind, 0) + 1
	$HUD/Hits.text = "Hedgehogs %d   Squirrels %d" % [hits.get("hedgehog", 0), hits.get("squirrel", 0)]
