extends Node2D

@onready var color_rect_2: ColorRect = $ColorRect2
const STREET = preload("uid://c6xk46jpedco4")

@onready var retry_button: Button = $ColorRect/retry 
@onready var score_label: Label = $ColorRect/ScoreLabel
@onready var highscore_label: Label = $ColorRect/HighScoreLabel


const MAIN = preload("uid://fldj3nccgla6")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.pressed.connect(_retry_button_pressed)
	# main.gd already called try_update_high_score() for the right mode
	var best := ScoreManager.get_high_score(ScoreManager.last_run_endless)
	score_label.text = "Score: %d" % ScoreManager.score
	if ScoreManager.last_run_new_record:
		highscore_label.text = "New High Score: %d!" % best
	else:
		highscore_label.text = "High Score: %d" % best
	
	# --- NEW: Fade Out ColorRect2 on Scene Load ---
	if color_rect_2:
		color_rect_2.visible = true
		color_rect_2.modulate.a = 1.0 # Start completely solid
		
		var fade_tween = create_tween()
		fade_tween.set_ignore_time_scale(true) 
		fade_tween.set_trans(Tween.TRANS_SINE)
		fade_tween.set_ease(Tween.EASE_OUT)
		
		# Smoothly fade alpha down to 0 over 1.5 seconds
		fade_tween.tween_property(color_rect_2, "modulate:a", 0.0, 1.5)
		# Hide completely at the end to save on draw calls
		fade_tween.tween_callback(func(): color_rect_2.visible = false)
	# ---------------------------------------------
	
func _retry_button_pressed() -> void:
	# --- CRITICAL FIX: Ensure the engine is fully unpaused before switching scenes ---
	get_tree().paused = false
	Engine.time_scale = 1.0
	PauseManager.unpause_game()
	PauseManager.disable_pause()
	ItemManager.stop_endless()
	ItemManager.clear_objects()
	# ---------------------------------------------------------------------------------
	SceneTransition.reload_scene()
	await get_tree().create_timer(0.4).timeout
	AudioManager.play_music(STREET)
	queue_free()
