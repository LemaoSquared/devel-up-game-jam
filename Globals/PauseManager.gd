extends Node

signal game_paused
signal game_unpaused

var is_paused: bool = false
var pause_enabled: bool = false  

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if not pause_enabled:
		return

	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func enable_pause() -> void:
	pause_enabled = true

func disable_pause() -> void:
	pause_enabled = false

func toggle_pause() -> void:
	if is_paused:
		unpause_game()
	else:
		pause_game()

func pause_game() -> void:
	get_tree().paused = true

func show_pause_menu() -> void:
	$Pause.visible = true

func hide_pause_menu() -> void:
	$Pause.visible = false

func unpause_game() -> void:
	is_paused = false
	get_tree().paused = false
	game_unpaused.emit()
