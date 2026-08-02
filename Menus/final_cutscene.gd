extends Node2D

@onready var kath: AnimatedSprite2D = $AnimatedSprite2D
@onready var continue_button: Button = $Button
@export var spawn_delay: float = 5.0
var front_facing_scale: float = 2.25
var back_facing_scale: float = 2.375
@onready var camera_effects: CanvasLayer = $CameraEffects

var target_button_y: float 

func _ready() -> void:
	target_button_y = continue_button.position.y
	continue_button.position.y = target_button_y + 30.0
	
	# --- FIX: Completely hide AND disable the button at the start ---
	continue_button.modulate.a = 0.0 
	continue_button.visible = false 
	continue_button.disabled = true
	# ----------------------------------------------------------------
	
	continue_button.pressed.connect(_on_continue_button_pressed)
	
	kath_walk_to_grave()


func kath_walk_to_grave() -> void:
	kath.scale = Vector2(front_facing_scale, front_facing_scale)
	kath.play("default") 
	
	var sequence = create_tween()
	
	sequence.tween_property(kath, "position:x", 900.0, 2.5).set_trans(Tween.TRANS_LINEAR)
	
	sequence.tween_callback(func():
		kath.play("walk_to_stand")
	)
	
	sequence.tween_property(kath, "position:x", 967.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	sequence.tween_interval(0.8) 
	
	sequence.tween_callback(func():
		kath.play("back_turned")
		kath.scale = Vector2(back_facing_scale, back_facing_scale)
	)
	
	# The 5 second dramatic pause
	sequence.tween_interval(5.0) 
	
	# --- FIX: Turn the button on EXACTLY when we are ready to fade it in ---
	sequence.tween_callback(func():
		continue_button.visible = true
		continue_button.disabled = false
	)
	# -----------------------------------------------------------------------
	
	sequence.set_parallel(true) 
	sequence.tween_property(continue_button, "modulate:a", 1.0, 1.5)
	sequence.tween_property(continue_button, "position:y", target_button_y, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sequence.set_parallel(false)
	
	sequence.tween_callback(_start_button_float)

func _start_button_float() -> void:
	var float_tween = create_tween().set_loops()
	float_tween.tween_property(continue_button, "position:y", target_button_y - 8.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(continue_button, "position:y", target_button_y, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_continue_button_pressed() -> void:
	continue_button.disabled = true
	camera_effects.visible = true
	await camera_effects.flash_in()
	
	get_tree().change_scene_to_file("res://Menus/GameOverScreen.tscn")
