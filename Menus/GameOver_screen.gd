extends Node2D

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
	
	# 2. Run the simple animation
	throw_pictures_on_table()

func throw_pictures_on_table() -> void:
	# Put them in a quick list so we can loop through them 1, 2, 3
	var pictures = [pic_1, pic_2, pic_3]
	
	for i in range(pictures.size()):
		var p = pictures[i]
		
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
		var delay = i * 0.25 # Delays the 2nd and 3rd picture slightly
		
		tween.tween_property(p, "position", target_pos, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
		tween.tween_property(p, "rotation", target_rot, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
		tween.tween_property(p, "scale", target_scale, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).set_delay(delay)

func _retry_button_pressed() -> void:
	ScoreManager.reset_score()
	SceneTransition.change_scene(MAIN)
	ItemManager.current_pattern = 1
