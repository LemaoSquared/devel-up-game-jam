extends Node2D

@onready var color_rect_2: ColorRect = $ColorRect2
const STREET = preload("uid://c6xk46jpedco4")

@onready var retry_button: Button = $ColorRect/retry 
@onready var score_label: Label = $ColorRect/ScoreLabel

# 1. Grab your 3 simple TextureRects (Update these paths to match your scene!)
@onready var pic_1: TextureRect = $Middle
@onready var pic_2: TextureRect = $Left
@onready var pic_3: TextureRect = $Right

const MAIN = preload("uid://fldj3nccgla6")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.pressed.connect(_retry_button_pressed)
	score_label.text = "Score: %d" % ScoreManager.score
	
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

func throw_pictures_on_table() -> void:
	# Put them in a quick list so we can loop through them 1, 2, 3
	var pictures = [pic_1, pic_2, pic_3]
	
	for i in range(pictures.size()):
		var p = pictures[i]
		if not is_instance_valid(p): continue
		
		# Save where you placed them in the editor
		var target_pos = p.position
		var target_rot = p.rotation
		var target_scale = p.scale
		
		# Push them way off screen, make them big, and twist them a bit
		p.position.y -= 800
		p.scale = target_scale * 2.0
		p.rotation = target_rot - 1.0 
		
		# Tween them back to normal!
		var tween = create_tween().set_parallel(true)
		tween.set_ignore_time_scale(true) 
		var delay = i * 0.25 # Delays the 2nd and 3rd picture slightly
		
		tween.tween_property(p, "position", target_pos, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
		tween.tween_property(p, "rotation", target_rot, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
		tween.tween_property(p, "scale", target_scale, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).set_delay(delay)

func _retry_button_pressed() -> void:
	# --- CRITICAL FIX: Ensure the engine is fully unpaused before switching scenes ---
	get_tree().paused = false
	Engine.time_scale = 1.0
	PauseManager.unpause_game()
	PauseManager.disable_pause()
	# ---------------------------------------------------------------------------------
	SceneTransition.reload_scene()
	await get_tree().create_timer(0.4).timeout
	AudioManager.play_music(STREET)
	queue_free()
