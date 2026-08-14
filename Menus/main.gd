extends Node2D
@export var final_cutscene: PackedScene
@onready var background_manager: Node2D = $BackgroundManager
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
const GameOverScreen = preload("uid://dh364flg18d2j")
const CutsceneScene = preload("uid://bqfwjyhkbhn82")
@onready var progress_bar: ProgressBar = $ProgressBar

const BACKYARD = preload("uid://c13kxu5fitd1y")

func _ready() -> void:
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
		AudioManager.stop_music()
		AudioManager.play_music(BACKYARD)
		await cutscene.cutscene_finished
		var game_over := GameOverScreen.instantiate()
		add_child(game_over)
		background_manager.reset()
