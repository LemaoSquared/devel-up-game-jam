extends Node2D
@onready var background_manager: Node2D = $BackgroundManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$StartPanel.game_started.connect($Background.close_cinematic_bars)
	$StartPanel.game_started.connect($ProgressBar.start_countdown)
	$StartPanel.game_started.connect(PauseManager.enable_pause)
	$StartPanel.visible = true
	background_manager.pause_movement()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
