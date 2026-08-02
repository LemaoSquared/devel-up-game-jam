extends Control

@export_file("*.tscn") var next_scene_path: String = "res://Menus/Main.tscn"

@export var fade_in_duration: float = 1.2
@export var logo_display_duration: float = 1.5
@export var fade_out_duration: float = 1.2

@onready var logo_container: Control = $CenterContainer
@onready var background: ColorRect = $ColorRect

var is_changing_scene: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Start completely invisible.
	logo_container.modulate.a = 0.0

	play_splash_animation()


func play_splash_animation() -> void:
	var tween := create_tween()

	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Smooth fade in.
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		logo_container,
		"modulate:a",
		1.0,
		fade_in_duration
	)

	# Keep the logo visible.
	tween.tween_interval(logo_display_duration)

	# Smooth fade out.
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		logo_container,
		"modulate:a",
		0.0,
		fade_out_duration
	)

	await tween.finished

	change_to_main_scene()


func change_to_main_scene() -> void:
	if is_changing_scene:
		return

	is_changing_scene = true

	var error := get_tree().change_scene_to_file(next_scene_path)

	if error != OK:
		push_error(
			"Failed to load scene: " + next_scene_path
		)
