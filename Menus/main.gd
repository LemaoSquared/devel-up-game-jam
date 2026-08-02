extends Node2D
@export var final_cutscene: PackedScene
@onready var background_manager: Node2D = $BackgroundManager
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect

func _ready() -> void:
	background_manager.sequence_finished.connect(_on_background_sequence_finished)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 1.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)

	$StartPanel.game_started.connect($Background.close_cinematic_bars)
	$StartPanel.game_started.connect($ProgressBar.start_countdown)
	$StartPanel.game_started.connect(PauseManager.enable_pause)

	$StartPanel.visible = true
	
func _on_background_sequence_finished() -> void:
	if final_cutscene:
		SceneTransition.change_scene(final_cutscene)
	else:
		push_error("Main Script: No final cutscene assigned in the Inspector!")
