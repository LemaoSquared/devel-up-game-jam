extends Node2D
@onready var background_manager: Node2D = $BackgroundManager
const CutsceneScene := preload("res://Menus/final_cutscene.tscn")
const GameOverScreen := preload("res://Menus/GameOverScreen.tscn")

func _ready() -> void:
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
		
	await $Transition.Return()
	cutscene.queue_free()
	
	var game_over_instance := GameOverScreen.instantiate()
	add_child(game_over_instance)
	await $Transition.Return()
