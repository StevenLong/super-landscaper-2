extends Node2D


func _ready() -> void:
	$Lawn.cut_changed.connect(func(f: float) -> void: $HUD/Percent.text = "%d%%" % floori(f * 100.0))
