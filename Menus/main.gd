extends Node2D

@onready var background_manager: Node2D = $BackgroundManager
const CutsceneScene := preload("res://Menus/final_cutscene.tscn")
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect

const GameOverScreen := preload("res://Menus/GameOverScreen.tscn")


func _ready() -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 1.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)

	$StartPanel.game_started.connect($Background.close_cinematic_bars)
	$StartPanel.game_started.connect($ProgressBar.start_countdown)
	$StartPanel.game_started.connect(PauseManager.enable_pause)
	$ProgressBar.countdown_finished.connect(_on_progress_bar_countdown_finished)

	$StartPanel.visible = true


func _on_progress_bar_countdown_finished() -> void:
	await $Transition.transition()

	$Background.retreat_cinematic_bars()
	
	var cutscene := CutsceneScene.instantiate()
	add_child(cutscene)
	await $Transition.Return()
	
	if cutscene.has_signal("cutscene_finished"):
		await cutscene.cutscene_finished
		
	await $Transition.transition() 
	cutscene.queue_free()
	
	var game_over_instance := GameOverScreen.instantiate()
	add_child(game_over_instance)

	await $Transition.Return()
