extends Node2D
@export var final_cutscene: PackedScene
@onready var background_manager: Node2D = $BackgroundManager
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
const GameOverScreen = preload("uid://dh364flg18d2j")
const CutsceneScene = preload("uid://bqfwjyhkbhn82")
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	background_manager.sequence_finished.connect(_on_background_sequence_finished)
	progress_bar.countdown_finished.connect(_on_progress_bar_countdown_finished)
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


func _on_progress_bar_countdown_finished() -> void:
	await $Transition.transition()

	$Background.retreat_cinematic_bars()
	
	var cutscene := CutsceneScene.instantiate()
	add_child(cutscene)
	await $Transition.Return()
	
	if cutscene.has_signal("cutscene_finished"):
		await cutscene.cutscene_finished
		cutscene.queue_free()

	
func _on_background_sequence_finished() -> void:
	SceneTransition.change_scene(final_cutscene)
