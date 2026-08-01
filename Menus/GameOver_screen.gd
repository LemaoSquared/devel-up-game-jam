extends Node2D
@onready var retry_button: Button = $ColorRect/retry 

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.pressed.connect(_retry_button_pressed)

func _retry_button_pressed() -> void:
	#AudioManager.stop_music()
	PauseManager.unpause_game()
	PauseManager.enable_pause()
	get_tree().reload_current_scene()
