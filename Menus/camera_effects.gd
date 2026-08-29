extends CanvasLayer

var effect_running: bool = false
@onready var hurt_rect: TextureRect = $HurtRect
@onready var heal_rect: TextureRect = $HealRect
@onready var glove_rect: TextureRect = $GloveRect
@onready var block_rect: TextureRect = $BlockRect

const SLOW_TIME_SCALE: float = 0.25
const SLOW_MOTION_DURATION: float = 0.7

@onready var polaroid_1: TextureRect = $"../Background/Polaroid_1"
@onready var polaroid_2: TextureRect = $"../Background/Polaroid_2"
@onready var polaroid_3: TextureRect = $"../Background/Polaroid_3"
@onready var polaroid_4: TextureRect = $"../Background/Polaroid_4"
@onready var polaroid_5: TextureRect = $"../Background/Polaroid_5"

@onready var flash_rect: ColorRect = $FlashRect

# Pool to track non-repeating polaroid choices
var polaroid_pool: Array[TextureRect] = []

func _ready() -> void:
	add_to_group("camera_effects")

	# Ensure the CanvasLayer itself is always active so children can render anytime
	visible = true 

	flash_rect.modulate.a = 0.0
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Initialize BlockRect
	if block_rect:
		block_rect.modulate.a = 0.0
		block_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		block_rect.visible = false
		
	# Initialize HurtRect
	if hurt_rect:
		hurt_rect.modulate.a = 0.0
		hurt_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hurt_rect.visible = false

	# Initialize HealRect
	if heal_rect:
		heal_rect.modulate.a = 0.0
		heal_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heal_rect.visible = false

	# Initialize GloveRect
	if glove_rect:
		glove_rect.modulate.a = 0.0
		glove_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glove_rect.visible = false
	
	# Position all 5 polaroids off-screen left at startup
	var polaroids = [polaroid_1, polaroid_2, polaroid_3, polaroid_4, polaroid_5]
	for p in polaroids:
		if p:
			p.global_position.x = -p.size.x
			p.visible = false

func activate_camera_effect() -> void:
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
	
	# 5. Let the remaining slow motion duration play out smoothly
	await get_tree().create_timer(
		SLOW_MOTION_DURATION,
		true, # process_always = true (ignores time_scale)
		false,
		true
	).timeout

	Engine.time_scale = 1.0
	effect_running = false

func transform_all_items() -> void:
	var targets := get_tree().get_nodes_in_group("camera_targets")
	for target in targets:
		if not is_instance_valid(target):
			continue
		if target.has_method("transform_to_polaroid"):
			target.transform_to_polaroid()

func slide_random_polaroid() -> void:
	# Refill and shuffle the pool with all 5 items if it runs dry to prevent repeats
	if polaroid_pool.is_empty():
		polaroid_pool = [polaroid_1, polaroid_2, polaroid_3, polaroid_4, polaroid_5]
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

func trigger_hurt_effect() -> void:
	if not hurt_rect:
		return
		
	hurt_rect.visible = true
	hurt_rect.modulate.a = 0.0
	
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT if "EASE_OUT" in [Tween.EASE_OUT] else Tween.EASE_OUT)
	
	tween.tween_property(hurt_rect, "modulate:a", 0.5, 0.06)
	tween.tween_property(hurt_rect, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func(): hurt_rect.visible = false)

func trigger_heal_effect() -> void:
	if not heal_rect:
		return
		
	heal_rect.visible = true
	heal_rect.modulate.a = 0.0
	
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(heal_rect, "modulate:a", 0.45, 0.1)
	tween.tween_property(heal_rect, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func(): heal_rect.visible = false)

# --- NEW: Glove Powerup & Hazard Block Screen Effect ---
func trigger_glove_effect() -> void:
	if not glove_rect:
		return
		
	glove_rect.visible = true
	glove_rect.modulate.a = 0.0
	
	var tween := create_tween()
	tween.set_ignore_time_scale(true) # Smooth playback regardless of time scale
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	# Phase 1: Fade in slightly longer and more prominent than heal/hurt (~0.2s)
	tween.tween_property(glove_rect, "modulate:a", 0.55, 0.2)
	
	# Phase 2: Hold for a tiny moment so it lingers comfortably (~0.2s)
	tween.tween_interval(0.2)
	
	# Phase 3: Smooth, slightly longer fade out back to clear (~0.35s)
	tween.tween_property(glove_rect, "modulate:a", 0.0, 0.35)
	
	# Clean up visibility toggle when finished
	tween.tween_callback(func(): glove_rect.visible = false)

func trigger_block_effect() -> void:
	if not block_rect:
		return
		
	# Snap to fully visible instantly
	block_rect.visible = true
	block_rect.modulate.a = 1.0 
	
	var tween := create_tween()
	tween.set_ignore_time_scale(true) # Ensures it works while the game is frozen
	
	# Changed from TRANS_EXPO to TRANS_QUAD for a smoother, softer fade
	tween.set_trans(Tween.TRANS_QUAD) 
	tween.set_ease(Tween.EASE_OUT)
	
	# Hold at full visibility for the duration of the hitstop (0.25 seconds)
	tween.tween_interval(0.25)
	
	# Gradually drop the opacity to 0 over 0.5 seconds (increased from 0.15)
	tween.tween_property(block_rect, "modulate:a", 0.0, 0.5)
	
	# Clean up visibility toggle when finished
	tween.tween_callback(func(): block_rect.visible = false)
