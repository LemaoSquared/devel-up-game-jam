extends TextureRect

@export var swipe_duration: float = 1.0       # Time taken to complete the movement
@export var move_x_offset: float = 500.0      # How many pixels to move right from original position

var initial_global_pos: Vector2
var initial_rotation: float

func _ready() -> void:
	# Cache original placed position in the scene
	initial_global_pos = global_position
	initial_rotation = rotation
	
	modulate.a = 0.0
	visible = false

func play_paw_swipe() -> void:
	visible = true
	z_index = 4096 
	
	# Start exactly at its original position
	global_position = initial_global_pos
	rotation = initial_rotation - deg_to_rad(8.0) # Subtle wind-up tilt
	modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# 1. Fade in quickly right at the start location
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	
	# 2. Move X relative to its original starting position
	var target_x = initial_global_pos.x + move_x_offset
	tween.tween_property(self, "global_position:x", target_x, swipe_duration)
	
	# 3. Slight tilt while swiping forward
	tween.tween_property(self, "rotation", initial_rotation + deg_to_rad(6.0), swipe_duration)
	
	# 4. Fade out during the second half of the movement
	var fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_IN)
	fade_tween.tween_interval(swipe_duration * 0.4)
	fade_tween.tween_property(self, "modulate:a", 0.0, swipe_duration * 0.6)
	
	# Reset back to original state for the next use
	await tween.finished
	visible = false
	rotation = initial_rotation
	global_position = initial_global_pos
