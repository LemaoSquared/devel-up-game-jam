extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$StartPanel.game_started.connect($Background.close_cinematic_bars)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
