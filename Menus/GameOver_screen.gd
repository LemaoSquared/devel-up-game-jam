extends Node2D
@onready var retry_button: Button = $ColorRect/retry 
@onready var score_label: Label = $ColorRect/ScoreLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.pressed.connect(_retry_button_pressed)
	score_label.text = "Score: %d" % ScoreManager.score

func _retry_button_pressed() -> void:
	#AudioManager.stop_music()
	PauseManager.unpause_game()
	PauseManager.enable_pause()
	ScoreManager.reset_score()
	get_tree().reload_current_scene()
