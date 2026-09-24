extends Node2D


func _ready() -> void:
	var lawn: Lawn = $Lawn
	lawn.cut_changed.connect(func(f: float) -> void: $HUD/Percent.text = "%d%%" % floori(f * 100.0))

	# Keep the camera inside the lawn so nothing beyond its edge is ever shown.
	var cam: Camera2D = $Mower/Camera
	cam.limit_left = int(lawn.global_position.x)
	cam.limit_top = int(lawn.global_position.y)
	cam.limit_right = int(lawn.global_position.x) + lawn.size_px.x
	cam.limit_bottom = int(lawn.global_position.y) + lawn.size_px.y
