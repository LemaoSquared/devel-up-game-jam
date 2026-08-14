extends CanvasLayer

var effect_running: bool = false

const SLOW_TIME_SCALE: float = 0.25
const SLOW_MOTION_DURATION: float = 0.7

@onready var polaroid_1: TextureRect = $"../Background/Polaroid_1"
@onready var polaroid_2: TextureRect = $"../Background/Polaroid_2"
@onready var polaroid_3: TextureRect = $"../Background/Polaroid_3"

@onready var flash_rect: ColorRect = $FlashRect

# Pool to track non-repeating polaroid choices
var polaroid_pool: Array[TextureRect] = []

func _ready() -> void:
	add_to_group("camera_effects")

	flash_rect.modulate.a = 0.0
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Position polaroids off-screen left at startup
	var polaroids = [polaroid_1, polaroid_2, polaroid_3]
	for p in polaroids:
		if p:
			p.global_position.x = -p.size.x
			p.visible = false

func activate_camera_effect() -> void:
	visible = true
	if effect_running:
		return
	effect_running = true
	
	# 1. Flash quickly hits full white blinding effect
	await flash_in()
	
	# 2. Trigger the time dilation and object transformations
	Engine.time_scale = SLOW_TIME_SCALE
	transform_all_items()
	
	# 3. Fade the flash out immediately so the screen doesn't stay white
	flash_out()
	
	# 4. Wait a split second after the flash peak, then slide the polaroid in seamlessly
	get_tree().create_timer(0.1, true).timeout.connect(func():
		slide_random_polaroid()
	)
	
	# Wait for the screen to finish clearing up visually
	
	
	# 5. Let the remaining slow motion duration play out smoothly
	await get_tree().create_timer(
		SLOW_MOTION_DURATION,
		true, # process_always = true (ignores time_scale)
		false,
		true
	).timeout

	Engine.time_scale = 1.0
	effect_running = false
	visible = false

func transform_all_items() -> void:
	var targets := get_tree().get_nodes_in_group("camera_targets")
	for target in targets:
		if not is_instance_valid(target):
			continue
		if target.has_method("transform_to_polaroid"):
			target.transform_to_polaroid()

func slide_random_polaroid() -> void:
	# Refill and shuffle the pool if it runs dry to prevent repeats
	if polaroid_pool.is_empty():
		polaroid_pool = [polaroid_1, polaroid_2, polaroid_3]
		polaroid_pool.shuffle()
		
	# Pop a random, non-repeating polaroid from the pool
	var chosen_polaroid = polaroid_pool.pop_back()
	if not is_instance_valid(chosen_polaroid):
		return

	# Setup target positioning dimensions
	var hidden_x: float = -chosen_polaroid.size.x
	var visible_x: float = 5.0 # Rest position inside the screen's left edge
	
	# Reset properties before starting the movement loop
	chosen_polaroid.global_position.x = hidden_x
	chosen_polaroid.visible = true
	
	# Create the slide-in and slide-out sequence
	var tween = create_tween()
	tween.set_ignore_time_scale(true) # Runs smoothly during slow-mo!
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	# Phase A: Slide onto screen left side
	tween.tween_property(chosen_polaroid, "global_position:x", visible_x, 0.4)
	
	# Phase B: Hold it on screen for a brief display window
	tween.tween_interval(3.0)
	
	# Phase C: Slide back out off-screen left side
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(chosen_polaroid, "global_position:x", hidden_x, 0.3)
	
	# Hide layout reference entirely when fully out of view bounds
	tween.tween_callback(func(): chosen_polaroid.visible = false)

func flash_in() -> void:
	flash_rect.modulate.a = 0.0
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		flash_rect,
		"modulate:a",
		1.0,
		0.08
	)
	await tween.finished

func flash_out() -> void:
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		flash_rect,
		"modulate:a",
		0.0,
		0.3
	)
	await tween.finished
