extends Panel  # change if Pause's root type is different (e.g. Control, Panel)

@onready var resume_button: Button = $VBoxContainer/Resume
@onready var quit_button: Button = $VBoxContainer/Quit
const STREET = preload("uid://c6xk46jpedco4")

func _ready() -> void:
	# This node must run even while paused, so it can respond to button presses
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
	print("UNPAUSED")

func _on_quit_pressed() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	PauseManager.unpause_game()
	PauseManager.disable_pause()
	SceneTransition.reload_scene()
	await get_tree().create_timer(0.4).timeout
	AudioManager.play_music(STREET)
	queue_free()
