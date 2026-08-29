extends Node2D

signal popped_out(obj: Node, was_clicked: bool)
#const GLOVE_PARTICLE = preload("uid://b1e6bon8ifbuk") # Replace with your glove particle UID/path if needed

var is_popping: bool = false

const DURATION: float = 6.0
const GLOVES = preload("uid://citaxe8665j87")

@onready var glove_area: Area2D = $Glove
@onready var sprite_2d: AnimatedSprite2D = $Glove/Sprite2D


func _ready() -> void:
	if sprite_2d and sprite_2d.sprite_frames and sprite_2d.sprite_frames.has_animation("default"):
		sprite_2d.play("default")

	# Disabled standard area input pickable in favor of global _input handling
	glove_area.input_pickable = false

	var timer := get_tree().create_timer(DURATION, false)
	timer.timeout.connect(_on_duration_expired)

	start_floating(self)


# --- Multi-touch & Mouse Input Handling ---
func _input(event: InputEvent) -> void:
	if is_popping:
		return
		
	var click_pos = Vector2.ZERO
	var is_triggered: bool = false
	
	if event is InputEventScreenTouch and event.pressed:
		click_pos = event.position
		is_triggered = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_pos = event.position
		is_triggered = true
		
	if is_triggered:
		if global_position.distance_to(click_pos) < 64.0: # Adjust radius if needed
			collect_glove()


func collect_glove() -> void:
	if is_popping:
		return
		
	AudioManager.play_sound(GLOVES)
	#ParticleManager.spawn_particle(GLOVE_PARTICLE, global_position)
	
	is_popping = true
	glove_area.input_pickable = false

	# LivesManager is left completely untouched here.
	# Call your custom glove mechanics inside this function:
	_apply_glove_effect()

	popped_out.emit(self, true)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)


func _apply_glove_effect() -> void:
	# TODO: Implement your unique glove power-up logic here 
	# (e.g., temporary score multiplier, auto-tap frenzy, or clearing active hazards)
	pass


func start_floating(
	obj: Node2D,
	float_height: float = 12.0,
	duration: float = 1.0
) -> void:
	var float_tween := obj.create_tween().set_loops()

	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)

	# Float upward
	float_tween.tween_property(
		obj,
		"position:y",
		-float_height,
		duration
	).as_relative()

	# Float downward past the original position
	float_tween.tween_property(
		obj,
		"position:y",
		float_height * 2.0,
		duration * 2.0
	).as_relative()

	# Return upward to the starting position
	float_tween.tween_property(
		obj,
		"position:y",
		-float_height * 2.0,
		duration * 2.0
	).as_relative()


func _on_duration_expired() -> void:
	if is_popping:
		return

	pop_out()


func pop_out() -> void:
	if is_popping:
		return

	is_popping = true
	glove_area.input_pickable = false

	# false = expired without being clicked
	popped_out.emit(self, false)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)
