extends Node2D
@export var final_cutscene: PackedScene
@onready var background_manager: Node2D = $BackgroundManager
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
const GameOverScreen = preload("uid://dh364flg18d2j")
const CutsceneScene = preload("uid://bqfwjyhkbhn82")
@onready var progress_bar: ProgressBar = $ProgressBar
const BACKYARD = preload("uid://c13kxu5fitd1y")
@onready var lives: HBoxContainer = $Lives
@onready var pause_button: TextureButton = $PauseButton

func _ready() -> void:
	pause_button.visible = false
	
	progress_bar.countdown_finished.connect(_on_story_mode_completed)
	
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 1.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	
	# Story
	$StartPanel.game_started.connect($Background.close_cinematic_bars)
	$StartPanel.game_started.connect($ProgressBar.start_countdown)
	$StartPanel.game_started.connect(_on_game_start_enable_pause)
	
	# Endless
	$StartPanel.endless_started.connect($Background.close_cinematic_bars)
	$StartPanel.endless_started.connect(_on_game_start_enable_pause)
	LivesManager.game_over.connect(_on_lives_depleted)
	
	$StartPanel.visible = true

func _on_game_start_enable_pause() -> void:
	PauseManager.enable_pause()
	await get_tree().create_timer(0.5).timeout
	pause_button.visible = true

func _on_story_mode_completed() -> void:
	PauseManager.disable_pause()
	pause_button.visible = false
	
	if ItemManager.has_method("stop_spawning"):
		ItemManager.stop_spawning()
	await _run_game_over_sequence(true)

func _on_lives_depleted() -> void:
	if !ItemManager.is_endless:
		return
	PauseManager.disable_pause()
	pause_button.visible = false
	
	ItemManager.stop_endless()
	await _run_game_over_sequence(false)

func _run_game_over_sequence(show_cutscene: bool = true) -> void:
	if show_cutscene:
		await $Transition.transition()
		$Background.retreat_cinematic_bars()
		var cutscene := CutsceneScene.instantiate()
		add_child(cutscene)
		await $Transition.Return()
		if cutscene.has_signal("cutscene_finished"):
			AudioManager.stop_music()
			AudioManager.play_music(BACKYARD)
			await cutscene.cutscene_finished
	else:
		await $Transition.Return()
	lives.visible = false
	pause_button.visible = false
	var game_over := GameOverScreen.instantiate()
	$Background.retreat_cinematic_bars()
	add_child(game_over)
	background_manager.reset()


func _on_pause_button_pressed() -> void:
	PauseManager.pause_game()
