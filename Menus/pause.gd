extends Panel  

@onready var resume_button: Button = $Resume
@onready var quit_button: Button = $Quit

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	PauseManager.game_paused.connect(_on_game_paused)
	PauseManager.game_unpaused.connect(_on_game_unpaused)

	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_game_paused() -> void:
	visible = true

func _on_game_unpaused() -> void:
	visible = false

func _on_resume_pressed() -> void:
	PauseManager.unpause_game()

func _on_quit_pressed() -> void:
	#get_tree().quit() #If you want to directly exit the game
	PauseManager.unpause_game()
	PauseManager.disable_pause()
	get_tree().reload_current_scene()
