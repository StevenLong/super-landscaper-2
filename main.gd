extends Node2D


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
