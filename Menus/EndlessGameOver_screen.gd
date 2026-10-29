extends Node2D

@onready var color_rect_2: ColorRect = $ColorRect2
const STREET = preload("uid://c6xk46jpedco4")
@onready var pic_1: TextureRect = $Middle

@onready var treat_count: Label = $HBoxContainer/Control/Treat_Count
@onready var yarn_count: Label = $HBoxContainer/Control2/Yarn_Count
@onready var sardine_count: Label = $HBoxContainer/Control4/Sardine_Count
@onready var rat_count: Label = $HBoxContainer/Control5/Rat_Count
@onready var sack_count: Label = $HBoxContainer/Control6/Sack_Count
@onready var polaroid_count: Label = $HBoxContainer/Control7/Polaroid_Count
@onready var red_shoe_count: Label = $"HBoxContainer/Control8/Red Shoe_Count"
@onready var garbage_count: Label = $HBoxContainer/Control9/Garbage_Count
@onready var shoe_count: Label = $HBoxContainer/Control10/Shoe_Count

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
	
	# --- NEW: Populate Item Counts from ScoreManager ---
	# (These will call upon the dedicated variables added to ScoreManager next[cite: 1])
	treat_count.text = str(ScoreManager.treat_count)
	yarn_count.text = str(ScoreManager.yarn_count)
	sardine_count.text = str(ScoreManager.sardine_count)
	rat_count.text = str(ScoreManager.rat_count)
	sack_count.text = str(ScoreManager.sack_count)
	polaroid_count.text = str(ScoreManager.polaroid_count)
	red_shoe_count.text = str(ScoreManager.red_shoe_count)
	garbage_count.text = str(ScoreManager.garbage_count)
	shoe_count.text = str(ScoreManager.shoe_count)
	# --------------------------------------------------


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
	
	# 2. Run the simple animation
	throw_pictures_on_table()
	
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
	


func throw_pictures_on_table() -> void:
	# Put them in a quick list so we can loop through them 1, 2, 3
	

	
	# Save where you placed them in the editor
	var target_pos = pic_1.position
	var target_rot = pic_1.rotation
	var target_scale = pic_1.scale
	
	# Push them way off screen, make them big, and twist them a bit
	pic_1.position.y -= 800
	pic_1.scale = target_scale * 2.0
	pic_1.rotation = target_rot - 1.0 
	
	# Tween them back to normal!
	var tween = create_tween().set_parallel(true)
	tween.set_ignore_time_scale(true) 
	var delay = 0.25 # Delays the 2nd and 3rd picture slightly
	
	tween.tween_property(pic_1, "position", target_pos, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.tween_property(pic_1, "rotation", target_rot, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.tween_property(pic_1, "scale", target_scale, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).set_delay(delay)
